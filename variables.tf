variable "env" {
  description = "The target deployment environment"
  type        = string
}

variable "project_id" {
  description = "The GCP project ID"
  type        = string
}

variable "region" {
  description = "The GCP region in which to deploy resources"
  type        = string
  default     = "us-east1"
}

variable "region_shorthand" {
  description = "The shorthand for the GCP region"
  type        = string
  default     = "use1"
}

variable "vpc_network_name" {
  description = "The name of the existing VPC network"
  type        = string
}

variable "vpc_project_id" {
  description = "The project of the existing VPC"
  type        = string
}

variable "admin_user_gmail_account" {
  description = "Google Group email for the admin"
  type        = string
}

variable "zone" {
  type    = string
  default = "us-east1-a"
}

variable "machine_type" {
  type        = string
  description = "VM size. Use e2-micro to stay in Free Tier, or e2-medium for basic production performance."
  default     = "e2-medium" 
}

variable "network_tag" {
  description = "the network tag to allow traffic"
  type        = string
}

variable "active_stack" {
  description = "Active environment: blue or green"
  type        = string
  default     = "blue"
}