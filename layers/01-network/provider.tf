provider "aws" {
  region = var.region

  # Tags applied automatically to every resource created in this layer
  default_tags {
    tags = {
      Project     = var.project
      Environment = var.environment
      Owner       = var.owner
      CostCenter  = var.cost_center
    }
  }
}