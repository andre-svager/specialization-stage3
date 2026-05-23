# GitOps com ArgoCD - Infraestrutura Completa

## 📋 Visão Geral

Este diretório contém toda a infraestrutura GitOps para o projeto usando ArgoCD como ferramenta de sincronização contínua. A abordagem segue as melhores práticas de GitOps com sincronização automática, auto-healing e monitoramento.

## 🏗️ Estrutura do Projeto

```
gitops/
├── argocd/                 # Instalação e configuração do ArgoCD
│   ├── install.sh          # Script de instalação
│   ├── namespace.yaml      # Namespace do ArgoCD
│   ├── rbac.yaml          # Políticas RBAC
│   ├── values.yaml        # Valores do Helm para ArgoCD
│   ├── config.yaml        # Configurações do ArgoCD
│   └── secret-management.yaml  # Gerenciamento de secrets
├── helm/                   # Helm Charts para cada serviço
│   ├── analytics-service/
│   ├── auth-service/
│   ├── evaluation-service/
│   ├── flag-service/
│   └── target-service/
├── apps/                   # ArgoCD Applications (definições)
│   ├── analytics-app.yaml
│   ├── auth-app.yaml
│   ├── evaluation-app.yaml
│   ├── flag-app.yaml
│   ├── target-app.yaml
│   └── argocd-root.yaml    # App of Apps
├── kustomize/              # Kustomize overlays para diferentes ambientes
│   ├── base/
│   ├── overlays/
│   │   ├── dev/
│   │   ├── staging/
│   │   └── prod/
├── tests/                  # Scripts de teste
│   ├── test-argocd-workflow.sh
│   ├── test-e2e-workflow.sh
│   └── manage-applications.sh
└── README.md              # Este arquivo
```

## 🚀 Quick Start

### 1. Pré-requisitos

- Cluster Kubernetes 1.24+
- kubectl configurado
- Helm 3.0+
- AWS CLI (se usar ECR)

### 2. Instalar ArgoCD

```bash
cd gitops/argocd
bash install.sh
```

O script irá:
- Criar namespace `argocd`
- Instalar ArgoCD via Helm
- Configurar RBAC
- Exibir credenciais de acesso

### 3. Acessar a UI do ArgoCD

```bash
# Port forward para a UI
kubectl port-forward -n argocd svc/argocd-server 8080:443

# Acesso
# URL: https://localhost:8080
# User: admin
# Password: (exibida no final do install.sh)
```

### 4. Configurar Repositório Git

```bash
# 1. Configure seu repositório Git no ArgoCD
# 2. Atualize as URLs nos arquivos em gitops/apps/*.yaml
# 3. Atualize as credenciais em gitops/argocd/secret-management.yaml
```

### 5. Implantar Applications

```bash
# Opção 1: Usar App of Apps (recomendado)
kubectl apply -f gitops/apps/argocd-root.yaml

# Opção 2: Implantar applications individualmente
kubectl apply -f gitops/apps/
```

## 📊 Fluxo GitOps

```
┌──────────────────┐
│   Git Repository │
│   (seu-gitops)   │
└────────┬─────────┘
         │
         │ ArgoCD monitora
         ▼
┌──────────────────┐
│     ArgoCD       │
│   (sync check)   │
└────────┬─────────┘
         │
         │ Apply manifests
         ▼
┌──────────────────┐
│ Kubernetes API   │
│   (EKS/Cluster)  │
└────────┬─────────┘
         │
         │ Create/Update resources
         ▼
┌──────────────────┐
│  Running Pods    │
│   (Services)     │
└──────────────────┘
```

## 🔧 Configuração de Serviços

### Analytics Service (Python)

- **Port**: 8000
- **Database**: PostgreSQL
- **Chart**: `gitops/helm/analytics-service/`
- **Values**: `values.yaml`

```bash
# Deploy via ArgoCD
kubectl apply -f gitops/apps/analytics-app.yaml

# Verificar status
kubectl get application analytics-service -n argocd -w
```

### Auth Service (Go)

- **Port**: 8080
- **Database**: PostgreSQL
- **Chart**: `gitops/helm/auth-service/`
- **Application**: RBAC + JWT

### Evaluation Service (Go)

- **Port**: 8080
- **Message Queue**: SQS
- **Chart**: `gitops/helm/evaluation-service/`

### Flag Service (Python)

- **Port**: 8000
- **Database**: PostgreSQL
- **Chart**: `gitops/helm/flag-service/`

### Target Service (Python)

- **Port**: 8000
- **Database**: PostgreSQL
- **Chart**: `gitops/helm/target-service/`

## 🧪 Testes

### Teste de Workflow do ArgoCD

```bash
bash gitops/tests/test-argocd-workflow.sh
```

