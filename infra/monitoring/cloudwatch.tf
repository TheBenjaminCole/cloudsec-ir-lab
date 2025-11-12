##############
# Cloudwatch Log Grps & Alarms
##############

resource "aws_cloudwatch_log_group" "juice_shop" {
  name              = "/cloudsec-ir-lab/juice-shop"
  retention_in_days = 14
}

resource "aws_cloudwatch_metric_alarm" "failed_logins" {
  alarm_name          = "FailedLoginAttempts"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "FailedLogin"
  namespace           = "CloudSecLab/JuiceShop"
  period              = 300
  statistic           = "Sum"
  threshold           = 5
  alarm_actions       = []
}