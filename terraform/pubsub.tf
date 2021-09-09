resource "random_string" "input_topic_words_name" {
  length  = 5
  special = false
  upper   = false
}

resource "random_string" "output_topic_words_name" {
  length  = 5
  special = false
  upper   = false
}

resource "google_pubsub_topic" "input_topic_words" {
  name    = "wordcount_input_${random_string.input_topic_words_name.result}"
  project = var.project_id
}

resource "google_pubsub_topic" "output_topic_words" {
  name    = "wordcount_output_${random_string.output_topic_words_name.result}"
  project = var.project_id
}

resource "google_pubsub_subscription" "input_subscription" {
  name    = "input-subscription"
  topic   = google_pubsub_topic.input_topic_words.name
  project = var.project_id

  ack_deadline_seconds = 20
}

output "wordcount-input-topic" {
  value = google_pubsub_topic.input_topic_words.name
}

output "wordcount-output-topic" {
  value = google_pubsub_topic.output_topic_words.name
}

output "wordcount-input-subscription" {
  value = google_pubsub_subscription.input_subscription.name
}
