# Tell Terraform which cloud provider to use and which version
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"    # use AWS provider version 5.x
    }
  }
}

# Configure the AWS provider
provider "aws" {
  region = var.aws_region  # uses the variable we defined
}

# ── VPC (Virtual Private Cloud) ───────────────────────
# A VPC is your own private network inside AWS
# Think of it like your home WiFi network, but on AWS
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"   # IP range for your network
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${var.app_name}-vpc"
  }
}

# ── Subnets ───────────────────────────────────────────
# Subnets divide your VPC into smaller sections
# Public subnets can talk to the internet
# We create 2 in different availability zones for high availability

resource "aws_subnet" "public_1" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "${var.aws_region}a"
  map_public_ip_on_launch = true

  tags = { Name = "${var.app_name}-subnet-1" }
}

resource "aws_subnet" "public_2" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "${var.aws_region}b"
  map_public_ip_on_launch = true

  tags = { Name = "${var.app_name}-subnet-2" }
}

# ── Internet Gateway ──────────────────────────────────
# This is the door between your VPC and the real internet
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = { Name = "${var.app_name}-igw" }
}

# ── Route Table ───────────────────────────────────────
# Rules that say "if traffic is going to the internet, use the gateway"
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"                    # all internet traffic
    gateway_id = aws_internet_gateway.main.id   # goes through this gateway
  }

  tags = { Name = "${var.app_name}-rt" }
}

# Connect route table to both subnets
resource "aws_route_table_association" "public_1" {
  subnet_id      = aws_subnet.public_1.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_2" {
  subnet_id      = aws_subnet.public_2.id
  route_table_id = aws_route_table.public.id
}

# ── Security Groups ───────────────────────────────────
# Firewalls that control what traffic is allowed in/out

# Security group for the Load Balancer
resource "aws_security_group" "alb" {
  name   = "${var.app_name}-alb-sg"
  vpc_id = aws_vpc.main.id

  # Allow HTTP traffic IN from anywhere
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow all traffic OUT
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.app_name}-alb-sg" }
}

# Security group for the ECS containers
resource "aws_security_group" "ecs" {
  name   = "${var.app_name}-ecs-sg"
  vpc_id = aws_vpc.main.id

  # Only allow traffic IN from the load balancer
  ingress {
    from_port       = var.app_port
    to_port         = var.app_port
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  # Allow all traffic OUT (so container can pull images etc)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.app_name}-ecs-sg" }
}

# ── Application Load Balancer ─────────────────────────
# Receives internet traffic and distributes it to your containers
resource "aws_lb" "main" {
  name               = "${var.app_name}-alb"
  internal           = false                        # public facing
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = [aws_subnet.public_1.id, aws_subnet.public_2.id]

  tags = { Name = "${var.app_name}-alb" }
}

# Target Group — where the ALB sends traffic to
resource "aws_lb_target_group" "app" {
  name        = "${var.app_name}-tg"
  port        = var.app_port
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "ip"     # required for Fargate

  # Health check — ALB pings this to make sure containers are alive
  health_check {
    path                = "/health"
    healthy_threshold   = 2
    unhealthy_threshold = 3
    interval            = 30
  }
}

# Listener — ALB listens on port 80 and forwards to target group
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }
}
