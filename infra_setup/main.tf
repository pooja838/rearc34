provider "aws" {
  region = var.aws_region
}
resource "aws_key_pair" "ec2_key" {
  key_name   = "my-key"
  public_key = file("/home/pooja/.ssh/id_rsa.pub")  # Path to your public key file
}

# Get default VPC
data "aws_vpc" "default" {
  default = true
}

# Get all subnet IDs from default VPC
data "aws_subnet" "default" {
  vpc_id = data.aws_vpc.default.id
  availability_zone = "${var.aws_region}a"
  default_for_az = true
}
# Pick the first available subnet (note: no filtering on public IPs)
data "aws_subnet" "default_public_a" {
 vpc_id              = data.aws_vpc.default.id
  availability_zone   = "${var.aws_region}a"  # Ensure it's in the correct AZ
  default_for_az      = true
}
data "aws_subnet" "default_public_b" {
  vpc_id              = data.aws_vpc.default.id
  availability_zone   = "${var.aws_region}b"
  default_for_az      = true
}

# Get the default security group
data "aws_security_group" "default" {
  vpc_id = data.aws_vpc.default.id
  name   = "default"
}

# Create a custom security group for your instance or ECS
resource "aws_security_group" "instance_sg" {
  name_prefix = "rearc-quest-instances-sg-"
  vpc_id      = data.aws_vpc.default.id

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
    Name = "rearc-quest-instances-sg"
  }
}
resource "aws_instance" "app_instance" {
 count         = 3
 ami           = "ami-0e35ddab05955cf57"
  instance_type        = "t2.micro"
 subnet_id     = data.aws_subnet.default_public_a.id
 vpc_security_group_ids = [aws_security_group.instance_sg.id]
 associate_public_ip_address = true 
 key_name                    = aws_key_pair.ec2_key.key_name

user_data = <<-EOF
              #!/bin/bash
              apt-get update -y
              apt-get install -y docker.io
              systemctl start docker
              systemctl enable docker
              usermod -aG docker ubuntu
              EOF

tags = {
    Name = "node${count.index + 1}"              # ✅ Gives instances unique names: node1, node2, node3
  }
}
resource "aws_security_group" "lb_sg" {
  name        = "load-balancer-sg"
  description = "Allow inbound HTTP traffic"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Adjust as needed for security
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
resource "aws_lb_target_group" "app_tg" {
  name     = "app-tg"
  port     = 3000
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.default.id

  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}
resource "aws_lb_target_group_attachment" "app_attachment" {
  count            = length(aws_instance.app_instance)
  target_group_arn = aws_lb_target_group.app_tg.arn
  target_id        = aws_instance.app_instance[count.index].id
  port             = 3000
}
# --- Load Balancer Target Group ---

resource "aws_lb" "app_lb" {
  name_prefix        = "myapp-"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.lb_sg.id]
  subnets            = [
    data.aws_subnet.default_public_a.id,
    data.aws_subnet.default_public_b.id
  ]
  enable_deletion_protection = false
}
resource "aws_lb_listener" "http_listener" {
  load_balancer_arn = aws_lb.app_lb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app_tg.arn
  }
}
