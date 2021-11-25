locals {
  name            = "fargate-${random_string.suffix.result}"
  cluster_version = "1.21"
  region          = "us-east-1"
}

resource "aws_ssm_parameter" "db_url" {
  name  = "/prod/meltano/db_connection_string"
  type  = "SecureString"
  value = "postgresql://${module.db.db_instance_username}:${module.db.db_instance_password}@${module.db.db_instance_endpoint}:${module.db.db_instance_port}/"
}