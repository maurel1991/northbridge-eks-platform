variable "region" {
  description = "AWS region where the Terraform state bucket is created"
  type        = string
}

variable "bucket_name" {
  description = "Name of the S3 bucket that stores the Terraform state (must be globally unique)"
  type        = string
}

variable "project" {
  description = "Project name (used for the Project tag)"
  type        = string
}

variable "owner" {
  description = "Owner of the resources (used for the Owner tag)"
  type        = string
}

variable "cost_center" {
  description = "Cost center (used for the CostCenter tag)"
  type        = string
}