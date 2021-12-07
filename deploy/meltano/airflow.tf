locals {
  airflow_env_variables = [
    {
      name  = "AWS_REGION"
      value = local.region
    },
    {
      name  = "AWS_DEFAULT_REGION"
      value = local.region
    },
    {
      name = "MELTANO_PROJECT_ROOT"
      value = "/opt/airflow/meltano"
    }
  ]
  base64_meltano_uri = base64encode("${local.meltano_db_credentials.url}?sslmode=disable")
  airflow_extra_secrets = <<EOT
extraSecrets:
  meltano-database-uri:
    data: |
      uri: "${local.base64_meltano_uri}"
EOT
  airflow_secrets = {
    secret = [
      {
        envName = "MELTANO_DATABASE_URI"
        secretKey = "uri"
        secretName = "meltano-database-uri"
      }
    ]
  }
}

# ECR Repository
data "aws_ecr_repository" "airflow" {
  name = "m5o-prod-airflow"
}

# Secrets
data "aws_ssm_parameter" "airflow_fernet_key" {
  name = "/prod/meltano/airflow/fernet_key"
}

data "aws_ssm_parameter" "airflow_webserver_secret_key" {
  name = "/prod/meltano/airflow/webserver_secret_key"
}

data "aws_ssm_parameter" "airflow_db_credentials" {
  name = "/prod/meltano/airflow/db_credentials"
}

locals {
  airflow_db_credentials = jsondecode(data.aws_ssm_parameter.airflow_db_credentials.value)
}

resource "helm_release" "airflow" {
  name        = "airflow"
  namespace   = local.k8_namespace
  repository  = "https://airflow.apache.org"
  chart       = "airflow"
  version     = "1.3.0"
  max_history = 10
  wait        = false
  depends_on = [
    kubernetes_namespace.meltano
  ]
  values = [
    file("${path.module}/data/airflow/values.yaml"),
    yamlencode(local.airflow_secrets),
    local.airflow_extra_secrets
  ]

  set {
    name  = "extraEnv"
    value = yamlencode(local.airflow_env_variables)
  }

  set {
    name = "images.airflow.repository"
    value = data.aws_ecr_repository.airflow.repository_url
  }

  set {
    name = "images.airflow.tag"
    value = "latest"
  }

  set {
    name = "images.pod_template.repository"
    value = data.aws_ecr_repository.airflow.repository_url
  }

  set {
    name = "images.pod_template.repository"
    value = "latest"
  }

  set {
    name = "fernetKey"
    value = data.aws_ssm_parameter.airflow_fernet_key.value
  }

  set {
    name = "webserverSecretKey"
    value = data.aws_ssm_parameter.airflow_webserver_secret_key.value
  }

  set {
    name = "data.metadataConnection.host"
    value = local.airflow_db_credentials.host
  }

  set {
    name = "data.metadataConnection.user"
    value = local.airflow_db_credentials.user
  }
  set {
    name = "data.metadataConnection.pass"
    value = local.airflow_db_credentials.password
  }

  set {
    name = "data.metadataConnection.db"
    value = local.airflow_db_credentials.database
  }

  set {
    name = "data.metadataConnection.port"
    value = local.airflow_db_credentials.port
  }

  set {
    name = "data.metadataConnection.protocol"
    value = "postgresql"
  }

  # This is not a chart value, but just a way to trick helm_release into running every time.
  # Without this, helm_release only updates the release if the chart version (in Chart.yaml) has been updated.
  set {
    name  = "timestamp"
    value = timestamp()
  }
}