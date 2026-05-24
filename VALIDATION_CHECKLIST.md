# Infrastructure Validation Checklist

## Pre-Terraform Validation

### Terraform Configuration Files ✅

- [x] `infra/modules/databases/main.tf`
  - [x] Removed: `aws_db_instance.analytics`
  - [x] Corrected: `aws_db_instance.auth` (database: `auth_db`)
  - [x] Corrected: `aws_db_instance.flag` (database: `flags_db`)
  - [x] Added: `aws_db_instance.target` (database: `targeting_db`)
  - [x] Fixed DynamoDB: hash_key = "event_id" (was: "id")

- [x] `infra/modules/databases/outputs.tf`
  - [x] Removed analytics outputs
  - [x] Added target outputs

- [x] `infra/outputs.tf`
  - [x] Removed analytics RDS references
  - [x] Added target RDS references

- [x] `infra/README.md`
  - [x] Updated RDS documentation (3 instances: auth, flag, target)
  - [x] Updated SQS documentation (single evaluation queue)

### Helm Chart Values ✅

- [x] `gitops/helm/auth-service/values.yaml`
  - [x] Environment: production → staging
  - [x] Database: auth_db
  - [x] Host: staging-auth-db endpoint

- [x] `gitops/helm/flag-service/values.yaml`
  - [x] Environment: production → staging
  - [x] Database: flags_db
  - [x] Host: staging-flag-db endpoint

- [x] `gitops/helm/target-service/values.yaml`
  - [x] Environment: production → staging
  - [x] Database: targeting_db (corrected from targets_db)
  - [x] Host: staging-target-db endpoint

- [x] `gitops/helm/analytics-service/values.yaml`
  - [x] Environment: production → staging
  - [x] Added: DYNAMODB_TABLE_NAME
  - [x] Added: SQS_QUEUE_URL

- [x] `gitops/helm/evaluation-service/values.yaml`
  - [x] Environment: production → staging
  - [x] Added: REDIS_URL
  - [x] Added: SQS_QUEUE_URL

### Documentation ✅

- [x] `TERRAFORM_CHANGES.md` - Complete summary of all changes
- [x] `gitops/TERRAFORM_UPDATE_GUIDE.md` - Integration guide
- [x] `gitops/update-helm-values.sh` - Automated update script

## Terraform Plan Validation

Run these commands to validate:

```bash
cd infra/

# Validate syntax
terraform validate

# Check the plan
terraform plan -out=tfplan

# Verify expected resources
terraform show tfplan | grep -E "(aws_db_instance|aws_dynamodb_table|aws_elasticache|aws_sqs_queue|aws_ecr)"
```

### Expected Resources in Plan:

**RDS (Should be 3, NOT 4):**
- [ ] `aws_db_instance.auth` (database: auth_db)
- [ ] `aws_db_instance.flag` (database: flags_db)
- [ ] `aws_db_instance.target` (database: targeting_db)
- [ ] ✗ NO `aws_db_instance.analytics` (removed - should NOT appear)

**DynamoDB:**
- [ ] `aws_dynamodb_table.toggle_master_analytics`
  - Hash key: event_id
  - Table name: staging-ToggleMasterAnalytics

**ElastiCache:**
- [ ] `aws_elasticache_cluster.redis`
  - Cluster ID: staging-redis

**SQS (Should be 2 per queue: queue + DLQ):**
- [ ] `aws_sqs_queue.evaluation` (staging-evaluation-queue.fifo)
- [ ] `aws_sqs_queue.evaluation_dlq` (staging-evaluation-queue-dlq.fifo)
- [ ] ✗ NO `main_queue` (removed)
- [ ] ✗ NO `analytics_queue` (removed)

**ECR:**
- [ ] 5 repositories (auth, flag, target, analytics, evaluation)

## Terraform Apply Validation

After running `terraform apply`:

```bash
# Get all outputs
terraform output

# Specifically check:
terraform output rds_auth_endpoint
terraform output rds_flag_endpoint
terraform output rds_target_endpoint
terraform output redis_endpoint
terraform output dynamodb_table_name
terraform output evaluation_queue_url
```

### Expected Outputs:

- [x] `rds_auth_endpoint` - Contains "auth-db"
- [x] `rds_flag_endpoint` - Contains "flag-db"
- [x] `rds_target_endpoint` - Contains "target-db"
- [x] ✗ NO `rds_analytics_endpoint`
- [x] `redis_endpoint` - Contains "redis"
- [x] `dynamodb_table_name` - "staging-ToggleMasterAnalytics"
- [x] `evaluation_queue_url` - SQS queue URL with "evaluation-queue.fifo"

## AWS Console Validation

### RDS Dashboard

- [ ] 3 Database instances:
  - [ ] staging-auth-db
    - Database name: auth_db
    - Engine: PostgreSQL 13
  - [ ] staging-flag-db
    - Database name: flags_db
    - Engine: PostgreSQL 13
  - [ ] staging-target-db
    - Database name: targeting_db
    - Engine: PostgreSQL 13
- [ ] ✗ NO staging-analytics-db

### DynamoDB Console

- [ ] Table: staging-ToggleMasterAnalytics
  - [ ] Partition key: event_id (String)
  - [ ] Billing mode: PAY_PER_REQUEST
  - [ ] Encryption: Enabled

### ElastiCache Console

