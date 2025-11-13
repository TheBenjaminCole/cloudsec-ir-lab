#########################
# Phase 3: CloudTrail + Monitoring
#########################

#########################
# Data sources
#########################
data "aws_caller_identity" "current" {}

#########################
# CloudTrail S3 Bucket
#########################
resource "aws_s3_bucket" "cloudtrail_logs" {
  bucket = "cloudsec-ir-lab-cloudtrail-logs-${var.env}"

  tags = {
    Name        = "cloudsec-ir-lab-cloudtrail-logs-${var.env}"
    Environment = var.env
  }
}

# Versioning
resource "aws_s3_bucket_versioning" "cloudtrail_logs_versioning" {
  bucket = aws_s3_bucket.cloudtrail_logs.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "cloudtrail_logs_encryption" {
  bucket = aws_s3_bucket.cloudtrail_logs.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Block Public Access
resource "aws_s3_bucket_public_access_block" "cloudtrail_logs_public_access" {
  bucket                  = aws_s3_bucket.cloudtrail_logs.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

#########################
# S3 Bucket Policy (allow CloudTrail and AWS Config to write)
# - CloudTrail uses the service principal to write to bucket
# - AWS Config needs permission to put objects
#########################
resource "aws_s3_bucket_policy" "cloudtrail_logs_policy" {
  bucket = aws_s3_bucket.cloudtrail_logs.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      # CloudTrail needs to check the bucket ACL
      {
        Sid       = "AWSCloudTrailBucketAclCheck"
        Effect    = "Allow"
        Principal = { Service = "cloudtrail.amazonaws.com" }
        Action    = "s3:GetBucketAcl"
        Resource  = aws_s3_bucket.cloudtrail_logs.arn
      },

      # CloudTrail to put objects into the AWSLogs
      {
        Sid       = "AWSCloudTrailWrite"
        Effect    = "Allow"
        Principal = { Service = "cloudtrail.amazonaws.com" }
        Action    = "s3:PutObject"
        Resource  = "${aws_s3_bucket.cloudtrail_logs.arn}/AWSLogs/${data.aws_caller_identity.current.account_id}/*"
        Condition = {
          StringEquals = {
            "s3:x-amz-acl" = "bucket-owner-full-control"
          }
        }
      },

      # AWS Config needs to be able to get bucket ACL and put objects
      {
        Sid       = "AWSConfigBucketPermissionsCheck"
        Effect    = "Allow"
        Principal = { Service = "config.amazonaws.com" }
        Action    = "s3:GetBucketAcl"
        Resource  = aws_s3_bucket.cloudtrail_logs.arn
      },

      {
        Sid       = "AWSConfigBucketDelivery"
        Effect    = "Allow"
        Principal = { Service = "config.amazonaws.com" }
        Action    = "s3:PutObject"
        Resource  = "${aws_s3_bucket.cloudtrail_logs.arn}/*"
      }
    ]
  })
}

#########################
# CloudWatch Log Group for CloudTrail
#########################
resource "aws_cloudwatch_log_group" "cloudtrail_logs" {
  name              = "/cloudtrail/logs"
  retention_in_days = 90
}

#########################
# IAM Role CloudTrail will assume to write to CloudWatch Logs
# (CloudTrail service principal writes to S3, need a role to let CloudTrail push to CW Logs)
#########################
resource "aws_iam_role" "cloudtrail_logs_role" {
  name_prefix = "cloudtrail-logs-role-"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { Service = "cloudtrail.amazonaws.com" }
        Action    = "sts:AssumeRole"
      }
    ]
  })
}

# Inline policy for the role: allow create stream & put log events on the log group
resource "aws_iam_role_policy" "cloudtrail_logs_role_policy" {
  name = "cloudtrail-logs-write"
  role = aws_iam_role.cloudtrail_logs_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "${aws_cloudwatch_log_group.cloudtrail_logs.arn}:*"
      },
      # allow describe for good measure
      {
        Effect = "Allow"
        Action = [
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams"
        ]
        Resource = "*"
      }
    ]
  })
}

#####################
# CloudTrail
#####################
resource "aws_cloudtrail" "main" {
  name                          = "cloudsec-ir-lab-trail"
  s3_bucket_name                = aws_s3_bucket.cloudtrail_logs.id
  include_global_service_events = true
  is_multi_region_trail         = true
  enable_logging                = true

  # CloudWatch integration
  cloud_watch_logs_group_arn = "${aws_cloudwatch_log_group.cloudtrail_logs.arn}:*"
  cloud_watch_logs_role_arn  = aws_iam_role.cloudtrail_logs_role.arn

  event_selector {
    read_write_type           = "All"
    include_management_events = true
  }

  depends_on = [
    aws_s3_bucket_policy.cloudtrail_logs_policy,
    aws_iam_role_policy.cloudtrail_logs_role_policy
  ]
}
