## Airflow

The [Airflow](https://github.com/apache/airflow/) plugin is used to orchestrate our Meltano pipelines.
Follow the [orchestrate docs](https://docs.meltano.com/guide/orchestration) to get airflow installed in your project.
Visit [MeltanoHub](https://hub.meltano.com/utilities/airflow) to get the most up to date installation instructions.


## Squared Implementation Notes

In the production environment we are running Airflow on Kubernetes so we use a custom [KubernetesPodOperator](./plugins/meltano_k8_operator.py) to fan out all of our tasks across the cluster but locally we want to use the [BashOperator](https://airflow.apache.org/docs/apache-airflow/stable/howto/operator/bash.html) as if were running in our terminal.

We also use a slight variation of the default DAG [generator](./dags/meltano.py) to support our production deployment better by doing the following:

- Logic to toggle between the KubernetesPodOperator or BashOperator based on the `OPERATOR_TYPE` Airflow variable. In the `userdev` environment its configured to use the BashOperator locally.
- Allow reading from a cached version of the `meltano schedule list --format=json` output which is in the [schedules.cache.json](schedules.cache.json) file.
Locally if this file doesn't exist it will run the Meltano subprocess and dynamically generate DAGs (same as the default behavior) but in production our Airflow container doesn't have Meltano installed so instead of dynamically generating the DAGs it just reads the cached output.
The cache file is generated [during CI](../../.github/workflows/prod_deploy.yml) when the airflow docker image is being built.

To start up locally, using 3 terminals (or add -D for background), then go to http://0.0.0.0:8080 and login.
```bash
# Create an admin user for UI login
meltano invoke airflow:create-admin
# Webserver
meltano invoke airflow:ui
# Scheduler (in a separate terminal)
meltano invoke airflow scheduler
```
