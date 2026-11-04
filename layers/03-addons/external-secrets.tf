# External Secrets Operator: syncs secrets from AWS Secrets Manager into Kubernetes.
# Its IAM role and Pod Identity association are created in layer 2 (namespace and
# service account names below must match them).
resource "helm_release" "external_secrets" {
  name             = "external-secrets"
  namespace        = "external-secrets"
  create_namespace = true
  repository       = "https://charts.external-secrets.io"
  chart            = "external-secrets"
  version          = var.external_secrets_chart_version

  values = [
    yamlencode({
      installCRDs = true

      serviceAccount = {
        create = true
        name   = "external-secrets"
      }
    })
  ]

  wait    = true
  atomic  = true
  timeout = 300
}