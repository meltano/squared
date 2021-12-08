import os
from datetime import datetime, timedelta
from textwrap import dedent

# The DAG object; we'll need this to instantiate a DAG
from airflow import DAG

# Operators; we need this to operate!
from airflow.operators.bash import BashOperator
# These args will get passed on to each operator
# You can override them on a per-task basis during operator initialization
default_args = {
    'owner': 'airflow',
    'depends_on_past': False,
    'email': ['airflow@example.com'],
    'email_on_failure': False,
    'email_on_retry': False,
    'retries': 1,
    'retry_delay': timedelta(minutes=5),
    # 'queue': 'bash_queue',
    # 'pool': 'backfill',
    # 'priority_weight': 10,
    # 'end_date': datetime(2016, 1, 1),
    # 'wait_for_downstream': False,
    # 'dag': dag,
    # 'sla': timedelta(hours=2),
    # 'execution_timeout': timedelta(seconds=300),
    # 'on_failure_callback': some_function,
    # 'on_success_callback': some_other_function,
    # 'on_retry_callback': another_function,
    # 'sla_miss_callback': yet_another_function,
    # 'trigger_rule': 'all_success'
}

with DAG(
    'meltano-hub-metrics',
    default_args=default_args,
    description='Update hub metrics daily.',
    schedule_interval=timedelta(days=1),
    start_date=datetime(2021, 1, 1),
    catchup=False,
    tags=['hub'],
) as dag:

    t1 = BashOperator(
        task_id='ga_athena_hub_metrics',
        bash_command='meltano --environment=prod elt tap-google-analytics target-athena --job_id=ga_athena_hub_metrics',
    )

    t2 = BashOperator(
        task_id='dbt_hub_metrics',
        bash_command='meltano --environment=prod invoke dbt:run --models marts.publish.meltano_hub.*',
    )

    publish_metrics_command = dedent(
        f"""
        meltano --environment=prod elt tap-athena-metrics target-yaml-metrics
        meltano --environment=prod invoke awscli s3 cp metrics.yml { os.getenv('HUB_METRICS_S3_PATH') }
        """
    )

    t3 = BashOperator(
        task_id='publish_metrics',
        bash_command=publish_metrics_command
    )

    publish_audit_command = dedent(
        f"""
        meltano --environment=prod elt tap-athena-audit target-yaml-audit
        meltano --environment=prod invoke awscli s3 cp audit.yml { os.getenv('HUB_METRICS_S3_PATH') }
        """
    )

    t4 = BashOperator(
        task_id='publish_audit',
        bash_command=publish_audit_command
    )

    t1 >> t2 >> [t3, t4]
