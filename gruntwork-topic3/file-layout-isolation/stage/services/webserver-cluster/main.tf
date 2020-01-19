terraform {
  backend "s3" {
    # Replace this with your bucket name!
    bucket = "terraform-state-20191104"
    key    = "stage/services/webserver-cluster/terraform.tfstate"
    region = "us-east-2"
    # Replace this with your DynamoDB table name!
    dynamodb_table = "terraform-up-and-running-locks"
    encrypt        = true
  }
}

data "terraform_remote_state" "db" {
  backend = "s3"

  config = {
      # Replace this with your bucket name!
    bucket = "terraform-state-20191104"
    key    = "stage/data-stores/mysql/terraform.tfstate"
    region = "us-east-2"
  }
}

provider "aws" {
  region                  = "us-east-2"
  # shared_credentials_file = "/home/ec2-user/.aws/cred"
  # profile                 = "dev"

#   assume_role {
#       session_name = "SESSION_NAME"
#       external_id  = "EXTERNAL_ID"
#     }

}

variable "server_port" {
  description = "The port the server will use for HTTP requests"
  type        = number
  # default     = 8080
}

resource "aws_security_group" "instance_SG" {
  name = "tf_ec2sg"
  ingress{
    from_port   = var.server_port
    to_port     = var.server_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  lifecycle {
    create_before_destroy = true
  }
}

# resource "aws_instance" "tf_ec2" {
#   ami                    = "ami-0c55b159cbfafe1f0"
#   instance_type          = "t2.micro"
#   vpc_security_group_ids = [aws_security_group.instance_SG.id]
#   user_data = <<-EOF
            # !/bin/bash
            # db_address="${data.terraform_remote_state.db.outputs.address}"
            # db_port="${data.terraform_remote_state.db.outputs.port}"
            # echo "Hello, World. DB is at $db_address:$db_port" >> index.html
            # nohup busybox httpd -f -p "${var.server_port}" &
            # EOF
#   tags = {
    # Name = "tf_xample"
#   }
# }


resource "aws_security_group" "elb_sg" {
  name = "terraform-example-elb"
  # Allow all outbound
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  # Inbound HTTP from anywhere
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_launch_configuration" "my_LConfig" {
  image_id        = "ami-0c55b159cbfafe1f0"
  instance_type   = "t2.micro"
  security_groups = [aws_security_group.instance_SG.id]
  user_data = <<-EOF
                #!/bin/bash
                db_address="${data.terraform_remote_state.db.outputs.address}"
                db_port="${data.terraform_remote_state.db.outputs.port}"
                echo "Hello, World. DB is at $db_address:$db_port" >> index.html
                nohup busybox httpd -f -p "${var.server_port}" &
                EOF
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "my_ASG" {
  launch_configuration = aws_launch_configuration.my_LConfig.id
  availability_zones   = data.aws_availability_zones.all.names

  min_size = 3
  max_size = 10

  load_balancers    = [aws_elb.exampleclb.name]
  health_check_type = "ELB"

  tag {
    key                 = "Name"
    value               = "terraform-asg-example"
    propagate_at_launch = true
  }
}

resource "aws_elb" "exampleclb" {
  name               = "terraform-asg-example"
  availability_zones = data.aws_availability_zones.all.names
  security_groups    = [aws_security_group.elb_sg.id]

  health_check {
    target              = "HTTP:${var.server_port}/"
    interval            = 30
    timeout             = 3
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  # This adds a listener for incoming HTTP requests.
  listener {
    lb_port           = 80
    lb_protocol       = "http"
    instance_port     = var.server_port
    instance_protocol = "http"
  }
}

data "aws_availability_zones" "all" {}

# output "public_ip" {
#   value       = aws_instance.first_ec2.public_ip
#   description = "The public IP of the web server"
# }

output "clb_dns_name" {
  value       = aws_elb.exampleclb.dns_name
  description = "The domain name of the load balancer"
}
