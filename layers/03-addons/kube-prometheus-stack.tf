# kube-prometheus-stack: Prometheus (metrics), Grafana (dashboards) and exporters.
# Sized for a small dev cluster (3 x t3.medium).
resource "helm_release" "kube_prometheus_stack" {
  name       = "kube-prometheus-stack"
  namespace  = kubernetes_namespace_v1.monitoring.metadata[0].name
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  version    = var.kube_prometheus_stack_chart_version

  values = [
    yamlencode({
      prometheus = {
        prometheusSpec = {
          retention = "7d"

          # Also pick up ServiceMonitors and PodMonitors that were not installed by this chart.
          serviceMonitorSelectorNilUsesHelmValues = false
          podMonitorSelectorNilUsesHelmValues     = false

          resources = {
            requests = { cpu = "200m", memory = "512Mi" }
          }

          # Metrics are stored on an encrypted gp3 EBS volume.
          storageSpec = {
            volumeClaimTemplate = {
              spec = {
                storageClassName = "gp3"
                accessModes      = ["ReadWriteOnce"]
                resources        = { requests = { storage = "10Gi" } }
              }
            }
          }
        }
      }

      grafana = {
        # Admin credentials come from the secret created in monitoring.tf.
        admin = {
          existingSecret = "grafana-admin"
          userKey        = "admin-user"
          passwordKey    = "admin-password"
        }

        persistence = {
          enabled          = true
          storageClassName = "gp3"
          size             = "5Gi"
        }

        service = { type = "ClusterIP" }

        resources = {
          requests = { cpu = "100m", memory = "256Mi" }
        }
      }

      # Alertmanager is not needed for now; it can be enabled later.
      alertmanager = { enabled = false }

      # On EKS the control plane is managed by AWS and not reachable for scraping.
      # Disabling these avoids permanently failing targets and false alerts.
      kubeControllerManager = { enabled = false }
      kubeScheduler         = { enabled = false }
      kubeEtcd              = { enabled = false }
      kubeProxy             = { enabled = false }
    })
  ]

  wait    = true
  atomic  = true
  timeout = 600

  depends_on = [kubernetes_secret_v1.grafana_admin]
}