variable "namespace" {
  description = "Kubernetes namespace for the app"
  type        = string
}

variable "app_name" {
  description = "Name of the app"
  type        = string
  default     = "web"
}

variable "image" {
  description = "Container image (always pin a version, never use :latest)"
  type        = string
  default     = "nginxinc/nginx-unprivileged:1.27-alpine"

  validation {
    condition     = !endswith(var.image, ":latest")
    error_message = "Do not use the :latest tag. Pin an exact version."
  }
}

variable "replicas" {
  description = "Number of pod copies"
  type        = number
  default     = 2
}

variable "page_title" {
  description = "Heading shown on the web page"
  type        = string
  default     = "Terraform IaC Platform"
}

variable "env" {
  description = "Environment name shown on the page"
  type        = string
  default     = "dev"
}

variable "owner" {
  description = "Owner label (not shown on the page)"
  type        = string
  default     = "platform-team"
}
