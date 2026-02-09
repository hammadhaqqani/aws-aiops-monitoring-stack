# Lambda Error Rate Alarm
resource "aws_cloudwatch_metric_alarm" "lambda_errors" {
  alarm_name          = "${var.project_name}-lambda-errors-${var.environment}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = 300
  statistic           = "Sum"
  threshold           = var.lambda_error_threshold
  alarm_description   = "This metric monitors lambda function errors"
  alarm_actions       = [var.sns_topic_arn]
  treat_missing_data  = "notBreaching"

  dimensions = {
    FunctionName = "${var.project_name}-*"
  }

  tags = {
    Name = "${var.project_name}-lambda-errors-alarm"
  }
}

# Lambda Duration Alarm
resource "aws_cloudwatch_metric_alarm" "lambda_duration" {
  alarm_name          = "${var.project_name}-lambda-duration-${var.environment}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "Duration"
  namespace           = "AWS/Lambda"
  period              = 300
  statistic           = "Average"
  threshold           = var.lambda_duration_threshold
  alarm_description   = "This metric monitors lambda function duration"
  alarm_actions       = [var.sns_topic_arn]
  treat_missing_data  = "notBreaching"

  dimensions = {
    FunctionName = "${var.project_name}-*"
  }

  tags = {
    Name = "${var.project_name}-lambda-duration-alarm"
  }
}

# Lambda Throttles Alarm
resource "aws_cloudwatch_metric_alarm" "lambda_throttles" {
  alarm_name          = "${var.project_name}-lambda-throttles-${var.environment}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "Throttles"
  namespace           = "AWS/Lambda"
  period              = 300
  statistic           = "Sum"
  threshold           = 1
  alarm_description   = "This metric monitors lambda function throttles"
  alarm_actions       = [var.sns_topic_arn]
  treat_missing_data  = "notBreaching"

  dimensions = {
    FunctionName = "${var.project_name}-*"
  }

  tags = {
    Name = "${var.project_name}-lambda-throttles-alarm"
  }
}

# Log Group Error Pattern Alarm (if log groups are provided)
resource "aws_cloudwatch_log_metric_filter" "error_pattern" {
  count = length(var.log_groups) > 0 ? 1 : 0

  name           = "${var.project_name}-error-pattern-${var.environment}"
  log_group_name = var.log_groups[0]
  pattern        = "[timestamp, request_id, level=ERROR, ...]"

  metric_transformation {
    name      = "ErrorCount"
    namespace = "${var.project_name}/Logs"
    value     = "1"
  }
}

resource "aws_cloudwatch_metric_alarm" "log_errors" {
  count = length(var.log_groups) > 0 ? 1 : 0

  alarm_name          = "${var.project_name}-log-errors-${var.environment}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "ErrorCount"
  namespace           = "${var.project_name}/Logs"
  period              = 300
  statistic           = "Sum"
  threshold           = 10
  alarm_description   = "This metric monitors error patterns in logs"
  alarm_actions       = [var.sns_topic_arn]
  treat_missing_data  = "notBreaching"

  tags = {
    Name = "${var.project_name}-log-errors-alarm"
  }
}

# Composite Alarm combining multiple alarms
resource "aws_cloudwatch_composite_alarm" "critical_issues" {
  alarm_name        = "${var.project_name}-critical-issues-${var.environment}"
  alarm_description = "Composite alarm for critical infrastructure issues"

  alarm_rule = "ALARM(${aws_cloudwatch_metric_alarm.lambda_errors.alarm_name}) OR ALARM(${aws_cloudwatch_metric_alarm.lambda_throttles.alarm_name})"

  alarm_actions = [var.sns_topic_arn]

  tags = {
    Name = "${var.project_name}-critical-composite-alarm"
  }
}
