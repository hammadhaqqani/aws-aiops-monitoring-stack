variable "project_name" {
  description = "Project name for resource naming"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "sns_topic_arn" {
  description = "ARN of SNS topic for cost anomaly notifications"
  type        = string
}

variable "account_id" {
  description = "AWS Account ID"
  type        = string
}

variable "monitor_name" {
  description = "Name for the cost anomaly monitor"
  type        = string
  default     = "AIOpsCostMonitor"
}

variable "threshold" {
  description = "Threshold for cost anomaly detection (dollars)"
  type        = number
  default     = 50
}
