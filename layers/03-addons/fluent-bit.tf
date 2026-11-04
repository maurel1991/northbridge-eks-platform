# Fluent Bit: runs on every node, reads container logs and ships them to CloudWatch Logs.
# Its IAM role and Pod Identity association are created in layer 2 (namespace and
# service account names below must match them).
resource "helm_release" "fluent_bit" {
  name             = "fluent-bit"
  namespace        = "logging"
  create_namespace = true
  repository       = "https://fluent.github.io/helm-charts"
  chart            = "fluent-bit"
  version          = var.fluent_bit_chart_version

  values = [
    yamlencode({
      serviceAccount = {
        create = true
        name   = "fluent-bit"
      }

      resources = {
        requests = { cpu = "50m", memory = "64Mi" }
      }

      # The chart's default inputs and Kubernetes filter are kept (they tag logs "kube.*").
      # Only the output is replaced: container logs go to the CloudWatch log group
      # created in layer 2 (name: /<cluster name>/containers).
      config = {
        outputs = <<-EOT
          [OUTPUT]
              Name                cloudwatch_logs
              Match               kube.*
              region              ${var.region}
              log_group_name      /${local.cluster_name}/containers
              log_stream_prefix   fluent-bit-
              auto_create_group   false
        EOT
      }
    })
  ]

  wait    = true
  atomic  = true
  timeout = 300
}