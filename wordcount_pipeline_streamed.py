"""A streaming word-counting workflow.
"""

# pytype: skip-file

import argparse
import logging
import re
import time

import apache_beam as beam
import apache_beam.transforms.window as window
from apache_beam.options.pipeline_options import PipelineOptions
from apache_beam.options.pipeline_options import SetupOptions
from apache_beam.options.pipeline_options import StandardOptions
from apache_beam.options.pipeline_options import GoogleCloudOptions, WorkerOptions
from apache_beam.metrics import Metrics


class WordExtractingDoFn(beam.DoFn):
  """Parse each line of input text into words."""
  def __init__(self):
    # TODO(BEAM-6158): Revert the workaround once we can pickle super() on py3.
    # super(WordExtractingDoFn, self).__init__()
    beam.DoFn.__init__(self)
    self.words_counter = Metrics.counter(self.__class__, 'words')
    self.word_lengths_counter = Metrics.counter(self.__class__, 'word_lengths')
    self.word_lengths_dist = Metrics.distribution(
        self.__class__, 'word_len_dist')
    self.empty_line_counter = Metrics.counter(self.__class__, 'empty_lines')
    self.latency_dist = Metrics.distribution(self.__class__, 'arrival_latency_dist')

  def process(self, element):
    """Returns an iterator over the words of this element.

    The element is a line of text.  If the line is blank, note that, too.

    Asssimes the first "word" is actually a unix timestamp

    Args:
      element: the element being processed

    Returns:
      The processed element.
    """
    text_line = element.strip()
    if not text_line:
      self.empty_line_counter.inc(1)
    words = re.findall(r'[\w\']+', text_line, re.UNICODE)
    timestamp = words[0]
    try:
      timestamp = int(timestamp)
      self.latency_dist.update(int(time.time()) - timestamp)
    except Exception as e:
      logging.exception(e)
    for w in words[1:]:
      self.words_counter.inc()
      self.word_lengths_counter.inc(len(w))
      self.word_lengths_dist.update(len(w))
    return words


def run(argv=None, save_main_session=True):
    """Build and run the pipeline."""
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--output_topic",
        required=True,
        help=(
            "Output PubSub topic of the form " '"projects/<PROJECT>/topics/<TOPIC>".'
        ),
    )
    group = parser.add_mutually_exclusive_group(required=True)
    group.add_argument(
        "--input_topic",
        help=("Input PubSub topic of the form " '"projects/<PROJECT>/topics/<TOPIC>".'),
    )
    group.add_argument(
        "--input_subscription",
        help=(
            "Input PubSub subscription of the form "
            '"projects/<PROJECT>/subscriptions/<SUBSCRIPTION>."'
        ),
    )
    known_args, pipeline_args = parser.parse_known_args(argv)

    # We use the save_main_session option because one or more DoFn's in this
    # workflow rely on global context (e.g., a module imported at module level).
    pipeline_options = PipelineOptions(pipeline_args)
    pipeline_options.view_as(SetupOptions).save_main_session = save_main_session
    pipeline_options.view_as(StandardOptions).streaming = True
    pipeline_options.view_as(GoogleCloudOptions).job_name = "streaming-wordcount-example"
    pipeline_options.view_as(WorkerOptions).num_workers = 1
    pipeline_options.view_as(WorkerOptions).max_num_workers = 2
    pipeline_options.view_as(WorkerOptions).machine_type = "e2-small"
    pipeline_options.view_as(WorkerOptions).disk_size_gb = 1

    p = beam.Pipeline(options=pipeline_options)

    # Read from PubSub into a PCollection.
    if known_args.input_subscription:
        messages = p | beam.io.ReadFromPubSub(
            subscription=known_args.input_subscription
        ).with_output_types(bytes)
    else:
        messages = p | beam.io.ReadFromPubSub(
            topic=known_args.input_topic
        ).with_output_types(bytes)

    lines = messages | "decode" >> beam.Map(lambda x: x.decode("utf-8"))

    # Count the occurrences of each word.
    def count_ones(word_ones):
        (word, ones) = word_ones
        return (word, sum(ones))

    counts = (
        lines
        | "extract" >> (beam.ParDo(WordExtractingDoFn()).with_output_types(str))
        | "pair_with_one" >> beam.Map(lambda x: (x, 1))
        | beam.WindowInto(window.FixedWindows(15, 0))
        | "group" >> beam.GroupByKey()
        | "count" >> beam.Map(count_ones)
    )

    # Format the counts into a PCollection of strings.
    def format_result(word_count):
        (word, count) = word_count
        return "%s: %d" % (word, count)

    output = (
        counts
        | "format" >> beam.Map(format_result)
        | "encode" >> beam.Map(lambda x: x.encode("utf-8")).with_output_types(bytes)
    )

    # Write to PubSub.
    # pylint: disable=expression-not-assigned
    output | beam.io.WriteToPubSub(known_args.output_topic)

    p.run()


if __name__ == "__main__":
    logging.getLogger().setLevel(logging.INFO)
    run()
