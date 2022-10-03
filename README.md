# Squared - Meltano for Meltano

This is the project the Meltano team uses to manage their Meltano instance. 

This project is used to process data for [MeltanoHub](https://hub.meltano.com/) and for internal metrics as defined in the [Handbook](https://handbook.meltano.com/data-team/). 

The primary maintainer is @pnadolny13. 
The primary slack channel for discussion is [#meltano-squared](https://meltano.slack.com/archives/C02GH7KNPAL).

## Why use Meltano to manage data at Meltano?
*"We don't just eat our own dog food, we embrace it! Meltano supercharges every part of our day-to-day work inside the data team."*

Our data team keeps on pushing the edge on use cases for [Meltano](https://docs.meltano.com/getting-started/meltano-at-a-glance), and utilizes all of the advanced features, including deployment to Kubernetes and CI/CD integrations. (All of which you can find in this repository)

We love our own Meltano because it allowed us to **start simple, provides DataOps out-of-the-box, integrates with everything, is easily customizable** (we do a lot of customizations), **it's a mature system and has first class ELT support** (our most important use case).

To get started with Meltano yourself, head over to the [Installation](https://docs.meltano.com/getting-started/installation), or if you already have Meltano installed, to [the Meltano Tutorial](https://docs.meltano.com/getting-started/part1). 

---

## Repo Plugins

These are all of the plugins that are currently being using in this repo.

Extractors:
- [Google Analytics](https://github.com/MeltanoLabs/tap-google-analytics)
- [Slack](https://github.com/MeltanoLabs/tap-slack)
- [GitLab](https://github.com/MeltanoLabs/tap-gitlab)
- [GitHub](https://github.com/MeltanoLabs/tap-github)
- [Snowflake](https://github.com/pnadolny13/pipelinewise-tap-snowflake)
- [Spreadsheets Anywhere](https://github.com/ets/tap-spreadsheets-anywhere)
- [MeltanoHub](https://github.com/AutoIDM/tap-meltanohub)

Mappers:
- [Meltano Map Transformer](https://github.com/MeltanoLabs/meltano-map-transform)

Loaders:
- [Snowflake](https://github.com/transferwise/pipelinewise-target-snowflake)
- [Yaml](https://github.com/MeltanoLabs/target-yaml)

Transformers:
- [dbt-snowflake](https://github.com/dbt-labs/dbt-core) -  Refer to the Squared [dbt README](./data/transform/README.md) for more detail on how its used in this repo.

Orchestrators:
- [Apache Airflow](https://github.com/apache/airflow/) -  Refer to the Squared [Airflow README](./data/orchestrate/README.md) for more detail on how its used in this repo. Visit [MeltanoHub](https://hub.meltano.com/orchestrators/airflow) for installation instructions.

Analyzers:
- [Apache Superset](https://github.com/apache/superset) - Refer to the Squared [Superset README](./data/analyze/README.md) for more detail on how its used in this repo. Visit [MeltanoHub](https://hub.meltano.com/utilities/superset) for installation instructions.

Utilities:
- [AWS CLI](https://github.com/aws/aws-cli) - Refer to the Squared [General README](./data/README.md) for more detail on how its used in this repo.
- [SqlFluff](https://github.com/sqlfluff/sqlfluff) - Refer to the Squared [General README](./data//README.md) for more detail on how its used in this repo. Visit [MeltanoHub](https://hub.meltano.com/utilities/sqlfluff) for installation instructions.
- [Great Expectations](https://github.com/great-expectations/great_expectations) - Refer to the Squared [Great Expectations README](./data/utilities/great_expectations/README.md) for more detail on how its used in this repo. Visit [MeltanoHub](https://hub.meltano.com/utilities/great_expectations) for installation instructions.
- [Permifrost](https://gitlab.com/gitlab-data/permifrost) - Refer to the Squared [Permifrost README](./data/utilities/permifrost/README.md) for more detail on how its used in this repo.


## Architectural Decision Records (ADR)

This Squared project makes use of ADR's to record architectural decisions roughly as [described by Michael Nygard](http://thinkrelevance.com/blog/2011/11/15/documenting-architecture-decisions). 
In a nutshell, these are used to document architectural decisions and to provide a record of the decisions made by the team and contributors in regard to the Squared project's architecture. These are held in [docs/adr](https://gitlab.com/meltano/squared/-/tree/master/docs/adr). 
To propose or add a new ADR, its simplest to create a new entry using [adr-tools](https://github.com/npryce/adr-tools), and then send a long a merge request for review.

```bash
brew install adr-tools
adr new <My ADR Name>
```
