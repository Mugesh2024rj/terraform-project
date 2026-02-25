provider "aws" {
  region = "us-east-1"
}

############################
# Get Default VPC
############################
data "aws_vpc" "default" {
  default = true
}

############################
# Get Subnets from Default VPC
############################
data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

############################
# Security Group
############################
resource "aws_security_group" "web_sg" {
  name        = "terraform-web-sg"
  description = "Allow SSH and HTTP"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "Allow SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow HTTP"
    from_port   = 80
    to_port     = 80
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
    Name = "Terraform-Web-SG"
  }
}

############################
# EC2 Instance
############################
resource "aws_instance" "my_server" {
  ami           = "ami-0f3caa1cf4417e51b"   # Amazon Linux 2023 (us-east-1)
  instance_type = "t3.micro"
  key_name      = "key-pair-virginia"      # Make sure this key exists

  subnet_id                   = data.aws_subnets.default.ids[0]
  vpc_security_group_ids      = [aws_security_group.web_sg.id]
  associate_public_ip_address = true

  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y httpd
              systemctl start httpd
              systemctl enable httpd
              echo "<h1>Terraform EC2 with User Data</h1>" > /var/www/html/index.html
              EOF

  tags = {
    Name = "Terraform-UserData-Server"
  }
}

############################
# Output Public IP
############################
output "public_ip" {
  value = aws_instance.my_server.public_ip
}
