variable "environment" {
  description = "Environment name (e.g., staging, production)"
  type        = string

  validation {
    condition     = can(regex("^(staging|production)$", var.environment))
    error_message = "Environment must be 'staging' or 'production'."
  }
}

variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
}

variable "kubernetes_version" {
  description = "Kubernetes version to use for the EKS cluster"
  type        = string
  default     = "1.29"
}

variable "instance_type" {
  description = "EC2 instance type for node group"
  type        = string
  default     = "t3.medium"
}

variable "desired_size" {
  description = "Desired number of nodes in the node group"
  type        = number
  default     = 2
}

variable "min_size" {
  description = "Minimum number of nodes in the node group"
  type        = number
  default     = 1
}

variable "max_size" {
  description = "Maximum number of nodes in the node group"
  type        = number
  default     = 2
}

variable "public_subnet_ids" {
  description = "List of public subnet IDs"
  type        = list(string)
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs"
  type        = list(string)
}

variable "eks_security_group_id" {
  description = "Security group ID for EKS cluster"
  type        = string
}

variable "rds_security_group_id" {
  description = "RDS security group ID"
  type        = string
}

variable "elasticache_security_group_id" {
  description = "ElastiCache security group ID"
  type        = string
}
