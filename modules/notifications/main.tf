# Lambda function for Slack notifications
resource "aws_lambda_function" "slack_notifier" {
  count = var.slack_webhook_url != "" ? 1 : 0

  filename         = "${path.module}/slack-notifier.zip"
  function_name    = "${var.project_name}-slack-notifier-${var.environment}"
  role             = aws_iam_role.notifier_role[0].arn
  handler          = "index.handler"
  source_code_hash = data.archive_file.slack_notifier_zip[0].output_base64sha256
  runtime          = "python3.11"
  timeout          = 30
  memory_size      = 128

  environment {
    variables = {
      SLACK_WEBHOOK_URL = var.slack_webhook_url
    }
  }

  tags = {
    Name = "${var.project_name}-slack-notifier"
  }
}

# Lambda function code for Slack
data "archive_file" "slack_notifier_zip" {
  count = var.slack_webhook_url != "" ? 1 : 0

  type        = "zip"
  output_path = "${path.module}/slack-notifier.zip"
  source {
    content  = <<EOF
import json
import urllib3
import os

http = urllib3.PoolManager()

def handler(event, context):
    webhook_url = os.environ['SLACK_WEBHOOK_URL']
    
    sns_message = json.loads(event['Records'][0]['Sns']['Message'])
    alarm_name = sns_message.get('AlarmName', 'Unknown')
    new_state = sns_message.get('NewStateValue', 'Unknown')
    reason = sns_message.get('NewStateReason', 'No reason provided')
    
    slack_message = {
        "text": f"AWS CloudWatch Alarm: {alarm_name}",
        "blocks": [
            {
                "type": "header",
                "text": {
                    "type": "plain_text",
                    "text": f"🚨 {alarm_name}"
                }
            },
            {
                "type": "section",
                "fields": [
                    {
                        "type": "mrkdwn",
                        "text": f"*Status:*\n{new_state}"
                    },
                    {
                        "type": "mrkdwn",
                        "text": f"*Reason:*\n{reason}"
                    }
                ]
            }
        ]
    }
    
    response = http.request(
        'POST',
        webhook_url,
        body=json.dumps(slack_message),
        headers={'Content-Type': 'application/json'}
    )
    
    return {
        'statusCode': response.status,
        'body': json.dumps('Slack notification sent')
    }
EOF
    filename = "index.py"
  }
}

# Lambda function for PagerDuty notifications
resource "aws_lambda_function" "pagerduty_notifier" {
  count = var.pagerduty_integration_key != "" ? 1 : 0

  filename         = "${path.module}/pagerduty-notifier.zip"
  function_name    = "${var.project_name}-pagerduty-notifier-${var.environment}"
  role             = aws_iam_role.notifier_role[0].arn
  handler          = "index.handler"
  source_code_hash = data.archive_file.pagerduty_notifier_zip[0].output_base64sha256
  runtime          = "python3.11"
  timeout          = 30
  memory_size      = 128

  environment {
    variables = {
      PAGERDUTY_INTEGRATION_KEY = var.pagerduty_integration_key
    }
  }

  tags = {
    Name = "${var.project_name}-pagerduty-notifier"
  }
}

# Lambda function code for PagerDuty
data "archive_file" "pagerduty_notifier_zip" {
  count = var.pagerduty_integration_key != "" ? 1 : 0

  type        = "zip"
  output_path = "${path.module}/pagerduty-notifier.zip"
  source {
    content  = <<EOF
import json
import urllib3
import os

http = urllib3.PoolManager()

def handler(event, context):
    integration_key = os.environ['PAGERDUTY_INTEGRATION_KEY']
    
    sns_message = json.loads(event['Records'][0]['Sns']['Message'])
    alarm_name = sns_message.get('AlarmName', 'Unknown')
    new_state = sns_message.get('NewStateValue', 'Unknown')
    reason = sns_message.get('NewStateReason', 'No reason provided')
    
    # Determine event action based on alarm state
    event_action = "trigger" if new_state == "ALARM" else "resolve"
    
    pagerduty_payload = {
        "routing_key": integration_key,
        "event_action": event_action,
        "payload": {
            "summary": f"AWS CloudWatch Alarm: {alarm_name}",
            "severity": "critical" if new_state == "ALARM" else "info",
            "source": "aws-cloudwatch",
            "custom_details": {
                "alarm_name": alarm_name,
                "state": new_state,
                "reason": reason
            }
        }
    }
    
    response = http.request(
        'POST',
        'https://events.pagerduty.com/v2/enqueue',
        body=json.dumps(pagerduty_payload),
        headers={'Content-Type': 'application/json'}
    )
    
    return {
        'statusCode': response.status,
        'body': json.dumps('PagerDuty notification sent')
    }
EOF
    filename = "index.py"
  }
}

# IAM Role for notification Lambda functions
resource "aws_iam_role" "notifier_role" {
  count = (var.slack_webhook_url != "" || var.pagerduty_integration_key != "") ? 1 : 0

  name = "${var.project_name}-notifier-role-${var.environment}"

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
    Name = "${var.project_name}-notifier-role"
  }
}

resource "aws_iam_role_policy" "notifier_policy" {
  count = (var.slack_webhook_url != "" || var.pagerduty_integration_key != "") ? 1 : 0

  name = "${var.project_name}-notifier-policy-${var.environment}"
  role = aws_iam_role.notifier_role[0].id

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
      }
    ]
  })
}

# SNS Topic Subscription for Slack
resource "aws_sns_topic_subscription" "slack" {
  count = var.slack_webhook_url != "" ? 1 : 0

  topic_arn = var.sns_topic_arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.slack_notifier[0].arn
}

# SNS Topic Subscription for PagerDuty
resource "aws_sns_topic_subscription" "pagerduty" {
  count = var.pagerduty_integration_key != "" ? 1 : 0

  topic_arn = var.sns_topic_arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.pagerduty_notifier[0].arn
}

# Lambda permissions for SNS
resource "aws_lambda_permission" "slack_sns" {
  count = var.slack_webhook_url != "" ? 1 : 0

  statement_id  = "AllowExecutionFromSNS"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.slack_notifier[0].function_name
  principal     = "sns.amazonaws.com"
  source_arn    = var.sns_topic_arn
}

resource "aws_lambda_permission" "pagerduty_sns" {
  count = var.pagerduty_integration_key != "" ? 1 : 0

  statement_id  = "AllowExecutionFromSNS"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.pagerduty_notifier[0].function_name
  principal     = "sns.amazonaws.com"
  source_arn    = var.sns_topic_arn
}
