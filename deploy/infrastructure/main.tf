/**
* # Meltano Squared - Infrastructure
*
* Terraform module to deploy base infrastructure to support our Meltano Project and data platform.
*
* ## Usage
*
* This module is intended to be deployed manually, no by CI/CD. This is because our infrastructure is stateful, moves slowley and requires operator oversight to review the outputs of `terraform plan` and be sure of the changes.
*
* In order to `plan` and `apply` changes, you will need access to the `tf_data` IAM user in our 'Data' AWS account. Details of AWS onboarding are [in the handbook]().
*/

locals {
  aws_region = "us-east-1"
}
