# GitHub Module - GitHub Actions OIDC (CI/CD)

# Create IAM Role for GitHub
resource "aws_iam_role" "github_actions" {
  name = "github-actions-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Federated = aws_iam_openid_connect_provider.github.arn
      }
      Action = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringLike = {
          "token.actions.githubusercontent.com:sub" = "repo:andre-svager/specialization-stage3:*"
        }
      }
    }]
  })

  tags = {
    Name        = "${var.environment}-github-oidc-role"
    Environment = var.environment
    Project     = "ToggleMaster"
    ManagedBy   = "Terraforms"
    CreatedAt   = "2026-05-22"
  }
}

# Create IAM OIDC provider (AWS)
resource "aws_iam_openid_connect_provider" "github" {
    url = "https://token.actions.githubusercontent.com"
    client_id_list = ["sts.amazonaws.com"]
    thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"]

  tags = {
    Name        = "${var.environment}-eks-oidc-provider"
    Environment = var.environment
    Project     = "ToggleMaster"
    ManagedBy   = "Terraforms"
    CreatedAt   = "2026-05-22"
  }
}
