# Terraform Output Integration Guide

## Overview

This guide explains how to integrate AWS resources provisioned by Terraform into the Helm charts and GitOps deployment.

## Terraform Infrastructure

After running `terraform apply`, the following AWS resources will be provisioned:

### 1. RDS PostgreSQL Databases

Three separate PostgreSQL instances for staging environment:
- **Auth Service**: `staging-auth-db` (database: `auth_db`)
- **Flag Service**: `staging-flag-db` (database: `flags_db`)
- **Target Service**: `staging-target-db` (database: `targeting_db`)

**Terraform Outputs:**
```
rds_auth_endpoint = staging-auth-db.<random>.us-east-1.rds.amazonaws.com:5432
rds_flag_endpoint = staging-flag-db.<random>.us-east-1.rds.amazonaws.com:5432
rds_target_endpoint = staging-target-db.<random>.us-east-1.rds.amazonaws.com:5432
```

### 2. ElastiCache Redis

Single Redis cluster for evaluation service:
- **Endpoint**: `staging-redis` (port: 6379)

**Terraform Outputs:**
```
redis_endpoint = staging-redis.<random>.ng.0001.use1.cache.amazonaws.com
redis_port = 6379
```

### 3. DynamoDB Table

Single DynamoDB table for analytics service:
- **Table Name**: `staging-ToggleMasterAnalytics`
- **Primary Key**: `event_id` (String)
- **Billing Mode**: PAY_PER_REQUEST

**Terraform Output:**
```
dynamodb_table_name = staging-ToggleMasterAnalytics
dynamodb_table_arn = arn:aws:dynamodb:us-east-1:973397181776:table/staging-ToggleMasterAnalytics
```

### 4. SQS Queue

Single FIFO SQS queue and Dead Letter Queue:
- **Queue**: `staging-evaluation-queue.fifo`
- **DLQ**: `staging-evaluation-queue-dlq.fifo`

**Terraform Output:**
```
evaluation_queue_url = https://sqs.us-east-1.amazonaws.com/973397181776/staging-evaluation-queue.fifo
evaluation_queue_arn = arn:aws:sqs:us-east-1:973397181776:staging-evaluation-queue.fifo
```

## Updating Helm Values with Terraform Outputs

### Step 1: Run Terraform

```bash
cd infra/
terraform plan -out=tfplan
terraform apply tfplan
```

### Step 2: Capture Terraform Outputs

```bash
# Save all outputs for reference
terraform output > terraform_outputs.txt

# Or get specific outputs
terraform output rds_auth_endpoint
terraform output rds_flag_endpoint
terraform output rds_target_endpoint
terraform output redis_endpoint
terraform output dynamodb_table_name
terraform output evaluation_queue_url
```

### Step 3: Update Helm Chart Values

Update the following files in `gitops/helm/*/values.yaml`:

#### Auth Service
```yaml
# File: gitops/helm/auth-service/values.yaml
database:
  host: <rds_auth_endpoint-hostname>  # e.g., staging-auth-db.xxxxx.us-east-1.rds.amazonaws.com
  port: 5432
  name: auth_db
  user: postgres
```

#### Flag Service
```yaml
# File: gitops/helm/flag-service/values.yaml
database:
  host: <rds_flag_endpoint-hostname>  # e.g., staging-flag-db.xxxxx.us-east-1.rds.amazonaws.com
  port: 5432
  name: flags_db
  user: postgres
```

#### Target Service
```yaml
# File: gitops/helm/target-service/values.yaml
database:
  host: <rds_target_endpoint-hostname>  # e.g., staging-target-db.xxxxx.us-east-1.rds.amazonaws.com
  port: 5432
  name: targeting_db
  user: postgres
```

