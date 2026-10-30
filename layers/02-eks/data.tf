# Read the outputs of layer 1 (network) from its remote state.
# This is read-only: layer 2 can never modify the network state.
data "terraform_remote_state" "network" {
  backend = "s3"

  config = {
    bucket = var.state_bucket
    key    = "${var.environment}/01-network/terraform.tfstate"
    region = var.region
  }
}