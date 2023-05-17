terraform {
  backend "s3" {
    bucket         = "tf-remote-state20211115155239304300000004"
    dynamodb_table = "tf-remote-state-lock"
    encrypt        = true
    key            = "squared_infrastructure/terraform.tfstate"
    region         = "us-east-1"
  }
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "< 4.0.0"
    }
  }
}
