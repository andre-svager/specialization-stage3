output "analytics_service_repository_url" {
  description = "Analytics service ECR repository URL"
  value       = aws_ecr_repository.analytics_service.repository_url
}

output "auth_service_repository_url" {
  description = "Auth service ECR repository URL"
  value       = aws_ecr_repository.auth_service.repository_url
}

output "evaluation_service_repository_url" {
  description = "Evaluation service ECR repository URL"
  value       = aws_ecr_repository.evaluation_service.repository_url
}

output "flag_service_repository_url" {
  description = "Flag service ECR repository URL"
  value       = aws_ecr_repository.flag_service.repository_url
}

output "target_service_repository_url" {
  description = "Target service ECR repository URL"
  value       = aws_ecr_repository.target_service.repository_url
}

output "analytics_service_repository_arn" {
  description = "Analytics service ECR repository ARN"
  value       = aws_ecr_repository.analytics_service.arn
}

output "auth_service_repository_arn" {
  description = "Auth service ECR repository ARN"
  value       = aws_ecr_repository.auth_service.arn
}

output "evaluation_service_repository_arn" {
  description = "Evaluation service ECR repository ARN"
  value       = aws_ecr_repository.evaluation_service.arn
}

output "flag_service_repository_arn" {
  description = "Flag service ECR repository ARN"
  value       = aws_ecr_repository.flag_service.arn
}

output "target_service_repository_arn" {
  description = "Target service ECR repository ARN"
  value       = aws_ecr_repository.target_service.arn
}
