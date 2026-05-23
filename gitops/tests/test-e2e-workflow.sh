#!/bin/bash

set -e

# Teste E2E do fluxo GitOps completo

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

ARGOCD_NAMESPACE="argocd"
TEST_TIMEOUT=600

echo -e "${BLUE}╔════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║           GitOps E2E Workflow Test                 ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════╝${NC}"
echo ""

# 1. Deploy de teste
echo -e "${YELLOW}[1]${NC} Criando namespace de teste..."
kubectl create namespace gitops-test --dry-run=client -o yaml | kubectl apply -f -
echo -e "${GREEN}✓ Namespace criado${NC}"

# 2. Criar uma aplicação de teste
echo -e "${YELLOW}[2]${NC} Criando aplicação de teste no ArgoCD..."
cat > /tmp/test-app.yaml << 'EOF'
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: test-nginx
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://charts.bitnami.com/bitnami
    chart: nginx
    targetRevision: 13.2.23
    helm:
      releaseName: test-nginx
      values: |
        replicaCount: 1
        service:
          type: ClusterIP
  destination:
    server: https://kubernetes.default.svc
    namespace: gitops-test
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
EOF

kubectl apply -f /tmp/test-app.yaml
echo -e "${GREEN}✓ Aplicação de teste criada${NC}"

# 3. Aguardar sincronização
echo -e "${YELLOW}[3]${NC} Aguardando sincronização (máximo ${TEST_TIMEOUT}s)..."
START_TIME=$(date +%s)
while true; do
    STATUS=$(kubectl get application test-nginx -n ${ARGOCD_NAMESPACE} \
        -o jsonpath='{.status.operationState.phase}' 2>/dev/null || echo "Unknown")
    
    if [ "${STATUS}" == "Succeeded" ]; then
        echo -e "${GREEN}✓ Sincronização bem-sucedida${NC}"
        break
    elif [ "${STATUS}" == "Failed" ]; then
        echo -e "${RED}✗ Sincronização falhou${NC}"
        exit 1
    else
        ELAPSED=$(($(date +%s) - START_TIME))
        if [ $ELAPSED -gt $TEST_TIMEOUT ]; then
            echo -e "${RED}✗ Timeout esperando sincronização${NC}"
            exit 1
        fi
        echo -e "  Status: ${STATUS} (${ELAPSED}s)..."
        sleep 10
    fi
done

# 4. Verificar recursos implantados
echo -e "${YELLOW}[4]${NC} Verificando recursos implantados..."
PODS=$(kubectl get pods -n gitops-test -o jsonpath='{.items[*].metadata.name}')
if [ -n "${PODS}" ]; then
    echo -e "${GREEN}✓ Pods encontrados: ${PODS}${NC}"
else
    echo -e "${RED}✗ Nenhum pod encontrado${NC}"
    exit 1
fi

# 5. Verificar saúde dos pods
echo -e "${YELLOW}[5]${NC} Verificando saúde dos pods..."
kubectl wait --for=condition=Ready pod -n gitops-test --all --timeout=300s
echo -e "${GREEN}✓ Todos os pods estão prontos${NC}"

# 6. Testar resiliência (auto-healing)
echo -e "${YELLOW}[6]${NC} Testando auto-healing..."
# Deletar um deployment
kubectl delete deployment test-nginx -n gitops-test --ignore-not-found=true
sleep 10
# Verificar se foi recriado
if kubectl get deployment test-nginx -n gitops-test &>/dev/null; then
    echo -e "${GREEN}✓ Deployment recriado automaticamente${NC}"
else
    echo -e "${YELLOW}⚠ Deployment não foi recriado ainda${NC}"
fi

# 7. Limpeza
echo -e "${YELLOW}[7]${NC} Limpando recursos de teste..."
kubectl delete application test-nginx -n ${ARGOCD_NAMESPACE} --ignore-not-found=true
kubectl delete namespace gitops-test --ignore-not-found=true
echo -e "${GREEN}✓ Limpeza concluída${NC}"

echo ""
echo -e "${BLUE}╔════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║            E2E Test Concluído!                     ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════╝${NC}"
echo ""
