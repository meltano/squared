/**
* # Meltano Squared - Meltano
*
* Terraform module to deploy our Meltano Project.
*
* ## Usage
*
* This module is deployed automatically during [CI/CD](.gitlab-ci.yml).
*
*/

locals {
  aws_region = "us-east-1"
}

data "aws_ssm_parameter" "airflow_fernet_key" {
  name = "/prod/meltano/airflow/fernet_key"
}

data "aws_ssm_parameter" "airflow_webserver_secret" {
  name = "/prod/meltano/airflow/webserver_secret_key"
}

data "aws_ssm_parameter" "meltano_env_file" {
  name = "/prod/meltano/env_file"
}

data "aws_ssm_parameter" "inventory" {
  name = "/prod/meltano/inventory"
}

locals {
  inventory = jsondecode(data.aws_ssm_parameter.inventory.value)
}

resource "random_password" "superset_password" {
  length           = 25
  special          = true
  override_special = "_%@"
}

resource "aws_ssm_parameter" "superset_admin" {
  name  = "/prod/meltano/superset/admin_password"
  type  = "SecureString"
  value = random_password.superset_password.result
}

module "meltano" {
  source = "git::https://gitlab.com/meltano/infra/terraform.git//kubernetes/modules/meltano?ref=v0.1.0"
  # source = "../../../infrastructure/terraform/kubernetes/modules/meltano"
  # aws
  aws_region = local.inventory.aws.region
  # airflow
  airflow_fernet_key           = data.aws_ssm_parameter.airflow_fernet_key.value
  airflow_image_repository_url = local.inventory.airflow_registry.repository_url
  airflow_image_tag            = var.airflow_image_tag
  airflow_logs_pvc_claim_name  = local.inventory.kubernetes_cluster.storage.logs_storage_claim_name
  airflow_meltano_project_root = "/opt/airflow/meltano"
  airflow_webserver_secret_key = data.aws_ssm_parameter.airflow_webserver_secret.value
  # airflow database
  airflow_db_database = local.inventory.airflow_database.database
  airflow_db_host     = local.inventory.airflow_database.host
  airflow_db_password = local.inventory.airflow_database.password
  airflow_db_port     = local.inventory.airflow_database.port
  airflow_db_protocol = local.inventory.airflow_database.protocol
  airflow_db_user     = local.inventory.airflow_database.user
  airflow_db_uri      = local.inventory.airflow_database.url
  # k8 cluster
  kubernetes_cluster_ca_certificate = base64decode(data.aws_eks_cluster.eks.certificate_authority[0].data)
  kubernetes_cluster_endpoint       = data.aws_eks_cluster.eks.endpoint
  kubernetes_cluster_token          = data.aws_eks_cluster_auth.eks.token
  kubernetes_namespace              = local.inventory.kubernetes_cluster.namespace
  # meltano
  meltano_db_uri               = "${local.inventory.meltano_database.url}?sslmode=disable"
  meltano_image_repository_url = local.inventory.meltano_registry.repository_url
  meltano_image_tag            = var.meltano_image_tag
  meltano_env_file             = data.aws_ssm_parameter.meltano_env_file.value
  # superset
  superset_db_host        = local.inventory.superset_database.host
  superset_db_user        = local.inventory.superset_database.user
  superset_db_password    = local.inventory.superset_database.password
  superset_db_database    = local.inventory.superset_database.database
  superset_db_port        = local.inventory.superset_database.port
  superset_admin_password = random_password.superset_password.result
  superset_dependencies   = "'snowflake-connector-python==2.7.9' 'typing-extensions==4.3.0' 'snowflake-sqlalchemy==1.2.4'"
  superset_webserver_host = "internal-095a2699-meltano-superset-608a-2127736714.us-east-1.elb.amazonaws.com"
}
