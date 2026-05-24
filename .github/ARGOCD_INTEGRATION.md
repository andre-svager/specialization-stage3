# ArgoCD Integration - CI/CD → Deployment

Guia para integrar GitHub Actions CI/CD com ArgoCD para deploys automáticos no EKS.

## 🎯 Fluxo Completo

```
┌──────────────────────────────────────────────────────┐
│ 1. Developer push código para GitHub (main/develop)  │
└────────────────────┬─────────────────────────────────┘
                     │
         ┌───────────▼──────────────┐
         │ GitHub Actions CI        │
         │ - Lint, test, build      │
         │ - Push para ECR          │
         │ - Gera deployment-info   │
         └───────────┬──────────────┘
                     │
         ┌───────────▼──────────────────────────┐
         │ Atualizar Gitops Repo                │
         │ - Commit novo deployment config      │
         │ - ou dispara webhook ArgoCD          │
         └───────────┬──────────────────────────┘
                     │
         ┌───────────▼──────────────────────────┐
         │ ArgoCD Detects Change                │
         │ - Sincroniza com manifests           │
         │ - Aplica no EKS                      │
         └───────────┬──────────────────────────┘
                     │
         ┌───────────▼──────────────┐
         │ 🟢 Deployment Success    │
         │ Serviço atualizado no    │
         │ Kubernetes               │
         └──────────────────────────┘
```

## 📦 O que é deployment-info.json?

Arquivo gerado ao final do CI workflow com:

```json
{
  "service": "analytics-service",
  "image": "123456789012.dkr.ecr.us-east-1.amazonaws.com/analytics-service:abc123def456",
  "commit_sha": "abc123def456789",
  "commit_message": "feat: add new feature",
  "timestamp": "2026-05-23T10:30:45Z"
}
```

## 🔄 Opções de Integração

### Opção 1: Webhook Direto (Recomendado para GitOps simples)

ArgoCD dispara refresh quando recebe webhook do GitHub.

**Vantagem:** Simples, direto
**Desvantagem:** Requer acesso ao webhook do ArgoCD



### Opção 3: Image Update Automation (Flux / ArgoCD Image Updater)

ArgoCD monitora ECR e atualiza automatically quando nova imagem disponível.

**Vantagem:** Completamente automático
**Desvantagem:** Mais complexo, requer configuração

## 📚 Implementação: Opção 2 (Recomendada)

### Passo 1: Criar Repository GitOps

```bash
# Em organizção/conta separada (melhor prática)
mkdir infrastructure
cd infrastructure
git init
git remote add origin https://github.com/seu-org/infrastructure.git
```

### Passo 2: Estrutura de Manifestos

```
infrastructure/
├── argocd/
│   ├── argocd-ns.yaml          # Namespace do ArgoCD
│   ├── argocd-config.yaml      # Configuração
│   └── secret-management.yaml  # Secrets (sealed)
├── apps/
│   ├── analytics/
│   │   ├── deployment.yaml
│   │   ├── service.yaml
│   │   └── kustomization.yaml
│   ├── auth/
│   │   ├── deployment.yaml
│   │   ├── service.yaml
│   │   └── kustomization.yaml
│   ├── evaluation/
│   ├── flag/
│   └── target/
└── appset.yaml                 # ApplicationSet (ArgoCD)
```

### Passo 3: ApplicationSet (Multi-app)

Arquivo: `infrastructure/appset.yaml`

```yaml
apiVersion: argoproj.io/v1alpha1
kind: ApplicationSet
metadata:
  name: fiap-stage3-apps
  namespace: argocd
spec:
  generators:
    - list:
        elements:
          - name: analytics-service
            path: apps/analytics
            image: ""  # será preenchido por CI
          - name: auth-service
            path: apps/auth
            image: ""
          - name: evaluation-service
            path: apps/evaluation
            image: ""
          - name: flag-service
            path: apps/flag
            image: ""
          - name: target-service
            path: apps/target
            image: ""
  
  template:
    metadata:
      name: "{{ name }}"
    spec:
      project: default
      source:
        repoURL: https://github.com/seu-org/infrastructure.git
        targetRevision: main
        path: "{{ path }}"
      destination:
        server: https://kubernetes.default.svc
        namespace: default
      syncPolicy:
        automated:
          prune: true
          selfHeal: true
        syncOptions:
          - CreateNamespace=true
```

### Passo 4: Exemplo de Deployment

Arquivo: `infrastructure/apps/analytics/deployment.yaml`

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: analytics-service
  namespace: default
spec:
  replicas: 2
  selector:
    matchLabels:
      app: analytics-service
  template:
    metadata:
      labels:
        app: analytics-service
    spec:
      serviceAccountName: analytics-sa
      containers:
      - name: analytics
        image: "123456789012.dkr.ecr.us-east-1.amazonaws.com/analytics-service:latest"
        imagePullPolicy: IfNotPresent
        ports:
        - containerPort: 5000
        env:
        - name: RDS_HOST
          valueFrom:
            secretKeyRef:
              name: analytics-secrets
              key: db-host
        - name: REDIS_HOST
          valueFrom:
            secretKeyRef:
              name: analytics-secrets
              key: redis-host
        livenessProbe:
          httpGet:
            path: /health
            port: 5000
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /ready
            port: 5000
          initialDelaySeconds: 10
          periodSeconds: 5
        resources:
          requests:
            memory: "128Mi"
            cpu: "100m"
          limits:
            memory: "512Mi"
            cpu: "500m"
