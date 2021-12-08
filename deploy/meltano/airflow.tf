# ECR Repository
data "aws_ecr_repository" "airflow" {
  name = "m5o-prod-airflow"
}

# Meltano Secrets
data "aws_ssm_parameter" "meltano_hub_metrics_s3_path" {
  name = "/prod/meltano/hub_metrics_s3_path"
}

data "aws_ssm_parameter" "meltano_env_file" {
  name = "/prod/meltano/env_file"
}

# Airflow Secrets
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
  meltano-hub-metrics-s3-path:
    data: |
      path: "${base64encode(data.aws_ssm_parameter.meltano_hub_metrics_s3_path.value)}"
  meltano-env-file:
    data: |
      file: "${base64encode(data.aws_ssm_parameter.meltano_env_file.value)}"
EOT

  airflow_secrets = {
    secret = [
      {
        envName = "MELTANO_DATABASE_URI"
        secretName = "meltano-database-uri"
        secretKey = "uri"
      },
      {
        envName = "HUB_METRICS_S3_PATH"
        secretName = "meltano-hub-metrics-s3-path"
        secretKey = "path"
      }
    ]
  }

  meltano_env_volumes = [
    {
      name = "env-file"
      secret = {
        secretName = "meltano-env-file"
        items = [
          {
            key = "file"
          }
        ]
      }
    }
  ]

  meltano_env_volume_mounts = [
    {
      name = "env-file"
      mountPath = "/opt/airflow/meltano/.env"
      readOnly = true
    }
  ]

  airflow_worker_volumes = {
    workers = {
      extraVolumes = local.meltano_env_volumes
    }
  }

  airflow_worker_volume_mounts = {
    workers = {
      extraVolumeMounts = local.meltano_env_volume_mounts
    }
  }

  airflow_webserver_volumes = {
    webserver = {
      extraVolumes = local.meltano_env_volumes
    }
  }

  airflow_webserver_volume_mounts = {
    webserver = {
      extraVolumeMounts = local.meltano_env_volume_mounts
    }
  }


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
    local.airflow_extra_secrets,
    yamlencode(local.airflow_worker_volumes),
    yamlencode(local.airflow_worker_volume_mounts),
    yamlencode(local.airflow_webserver_volumes),
    yamlencode(local.airflow_webserver_volume_mounts),
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
    value = var.airflow_image_tag
  }

  set {
    name = "images.pod_template.repository"
    value = data.aws_ecr_repository.airflow.repository_url
  }

  set {
    name = "images.pod_template.repository"
    value = var.airflow_image_tag
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