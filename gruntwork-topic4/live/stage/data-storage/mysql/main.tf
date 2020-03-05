provider "aws" {
  region                  = "us-east-2"
  shared_credentials_file = "/Users/david/.aws/config"
  profile                 = "dev"
}

terraform {
  backend "s3" {
    bucket         = "terraform-state-20191104"
    key            = "gw/topic4/stage/data-storage/mysql/terraform.tfstate"
    region         = "us-east-2"
    dynamodb_table = "terraform-up-and-running-locks"
    encrypt        = true
  }
}

module "mysql-db" {
  source = "../../../modules/data-storage/"

  db-name = "mysql-test"
}
