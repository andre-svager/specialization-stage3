output "rds_analytics_endpoint" {
  description = "Analytics RDS endpoint"
  value       = aws_db_instance.analytics.endpoint
}

output "rds_auth_endpoint" {
  description = "Auth RDS endpoint"
  value       = aws_db_instance.auth.endpoint
}

output "rds_flag_endpoint" {
  description = "Flag RDS endpoint"
  value       = aws_db_instance.flag.endpoint
}

output "rds_analytics_address" {
  description = "Analytics RDS address"
  value       = aws_db_instance.analytics.address
}

output "rds_auth_address" {
  description = "Auth RDS address"
  value       = aws_db_instance.auth.address
}

output "rds_flag_address" {
  description = "Flag RDS address"
  value       = aws_db_instance.flag.address
}

output "rds_analytics_port" {
  description = "Analytics RDS port"
  value       = aws_db_instance.analytics.port
}

output "rds_auth_port" {
  description = "Auth RDS port"
  value       = aws_db_instance.auth.port
}

output "rds_flag_port" {
  description = "Flag RDS port"
  value       = aws_db_instance.flag.port
}

output "redis_endpoint" {
  description = "Redis endpoint"
  value       = aws_elasticache_cluster.redis.cache_nodes[0].address
}

output "redis_port" {
  description = "Redis port"
  value       = aws_elasticache_cluster.redis.port
}

output "redis_engine_version" {
  description = "Redis engine version"
  value       = aws_elasticache_cluster.redis.engine_version
}

output "dynamodb_table_name" {
  description = "DynamoDB table name"
  value       = aws_dynamodb_table.toggle_master_analytics.name
}

output "dynamodb_table_arn" {
  description = "DynamoDB table ARN"
  value       = aws_dynamodb_table.toggle_master_analytics.arn
}
