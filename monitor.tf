resource "aws_cloudwatch_log_group" "app" {
    name = /demo-app/application
    retention_in_days = 14
}

resource "aws_cloudwatch_log_group" "system" {
  name              = "/demo-app/system"
  retention_in_days = 14
}

resource "aws_cloudwatch_log_group" "cloud_init" {
  name              = "/demo-app/cloud-init"
  retention_in_days = 14
}

resource "aws_iam_role_policy_attachment" "cloudwatch_agent" {
  role = aws_iam_role.ec2_ssm_role.name

  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  alarm_name          = "demo-app-high-cpu"
  alarm_description   = "EC2 CPU utilization is above 80%"
  comparison_operator = "GreaterThanThreshold"

  namespace   = "AWS/EC2"
  metric_name = "CPUUtilization"
  statistic   = "Average"

  period              = 300
  evaluation_periods  = 1
  threshold           = 80
  treat_missing_data  = "notBreaching"

  dimensions = {
    InstanceId = aws_instance.app.id
  }
}

resource "aws_cloudwatch_metric_alarm" "app_unhealthy" {
  alarm_name        = "demo-app-unhealthy"
  alarm_description = "No healthy EC2 targets are available"

  comparison_operator = "LessThanThreshold"

  namespace   = "AWS/ApplicationELB"
  metric_name = "HealthyHostCount"
  statistic   = "Minimum"

  period             = 60
  evaluation_periods = 2
  threshold          = 1

  treat_missing_data = "breaching"

  dimensions = {
    LoadBalancer = aws_lb.app.arn_suffix
    TargetGroup  = aws_lb_target_group.app.arn_suffix
  }
}