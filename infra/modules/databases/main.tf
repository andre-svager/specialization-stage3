# Databases Module - RDS PostgreSQL, ElastiCache Redis, DynamoDB

# DB Subnet Group for RDS
resource "aws_db_subnet_group" "rds" {
  name       = "${var.environment}-rds-subnet-group"
  subnet_ids = var.private_subnet_ids

  tags = {
    Name        = "${var.environment}-rds-subnet-group"
    Environment = var.environment
  }
}

# ElastiCache Subnet Group for Redis
resource "aws_elasticache_subnet_group" "redis" {
  name       = "${var.environment}-redis-subnet-group"
  subnet_ids = var.private_subnet_ids

  tags = {
    Name        = "${var.environment}-redis-subnet-group"
    Environment = var.environment
  }
}

# ==================== RDS PostgreSQL Databases ====================

# RDS 1: Auth Service Database
resource "aws_db_instance" "auth" {
  identifier            = "${var.environment}-auth-db"
  engine                = "postgres"
  engine_version        = var.postgres_version
  instance_class        = var.rds_instance_class
  allocated_storage     = var.rds_allocated_storage
  db_name               = "auth_db"
  username              = var.rds_username
  password              = var.rds_password
  parameter_group_name  = aws_db_parameter_group.postgres.name
  db_subnet_group_name  = aws_db_subnet_group.rds.name
  vpc_security_group_ids = [var.rds_security_group_id]
  
  multi_az               = var.multi_az
  publicly_accessible    = false
  skip_final_snapshot    = var.environment == "staging" ? true : false
  backup_retention_period = var.backup_retention_days
  backup_window          = "03:00-04:00"
  maintenance_window     = "sun:04:00-sun:05:00"

  storage_type      = "gp2"
  storage_encrypted = true

  tags = {
    Name        = "${var.environment}-auth-db"
    Environment = var.environment
    Service     = "auth-service"
  }
}

# RDS 2: Flag Service Database
resource "aws_db_instance" "flag" {
  identifier            = "${var.environment}-flag-db"
  engine                = "postgres"
  engine_version        = var.postgres_version
  instance_class        = var.rds_instance_class
  allocated_storage     = var.rds_allocated_storage
  db_name               = "flags_db"
  username              = var.rds_username
  password              = var.rds_password
  parameter_group_name  = aws_db_parameter_group.postgres.name
  db_subnet_group_name  = aws_db_subnet_group.rds.name
  vpc_security_group_ids = [var.rds_security_group_id]
  
  multi_az               = var.multi_az
  publicly_accessible    = false
  skip_final_snapshot    = var.environment == "staging" ? true : false
  backup_retention_period = var.backup_retention_days
  backup_window          = "03:00-04:00"
  maintenance_window     = "sun:04:00-sun:05:00"

  storage_type      = "gp2"
  storage_encrypted = true

  tags = {
    Name        = "${var.environment}-flag-db"
    Environment = var.environment
    Service     = "flag-service"
  }
}

# RDS 3: Target Service Database
resource "aws_db_instance" "target" {
  identifier            = "${var.environment}-target-db"
  engine                = "postgres"
  engine_version        = var.postgres_version
  instance_class        = var.rds_instance_class
  allocated_storage     = var.rds_allocated_storage
  db_name               = "targeting_db"
  username              = var.rds_username
  password              = var.rds_password
  parameter_group_name  = aws_db_parameter_group.postgres.name
  db_subnet_group_name  = aws_db_subnet_group.rds.name
  vpc_security_group_ids = [var.rds_security_group_id]
  
  multi_az               = var.multi_az
  publicly_accessible    = false
  skip_final_snapshot    = var.environment == "staging" ? true : false
  backup_retention_period = var.backup_retention_days
  backup_window          = "03:00-04:00"
  maintenance_window     = "sun:04:00-sun:05:00"

  storage_type      = "gp2"
  storage_encrypted = true

  tags = {
    Name        = "${var.environment}-target-db"
    Environment = var.environment
    Service     = "target-service"
  }
}

# PostgreSQL Parameter Group
resource "aws_db_parameter_group" "postgres" {
  name   = "${var.environment}-postgres-params"
  family = "postgres${var.postgres_version}"

  parameter {
    name  = "log_connections"
    value = "1"
  }

  parameter {
    name  = "log_disconnections"
    value = "1"
  }

  tags = {
    Name        = "${var.environment}-postgres-params"
    Environment = var.environment
  }
}

# ==================== ElastiCache Redis ====================

resource "aws_elasticache_cluster" "redis" {
  cluster_id           = "${var.environment}-redis"
  engine               = "redis"
  engine_version       = var.redis_version
  node_type            = var.redis_node_type
  num_cache_nodes      = var.redis_num_nodes
  parameter_group_name = "default.redis${substr(var.redis_version, 0, 3)}"
  port                 = 6379
  subnet_group_name    = aws_elasticache_subnet_group.redis.name
  security_group_ids   = [var.elasticache_security_group_id]
  
  maintenance_window = "sun:05:00-sun:06:00"
  notification_topic_arn = null
  
  log_delivery_configuration {
    destination      = aws_cloudwatch_log_group.redis_slow_log.name
    destination_type = "cloudwatch-logs"
    log_format       = "json"
    log_type         = "slow-log"
  }

  tags = {
    Name        = "${var.environment}-redis"
    Environment = var.environment
  }
}

# CloudWatch Log Group for Redis
resource "aws_cloudwatch_log_group" "redis_slow_log" {
  name              = "/aws/elasticache/${var.environment}-redis-slow-log"
  retention_in_days = 7

  tags = {
    Name        = "${var.environment}-redis-slow-log"
    Environment = var.environment
  }
}

# ==================== DynamoDB ====================

resource "aws_dynamodb_table" "toggle_master_analytics" {
  name           = var.environment == "production" ? "ToggleMasterAnalytics" : "${var.environment}-ToggleMasterAnalytics"
  billing_mode   = var.dynamodb_billing_mode
  hash_key       = "event_id"
  
  attribute {
    name = "event_id"
    type = "S"
  }

  point_in_time_recovery {
    enabled = true
  }

  server_side_encryption {
    enabled = true
  }

  tags = {
    Name        = "ToggleMasterAnalytics"
    Environment = var.environment
  }
}

# DynamoDB Auto Scaling (if billing_mode is PROVISIONED)
resource "aws_appautoscaling_target" "dynamodb_table" {
  count              = var.dynamodb_billing_mode == "PROVISIONED" ? 1 : 0
  max_capacity       = var.dynamodb_max_capacity
  min_capacity       = var.dynamodb_min_capacity
  resource_id        = "table/${aws_dynamodb_table.toggle_master_analytics.name}"
  scalable_dimension = "dynamodb:table:WriteCapacityUnits"
  service_namespace  = "dynamodb"
}

resource "aws_appautoscaling_policy" "dynamodb_table_policy" {
  count              = var.dynamodb_billing_mode == "PROVISIONED" ? 1 : 0
  name               = "${var.environment}-dynamodb-scaling-policy"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.dynamodb_table[0].resource_id
  scalable_dimension = aws_appautoscaling_target.dynamodb_table[0].scalable_dimension
  service_namespace  = aws_appautoscaling_target.dynamodb_table[0].service_namespace

  target_tracking_scaling_policy_configuration {
    target_value       = 70.0
    predefined_metric_specification {
      predefined_metric_type = "DynamoDBWriteCapacityUtilization"
    }
    scale_out_cooldown  = 60
    scale_in_cooldown   = 300
  }
}
