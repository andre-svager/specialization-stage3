# Guia de Deployment - Passo a Passo

Este arquivo fornece um guia detalhado, passo-a-passo, para deployar a infraestrutura.

## ✅ Fase 1: Preparação

### 1.1 Verificar Pré-requisitos

```bash
# Verificar Terraform
terraform version
# Esperado: >= 1.5

# Verificar AWS CLI
aws --version

# Verificar credenciais AWS
aws sts get-caller-identity
```

### 1.2 Configurar Variáveis

```bash
cd infra/
cp terraform.tfvars.example terraform.tfvars

# Editar terraform.tfvars
# IMPORTANTE: Mudar as senhas padrão!
nano terraform.tfvars  # ou use seu editor preferido
```

**Variáveis críticas a alterar:**

```hcl
# terraform.tfvars
environment = "staging"  # ou "production"
cluster_name = "fiap-stage3-eks"

# ⚠️ MUDAR ESTAS SENHAS!
rds_username = "postgres"
rds_password = "SenhaSegura123!@"  # Mude isto!
```

### 1.3 Inicializar Terraform

```bash
terraform init

# Output esperado:
# Terraform has been successfully configured for this working directory.
```

### 1.4 Validar Configuração

```bash
terraform validate

# Output esperado:
# Success! The configuration is valid.
```

## 📦 Fase 2: Deployment Modular

### ⚠️ IMPORTANTE: Testar cada módulo antes de aplicar

### 2.1 Deploying Networking (VPC, Subnets, IGW)

**Tempo esperado:** ~5-10 minutos

#### Step 1: Plan

```bash
terraform plan -target=module.networking -out=tfplan_networking
```

**Revise o output:**
- Deve criar: VPC, 2 subnets públicas, 2 subnets privadas, IGW, NAT Gateway, Route Tables, Security Groups
- Número de recursos: ~10-12

#### Step 2: Apply

```bash
terraform apply tfplan_networking

# Aguarde até ver:
# Apply complete! Resources: X added, 0 changed, 0 destroyed.
```

#### Step 3: Verificar

```bash
# Verificar VPC criada
aws ec2 describe-vpcs --filters Name=tag:Name,Values=staging-vpc --query 'Vpcs[0].VpcId' --output text

# Verificar subnets
aws ec2 describe-subnets --filters Name=tag:Name,Values=staging-public-subnet-1 --query 'Subnets[0].SubnetId' --output text
```

---

### 2.2 Deploying EKS (Kubernetes Cluster)

**Tempo esperado:** ~15-25 minutos

#### Step 1: Plan

```bash
terraform plan -target=module.eks -out=tfplan_eks
```

**Revise o output:**
- Deve criar: IAM roles, EKS cluster, node group, OIDC provider
- Número de recursos: ~15-20

#### Step 2: Apply

```bash
terraform apply tfplan_eks

# Aguarde até ver:
# Apply complete! Resources: X added, 0 changed, 0 destroyed.

# ⏳ Isto pode levar 15-20 minutos (criação do cluster + node group)
```

**Monitorar progresso:**

```bash
# Em outro terminal, verificar status do cluster
aws eks describe-cluster --name fiap-stage3-eks --region us-east-1 --query 'cluster.status'

# Esperado: ACTIVE (após conclusão)

# Verificar nodes
aws eks describe-nodegroup --cluster-name fiap-stage3-eks --nodegroup-name staging-node-group --region us-east-1 --query 'nodegroup.status'

# Esperado: ACTIVE
```

#### Step 3: Verificar

```bash
# Atualizar kubeconfig
aws eks update-kubeconfig --name fiap-stage3-eks --region us-east-1

# Verificar conexão
kubectl get nodes

# Output esperado:
# NAME                           STATUS   ROLES    AGE   VERSION
# ip-10-1-x-x.ec2.internal       Ready    <none>   1m    v1.29.x
# ip-10-1-x-x.ec2.internal       Ready    <none>   1m    v1.29.x
```

---

### 2.3 Deploying Databases (RDS, Redis, DynamoDB)

**Tempo esperado:** ~15-20 minutos

#### Step 1: Plan

```bash
terraform plan -target=module.databases -out=tfplan_databases
```

**Revise o output:**
- Deve criar: 3 instâncias RDS, ElastiCache cluster, DynamoDB table, security groups, subnet groups
- Número de recursos: ~15-18

#### Step 2: Apply

```bash
terraform apply tfplan_databases

# Aguarde até ver:
# Apply complete! Resources: X added, 0 changed, 0 destroyed.

# ⏳ Isto pode levar 15-20 minutos (RDS é lento)
```

**Monitorar progresso:**

```bash
# Em outro terminal, verificar status RDS
aws rds describe-db-instances --db-instance-identifier staging-analytics-db --region us-east-1 --query 'DBInstances[0].DBInstanceStatus'

# Esperado: available (após conclusão)

# Verificar ElastiCache
aws elasticache describe-cache-clusters --cache-cluster-id staging-redis --region us-east-1 --show-cache-node-info --query 'CacheClusters[0].CacheClusterStatus'

# Esperado: available
```

#### Step 3: Verificar

```bash
# Obter endpoints dos bancos
terraform output rds_analytics_address
terraform output rds_auth_address
terraform output rds_flag_address
terraform output redis_endpoint

# Testar conexão com RDS (opcional - requer psql)
# psql -h <endpoint> -U postgres -d analytics

# Testar conexão com Redis (opcional - requer redis-cli)
# redis-cli -h <endpoint>
```

---

### 2.4 Deploying SQS Queues (Messaging)

**Tempo esperado:** ~2-3 minutos

