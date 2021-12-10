
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
  allowed_security_group_ids = [
    module.eks.cluster_security_group_id,
    module.eks.worker_security_group_id
  ]
}

resource "aws_efs_file_system_policy" "efs-policy" {
  file_system_id = module.efs.id
  bypass_policy_lockout_safety_check = true
  policy = <<POLICY
{
    "Version": "2012-10-17",
    "Id": "EfsFsPolicy",
    "Statement": [
        {
            "Sid": "efs-fs-policy",
            "Effect": "Allow",
            "Principal": {
                "AWS": "*"
            },
            "Resource": "${module.efs.arn}",
            "Action": [
                "elasticfilesystem:ClientRootAccess",
                "elasticfilesystem:ClientMount",
                "elasticfilesystem:ClientWrite"
            ]
        }
    ]
}
POLICY
}

# Install the EFS CSI Driver
module "eks_efs_csi_driver" {
  source  = "DNXLabs/eks-efs-csi-driver/aws"
  version = "0.1.4"

  cluster_name                     = module.eks.cluster_id
  cluster_identity_oidc_issuer     = module.eks.cluster_oidc_issuer_url
  cluster_identity_oidc_issuer_arn = module.eks.oidc_provider_arn
  create_namespace = false
  create_storage_class = false
}

# Create
resource "kubernetes_storage_class" "efs_storage_class" {
  metadata {
    name = "efs-dsc"
  }
  storage_provisioner = "efs.csi.aws.com"
  parameters = {
    provisioningMode: "efs-ap"
    fileSystemId:  module.efs.id
    directoryPerms: "775"
  }
  reclaim_policy      = "Retain"
  depends_on = [module.eks_efs_csi_driver]
}

resource "kubernetes_manifest" "efs_persistant_volume_claim" {
  manifest = {
    apiVersion = "v1"
    kind       = "PersistentVolumeClaim"
    metadata = {
      name = "efs-claim"
      namespace = "meltano"
    }
    spec = {
      accessModes = ["ReadWriteMany"]
      storageClassName = "efs-dsc"
      resources = {
        requests = {
          storage = "5Gi"  # Not actually used - see https://aws.amazon.com/blogs/containers/introducing-efs-csi-dynamic-provisioning/
        }
      }
    }
  }
  depends_on = [kubernetes_manifest.efs_persistant_volume]
}