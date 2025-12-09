# # sg_remediation_rule.tf
# data "aws_caller_identity" "current" {}

# resource "aws_cloudwatch_event_rule" "public_sg_ingress" {
#   name        = "cloudsec-ir-public-sg-ssh-ingress"
#   description = "Detect Security Group changes involving 0.0.0.0/0 ingress"

#   event_pattern = jsonencode({
#     "source": ["aws.ec2"],
#     "detail-type": ["AWS API Call via CloudTrail"],
#     "detail": {
#       "eventName": [
#         "AuthorizeSecurityGroupIngress",
#         "RevokeSecurityGroupIngress",
#         "AuthorizeSecurityGroupEgress"
#       ],
#       "userIdentity": {
#         "arn": [
#           {
#             "anything-but": [
#               "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/cloudsec-ir-lab-lambda-role",
#               "arn:aws:sts::${data.aws_caller_identity.current.account_id}:assumed-role/cloudsec-ir-lab-lambda-role/*"
#             ]
#           }
#         ]
#       },
#       "requestParameters": {
#         "ipPermissions": {
#           "items": {
#             "ipRanges": {
#               "items": {
#                 "cidrIp": ["0.0.0.0/0"]
#               }
#             }
#           }
#         }
#       }
#     }
#   })
# }


# resource "aws_cloudwatch_event_target" "sg_to_remediate" {
#   rule = aws_cloudwatch_event_rule.public_sg_ingress.name
#   arn  = aws_lambda_function.remediate.arn
# }

# resource "aws_lambda_permission" "allow_eventbridge_remediate" {
#   statement_id  = "AllowEventBridgeInvokeRemediate"
#   action        = "lambda:InvokeFunction"
#   function_name = aws_lambda_function.remediate.function_name
#   principal     = "events.amazonaws.com"
#   source_arn    = aws_cloudwatch_event_rule.public_sg_ingress.arn
# }
