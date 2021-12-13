module "ecr_airflow" {
  source = "cloudposse/ecr/aws"
  version     = "0.32.3"
  namespace              = "m5o"
  stage                  = "prod"
  name                   = "airflow"
  image_tag_mutability = "MUTABLE" # for "latest"
  principals_full_access = [
    module.eks.cluster_iam_role_arn,
    module.eks.worker_iam_role_arn
  ]
}

module "ecr_meltano" {
  source = "cloudposse/ecr/aws"
  version     = "0.32.3"
  namespace              = "m5o"
  stage                  = "prod"
  name                   = "meltano"
  image_tag_mutability = "MUTABLE" # for "latest"
  principals_full_access = [
    module.eks.cluster_iam_role_arn,
    module.eks.worker_iam_role_arn
  ]
}