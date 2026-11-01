# Read the outputs of layer 2 (EKS) from its remote state.
# Read-only: this layer can never modify the cluster layer's state.
data "terraform_remote_state" "eks" {
  backend = "s3"

  config = {
    bucket = var.state_bucket
    key    = "${var.environment}/02-eks/terraform.tfstate"
    region = var.region
  }
}