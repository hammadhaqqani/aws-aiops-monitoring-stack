module "aiops_monitoring" {
  source = "../../"

  region      = "us-east-1"
  environment = "prod"
  project_name = "my-aiops-stack"

  # Enable features
  enable_anomaly_detection      = true
  enable_cost_anomaly_detection = true
  enable_bedrock                = false

  # Notification configuration
  slack_webhook_url       = var.slack_webhook_url
  pagerduty_integration_key = var.pagerduty_integration_key
  sns_email_addresses     = ["admin@example.com"]

  # Lambda configuration
  lambda_memory_size = 512
  lambda_timeout    = 300

  # Log groups to monitor
  log_groups = [
    "/aws/lambda/my-function-1",
    "/aws/lambda/my-function-2",
    "/aws/ecs/my-service"
  ]

  # Additional tags
  tags = {
    Team        = "Platform"
    CostCenter  = "Engineering"
    Application = "AIOps"
  }
}
