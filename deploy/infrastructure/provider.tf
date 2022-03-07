provider "aws" {
  region = local.aws_region
}

provider "aws" {
  alias  = "us_west_2"
  region = "us-west-2"
}