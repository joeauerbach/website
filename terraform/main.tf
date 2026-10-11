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
}

#------------------------------- locals ------------------------------------

#------------------------------- resources ---------------------------------

# Pull in existing network data
data "google_compute_network" "vpc_network" {
  project   = var.project_id
  name      = var.vpc_network_name
}

# -----------------------------------------------------------------
# SHARED RESOURCES (Database & Uploads Shared across Blue & Green)
# -----------------------------------------------------------------
resource "google_sql_database_instance" "wordpress_db" {
  name             = "wordpress-shared-db"
  database_version = "MYSQL_8_0"
  region           = var.region
  deletion_protection = false
  settings {
    tier = "db-f1-micro"
  }
}

resource "google_storage_bucket" "wp_uploads" {
  name          = "${var.project_id}-wp-uploads-bucket"
  location      = "US"
  force_destroy = true
}

# Firewall rule to allow HTTP traffic
 resource "google_compute_firewall" "allow_http" {
   name    = "allow-http"
   network = data.google_compute_network.vpc_network.name

   allow {
     protocol = "tcp"
     ports    = ["80", "443"]
   }

   source_ranges = ["108.217.92.201/32"] # my home ip
#   target_tags   = [var.network_tag]
 }

# -----------------------------------------------------------------
# BLUE INFRASTRUCTURE
# -----------------------------------------------------------------

resource "google_compute_address" "static_ip_blue" {
  name = "wordpress-ip-blue"
  region = var.region
}

resource "google_compute_instance_template" "blue_template" {
  name_prefix  = "wp-blue-template-"
  machine_type = "e2-medium"

  # Crucial for isolating firewall rules
  tags = ["wordpress-server"]

  metadata_startup_script = <<-EOT
    #!/bin/bash
    # Update package lists
    apt-get update -y

    # Install Docker GPG key
    apt-get install -y apt-transport-https ca-certificates curl software-properties-common
    install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
    chmod a+r /etc/apt/keyrings/docker.asc

    # Add Docker GPG repository to apt sources:
    sudo tee /etc/apt/sources.list.d/docker.sources <<EOF
    Types: deb
    URIs: https://download.docker.com/linux/debian
    Suites: $(. /etc/os-release && echo "$VERSION_CODENAME")
    Components: stable
    Architectures: $(dpkg --print-architecture)
    Signed-By: /etc/apt/keyrings/docker.asc
    EOF

    apt-get update -y
    apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

    # Inject Theme configuration dynamically and run WordPress container
    # (Assuming you are passing var.blue_theme_version to your application container)
    docker run -d --name wordpress-blue -p 80:80 \
      -e WORDPRESS_THEME_VERSION="${var.blue_theme_version}" \
      wordpress:latest

    # Install gcsfuse and mount the GCS Bucket
    sudo apt-get install -y curl lsb-release
    export GCSFUSE_REPO=gcsfuse-`lsb_release -c -s`
    echo "deb [signed-by=/usr/share/keyrings/cloud.google.asc] https://packages.cloud.google.com/apt $GCSFUSE_REPO main" | sudo tee /etc/apt/sources.list.d/gcsfuse.list
    curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo tee /usr/share/keyrings/cloud.google.asc
    sudo apt-get update -y
    sudo apt-get install -y gcsfuse
    
    # Create the gcsfuse directory and mount it. 
    mkdir -p /var/www/html/wp-content/uploads
    gcsfuse --implicit-dirs "${google_storage_bucket.wp_uploads.name}" /var/www/html/wp-content/uploads
  EOT

  disk {
    source_image = var.disk_image
    auto_delete  = true
    boot         = true
  }

  network_interface {
    network = var.vpc_network_name
    access_config {
      nat_ip = google_compute_address.static_ip_blue.address
    } 
  }
  
  service_account {
    # Add google apis to the instance scope so it can write to the bucket. 
    scopes = ["storage-rw"]
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "google_compute_instance_group_manager" "blue_mig" {
  name               = "wp-blue-mig"
  base_instance_name = "wp-blue"
  zone               = var.zone
  target_size        = 2

  version {
    instance_template = google_compute_instance_template.blue_template.id
  }

  named_port {
    name = "http"
    port = 80
  }
}

# -----------------------------------------------------------------
# GREEN INFRASTRUCTURE
# -----------------------------------------------------------------

resource "google_compute_address" "static_ip_green" {
  name = "wordpress-ip-green"
  region = var.region
}
resource "google_compute_instance_template" "green_template" {
  name_prefix  = "wp-green-template-"
  machine_type = "e2-medium"

  # Crucial for isolating firewall rules
  tags = ["wordpress-server"]

  metadata_startup_script = <<-EOT
    #!/bin/bash
    # Update package lists
    apt-get update -y

    # Install Docker GPG key
    apt-get install -y apt-transport-https ca-certificates curl software-properties-common
    install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
    chmod a+r /etc/apt/keyrings/docker.asc

    # Add Docker GPG repository to apt sources:
    sudo tee /etc/apt/sources.list.d/docker.sources <<EOF
    Types: deb
    URIs: https://download.docker.com/linux/debian
    Suites: $(. /etc/os-release && echo "$VERSION_CODENAME")
    Components: stable
    Architectures: $(dpkg --print-architecture)
    Signed-By: /etc/apt/keyrings/docker.asc
    EOF

    apt-get update -y
    apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

    # Inject Theme configuration dynamically and run WordPress container
    # (Assuming you are passing var.blue_theme_version to your application container)
    docker run -d --name wordpress-blue -p 80:80 \
      -e WORDPRESS_THEME_VERSION="${var.green_theme_version}" \
      wordpress:latest

    # Install gcsfuse and mount the GCS Bucket
    sudo apt-get install -y curl lsb-release
    export GCSFUSE_REPO=gcsfuse-`lsb_release -c -s`
    echo "deb [signed-by=/usr/share/keyrings/cloud.google.asc] https://packages.cloud.google.com/apt $GCSFUSE_REPO main" | sudo tee /etc/apt/sources.list.d/gcsfuse.list
    curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo tee /usr/share/keyrings/cloud.google.asc
    sudo apt-get update -y
    sudo apt-get install -y gcsfuse
    
    # Create the gcsfuse directory and mount it. 
    mkdir -p /var/www/html/wp-content/uploads
    gcsfuse --implicit-dirs "${google_storage_bucket.wp_uploads.name}" /var/www/html/wp-content/uploads
  EOT

  disk {
    source_image = var.disk_image
    auto_delete  = true
    boot         = true
  }

  network_interface {
    network = var.vpc_network_name
    access_config {
      nat_ip = google_compute_address.static_ip_green.address
    }
  }

  service_account {
    # Add google apis to the instance scope so it can write to the bucket. 
    scopes = ["storage-rw"]
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "google_compute_instance_group_manager" "green_mig" {
  name               = "wp-green-mig"
  base_instance_name = "wp-green"
  zone               = var.zone
  target_size        = 2

  version {
    instance_template = google_compute_instance_template.green_template.id
  }

  named_port {
    name = "http"
    port = 80
  }
}

 output "public_ip" {
  value = google_compute_global_forwarding_rule.wp_lb.ip_address
 }

output "green_ip" {
  value = google_compute_address.static_ip_green.address
}

output "blue_ip" {
  value = google_compute_address.static_ip_blue.address
}

output "active_stack" {
  value = var.active_env
}