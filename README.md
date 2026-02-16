# AWS AIOps Monitoring Stack

![License](https://img.shields.io/badge/license-MIT-blue.svg)
![Terraform](https://img.shields.io/badge/terraform->=1.0-blue.svg)
![AWS](https://img.shields.io/badge/AWS-Production%20Ready-orange.svg)

> AI-powered monitoring and observability stack for AWS using CloudWatch, Lambda-based anomaly detection, Grafana dashboards, and intelligent alerting

## 📋 Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [Features](#features)
- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Modules](#modules)
- [Lambda Functions](#lambda-functions)
- [Dashboards](#dashboards)
- [Cost Estimation](#cost-estimation)
- [Contributing](#contributing)

## 🎯 Overview

The AWS AIOps Monitoring Stack provides a comprehensive, production-ready solution for AI-powered IT operations on AWS. This Terraform-based stack combines CloudWatch metrics, intelligent log analysis, anomaly detection, and automated alerting to help you proactively identify and resolve infrastructure issues.

### Key Capabilities

- **Intelligent Log Analysis**: AI-powered log pattern detection and error analysis
- **Anomaly Detection**: Statistical and ML-based anomaly scoring for metrics
- **Cost Monitoring**: Automated cost anomaly detection and budget alerts
- **Multi-Channel Alerting**: Slack, PagerDuty, and email notifications
- **Comprehensive Dashboards**: Pre-built CloudWatch and Grafana dashboards
- **Production Ready**: Fully tested Terraform modules with best practices

## 🏗️ Architecture

```
┌─────────────────┐
│  CloudWatch     │
│  Log Groups     │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  CloudWatch     │
│  Metrics        │
└────────┬────────┘
         │
         ├──────────────────┐
         │                  │
         ▼                  ▼
┌─────────────────┐  ┌─────────────────┐
│  Log Analyzer   │  │ Anomaly Scorer  │
│  Lambda         │  │ Lambda          │
└────────┬────────┘  └────────┬────────┘
         │                    │
         │                    │
         └────────┬───────────┘
                  │
                  ▼
         ┌─────────────────┐
         │  SNS Topic      │
         └────────┬────────┘
                  │
         ┌────────┴────────┐
         │                 │
         ▼                 ▼
┌─────────────────┐  ┌─────────────────┐
│  Slack          │  │  PagerDuty      │
│  Integration    │  │  Integration    │
└─────────────────┘  └─────────────────┘
```

### Data Flow

1. **Logs** flow from AWS services (Lambda, ECS, etc.) into CloudWatch Log Groups
2. **Metrics** are collected by CloudWatch from various AWS services
3. **Log Analyzer Lambda** processes logs every 5 minutes, detecting patterns and errors
4. **Anomaly Scorer Lambda** analyzes metrics using statistical methods (Z-score, percentiles, trends)
5. **Alerts** are published to SNS when anomalies or errors are detected
6. **Notifications** are sent to Slack, PagerDuty, or email based on configuration

## ✨ Features

### Core Features

- ✅ **CloudWatch Dashboards**: Pre-configured dashboards for infrastructure and cost monitoring
- ✅ **Intelligent Alarms**: Threshold-based and anomaly detection alarms
- ✅ **Composite Alarms**: Combine multiple alarms for complex alerting logic
- ✅ **Cost Anomaly Detection**: AWS Cost Anomaly Detection integration
- ✅ **Lambda-Based Analysis**: Python Lambda functions for log and metric analysis
- ✅ **Multi-Channel Notifications**: Slack, PagerDuty, and SNS email support
- ✅ **Bedrock Integration**: Optional AWS Bedrock for advanced AI-powered insights
- ✅ **Grafana Dashboards**: JSON configurations for Grafana visualization

### Advanced Features

- **Statistical Anomaly Detection**: Z-score, percentile analysis, and trend detection
- **Pattern Recognition**: Automatic detection of error patterns in logs
- **Custom Metrics**: Publishes anomaly scores and analysis results as CloudWatch metrics
- **EventBridge Integration**: Scheduled execution of analysis functions
- **IAM Best Practices**: Least-privilege IAM roles and policies
- **Resource Tagging**: Consistent tagging strategy across all resources

## 📦 Prerequisites

Before deploying this stack, ensure you have:

1. **AWS Account** with appropriate permissions
2. **Terraform** >= 1.0 installed
3. **AWS CLI** configured with credentials
4. **Python 3.11** (for local Lambda testing, optional)
5. **GitHub CLI** (`gh`) for repository creation (optional)

### Required AWS Permissions

The AWS credentials used must have permissions for:
- CloudWatch (metrics, logs, alarms, dashboards)
- Lambda (create, update, invoke)
- SNS (create topics, subscriptions)
- IAM (create roles and policies)
- Cost Explorer (for cost anomaly detection)
- EventBridge (for scheduled rules)

### Optional Integrations

- **Slack**: Webhook URL for Slack notifications
- **PagerDuty**: Integration key for PagerDuty alerts
- **AWS Bedrock**: Access to Bedrock models for advanced AI analysis

## 🚀 Quick Start

### 1. Clone the Repository

```bash
git clone https://github.com/hammadhaqqani/aws-aiops-monitoring-stack.git
cd aws-aiops-monitoring-stack
```

### 2. Configure Variables

Copy the example variables file and customize:

```bash
cd examples/complete
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` with your values:

```hcl
region      = "us-east-1"
environment = "prod"
project_name = "my-aiops-stack"

slack_webhook_url       = "https://hooks.slack.com/services/YOUR/WEBHOOK/URL"
pagerduty_integration_key = "your-pagerduty-key"
sns_email_addresses     = ["admin@example.com"]

log_groups = [
  "/aws/lambda/my-function-1",
  "/aws/lambda/my-function-2"
]
```

### 3. Initialize Terraform

```bash
terraform init
```

### 4. Review the Plan

```bash
terraform plan
```

### 5. Deploy

```bash
terraform apply
```

### 6. Verify Deployment

After deployment, you'll receive outputs including:
- SNS Topic ARN
- Lambda function ARNs
- CloudWatch Dashboard URLs

Access the dashboards:
- Main Dashboard: `https://console.aws.amazon.com/cloudwatch/home?region=us-east-1#dashboards:name=aiops-monitoring-main-prod`
- Cost Dashboard: `https://console.aws.amazon.com/cloudwatch/home?region=us-east-1#dashboards:name=aiops-monitoring-cost-prod`

## 📚 Modules

### CloudWatch Dashboards Module

Creates pre-configured CloudWatch dashboards for infrastructure and cost monitoring.

**Usage:**
```hcl
module "cloudwatch_dashboards" {
  source = "./modules/cloudwatch-dashboards"
  
  project_name = "my-project"
  environment  = "prod"
  log_groups   = ["/aws/lambda/function1"]
}
```

**Outputs:**
- `dashboard_urls`: Map of dashboard names to URLs

### CloudWatch Alarms Module

Creates threshold-based alarms and composite alarms for infrastructure monitoring.

**Usage:**
```hcl
module "cloudwatch_alarms" {
  source = "./modules/cloudwatch-alarms"
  
  project_name  = "my-project"
  environment   = "prod"
  sns_topic_arn = aws_sns_topic.alerts.arn
  log_groups    = ["/aws/lambda/function1"]
}
```

**Features:**
- Lambda error rate alarms
- Lambda duration alarms
- Lambda throttle alarms
- Log error pattern detection
- Composite alarms combining multiple conditions

### Anomaly Detection Module

Enables CloudWatch anomaly detection for key metrics using ML-based algorithms.

**Usage:**
```hcl
module "anomaly_detection" {
  source = "./modules/anomaly-detection"
  
  project_name  = "my-project"
  environment   = "prod"
  sns_topic_arn = aws_sns_topic.alerts.arn
}
```

**Features:**
- Lambda duration anomaly detection
- Lambda error anomaly detection
- ALB response time anomaly detection
- Automatic baseline learning

### Cost Anomaly Module

Integrates with AWS Cost Anomaly Detection for automated cost monitoring.

**Usage:**
```hcl
module "cost_anomaly" {
  source = "./modules/cost-anomaly"
  
  project_name  = "my-project"
  environment   = "prod"
  sns_topic_arn = aws_sns_topic.alerts.arn
  account_id    = "123456789012"
  threshold     = 50  # USD
}
```

**Features:**
- Dimensional cost anomaly monitoring
- Daily anomaly reports
- Threshold-based alerts
- Billing alarm integration

### Notifications Module

Configures Slack and PagerDuty integrations for alerting.

**Usage:**
```hcl
module "notifications" {
  source = "./modules/notifications"
  
  project_name            = "my-project"
  environment             = "prod"
  sns_topic_arn           = aws_sns_topic.alerts.arn
  slack_webhook_url       = var.slack_webhook_url
  pagerduty_integration_key = var.pagerduty_integration_key
}
```

**Features:**
- Slack webhook integration
- PagerDuty event API integration
- Rich message formatting
- Automatic incident creation/resolution

## 🔧 Lambda Functions

### Log Analyzer (`lambdas/log-analyzer/`)

Analyzes CloudWatch Logs for patterns, errors, and anomalies.

**Capabilities:**
- Error pattern detection (ERROR, FATAL, EXCEPTION, etc.)
- Statistical analysis (error rates, message patterns)
- Anomaly scoring (0-100 scale)
- Optional AWS Bedrock integration for AI-powered insights
- Custom CloudWatch metrics publication

**Trigger:** EventBridge rule (every 5 minutes)

**Input:**
```json
{
  "log_groups": ["/aws/lambda/function1"],
  "hours": 1
}
```

**Output:**
- Anomaly scores published to CloudWatch
- SNS alerts for high-severity issues
- AI insights (if Bedrock enabled)

### Anomaly Scorer (`lambdas/anomaly-scorer/`)

Calculates anomaly scores for CloudWatch metrics using statistical methods.

**Capabilities:**
- Z-score calculation
- Percentile analysis
- Trend detection (increasing/decreasing/stable)
- Multi-metric analysis
- Baseline learning from historical data

**Trigger:** EventBridge rule or manual invocation

**Input:**
```json
{
  "metrics": [
    {
      "namespace": "AWS/Lambda",
      "metric_name": "Duration",
      "statistic": "Average"
    }
  ]
}
```

**Output:**
- Anomaly scores (0-1 scale)
- Severity classification (LOW/MEDIUM/HIGH/CRITICAL)
- SNS alerts for anomalies above threshold

## 📊 Dashboards

### CloudWatch Dashboards

Pre-built dashboards are automatically created:

1. **Main Dashboard** (`aiops-monitoring-main-{env}`)
   - Lambda metrics overview
   - Error logs
   - ALB metrics
   - ECS container metrics

2. **Cost Dashboard** (`aiops-monitoring-cost-{env}`)
   - Daily AWS charges
   - Cost trends
   - Lambda cost drivers

### Grafana Dashboards

JSON configurations are provided in `dashboards/grafana/`:

1. **Infrastructure Overview** (`infrastructure-overview.json`)
   - Lambda invocations and errors
   - Anomaly scores
   - ALB response times
   - Error rates and active alarms

2. **Cost Analysis** (`cost-analysis.json`)
   - Daily charges
   - Cost by service
   - Cost anomaly detection
   - Monthly cost forecast

**Import Instructions:**
1. Open Grafana
2. Go to Dashboards → Import
3. Upload the JSON file
4. Configure data source (CloudWatch or Prometheus)

## 💰 Cost Estimation

### Monthly Cost Breakdown (Estimated)

| Service | Usage | Cost |
|---------|-------|------|
| CloudWatch Metrics | ~100 metrics | $0.30 |
| CloudWatch Logs | 5 GB ingestion | $2.50 |
| CloudWatch Alarms | 20 alarms | $6.00 |
| Lambda Invocations | 8,640/month (5-min schedule) | $0.17 |
| Lambda Compute | 512 MB, 5-min runs | $2.00 |
| SNS | 1,000 notifications | $0.50 |
| Cost Anomaly Detection | Included | $0.00 |
| **Total** | | **~$11.50/month** |

### Cost Optimization Tips

1. **Reduce Log Retention**: Adjust log retention periods based on needs
2. **Optimize Lambda Memory**: Tune memory size based on actual usage
3. **Filter Logs**: Use metric filters to reduce log ingestion
4. **Consolidate Alarms**: Use composite alarms to reduce alarm count
5. **Schedule Analysis**: Adjust Lambda schedule frequency based on requirements

### Free Tier Eligibility

- CloudWatch: 10 custom metrics, 5 GB log ingestion
- Lambda: 1M requests, 400,000 GB-seconds
- SNS: 1M requests

## 🤝 Contributing

Contributions are welcome! Please follow these guidelines:

1. **Fork the repository**
2. **Create a feature branch** (`git checkout -b feature/amazing-feature`)
3. **Make your changes** with tests if applicable
4. **Follow Terraform best practices**:
   - Use `terraform fmt` before committing
   - Validate with `terraform validate`
   - Document new variables and outputs
5. **Commit your changes** (`git commit -m 'Add amazing feature'`)
6. **Push to the branch** (`git push origin feature/amazing-feature`)
7. **Open a Pull Request**

### Development Setup

```bash
# Install pre-commit hooks (optional)
pre-commit install

# Format Terraform code
terraform fmt -recursive

# Validate Terraform
terraform validate

# Run security scan
tfsec .
```

### Code Style

- Use meaningful variable and resource names
- Add descriptions to all variables and outputs
- Follow Terraform style guide
- Include examples in module documentation
- Update README for new features

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- AWS CloudWatch team for comprehensive monitoring capabilities
- HashiCorp for Terraform
- The open-source community for inspiration and feedback

## 📞 Support

For issues, questions, or contributions:
- Open an issue on GitHub
- Check existing documentation
- Review example configurations

---

**Built with ❤️ for AWS AIOps**
---

## Support

If you find this useful, consider buying me a coffee!

[![Buy Me A Coffee](https://img.shields.io/badge/Buy%20Me%20A%20Coffee-ffdd00?style=for-the-badge&logo=buy-me-a-coffee&logoColor=black)](https://buymeacoffee.com/hammadhaqqani)
