
locals {
  aws_region = "us-east-1"
}

module "infrastructure" {
  source = "git::https://gitlab.com/meltano/infra/terraform.git//aws/modules/infrastructure"
  aws_region = local.aws_region
}

locals {
  inventory = {
    aws = {
      region = module.infrastructure.aws_region
    }
    airflow_database = module.infrastructure.airflow_database
    airflow_registry = {
      repository_url = module.infrastructure.airflow_registry.repository_url
    }
    kubernetes_cluster = {
      namespace              = module.infrastructure.kubernetes_cluster.namespace
      cluster_id             = module.infrastructure.kubernetes_cluster.cluster_id
      cluster_endpoint       = module.infrastructure.kubernetes_cluster.cluster_endpoint
      storage                = module.infrastructure.kubernetes_cluster.storage
    }
    meltano_database = module.infrastructure.meltano_database
    meltano_registry = {
      repository_url = module.infrastructure.meltano_registry.repository_url
    }
  }
}

resource "aws_ssm_parameter" "inventory" {
  name  = "/prod/meltano/inventory"
  type  = "SecureString"
  value = jsonencode(local.inventory)
}