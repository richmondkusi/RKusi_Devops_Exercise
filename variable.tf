variable "region" {
  description = "making my region a variable"
  default     = "eu-west-1"
}

variable "project_name" {
  default = "RichKusi"

}

variable "vpc_id" {
  default = "vpc-23664845"
}

variable "subnet_ids" {
  type    = list(any)
  default = ["subnet-de127996", "subnet-f4e643ae", "subnet-8e77efe8"]
}

variable "vpc_security_group_ids" {
  default = "aws_security_group.RichKusi-sg.id"
}

variable "container_image" {
  default = "894213385675.dkr.ecr.eu-west-1.amazonaws.com/devops-interview:latest"
}

variable "environment" {
  default     = "TEST"
  description = "making my environment a variable"
  type        = string
}

variable "ecs_task_execution_role" {
  default = "arn:aws:iam::894213385675:role/ecsTaskExecutionRole"
}

variable "ecs_task_role" {
  default = "arn:aws:iam::894213385675:role/ecsTaskExecutionRole"
}
