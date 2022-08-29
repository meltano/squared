## dbt

The [dbt plugin](https://github.com/dbt-labs/dbt-core) in used to as part of the T step in ELT.
It manages all of the SQL transformation logic that happens after the source data has been replicated to the data warehouse.
Follow the [data transformation docs](https://docs.meltano.com/guide/transformation) to get dbt installed in your project.
Visit [MeltanoHub](https://hub.meltano.com/transformers/) to get the most up to date installation instructions.

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
Any mart specific base transformations can go in a `base` directory and will be written to the PREP database.
All exposed models should be well documented.

- analysis: A place to put models that are used for ad-hoc analytics.
Analyst that build ad-hoc models can store them in here for reuse in the future.
These are not exposed as consumption models in reporting tool.

- seed: Static csv datasets.

The output destination for each set of models is defined in the [dbt_profile.yml](https://gitlab.com/meltano/squared/-/blob/master/data/transform/dbt_project.yml).
The marts/publish models which are used for consumption are written to the PROD database and staging or intermediate transformation tables/views are written to the PREP database.
All non-consumption models should be defaulted to a view materialization but can optionally be set to a table if needed for optimization.
The output schema names are explicitly set in the dbt_profile.yml with a backup schema name of DEFAULT in case one is not set, although using the DEFAULT schema should be avoided.

### Development Environments

In this project there are two types of Snowflake development environments: shared and private.
For either case an admin will need to help you get onboarded as a Snowflake user and create any associated Snowflake objects you need before you can use your environment.

#### Shared (Default)

Shared is the default development environment in this project and is for developers who only need to do dbt model development.
The [userdev.meltano.yml](../environments/userdev.meltano.yml) is configured to use the shared development environment automatically.
The shared environment means that dbt is configured to read from the production `RAW` database and write to namespaced schemas in the `USERDEV_RAW/PREP/PROD` databases (e.g. `PROD.TELEMETRY.FACT_CLI_EVENTS` -> `USERDEV_PROD.PNADOLNY_TELEMETRY.FACT_CLI_EVENTS`).
The namespace prefix logic is managed in the `generate_schema_name.sql` dbt macro.
This allows for easily sharing between developers since everyone has access to the same `USERDEV_X` databases, while also giving developers isolation to avoid stepping on each others toes.
The default is to read from production `RAW` but can be uncommented in the [userdev.meltano.yml](../environments/userdev.meltano.yml) to read and write to `USERDEV_RAW`.
This gives developers the option to chose depending on their needs, read from production `RAW` if only updating dbt transformations or read from `USERDEV_RAW.<USER_PREFIX>_<SCHEMA_NAME>` if doing EL development as well.

To configure, simply add your username to the [userdev.meltano.yml](../environments/userdev.meltano.yml) as your `USER_PREFIX` environment variable within the `userdev` Meltano config environment, in place of `melty`.
You also need to have `SNOWFLAKE_PASSWORD` set in your .env in order to authenticate with Snowflake in dbt.

#### Private

Private development environments are for developers that need to work in private isolation due to something like sensitive data that shouldnt be in the shared database.
For this its better to use a set of private databases instead of the shared `USERDEV_X` databases.
Developers will get 3 empty databases provisioned for them which they have full permissions on: `<USER_PREFIX>_RAW`, `<USER_PREFIX>_PREP`, `<USER_PREFIX>_PROD`.
The developer is able to customize their environment as needed which could mean using the available dbt macros to clone production data or by continuing to read from `RAW` and `PREP` but write output to the private `<USER_PREFIX>_PROD` database.
EL development will also be private since the `target-snowflake` loader is configured to write to the `<USER_PREFIX>_RAW` database when the `userdev` Meltano config environment is active.

Private development environments are currently not in use.

### Seed

As part of a CI deployment to production `dbt:seed` is run in order to persist any updates that have been made to the seed files.
Seed tables should be static unless a change is made to the code base so by updating them in CI it avoids redundant seed calls in the DAGs.
All DAGs can assume that seed tables are always up to date with the master branch.

### Clone to Private Userdev Environments

Developers who have a private development environment provisioned for them usually want to seed some amount of production data in their databases.
The easiest way to set this up is to run the following command which executes a dbt macro that finds all the `RAW` schemas from production that the developer has access to and clones them into the private development environment using the `USER_PREFIX` set in the userdev Meltano environment (i.e. clone `RAW.X` to `PNADOLNY_RAW.X`).

```bash
meltano --environment=userdev invoke dbt-snowflake:create_userdev_env
```

This command and its arguments are defined in meltano.yml.
The macro defaults to `dry_run` mode where the SQL script is only generated and logged to the console to be manually executed vs actually executing against Snowflake.
If you'd like to have it execute just edit the command in meltano.yml to `'dry_run': False`.
Additionally it defaults to only clone the `RAW` database because developers are presumed to be updating EL or staging dbt models and the rest can be built by running dbt but you can also edit the command to include `PROD` or `PREP` in the `db_list` if you have access and would like those cloned as well.
In addition, the command in meltano.yml includes a schema_list argument that allows you to define more precisely what schemas to clone.
An empty list will clone all accessible schemas (i.e. `RAW.*`).
To use this filter, edit the command in meltano.yml and set the full names of the schemas you'd like to clone (i.e. `RAW.GOOGLE_ANALYTICS`).

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
meltano invoke dbt-snowflake:deps
meltano invoke dbt-snowflake run-operation generate_model_yaml --args '{"model_name": "fact_plugin_usage"}'
```

### dbt Docs

The [dbt docs](https://docs.getdbt.com/docs/building-a-dbt-project/documentation) for this project are generated in CI after a new deployment to production and are served using GitLab Pages at https://meltano.gitlab.io/squared/. 

### Style Guide

Refer to the[ Meltano Data Team handbook](https://handbook.meltano.com/data-team/sql-style-guide) for the SQL style guide information.
