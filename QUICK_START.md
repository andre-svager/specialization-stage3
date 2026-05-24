# Quick Start Guide - Terraform Infrastructure

## Overview

Your infrastructure is now properly configured to match actual service requirements:
- 3 RDS PostgreSQL instances (auth, flag, target services)
- 1 DynamoDB table (analytics service)
- 1 Redis cluster (evaluation service)
- 1 SQS FIFO queue (analytics + evaluation services)

All configured for **staging environment only**.

## Step 1: Validate Configuration (2 minutes)

```bash
cd infra/

# Verify Terraform syntax
terraform validate

# See what will be created (review for ~5 minutes)
terraform plan
```

**Expected in plan:**
- ✅ 3 RDS instances: auth-db, flag-db, target-db
- ✅ 1 DynamoDB table: staging-ToggleMasterAnalytics
- ✅ 1 Redis cluster: staging-redis
- ✅ 1 SQS queue: staging-evaluation-queue.fifo
- ❌ NO analytics-db, main_queue, or analytics_queue

## Step 2: Provision Infrastructure (30-45 minutes)

```bash
# Create the plan file
terraform plan -out=tfplan

# Apply infrastructure
terraform apply tfplan

# This will create:
# - VPC and networking (5 min)
# - EKS cluster (15-20 min)
# - RDS databases (10-15 min)
# - ElastiCache Redis (5 min)
# - DynamoDB table (1 min)
# - SQS queues (1 min)
# - ECR repositories (1 min)
```

## Step 3: Save Terraform Outputs (1 minute)

```bash
# Generate outputs file
terraform output -json > terraform_outputs.json

# You should see outputs like:
# - rds_auth_endpoint
# - rds_flag_endpoint
# - rds_target_endpoint
# - redis_endpoint
# - dynamodb_table_name
# - evaluation_queue_url

# Save this file safely - you'll need it to update Helm
cat terraform_outputs.json
```

## Step 4: Update Helm Values with Real Endpoints (1 minute)

```bash
# Go to GitOps directory
cd ../gitops/

# Run the update script (make it executable first)
chmod +x update-helm-values.sh
./update-helm-values.sh ../infra/terraform_outputs.json

# This will automatically update all Helm values.yaml files with:
# - RDS endpoints for auth, flag, target services
# - DynamoDB table name for analytics service
# - Redis endpoint for evaluation service
# - SQS queue URL for analytics and evaluation services
```

## Step 5: Configure Kubernetes

```bash
# Update kubeconfig to connect to your EKS cluster
aws eks update-kubeconfig --name fiap-stage3-eks --region us-east-1

# Verify connection
kubectl get nodes

# Create RDS credentials secret
kubectl create secret generic rds-credentials \
  --from-literal=username=postgres \
  --from-literal=password=YOUR_RDS_PASSWORD \
  -n default

# Where YOUR_RDS_PASSWORD is the value from terraform.tfvars (rds_password)
```

## Step 6: Initialize Databases

```bash
# Get RDS endpoints from terraform output
export RDS_AUTH_HOST=$(terraform output -raw rds_auth_address)
export RDS_FLAG_HOST=$(terraform output -raw rds_flag_address)
export RDS_TARGET_HOST=$(terraform output -raw rds_target_address)

# Create tables by running init scripts
# From the root of your project:

psql -h $RDS_AUTH_HOST -U postgres -d auth_db \
  -f auth-service/db/init.sql

psql -h $RDS_FLAG_HOST -U postgres -d flags_db \
  -f flag-service/db/init.sql

psql -h $RDS_TARGET_HOST -U postgres -d targeting_db \
  -f target-service/db/init.sql
```

## Step 7: Deploy with GitOps/ArgoCD

```bash
# Go to ArgoCD directory
cd gitops/argocd/

# Install ArgoCD
./install.sh

# Go to apps directory
cd ../apps/

# Create ArgoCD applications
kubectl apply -f .

# Or use argocd CLI:
# argocd app create analytics-app -f analytics-app.yaml
# argocd app create auth-app -f auth-app.yaml
# argocd app create evaluation-app -f evaluation-app.yaml
# argocd app create flag-app -f flag-app.yaml
# argocd app create target-app -f target-app.yaml
```