#### Analytics Service
```yaml
# File: gitops/helm/analytics-service/values.yaml
env:
  - name: DYNAMODB_TABLE_NAME
    value: "<dynamodb_table_name>"  # e.g., staging-ToggleMasterAnalytics
  - name: SQS_QUEUE_URL
    value: "<evaluation_queue_url>"  # e.g., https://sqs.us-east-1.amazonaws.com/xxx/staging-evaluation-queue.fifo
```

#### Evaluation Service
```yaml
# File: gitops/helm/evaluation-service/values.yaml
env:
  - name: REDIS_URL
    value: "redis://<redis_endpoint>:6379"  # e.g., redis://staging-redis.xxxxx.ng.0001.use1.cache.amazonaws.com:6379
  - name: SQS_QUEUE_URL
    value: "<evaluation_queue_url>"  # e.g., https://sqs.us-east-1.amazonaws.com/xxx/staging-evaluation-queue.fifo
```

### Step 4: Update Database Credentials

All services use the same PostgreSQL credentials (from Terraform variables):
- **Username**: `postgres`
- **Password**: As configured in `terraform.tfvars` (rds_password variable)

Update the Kubernetes secrets:

```bash
# Create secret for RDS credentials
kubectl create secret generic rds-credentials \
  --from-literal=username=postgres \
  --from-literal=password=<your-rds-password> \
  -n default

# Update secret in helm values or create ConfigMap with endpoints
```

### Step 5: Sync GitOps with ArgoCD

```bash
# Deploy ArgoCD Applications
argocd app create analytics-app \
  --repo https://github.com/<your-repo> \
  --path gitops/apps \
  --dest-server https://kubernetes.default.svc \
  --dest-namespace default

# Or use the existing Application manifests
kubectl apply -f gitops/apps/
```

## Database Initialization

After resources are provisioned:

```bash
# Connect to each RDS instance and run init scripts
# Auth Service
psql -h <auth-db-host> -U postgres -d auth_db -f auth-service/db/init.sql

# Flag Service
psql -h <flag-db-host> -U postgres -d flags_db -f flag-service/db/init.sql

# Target Service
psql -h <target-db-host> -U postgres -d targeting_db -f target-service/db/init.sql
```

## Service Account and IAM Configuration

For proper AWS service access, ensure:

1. **EKS Cluster**: Running with IRSA (IAM Roles for Service Accounts) enabled
2. **Service Accounts**: Created with proper IAM annotations
3. **IAM Policies**: Services have permissions for:
   - DynamoDB: analytics-service (GetItem, PutItem, Scan)
   - SQS: analytics-service and evaluation-service (ReceiveMessage, DeleteMessage)
   - Redis: evaluation-service (Connect)
   - RDS: All services (database connections)

## Validation

After deployment:

```bash
# Check service health
kubectl get pods -n default
kubectl logs <pod-name>

# Verify database connectivity
kubectl exec -it <auth-service-pod> -- psql -h <rds-host> -U postgres -d auth_db -c "SELECT 1;"

# Verify SQS access
kubectl exec -it <evaluation-service-pod> -- aws sqs get-queue-attributes \
  --queue-url <sqs-queue-url> --attribute-names All

# Verify DynamoDB access
kubectl exec -it <analytics-service-pod> -- aws dynamodb describe-table \
  --table-name staging-ToggleMasterAnalytics
```

## Troubleshooting

### Database Connection Issues

1. **Check Security Groups**: Ensure RDS security groups allow inbound traffic from EKS nodes
2. **Check Network**: Verify VPC and subnet configuration
3. **Check Credentials**: Verify username/password in Kubernetes secrets

### AWS Service Access Issues

1. **Check IAM Roles**: Verify IRSA service accounts have correct permissions
2. **Check Endpoints**: Verify services have correct endpoint URLs
3. **Check Regional Configuration**: All resources must be in same region (us-east-1)

### ArgoCD Sync Issues

1. **Check Git Credentials**: Ensure ArgoCD can access the Git repository
2. **Check YAML**: Run `kubectl validate` on manifests
3. **Check Resources**: Use `argocd app info <app-name>` for status
