locals {
  name            = "eks-${random_string.suffix.result}"
  cluster_version = "1.21"
  region          = "us-east-1"
  vpc_cidr = "10.0.0.0/16"
  rds_port = 5432
}