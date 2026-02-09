output "sns_topic_arn" {
  description = "ARN of the SNS topic for AIOps alerts"
  value       = aws_sns_topic.aiops_alerts.arn
}

output "sns_topic_name" {
  description = "Name of the SNS topic for AIOps alerts"
  value       = aws_sns_topic.aiops_alerts.name
}

output "log_analyzer_lambda_arn" {
  description = "ARN of the log analyzer Lambda function"
  value       = aws_lambda_function.log_analyzer.arn
}

output "log_analyzer_lambda_name" {
  description = "Name of the log analyzer Lambda function"
  value       = aws_lambda_function.log_analyzer.function_name
}

output "anomaly_scorer_lambda_arn" {
  description = "ARN of the anomaly scorer Lambda function"
  value       = aws_lambda_function.anomaly_scorer.arn
}

output "anomaly_scorer_lambda_name" {
  description = "Name of the anomaly scorer Lambda function"
  value       = aws_lambda_function.anomaly_scorer.function_name
}

output "lambda_role_arn" {
  description = "ARN of the IAM role for Lambda functions"
  value       = aws_iam_role.lambda_role.arn
}

output "cloudwatch_dashboard_urls" {
  description = "URLs of CloudWatch dashboards"
  value       = module.cloudwatch_dashboards.dashboard_urls
}
