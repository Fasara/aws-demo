resource "aws_cloudwatch_log_group" "lambda_logs" {
  name              = "/aws/lambda/aws-demo-backend"
  retention_in_days = 7

  tags = {
    Project = "aws-demo-project"
  }
}

resource "aws_cloudwatch_metric_alarm" "lambda_errors" {
  alarm_name          = "aws-demo-backend-error-rate"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods   = 1
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = 300
  statistic           = "Sum"
  threshold           = 1

  dimensions = {
    FunctionName = "aws-demo-backend"
  }

  alarm_description = "Triggers when the Lambda function has 1 or more errors in a 5-minute window"
  treat_missing_data = "notBreaching"

  tags = {
    Project = "aws-demo-project"
  }
}

resource "aws_cloudwatch_metric_alarm" "lambda_duration" {
  alarm_name          = "aws-demo-backend-duration"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "Duration"
  namespace           = "AWS/Lambda"
  period              = 300
  statistic           = "Maximum"
  threshold           = 8000

  dimensions = {
    FunctionName = "aws-demo-backend"
  }

  alarm_description  = "Triggers when Lambda duration approaches the 10s timeout (80% threshold)"
  treat_missing_data = "notBreaching"

  tags = {
    Project = "aws-demo-project"
  }
}