#!/bin/bash

# Script to update Helm values with Terraform outputs
# Usage: ./update-helm-values.sh <path-to-terraform-outputs-file>

set -e

TERRAFORM_OUTPUTS="${1:-.}"
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}===============================================${NC}"
echo -e "${GREEN}Helm Values Update from Terraform Outputs${NC}"
echo -e "${GREEN}===============================================${NC}"

if [ "$TERRAFORM_OUTPUTS" = "." ]; then
    echo ""
    echo -e "${YELLOW}Step 1: Generate Terraform Outputs${NC}"
    echo "Run this command from the infra/ directory:"
    echo ""
    echo "  cd infra/"
    echo "  terraform output -json > terraform_outputs.json"
    echo ""
    echo "Then run this script with the path to that file:"
    echo "  ./update-helm-values.sh terraform_outputs.json"
    echo ""
    exit 1
fi

if [ ! -f "$TERRAFORM_OUTPUTS" ]; then
    echo -e "${RED}Error: File not found: $TERRAFORM_OUTPUTS${NC}"
    exit 1
fi

# Check if jq is installed
if ! command -v jq &> /dev/null; then
    echo -e "${YELLOW}jq is not installed. Installing...${NC}"
    if [ "$(uname)" = "Linux" ]; then
        sudo apt-get update && sudo apt-get install -y jq
    elif [ "$(uname)" = "Darwin" ]; then
        brew install jq
    fi
fi

# Extract values from terraform outputs
echo ""
echo -e "${GREEN}Extracting Terraform Outputs...${NC}"
echo ""

# Function to safely extract JSON value
extract_value() {
    local key=$1
    jq -r ".${key}.value // empty" "$TERRAFORM_OUTPUTS"
}

# Extract RDS endpoints
RDS_AUTH_ENDPOINT=$(extract_value "rds_auth_endpoint")
RDS_FLAG_ENDPOINT=$(extract_value "rds_flag_endpoint")
RDS_TARGET_ENDPOINT=$(extract_value "rds_target_endpoint")

# Extract Redis
REDIS_ENDPOINT=$(extract_value "redis_hostname")
REDIS_PORT=$(extract_value "redis_port")

# Extract DynamoDB
DYNAMODB_TABLE=$(extract_value "dynamodb_table_name")

# Extract SQS
SQS_QUEUE_URL=$(extract_value "evaluation_queue_url")

# Display extracted values
echo "RDS Auth Endpoint:      $RDS_AUTH_ENDPOINT"
echo "RDS Flag Endpoint:      $RDS_FLAG_ENDPOINT"
echo "RDS Target Endpoint:    $RDS_TARGET_ENDPOINT"
echo "Redis Endpoint:         $REDIS_ENDPOINT:$REDIS_PORT"
echo "DynamoDB Table:         $DYNAMODB_TABLE"
echo "SQS Queue URL:          $SQS_QUEUE_URL"
echo ""

# Verify all values are present
if [ -z "$RDS_AUTH_ENDPOINT" ] || [ -z "$RDS_FLAG_ENDPOINT" ] || [ -z "$RDS_TARGET_ENDPOINT" ] || \
   [ -z "$REDIS_ENDPOINT" ] || [ -z "$DYNAMODB_TABLE" ] || [ -z "$SQS_QUEUE_URL" ]; then
    echo -e "${RED}Error: Missing required Terraform outputs${NC}"
    echo "Make sure you ran 'terraform output -json' from infra/ directory"
    exit 1
fi

# Update Helm values files
echo -e "${GREEN}Updating Helm values files...${NC}"
echo ""

# Function to update YAML values
update_yaml() {
    local file=$1
    local key=$2
    local value=$3
    
    if [ -f "$file" ]; then
        if grep -q "host:" "$file"; then
            # Using sed to update
            sed -i.bak "s|host: .*$|host: $value|g" "$file"
            echo -e "${GREEN}✓${NC} Updated $file"
        fi
    fi
}

# Update Auth Service
AUTH_HOST=$(echo "$RDS_AUTH_ENDPOINT" | cut -d':' -f1)
sed -i.bak "s|host: .*# Auth RDS|host: $AUTH_HOST  # Auth RDS|g" gitops/helm/auth-service/values.yaml
echo -e "${GREEN}✓${NC} Updated auth-service/values.yaml"

# Update Flag Service
FLAG_HOST=$(echo "$RDS_FLAG_ENDPOINT" | cut -d':' -f1)
sed -i.bak "s|host: .*# Flag RDS|host: $FLAG_HOST  # Flag RDS|g" gitops/helm/flag-service/values.yaml
echo -e "${GREEN}✓${NC} Updated flag-service/values.yaml"

# Update Target Service
TARGET_HOST=$(echo "$RDS_TARGET_ENDPOINT" | cut -d':' -f1)
sed -i.bak "s|host: .*# Target RDS|host: $TARGET_HOST  # Target RDS|g" gitops/helm/target-service/values.yaml
echo -e "${GREEN}✓${NC} Updated target-service/values.yaml"

# Update Analytics Service (DynamoDB + SQS)
if [ -f "gitops/helm/analytics-service/values.yaml" ]; then
    sed -i.bak "s|value: \"ToggleMasterAnalytics\"|value: \"$DYNAMODB_TABLE\"|g" gitops/helm/analytics-service/values.yaml
    sed -i.bak "s|value: \"https://sqs.*evaluation-queue.fifo\"|value: \"$SQS_QUEUE_URL\"|g" gitops/helm/analytics-service/values.yaml
    echo -e "${GREEN}✓${NC} Updated analytics-service/values.yaml"
fi

# Update Evaluation Service (Redis + SQS)
if [ -f "gitops/helm/evaluation-service/values.yaml" ]; then
    sed -i.bak "s|value: \"redis://.*:6379\"|value: \"redis://$REDIS_ENDPOINT:$REDIS_PORT\"|g" gitops/helm/evaluation-service/values.yaml
    sed -i.bak "s|value: \"https://sqs.*evaluation-queue.fifo\"|value: \"$SQS_QUEUE_URL\"|g" gitops/helm/evaluation-service/values.yaml
    echo -e "${GREEN}✓${NC} Updated evaluation-service/values.yaml"
fi

# Clean up backup files
find gitops/helm -name "*.bak" -delete

echo ""
echo -e "${GREEN}===============================================${NC}"
echo -e "${GREEN}Update Complete!${NC}"
echo -e "${GREEN}===============================================${NC}"
echo ""
echo "Next steps:"
echo "1. Review the updated values files:"
echo "   git diff gitops/helm/"
echo ""
echo "2. Commit changes:"
echo "   git add gitops/helm/"
echo "   git commit -m 'Update Helm values with Terraform outputs'"
echo ""
echo "3. Deploy with ArgoCD:"
echo "   argocd app create -f gitops/apps/"
echo ""
