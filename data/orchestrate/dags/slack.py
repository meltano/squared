import os
from datetime import datetime, timedelta
from textwrap import dedent

# The DAG object; we'll need this to instantiate a DAG
from airflow import DAG

# Operators; we need this to operate!
from meltano_k8_operator import MeltanoKubernetesPodOperator
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
    'meltano-slack',
    default_args=default_args,
    description='Slack ELT',
    schedule_interval=timedelta(days=1),
    start_date=datetime(2021, 1, 1),
    catchup=False,
    tags=[],
) as dag:

    t1 = MeltanoKubernetesPodOperator(
        task_id='tap_slack_target_athena',
        name='slack-tap-slack-target-athena',
        environment='prod',
        debug=True,
        arguments=["meltano elt tap-slack target-athena-slack --job_id=tap_slack_target_athena"]
    )

    t2 = MeltanoKubernetesPodOperator(
        task_id='dbt_slack_run_stage',
        name='slack_dbt_slack_run_stage',
        environment='prod',
        arguments=["meltano invoke dbt:run --models staging.slack.*"]
    )

    t3 = MeltanoKubernetesPodOperator(
        task_id='dbt_slack_test_stage',
        name='slack_dbt_slack_test_stage',
        environment='prod',
        arguments=["meltano invoke dbt:test --models staging.slack.*"]
    )

    t4 = MeltanoKubernetesPodOperator(
        task_id='dbt_slack_run_models',
        name='slack_dbt_slack_run_models',
        environment='prod',
        arguments=["meltano invoke dbt:run --models common.slack_new_members analysis.slack_company_domains"]
    )

    t5 = MeltanoKubernetesPodOperator(
        task_id='dbt_slack_test_models',
        name='slack_dbt_slack_test_models',
        environment='prod',
        arguments=["meltano invoke dbt:test --models common.slack_new_members analysis.slack_company_domains"]
    )

    t1 >> t2 >> t3 >> t4 >> t5
