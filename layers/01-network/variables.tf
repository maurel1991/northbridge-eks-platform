variable "region" {
  description = "AWS region where the network is created"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, staging, prod, dr)"
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

variable "vpc_cidr" {
  description = "CIDR block of the VPC"
  type        = string
}

variable "azs" {
  description = "List of Availability Zones to use (3 for high availability)"
  type        = list(string)
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks of the public subnets, one per Availability Zone"
  type        = list(string)
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks of the private subnets, one per Availability Zone"
  type        = list(string)
}

variable "single_nat_gateway" {
  description = "If true, use one shared NAT gateway (dev). If false, one per AZ (prod)"
  type        = bool
  default     = true
}

variable "cluster_name" {
  description = "Name of the EKS cluster, used for the Kubernetes subnet tags"
  type        = string
}