Verifica:
- ✓ Instalação do ArgoCD
- ✓ Pods em execução
- ✓ API disponível
- ✓ Repositórios configurados
- ✓ Applications sincronizadas
- ✓ Saúde dos serviços

### Teste E2E Completo

```bash
bash gitops/tests/test-e2e-workflow.sh
```

Testa:
- Criação de aplicação
- Sincronização automática
- Auto-healing
- Resiliência

### Gerenciar Applications

```bash
bash gitops/tests/manage-applications.sh list
bash gitops/tests/manage-applications.sh status analytics-service
bash gitops/tests/manage-applications.sh sync-all
```

## 📈 Monitoramento

### Verificar Status de Sincronização

```bash
# Listar todas as applications
kubectl get applications -n argocd

# Ver detalhes de uma application
kubectl describe application analytics-service -n argocd

# Ver logs de sincronização
kubectl logs -n argocd -l app.kubernetes.io/name=argocd-controller-manager
```

### Métricas do ArgoCD

Se Prometheus está instalado:

```bash
# Port forward para Prometheus
kubectl port-forward -n monitoring svc/prometheus 9090:9090
```

Métricas disponíveis:
- `argocd_app_sync_total`
- `argocd_app_reconcile_duration_seconds`
- `argocd_controller_reconcile_duration_seconds`

## 🔐 Segurança

### Secrets Gerenciamento

Use **Sealed Secrets** ou **External Secrets** em produção:

```bash
# Sealed Secrets
kubectl create secret generic db-password \
  --from-literal=password=mypassword \
  --dry-run=client -o yaml | kubeseal -f - > sealed-secret.yaml
```

### RBAC Policies

Configurado em `gitops/argocd/rbac.yaml`:

- **admin**: Acesso total
- **developers**: Pode criar/atualizar/sincronizar apps
- **readonly**: Apenas leitura

## 🌍 Multi-Ambientes

Use Kustomize overlays para diferentes ambientes:

```bash
# Dev
kubectl apply -k gitops/kustomize/overlays/dev

# Staging
kubectl apply -k gitops/kustomize/overlays/staging

# Production
kubectl apply -k gitops/kustomize/overlays/prod
```

## 🔄 CI/CD Integration

### GitHub Actions

Seu repositório CI/CD deve:

1. **Build & Push**
   ```bash
   docker build -t $ECR_REPO:$TAG .
   docker push $ECR_REPO:$TAG
   ```

2. **Update Image Tag** (no repositório GitOps)
   ```bash
   git clone $GITOPS_REPO
   kustomize edit set image $SERVICE=$ECR_REPO:$TAG
   git commit && git push
   ```

3. **ArgoCD Sincroniza Automaticamente**
   - Detecta mudança no repositório
   - Aplica novos manifestos
   - Pods atualizam com nova imagem

## 📝 Best Practices

1. **Versionamento**: Sempre use tags de versão explícitas, não `latest`
2. **Helmfiles**: Use HelmFile para gerenciar múltiplos releases
3. **GitOps Repo**: Mantenha em repositório separado
4. **Secrets**: Nunca committe secrets, use Sealed Secrets
5. **RBAC**: Implemente controle de acesso fino
6. **Notifications**: Configure notificações para falhas de sync
7. **Backup**: Backup regular de CRDs e configurações

## 🐛 Troubleshooting

### Application em "OutOfSync"

```bash
# Verificar diferenças
kubectl get application analytics-service -n argocd -o yaml | grep -A20 status

# Forçar sincronização
kubectl patch application analytics-service -n argocd \
  --type merge -p '{"spec":{"syncPolicy":{"syncOptions":["Refresh=hard"]}}}'
```

### Pods não iniciando

```bash
# Ver eventos da aplicação
kubectl describe application analytics-service -n argocd

# Ver logs dos pods
kubectl logs -n default -l app=analytics-service
```

### Erro de conexão com repositório

```bash
# Verificar secrets
kubectl get secret -n argocd -l argocd.argoproj.io/secret-type=repository

# Testar conexão
kubectl port-forward -n argocd svc/argocd-repo-server 8081:8081
```

## 📚 Referências

- [ArgoCD Documentation](https://argo-cd.readthedocs.io/)
- [GitOps Best Practices](https://www.gitops.tech/)
- [Kubernetes Best Practices](https://kubernetes.io/docs/)
- [Helm Best Practices](https://helm.sh/docs/)

## 🤝 Contribuindo

1. Crie uma branch para sua feature
2. Faça as alterações
3. Teste localmente
4. Faça commit e push
5. Abra um Pull Request

## 📞 Suporte

Para problemas ou dúvidas:

```bash
# Verificar logs do ArgoCD
kubectl logs -n argocd -f deployment/argocd-server

# Debug de manifests
kubectl apply --dry-run=client -f gitops/apps/

# Validar Helm charts
helm lint gitops/helm/*/
```
