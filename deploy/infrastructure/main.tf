
locals {
  aws_region = "us-east-1"
}

module "infrastructure" {
  source = "git::https://gitlab.com/meltano/infra/terraform.git//aws/modules/infrastructure"
  # source = "../../../infrastructure/terraform/aws/modules/infrastructure"
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
      namespace        = module.infrastructure.kubernetes_cluster.namespace
      cluster_id       = module.infrastructure.kubernetes_cluster.cluster_id
      cluster_endpoint = module.infrastructure.kubernetes_cluster.cluster_endpoint
      storage          = module.infrastructure.kubernetes_cluster.storage
    }
    meltano_database = module.infrastructure.meltano_database
    meltano_registry = {
      repository_url = module.infrastructure.meltano_registry.repository_url
    }
    superset_database = module.infrastructure.superset_database
  }
}

resource "aws_ssm_parameter" "inventory" {
  name  = "/prod/meltano/inventory"
  type  = "SecureString"
  value = jsonencode(local.inventory)
}

data "aws_acm_certificate" "vpn_server" {
  domain   = "server.aws-vpn.meltano.com"
  statuses = ["ISSUED"]
}


data "aws_acm_certificate" "vpn_client" {
  domain   = "client.aws-vpn.meltano.com"
  statuses = ["ISSUED"]
}

module "client-vpn" {
  source            = "../modules/client-vpn"
  region            = local.aws_region
  client_cidr_block = "10.22.0.0/22"
  vpc_id            = module.infrastructure.vpc.vpc_id
  subnet_id         = module.infrastructure.vpc.private_subnets // ["subnet-*****", "subnet-*****"] // central-backend w/ route table 0.0.0.0/0 which has central-public EIPs
  domain            = "aws-vpn.meltano.com"
  server_cert       = data.aws_acm_certificate.vpn_server.arn
  client_cert       = data.aws_acm_certificate.vpn_client.arn
  split_tunnel      = "true"
}