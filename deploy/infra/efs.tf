
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
  access_points = {
    airflow = {
      posix_user = {
        gid            = "1001"
        uid            = "5000"
        secondary_gids = "1002,1003"
      }
      creation_info = {
        gid         = "1001"
        uid         = "5000"
        permissions = "0755"
      }
    }
  }
}

resource "helm_release" "aws-efs-csi-driver" {
  name        = "aws-efs-csi-driver"
  namespace   = "kube-system"
  repository  = "https://kubernetes-sigs.github.io/aws-efs-csi-driver/"
  chart       = "aws-efs-csi-driver"
  version     = "2.2.0"
  max_history = 10
  wait        = false

  # This is not a chart value, but just a way to trick helm_release into running every time.
  # Without this, helm_release only updates the release if the chart version (in Chart.yaml) has been updated
  set {
    name  = "timestamp"
    value = timestamp()
  }
}

resource "helm_release" "aws-efs-pv" {
  name        = "aws-efs-pv"
  namespace   = "meltano"
  chart       = "${path.module}/aws-efs-pv"
  max_history = 10
  depends_on = [kubernetes_namespace.meltano]

  set {
    name = "efs.id"
    value = "${module.efs.id}::${module.efs.access_point_ids.airflow}"
  }

  # This is not a chart value, but just a way to trick helm_release into running every time.
  # Without this, helm_release only updates the release if the chart version (in Chart.yaml) has been updated
  set {
    name  = "timestamp"
    value = timestamp()
  }
}