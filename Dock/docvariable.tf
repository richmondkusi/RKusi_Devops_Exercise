variable "region" {
  default = "eu-west-1"
}

variable "project_name" {
  default = "RichKusi"

}

variable "environment" {
  default = "Test"
}

variable "vpc_id" {
  default = "vpc-23664845"
}

variable "subnet_ids" {
  type    = list(any)
  default = ["subnet-de127996", "subnet-f4e643ae", "subnet-8e77efe8"]
}

variable "instance_type" {
  default = "t2.micro"
}


variable "ami" {
    default = "ami-005e7be1c849abba7"
  
}

variable "key_name" {
  default = "RichKusi-KP"
}