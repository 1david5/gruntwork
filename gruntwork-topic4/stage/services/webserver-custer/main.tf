terraform {
  backend "s3" {
    bucket         = "terraform-state-20191104"
    key            = "gw/topic4/stage/services/webserver-cluster/terraform.tfstate"
    region         = "us-east-2"
    dynamodb_table = "terraform-up-and-running-locks"
    encrypt        = true
  }
}

provider "aws" {
  region = "us-east-2"
}

module "webserver-cluster" {
  source = "../../../modules/services/webserver-cluster/"

  cluster_name  = "webservers-stage"
  instance_type = "t2.micro"
  min_size      = 2
  max_size      = 2
  server_port   = var.server_port
}