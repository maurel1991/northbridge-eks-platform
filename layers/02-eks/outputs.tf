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