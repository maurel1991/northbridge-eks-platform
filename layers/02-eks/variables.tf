variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name (dev, staging, prod). Used to locate the matching network state."
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
variable "cluster_name" {
  description = "EKS cluster name. Must match the cluster_name used by the network layer for the subnet tags."
  type        = string
}

variable "kubernetes_version" {
  description = "Kubernetes version of the EKS control plane (pinned, upgraded deliberately)"
  type        = string
}
variable "api_allowed_cidrs" {
  description = "CIDR blocks allowed to reach the public EKS API endpoint (use your own public IP as /32)"
  type        = list(string)
}
variable "dns_zone_name" {
  description = "Route 53 public hosted zone that ExternalDNS is allowed to manage"
  type        = string
}