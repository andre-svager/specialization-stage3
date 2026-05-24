variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name (e.g., staging, production)"
  type        = string
  default     = "staging"

  validation {
    condition     = can(regex("^(staging|production)$", var.environment))
    error_message = "Environment must be 'staging' or 'production'."
  }
}

# ========== VPC / Networking ==========

variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
  default     = "10.1.0.0/16"
}

variable "availability_zones" {
  description = "List of availability zones"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

# ========== EKS Configuration ==========

variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
}

variable "kubernetes_version" {
  description = "Kubernetes version for EKS"
  type        = string
  default     = "1.29"
}

variable "node_instance_type" {
  description = "EC2 instance type for EKS nodes"
  type        = string
  default     = "t3.medium"
}

variable "node_desired_size" {
  description = "Desired number of nodes"
  type        = number
  default     = 2
}

variable "node_min_size" {
  description = "Minimum number of nodes"
  type        = number
  default     = 1
}

variable "node_max_size" {
  description = "Maximum number of nodes"
  type        = number
  default     = 2
}

# ========== RDS Configuration ==========

variable "postgres_version" {
  description = "PostgreSQL version"
  type        = string
  default     = "13"
}

variable "rds_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.micro"
}

variable "rds_allocated_storage" {
  description = "Allocated storage in GB for RDS"
  type        = number
  default     = 20
}

variable "rds_username" {
  description = "RDS master username"
  type        = string
  sensitive   = true
}

variable "rds_password" {
  description = "RDS master password"
  type        = string
  sensitive   = true
}

variable "rds_multi_az" {
  description = "Enable Multi-AZ for RDS"
  type        = bool
  default     = false
}

variable "rds_backup_retention_days" {
  description = "RDS backup retention days"
  type        = number
  default     = 7
}

# ========== ElastiCache Configuration ==========

variable "redis_version" {
  description = "Redis version"
  type        = string
  default     = "7.0"
}

variable "redis_node_type" {
  description = "Redis node type"
  type        = string
  default     = "cache.t3.micro"
}

variable "redis_num_nodes" {
  description = "Number of Redis nodes"
  type        = number
  default     = 1
}

# ========== DynamoDB Configuration ==========

variable "dynamodb_billing_mode" {
  description = "DynamoDB billing mode"
  type        = string
  default     = "PAY_PER_REQUEST"

  validation {
    condition     = can(regex("^(PAY_PER_REQUEST|PROVISIONED)$", var.dynamodb_billing_mode))
    error_message = "Billing mode must be 'PAY_PER_REQUEST' or 'PROVISIONED'."
  }
}

variable "dynamodb_min_capacity" {
  description = "DynamoDB min capacity (PROVISIONED mode only)"
  type        = number
  default     = 5
}

variable "dynamodb_max_capacity" {
  description = "DynamoDB max capacity (PROVISIONED mode only)"
  type        = number
  default     = 40
}

# ========== SQS Configuration ==========

variable "use_fifo_queues" {
  description = "Use FIFO queues"
  type        = bool
  default     = true
}

variable "sqs_visibility_timeout" {
  description = "SQS visibility timeout (seconds)"
  type        = number
  default     = 300
}

variable "sqs_message_retention_period" {
  description = "SQS message retention period (seconds)"
  type        = number
  default     = 345600  # 4 days
}

variable "sqs_receive_wait_time" {
  description = "SQS receive wait time for long polling"
  type        = number
  default     = 20
}

# ========== ECR Configuration ==========

variable "ecr_images_to_keep" {
  description = "Number of images to keep per ECR repository"
  type        = number
  default     = 10
}
