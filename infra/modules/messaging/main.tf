# Messaging Module - SQS Queues

# Evaluation processing queue
resource "aws_sqs_queue" "evaluation" {
  name                      = "${var.environment}-evaluation-queue.fifo"
  fifo_queue                = var.use_fifo_queue
  content_based_deduplication = var.use_fifo_queue ? true : false
  
  visibility_timeout_seconds = var.visibility_timeout
  message_retention_seconds  = var.message_retention_period
  receive_wait_time_seconds  = var.receive_wait_time
  sqs_managed_sse_enabled    = true

  tags = {
    Name        = "${var.environment}-evaluation-queue"
    Environment = var.environment
    Project     = "evaluation-service"
    ManagedBy   = "Terraforms"
    CreatedAt   = "2026-05-22"
  }
}

# Evaluation DLQ
resource "aws_sqs_queue" "evaluation_dlq" {
  name                      = "${var.environment}-evaluation-queue-dlq.fifo"
  fifo_queue                = var.use_fifo_queue
  content_based_deduplication = var.use_fifo_queue ? true : false
  
  message_retention_seconds = var.dlq_message_retention_period
  sqs_managed_sse_enabled   = true

  tags = {
    Name        = "${var.environment}-evaluation-queue-dlq"
    Environment = var.environment
    Project     = "evaluation-service"
    ManagedBy   = "Terraforms"
    CreatedAt   = "2026-05-22"
  }
}

# Redrive policy for evaluation queue
resource "aws_sqs_queue_redrive_policy" "evaluation" {
  queue_url = aws_sqs_queue.evaluation.url

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.evaluation_dlq.arn
    maxReceiveCount     = var.max_receive_count
  })
}

# CloudWatch Alarms for queue depth
resource "aws_cloudwatch_metric_alarm" "evaluation_queue_depth" {
  alarm_name          = "${var.environment}-evaluation-queue-depth"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "ApproximateNumberOfMessagesVisible"
  namespace           = "AWS/SQS"
  period              = "300"
  statistic           = "Average"
  threshold           = "100"
  alarm_description   = "Alert when evaluation queue has more than 100 messages"

  dimensions = {
    QueueName = aws_sqs_queue.evaluation.name
  }

  tags = {
    Name        = "${var.environment}-cw-evaluation-queue-dlq"
    Environment = var.environment
    Project     = "evaluation-service"
    ManagedBy   = "Terraforms"
    CreatedAt   = "2026-05-22"
  }
}
