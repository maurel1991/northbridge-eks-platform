# Exposed to confirm that layer 2 can read the network layer.
output "vpc_id" {
  description = "VPC ID read from the network layer"
  value       = data.terraform_remote_state.network.outputs.vpc_id
}

output "private_subnet_ids" {
  description = "Private subnet IDs read from the network layer"
  value       = data.terraform_remote_state.network.outputs.private_subnet_ids
}
output "efs_file_system_id" {
  description = "EFS file system ID, used later by the EFS CSI driver StorageClass"
  value       = aws_efs_file_system.this.id
}
output "cluster_name" {
  description = "EKS cluster name, read by the add-ons layer"
  value       = module.eks.cluster_name
}

output "cluster_endpoint" {
  description = "EKS API server endpoint, read by the add-ons layer"
  value       = module.eks.cluster_endpoint
}

output "cluster_certificate_authority_data" {
  description = "Base64 CA certificate of the cluster, read by the add-ons layer"
  value       = module.eks.cluster_certificate_authority_data
}