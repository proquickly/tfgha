provider "aws" {
  region = "us-west-2"
}

resource "aws_instance" "py_server" {
  ami           = "ami-06946f6c9b153d494"
  instance_type = "t2.micro"

  user_data = <<-EOF
              #!/bin/bash
              sudo apt-get update
              sudo apt-get install -y python3 python3-pip
              pip3 install flask requests
              mkdir -p /home/ubuntu/app

              # Downloading app.py from S3
              # must first aws s3 cp /Users/andy/ws/projects/andy/tfgha/src/tfgha/app.py s3://proquickly/apps/tfgha/app.py
              aws s3 cp s3://proquickly/apps/tfgha/app.py /home/ubuntu/app/app.py

              cd /home/ubuntu/app
              nohup python3 app.py &
              EOF

  tags = {
    Name = "FlaskAppInstance"
  }

  vpc_security_group_ids = [aws_security_group.allow_http.id]
}

resource "aws_security_group" "allow_http" {
  name        = "allow_http_flask_web"
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
}
