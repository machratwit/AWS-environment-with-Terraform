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