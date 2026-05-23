# Networking Module
module "networking" {
  source = "./modules/networking"

  environment  = var.environment
  vpc_cidr     = var.vpc_cidr
  cluster_name = var.cluster_name
  availability_zones = var.availability_zones
}

# EKS Module
module "eks" {
  source = "./modules/eks"

  environment                   = var.environment
  cluster_name                  = var.cluster_name
  kubernetes_version            = var.kubernetes_version
  instance_type                 = var.node_instance_type
  desired_size                  = var.node_desired_size
  min_size                      = var.node_min_size
  max_size                      = var.node_max_size
  public_subnet_ids             = module.networking.public_subnet_ids
  private_subnet_ids            = module.networking.private_subnet_ids
  eks_security_group_id         = module.networking.eks_control_plane_security_group_id
  rds_security_group_id         = module.networking.rds_security_group_id
  elasticache_security_group_id = module.networking.elasticache_security_group_id

  depends_on = [module.networking]
}

# Databases Module
module "databases" {
  source = "./modules/databases"

  environment                   = var.environment
  private_subnet_ids            = module.networking.private_subnet_ids
  rds_security_group_id         = module.networking.rds_security_group_id
  elasticache_security_group_id = module.networking.elasticache_security_group_id

  # RDS Configuration
  postgres_version        = var.postgres_version
  rds_instance_class      = var.rds_instance_class
  rds_allocated_storage   = var.rds_allocated_storage
  rds_username            = var.rds_username
  rds_password            = var.rds_password
  multi_az                = var.rds_multi_az
  backup_retention_days   = var.rds_backup_retention_days

  # ElastiCache Configuration
  redis_version    = var.redis_version
  redis_node_type  = var.redis_node_type
  redis_num_nodes  = var.redis_num_nodes

  # DynamoDB Configuration
  dynamodb_billing_mode  = var.dynamodb_billing_mode
  dynamodb_min_capacity  = var.dynamodb_min_capacity
  dynamodb_max_capacity  = var.dynamodb_max_capacity

  depends_on = [module.networking]
}

# Messaging Module
module "messaging" {
  source = "./modules/messaging"

  environment         = var.environment
  use_fifo_queue      = var.use_fifo_queues
  visibility_timeout  = var.sqs_visibility_timeout
  message_retention_period = var.sqs_message_retention_period
  receive_wait_time   = var.sqs_receive_wait_time
}

# ECR Module
module "ecr" {
  source = "./modules/ecr"

  environment           = var.environment
  images_to_keep        = var.ecr_images_to_keep
  eks_cluster_role_arn  = module.eks.cluster_id

  depends_on = [module.eks]
}
