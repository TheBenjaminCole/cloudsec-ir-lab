##############
# AWS Config
##############

# IAM role AWS Config will assume to deliver configuration snapshots/logs to S3
resource "aws_iam_role" "config_role" {
  name = "cloudsec-ir-lab-config-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action    = "sts:AssumeRole"
        Effect    = "Allow"
        Principal = { Service = "config.amazonaws.com" }
      }
    ]
  })
}

# Inline policy granting S3 permissions for delivery
resource "aws_iam_role_policy" "config_inline_policy" {
  name = "cloudsec-ir-lab-config-delivery"
  role = aws_iam_role.config_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "s3:PutObject",
          "s3:GetBucketAcl",
          "s3:GetBucketLocation",
          "s3:ListBucket"
        ],
        Resource = [
          "${aws_s3_bucket.cloudtrail_logs.arn}",
          "${aws_s3_bucket.cloudtrail_logs.arn}/*"
        ]
      },
      {
        Effect = "Allow",
        Action = [
          "sns:Publish"
        ],
        Resource = "*"
      }
    ]
  })
}

resource "aws_config_configuration_recorder" "recorder" {
  name     = "cloudsec-ir-lab"
  role_arn = aws_iam_role.config_role.arn

  recording_group {
    all_supported = true
  }

  depends_on = [
    aws_iam_role_policy.config_inline_policy
  ]
}

# Delivery channel for Config -> S3
resource "aws_config_delivery_channel" "delivery" {
  name           = "cloudsec-ir-lab-channel"
  s3_bucket_name = aws_s3_bucket.cloudtrail_logs.id

  depends_on = [
    aws_s3_bucket_policy.cloudtrail_logs_policy
  ]
}
