output "address" {
  value       = module.mysql-db.address
  description = "Connect to the database at this endpoint"
}

output "port" {
  value       = module.mysql-db.port
  description = "The port the database is listening on"
}