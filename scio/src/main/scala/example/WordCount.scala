package example

import com.spotify.scio._

import org.apache.beam.sdk.io.gcp.pubsub.PubsubIO
import org.apache.beam.sdk.options.{
  Description,
  PipelineOptions,
  PipelineOptionsFactory,
  StreamingOptions,
  ValueProvider
}
import org.apache.beam.sdk.options.Validation.Required
import org.apache.beam.runners.dataflow.options.DataflowPipelineWorkerPoolOptions
import org.slf4j.{Logger, LoggerFactory}

object WordCount {
  private val logger = LoggerFactory.getLogger(WordCount.getClass())


  trait Options extends PipelineOptions with StreamingOptions with DataflowPipelineWorkerPoolOptions {
    @Description("The Cloud Pub/Sub subscription to read from")
    @Required
    def getInputSubscription: ValueProvider[String]
    def setInputSubscription(value: ValueProvider[String]): Unit

    @Description("The Cloud Pub/Sub topic to write to")
    @Required
    def getOutputTopic: ValueProvider[String]
    def setOutputTopic(value: ValueProvider[String]): Unit
  }

  def main(cmdlineArgs: Array[String]): Unit = {
    PipelineOptionsFactory.register(classOf[Options])
    val options = PipelineOptionsFactory
      .fromArgs(cmdlineArgs: _*)
      .withValidation
      .as(classOf[Options])
    options.setStreaming(true)
    options.setMaxNumWorkers(1)
    options.setNumWorkers(0)
    options.setDiskSizeGb(0)
    options.setWorkerMachineType("e2-medium")
    run(options)
  }

  def run(options: Options): Unit = {
    val sc = ScioContext(options)

    val inputIO =
      PubsubIO.readStrings().fromSubscription(options.getInputSubscription)
    val outputIO = PubsubIO.writeStrings().to(options.getOutputTopic)

    val input = sc.customInput("input", inputIO)

    val printed = input map { (str: String) =>
      logger.debug("map start")
      logger.info(s"handling $str")
      logger.debug("map end")
      str
    }

    val result = printed.saveAsCustomOutput("output", outputIO)

    sc.run()
    ()
  }
}

/*
sbt "runMain [PACKAGE].WordCount
  --project=[PROJECT] --runner=DataflowRunner --zone=[ZONE]
  --input=gs://dataflow-samples/shakespeare/kinglear.txt
  --output=gs://[BUCKET]/[PATH]/wordcount"
 */

// object WordCount {
//   def main(cmdlineArgs: Array[String]): Unit = {
//     val (sc, args) = ContextAndArgs(cmdlineArgs)

//     val exampleData = "gs://dataflow-samples/shakespeare/kinglear.txt"
//     val input = args.getOrElse("input", exampleData)
//     val output = args("output")

//     sc.textFile(input)
//       .map(_.trim)
//       .flatMap(_.split("[^a-zA-Z']+").filter(_.nonEmpty))
//       .countByValue
//       .map(t => t._1 + ": " + t._2)
//       .saveAsTextFile(output)

//     val result = sc.run().waitUntilFinish()
//   }
// }
