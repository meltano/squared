import os

from kubernetes.client import models as k8s
from airflow.kubernetes.secret import Secret
from airflow.providers.cncf.kubernetes.operators.kubernetes_pod import KubernetesPodOperator


database_uri = Secret('env', 'MELTANO_DATABASE_URI', 'meltano-env', 'database-uri')
env_file = Secret('volume', '/project/.env', 'meltano-env', 'env-file')

volume = k8s.V1Volume(
    name='env-file',
    secret=k8s.V1SecretVolumeSource(
        secret_name='meltano-env',
        items=[
            k8s.V1KeyToPath(
                key='env-file',
                path='.env'
            )
        ]
    )
)

volume_mount = k8s.V1VolumeMount(
    name='env-file',
    mount_path='/project/.env',
    sub_path='.env',
    read_only=True
)

class MeltanoKubernetesPodOperator(KubernetesPodOperator):

    def __init__(self, task_id, name, arguments, environment=None, debug=False, **kwargs):
        """ Meltano KubernetesPodOperator
        """
        env_vars = [
            k8s.V1EnvVar(name='AWS_REGION', value=os.getenv("AWS_REGION")),
            k8s.V1EnvVar(name='AWS_DEFAULT_REGION', value=os.getenv("AWS_DEFAULT_REGION")),
        ]
        if environment is not None:
            env_vars.append(
                k8s.V1EnvVar(name='MELTANO_ENVIRONMENT', value=environment)
            )
        if debug:
            env_vars.append(
                k8s.V1EnvVar(name='MELTANO_CLI_LOG_LEVEL', value='debug')
            )
        meltano_values = dict(
            task_id=task_id,
            image = f"{os.getenv('MELTANO_IMAGE_REPOSITORY_URL')}:{os.getenv('MELTANO_IMAGE_TAG')}",
            image_pull_policy="Always",
            namespace = os.getenv("MELTANO_NAMESPACE"),
            is_delete_operator_pod = False,
            service_account_name="default",
            in_cluster=True,
            arguments=arguments,
            name=name,
            startup_timeout_seconds=60*10,
            retries=2,
            get_logs=True,
            env_vars=env_vars,
            secrets = [database_uri],
            volumes=[volume],
            volume_mounts=[volume_mount],
            resources={
                "request_cpu": "512m",
                "request_memory": "1048Mi",
                "limit_cpu": "1024m",
                "limit_memory": "2048Mi"
            }
        )
        meltano_values.update(kwargs)
        super().__init__(**meltano_values)
