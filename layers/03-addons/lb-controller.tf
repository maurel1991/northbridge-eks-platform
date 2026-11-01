# AWS Load Balancer Controller: creates ALBs and NLBs from Ingress and Service objects.
# Its IAM role and Pod Identity association are created in layer 2.
# The chart version must install the same controller version as the IAM policy (v3.6.2).
resource "helm_release" "lb_controller" {
  name       = "aws-load-balancer-controller"
  namespace  = "kube-system"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  version    = var.lb_controller_chart_version

  values = [
    yamlencode({
      clusterName = local.cluster_name
      region      = var.region
      vpcId       = data.terraform_remote_state.eks.outputs.vpc_id

      # The service account name must match the Pod Identity association in layer 2.
      serviceAccount = {
        create = true
        name   = "aws-load-balancer-controller"
      }
    })
  ]

  wait    = true
  atomic  = true
  timeout = 300
}