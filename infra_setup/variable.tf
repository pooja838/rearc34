variable "aws_region" {
  description = "AWS region"
}

variable "ami_id" {
  description = "AMI ID for EC2"
}

variable "key_name" {
  description = "Name of the SSH key pair"
}
variable "ssl_policy" {
  description = "The SSL policy to use for the HTTPS listener."
  type        = string
}
variable "certificate_arn" {
  description = "The ARN of the SSL certificate to use for the HTTPS listener."
  type        = string
}
variable "instance_type" {
  description = "The EC2 instance type."
  type        = string
  
}
variable "desired_capacity" {
  description = "The desired capacity for the Auto Scaling group."
  type        = number
}

variable "max_size" {
  description = "The max size for the Auto Scaling group."
  type        = number
}

variable "min_size" {
  description = "The min size for the Auto Scaling group."
  type        = number
}

