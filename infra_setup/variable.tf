variable "region" {
description = "aws resgion for deployment"
type        = string
default     = "ap-south-1"
}

variable "ami_id" {
    description = "ami id for ec2 instance"
    type        = string
    default     = "ami-002f6e91abff6eb96"
}

variable "instance_type" {
    description = "instance type for ec2 instance"
    type        = string
    default     = "t2.micro"
}

