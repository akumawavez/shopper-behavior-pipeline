output "data_lake_bucket_name" {
  description = "GCS data lake bucket name"
  value       = google_storage_bucket.data_lake.name
}

output "data_lake_bucket_url" {
  description = "GCS data lake bucket URL"
  value       = google_storage_bucket.data_lake.url
}

output "bigquery_dataset_id" {
  description = "BigQuery dataset ID"
  value       = google_bigquery_dataset.cart_abandonment.dataset_id
}

output "dataproc_cluster_name" {
  description = "Dataproc cluster name"
  value       = google_dataproc_cluster.spark_cluster.name
}

output "dataproc_cluster_region" {
  description = "Dataproc cluster region"
  value       = google_dataproc_cluster.spark_cluster.region
}
