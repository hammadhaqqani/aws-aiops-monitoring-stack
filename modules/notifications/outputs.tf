output "slack_notifier_arn" {
  description = "ARN of Slack notifier Lambda function"
  value       = var.slack_webhook_url != "" ? aws_lambda_function.slack_notifier[0].arn : null
}

output "pagerduty_notifier_arn" {
  description = "ARN of PagerDuty notifier Lambda function"
  value       = var.pagerduty_integration_key != "" ? aws_lambda_function.pagerduty_notifier[0].arn : null
}
