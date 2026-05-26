# Changes Summary - Terraform Infrastructure Consolidation

## Overview

Complete consolidation of AWS infrastructure to single staging environment with proper resource configuration matching actual microservice requirements.

## Changes Made

### 1. Terraform Database Module (`infra/modules/databases/main.tf`)

**Removed:**
- ❌ `aws_db_instance.analytics` - Analytics service uses DynamoDB, not PostgreSQL

**Modified:**
- ✅ `aws_db_instance.auth` - Corrected database name: `auth` → `auth_db`
- ✅ `aws_db_instance.flag` - Corrected database name: `flag` → `flags_db`

**Added:**
- ✅ `aws_db_instance.target` - New PostgreSQL instance for target-service (database: `targeting_db`)

**DynamoDB Configuration:**
- ✅ Corrected hash key: `id` → `event_id` (per analytics-service README requirement)
- Table naming: `staging-ToggleMasterAnalytics` (staging environment)

**Summary:**
- **Before**: 3 RDS instances (analytics, auth, flag) + 1 DynamoDB
- **After**: 3 RDS instances (auth, flag, target) + 1 DynamoDB
- All databases now correctly match service requirements

### 2. Terraform Database Outputs (`infra/modules/databases/outputs.tf`)

**Removed:**
- ❌ `output.rds_analytics_endpoint`
- ❌ `output.rds_analytics_address`
- ❌ `output.rds_analytics_port`

**Added:**
- ✅ `output.rds_target_endpoint`
- ✅ `output.rds_target_address`
- ✅ `output.rds_target_port`

### 3. Terraform Root Outputs (`infra/outputs.tf`)

**Removed:**
- ❌ `output.rds_analytics_endpoint`
- ❌ `output.rds_analytics_address`

**Added:**
- ✅ `output.rds_target_endpoint`
- ✅ `output.rds_target_address`

### 4. Messaging Module - No Changes

✅ **Already Correct** - SQS configuration already consolidated to single `evaluation-queue` with DLQ.

Previous changes (in prior session):
- Removed: main_queue, main_dlq, analytics_queue, analytics_dlq
- Kept: evaluation-queue, evaluation-dlq

### 5. Helm Chart Values Updates

All Helm charts updated to:
- ✅ Use `staging` environment (removed references to `production`)
- ✅ Point to correct RDS endpoints (placeholder values for update after terraform apply)
- ✅ Include AWS service configurations (DynamoDB, Redis, SQS)

#### Auth Service (`gitops/helm/auth-service/values.yaml`)
```yaml
env:
  - name: ENVIRONMENT
    value: "staging"  # ← Updated from "production"

database:
  name: auth_db
  host: staging-auth-db.c8k5zq8g0qxw.us-east-1.rds.amazonaws.com
```

#### Flag Service (`gitops/helm/flag-service/values.yaml`)
```yaml
env:
  - name: ENVIRONMENT
    value: "staging"  # ← Updated from "production"

database:
  name: flags_db
  host: staging-flag-db.c8k5zq8g0qxw.us-east-1.rds.amazonaws.com
```

#### Target Service (`gitops/helm/target-service/values.yaml`)
```yaml
env:
  - name: ENVIRONMENT
    value: "staging"  # ← Updated from "production"

database:
  name: targeting_db  # ← Changed from targets_db
  host: staging-target-db.c8k5zq8g0qxw.us-east-1.rds.amazonaws.com
```

#### Analytics Service (`gitops/helm/analytics-service/values.yaml`)
```yaml
env:
  - name: ENVIRONMENT
    value: "staging"  # ← Updated from "production"
  - name: DYNAMODB_TABLE_NAME
    value: "staging-ToggleMasterAnalytics"  # ← Added
  - name: SQS_QUEUE_URL
    value: "https://sqs.us-east-1.amazonaws.com/973397181776/staging-evaluation-queue.fifo"  # ← Added
```

#### Evaluation Service (`gitops/helm/evaluation-service/values.yaml`)
```yaml
env:
  - name: ENVIRONMENT
    value: "staging"  # ← Updated from "production"
  - name: REDIS_URL
    value: "redis://staging-redis.c8k5zq8g0qxw.ng.0001.use1.cache.amazonaws.com:6379"  # ← Added
  - name: SQS_QUEUE_URL
    value: "https://sqs.us-east-1.amazonaws.com/973397181776/staging-evaluation-queue.fifo"  # ← Added
```

### 6. Infrastructure Documentation Updates

