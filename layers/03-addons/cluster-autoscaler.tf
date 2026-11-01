# Cluster Autoscaler: adds nodes when pods cannot be scheduled and removes unneeded nodes.
# Its IAM role and Pod Identity association are created in layer 2.
resource "helm_release" "cluster_autoscaler" {
  name       = "cluster-autoscaler"
  namespace  = "kube-system"
  repository = "https://kubernetes.github.io/autoscaler"
  chart      = "cluster-autoscaler"
  version    = var.cluster_autoscaler_chart_version

  values = [
    yamlencode({
      fullnameOverride = "cluster-autoscaler"
      awsRegion        = var.region

      # Finds the node groups through the tags k8s.io/cluster-autoscaler/enabled
      # and k8s.io/cluster-autoscaler/<cluster name>, added by EKS managed node groups.
      autoDiscovery = {
        clusterName = local.cluster_name
      }

      # The service account name must match the Pod Identity association in layer 2.
      rbac = {
        serviceAccount = {
          create = true
          name   = "cluster-autoscaler"
        }
      }

      extraArgs = {
        "balance-similar-node-groups" = true
        "skip-nodes-with-system-pods" = false
      }
    })
  ]

  wait    = true
  atomic  = true
  timeout = 300
}