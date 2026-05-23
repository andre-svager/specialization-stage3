variable "environment" {
  description = "Environment name (e.g., staging, production)"
  type        = string

  validation {
    condition     = can(regex("^(staging|production)$", var.environment))
    error_message = "Environment must be 'staging' or 'production'."
  }
}

variable "images_to_keep" {
  description = "Number of images to keep per repository"
  type        = number
  default     = 10
}

variable "eks_cluster_role_arn" {
  description = "EKS cluster role ARN (for ECR pull permissions)"
  type        = string
}
