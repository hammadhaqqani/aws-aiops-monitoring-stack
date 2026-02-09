output "alarm_arns" {
  description = "ARNs of CloudWatch alarms"
  value = {
    lambda_errors    = aws_cloudwatch_metric_alarm.lambda_errors.arn
    lambda_duration  = aws_cloudwatch_metric_alarm.lambda_duration.arn
    lambda_throttles = aws_cloudwatch_metric_alarm.lambda_throttles.arn
    composite_alarm  = aws_cloudwatch_composite_alarm.critical_issues.arn
  }
}
