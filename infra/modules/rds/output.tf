output "db_name_id" {
  value = aws_db_instance.ecs_app_db.id
}

output "db_endpoint" {
  value = aws_db_instance.ecs_app_db.address
}

output "db_arn" {
  value = aws_db_instance.ecs_app_db.arn  
}

output "db_name" {
  description = "database name"
  value       = aws_db_instance.ecs_app_db.db_name
}

output "db_username" {
  description = "username database"
  value       = aws_db_instance.ecs_app_db.username
}

output "db_port" {
  value = aws_db_instance.ecs_app_db.port
}

output "db_password_secret_arn" {
  description = "Secrets Manager ARN untuk DB password"
  value       = aws_db_instance.ecs_app_db.master_user_secret[0].secret_arn
}