#### `infra/README.md`
- Updated RDS section: "3 instances (analytics, auth, flag)" → "3 instances (auth, flag, target)"
- Updated SQS section: "3 filas SQS (main, analytics, evaluation)" → "1 fila SQS FIFO (evaluation)"
- Removed plan step references to "analytics" database
- Updated messaging review to reflect single evaluation queue

#### New File: `gitops/TERRAFORM_UPDATE_GUIDE.md`
Complete guide for:
- Capturing Terraform outputs
- Updating Helm values with actual AWS resource endpoints
- Database initialization scripts
- IAM and IRSA configuration
- Validation and troubleshooting procedures

## Service Resource Requirements (Verified)

| Service | Requirement | Resource | Status |
|---------|-------------|----------|--------|
| auth-service | Database | RDS (auth_db) | ✅ Configured |
| flag-service | Database | RDS (flags_db) | ✅ Configured |
| target-service | Database | RDS (targeting_db) | ✅ Configured |
| analytics-service | Data Store | DynamoDB (staging-ToggleMasterAnalytics) | ✅ Configured |
| analytics-service | Message Queue | SQS (evaluation-queue) | ✅ Configured |
| evaluation-service | Cache | ElastiCache Redis | ✅ Configured |
| evaluation-service | Message Queue | SQS (evaluation-queue) | ✅ Configured |

## Environment Consolidation

**Previous State:**
- Multiple environment definitions (main, staging, production)
- Analytics service hardcoded to PostgreSQL
- Mismatched database names
- Missing target-service database

**Current State:**
- ✅ Staging as primary environment in Terraform
- ✅ Variables default to staging
- ✅ All Helm charts configured for staging
- ✅ All services have correct AWS resource configurations
- ✅ Single SQS queue for event flow (evaluation → analytics)

## Next Steps

1. **Run Terraform Plan:**
   ```bash
   cd infra/
   terraform plan -out=tfplan
   ```

2. **Review Resources:**
   - 3 RDS instances (auth, flag, target)
   - 1 Redis cluster
   - 1 DynamoDB table
   - 1 FIFO SQS queue + DLQ
   - 5 ECR repositories
   - VPC, EKS cluster, security groups

3. **Apply Infrastructure:**
   ```bash
   terraform apply tfplan
   ```

4. **Capture Outputs:**
   ```bash
   terraform output > terraform_outputs.txt
   ```

5. **Update Helm Values:**
   Use actual RDS/Redis endpoints from Terraform outputs
   Reference: `gitops/TERRAFORM_UPDATE_GUIDE.md`

6. **Deploy with ArgoCD:**
   ```bash
   cd gitops/argocd/
   ./install.sh
   argocd app create -f apps/
   ```

## Validation Checklist

- [ ] Terraform plan shows correct resources
- [ ] No "analytics" RDS instance in plan
- [ ] "target" RDS instance present in plan
- [ ] DynamoDB table with "event_id" partition key
- [ ] Single evaluation-queue (no main/analytics queues)
- [ ] All Helm values reference staging environment
- [ ] Terraform apply completes successfully
- [ ] All AWS resources provisioned correctly
- [ ] Services can connect to respective databases/caches/queues
- [ ] ArgoCD applications sync successfully
- [ ] All pods are running (2 replicas per service in staging)

## Files Modified

```
infra/
├── modules/
│   └── databases/
│       ├── main.tf                    # ← Modified
│       └── outputs.tf                 # ← Modified
├── outputs.tf                         # ← Modified
└── README.md                          # ← Modified

gitops/
├── TERRAFORM_UPDATE_GUIDE.md          # ← New File
├── helm/
│   ├── auth-service/values.yaml       # ← Modified
│   ├── flag-service/values.yaml       # ← Modified
│   ├── target-service/values.yaml     # ← Modified
│   ├── analytics-service/values.yaml  # ← Modified
│   └── evaluation-service/values.yaml # ← Modified
```

## Summary Statistics

- **Files Modified:** 8
- **Files Created:** 1
- **Terraform Resources Changed:** 
  - RDS: 1 removed, 1 added (net: -1 analytics, +1 target)
  - Database names corrected: 2 (auth, flag)
  - DynamoDB key corrected: 1
- **Helm Charts Updated:** 5 (environment + AWS configs)
- **Database Instances:** 3 (correct count)
- **Total AWS Resources:** 1 VPC, 1 EKS, 3 RDS, 1 Redis, 1 DynamoDB, 1 SQS queue, 5 ECR repos
