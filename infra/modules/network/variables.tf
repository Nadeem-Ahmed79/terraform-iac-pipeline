variable "name" {
  description = "Name prefix for all resources"
  type        = string
}

variable "vpc_cidr" {
  description = "IP range for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "tags" {
  description = "Extra tags for all resources"
  type        = map(string)
  default     = {}
}

variable "azs" {
  description = "Availability zones to spread subnets across"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

variable "admin_cidr" {
  description = "IP range allowed to SSH (must never be the whole internet)"
  type        = string
  default     = "10.0.0.0/16"

  validation {
    condition     = var.admin_cidr != "0.0.0.0/0"
    error_message = "admin_cidr must not be 0.0.0.0/0 (SSH open to the whole internet)."
  }
}
