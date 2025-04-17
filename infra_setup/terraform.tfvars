
aws_region = "ap-south-1"
ami_id     = "ami-0e35ddab05955cf57"  
key_name   = "shubham"


ssl_policy = "ELBSecurityPolicy-TLS13-1-2-2021-06"
certificate_arn = "arn:aws:iam::089830611065:server-certificate/my-self-signed-cert" 

instance_type = "t2.micro"
desired_capacity = 2
max_size         = 4
min_size         = 2
