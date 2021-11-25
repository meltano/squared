
module "db_security_group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "4.7.0"

  name        = "meltano_db_security_group"
  description = "Security group for Meltano platform RDS database"
  vpc_id      = module.vpc.vpc_id

  ingress_cidr_blocks      = module.vpc.private_subnets
  computed_ingress_with_source_security_group_id = [
    {
      rule                     = "postgresql-tcp"
      source_security_group_id = module.eks.cluster_security_group_id
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
  port     = "3306"
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