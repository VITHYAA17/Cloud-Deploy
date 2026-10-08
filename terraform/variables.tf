variable "project_id" {
  description = "The GCP project ID"
  type        = string
  default     = "your-gcp-project-id"
}

variable "region" {
  description = "The GCP region to deploy to"
  type        = string
  default     = "us-central1"
}

variable "cluster_name" {
  description = "The name for the GKE cluster"
  type        = string
  default     = "clouddeploy-cluster"
}

variable "gke_num_nodes" {
  description = "Number of GKE nodes"
  type        = number
  default     = 2
}
