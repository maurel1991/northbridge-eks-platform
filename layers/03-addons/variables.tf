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