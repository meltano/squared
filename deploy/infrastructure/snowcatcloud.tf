# Setup snowcatcloud S3 bucket in us-west-2 (as per vendor instructions)

resource "aws_s3_bucket" "snowcat" {
  bucket = "mirror-sc-data-snowcat.meltano.com"
  acl    = "private"

  versioning {
    enabled = true
  }

  provider = aws.us_west_2

}

resource "aws_s3_bucket_policy" "allow_access_from_snowcat_account" {
  bucket   = aws_s3_bucket.snowcat.id
  policy   = file("templates/snowcat_s3_policy.json")
  provider = aws.us_west_2
}