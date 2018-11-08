variable "project_id" {
  description = "ID of project to set up the infrastructure on"
  default     = "ultra-airway-221916"
}

variable "region" {
	description = "Region for cluster"
	default = "us-east1-b"
}

variable "cluster_name" {
	description = "Name of cluster"
	default = "sample-terraform-cluster"
}

