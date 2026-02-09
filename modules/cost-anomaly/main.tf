# Cost Anomaly Detection Monitor
resource "aws_ce_anomaly_monitor" "cost_monitor" {
  name              = "${var.project_name}-${var.monitor_name}-${var.environment}"
  monitor_type      = "DIMENSIONAL"
  monitor_dimension = "SERVICE"

  tags = {
    Name = "${var.project_name}-cost-monitor"
  }
}

# Cost Anomaly Detection Subscription
resource "aws_ce_anomaly_subscription" "cost_subscription" {
  name             = "${var.project_name}-cost-subscription-${var.environment}"
  monitor_arn_list = [aws_ce_anomaly_monitor.cost_monitor.arn]
  frequency        = "DAILY"
  threshold_expression {
    dimension {
      key           = "ANOMALY_TOTAL_IMPACT_ABSOLUTE"
      values        = [tostring(var.threshold)]
      match_options = ["GREATER_THAN_OR_EQUAL"]
    }
  }

  subscriber {
    type    = "SNS"
    address = var.sns_topic_arn
  }

  tags = {
    Name = "${var.project_name}-cost-subscription"
  }
}

# CloudWatch Alarm for Billing
resource "aws_cloudwatch_metric_alarm" "billing_threshold" {
  alarm_name          = "${var.project_name}-billing-threshold-${var.environment}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "EstimatedCharges"
  namespace           = "AWS/Billing"
  period              = 86400
  statistic           = "Maximum"
  threshold           = var.threshold
  alarm_description   = "Alarm when estimated charges exceed threshold"
  alarm_actions       = [var.sns_topic_arn]

  dimensions = {
    Currency      = "USD"
    LinkedAccount = var.account_id
  }

  treat_missing_data = "notBreaching"

  tags = {
    Name = "${var.project_name}-billing-alarm"
  }
}
