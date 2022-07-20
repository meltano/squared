data "aws_ssm_parameter" "snowpipe" {
  name = "/prod/meltano/snowpipe"
}

locals {
  snowpipe = yamldecode(data.aws_ssm_parameter.snowpipe.value)
}

data "template_file" "snowflake_trust_policy_template" {
  template = file("${path.module}/templates/snowflake_trust_policy.json")
  vars = {
    snowflake_account_arn = "${local.snowpipe.snowflake_account_arn}"
    snowflake_external_id = "${local.snowpipe.snowflake_external_id}"
  }
}

resource "aws_iam_role" "snowflake_read_role" {
  name               = "snowflake-read-role"
  description        = "AWS role for Snowflake"
  assume_role_policy = data.template_file.snowflake_trust_policy_template.rendered
}

resource "aws_iam_policy" "allow_s3_read_assess_to_snowflake" {
  name   = "snowflake_storage_integration"
  policy = file("${path.module}/templates/snowflake_s3_policy.json")
}

resource "aws_iam_role_policy_attachment" "snowflake_read_role_policy_attachment" {
  role       = aws_iam_role.snowflake_read_role.name
  policy_arn = aws_iam_policy.allow_s3_read_assess_to_snowflake.arn
}

resource "aws_s3_bucket_notification" "bucket_notification" {
  bucket = aws_s3_bucket.snowcat.id

  provider = aws.us_west_2

  queue {
    queue_arn     = local.snowpipe.snowflake_sqs_arn
    events        = ["s3:ObjectCreated:*"]
    filter_prefix = "customer-data/meltano/enriched/stream/"
    filter_suffix = ".gz"
  }
}

resource "aws_s3_bucket_notification" "bucket_notification_bad" {
  bucket = aws_s3_bucket.snowcat.id

  provider = aws.us_west_2

  queue {
    queue_arn     = local.snowpipe.snowflake_sqs_arn
    events        = ["s3:ObjectCreated:*"]
    filter_prefix = "customer-data/meltano/enriched/bad/"
    filter_suffix = ".gz"
  }
}
