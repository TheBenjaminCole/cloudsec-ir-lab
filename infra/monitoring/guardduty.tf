##############
# Guard Duty
##############

resource "aws_guardduty_detector" "detector" {
  enable                       = true
  finding_publishing_frequency = "FIFTEEN_MINUTES"
}

