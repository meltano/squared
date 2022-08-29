# Squared Meltano Project

README files for installed plugins can be found in their respective subdirectories.
For a few plugins they dont have subdiretories so they are described here.

## SQLFluff

This is a utility for linting and fixing SQL, including dbt templated SQL.
Refer to their [GitHub repo](https://github.com/sqlfluff/sqlfluff) for more details.
Visit [MeltanoHub](https://hub.meltano.com/utilities/sqlfluff) for the most up to date installation instructions.

### Linting in CI

Refer to [.gitlab-ci.yml](../.gitlab-ci.yml) to see an exmaple of using SQLFluff in CI for linting.


## AWS CLI

This is the CLI that lets you manage AWS services.
Refer to their [GitHub repo](https://github.com/aws/aws-cli) for more details.

## Adding and Installing

Run the following command to get aws-cli installed in your Meltano project.

```bash
meltano add --custom utility awscli
# (namespace) [awscli]:
# (pip_url) [awscli]: awscli==1.21.7
# (executable) [aws]:

meltano invoke awscli s3 cp file1.txt s3://bucket-name/
```

The utility requires AWS credentials to be set in the environment - Refer to their [GitHub repo](https://github.com/aws/aws-cli) for more details.
This can be done using configuration files but the easiest way is to add `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` to your `.env` file.

If this plugin is run in an ephemeral environment or is run on a machine with a fresh clone of the repo, you will need to install the configured python packages before you can execute the plugin:

```bash
meltano install utility awscli
```

## CI Testing

Refer to [.gitlab-ci.yml](../.gitlab-ci.yml) for full details on how the CI pipelines work.

To summarize - the pipeline will run on a merge request to the default branch to do the following:

- Sqlfluff Linting
- Airflow tests
- EL pipelines run using the [cicd.meltano.yml](./environments/cicd.meltano.yml) configurations.
These take a relative start date or 1 day and writes to an isolated Snowflake environment prefixed with the pipeline ID in the `CICD_RAW` database.
- dbt transformations and tests are run on the isolated EL data that was created

Once tests pass and the code is merged, Docker images are built and terraform is executed to deploy the new code.
Additionally `dbt seed` is run against production to update any CSV files that were added via the merge request and dbt docs are built and deployed using GitLab pages.

Periodically a schedule is run in CI to drop any old CI data so the Snowflake database stays clean.
