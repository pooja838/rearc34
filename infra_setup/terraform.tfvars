# AWS Region
aws_region = "ap-south-1"

# AMI ID for EC2 instance
ami_id = "ami-0e35ddab05955cf57"  # Replace with your AMI ID

# Key name for SSH access to EC2 instances
key_name = "shubham"

# SSL Configuration
ssl_policy = "ELBSecurityPolicy-TLS13-1-2-2021-06"

# ARN of the SSL certificate from IAM or ACM for the HTTPS listener
certificate_arn = "arn:aws:iam::089830611065:server-certificate/my-self-signed-cert"  # Replace with your actual certificate ARN

# EC2 Instance Type
instance_type = "t2.micro"

# Auto Scaling Group Configuration
desired_capacity = 2
max_size         = 4
min_size         = 2
