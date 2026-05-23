# Messaging Module - SQS Queues

# Main SQS Queue for async processing
resource "aws_sqs_queue" "main" {
  name                      = "${var.environment}-main-queue.fifo"
  fifo_queue                = var.use_fifo_queue
  content_based_deduplication = var.use_fifo_queue ? true : false
  
  visibility_timeout_seconds      = var.visibility_timeout
  message_retention_seconds       = var.message_retention_period
  receive_wait_time_seconds       = var.receive_wait_time
  max_message_size                = var.max_message_size
  
  sqs_managed_sse_enabled = true

  tags = {
    Name        = "${var.environment}-main-queue"
    Environment = var.environment
  }
}

# Dead Letter Queue (DLQ) for main queue
resource "aws_sqs_queue" "main_dlq" {
  name                      = "${var.environment}-main-queue-dlq.fifo"
  fifo_queue                = var.use_fifo_queue
  content_based_deduplication = var.use_fifo_queue ? true : false
  
  message_retention_seconds = var.dlq_message_retention_period
  sqs_managed_sse_enabled   = true

  tags = {
    Name        = "${var.environment}-main-queue-dlq"
    Environment = var.environment
  }
}

# Redrive policy for main queue
resource "aws_sqs_queue_redrive_policy" "main" {
  queue_url = aws_sqs_queue.main.url

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.main_dlq.arn
    maxReceiveCount     = var.max_receive_count
  })
}

# Analytics processing queue
resource "aws_sqs_queue" "analytics" {
  name                      = "${var.environment}-analytics-queue.fifo"
  fifo_queue                = var.use_fifo_queue
  content_based_deduplication = var.use_fifo_queue ? true : false
  
  visibility_timeout_seconds = var.visibility_timeout
  message_retention_seconds  = var.message_retention_period
  receive_wait_time_seconds  = var.receive_wait_time
  sqs_managed_sse_enabled    = true

  tags = {
    Name        = "${var.environment}-analytics-queue"
    Environment = var.environment
  }
}

# Analytics DLQ
resource "aws_sqs_queue" "analytics_dlq" {
  name                      = "${var.environment}-analytics-queue-dlq.fifo"
  fifo_queue                = var.use_fifo_queue
  content_based_deduplication = var.use_fifo_queue ? true : false
  
  message_retention_seconds = var.dlq_message_retention_period
  sqs_managed_sse_enabled   = true

  tags = {
    Name        = "${var.environment}-analytics-queue-dlq"
    Environment = var.environment
  }
}

# Redrive policy for analytics queue
resource "aws_sqs_queue_redrive_policy" "analytics" {
  queue_url = aws_sqs_queue.analytics.url

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.analytics_dlq.arn
    maxReceiveCount     = var.max_receive_count
  })
}

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
resource "aws_cloudwatch_metric_alarm" "main_queue_depth" {
  alarm_name          = "${var.environment}-main-queue-depth"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "ApproximateNumberOfMessagesVisible"
  namespace           = "AWS/SQS"
  period              = "300"
  statistic           = "Average"
  threshold           = "100"
  alarm_description   = "Alert when main queue has more than 100 messages"

  dimensions = {
    QueueName = aws_sqs_queue.main.name
  }
}

resource "aws_cloudwatch_metric_alarm" "analytics_queue_depth" {
  alarm_name          = "${var.environment}-analytics-queue-depth"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "ApproximateNumberOfMessagesVisible"
  namespace           = "AWS/SQS"
  period              = "300"
  statistic           = "Average"
  threshold           = "100"
  alarm_description   = "Alert when analytics queue has more than 100 messages"

  dimensions = {
    QueueName = aws_sqs_queue.analytics.name
  }
}

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
}
