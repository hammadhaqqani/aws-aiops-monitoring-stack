output "dashboard_urls" {
  description = "URLs of CloudWatch dashboards"
  value = {
    main = "https://console.aws.amazon.com/cloudwatch/home?region=us-east-1#dashboards:name=${aws_cloudwatch_dashboard.main.dashboard_name}"
    cost = "https://console.aws.amazon.com/cloudwatch/home?region=us-east-1#dashboards:name=${aws_cloudwatch_dashboard.cost.dashboard_name}"
  }
}
