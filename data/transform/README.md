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

### Seed

As part of a CI deployment to production `dbt:seed` is run in order to persist any updates that have been made to the seed files.
Seed tables should be static unless a change is made to the code base so by updating them in CI it avoids redundant seed calls in the DAGs.
All DAGs can assume that seed tables are always up to date with the master branch.

### Isolated Userdev Environments

Each developer should have their own isolated development environment in Snowflake.
The easiest way to set this up is to run the following command which runs a dbt macro which finds all the `PREP` schemas from production that the developer has access to and clones them into the userdev environment using the `USER_PREFIX` set in the userdev Meltano environment.

```bash
meltano --environment=userdev invoke dbt-snowflake:create_userdev_env
```

This command and its arguments are defined in meltano.yml.
The macro defaults to `dry_run` mode where the SQL script is only generated and logged to the console vs actually executing against Snowflake.
If you'd like to have it execute just edit the command in meltano.yml to `'dry_run': False`.
Additionally it defaults to only clone the `PREP` database because developers are presumed to be updating and running the dbt models to build the tables/views themselves but you can also edit the command to include `PROD` or `RAW` in the `db_list` if you have access and would like those as well.

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

### Style Guide

Refer to the[ Meltano Data Team handbook](https://handbook.meltano.com/data-team/sql-style-guide) for the SQL style guide information.
