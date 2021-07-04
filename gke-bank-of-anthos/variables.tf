variable "project_service_account" {
  description = "Email of the service account created on step 4-projects for the business unit 1 sample base project where the GCE instance will be created"
  type        = string
}

variable "org_id" {
  description = "The organization id for the associated services"
  type        = string
}

variable "instance_region" {
  description = "The region where compute instance will be created. A subnetwork must exists in the instance region."
  type        = string
  default     = "asia-southeast1"
}

variable "folder_prefix" {
  description = "Name prefix to use for folders created. Should be the same in all steps."
  type        = string
  default     = "fldr"
}

variable "parent_folder" {
  description = "Optional - for an organization with existing projects or for development/validation. It will place all the example foundation resources under the provided folder instead of the root organization. The value is the numeric folder ID. The folder must already exist. Must be the same value used in previous step."
  type        = string
  default     = ""
}

# Added on
variable "cluster_name" {
  description = "GKE cluster name."
  type        = string
  default     = "my-gke-cluster"
}

variable "network" {
  description = "Network to be used in deploying Bank of Anthos."
  type        = string
  default     = "bank-of-anthos-network"
}
