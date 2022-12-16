resource "aws_s3_bucket" "meltano-squared-prod" {
  bucket = "meltano-squared-prod"
  acl    = "private"

  versioning {
    enabled = true
  }

  provider = aws.us_west_2

}