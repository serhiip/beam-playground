"""A word-counting workflow."""

import argparse
import logging
import re
from typing import List

import apache_beam as beam
from apache_beam.io import ReadFromText
from apache_beam.io import WriteToText
from apache_beam.options.pipeline_options import PipelineOptions
from apache_beam.options.pipeline_options import SetupOptions
from apache_beam.options.pipeline_options import GoogleCloudOptions, WorkerOptions


class WordExtractingDoFn(beam.DoFn):
    """Parse each line of input text into words."""

    def process(self, elements: List[str]):
        """Returns an iterator over the words of this element.

        The element is a line of text.  If the line is blank, note that, too.

        Args:
        element: the element being processed

        Returns:
        The processed element.
        """
        return [re.findall(r'[\w\']+', element, re.UNICODE) for element in elements]


class WordcountOptions(PipelineOptions):
    @classmethod
    def _add_argparse_args(cls, parser):
        parser.add_value_provider_argument(
            '--input',
            type=str,
            default='gs://dataflow-samples/shakespeare/kinglear.txt',
            help='Path of the file to read from')
        parser.add_value_provider_argument(
            '--output',
            type=str,
            required=False,
            help='Output file to write results to.')


def run(argv=None, save_main_session=True):
    """Main entry point; defines and runs the wordcount pipeline."""
    # We use the save_main_session option because one or more DoFn's in this
    # workflow rely on global context (e.g., a module imported at module level).
    pipeline_options = PipelineOptions()
    wordcount_options = pipeline_options.view_as(WordcountOptions)
    pipeline_options.view_as(SetupOptions).save_main_session = save_main_session
    pipeline_options.view_as(GoogleCloudOptions).job_name = "batch-wordcount-example"
    pipeline_options.view_as(WorkerOptions).num_workers = 1
    pipeline_options.view_as(WorkerOptions).max_num_workers = 1
    pipeline_options.view_as(WorkerOptions).machine_type = "e2-small"
    pipeline_options.view_as(WorkerOptions).disk_size_gb = 0

    # The pipeline will be run on exiting the with block.
    p = beam.Pipeline(options=pipeline_options)

    # Read the text file[pattern] into a PCollection.
    lines = p | ('Read' >> ReadFromText(wordcount_options.input)).with_output_types(List[str])

    counts = (
        lines
        | 'CreateBatch' >> beam.BatchElements(10000)
        | 'Split' >> (beam.ParDo(WordExtractingDoFn()).with_output_types(List[List[str]]))
        | 'PairWithOne' >> beam.FlatMap(lambda words: [(str(w), 1) for w in words])
        | 'GroupAndSum' >> beam.CombinePerKey(sum))

    # Format the counts into a PCollection of strings.
    def format_result(word, count):
        return '%s: %d' % (word, count)

    output = counts | 'Format' >> beam.MapTuple(format_result)

    # Write the output using a "Write" transform that has side effects.
    # pylint: disable=expression-not-assigned
    output | 'Write' >> WriteToText(wordcount_options.output)

    return p.run()

if __name__ == '__main__':
    logging.getLogger().setLevel(logging.INFO)
    run()
