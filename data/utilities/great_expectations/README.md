# Great Expectations

## Adding and Installing

Run the following command to get great_expecations installed in your Meltano project.
Depending on your datasource you might need to install additional python dependencies (i.e. sqlalchemy, PyAthena, and PyAthena for this case).

```bash
meltano add --custom utility great_expectations
# (namespace) [great_expectations]:
# (pip_url) [great_expectations]: great_expectations; sqlalchemy; PyAthenaJDBC>1.0.9; PyAthena>1.2.0
# (executable) [great_expectations]:
```


In order for Meltano to know where to find your GE project, manually add a `settings` entry to your meltano.yml config so it looks like the following:

```yaml
  - name: great_expectations
    namespace: great_expectations
    pip_url: great_expectations; sqlalchemy; PyAthenaJDBC>1.0.9; PyAthena>1.2.0
    executable: great_expectations
    settings:
      - name: ge_home
        value: $MELTANO_PROJECT_ROOT/utilities/great_expectations
        env: GE_HOME
```

If this plugin is run in an ephemeral environment or is run on a machine with a fresh clone of the repo, you will need to install the configured python packages before you can execute the plugin:

```bash
meltano install utility great_expectations
```

## Squared Implementation Notes

Great Expectations can be used in many ways, the following is the details around how we chose to use GE in this repo.
## Approach
The strategy for using great_expectations in this project is to test the boundaries of our dbt project.
The raw data that is used as a dbt source and the final dbt models that were consuming have expectations that need to pass for a successful pipeline run.

The approach that was taken here was to make expectation suites for every table that we want to test, then checkpoints for configuring a set of expectations that we want to run together relative to our DAG structure.
Usually we will have a DAG which runs EL, a checkpoint for the raw data, all dbt models, a checkpoint for final dbt output consumption models.

```bash
# Run the dbt_hub_metrics checkpoint to validate for failures
meltano --environment=prod invoke great_expectations checkpoint run dbt_hub_metrics

# Add a new expecation suite
meltano --environment=prod invoke great_expectations suite new

# Edit an existing suite
meltano --environment=prod invoke great_expectations suite edit dbt_hub_metrics

# Add a new checkpoint (one or more expectation suites to validate against)
meltano --environment=prod invoke great_expectations checkpoint add my_new_checkpoint
```

## Other Details

In our `great_expecations.yml` file and `checkpoints/*.yml` we templated out our secrets (i.e. AWS keys) and environment specific configurations (i.e. schema) so that we could pass those from our `.env` and `*meltano.yml` configurations.
