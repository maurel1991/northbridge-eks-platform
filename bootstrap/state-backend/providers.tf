provider "aws" {
  region = var.region

  # Tags applied automatically to every resource created by this provider
  default_tags {
    tags = {
      Project     = var.project
      Environment = "shared"
      Owner       = var.owner
      CostCenter  = var.cost_center
    }
  }
}