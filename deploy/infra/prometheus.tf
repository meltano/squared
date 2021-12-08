resource "kubernetes_namespace" "prometheus" {
  metadata {
    name = "prometheus"
  }
}

resource "helm_release" "prometheus" {
  name        = "prometheus"
  namespace   = "prometheus"
  repository  = "https://prometheus-community.github.io/helm-charts"
  chart       = "prometheus"
  version     = "15.0.1"
  max_history = 10
  wait        = false
  depends_on = [
    kubernetes_namespace.prometheus
  ]
}