provider "aws" {
   region = var.region
}

resource "aws_security_group" "app_sg" {
    name        = "my_node_app_sg"
    description = "sg for ec2"

    ingress {
        from_port   = 3000
        to_port     = 3000
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    ingress {
        from_port   = 22
        to_port     = 22
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
 tags = {
    Name = "my_node_app_sg"
  }
}

resource "aws_instance" "quest_instance" {
    count           = 1
    ami             = var.ami_id
    instance_type   = var.instance_type
    security_groups = [aws_security_group.app_sg.name]

user_data = file("script.sh") 
  tags = {
    Name = "myinstance"
  }
}