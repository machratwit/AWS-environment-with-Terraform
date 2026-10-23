data "aws_ssm_parameter" "al2023_ami" {
    name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-6.1-x86_64"
}

# IAM role for EC2 Systems Manager access
resource "aws_iam_role" "ec2_ssm_role" {
    name = "main-ec2-ssm-role"

    assume_role_policy = jsonencode{
        Version = "2012-10-17"
        Statement = [{
            Effect = "Allow"
            Principal = {
                Service = "ec2.amazonaws.com"
            }
            Action = "sts:AssumeRole
        }]
    }
}

resource "aws_iam_role_policy_attachment" "ssm_core" {
    role = aws_iam_role.ec2_ssm_role.name
    policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ec2_profile" {
    name = "main-ec2-aws_iam_instance_profile"
    role = aws_iam_role.name
}

# Security Group for the ALB
resouce "aws_security_group" "alb" {
    name = "main-alb-sg"
    description = "Public web traffic to the load balancer"
    vpc_id = aws_vpc.main-vpc.id

    tag = {
        Name = "main-alb-sg"
    }
}

resource "aws_vpc_security"