- [ ] Cluster: staging-redis
  - [ ] Engine: redis
  - [ ] Version: 7.0
  - [ ] Node type: cache.t3.micro

### SQS Console

- [ ] Queue: staging-evaluation-queue.fifo
  - [ ] Type: FIFO
  - [ ] Visibility timeout: 300s
- [ ] Queue: staging-evaluation-queue-dlq.fifo
  - [ ] Type: FIFO
- [ ] ✗ NO main_queue
- [ ] ✗ NO main_dlq
- [ ] ✗ NO analytics_queue
- [ ] ✗ NO analytics_dlq

### ECR Console

- [ ] 5 repositories:
  - [ ] auth-service
  - [ ] flag-service
  - [ ] target-service
  - [ ] analytics-service
  - [ ] evaluation-service

## Database Initialization

After RDS instances are created:

```bash
# Get credentials and endpoints from terraform output
RDS_AUTH_HOST=$(terraform output -raw rds_auth_address)
RDS_FLAG_HOST=$(terraform output -raw rds_flag_address)
RDS_TARGET_HOST=$(terraform output -raw rds_target_address)

# Initialize databases
psql -h $RDS_AUTH_HOST -U postgres -d auth_db -f ../../auth-service/db/init.sql
psql -h $RDS_FLAG_HOST -U postgres -d flags_db -f ../../flag-service/db/init.sql
psql -h $RDS_TARGET_HOST -U postgres -d targeting_db -f ../../target-service/db/init.sql

# Verify tables were created
psql -h $RDS_AUTH_HOST -U postgres -d auth_db -c "\dt"  # Should show api_keys table
psql -h $RDS_FLAG_HOST -U postgres -d flags_db -c "\dt" # Should show flags table
psql -h $RDS_TARGET_HOST -U postgres -d targeting_db -c "\dt" # Should show targeting_rules table
```

## Helm Values Update

```bash
# Generate terraform outputs
cd infra/
terraform output -json > terraform_outputs.json

# Update Helm values with actual endpoints
cd ../gitops/
./update-helm-values.sh ../infra/terraform_outputs.json

# Verify updates
git diff helm/
```

### Verification Points:

- [ ] Auth service values show correct RDS host (auth-db)
- [ ] Flag service values show correct RDS host (flag-db)
- [ ] Target service values show correct RDS host (target-db)
- [ ] Analytics service has DYNAMODB_TABLE_NAME and SQS_QUEUE_URL
- [ ] Evaluation service has REDIS_URL and SQS_QUEUE_URL
- [ ] All services have ENVIRONMENT=staging
- [ ] No "production" references remain

## Kubernetes Deployment

```bash
# Apply Kubernetes secrets for RDS
kubectl create secret generic rds-credentials \
  --from-literal=username=postgres \
  --from-literal=password=YOUR_PASSWORD \
  -n default

# Install ArgoCD (if not already done)
cd gitops/argocd/
./install.sh

# Create ArgoCD applications
argocd app create -f ../apps/

# Verify sync
argocd app get analytics-app
argocd app get auth-app
argocd app get evaluation-app
argocd app get flag-app
argocd app get target-app
```

### Pod Validation:

```bash
# Check all pods are running
kubectl get pods -A

# Verify service connectivity
kubectl logs -f deployment/analytics-app -c analytics-service
kubectl logs -f deployment/auth-app -c auth-service
kubectl logs -f deployment/flag-app -c flag-service
kubectl logs -f deployment/target-app -c target-service
kubectl logs -f deployment/evaluation-app -c evaluation-service

# Test database connectivity
kubectl exec -it deployment/auth-app -- psql -h $RDS_AUTH_HOST -U postgres -d auth_db -c "SELECT 1;"
```

## Summary Checklist

**Pre-Apply:**
- [x] Terraform files corrected
- [x] Helm values updated
- [x] Database names standardized
- [x] DynamoDB key fixed
- [x] SQS consolidated

**Post-Apply:**
- [ ] terraform plan shows correct resources
- [ ] terraform apply succeeds
- [ ] AWS resources exist with correct names
- [ ] Helm values have actual endpoints
- [ ] RDS databases initialized
- [ ] ArgoCD applications sync successfully
- [ ] All pods running with 2 replicas (staging)
- [ ] Services can connect to databases/caches/queues

## Troubleshooting

### If Terraform Plan Shows Wrong Resources:

1. Verify infra/modules/databases/main.tf:
   - Check that analytics RDS is removed
   - Check that target RDS exists
   - Check DynamoDB hash_key is "event_id"

2. Verify outputs.tf:
   - Check no analytics references
   - Check target references exist

### If Helm Update Script Fails:

1. Verify terraform output format:
   ```bash
   cd infra/
   terraform output -json | jq '.rds_auth_endpoint'
   ```

2. Check Helm file paths:
   ```bash
   ls -la gitops/helm/*/values.yaml
   ```

3. Run script with debug:
   ```bash
   bash -x gitops/update-helm-values.sh terraform_outputs.json
   ```

### If Pods Don't Start:

1. Check environment variables:
   ```bash
   kubectl env pod <pod-name>
   ```

2. Check database connectivity:
   ```bash
   kubectl exec -it <pod-name> -- env | grep DATABASE
   kubectl exec -it <pod-name> -- env | grep REDIS
   kubectl exec -it <pod-name> -- env | grep SQS
   ```

3. Check pod logs:
   ```bash
   kubectl logs <pod-name>
   ```
