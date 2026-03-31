terraform {
  required_version = ">= 1.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

# ---------- GCS Data Lake Bucket ----------

resource "google_storage_bucket" "data_lake" {
  name                        = "${var.gcs_bucket_name}-${var.environment}"
  location                    = var.region
  storage_class               = "STANDARD"
  uniform_bucket_level_access = true
  force_destroy               = true

  versioning {
    enabled = false
  }

  lifecycle_rule {
    condition {
      age = 90
    }
    action {
      type = "Delete"
    }
  }
}

# ---------- BigQuery Dataset ----------

resource "google_bigquery_dataset" "cart_abandonment" {
  dataset_id                 = "${var.bq_dataset_id}_${var.environment}"
  friendly_name              = "Cart Abandonment (${var.environment})"
  description                = "Shopping cart abandonment analysis - ${var.environment} environment"
  location                   = var.region
  delete_contents_on_destroy = true
}

# ---------- Dataproc Cluster ----------

resource "google_dataproc_cluster" "spark_cluster" {
  name   = "${var.dataproc_cluster_name}-${var.environment}"
  region = var.region

  cluster_config {
    staging_bucket = google_storage_bucket.data_lake.name

    master_config {
      num_instances = 1
      machine_type  = var.dataproc_master_machine_type

      disk_config {
        boot_disk_size_gb = 50
        boot_disk_type    = "pd-standard"
      }
    }

    worker_config {
      num_instances = var.dataproc_worker_count
      machine_type  = "n1-standard-4"

      disk_config {
        boot_disk_size_gb = 50
        boot_disk_type    = "pd-standard"
      }
    }

    software_config {
      image_version = "2.1-debian11"

      override_properties = {
        "spark:spark.jars.packages" = "com.google.cloud.spark:spark-bigquery-with-dependencies_2.12:0.36.1"
      }
    }

    gce_cluster_config {
      zone = var.zone
    }
  }
}
