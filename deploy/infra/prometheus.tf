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

  # This is not a chart value, but just a way to trick helm_release into running every time.
  # Without this, helm_release only updates the release if the chart version (in Chart.yaml) has been updated.
  set {
    name  = "timestamp"
    value = timestamp()
  }
}