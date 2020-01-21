resource "aws_db_instance" "example" {
  identifier_prefix = var.db-name
  engine            = "mysql"
  allocated_storage = 10
  instance_class    = "db.t2.micro"
  name              = "example_database"
  username          = "admin"
  password          = "password"
  skip_final_snapshot = true
}