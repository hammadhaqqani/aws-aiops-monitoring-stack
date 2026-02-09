# CloudWatch Anomaly Detection for Lambda Duration
resource "aws_cloudwatch_metric_alarm" "lambda_duration_anomaly" {
  alarm_name          = "${var.project_name}-lambda-duration-anomaly-${var.environment}"
  comparison_operator = "GreaterThanUpperThreshold"
  evaluation_periods  = 2
  threshold_metric_id = "e1"
  alarm_description   = "This alarm triggers when Lambda duration exceeds expected range"

  metric_query {
    id          = "e1"
    expression  = "ANOMALY_DETECTION_BAND(m1, 2)"
    label       = "Lambda Duration (Expected)"
    return_data = "true"
  }

  metric_query {
    id          = "m1"
    return_data = "true"
    metric {
      metric_name = "Duration"
      namespace   = "AWS/Lambda"
      period      = 300
      stat        = "Average"
      unit        = "Milliseconds"

      dimensions = {
        FunctionName = "${var.project_name}-*"
      }
    }
  }

  alarm_actions = [var.sns_topic_arn]

  tags = {
    Name = "${var.project_name}-lambda-duration-anomaly"
  }
}

# CloudWatch Anomaly Detection for Lambda Errors
resource "aws_cloudwatch_metric_alarm" "lambda_errors_anomaly" {
  alarm_name          = "${var.project_name}-lambda-errors-anomaly-${var.environment}"
  comparison_operator = "GreaterThanUpperThreshold"
  evaluation_periods  = 1
  threshold_metric_id = "e1"
  alarm_description   = "This alarm triggers when Lambda errors exceed expected range"

  metric_query {
    id          = "e1"
    expression  = "ANOMALY_DETECTION_BAND(m1, 3)"
    label       = "Lambda Errors (Expected)"
    return_data = "true"
  }

  metric_query {
    id          = "m1"
    return_data = "true"
    metric {
      metric_name = "Errors"
      namespace   = "AWS/Lambda"
      period      = 300
      stat        = "Sum"
      unit        = "Count"

      dimensions = {
        FunctionName = "${var.project_name}-*"
      }
    }
  }

  alarm_actions = [var.sns_topic_arn]

  tags = {
    Name = "${var.project_name}-lambda-errors-anomaly"
  }
}

# CloudWatch Anomaly Detection for Application Load Balancer Response Time
resource "aws_cloudwatch_metric_alarm" "alb_response_time_anomaly" {
  alarm_name          = "${var.project_name}-alb-response-time-anomaly-${var.environment}"
  comparison_operator = "GreaterThanUpperThreshold"
  evaluation_periods  = 2
  threshold_metric_id = "e1"
  alarm_description   = "This alarm triggers when ALB response time exceeds expected range"

  metric_query {
    id          = "e1"
    expression  = "ANOMALY_DETECTION_BAND(m1, 2)"
    label       = "ALB Response Time (Expected)"
    return_data = "true"
  }

  metric_query {
    id          = "m1"
    return_data = "true"
    metric {
      metric_name = "TargetResponseTime"
      namespace   = "AWS/ApplicationELB"
      period      = 300
      stat        = "Average"
      unit        = "Seconds"
    }
  }

  alarm_actions = [var.sns_topic_arn]

  tags = {
    Name = "${var.project_name}-alb-response-time-anomaly"
  }
}
