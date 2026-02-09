provider "aws" {
  region = var.region

  default_tags {
    tags = merge(
      {
        Project     = var.project_name
        Environment = var.environment
        ManagedBy   = "Terraform"
      },
      var.tags
    )
  }
}

# Data source for current AWS account
data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

# SNS Topic for notifications
resource "aws_sns_topic" "aiops_alerts" {
  name              = "${var.project_name}-aiops-alerts-${var.environment}"
  display_name      = "AIOps Alerts"
  kms_master_key_id = "alias/aws/sns"

  tags = {
    Name = "${var.project_name}-aiops-alerts"
  }
}

# SNS Topic subscriptions
resource "aws_sns_topic_subscription" "email" {
  count     = length(var.sns_email_addresses)
  topic_arn = aws_sns_topic.aiops_alerts.arn
  protocol  = "email"
  endpoint  = var.sns_email_addresses[count.index]
}

# IAM Role for Lambda functions
resource "aws_iam_role" "lambda_role" {
  name = "${var.project_name}-lambda-role-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "${var.project_name}-lambda-role"
  }
}

# IAM Policy for Lambda functions
resource "aws_iam_role_policy" "lambda_policy" {
  name = "${var.project_name}-lambda-policy-${var.environment}"
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        Effect = "Allow"
        Action = [
          "cloudwatch:PutMetricData",
          "cloudwatch:GetMetricStatistics",
          "cloudwatch:ListMetrics",
          "cloudwatch:DescribeAlarms"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "logs:FilterLogEvents",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "sns:Publish"
        ]
        Resource = aws_sns_topic.aiops_alerts.arn
      },
      {
        Effect = "Allow"
        Action = [
          "bedrock:InvokeModel",
          "bedrock:InvokeModelWithResponseStream"
        ]
        Resource  = var.enable_bedrock ? "arn:aws:bedrock:${var.region}::foundation-model/${var.bedrock_model_id}" : "*"
        Condition = var.enable_bedrock ? {} : null
      }
    ]
  })
}

# CloudWatch Log Group for Lambda functions
resource "aws_cloudwatch_log_group" "lambda_logs" {
  name              = "/aws/lambda/${var.project_name}-${var.environment}"
  retention_in_days = 14

  tags = {
    Name = "${var.project_name}-lambda-logs"
  }
}

# Module: CloudWatch Dashboards
module "cloudwatch_dashboards" {
  source = "./modules/cloudwatch-dashboards"

  project_name = var.project_name
  environment  = var.environment
  log_groups   = var.log_groups
}

# Module: CloudWatch Alarms
module "cloudwatch_alarms" {
  source = "./modules/cloudwatch-alarms"

  project_name  = var.project_name
  environment   = var.environment
  sns_topic_arn = aws_sns_topic.aiops_alerts.arn
  log_groups    = var.log_groups
}

# Module: Anomaly Detection
module "anomaly_detection" {
  source = "./modules/anomaly-detection"

  count = var.enable_anomaly_detection ? 1 : 0

  project_name  = var.project_name
  environment   = var.environment
  sns_topic_arn = aws_sns_topic.aiops_alerts.arn
}

# Module: Cost Anomaly Detection
module "cost_anomaly" {
  source = "./modules/cost-anomaly"

  count = var.enable_cost_anomaly_detection ? 1 : 0

  project_name  = var.project_name
  environment   = var.environment
  sns_topic_arn = aws_sns_topic.aiops_alerts.arn
  account_id    = data.aws_caller_identity.current.account_id
}

# Module: Notifications
module "notifications" {
  source = "./modules/notifications"

  project_name              = var.project_name
  environment               = var.environment
  sns_topic_arn             = aws_sns_topic.aiops_alerts.arn
  slack_webhook_url         = var.slack_webhook_url
  pagerduty_integration_key = var.pagerduty_integration_key
}

# Lambda: Log Analyzer
resource "aws_lambda_function" "log_analyzer" {
  filename         = "${path.module}/lambdas/log-analyzer.zip"
  function_name    = "${var.project_name}-log-analyzer-${var.environment}"
  role             = aws_iam_role.lambda_role.arn
  handler          = "handler.lambda_handler"
  source_code_hash = data.archive_file.log_analyzer_zip.output_base64sha256
  runtime          = "python3.11"
  timeout          = var.lambda_timeout
  memory_size      = var.lambda_memory_size

  environment {
    variables = {
      SNS_TOPIC_ARN    = aws_sns_topic.aiops_alerts.arn
      ENABLE_BEDROCK   = tostring(var.enable_bedrock)
      BEDROCK_MODEL_ID = var.bedrock_model_id
      LOG_LEVEL        = "INFO"
    }
  }

  depends_on = [
    aws_cloudwatch_log_group.lambda_logs,
    aws_iam_role_policy.lambda_policy
  ]

  tags = {
    Name = "${var.project_name}-log-analyzer"
  }
}

# Archive Lambda function
data "archive_file" "log_analyzer_zip" {
  type        = "zip"
  source_dir  = "${path.module}/lambdas/log-analyzer"
  output_path = "${path.module}/lambdas/log-analyzer.zip"
}

# Lambda: Anomaly Scorer
resource "aws_lambda_function" "anomaly_scorer" {
  filename         = "${path.module}/lambdas/anomaly-scorer.zip"
  function_name    = "${var.project_name}-anomaly-scorer-${var.environment}"
  role             = aws_iam_role.lambda_role.arn
  handler          = "handler.lambda_handler"
  source_code_hash = data.archive_file.anomaly_scorer_zip.output_base64sha256
  runtime          = "python3.11"
  timeout          = var.lambda_timeout
  memory_size      = var.lambda_memory_size

  environment {
    variables = {
      SNS_TOPIC_ARN = aws_sns_topic.aiops_alerts.arn
      LOG_LEVEL     = "INFO"
    }
  }

  depends_on = [
    aws_cloudwatch_log_group.lambda_logs,
    aws_iam_role_policy.lambda_policy
  ]

  tags = {
    Name = "${var.project_name}-anomaly-scorer"
  }
}

# Archive Lambda function
data "archive_file" "anomaly_scorer_zip" {
  type        = "zip"
  source_dir  = "${path.module}/lambdas/anomaly-scorer"
  output_path = "${path.module}/lambdas/anomaly-scorer.zip"
}

# EventBridge Rule to trigger log analyzer periodically
resource "aws_cloudwatch_event_rule" "log_analyzer_schedule" {
  name                = "${var.project_name}-log-analyzer-schedule-${var.environment}"
  description         = "Trigger log analyzer every 5 minutes"
  schedule_expression = "rate(5 minutes)"

  tags = {
    Name = "${var.project_name}-log-analyzer-schedule"
  }
}

resource "aws_cloudwatch_event_target" "log_analyzer_target" {
  rule      = aws_cloudwatch_event_rule.log_analyzer_schedule.name
  target_id = "LogAnalyzerTarget"
  arn       = aws_lambda_function.log_analyzer.arn
}

resource "aws_lambda_permission" "log_analyzer_eventbridge" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.log_analyzer.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.log_analyzer_schedule.arn
}
