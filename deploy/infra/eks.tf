
module "eks_worker_additional_security_group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "4.7.0"

  name        = "eks_worker_additional_security_group"
  description = "Security group for Meltano platform EKS Workers"
  vpc_id      = module.vpc.vpc_id

  ingress_cidr_blocks      = module.vpc.private_subnets
  egress_with_source_security_group_id = [
    {
      rule = "postgresql-tcp"
      source_security_group_id = module.db_security_group.security_group_id
    }
  ]
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "17.23.0"

  cluster_name    = local.name
  cluster_version = local.cluster_version

  vpc_id          = module.vpc.vpc_id
  subnets         = concat(module.vpc.public_subnets, module.vpc.private_subnets)

  cluster_endpoint_private_access = true
  cluster_endpoint_public_access  = true

  worker_groups = [
    {
      instance_type = "t3.small"
      asg_max_size  = 4
      asg_desired_capacity = 2
      additional_security_group_ids = [module.eks_worker_additional_security_group.security_group_id]
      subnets = module.vpc.private_subnets
    }
  ]

  manage_aws_auth = true

  tags = {
    GitlabRepo = "squared"
    GitlabOrg  = "meltano"
  }
}