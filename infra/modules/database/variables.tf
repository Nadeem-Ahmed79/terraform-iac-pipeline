variable "name" {
  description = "Environment name prefix (dev, prod)"
  type        = string
}

variable "namespace" {
  description = "Kubernetes namespace where Postgres will run"
  type        = string
  default     = "data"
}

variable "db_name" {
  description = "Database name"
  type        = string
  default     = "appdb"
}

variable "db_user" {
  description = "Database username"
  type        = string
  default     = "appuser"
}

variable "storage_size" {
  description = "Disk size for Postgres data"
  type        = string
  default     = "1Gi"
}

variable "image" {
  description = "Postgres image (pinned version)"
  type        = string
  default     = "postgres:17-alpine"
}
