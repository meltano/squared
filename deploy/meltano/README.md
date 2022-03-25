<!-- BEGIN_TF_DOCS -->
# Meltano Squared - Meltano

Terraform module to deploy our Meltano Project.

## Usage

This module is deployed automatically during [CI/CD](.gitlab-ci.yml).

## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 3.65.0 |
| <a name="provider_random"></a> [random](#provider\_random) | 3.1.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_meltano"></a> [meltano](#module\_meltano) | git::https://gitlab.com/meltano/infra/terraform.git//kubernetes/modules/meltano | v0.1.0 |

## Resources

| Name | Type |
|------|------|
| [aws_ssm_parameter.superset_admin](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssm_parameter) | resource |
| [random_password.superset_password](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/password) | resource |
| [aws_eks_cluster.eks](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/eks_cluster) | data source |
| [aws_eks_cluster_auth.eks](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/eks_cluster_auth) | data source |
| [aws_ssm_parameter.airflow_fernet_key](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ssm_parameter) | data source |
| [aws_ssm_parameter.airflow_webserver_secret](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ssm_parameter) | data source |
| [aws_ssm_parameter.inventory](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ssm_parameter) | data source |
| [aws_ssm_parameter.meltano_env_file](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ssm_parameter) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_airflow_image_tag"></a> [airflow\_image\_tag](#input\_airflow\_image\_tag) | n/a | `string` | `"latest"` | no |
| <a name="input_meltano_image_tag"></a> [meltano\_image\_tag](#input\_meltano\_image\_tag) | n/a | `string` | `"latest"` | no |

## Outputs

No outputs.
<!-- END_TF_DOCS -->