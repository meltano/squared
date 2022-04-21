## dbt

The [dbt plugin](https://github.com/dbt-labs/dbt-core) in used to as part of the T step in ELT.
It manages all of the SQL transformation logic that happens after the source data has been replicated to the data warehouse.
Follow the [data transformation docs](https://docs.meltano.com/guide/transformation) to get dbt installed in your project.

## Squared Implementation Notes

### Project Structure

The following is the project structure for this repo:

- staging: Initial prep.
This includes things like deduplication, renaming, casting, adding surrogate keys, etc.

- common: Shared transformations.
This is to avoid duplicating transformation logic in multiple places.
If something is done multiple times it should be pulled out to a common shared model to improve maintenance and consistency.

- marts: Consumption models for a particular domain.
These are the tables that will be exposed for reporting tools and reverse ETL use cases.
Any mart specific base transformations can go in a `base` directory.
All exposed models should be well documented.

- analysis: A place to put models that are used for ad-hoc analytics.
Analyst that build ad-hoc models can store them in here for reuse in the future.
These are not exposed as consumption models in reporting tool.

- seed: Static csv datasets.

The output destination for each set of models is defined in the [dbt_profile.yml](https://gitlab.com/meltano/squared/-/blob/master/data/transform/dbt_project.yml).
Each of these sets of models write to the PROD database except for staging which writes to the PREP database.
The output schema names are explicitly set in the dbt_profile.yml with a backup schema name of DEFAULT in case one is not set, although using the DEFAULT schema should be avoided.

### Development Environments

In this project there are two types of Snowflake development environments: shared and private.
For either case an admin will need to help you get onboarded as a Snowflake user and create any associated Snowflake objects you need before you can use your environment.

#### Shared (Default)

Shared is the default development environment in this project and is for developers who only need to do dbt model development.
The meltano.yml is set up to use the shared development environment automatically.
The shared environment means that dbt is configured to read from the production `RAW` and `PREP` databases and write to namespaced schemas in the `USERDEV` database (e.g. `PROD.TELEMETRY.FACT_CLI_EVENTS` -> `USERDEV.PNADOLNY_TELEMETRY.FACT_CLI_EVENTS`).
The namespace prefix logic is managed in the `generate_schema_name.sql` dbt macro.
This allows for easily sharing between developers since everyone has access to the same `USERDEV` database, while also giving developers loose isolation to avoid stepping on each others toes.
In this shared environment the assumption is that you arent editing any source data so staging models will fail due to insufficient privileges, if you need to edit EL or staging models contact an admin to get a private development environment provisioned. 

To configure, simply add your username to the `environments.meltano.yml` as your `USER_PREFIX` environment variable within the `userdev` Meltano config environment, in place of `melty`.
You also need to have `SNOWFLAKE_PASSWORD` set in your .env in order to authenticate with Snowflake in dbt.

#### Private

Private development environments are for developers that need to work on EL pipelines, dbt staging logic, or are accessing sensitive data that shouldnt be in the shared database.
For this its better to use a set of private databases instead of the shared `USERDEV` database.
Developers will get 3 empty databases provisioned for them which they have full permissions on: `<USER_PREFIX>_RAW`, `<USER_PREFIX>_PREP`, `<USER_PREFIX>_PROD`.
The developer is able to customize their environment as needed which could mean using the available dbt macros to clone production data or by continuing to read from `RAW` and `PREP` but write output to the private `<USER_PREFIX>_PROD` database.
EL development will also be private since the `target-snowflake` loader is configured to write to the `<USER_PREFIX>_RAW` database when the `userdev` Meltano config environment is active.

To configure Meltano to use a private environment, uncomment the `dbt-snowflake` config section labeled `Private Development Environments` in the `userdev` Meltano config environment to override the `database`, `database_prep`, and `database_raw`. You can chose to only override the `database` setting if you just want dbt to write to a private database and continue to read from the production RAW/PREP databases.
You also need to have `SNOWFLAKE_PASSWORD` set in your .env to authenticate with Snowflake in dbt and with target-snowflake.

### Seed

As part of a CI deployment to production `dbt:seed` is run in order to persist any updates that have been made to the seed files.
Seed tables should be static unless a change is made to the code base so by updating them in CI it avoids redundant seed calls in the DAGs.
All DAGs can assume that seed tables are always up to date with the master branch.

### Code Gen

The dbt `codegen` [package](https://github.com/dbt-labs/dbt-codegen) is a useful accelerator to help create source, model, and base files.
To use it you need to add the following to the [packages.yml](packages.yml) file.

```yaml
packages:
  - package: fishtown-analytics/codegen
    version: 0.3.2
```
Then run the following and paste the output into the appropriate file and finish editing:

```bash
meltano invoke dbt:deps
meltano invoke dbt run-operation generate_model_yaml --args '{"model_name": "fact_cli_events"}'
```

### dbt Docs

The [dbt docs](https://docs.getdbt.com/docs/building-a-dbt-project/documentation) for this project are generated in CI after a new deployment to production and are served using GitLab Pages at https://meltano.gitlab.io/squared/. 

### Style Guide

Refer to the[ Meltano Data Team handbook](https://handbook.meltano.com/data-team/sql-style-guide) for the SQL style guide information.
