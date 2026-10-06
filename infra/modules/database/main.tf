locals {
  # Address the app will use to reach Postgres inside the cluster
  db_host = "postgres.${var.namespace}.svc.cluster.local"
}

# ---------- Strong random password ----------
resource "random_password" "db" {
  length           = 24
  special          = true
  override_special = "_-"
}

# ---------- The "vault" entry in Secrets Manager ----------
resource "aws_secretsmanager_secret" "db" {
  # checkov:skip=CKV_AWS_149:AWS-managed key is enough locally; use a customer-managed KMS key in prod
  # checkov:skip=CKV2_AWS_57:Rotation needs a rotation Lambda; out of scope locally
  name                    = "${var.name}/postgres/credentials"
  description             = "Postgres credentials for ${var.name}"
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "db" {
  secret_id = aws_secretsmanager_secret.db.id
  secret_string = jsonencode({
    username = var.db_user
    password = random_password.db.result
    dbname   = var.db_name
    host     = local.db_host
    port     = 5432
  })
}
