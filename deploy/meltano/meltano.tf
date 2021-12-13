locals {
  meltano_env_variables = []
}

data "aws_ssm_parameter" "meltano_db_credentials" {
  name = "/prod/meltano/db_credentials"
}

locals {
  meltano_db_credentials = jsondecode(data.aws_ssm_parameter.meltano_db_credentials.value)
}

data "aws_ecr_repository" "meltano" {
  name = "m5o-prod-meltano"
}

resource "helm_release" "meltano" {
  name        = "meltano"
  repository  = "https://meltano.gitlab.io/infra/helm-meltano/meltano"
  chart       = "meltano"
  namespace   = "meltano"
  version     = "0.1.1"
  wait        = false
  # values = [
  #   "${file("values.yml")}"
  # ]

  set {
    name  = "extraEnv"
    value = yamlencode(local.meltano_env_variables)
  }

  set {
    name = "image.repository"
    value = data.aws_ecr_repository.meltano.repository_url
  }

  set {
    name = "image.tag"
    value = var.meltano_image_tag
  }

  set {
    name = "meltano.database_uri"
    value = "${local.meltano_db_credentials.url}?sslmode=disable"
  }

  # This is not a chart value, but just a way to trick helm_release into running every time.
  # Without this, helm_release only updates the release if the chart version (in Chart.yaml) has been updated
  set {
    name  = "timestamp"
    value = timestamp()
  }

}