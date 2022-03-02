provider "aws" {
  region = local.aws_region
}

provider "aws" {
  alias = "us-west-2"
  region = "us-west-2"
}