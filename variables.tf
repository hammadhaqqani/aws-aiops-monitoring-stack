variable "region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
  default     = "prod"
}

variable "project_name" {
  description = "Project name for resource naming and tagging"
  type        = string
  default     = "aiops-monitoring"
}

variable "enable_anomaly_detection" {
  description = "Enable CloudWatch anomaly detection"
  type        = bool
  default     = true
}

variable "enable_cost_anomaly_detection" {
  description = "Enable AWS Cost Anomaly Detection"
  type        = bool
  default     = true
}

variable "slack_webhook_url" {
  description = "Slack webhook URL for notifications (optional)"
  type        = string
  default     = ""
  sensitive   = true
}

variable "pagerduty_integration_key" {
  description = "PagerDuty integration key for critical alerts (optional)"
  type        = string
  default     = ""
  sensitive   = true
}

variable "sns_email_addresses" {
  description = "List of email addresses for SNS notifications"
  type        = list(string)
  default     = []
}

variable "lambda_memory_size" {
  description = "Memory size for Lambda functions in MB"
  type        = number
  default     = 512
}

variable "lambda_timeout" {
  description = "Timeout for Lambda functions in seconds"
  type        = number
  default     = 300
}

variable "tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default     = {}
}

variable "log_groups" {
  description = "List of CloudWatch Log Groups to monitor"
  type        = list(string)
  default     = []
}

variable "enable_bedrock" {
  description = "Enable AWS Bedrock for advanced AI analysis"
  type        = bool
  default     = false
}

variable "bedrock_model_id" {
  description = "Bedrock model ID for AI analysis"
  type        = string
  default     = "anthropic.claude-3-sonnet-20240229-v1:0"
}
