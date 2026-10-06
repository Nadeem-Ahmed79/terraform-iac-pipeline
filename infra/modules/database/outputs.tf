output "secret_name" {
  description = "Secrets Manager secret holding the DB credentials"
  value       = aws_secretsmanager_secret.db.name
}

output "secret_arn" {
  value = aws_secretsmanager_secret.db.arn
}

output "db_host" {
  value = local.db_host
}
