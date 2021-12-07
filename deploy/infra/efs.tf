
module "efs" {
  source = "cloudposse/efs/aws"
  version     = "0.32.2"
  namespace = "m5o"
  stage     = "prod"
  name      = "meltano"
  region    = "us-east-1"
  vpc_id    = module.vpc.vpc_id
  subnets   = module.vpc.private_subnets
  zone_id   = []
  allowed_security_group_ids = [module.eks.cluster_security_group_id]
}