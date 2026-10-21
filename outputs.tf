output "vpc_id" {
    description = "ID of VPC"
    value = aws_vpc.main-vpc.id
}

output "vpc_cidr" {
  description = "CIDR block of the project VPC"
  value       = aws_vpc.main-vpc.cidr_block
}