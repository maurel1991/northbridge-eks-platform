# Namespace for the monitoring stack (Prometheus, Grafana, Alertmanager).
resource "kubernetes_namespace_v1" "monitoring" {
  metadata {
    name = "monitoring"
  }
}

# Random Grafana admin password (option A). It lives in the Terraform state
# (encrypted in S3) and in a Kubernetes secret, never in Git.
resource "random_password" "grafana_admin" {
  length  = 32
  special = false
}

# Secret read by Grafana through admin.existingSecret (set in the next step).
resource "kubernetes_secret_v1" "grafana_admin" {
  metadata {
    name      = "grafana-admin"
    namespace = kubernetes_namespace_v1.monitoring.metadata[0].name
  }

  data = {
    "admin-user"     = "admin"
    "admin-password" = random_password.grafana_admin.result
  }
}