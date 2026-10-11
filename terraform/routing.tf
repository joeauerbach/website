# Health Check shared by both environments
# resource "google_compute_global_address" "lb_static_ip" {
#   name = "wp-lb-static-ip"
# }

# 2. Create a Google-Managed SSL Certificate
# resource "google_compute_managed_ssl_certificate" "wp_ssl" {
#   name = "wp-ssl-cert"

#   managed {
#     domains = ["yourdomain.com"] 
#   }
# }

resource "google_compute_health_check" "wp_health" {
  name               = "wp-health-check"
  check_interval_sec = 5
  timeout_sec        = 5

  http_health_check {
    port = 80
    request_path = "/wp-includes/images/blank.gif" # Safe endpoint that doesn't trigger heavy DB queries
  }
}

# Backend Service mapping traffic to the active stack via conditional local assignments
resource "google_compute_backend_service" "wp_backend" {
  name          = "wp-backend-service"
  protocol      = "HTTP"
  health_checks = [google_compute_health_check.wp_health.id]

  # Dynamic Backend Selection based on var.active_env
  backend {
    group = var.active_env == "blue" ? google_compute_instance_group_manager.blue_mig.instance_group : google_compute_instance_group_manager.green_mig.instance_group
  }

  params {
    
  }
}

# URL Map, Proxy, and Global Forwarding Rule for the Frontend
resource "google_compute_url_map" "wp_url_map" {
  name            = "wp-url-map"
  default_service = google_compute_backend_service.wp_backend.id
}

# https version for later
# resource "google_compute_url_map" "url_map" {
#   name            = "wp-lb-url-map"
#   default_service = var.active_stack == "blue" ? google_compute_backend_service.backend_blue.id : google_compute_backend_service.backend_green.id
# }

resource "google_compute_target_http_proxy" "wp_http_proxy" {
  name    = "wp-http-proxy"
  url_map = google_compute_url_map.wp_url_map.id
}

#https version for later
# resource "google_compute_target_https_proxy" "https_proxy" {
#   name             = "wp-https-proxy"
#   url_map          = google_compute_url_map.url_map.id
#   ssl_certificates = [google_compute_managed_ssl_certificate.wp_ssl.id]
# }

resource "google_compute_global_forwarding_rule" "wp_lb" {
  name       = "wp-frontend-rule"
  target     = google_compute_target_http_proxy.wp_http_proxy.id
  port_range = "80"
}

#https version for later
# resource "google_compute_global_forwarding_rule" "https_forwarding" {
#   name                  = "wp-https-forwarding"
#   target                = google_compute_target_https_proxy.https_proxy.id
#   port_range            = "443"
#   ip_address            = google_compute_global_address.lb_static_ip.address
#   load_balancing_scheme = "EXTERNAL_MANAGED"
# }

# =====================================================================
# THE REDIRECT: Force all Port 80 Traffic to Port 443
# ALL of this is for later. 
# =====================================================================

# 6. Redirect URL Map (Intercepts HTTP requests and responds with a 301 Redirect)
# resource "google_compute_url_map" "redirect_url_map" {
#   name = "wp-http-to-https-redirect"

#   default_url_redirect {
#     https_redirect         = true
#     strip_query            = false
#     redirect_response_code = "MOVED_PERMANENTLY_DEFAULT" # 301 Redirect
#   }
# }

# # 7. HTTP Target Proxy
# resource "google_compute_target_http_proxy" "http_proxy" {
#   name    = "wp-http-proxy"
#   url_map = google_compute_url_map.redirect_url_map.id
# }

# # 8. HTTP Global Forwarding Rule (Accepts traffic on 80 and passes to redirect map)
# resource "google_compute_global_forwarding_rule" "http_forwarding" {
#   name                  = "wp-http-forwarding"
#   target                = google_compute_target_http_proxy.http_proxy.id
#   port_range            = "80"
#   ip_address            = google_compute_global_address.lb_static_ip.address
#   load_balancing_scheme = "EXTERNAL_MANAGED"
# }