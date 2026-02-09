variable "project_name" {
  description = "Project name for resource naming"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "sns_topic_arn" {
  description = "ARN of SNS topic for notifications"
  type        = string
}

variable "slack_webhook_url" {
  description = "Slack webhook URL (optional)"
  type        = string
  default     = ""
  sensitive   = true
}

variable "pagerduty_integration_key" {
  description = "PagerDuty integration key (optional)"
  type        = string
  default     = ""
  sensitive   = true
}
