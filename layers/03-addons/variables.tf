variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name (dev, staging, prod). Used to locate the matching EKS state."
  type        = string
}

variable "state_bucket" {
  description = "S3 bucket that stores the Terraform state files"
  type        = string
}

variable "project" {
  description = "Project name, applied as the Project tag"
  type        = string
}

variable "owner" {
  description = "Owner of the resources, applied as the Owner tag"
  type        = string
}

variable "cost_center" {
  description = "Cost center, applied as the CostCenter tag"
  type        = string
}
variable "ebs_csi_addon_version" {
  description = "Pinned version of the aws-ebs-csi-driver EKS add-on"
  type        = string
}
variable "efs_csi_addon_version" {
  description = "Pinned version of the aws-efs-csi-driver EKS add-on"
  type        = string
}
variable "metrics_server_chart_version" {
  description = "Pinned version of the metrics-server Helm chart"
  type        = string
}
variable "lb_controller_chart_version" {
  description = "Pinned version of the aws-load-balancer-controller Helm chart (must match the IAM policy version)"
  type        = string
}
variable "cluster_autoscaler_chart_version" {
  description = "Pinned version of the cluster-autoscaler Helm chart (its app version must match the Kubernetes minor version)"
  type        = string
}