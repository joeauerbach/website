# Lock the terraform version and set GCS backend
terraform {
  required_version = ">= 1.16" 

  backend "gcs" {
  }
}

# Configure the Google Cloud provider
provider "google" {
  project = var.project_id
  region  = var.region

  default_labels = local.label_map
}

#------------------------------- locals ------------------------------------

locals {
  label_list = [
    { key = "environment",            value = var.env },
    { key = "admin",                  value = var.admin_user_gmail_account },
    { key = "managed-by",             value = "terraform" },
    { key = "github-org",             value = "joeauerbach" },
    { key = "github-repo",            value = "website" }
  ]
  
  # Transform the array/list into a map for for_each
  label_map = { for item in local.label_list : item.key => item.value }
}

#------------------------------- resources ---------------------------------

# Pull in existing network data
data "google_compute_network" "vpc_network" {
  project   = var.project_id
  name      = var.vpc_network_name
}

# Firewall rule to allow HTTP traffic
resource "google_compute_firewall" "allow_http" {
  name    = "allow-http"
  network = google_compute_network.vpc_network.name

  allow {
    protocol = "tcp"
    ports    = ["80", "443"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = [var.network_tag]
}

# Reserve ip addresses to flop back and forth between instances. 
resource "google_compute_address" "static_ip_green" {
  name = "wordpress-ip-green"
  region = var.region
}

resource "google_compute_address" "static_ip_blue" {
  name = "wordpress-ip-blue"
  region = var.region
}