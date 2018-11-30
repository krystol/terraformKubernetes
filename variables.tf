variable "project_id" {
  description = "ID of project to set up the infrastructure on"
  default     = "gft-microservices-activator"
}

variable "region" {
	description = "Region for cluster"
	default = "europe-west1-b"
}

variable "cluster_name" {
	description = "Name of cluster"
	default = "knak-terraform-cluster"
}

variable "username" {
	description = "Admin username for cluster"
	default = "krystianadamczyk"
}

variable "password" {
	description = "Admin password for cluster"
	default = "passwordmustbe16characters"
}

variable "bastion_name" {
	description = "Name of bastion host"
	default = "thomas-bastion-host"
}

variable "onprem_name" {
	description = "Name of onPrem host"
	default = "on-prem-k8s"
}

variable "onprem_name_node" {
	description = "Name of onPrem node"
	default = "on-prem-k8s-node"
}

variable "gce_ssh_pub_key_file" {
	description = "File location of the ssh public ke"
	default = "./ssh/id_rsa.pub"
}

variable "ssh_private_key" {
	description = "File location of the ssh private key"
	default     = "./ssh/id_rsa"
}

variable "gce_ssh_user" {
	description = "ssh username"
	default     = "knak"
}