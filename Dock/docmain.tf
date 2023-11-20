provider "aws" {
  region = var.region
}

resource "aws_instance" "express_api_instance" {
  ami             = var.ami
  instance_type   = var.instance_type
  key_name        = var.key_name
  count = 3
  security_groups  = [aws_security_group.ec2_security_group.id]
  subnet_id      = element(var.subnet_ids, count.index)

  tags = {
    Name = "${var.project_name}-Server-${count.index + 1}"
  }

  user_data = <<-EOF
              #!/bin/bash
              sudo amazon-linux-extras install docker -y
              sudo service docker start
              sudo usermod -a -G docker ec2-user
              sudo docker run -d -p 80:80 894213385675.dkr.ecr.eu-west-1.amazonaws.com/devops-interview:latest
              EOF
}

resource "aws_security_group" "ec2_security_group" {
  vpc_id = var.vpc_id
  
  ingress {
    description = "SSH from server"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
  
  ingress {
    description = "HTTP access from VPC"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


# APPLICATION LOAD BALANCER
resource "aws_lb" "RichKusi-alb" {
  name               = "${var.project_name}-alb-${var.environment}"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.ec2_security_group.id]
  subnets            = var.subnet_ids[*]

  enable_deletion_protection = false
}

resource "aws_alb_target_group" "ec2_target_group" {
  name        = "${var.project_name}-tg-${var.environment}"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    healthy_threshold   = "3"
    interval            = "30"
    protocol            = "HTTP"
    matcher             = "200"
    timeout             = "3"
    path                = "/"
    unhealthy_threshold = "2"
  }
}

resource "aws_alb_listener" "http" {
  load_balancer_arn = aws_lb.RichKusi-alb.id
  port              = 80
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_alb_target_group.ec2_target_group.id
    type             = "forward"
  }
}

