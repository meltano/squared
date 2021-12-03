locals {
  region = "us-east-1"
  k8_namespace = "meltano"
  eks_cluster_id = "eks-mmJgK6GB"
}

resource "kubernetes_namespace" "meltano" {
  metadata {
    name = local.k8_namespace
  }
}