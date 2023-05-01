### Squared User - S3 Read Access

resource "aws_iam_user" "hub_system_user" {
  name = "hub_system_user"
}

resource "aws_iam_access_key" "hub_system_user" {
  user    = aws_iam_user.hub_system_user.name
}

resource "aws_iam_user_policy" "hub_system_user_policy" {
  name = "hub_system_user_policy"
  user = aws_iam_user.hub_system_user.name

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "s3:Get*",
        "s3:List*"
      ],
      "Effect": "Allow",
      "Resource": "arn:aws:s3:::meltano-squared-prod/hub_metrics/*"
    }
  ]
}
EOF
}

### Squared User - S3 Write Access

resource "aws_iam_user" "squared_system_user" {
  name = "squared_system_user"
}

resource "aws_iam_access_key" "squared_system_user" {
  user    = aws_iam_user.squared_system_user.name
}

resource "aws_iam_user_policy" "squared_system_user_policy" {
  name = "squared_system_user_policy"
  user = aws_iam_user.squared_system_user.name

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "s3:Get*",
        "s3:List*",
        "s3:PutObject*"
      ],
      "Effect": "Allow",
      "Resource": "arn:aws:s3:::meltano-squared-prod/hub_metrics/*"
    }
  ]
}
EOF
}

## Output IDs and Encrypted Secrets

output "hub_system_user_secret" {
  value = aws_iam_access_key.hub_system_user.encrypted_secret
}

output "hub_system_user_id" {
  value = aws_iam_access_key.hub_system_user.id
}

output "squared_system_user_secret" {
  value = aws_iam_access_key.squared_system_user.encrypted_secret
}

output "squared_system_user_id" {
  value = aws_iam_access_key.squared_system_user.id
}
