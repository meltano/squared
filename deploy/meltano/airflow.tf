locals {
  airflow_env_variables = [
    {
      name  = "AWS_REGION"
      value = local.region
    },
    {
      name  = "AWS_DEFAULT_REGION"
      value = local.region
    }
  ]
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
  values = [file("${path.module}/data/airflow/values.yaml")]

  set {
    name = "images.airflow.repository"
    value = data.aws_ecr_repository.airflow.repository_url
  }

  set {
    name = "images.pod_template.repository"
    value = data.aws_ecr_repository.airflow.repository_url
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
    name  = "extraEnv"
    value = yamlencode(local.airflow_env_variables)
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