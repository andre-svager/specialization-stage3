# ========== Networking Outputs ==========

output "vpc_id" {
  description = "VPC ID"
  value       = module.networking.vpc_id
}

output "vpc_cidr" {
  description = "VPC CIDR block"
  value       = module.networking.vpc_cidr
}

output "public_subnet_ids" {
  description = "Public subnet IDs"
  value       = module.networking.public_subnet_ids
}

output "private_subnet_ids" {
  description = "Private subnet IDs"
  value       = module.networking.private_subnet_ids
}

output "nat_gateway_id" {
  description = "NAT Gateway ID"
  value       = module.networking.nat_gateway_id
}

# ========== EKS Outputs ==========

output "eks_cluster_id" {
  description = "EKS cluster ID"
  value       = module.eks.cluster_id
}

output "eks_cluster_name" {
  description = "EKS cluster name"
  value       = module.eks.cluster_name
}

output "eks_cluster_endpoint" {
  description = "EKS cluster API endpoint"
  value       = module.eks.cluster_endpoint
}

output "eks_cluster_certificate_authority_data" {
  description = "EKS cluster certificate authority data"
  value       = module.eks.cluster_certificate_authority_data
  sensitive   = true
}

output "eks_oidc_provider_arn" {
  description = "EKS OIDC provider ARN"
  value       = module.eks.oidc_provider_arn
}

output "eks_oidc_issuer_url" {
  description = "EKS OIDC issuer URL"
  value       = module.eks.oidc_issuer_url
}

# ========== RDS Outputs ==========

output "rds_analytics_endpoint" {
  description = "Analytics RDS endpoint"
  value       = module.databases.rds_analytics_endpoint
}

output "rds_analytics_address" {
  description = "Analytics RDS address (hostname only)"
  value       = module.databases.rds_analytics_address
}

output "rds_auth_endpoint" {
  description = "Auth RDS endpoint"
  value       = module.databases.rds_auth_endpoint
}

output "rds_auth_address" {
  description = "Auth RDS address (hostname only)"
  value       = module.databases.rds_auth_address
}

output "rds_flag_endpoint" {
  description = "Flag RDS endpoint"
  value       = module.databases.rds_flag_endpoint
}

output "rds_flag_address" {
  description = "Flag RDS address (hostname only)"
  value       = module.databases.rds_flag_address
}

# ========== ElastiCache Outputs ==========

output "redis_endpoint" {
  description = "Redis endpoint (hostname:port)"
  value       = "${module.databases.redis_endpoint}:${module.databases.redis_port}"
}

output "redis_hostname" {
  description = "Redis hostname"
  value       = module.databases.redis_endpoint
}

output "redis_port" {
  description = "Redis port"
  value       = module.databases.redis_port
}

# ========== DynamoDB Outputs ==========

output "dynamodb_table_name" {
  description = "DynamoDB table name"
  value       = module.databases.dynamodb_table_name
}

output "dynamodb_table_arn" {
  description = "DynamoDB table ARN"
  value       = module.databases.dynamodb_table_arn
}

# ========== SQS Outputs ==========

output "evaluation_queue_url" {
  description = "Evaluation SQS queue URL"
  value       = module.messaging.evaluation_queue_url
}

output "evaluation_queue_arn" {
  description = "Evaluation SQS queue ARN"
  value       = module.messaging.evaluation_queue_arn
}

# ========== ECR Outputs ==========

output "ecr_analytics_service_url" {
  description = "Analytics service ECR repository URL"
  value       = module.ecr.analytics_service_repository_url
}

output "ecr_auth_service_url" {
  description = "Auth service ECR repository URL"
  value       = module.ecr.auth_service_repository_url
}

output "ecr_evaluation_service_url" {
  description = "Evaluation service ECR repository URL"
  value       = module.ecr.evaluation_service_repository_url
}

output "ecr_flag_service_url" {
  description = "Flag service ECR repository URL"
  value       = module.ecr.flag_service_repository_url
}

output "ecr_target_service_url" {
  description = "Target service ECR repository URL"
  value       = module.ecr.target_service_repository_url
}

# ========== Connection String Outputs ==========

output "database_connection_strings" {
  description = "Database connection strings for services"
  value = {
    analytics = "postgresql://${var.rds_username}:****@${module.databases.rds_analytics_address}:5432/analytics"
    auth      = "postgresql://${var.rds_username}:****@${module.databases.rds_auth_address}:5432/auth"
    flag      = "postgresql://${var.rds_username}:****@${module.databases.rds_flag_address}:5432/flag"
  }
  sensitive = true
}

output "redis_connection_string" {
  description = "Redis connection string"
  value       = "redis://${module.databases.redis_endpoint}:${module.databases.redis_port}"
}
