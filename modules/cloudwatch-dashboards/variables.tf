variable "project_name" {
  description = "Project name for resource naming"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "log_groups" {
  description = "List of CloudWatch Log Groups to monitor"
  type        = list(string)
  default     = []
}
