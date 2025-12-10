# # iam_changes_rule.tf
# resource "aws_cloudwatch_event_rule" "iam_changes" {
#   name        = "cloudsec-ir-iam-changes"
#   description = "Capture IAM policy/user/role changes"
#   event_pattern = jsonencode({
#     "source" : ["aws.iam", "aws.identitystore", "aws.sts", "aws.cloudtrail"],
#     "detail-type" : ["AWS API Call via CloudTrail"],
#     "detail" : {
#       "eventName" : [
#         "CreateUser",
#         "DeleteUser",
#         "CreateRole",
#         "PutUserPolicy",
#         "PutRolePolicy",
#         "AttachRolePolicy",
#         "DetachRolePolicy",
#         "DeleteRolePolicy",
#         "UpdateAssumeRolePolicy"
#       ]
#     }
#   })
# }

# resource "aws_cloudwatch_event_target" "iam_to_notify" {
#   rule = aws_cloudwatch_event_rule.iam_changes.name
#   arn  = aws_lambda_function.notify.arn
# }

# resource "aws_lambda_permission" "allow_eventbridge_notify_iam" {
#   statement_id  = "AllowEventBridgeInvokeNotifyIAM"
#   action        = "lambda:InvokeFunction"
#   function_name = aws_lambda_function.notify.function_name
#   principal     = "events.amazonaws.com"
#   source_arn    = aws_cloudwatch_event_rule.iam_changes.arn
# }
