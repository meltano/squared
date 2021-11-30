
module "db_security_group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "4.7.0"

  name        = "meltano_db_security_group"
  description = "Security group for Meltano platform RDS database"
  vpc_id      = module.vpc.vpc_id

  ingress_cidr_blocks      = module.vpc.private_subnets
  ingress_with_source_security_group_id = [
    {
      from_port                = local.rds_port
      to_port                  = local.rds_port
      protocol                 = "tcp"
      description              = "Custom Postgres Port"
      source_security_group_id = module.eks_worker_additional_security_group.security_group_id
    }
  ]
}

module "db" {
  source  = "terraform-aws-modules/rds/aws"
  version = "~> 3.0"

  identifier = "meltanodb"

  engine            = "postgres"
  engine_version    = "13.4"
  instance_class    = "db.t4g.micro"
  allocated_storage = 10

  name     = "meltano"
  username = "meltano"
  port     = local.rds_port
  create_random_password = true
  iam_database_authentication_enabled = false

  vpc_security_group_ids = [module.db_security_group.security_group_id]

  maintenance_window = "Sun:00:00-Sun:03:00"
  backup_window      = "03:00-06:00"

  # Enhanced Monitoring
  create_monitoring_role = false

  tags = {
    GitlabRepo = "squared"
    GitlabOrg  = "meltano"
  }

  # DB subnet group
  subnet_ids = module.vpc.private_subnets

  # DB parameter group
  family = "postgres13"

  # DB option group
  major_engine_version = "13.4"

  # Database Deletion Protection
  deletion_protection = true

  parameters = []

  options = []
}

locals {
  meltano_db_credentials = {
    host = module.db.db_instance_endpoint
    port = module.db.db_instance_port
    user = module.db.db_instance_username
    password = module.db.db_instance_password
    database = module.db.db_instance_name
    url = "postgresql://${module.db.db_instance_username}:${module.db.db_instance_password}@${module.db.db_instance_endpoint}:${module.db.db_instance_port}/${module.db.db_instance_name}"
  }
}

resource "aws_ssm_parameter" "meltano_db_credentials" {
  name  = "/prod/meltano/db_credentials"
  type  = "SecureString"
  value = jsonencode(local.meltano_db_credentials)
}

module "airflow_db" {
  source  = "terraform-aws-modules/rds/aws"
  version = "~> 3.0"

  identifier = "airflowdb"

  engine            = "postgres"
  engine_version    = "13.4"
  instance_class    = "db.t4g.micro"
  allocated_storage = 10

  name     = "airflow"
  username = "airflow"
  port     = local.rds_port
  create_random_password = true
  iam_database_authentication_enabled = false

  vpc_security_group_ids = [module.db_security_group.security_group_id]

  maintenance_window = "Sun:00:00-Sun:03:00"
  backup_window      = "03:00-06:00"

  # Enhanced Monitoring
  create_monitoring_role = false

  tags = {
    GitlabRepo = "squared"
    GitlabOrg  = "meltano"
  }

  # DB subnet group
  subnet_ids = module.vpc.private_subnets

  # DB parameter group
  family = "postgres13"

  # DB option group
  major_engine_version = "13.4"

  # Database Deletion Protection
  deletion_protection = true

  parameters = []

  options = []
}

locals {
  airflow_db_credentials = {
    host = module.airflow_db.db_instance_address
    port = module.airflow_db.db_instance_port
    user = module.airflow_db.db_instance_username
    password = module.airflow_db.db_instance_password
    database = module.airflow_db.db_instance_name
  }
}

resource "aws_ssm_parameter" "airflow_db" {
  name  = "/prod/meltano/airflow/db_credentials"
  type  = "SecureString"
  value = jsonencode(local.airflow_db_credentials)
}