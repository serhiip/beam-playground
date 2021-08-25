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

resource "google_storage_bucket" "input_topic_words" {
  name          = "wordcount_input_${random_string.input_topic_words_name.result}"
  location      = var.region
  project       = var.project_id
  force_destroy = true
}

resource "google_storage_bucket" "output_topic_words" {
  name          = "wordcount_output_${random_string.output_topic_words_name.result}"
  location      = var.region
  project       = var.project_id
  force_destroy = true
}

output "wordcount-input-topic" {
  value = google_storage_bucket.input_topic_words.name
}

output "wordcount-output-topic" {
  value = google_storage_bucket.output_topic_words.name
}
