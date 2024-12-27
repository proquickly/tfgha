provider "aws" {
  region = var.aws_region
}

variable "aws_region" {
  description = "The AWS region to deploy resources in"
  type        = string
  default     = "us-west-2"
}

variable "public_key_path" {
  description = "Path to the public key file"
  type        = string
  default     = "id_rsa.pub"
}

data "aws_security_groups" "all" {
  filter {
    name   = "group-name"
    values = ["*"]
  }
}

resource "aws_security_group" "cleanup_security_groups" {
  name        = "cleanup_security_groups_${random_id.suffix.hex}"
  description = "Security group for cleanup purposes"

  lifecycle {
    prevent_destroy = false
  }
}

# Add random suffix to avoid conflicts
resource "random_id" "suffix" {
  byte_length = 4
}

resource "aws_key_pair" "deployer" {
  key_name   = "deployer-key-${random_id.suffix.hex}"
  public_key = file(var.public_key_path)
}

resource "aws_security_group" "allow_ssh" {
  name        = "allow_ssh_${random_id.suffix.hex}"
  description = "Allow SSH inbound traffic"

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

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group" "allow_http" {
  name        = "allow_http_flask_${random_id.suffix.hex}"
  description = "Allow inbound HTTP traffic"

  ingress {
    from_port   = 5000
    to_port     = 5000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_instance" "py_server" {
  ami           = "ami-06946f6c9b153d494"
  instance_type = "t2.micro"
  key_name      = aws_key_pair.deployer.key_name

  user_data = file("setup.sh")

  tags = {
    Name = "FlaskAppInstance"
  }

  vpc_security_group_ids = [
    aws_security_group.allow_http.id, aws_security_group.allow_ssh.id
  ]
}
