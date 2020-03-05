provider "aws" {
  # shared_credentials_file = "/Users/david/.aws/config"
  region = "us-east-2"
}

terraform {
  backend "s3" {
    bucket         = "terraform-state-20191104"
    key            = "gw/topic5/"
    region         = "us-east-2"
    dynamodb_table = "terraform-up-and-running-locks"
    encrypt        = true
  }
}

# variable "user_name" {
#   description = "Create IAM users with these names"
#   type        = list(string)
#   default     = ["david", "test1", "test2", "test"]
# }

# variable "m_var"{
#   description = "Test loop over map"
#   type = map(string)
#   default = {
#     Name = "Test1"
#     ICAO = "TRAX"
#     Environment = "Test"
#   }
# }

# output "output"{
#   value = {for key, value in var.m_var :  upper(key)=>upper(value)}
# }

# resource "aws_iam_user" "user" {
#   count = length(var.user_name)
#   name  = var.user_name[count.index]
# }

# resource "aws_iam_user" "user"{
#   for_each = toset(var.user_name)
#   name = each.value
# }

# output "all_users"{
#   value = aws_iam_user.user
#   description = "All ARNs"
# }

# output "all_arns"{
#   value = values(aws_iam_user.user)[*].arn
# }

variable "server_port" {
  description = "The port the server will use for HTTP requests"
  type        = number
  default     = 8080
}

# resource "aws_security_group" "instance_SG" {
#   name = "terr_first_ec2"
#   ingress {
#     from_port   = var.server_port
#     to_port     = var.server_port
#     protocol    = "tcp"
#     cidr_blocks = ["0.0.0.0/0"]
#   }
#   lifecycle {
#     create_before_destroy = true
#   }
# }

# resource "aws_instance" "first_ec2" {
#   ami                    = "ami-0c55b159cbfafe1f0"
#   instance_type          = "t2.micro"
#   vpc_security_group_ids = [aws_security_group.instance_SG.id]
#   # tags                   = var.custom_tags
#   dynamic "tag" {
#     for_each = var.custom_tags
#     content {
#       key                 = tag.key
#       value               = tag.value
#       propagate_at_launch = true
#     }
#   }
# }

data "aws_availability_zones" "all" {}

variable "enable_autoscaling"{
  description = "If set to true, enable autoscaling"
  type = bool
}

variable "custom_tags" {
  description = "Tags for resources"
  type        = map(string)
  default = {
    Name = "TestDynamicBlock"
    Env  = "Test"
    ICAO = "Trax"
  }
}

resource "aws_security_group" "instance_SG" {
  name = "terr_first_ec2"
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

resource "aws_launch_configuration" "my_LConfig" {
  image_id        = "ami-0c55b159cbfafe1f0"
  instance_type   = "t2.micro"
  security_groups = [aws_security_group.instance_SG.id]
  user_data = <<-EOF
              #!/bin/bash
                echo "Hello, World" > index.html
                nohup busybox httpd -f -p 8080 &
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

  # load_balancers    = null
  health_check_type = "ELB"

  dynamic "tag" {
    for_each = var.custom_tags
    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }
}

resource "aws_autoscaling_schedule" "scale_out_busines_hours" {
  count = var.enable_autoscaling ? 1 :0
  scheduled_action_name  = "scale-out-during-business-hours"
  min_size               = 2
  max_size               = 10
  desired_capacity       = 10
  recurrence             = "0 9 * * *"
  autoscaling_group_name = aws_autoscaling_group.my_ASG.name
}

resource "aws_autoscaling_schedule" "scale_in_at_night"{
  count = var.enable_autoscaling ? 1 :0
  scheduled_action_name = "scale_in_at_night"
  min_size = 2
  max_size = 10
  desired_capacity = 2
  recurrence = "0 17 * * *"
  autoscaling_group_name = aws_autoscaling_group.my_ASG.name

}