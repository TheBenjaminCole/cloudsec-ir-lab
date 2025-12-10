# -------------------------------------------------
# IAM ROLE LAMBDA
# -------------------------------------------------
resource "aws_iam_role" "lambda_auto_remediate" {
  name = "lambda-sg-autoremediate-cloudsec-ir-lab"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

# policy attachment - lambda
resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  role       = aws_iam_role.lambda_auto_remediate.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# inline policy for EC2 + SNS tagging
resource "aws_iam_role_policy" "lambda_sg_remediation_policy" {
  name = "lambda_sg_remediation-cloudsec-ir-lab"
  role = aws_iam_role.lambda_auto_remediate.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid    = "EC2SecurityGroupActions"
        Effect = "Allow"
        Action = [
          "ec2:DescribeSecurityGroups",
          "ec2:RevokeSecurityGroupIngress",
          "ec2:DescribeTags",
          "ec2:CreateTags"
        ]
        Resource = "*"
      },
      {
        Sid    = "SNSPublish"
        Effect = "Allow"
        Action = [
          "sns:Publish"
        ]
        Resource = [
          aws_sns_topic.sg_remediation.arn 
        ]
      }
    ]
  })
}