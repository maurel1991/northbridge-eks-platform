# Exposed to confirm that layer 3 can read the EKS layer.
output "cluster_name" {
  description = "Cluster name read from the EKS layer"
  value       = data.terraform_remote_state.eks.outputs.cluster_name
}