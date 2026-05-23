output "main_queue_url" {
  description = "Main queue URL"
  value       = aws_sqs_queue.main.url
}

output "main_queue_arn" {
  description = "Main queue ARN"
  value       = aws_sqs_queue.main.arn
}

output "main_queue_dlq_url" {
  description = "Main queue DLQ URL"
  value       = aws_sqs_queue.main_dlq.url
}

output "analytics_queue_url" {
  description = "Analytics queue URL"
  value       = aws_sqs_queue.analytics.url
}

output "analytics_queue_arn" {
  description = "Analytics queue ARN"
  value       = aws_sqs_queue.analytics.arn
}

output "analytics_queue_dlq_url" {
  description = "Analytics queue DLQ URL"
  value       = aws_sqs_queue.analytics_dlq.url
}

output "evaluation_queue_url" {
  description = "Evaluation queue URL"
  value       = aws_sqs_queue.evaluation.url
}

output "evaluation_queue_arn" {
  description = "Evaluation queue ARN"
  value       = aws_sqs_queue.evaluation.arn
}

output "evaluation_queue_dlq_url" {
  description = "Evaluation queue DLQ URL"
  value       = aws_sqs_queue.evaluation_dlq.url
}
