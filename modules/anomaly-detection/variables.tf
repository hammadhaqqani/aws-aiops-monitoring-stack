variable "project_name" {
  description = "Project name for resource naming"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "sns_topic_arn" {
  description = "ARN of SNS topic for anomaly notifications"
  type        = string
}

variable "anomaly_detection_metrics" {
  description = "List of metrics to enable anomaly detection for"
  type = list(object({
    namespace = string
    metric_name = string
    statistic = string
  }))
  default = [
    {
      namespace  = "AWS/Lambda"
      metric_name = "Duration"
      statistic  = "Average"
    },
    {
      namespace  = "AWS/Lambda"
      metric_name = "Errors"
      statistic  = "Sum"
    }
  ]
}
