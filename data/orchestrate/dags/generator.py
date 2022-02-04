# If you want to define a custom DAG, create
# a new file under orchestrate/dags/ and Airflow
# will pick it up automatically.

import logging
import os
import pathlib
from datetime import datetime, timedelta

import yaml
from airflow import DAG
from airflow.models import Variable
from airflow.operators.bash_operator import BashOperator

operator = Variable.get("OPERATOR_TYPE", "k8")
if operator == "k8":
    from meltano_k8_operator import MeltanoKubernetesPodOperator

logger = logging.getLogger(__name__)


DEFAULT_ARGS = {
    "owner": "airflow",
    "depends_on_past": False,
    "email_on_failure": False,
    "email_on_retry": False,
    "catchup": False,
    "retries": 1,
    "retry_delay": timedelta(minutes=5),
    "concurrency": 1,
}

DEFAULT_TAGS = ["meltano"]

orchestrate_path = pathlib.Path(__file__).resolve().parents[1]
project_root = os.getenv("MELTANO_PROJECT_ROOT", os.getcwd())
environment = Variable.get("MELTANO_ENVIRONMENT", "")


with open(os.path.join(orchestrate_path, "dag_definition.yml"), "r") as yaml_file:
    yaml_content = yaml.safe_load(yaml_file)
    dags = yaml_content.get("dags")

for dag_name, dag_def in dags.items():
    logger.info(f"Considering dag '{dag_name}'")

    if not dag_def["interval"]:
        logger.info(
            f"No DAG created for schedule '{dag_name}' because its interval is set to `@once`."
        )
        continue

    args = DEFAULT_ARGS.copy()
    dag_id = f"meltano_{dag_name}"

    # from https://airflow.apache.org/docs/stable/scheduler.html#backfill-and-catchup
    #
    # It is crucial to set `catchup` to False so that Airflow only create a single job
    # at the tail end of date window we want to extract data.
    #
    # Because our extractors do not support date-window extraction, it serves no
    # purpose to enqueue date-chunked jobs for complete extraction window.
    dag = DAG(
        dag_id,
        tags=DEFAULT_TAGS,
        catchup=False,
        default_args=args,
        schedule_interval=dag_def["interval"],
        # We don't care about start date since were not using it and its recommended
        # to be static so we just set it the same date for all
        start_date=datetime(2022, 1, 1),
        max_active_runs=1,
    )
    
    # dict of name to dag object reference
    name_map = {}
    # register all tasks to DAG
    for step in dag_def.get("steps"):
        task_name = step.get("name")
        cmd = step.get("cmd")
        task_id = f"{dag_id}_{task_name}"
        if operator == "k8":
            task = MeltanoKubernetesPodOperator(
                task_id=task_id,
                name=task_name,
                environment="prod",
                debug=True,
                arguments=[cmd],
                dag=dag
            )
        else:
            task = BashOperator(
                task_id=task_id,
                bash_command=f"export MELTANO_ENVIRONMENT={environment} ; cd {project_root}; {cmd}",
                retries=step.get("retries", 0),
                dag=dag,
            )
        name_map[task_name] = task

    # assign dependencies
    for step in dag_def.get("steps"):
        deps = step.get("depends_on")
        if deps:
            task_obj = name_map.get(step.get("name"))
            for dep_name in deps:
                dep_obj = name_map.get(dep_name)
                task_obj.set_upstream(dep_obj)


    # register the dag
    globals()[dag_id] = dag

    logger.info(f"DAG created for schedule '{dag_name}'")
