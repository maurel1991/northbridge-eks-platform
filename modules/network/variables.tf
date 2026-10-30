variable "name" {
  description = "Name prefix used for the network resources (for example: northbridge-dev)"
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
  description = "If true, use one shared NAT gateway (cheaper, for dev). If false, use one NAT gateway per AZ (high availability)"
  type        = bool
  default     = true
}

variable "cluster_name" {
  description = "Name of the EKS cluster, used for the Kubernetes subnet tags"
  type        = string
}