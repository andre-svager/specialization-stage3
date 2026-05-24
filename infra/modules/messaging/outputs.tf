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
