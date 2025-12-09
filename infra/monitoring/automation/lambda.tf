data "archive_file" "sg_remediate_zip" {
  type        = "zip"
  output_path = "${path.module}/sg_remediate.zip"
  source {
    content  = file("${path.module}/lambda/sg_remediate.py")
    filename = "sg_remediate.py"
  }
}

resource "aws_lambda_function" "sg_autoremediate" {
  filename      = data.archive_file.sg_remediate_zip.output_path
  function_name = "sg-autoremediate"
  handler       = "sg_remediate.lambda_handler"
  runtime       = "python3.11"
  role          = aws_iam_role.lambda_auto_remediate.arn
  timeout       = 30
  memory_size   = 256

  environment {
    variables = {
      LAMBDA_ROLE_ARN         = aws_iam_role.lambda_auto_remediate.arn
      SNS_TOPIC_ARN           = aws_sns_topic.sg_remediation.arn
      REMEDIATION_TAG_KEY     = "auto-remediated"
      REMEDIATION_TTL_MINUTES = "60" # tag considered active for 60 minutes
    }
  }

  source_code_hash = data.archive_file.sg_remediate_zip.output_base64sha256

  depends_on = [
    aws_iam_role_policy.lambda_sg_remediation_policy,
    aws_iam_role_policy_attachment.lambda_basic_execution,
    aws_sns_topic.sg_remediation
  ]
}

# giving EventBridge permission to invoke lambda
resource "aws_lambda_permission" "allow_eventbridge" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.sg_autoremediate.function_name
  principal     = "events.amazonaws.com"
}
