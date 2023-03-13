# Contributing

## Transforms

### Development Environments

This Meltano project is configured to use a `userdev` environment by default which allows for developer isolation within the development databases in Snowflake.
All developer users and roles are configured to be restrictive for all destructive behavior on production while also having loose restrictions on what developers can do in the development database (`USERDEV_PREP` and `USERDEV_PROD`).

In addition to being safely isolated from production, developers are configured to be isolated from other developers within the development Snowflake databases by using schema prefixes.
For example when dbt models are run in the userdev environment it maps a production model from `PREP.SCHEMA_NAME.TABLE_NAME` to `USERDEV_PREP.<USER_PREFIX>_SCHEMA_NAME.TABLE_NAME`.
This allows multiple developers to work in isolation within the same Snowflake development databases.

### Configuration

To develop transforms, you'll need at least these env vars declared in your `.env`:

- `USER_PREFIX=<YOUR_SNOWFLAKE_USERNAME>`
- `MELTANO_ENVIRONMENT="userdev"`
- `SNOWFLAKE_PASSWORD="=<YOUR_SNOWFLAKE_PASSWORD>"`

### Clone a development environment

Run the following command to clone or refresh a development environment:

```console
meltano run clone_dbt_dev_env
```

1. This runs the `snowflake-cloner` which clones all tables from the PREP and PROD databases into a USERDEV_PREP and USERDEV_PROD databases using your schema prefix.
Ultimately a table named `PROD.TELEMETRY.PROJECT_DIM` will be cloned to `USERDEV_PROD.PNADOLNY_TELEMETRY.PROJECT_DIM`.
If your Snowflake user has developer permissions then you will be able to run this clone operation and the outcome will be Snowflake objects that are owned by your user so you can run normal dbt operations like create/update/delete.

2. Next it runs `dbt-snowflake:run_views` to build all dbt-owned views in your isolated development environment.

Once this completes you have a full development environment cloned from production.

### Common workflows and tips

A common workflow for a developer intending to make changes to the Meltano managed dbt project is:

1. Clone a fresh development environment (described above)
2. Edit or add dbt models
3. Run models precisely using select criteria i.e `meltano invoke dbt-snowflake --select my_new_model`
4. Evaluate if downstream models are affected by these change and run those too using graph operator select criteria `--select my_new_model+`.


WARNING: be careful to avoid triggering large incremental table builds. You can run `meltano run dbt_docs` to build and serve the dbt docs and explore the DAG in more detail.
Primarily the models to be aware of are downstream of Snowplow where materialization is table or incremental.
These models shouldn't need to be changed often so reach out to the other Squared developers if you need to make changes.

Long running models of note:
- staging.snowplow.stg_snowplow__events
- marts.telemetry.base.unstructured_parsing.context_base
- marts.telemetry.base.unstructured_parsing.unstruct_context_flattened
- marts.telemetry.base.unstructured_parsing.unstruct_event_flattened
- marts.telemetry.base.unstructured_parsing.unstruct_exec_flattened


### Scheduling models

After the model changes are complete, evaluate whether the models need a new job/schedule or if theyre already managed by an existing schedule.
If a schedule is needed:

1. Add a command to the dbt-snowflake plugin in the [transformers.meltano.yml](trasform/transformers.meltano.yml) with the select criteria needed in the job/schedule.
2. Add the job/schedule to the [orchestrators.meltano.yml](orchestrate/orchestrators.meltano.yml) file.


## EL Pipelines

TODO
