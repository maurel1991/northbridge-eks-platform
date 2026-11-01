# Partial backend configuration: bucket, region, encryption and locking
# come from envs/<env>/backend.hcl, and the state key is passed at init time.
terraform {
  backend "s3" {}
}