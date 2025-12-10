variable "env" {
  type    = string
  default = "dev"
}

variable "aws_region" {
  type    = string
  default = "us-east-1"
}



variable "sns_topic_name" {
  description = "SNS topic for notifications"
  type        = string
  default     = "cloudsec-ir-lab-notify"
}

variable "slack_webhook_url" {
  description = "Slack webhook URL for alerts"
  type        = string
  default     = "" # Fill in once I create the webhook
}

variable "lambda_notify_name" {
  description = "Name of the notification Lambda function"
  type        = string
  default     = "notify_lambda"
}

variable "email_endpoint" {
  description = "Email to receive SNS notifications"
  type = string
}

variable "risky_cidrs" {
  type    = string
  default = "0.0.0.0/0,::/0" 
}