#### Step 1: Plan

```bash
terraform plan -target=module.messaging -out=tfplan_messaging
```

**Revise o output:**
- Deve criar: 3 filas SQS, 3 DLQs, CloudWatch alarms
- Número de recursos: ~9-12

#### Step 2: Apply

```bash
terraform apply tfplan_messaging

# Aguarde até ver:
# Apply complete! Resources: X added, 0 changed, 0 destroyed.
```

#### Step 3: Verificar

```bash
# Listar filas SQS criadas
aws sqs list-queues --region us-east-1 --query 'QueueUrls' | grep staging

# Obter URLs
terraform output main_queue_url
terraform output analytics_queue_url
terraform output evaluation_queue_url
```

---

### 2.5 Deploying ECR (Container Registries)

**Tempo esperado:** ~1-2 minutos

#### Step 1: Plan

```bash
terraform plan -target=module.ecr -out=tfplan_ecr
```

**Revise o output:**
- Deve criar: 5 repositórios ECR, lifecycle policies, repository policies
- Número de recursos: ~12-15

#### Step 2: Apply

```bash
terraform apply tfplan_ecr

# Aguarde até ver:
# Apply complete! Resources: X added, 0 changed, 0 destroyed.
```

#### Step 3: Verificar

```bash
# Listar repositórios ECR
aws ecr describe-repositories --region us-east-1 --query 'repositories[*].repositoryName'

# Obter URLs para push
terraform output ecr_analytics_service_url
terraform output ecr_auth_service_url
terraform output ecr_evaluation_service_url
terraform output ecr_flag_service_url
terraform output ecr_target_service_url
```

---

## 🎯 Fase 3: Validação Final

### 3.1 Verificar Todos os Recursos

```bash
# Verificar VPC
aws ec2 describe-vpcs --filters Name=tag:Environment,Values=staging --query 'Vpcs[0].VpcId'

# Verificar EKS
aws eks describe-cluster --name fiap-stage3-eks --region us-east-1 --query 'cluster.status'

# Verificar RDS
aws rds describe-db-instances --query 'DBInstances[?DBInstanceIdentifier==`staging-analytics-db`].[DBInstanceStatus]'

# Verificar ElastiCache
aws elasticache describe-cache-clusters --show-cache-node-info --query 'CacheClusters[?CacheClusterId==`staging-redis`].[CacheClusterStatus]'

# Verificar DynamoDB
aws dynamodb describe-table --table-name staging-ToggleMasterAnalytics --query 'Table.TableStatus'

# Verificar SQS
aws sqs list-queues --region us-east-1 | grep staging

# Verificar ECR
aws ecr describe-repositories --region us-east-1 --query 'repositories[*].repositoryName'
```

### 3.2 Obter Todos os Outputs

```bash
terraform output

# Isto mostrará:
# - VPC ID e subnets
# - EKS endpoint e kubeconfig info
# - RDS endpoints e porta
# - Redis endpoint e porta
# - DynamoDB table name
# - SQS queue URLs
# - ECR repository URLs
```

### 3.3 Testar Conectividade EKS

```bash
# Verificar nodes
kubectl get nodes

# Verificar pods do sistema
kubectl get pods -n kube-system

# Testar deployment simples
kubectl create deployment nginx --image=nginx:latest --replicas=1

# Aguardar pod estar pronto
kubectl wait --for=condition=ready pod -l app=nginx --timeout=300s

# Limpar
kubectl delete deployment nginx
```

---

## 🔄 Fase 4: Próximos Passos

Após deployment bem-sucedido:

1. **Criar Secrets no EKS** para RDS/Redis/SQS:
   ```bash
   kubectl create secret generic db-credentials --from-literal=username=postgres --from-literal=password=...
   ```

2. **Deploy das Aplicações** usando os ECR URLs

3. **Configurar CI/CD** para build e push de imagens

4. **Configurar Monitoring** com CloudWatch/Prometheus

5. **Backup Strategy** para RDS e DynamoDB

---

## ❌ Rollback / Destroir

### Se algo der errado:

```bash
# Rollback específico de um módulo
terraform destroy -target=module.ecr
# ou
terraform destroy -target=module.messaging

# Rollback completo (⚠️ CUIDADO!)
terraform destroy
```

### Ordem recomendada para destroy:

1. `terraform destroy -target=module.ecr`
2. `terraform destroy -target=module.messaging`
3. `terraform destroy -target=module.databases`
4. `terraform destroy -target=module.eks`
5. `terraform destroy -target=module.networking`

Ou simplesmente:

```bash
terraform destroy  # Destroy everything
```

---

## 📊 Tempos Estimados (Total: ~45-60 minutos)

| Módulo | Tempo |
|--------|-------|
| Networking | 5-10 min |
| EKS | 15-25 min |
| Databases | 15-20 min |
| SQS | 2-3 min |
| ECR | 1-2 min |
| **TOTAL** | **45-60 min** |

---

## 📝 Checklist Final

- [ ] Terraform validou com sucesso
- [ ] Networking criado com sucesso
- [ ] EKS cluster criado e nodes prontos
- [ ] 3 RDS databases prontos
- [ ] Redis ElastiCache pronto
- [ ] DynamoDB table criado
- [ ] SQS queues criadas com DLQs
- [ ] 5 ECR repositories criados
- [ ] kubectl conecta ao cluster
- [ ] Todos os outputs estão visíveis
- [ ] Credenciais seguras armazenadas
- [ ] Backup strategy definida

---

**Data:** Maio 2026
**Ambiente:** Staging
**Próximo Review:** Antes de fazer deploy em Production
