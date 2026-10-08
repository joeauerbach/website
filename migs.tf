resource "google_compute_region_instance_group_manager" "mig" {
  for_each = toset(["blue", "green"])
  name     = "wordpress-mig-${each.key}"
  region   = var.region

  version {
    instance_template = google_compute_instance_template.wp_template[each.key].id
  }

  base_instance_name = "wp-${each.key}"
  target_size        = 2

  named_port {
    name = "http"
    port = 80
  }
}