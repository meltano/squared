# Snowplow

Currently we use https://www.snowcatcloud.com/ to host our Snowplow infrastructure.

When the data lands in S3 we have a Snowpipe set up to continuously load the new files into a Snowflake table `RAW.SNOWPLOW.EVENTS`.
Snowpipes require an external S3 storage integration, a stage, S3 event notifications, and appropriate access to read the data.
The instructions for configuring this are documented in https://docs.snowflake.com/en/user-guide/data-load-snowpipe-auto-s3.html but the high level steps are outlined below:

1. AWS
  - Create IAM policy
  - Create IAM role

2. Snowflake
  - Create Snowflake integration object with new IAM role
  - Retrieve integration object to get the external ID to be used for the AWS trust relationship

3. AWS
  - Add Snowflake external Id as trust relationship for IAM role

4. Snowflake
  - Create stage in Snowflake using the new storage integration object
  - Create Snowpipe
  - Alter permissions on Snowpipe
  - Retrieve SQS queue from Snowpipe, this is a Snowflake internal SQS queue created for us

5. AWS
  - Configure S3 event notification and set Snowpipes SQS Queue ARN as target to write to


We chose to use Terraform in [https://gitlab.com/meltano/squared/-/blob/master/deploy/infrastructure/snowflake.tf](snowflake.tf) to manage AWS resources and have an accountadmin/sysadmin manage the Snowflake objects manually since its a one time operation and accountadmin privileges are required to create storage integrations.
The Snowflake operations for our creating the required objects are in [.snowplow_snowcat_snowpipe.sql](snowplow_snowcat_snowpipe.sql).

Since Snowflake doesnt validate the connection we can run the Snowflake operations first then the external ID, SQS queue ARN, and integration user ARN can be retrieved and passed to the terraform module as input variables.
Once the terraform module is run, the stage should be accessible in Snowflake and the pipe will start loading data once it arrives.
You can also always run the COPY statement from the Snowpipe command to backfill files if they fail to load or if there were any issues during set up.
