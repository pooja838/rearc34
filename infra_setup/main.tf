provider "aws" {
  region = var.aws_region
}
data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_vpc" "myapp_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "myapp-vpc"
  }
}

resource "aws_subnet" "myapp_public_subnet_1" {
  vpc_id                  = aws_vpc.myapp_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "${var.aws_region}a"
  map_public_ip_on_launch = true

  tags = {
    Name = "myapp-public-subnet-1"
  }
}

resource "aws_subnet" "myapp_public_subnet_2" {
  vpc_id                  = aws_vpc.myapp_vpc.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "${var.aws_region}b"
  map_public_ip_on_launch = true

  tags = {
    Name = "myapp-public-subnet-2"
  }
}

resource "aws_internet_gateway" "myapp_igw" {
  vpc_id = aws_vpc.myapp_vpc.id

  tags = {
    Name = "myapp-igw"
  }
}

resource "aws_route_table" "myapp_public_rt" {
  vpc_id = aws_vpc.myapp_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.myapp_igw.id
  }

  tags = {
    Name = "myapp-public-rt"
  }
}

resource "aws_route_table_association" "myapp_rt_assoc_1" {
  subnet_id      = aws_subnet.myapp_public_subnet_1.id
  route_table_id = aws_route_table.myapp_public_rt.id
}

resource "aws_route_table_association" "myapp_rt_assoc_2" {
  subnet_id      = aws_subnet.myapp_public_subnet_2.id
  route_table_id = aws_route_table.myapp_public_rt.id
}
resource "aws_security_group" "myapp_sg_alb" {
  name        = "myapp-sg-alb"
  description = "ALB Security Group"
  vpc_id      = aws_vpc.myapp_vpc.id

  ingress {
    description = "Allow HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
    egress {
   description     = "Allow TCP 3000 to app SG"
     from_port       = 3000
    to_port         = 3000
   protocol        = "tcp"
   security_groups = ["sg-063fdeb13ef55df62"]
   }
  tags = {
    Name = "myapp-sg-alb"
  }
}
resource "aws_security_group" "myapp_sg_ec2" {
  name        = "myapp-sg-ec2"
  description = "Allow traffic for the app EC2"
  vpc_id      = aws_vpc.myapp_vpc.id

  ingress {
    description = "SSH from anywhere"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
     description     = "Allow TCP 3000 from another SG"
    from_port       = 3000
    to_port         = 3000
    protocol        = "tcp"
    security_groups = ["sg-0f82bb9cb61322bd9"]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "myapp-sg-ec2"
  }
}
resource "aws_lb" "myapp_alb" {
  name               = "myapp-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.myapp_sg_alb.id]
  subnets            = [
    aws_subnet.myapp_public_subnet_1.id,
    aws_subnet.myapp_public_subnet_2.id
  ]

  tags = {
    Name = "myapp-alb"
  }
}
resource "aws_lb_target_group" "myapp_tg" {
  name     = "myapp-tg"
  port     = 3000
  protocol = "HTTP"
  target_type = "instance"
  vpc_id   = aws_vpc.myapp_vpc.id

  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200-399"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}
resource "aws_lb_listener" "myapp_https_listener" {
  load_balancer_arn = aws_lb.myapp_alb.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = var.ssl_policy
  certificate_arn   = var.certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.myapp_tg.arn
  }
}
resource "aws_launch_template" "myapp_launch_template" {
  name_prefix   = "myapp-launch-template"
  image_id      = var.ami_id
  instance_type = var.instance_type
  key_name      = var.key_name

  vpc_security_group_ids = [aws_security_group.myapp_sg_ec2.id]

  user_data = base64encode(<<-EOF
    #!/bin/bash
    apt-get update
    apt-get install -y docker.io
    systemctl start docker
    systemctl enable docker
    docker pull poojasuryavanshi/my-docker-image8
    docker run -d -p 3000:3000 -e SECRET_WORD=MYDATA --network host poojasuryavanshi/my-docker-image8:latest
  EOF
  )

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "myapp-instance"
    }
  }
}

resource "aws_autoscaling_group" "myapp_asg" {
  desired_capacity    = var.desired_capacity
  max_size            = var.max_size
  min_size            = var.min_size
  vpc_zone_identifier = [aws_subnet.myapp_public_subnet_1.id, aws_subnet.myapp_public_subnet_2.id]

  launch_template {
    id      = aws_launch_template.myapp_launch_template.id
    version = "$Latest"
  }

  target_group_arns = [aws_lb_target_group.myapp_tg.arn]

  tag {
    key                 = "Name"
    value               = "myapp-asg"
    propagate_at_launch = true
  }
}
