output "anomaly_alarm_arns" {
  description = "ARNs of anomaly detection alarms"
  value = {
    lambda_duration_anomaly   = aws_cloudwatch_metric_alarm.lambda_duration_anomaly.arn
    lambda_errors_anomaly     = aws_cloudwatch_metric_alarm.lambda_errors_anomaly.arn
    alb_response_time_anomaly = aws_cloudwatch_metric_alarm.alb_response_time_anomaly.arn
  }
}
