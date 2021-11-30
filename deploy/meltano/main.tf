locals {
  region = "us-east-1"
  k8_namespace = "meltano"
  eks_cluster_id = "fargate-yXpnnpRb"
}

resource "kubernetes_namespace" "meltano" {
  metadata {
    name = local.k8_namespace
  }
}