# Squared - Meltano for Meltano

This is the project the Meltano team uses to manage their Meltano instance. 

This project is used to process data for [MeltanoHub](https://hub.meltano.com/) and for internal metrics as defined in the [Handbook](https://handbook.meltano.com/data-team/). 

The primary maintainer is @pnadolny13. 
The primary slack channel for discussion is [#meltano-cubed](https://meltano.slack.com/archives/C02GH7KNPAL).

## Repo Plugins

These are all of the plugins that are currently being using in this repo.

Extractors:
- [Google Analytics](https://hub.meltano.com/taps/google-analytics)
- [Slack](https://github.com/MeltanoLabs/tap-slack)
- [GitLab](https://hub.meltano.com/taps/gitlab)
- [Athena](https://hub.meltano.com/taps/athena)

Loaders:
- [Athena](https://hub.meltano.com/targets/athena)
- [Yaml](https://hub.meltano.com/targets/yaml)

Transformers:
- [dbt](https://github.com/dbt-labs/dbt-core) -  Refer to the Squared [plugin subdirectory](./data/transform/) for more detail on how its used in this repo.

Orchestrators:
- [Apache Airflow](https://github.com/apache/airflow/) -  Refer to the Squared [plugin subdirectory](./data/orchestrate/) for more detail on how its used in this repo.

Analyzers:
- [Apache Superset](https://github.com/apache/superset) - Refer to the Squared [Superset README](./data/analyze/README.md) for more detail on how its used in this repo.

Utilities:
- [AWS CLI](https://github.com/aws/aws-cli) - Refer to the Squared [General README](./data/README.md) for more detail on how its used in this repo.
- [SqlFluff](https://github.com/sqlfluff/sqlfluff) - Refer to the Squared [General README](./data//README.md) for more detail on how its used in this repo.
- [Great Expectations](https://github.com/great-expectations/great_expectations) - Refer to the Squared [Great Expectations README](./data/utilities/great_expectations/README.md) for more detail on how its used in this repo.
- [Permifrost](https://gitlab.com/gitlab-data/permifrost) - Refer to the Squared [Permifrost README](./data/utilities/permifrost/README.md) for more detail on how its used in this repo.

