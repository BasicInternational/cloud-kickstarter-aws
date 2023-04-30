output "db_address" {
  value = aws_db_instance.prod.address
}

output "db_username" {
  value = var.rds_admin_username
}

output "db_password" {
  value = random_password.db_admin_password.result
}