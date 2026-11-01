# Cluster connection details, read from the EKS layer's remote state.
locals {
  cluster_name     = data.terraform_remote_state.eks.outputs.cluster_name
  cluster_endpoint = data.terraform_remote_state.eks.outputs.cluster_endpoint
  cluster_ca       = base64decode(data.terraform_remote_state.eks.outputs.cluster_certificate_authority_data)
}

provider "aws" {
  region = var.region

  # Applied automatically to every taggable AWS resource in this layer.
  default_tags {
    tags = {
      Project     = var.project
      Environment = var.environment
      Owner       = var.owner
      CostCenter  = var.cost_center
    }
  }
}

# Helm provider v3: "kubernetes" and "exec" are attributes (with "="), not blocks.
provider "helm" {
  kubernetes = {
    host                   = local.cluster_endpoint
    cluster_ca_certificate = local.cluster_ca

    # Short-lived token, requested from AWS each time Terraform talks to the cluster.
    exec = {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args        = ["eks", "get-token", "--cluster-name", local.cluster_name, "--region", var.region]
    }
  }
}

provider "kubernetes" {
  host                   = local.cluster_endpoint
  cluster_ca_certificate = local.cluster_ca

  # Kubernetes provider: "exec" is a block (no "="), unlike the Helm provider v3.
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args        = ["eks", "get-token", "--cluster-name", local.cluster_name, "--region", var.region]
  }
}