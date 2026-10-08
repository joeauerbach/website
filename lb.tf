resource "google_compute_backend_service" "wordpress_backend" {
  name        = "wordpress-backend-service"
  protocol    = "HTTP"
  port_name   = "http"
  timeout_sec = 30

  # Dynamically pick the MIG based on active_stack variable
  backend {
    group = var.active_stack == "blue" ? google_compute_region_instance_group_manager.mig["blue"].instance_group : google_compute_region_instance_group_manager.mig["green"].instance_group
  }

  health_checks = [google_compute_http_health_check.default.id]
}

resource "google_compute_http_health_check" "default" {
  name               = "wp-health-check"
  request_path       = "/"
  check_interval_sec = 10
  timeout_sec        = 5
}