variable "environment" {
  description = "Environment name (e.g., staging, production)"
  type        = string

  validation {
    condition     = can(regex("^(staging|production)$", var.environment))
    error_message = "Environment must be 'staging' or 'production'."
  }
}

variable "use_fifo_queue" {
  description = "Use FIFO queues instead of standard"
  type        = bool
  default     = true
}

variable "visibility_timeout" {
  description = "Visibility timeout in seconds"
  type        = number
  default     = 300
}

variable "message_retention_period" {
  description = "Message retention period in seconds (max 1209600 = 14 days)"
  type        = number
  default     = 345600  # 4 days
}

variable "receive_wait_time" {
  description = "Wait time for long polling in seconds"
  type        = number
  default     = 20
}

variable "max_message_size" {
  description = "Maximum message size in bytes"
  type        = number
  default     = 262144  # 256 KB
}

variable "dlq_message_retention_period" {
  description = "DLQ message retention period in seconds"
  type        = number
  default     = 1209600  # 14 days
}

variable "max_receive_count" {
  description = "Maximum number of receives before sending to DLQ"
  type        = number
  default     = 3
}
