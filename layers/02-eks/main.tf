module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "21.29.0" # pinned exactly, upgraded deliberately

  name               = var.cluster_name
  kubernetes_version = var.kubernetes_version

  # Network: control plane ENIs (and later the nodes) live in the private subnets.
  vpc_id     = data.terraform_remote_state.network.outputs.vpc_id
  subnet_ids = data.terraform_remote_state.network.outputs.private_subnet_ids

  # API endpoint: reachable from inside the VPC and from the allowed CIDRs only.
  endpoint_private_access      = true
  endpoint_public_access       = true
  endpoint_public_access_cidrs = var.api_allowed_cidrs

  # Gives the identity running Terraform admin rights on the cluster (access entry).
  enable_cluster_creator_admin_permissions = true
  # Core add-ons. before_compute installs the networking pieces before the
  # nodes boot, so the nodes can become Ready right away.
  addons = {
    coredns                = {}
    kube-proxy             = {}
    eks-pod-identity-agent = { before_compute = true }
    vpc-cni                = { before_compute = true }
  }

  # Managed node group: with 3 private subnets (one per AZ), AWS balances
  # the 3 nodes across the 3 zones.
  eks_managed_node_groups = {
    general = {
      ami_type       = "AL2023_x86_64_STANDARD"
      instance_types = ["t3.medium"]

      min_size     = 3
      max_size     = 6
      desired_size = 3
    }
  }
}