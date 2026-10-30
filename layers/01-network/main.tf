module "network" {
  source = "../../modules/network"

  name         = "${var.project}-${var.environment}"
  cluster_name = var.cluster_name

  vpc_cidr             = var.vpc_cidr
  azs                  = var.azs
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  single_nat_gateway   = var.single_nat_gateway
}