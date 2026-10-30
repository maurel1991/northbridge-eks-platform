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