locals {
  name            = "fargate-${random_string.suffix.result}"
  cluster_version = "1.21"
  region          = "us-east-1"
}