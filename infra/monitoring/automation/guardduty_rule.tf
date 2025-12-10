# # guardduty_rule.tf
# resource "aws_cloudwatch_event_rule" "guardduty_findings" {
#   name        = "cloudsec-ir-guardduty-findings"
#   description = "Forward GuardDuty findings to notify lambda"
#   event_pattern = jsonencode({
#     "source" : ["aws.guardduty"],
#     # match all findings - can refine severity / types later
#   })
# }

# resource "aws_cloudwatch_event_target" "gd_to_notify" {
#   rule = aws_cloudwatch_event_rule.guardduty_findings.name
#   arn  = aws_lambda_function.notify.arn
# }

# resource "aws_lambda_permission" "allow_eventbridge_notify" {
#   statement_id  = "AllowEventBridgeInvokeNotify"
#   action        = "lambda:InvokeFunction"
#   function_name = aws_lambda_function.notify.function_name
#   principal     = "events.amazonaws.com"
#   source_arn    = aws_cloudwatch_event_rule.guardduty_findings.arn
# }
