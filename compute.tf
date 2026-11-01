data "aws_ssm_parameter" "al2023_ami" {
    name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-6.1-x86_64"
}

# IAM role for EC2 Systems Manager access
resource "aws_iam_role" "ec2_ssm_role" {
    name = "main-ec2-ssm-role"

    assume_role_policy = jsonencode({
        Version = "2012-10-17"
        Statement = [{
            Effect = "Allow"
            Principal = {
                Service = "ec2.amazonaws.com"
            }
            Action = "sts:AssumeRole"
        }]
    })
}

resource "aws_iam_role_policy_attachment" "ssm_core" {
    role = aws_iam_role.ec2_ssm_role.name
    policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ec2_profile" {
    name = "main-ec2-instance-profile"
    role = aws_iam_role.ec2_ssm_role.name
}

# Security Group for the ALB
resource "aws_security_group" "alb" {
    name        = "main-alb-sg"
    description = "Public web traffic to the load balancer"
    vpc_id      = aws_vpc.main-vpc.id

    egress = []

    tags = {
        Name = "main-alb-sg"
    }
}

resource "aws_vpc_security_group_ingress_rule" "alb-http" {
    security_group_id = aws_security_group.alb.id
    cidr_ipv4   = "0.0.0.0/0"
    from_port   = 80
    to_port     = 80
    ip_protocol = "tcp"
    description = "Public HTTP Access"
}

resource "aws_vpc_security_group_egress_rule" "alb-to-app" {
    security_group_id = aws_security_group.alb.id
    referenced_security_group_id = aws_security_group.app.id
    from_port   = 8080
    to_port     = 8080
    ip_protocol = "tcp"
    description = "Forward requests to the application"
}

# Security group for the private EC2 instance
resource "aws_security_group" "app" {
  name        = "main-app-sg"
  description = "Private application, accessible only through ALB"
  vpc_id      = aws_vpc.main-vpc.id

  egress = []

  tags = {
    Name = "main-app-sg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "app_from_alb" {
    security_group_id            = aws_security_group.app.id
    referenced_security_group_id = aws_security_group.alb.id
    from_port                    = 8080
    to_port                      = 8080
    ip_protocol                  = "tcp"
    description                  = "Application traffic from ALB only"
}

resource "aws_vpc_security_group_egress_rule" "app_to_endpoints" {
  security_group_id            = aws_security_group.app.id
  referenced_security_group_id = aws_security_group.vpc_endpoints.id
  from_port                    = 443
  to_port                      = 443
  ip_protocol                  = "tcp"
  description                  = "HTTPS to Systems Manager VPC endpoints"
}


# ALB
resouce "aws_lb" "app" {
    name                = "main-app-alb"
    internal            = false
    load_balancer_type  = "application"
    security_groups      = [aws_security_group.alb.id]
    subnets              = [aws_subnet.public_a.id, aws_subnet.public_b.id]
    
    tags{
        Name = "main-app-alb"
    }
}

# Target group for the application
resource "aws_lb_target_group" "app" {
    name = "main-app-tg"
    port = 8080
    protocol = "HTTP"
    vpc_id = aws_vpc.main-vpc.id
    target_type = "instance"
    health_check {
        enabled             = true
        protocol            = "HTTP"
        path                = "/"
        matcher             = "200"
        interval            = 30
        healthy_threshold   = 2
        unhealthy_threshold = 3
    }

  tags = {
    Name = "main-app-tg"
  }
}

# HTTP listener
resource "aws_lb_listener" "http" {
    load_balancer_arn = "aws_lb.app.arn"
    port = "80"
    protocol = "HTTP"
    default_action {
        type = "forward"
        target_group_arn = aws_lb_target_group.app.arn
    }
}

# EC2 Instance in Private subnet
resource "aws_instance" "app" {
    ami = data.aws_ssm_parameter.al2023_ami.value
    instance_type = "t3.micro"
    subnet_id = aws_subnet.private_a.id
    vpc_security_group_ids = [aws_security_group.app.id]
    iam_instance_profile = aws_iam_instance_profile.ec2_profile.name
    associate_public_ip_address = false

    user_data = file("${path.module}/userdata.sh")

    depends_on = [
        aws_iam_role_policy_attachment.ssm_core,
        aws_vpc_endpoint.ssm,
        aws_vpc_endpoint.ssmmessages
    ]
    tags = {
    Name = "main-private-app"
  }
}


resource "aws_lb_target_group_attachment" "app" {
  target_group_arn = aws_lb_target_group.app.arn
  target_id        = aws_instance.app.id
  port             = 8080
}