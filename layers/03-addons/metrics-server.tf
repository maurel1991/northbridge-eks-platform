# Metrics Server: collects CPU and memory usage from the kubelets.
# Needed by "kubectl top" and, later, by the Horizontal Pod Autoscaler.
resource "helm_release" "metrics_server" {
  name       = "metrics-server"
  namespace  = "kube-system"
  repository = "https://kubernetes-sigs.github.io/metrics-server/"
  chart      = "metrics-server"
  version    = var.metrics_server_chart_version

  # Wait until the pods are ready, and roll back automatically if the install fails.
  wait   = true
  atomic = true

  timeout = 300
}