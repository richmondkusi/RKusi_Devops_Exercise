#Creation of Security Group for ALB
resource "aws_security_group" "RichKusi-sg1" {
  name        = "RichKusi-sg"
  description = "Allow TLS inbound traffic"
  vpc_id      = var.vpc_id


  ingress {
    description      = "HTTP access from VPC"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }


  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "RichKusi-sg1"
  }
}


variable "container_port" {
  default     = "80"
  description = "making my container port a variable"
}


# creation of security group for ECS Tasks
resource "aws_security_group" "ecs-tasks-sg" {
  name   = "${var.project_name}-sg-task-${var.environment}"
  vpc_id = var.vpc_id


  ingress {
    protocol        = "tcp"
    from_port       = var.container_port
    to_port         = var.container_port
    security_groups = [aws_security_group.RichKusi-sg1.id]

  }

  egress {
    protocol         = "-1"
    from_port        = 0
    to_port          = 0
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}



# ECS CLUSTER creation
resource "aws_ecs_cluster" "RichKusi-cluster" {
  name = "${var.project_name}-cluster-${var.environment}"
}



# TASK DEFINITION creation


resource "aws_ecs_task_definition" "RichKusi-task-definition" {
  family                = "RichKusi-task-definition"
  container_definitions = <<EOF
  [
    {
      "name": "${var.project_name}-container-${var.environment}",
      "image": "${var.container_image}:latest",
      "portMappings": [
        {
          "containerPort": 80,
          "hostPort": 80,
          "protocol": "tcp"
         
        }
      ]
    }
  ]
EOF

  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  task_role_arn            = var.ecs_task_role
  execution_role_arn       = var.ecs_task_execution_role
}


### Create an IAM ROLE for ECS tasks to interact with ECR 
resource "aws_iam_role" "ecs_task_role" {
  name = "${var.project_name}-ecs-task-role"
 
  assume_role_policy = <<EOF
{
 "Version": "2012-10-17",
 "Statement": [
   {
     "Action": "sts:AssumeRole",
     "Principal": {
       "Service": "ecs-tasks.amazonaws.com"
     },
     "Effect": "Allow",
     "Sid": ""
   }
 ]
}
EOF
}



### Task Execution Role, because the application will be run serverless
resource "aws_iam_role" "ecs_task_execution_role" {
  name = "${var.project_name}-ecsTaskExecutionRole"
 
  assume_role_policy = <<EOF
{
 "Version": "2012-10-17",
 "Statement": [
   {
     "Action": "sts:AssumeRole",
     "Principal": {
       "Service": "ecs-tasks.amazonaws.com"
     },
     "Effect": "Allow",
     "Sid": ""
   }
 ]
}
EOF
} 
 
resource "aws_iam_role_policy_attachment" "ecs-task-execution-role-policy-attachment" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}


# SERVICE Creation
resource "aws_ecs_service" "RichKusi-service" {
  name                               = "${var.project_name}-service-${var.environment}"
  cluster                            = aws_ecs_cluster.RichKusi-cluster.id
  task_definition                    = aws_ecs_task_definition.RichKusi-task-definition.arn
  desired_count                      = 2
  deployment_minimum_healthy_percent = 50
  deployment_maximum_percent         = 200
  launch_type                        = "FARGATE"
  scheduling_strategy                = "REPLICA"

  network_configuration {
    security_groups  = [aws_security_group.ecs-tasks-sg.id]
    subnets          = var.subnet_ids
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_alb_target_group.RichKusi-tg1.arn
    container_name   = "${var.project_name}-container-${var.environment}"
    container_port   = var.container_port
  }

  lifecycle {
    ignore_changes = [task_definition, desired_count]
  }
}



# APPLICATION LOAD BALANCER
resource "aws_lb" "RichKusi-alb" {
  name               = "${var.project_name}-alb-${var.environment}"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.RichKusi-sg1.id]
  subnets            = var.subnet_ids

  enable_deletion_protection = false
}

resource "aws_alb_target_group" "RichKusi-tg1" {
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
    target_group_arn = aws_alb_target_group.RichKusi-tg1.id
    type             = "forward"
  }
}



 