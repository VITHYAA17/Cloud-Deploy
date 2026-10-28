output "gke_cluster_name" {
  description = "The GKE Cluster Name"
  value       = google_container_cluster.primary.name
}

output "gke_cluster_endpoint" {
  description = "GKE Cluster Endpoint"
  value       = google_container_cluster.primary.endpoint
}

output "gke_region" {
  description = "GKE Region"
  value       = var.region
}
