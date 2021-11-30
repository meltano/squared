
module "eks_worker_additional_security_group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "4.7.0"

  name        = "eks_worker_additional_security_group"
  description = "Security group for Meltano platform EKS Workers"
  vpc_id      = module.vpc.vpc_id

  ingress_cidr_blocks      = module.vpc.private_subnets
  egress_with_source_security_group_id = [
    {
      from_port                = local.rds_port
      to_port                  = local.rds_port
      protocol                 = "tcp"
      description              = "Custom Postgres Port"
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
  subnets         = [module.vpc.private_subnets[0], module.vpc.private_subnets[1]]
  fargate_subnets = [module.vpc.private_subnets[2]]

  cluster_endpoint_private_access = true
  cluster_endpoint_public_access  = true

  # You require a node group to schedule coredns which is critical for running correctly internal DNS.
  # If you want to use only fargate you must follow docs `(Optional) Update CoreDNS`
  # available under https://docs.aws.amazon.com/eks/latest/userguide/fargate-getting-started.html
  node_groups = {
    core_dns = {
      desired_capacity = 1

      instance_types = ["t3.medium"]
      k8s_labels = {
        GitlabRepo = "squared"
        GitlabOrg  = "meltano"
      }
      additional_tags = {}
      update_config = {
        max_unavailable_percentage = 50 # or set `max_unavailable`
      }
    }
  }

  fargate_profiles = {
    default = {
      name = "default"
      selectors = [
        {
          namespace = "kube-system"
          labels = {
            k8s-app = "kube-dns"
          }
        },
        {
          namespace = "default"
          labels = {
            WorkerType = "fargate"
          }
        }
      ]

      tags = {
        Owner = "default"
      }

      timeouts = {
        create = "20m"
        delete = "20m"
      }
    }
  }

  manage_aws_auth = false

  tags = {
    GitlabRepo = "squared"
    GitlabOrg  = "meltano"
  }
}