## Airflow

The [Airflow](https://github.com/apache/airflow/) plugin is used to orchestrate our Meltano pipelines.
Follow the [orchestrate docs](https://docs.meltano.com/guide/orchestration) to get dbt installed in your project.

## Squared Implementation Notes

In the production environment we are running Airflow on Kubernetes so we use a custom [KubernetesPodOperator](./plugins/meltano_k8_operator.py) to fan out all of our tasks across the cluster but locally we want to use the [BashOperator](https://airflow.apache.org/docs/apache-airflow/stable/howto/operator/bash.html) as if were running in our terminal.
We also use a DAG [generator](./dags/generator.py) because want to limit as much DAG writing as possible to avoid duplicate code, maintenance burden, and potential for mistakes.
DAGs are defined in the dag_definition.yml file (eventually will be pulled into Meltano as part of meltano.yml probably) which is read by the generator to build DAG definitions on the fly.
The DAG generator is referenced by both the locally configured `userdev` environment and the `prod` environment which is built and deployed using the [deploy module](../../deploy/meltano/).

To start up locally, using 3 terminals (or add -D for background), then go to http://0.0.0.0:8080 and login.
```bash
# Webserver
meltano --environment=userdev invoke airflow webserver
# Create an admin user for UI login
meltano --environment=userdev invoke airflow users create --username melty --firstname melty --lastname meltano --role Admin --password melty --email melty@meltano.com
# Scheduler
meltano --environment=userdev invoke airflow scheduler
```
