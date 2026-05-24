# GitOps Workflow Guide - Fluxo Completo

## 🔄 Fluxo Completo do GitOps com ArgoCD

```
┌─────────────────────────────────────────────────────────────────┐
│                   FLUXO GITOPS COMPLETO                         │
└─────────────────────────────────────────────────────────────────┘

1. DESENVOLVIMENTO
   └─ Developer modifica código da aplicação (ex: analytics-service)

2. CI/CD PIPELINE (GitHub Actions)
   ├─ Build Docker image
   ├─ Run tests
   ├─ Push para ECR: 123456789012.dkr.ecr.us-east-1.amazonaws.com/analytics-service:abc123
   └─ Commit no repositório GitOps com nova tag de imagem

3. GIT REPOSITORY (GitOps Repo)
   ├─ Manifestos Kubernetes (gitops/apps/)
   ├─ Helm Charts (gitops/helm/)
   ├─ Kustomize bases e overlays
   └─ Configurações do ArgoCD (gitops/argocd/)

4. ARGOCD MONITORING
   ├─ ArgoCD detecta mudança no repositório
   ├─ Compara desejado (repo) vs atual (cluster)
   └─ Sincronização automática iniciada

5. KUBERNETES CLUSTER
   ├─ Nova imagem Docker pulled do ECR
   ├─ Pods substituídos com nova versão
   ├─ Health checks passam
   └─ Tráfego roteado para novos pods

6. OBSERVABILIDADE
   ├─ Logs dos novos pods
   ├─ Métricas de performance
   ├─ Alerts e notificações
   └─ ArgoCD registra estado final

```

## 📌 Pre-requisitos

- Cluster Kubernetes (EKS) configurado
- kubectl com acesso ao cluster
- Helm 3+
- Git com acesso aos repositórios
- Docker (para build local)
- AWS credentials (para ECR)

## 🚀 Step-by-Step: Setup Inicial

### Passo 1: Preparar Repositório GitOps

```bash
# Clone seu repositório GitOps
git clone https://github.com/seu-usuario/seu-gitops-repo.git
cd seu-gitops-repo

# Copiar estrutura do gitops
cp -r /caminho/para/stage3/gitops .
git add gitops/
git commit -m "feat: add gitops infrastructure"
git push origin main
```

### Passo 2: Instalar ArgoCD

```bash
# Entrar no diretório
cd gitops/argocd

# Executar instalação
bash install.sh

# Nota: salvar a senha exibida
```

### Passo 3: Acessar ArgoCD UI

```bash
# Port forward
kubectl port-forward -n argocd svc/argocd-server 8080:443 &

# Browser
# https://localhost:8080
# User: admin
# Password: (da instalação)
```

### Passo 4: Configurar Repositório Git

Na UI do ArgoCD:

1. Settings → Repositories → Connect Repo
2. Escolher connection method: HTTPS ou SSH
3. Preencher URL do repositório GitOps
4. Preencher credenciais (GitHub token ou SSH key)
5. Test connection
6. Create

### Passo 5: Criar Applications

Opção A - Usar App of Apps (recomendado):
```bash
kubectl apply -f gitops/apps/argocd-root.yaml
```

Opção B - Aplicar manualmente:
```bash
kubectl apply -f gitops/apps/
```

### Passo 6: Monitorar Sincronização

```bash
# Ver status
kubectl get applications -n argocd -w

# Ver detalhes
kubectl describe application analytics-service -n argocd

# Ver logs
kubectl logs -n argocd -f deployment/argocd-server
```

## 🔄 Fluxo Diário: Atualizando um Serviço

### Cenário: Atualizar Analytics Service

```bash
# 1. Modificar código
cd analytics-service
# ... fazer mudanças ...
git commit -m "feat: add new analytics feature"
git push origin main

# 2. CI Pipeline (GitHub Actions)
# - Build: docker build -t $ECR/analytics-service:v1.2.3 .
# - Test: pytest
# - Push: docker push $ECR/analytics-service:v1.2.3
# - Update: Push no GitOps repo com novo tag

# 3. Atualizar repositório GitOps
cd seu-gitops-repo
kustomize edit set image analytics-service=$ECR/analytics-service:v1.2.3
git commit -m "ci: update analytics-service to v1.2.3"
git push origin main

# 4. ArgoCD detecta e sincroniza automaticamente
# (verificável na UI ou com)
kubectl get applications analytics-service -n argocd -o wide

# 5. Validar deployment
kubectl rollout status deployment/analytics-service
kubectl logs -l app=analytics-service
```

## 🧪 Validação e Testes

### Teste 1: Health Check dos Serviços

```bash
# Verificar pods prontos
kubectl get pods -n default

# Verificar endpoints
kubectl get endpoints

# Fazer requisição para serviço
kubectl port-forward service/analytics-service 8000:8000
curl http://localhost:8000/health
```

### Teste 2: Simular Falha de Pod

```bash
# Deletar um pod (ArgoCD deve recriá-lo)
kubectl delete pod -l app=analytics-service

# Verificar recriação
kubectl get pods -l app=analytics-service -w

# Confirmar auto-healing funcionou
# (Pod deve voltar em poucos segundos)
```

