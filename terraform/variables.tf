variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "region" {
  description = "GCP region for resources"
  type        = string
  default     = "us-central1"
}

variable "zone" {
  description = "GCP zone for zonal resources"
  type        = string
  default     = "us-central1-a"
}

variable "environment" {
  description = "Deployment environment (staging or prod)"
  type        = string
  validation {
    condition     = contains(["staging", "prod"], var.environment)
    error_message = "Environment must be 'staging' or 'prod'."
  }
}

variable "gcs_bucket_name" {
  description = "Name for the GCS data lake bucket"
  type        = string
}

variable "bq_dataset_id" {
  description = "BigQuery dataset ID"
  type        = string
  default     = "cart_abandonment"
}

variable "dataproc_cluster_name" {
  description = "Name for the Dataproc cluster"
  type        = string
  default     = "shopper-spark-cluster"
}

variable "dataproc_worker_count" {
  description = "Number of Dataproc worker nodes (0 for single-node)"
  type        = number
  default     = 0
}

variable "dataproc_master_machine_type" {
  description = "Machine type for the Dataproc master node"
  type        = string
  default     = "n1-standard-4"
}
