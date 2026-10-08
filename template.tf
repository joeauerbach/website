resource "google_compute_instance_template" "wp_template" {
  for_each    = toset(["blue", "green"])
  name_prefix = "wordpress-${each.key}-tpl-"
  machine_type = "e2-medium"

  disk {
    source_image = "debian-cloud/debian-12"
    auto_delete  = true
    boot         = true
  }

  network_interface {
    network = google_compute_network.vpc.name
    access_config {
        nat_ip = google_compute_address.static_ip_[each.key].address
    }
  }

  metadata_startup_script = <<-EOF
    #!/bin/bash
    apt-get update
    apt-get install -y apache2 php php-mysql wordpress
    # Configure wp-config.php with Cloud SQL credentials and stack name (${each.key})
  EOF

  lifecycle {
    create_before_destroy = true
  }
}