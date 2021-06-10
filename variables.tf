variable "project" {
  type = string
}

variable "network" {
  type = string
}

variable "region" {
  description = "GCP region name."
  type    = string
  default = "asia-southeast1"
}

variable "zone" {
  description = "GCP zone name."
  type    = string
  default = "asia-southeast1-a"
}

variable "machine_type" {
  description = "GCP VM instance machine type."
  type        = string
  default     = "f1-micro"
}

variable "instance_name" {
  description = "Web server name."
  type        = string
  default     = "my-webserver"
}

variable "labels" {
  description = "List of labels to attach to the VM instance."
  type        = map(any)
}
