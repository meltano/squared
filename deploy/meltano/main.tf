locals {
  aws_region = "us-east-1"
}

data "aws_ssm_parameter" "inventory" {
  name = "/prod/meltano/inventory"
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

locals {
  inventory = jsondecode(data.aws_ssm_parameter.inventory.value)
}

module "meltano" {
  source = "git::https://gitlab.com/meltano/infra/terraform.git//kubernetes/modules/meltano"
  # source = "../../../infrastructure/terraform/kubernetes/modules/meltano"
  # aws
  aws_region = local.inventory.aws.region
  # airflow
  airflow_fernet_key = data.aws_ssm_parameter.airflow_fernet_key.value
  airflow_image_repository_url = local.inventory.airflow_registry.repository_url
  airflow_image_tag = var.airflow_image_tag
  airflow_logs_pvc_claim_name = local.inventory.kubernetes_cluster.storage.logs_storage_claim_name
  airflow_meltano_project_root = "/opt/airflow/meltano"
  airflow_webserver_secret_key = data.aws_ssm_parameter.airflow_webserver_secret.value
  # airflow database
  airflow_db_database = local.inventory.airflow_database.database
  airflow_db_host = local.inventory.airflow_database.host
  airflow_db_password = local.inventory.airflow_database.password
  airflow_db_port = local.inventory.airflow_database.port
  airflow_db_protocol = local.inventory.airflow_database.protocol
  airflow_db_user = local.inventory.airflow_database.user
  airflow_db_uri = "${local.inventory.airflow_database.url}?sslmode=disable"
  # k8 cluster
  kubernetes_cluster_ca_certificate = base64decode(data.aws_eks_cluster.eks.certificate_authority[0].data)
  kubernetes_cluster_endpoint = data.aws_eks_cluster.eks.endpoint
  kubernetes_cluster_token = data.aws_eks_cluster_auth.eks.token
  kubernetes_namespace = local.inventory.kubernetes_cluster.namespace
  # meltano
  meltano_db_uri = "${local.inventory.meltano_database.url}?sslmode=disable"
  meltano_image_repository_url = local.inventory.meltano_registry.repository_url
  meltano_image_tag = var.meltano_image_tag
  meltano_env_file = data.aws_ssm_parameter.meltano_env_file.value
}