## Step 8: Monitor Deployment

```bash
# Watch pods being created
kubectl get pods -w

# Check ArgoCD applications sync status
argocd app list
argocd app status analytics-app
argocd app status auth-app
argocd app status evaluation-app
argocd app status flag-app
argocd app status target-app

# View logs from services
kubectl logs -f deployment/analytics-app
kubectl logs -f deployment/auth-app
kubectl logs -f deployment/flag-app
kubectl logs -f deployment/target-app
kubectl logs -f deployment/evaluation-app
```

## What Changed from Previous Configuration

### Database Configuration
| Service | Before | After |
|---------|--------|-------|
| auth | RDS analytics | RDS auth_db ✅ |
| flag | RDS flag | RDS flags_db ✅ |
| target | Missing | RDS targeting_db ✅ |
| analytics | RDS analytics | DynamoDB ✅ |

### Message Queues
- **Before**: main_queue, analytics_queue, evaluation_queue
- **After**: Only evaluation_queue (consolidated) ✅

### Environment
- **Before**: production (hardcoded in Helm)
- **After**: staging (environment variable) ✅

### DynamoDB
- **Before**: Partition key = id
- **After**: Partition key = event_id ✅

## File Structure

```
/home/andresv/dev/git/fiap/stage3/
├── TERRAFORM_CHANGES.md           ← What changed
├── VALIDATION_CHECKLIST.md        ← Detailed validation steps
├── infra/
│   ├── modules/databases/main.tf  ← 3 RDS + Redis + DynamoDB
│   ├── outputs.tf                 ← Updated outputs
│   └── README.md                  ← Updated documentation
└── gitops/
    ├── TERRAFORM_UPDATE_GUIDE.md  ← Integration guide
    ├── update-helm-values.sh      ← Automated script
    └── helm/
        ├── auth-service/values.yaml       ← Updated endpoints
        ├── flag-service/values.yaml       ← Updated endpoints
        ├── target-service/values.yaml     ← Updated endpoints
        ├── analytics-service/values.yaml  ← DynamoDB + SQS
        └── evaluation-service/values.yaml ← Redis + SQS
```

## Troubleshooting

### Terraform Issues
- See: `infra/README.md` Troubleshooting section
- Run: `terraform validate` to check syntax
- View: `terraform plan` to see all changes

### Helm/Kubernetes Issues
- See: `gitops/README.md` Troubleshooting section
- Check: `kubectl describe pod <pod-name>`
- Check: `kubectl logs <pod-name>`

### Database Connection Issues
- Verify RDS credentials in `terraform.tfvars`
- Check security groups allow traffic from EKS nodes
- Run database init scripts as documented in Step 6

## Important Notes

1. **Keep terraform_outputs.json safe** - Don't commit to git (contains endpoints)
2. **Update .gitignore** to exclude terraform state and outputs
3. **Use strong RDS password** - Change "ChangeMe!Secure123" in terraform.tfvars
4. **Staging resources only** - No production environment configured
5. **Database initialization required** - Must run init.sql scripts after RDS creation

## Next Steps

1. ✅ Review changes made: `TERRAFORM_CHANGES.md`
2. ✅ Run terraform plan to validate: `terraform plan`
3. ⬜ Apply infrastructure: `terraform apply`
4. ⬜ Update Helm with endpoints: `update-helm-values.sh`
5. ⬜ Initialize databases: Run init.sql scripts
6. ⬜ Deploy with ArgoCD: `kubectl apply -f gitops/apps/`
7. ⬜ Verify all services are running: `kubectl get pods`

## Questions?

- **Terraform details**: See `infra/README.md`
- **GitOps details**: See `gitops/README.md`
- **Integration steps**: See `gitops/TERRAFORM_UPDATE_GUIDE.md`
- **Validation**: See `VALIDATION_CHECKLIST.md`
- **What changed**: See `TERRAFORM_CHANGES.md`
