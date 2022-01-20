# Great Expectations

The approach that was taken here was to make expectation suites for every table that we want to test, then checkpoints for configuring a set of expectations that we want to run together relative to our DAG structure.
Usually we will have a DAG which runs EL, a checkpoint for the raw data, all dbt models, a checkpoint for final dbt output consumption models.

The strategy for using great_expectations in this project is to test the boundaries of our dbt project.
The raw data that is used as a dbt source and the final dbt models that were consuming have expectations that need to pass for a successful pipeline run.


In order to run great_expectations the current working directory needs to be in the `utilities/great_expectations/` directory where the great_expectations.yml configuration file is.

```bash
cd utilities/great_expectations/

# Run the dbt_hub_metrics checkpoint to validate for failures
meltano --environment=prod invoke great_expectations checkpoint run dbt_hub_metrics

# Add a new expecation suite
meltano --environment=prod invoke great_expectations suite new

# Edit an existing suite
meltano --environment=prod invoke great_expectations suite edit dbt_hub_metrics

# Add a new checkpoint (one or more expectation suites to validate against)
meltano --environment=prod invoke great_expectations checkpoint add my_new_checkpoint
```