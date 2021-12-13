terraform {
  backend "s3" {
    bucket         = "tf-remote-state20211115155239304300000004"
    dynamodb_table = "tf-remote-state-lock"
    encrypt        = true
    key            = "squared_infrastructure/terraform.tfstate"
    region         = "us-east-1"
  }
}