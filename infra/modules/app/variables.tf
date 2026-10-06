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
  default     = "nginx:1.27-alpine"

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
