variable "cluster_name" {
  description = "Name of the kind cluster"
  type        = string
}

variable "worker_count" {
  description = "Number of worker nodes"
  type        = number
  default     = 1

  validation {
    condition     = var.worker_count >= 1 && var.worker_count <= 3
    error_message = "worker_count must be between 1 and 3 (laptop resources are limited)."
  }
}
