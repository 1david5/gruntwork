provider "aws" {
  region = "us-east-2"
  shared_credentials_file = "/Users/david/.aws/config"
  profile                 = "dev"
}

terraform {
  backend "s3" {
    # Replace this with your bucket name!
    bucket         = "terraform-state-20191104"
    key            = "workspaces-example/terraform.tfstate"
    region         = "us-east-2"
    # Replace this with your DynamoDB table name!
    dynamodb_table = "terraform-up-and-running-locks"
    encrypt        = true
  }
}

resource "aws_instance" "tfexample" {
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = (
    terraform.workspace == "default" ? "t2.medium" : "t2.micro")
}