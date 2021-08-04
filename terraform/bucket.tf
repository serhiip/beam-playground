resource "google_project_service" "dataflow" {
  project = var.project_id
  service = "dataflow.googleapis.com"

  disable_dependent_services = true
}

resource "random_string" "data_bucket_name" {
  length  = 20
  special = false
  upper   = false
}

resource "google_storage_bucket" "data_bucket" {
  name          = random_string.data_bucket_name.result
  location      = var.region
  project       = var.project_id
  force_destroy = true
}

output "data-bucket-name" {
  value = google_storage_bucket.data_bucket.name
}
