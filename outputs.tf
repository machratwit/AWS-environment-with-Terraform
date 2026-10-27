output "vpc_id" {
    description = "ID of VPC"
    value = aws_vpc.main-vpc.id
}

output "vpc_cidr" {
  description = "CIDR block of the project VPC"
  value       = aws_vpc.main-vpc.cidr_block
}

output "application_url" {
  description = "HTTP URL for the demo application"
  value       = "http://${aws_lb.app.dns_name}"
}

output "private_instance_id" {
  description = "EC2 instance ID for Session Manager"
  value       = aws_instance.app.id
}