<!-- BEGIN_TF_DOCS -->
# Meltano Squared - Infrastructure

Terraform module to deploy base infrastructure to support our Meltano Project and data platform.

## Usage

This module is intended to be deployed manually, no by CI/CD. This is because our infrastructure is stateful, moves slowley and requires operator oversight to review the outputs of `terraform plan` and be sure of the changes.

In order to `plan` and `apply` changes, you will need access to the `tf_data` IAM user in our 'Data' AWS account. Details of AWS onboarding are [in the handbook]().

## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 3.65.0 |
| <a name="provider_aws.us_west_2"></a> [aws.us\_west\_2](#provider\_aws.us\_west\_2) | 3.65.0 |
| <a name="provider_template"></a> [template](#provider\_template) | 2.2.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_client_vpn"></a> [client\_vpn](#module\_client\_vpn) | ../modules/client_vpn | n/a |
| <a name="module_infrastructure"></a> [infrastructure](#module\_infrastructure) | git::https://gitlab.com/meltano/infra/terraform.git//aws/modules/infrastructure | v0.1.0 |

## Resources

| Name | Type |
|------|------|
| [aws_iam_policy.allow_s3_read_assess_to_snowflake](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_role.snowflake_read_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy_attachment.snowflake_read_role_policy_attachment](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_s3_bucket.snowcat](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) | resource |
| [aws_s3_bucket_notification.bucket_notification](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_notification) | resource |
| [aws_s3_bucket_policy.allow_access_from_snowcat_account](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_policy) | resource |
| [aws_ssm_parameter.inventory](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssm_parameter) | resource |
| [aws_acm_certificate.vpn_client](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/acm_certificate) | data source |
| [aws_acm_certificate.vpn_server](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/acm_certificate) | data source |
| [aws_ssm_parameter.snowpipe](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ssm_parameter) | data source |
| [template_file.snowflake_trust_policy_template](https://registry.terraform.io/providers/hashicorp/template/latest/docs/data-sources/file) | data source |

## Inputs

No inputs.

## Outputs

No outputs.
<!-- END_TF_DOCS -->