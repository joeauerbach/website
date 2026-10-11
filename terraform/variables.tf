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
  default = "us-east1-c"
}

variable "active_env" {
  type        = string
  default     = "blue"
  description = "Controls which MIG receives production traffic. Allowed: 'blue' or 'green'"
}

variable "blue_theme_version" {
  type        = string
  default     = "twentytwentyfour"
  description = "Theme checked out on the Blue environment"
}

variable "green_theme_version" {
  type        = string
  default     = "custom-premium-theme"
  description = "Theme checked out on the Green environment"
}

variable "disk_image" {
  type        = string
  description = "the disk used to make the instances"
}