### Teste 3: Sincronização Manual

```bash
# Desincronizar deliberadamente
kubectl edit deployment analytics-service
# Remover uma label ou mudar a imagem

# Forçar sincronização no ArgoCD
kubectl patch application analytics-service -n argocd \
  --type merge -p '{"spec":{"syncPolicy":{"syncOptions":["Refresh=hard"]}}}'

# Verificar se voltou ao desejado
kubectl get deployment analytics-service -o yaml | grep image
```

## 📊 Monitoramento Contínuo

### Logs do ArgoCD

```bash
# Servidor
kubectl logs -n argocd -f deployment/argocd-server

# Controller
kubectl logs -n argocd -f deployment/argocd-application-controller

# Repo Server
kubectl logs -n argocd -f deployment/argocd-repo-server
```

### Status de Applications

```bash
# Listar todos com status
kubectl get applications -n argocd -o wide

# JSON para parsing
kubectl get applications -n argocd -o json | jq '.items[] | {name: .metadata.name, status: .status.operationState.phase}'

# Watch em tempo real
kubectl get applications -n argocd -w
```

### Eventos do Kubernetes

```bash
# Ver eventos de deployment
kubectl describe deployment analytics-service

# Ver eventos do cluster
kubectl get events -n default --sort-by='.lastTimestamp' | tail -20
```

## 🚨 Troubleshooting Comum

### Application em OutOfSync

**Problema**: Application mostra status "OutOfSync"

**Solução 1**: Sincronização manual
```bash
kubectl patch application analytics-service -n argocd \
  --type merge -p '{"spec":{"syncPolicy":{"syncOptions":["Refresh=hard"]}}}'
```

**Solução 2**: Verificar diferenças
```bash
kubectl get application analytics-service -n argocd -o jsonpath='{.status.resources}' | jq
```

**Solução 3**: Verificar credenciais do repositório
```bash
kubectl get secret -n argocd argocd-repo-creds -o yaml | grep password
```

### Pods não iniciando

**Problema**: Pods stuck em "Pending" ou "CrashLoopBackOff"

**Debug**:
```bash
# Ver status detalhado
kubectl describe pod <pod-name>

# Ver logs
kubectl logs <pod-name> --tail=100

# Ver eventos
kubectl get events -n default --sort-by='.lastTimestamp'

# Verificar recursos disponíveis
kubectl top nodes
kubectl describe nodes
```

### Erro de sincronização

**Problema**: "sync failed"

**Verificar**:
```bash
# Validar manifests
kubectl apply -f gitops/apps/ --dry-run=client

# Validar Helm charts
helm lint gitops/helm/*/

# Testar kustomize
kustomize build gitops/kustomize/overlays/dev
```

## 📈 Escalando para Produção

### 1. Multi-Ambiente (Dev → Staging → Prod)

```bash
# ArgoCD Applications por ambiente
- dev-analytics (points to gitops/kustomize/overlays/dev)
- staging-analytics (points to gitops/kustomize/overlays/staging)
- prod-analytics (points to gitops/kustomize/overlays/prod)

# Cada ambiente com:
- Namespace separado
- Recursos diferenciados
- Políticas RBAC diferentes
- Notificações específicas
```

### 2. Notifications

Configure notificações para Slack/Teams:

```yaml
# gitops/argocd/notifications.yaml
trigger.on-sync-failed: |
  message: Application {{.app.metadata.name}} sync failed
  slack:
    attachments: |
      [{
        "text": "{{.app.status.operationState.finishedAt}}"
      }]
```

### 3. Backup e Disaster Recovery

```bash
# Backup de Applications
kubectl get applications -n argocd -o yaml > backup-apps.yaml

# Backup de ArgoCD Config
kubectl get cm,secret -n argocd -o yaml > backup-argocd.yaml

# Restaurar
kubectl apply -f backup-apps.yaml
kubectl apply -f backup-argocd.yaml
```

## 🔐 Segurança Best Practices

1. **Secrets Management**
   - Use Sealed Secrets para Git
   - Use External Secrets Operator para AWS Secrets Manager
   - Nunca committe credenciais

2. **RBAC**
   - Admin: apenas SRE/Platform
   - Developer: create/sync/get apps
   - Readonly: view only

3. **Repository Protections**
   - Branch protection rules
   - Require PR reviews
   - Require status checks

4. **Audit Logging**
   - Enable ArgoCD audit logging
   - Monitor mudanças via Git history
   - Setup alerts para mudanças suspeitas

## 📚 Referências

- [ArgoCD Official Docs](https://argo-cd.readthedocs.io/)
- [GitOps Principles](https://www.gitops.tech/)
- [Kubernetes Native Buildpacks](https://buildpacks.io/)
- [Helm Best Practices](https://helm.sh/docs/chart_best_practices/)

## 📞 Suporte Rápido

```bash
# Health check
bash gitops/tests/test-argocd-workflow.sh

# E2E Test
bash gitops/tests/test-e2e-workflow.sh

# Manage apps
bash gitops/tests/manage-applications.sh list
bash gitops/tests/manage-applications.sh status analytics-service
bash gitops/tests/manage-applications.sh sync-all
```