```

### Passo 5: GitHub Actions Atualiza GitOps Repo

Adicionar job no CI que faz push para infrastructure repo:

Arquivo: `.github/workflows/ci-analytics.yml` (adicionar ao final)

```yaml
  update-gitops:
    needs: call-python-ci
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main'  # Apenas em main
    
    steps:
      - name: Download deployment info
        uses: actions/download-artifact@v4
        with:
          name: deployment-info-analytics-service
      
      - name: Checkout infrastructure repo
        uses: actions/checkout@v4
        with:
          repository: seu-org/infrastructure
          token: ${{ secrets.GH_TOKEN }}  # Token com acesso ao repo
          path: infrastructure
      
      - name: Update image in kustomization
        working-directory: infrastructure
        run: |
          # Atualizar a imagem no kustomization.yaml
          IMAGE=$(cat ../deployment-info.json | jq -r '.image')
          
          cd apps/analytics
          kustomize edit set image analytics-service=$IMAGE
      
      - name: Commit and push
        working-directory: infrastructure
        run: |
          git config user.email "ci@fiap.com"
          git config user.name "CI Bot"
          git add apps/analytics/kustomization.yaml
          git commit -m "chore: update analytics-service image to $(cat ../deployment-info.json | jq -r '.image | split(":")[1]')"
          git push origin main
```

### Passo 6: ArgoCD Application

Registrar no ArgoCD:

```bash
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Esperar pelo ArgoCD estar pronto (2-3 min)
kubectl wait -n argocd --for=condition=ready pod -l app.kubernetes.io/name=argocd-server --timeout=300s

# Acessar ArgoCD
kubectl port-forward -n argocd svc/argocd-server 8080:443

# Abrir: https://localhost:8080
# Default user: admin
# Password: kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
```

Na UI do ArgoCD, criar Application:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: fiap-stage3
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/seu-org/infrastructure.git
    targetRevision: main
    path: "."
  destination:
    server: https://kubernetes.default.svc
    namespace: argocd
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
```

### Passo 7: Testar Fluxo Completo

```bash
# 1. Fazer mudança em um arquivo
echo "# test" >> analytics-service/app.py

# 2. Commit e push
git add analytics-service/app.py
git commit -m "test: trigger CI"
git push origin main

# 3. Acompanhar GitHub Actions
# → CI passa
# → Nova imagem publicada em ECR
# → deployment-info.json gerado
# → infrastructure repo é atualizado

# 4. Acompanhar ArgoCD
kubectl get applications -n argocd
kubectl describe application fiap-stage3 -n argocd

# 5. Verificar deployment no EKS
kubectl get deployments
kubectl get pods
```

## 🔐 Secrets Management

### Opção A: AWS Secrets Manager

No deployment manifest:

```yaml
env:
- name: DB_PASSWORD
  valueFrom:
    secretKeyRef:
      name: rds-credentials
      key: password
```

Criar secret:
```bash
kubectl create secret generic rds-credentials \
  --from-literal=password=$RDS_PASSWORD
```

### Opção B: Sealed Secrets (Recomendado)

Integrar Sealed Secrets no ArgoCD:

```bash
# 1. Instalar sealed-secrets controller
kubectl apply -f https://github.com/bitnami-labs/sealed-secrets/releases/download/v0.18.0/controller.yaml

# 2. Criar secret criptografado
echo -n "senhasuper123" | kubectl create secret generic rds-credentials --dry-run=client --from-file=password=/dev/stdin -o yaml | kubeseal -o yaml > sealed-secret.yaml

# 3. Adicionar ao Git (seguro!)
git add sealed-secret.yaml
git push origin main
```

## 📊 Monitoramento

### ArgoCD Notifications

Configurar Slack para notificações:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: argocd-notifications-cm
  namespace: argocd
data:
  service.slack: |
    token: $slack-token
  
  trigger.on-sync-failed: |
    - when: app.status.operationState.phase in ['Error', 'Failed']
      send: [app-sync-failed]
  
  template.app-sync-failed: |
    message: |
      ⚠️ {{.app.metadata.name}} sync failed!
      Commit: {{.app.status.sync.revision}}
```

### GitHub Status Checks

ArgoCD pode reportar status de volta ao GitHub:

```bash
# Ativar GitHub webhook notification
kubectl patch configmap argocd-notifications-cm -n argocd --type merge -p '{"data":{"service.github":"token: $github-token"}}'
```

## 🚨 Troubleshooting

### ArgoCD não sincroniza
```bash
# Verificar logs
kubectl logs -n argocd deployment/argocd-application-controller

# Forçar sincronização
argocd app sync fiap-stage3
```

### Imagem não está sendo atualizada
- Verificar se image tag no deployment está correto
- Verificar ImagePullPolicy: IfNotPresent (mude para Always)
- Verificar se ECR credentials estão corretos no cluster

```bash
# Debug
kubectl describe pod <pod-name>
kubectl logs <pod-name>
```

### GitOps repo mudanças não aparecem
```bash
# Forçar refresh
argocd app refresh fiap-stage3 --hard

# Verificar status
argocd app get fiap-stage3
```

## 📚 Referências

- ArgoCD Docs: https://argo-cd.readthedocs.io/
- Kustomize: https://kustomize.io/
- Sealed Secrets: https://github.com/bitnami-labs/sealed-secrets
- ApplicationSet: https://argo-cd.readthedocs.io/en/stable/user-guide/application-set/

---

**Próximos passos:** Implementar ArgoCD e testar fluxo completo!
