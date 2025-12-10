resource "aws_cloudwatch_event_rule" "sg_ingress_added" {
    name        = "sg-ingress-added"
  description = "Trigger when security group ingress is authorized."
  event_pattern = jsonencode({
    "detail-type": ["AWS API Call via CloudTrail"],
    "detail": {
      "eventSource": ["ec2.amazonaws.com"],
      "eventName": ["AuthorizeSecurityGroupIngress","AuthorizeSecurityGroupEgress"]
    }
  })
}

resource "aws_cloudwatch_event_target" "lambda_target" {
  rule      = aws_cloudwatch_event_rule.sg_ingress_added.name
  arn       = aws_lambda_function.sg_autoremediate.arn
  target_id = "sg-autoremediate-target"
}