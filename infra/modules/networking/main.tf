# Networking Module - VPC, Subnets, IGW, NAT Gateway, Route Tables

# VPC
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name        = "${var.environment}-vpc"
    Environment = var.environment
    CreatedAt   = "2026-05-22"
    ManagedBy   = "Terraforms"
    Project     = "ToggleMaster" 
  }
}

# Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name        = "${var.environment}-igw"
    Environment = var.environment
    Project     = "ToggleMaster"
    ManagedBy   = "Terraforms"
    CreatedAt   = "2026-05-22"
  }
}

# Elastic IP for NAT Gateway
resource "aws_eip" "nat" {
  domain = "vpc"

  tags = {
    Name        = "${var.environment}-nat-eip"
    Environment = var.environment
    Project     = "ToggleMaster"
    ManagedBy   = "Terraforms"
    CreatedAt   = "2026-05-22"
  }

  depends_on = [aws_internet_gateway.main]
}

# NAT Gateway (in first public subnet)
resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public[0].id

  tags = {
    Name        = "${var.environment}-nat-gateway"
    Environment = var.environment
    Project     = "ToggleMaster"
    ManagedBy   = "Terraforms"
    CreatedAt   = "2026-05-22"
  }

  depends_on = [aws_internet_gateway.main]
}

# Public Subnets (for Load Balancer, NAT Gateway)
resource "aws_subnet" "public" {
  count                   = length(var.availability_zones)
  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 2, count.index)
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name                                          = "${var.environment}-public-subnet-${count.index + 1}"
    Environment                                   = var.environment
    "kubernetes.io/role/elb"                      = "1"
    "kubernetes.io/cluster/${var.cluster_name}"   = "shared"
    Project     = "ToggleMaster"
    ManagedBy   = "Terraforms"
    CreatedAt   = "2026-05-22"
  }
}

# Private Subnets (for EKS nodes, RDS, etc)
resource "aws_subnet" "private" {
  count             = length(var.availability_zones)
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 2, count.index + length(var.availability_zones))
  availability_zone = var.availability_zones[count.index]

  tags = {
    Name                                          = "${var.environment}-private-subnet-${count.index + 1}"
    Environment                                   = var.environment
    "kubernetes.io/role/internal-elb"            = "1"
    "kubernetes.io/cluster/${var.cluster_name}"  = "shared"
    Project     = "ToggleMaster"
    ManagedBy   = "Terraforms"
    CreatedAt   = "2026-05-22"
  }
}

# Route Table for Public Subnets
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block      = "0.0.0.0/0"
    gateway_id      = aws_internet_gateway.main.id
  }

  tags = {
    Name        = "${var.environment}-public-rt"
    Environment = var.environment
    Project     = "ToggleMaster"
    ManagedBy   = "Terraforms"
    CreatedAt   = "2026-05-22"
  }
}

# Route Table for Private Subnets
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main.id
  }

  tags = {
    Name        = "${var.environment}-private-rt"
    Environment = var.environment
    Project     = "ToggleMaster"
    ManagedBy   = "Terraforms"
    CreatedAt   = "2026-05-22"
  }
}

# Route Table Associations - Public
resource "aws_route_table_association" "public" {
  count          = length(var.availability_zones)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# Route Table Associations - Private
resource "aws_route_table_association" "private" {
  count          = length(var.availability_zones)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}

# Security Group for EKS Control Plane
resource "aws_security_group" "eks_control_plane" {
  name        = "${var.environment}-eks-control-plane-sg"
  description = "Security group for EKS control plane"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name        = "${var.environment}-eks-control-plane-sg"
    Environment = var.environment
    Project     = "ToggleMaster"
    ManagedBy   = "Terraforms"
    CreatedAt   = "2026-05-22"
  }
}

# Allow inbound traffic from private subnets
resource "aws_security_group_rule" "eks_ingress_private" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = [aws_subnet.private[0].cidr_block, aws_subnet.private[1].cidr_block]
  security_group_id = aws_security_group.eks_control_plane.id
}

# Allow all outbound traffic
resource "aws_security_group_rule" "eks_egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.eks_control_plane.id
}

# Security Group for RDS
resource "aws_security_group" "rds" {
  name        = "${var.environment}-rds-sg"
  description = "Security group for RDS PostgreSQL"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name        = "${var.environment}-rds-sg"
    Environment = var.environment
    Project     = "ToggleMaster"
    ManagedBy   = "Terraforms"
    CreatedAt   = "2026-05-22"
  }
}

# Security Group for ElastiCache
resource "aws_security_group" "elasticache" {
  name        = "${var.environment}-elasticache-sg"
  description = "Security group for ElastiCache Redis"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name        = "${var.environment}-elasticache-sg"
    Environment = var.environment
    Project     = "ToggleMaster"
    ManagedBy   = "Terraforms"
    CreatedAt   = "2026-05-22"
  }
}
