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

variable "username" {
	description = "Admin username for cluster"
	default = "usernameformasterauth"
}

variable "password" {
	description = "Admin password for cluster"
	default = "passwordmustbe16characters"
}

variable "bastion_name" {
	description = "Name of bastion host"
	default = "thomas-bastion-host"
}