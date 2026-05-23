#!/bin/bash

set -e

# Cores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configurações
ARGOCD_NAMESPACE="argocd"
TEST_NAMESPACE="default"
TIMEOUT=600

echo -e "${BLUE}╔════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║         ArgoCD GitOps Workflow Test Suite          ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════╝${NC}"
echo ""

# 1. Verificar se ArgoCD está instalado
echo -e "${YELLOW}[TEST 1]${NC} Verificando instalação do ArgoCD..."
if kubectl get namespace ${ARGOCD_NAMESPACE} &>/dev/null; then
    echo -e "${GREEN}✓ Namespace argocd encontrado${NC}"
else
    echo -e "${RED}✗ Namespace argocd não encontrado${NC}"
    exit 1
fi

# 2. Verificar pods do ArgoCD
echo -e "${YELLOW}[TEST 2]${NC} Verificando pods do ArgoCD..."
ARGOCD_PODS=$(kubectl get pods -n ${ARGOCD_NAMESPACE} -l app.kubernetes.io/name=argocd-server --no-headers | wc -l)
if [ $ARGOCD_PODS -gt 0 ]; then
    echo -e "${GREEN}✓ ${ARGOCD_PODS} pod(s) do ArgoCD encontrado(s)${NC}"
else
    echo -e "${YELLOW}⚠ Nenhum pod do ArgoCD encontrado. Aguardando...${NC}"
    kubectl wait --for=condition=Ready pod -l app.kubernetes.io/name=argocd-server \
        -n ${ARGOCD_NAMESPACE} --timeout=300s
    echo -e "${GREEN}✓ Pods do ArgoCD prontos${NC}"
fi

# 3. Verificar API do ArgoCD
echo -e "${YELLOW}[TEST 3]${NC} Verificando API do ArgoCD..."
ARGOCD_SERVER=$(kubectl get svc -n ${ARGOCD_NAMESPACE} argocd-server -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || echo "localhost")
echo -e "${GREEN}✓ ArgoCD Server: ${ARGOCD_SERVER}${NC}"

# 4. Obter token de acesso
echo -e "${YELLOW}[TEST 4]${NC} Obtendo credenciais do ArgoCD..."
ARGOCD_PASSWORD=$(kubectl -n ${ARGOCD_NAMESPACE} get secret argocd-initial-admin-secret \
    -o jsonpath="{.data.password}" 2>/dev/null | base64 -d || echo "N/A")
if [ "${ARGOCD_PASSWORD}" != "N/A" ]; then
    echo -e "${GREEN}✓ Senha obtida com sucesso${NC}"
else
    echo -e "${YELLOW}⚠ Não foi possível obter a senha${NC}"
fi

# 5. Verificar repositórios configurados
echo -e "${YELLOW}[TEST 5]${NC} Verificando repositórios Git..."
REPOS=$(kubectl get secret -n ${ARGOCD_NAMESPACE} -l argocd.argoproj.io/secret-type=repository --no-headers | wc -l)
echo -e "${GREEN}✓ ${REPOS} repositório(s) configurado(s)${NC}"

# 6. Listar Applications
echo -e "${YELLOW}[TEST 6]${NC} Listando Applications do ArgoCD..."
APPS=$(kubectl get applications -n ${ARGOCD_NAMESPACE} -o jsonpath='{.items[*].metadata.name}' 2>/dev/null || echo "Nenhuma")
if [ "${APPS}" != "Nenhuma" ]; then
    echo -e "${GREEN}✓ Applications encontradas:${NC}"
    for app in $APPS; do
        echo -e "  - ${app}"
    done
else
    echo -e "${YELLOW}⚠ Nenhuma Application encontrada${NC}"
fi

# 7. Verificar estado de sincronização
echo -e "${YELLOW}[TEST 7]${NC} Verificando estado de sincronização..."
kubectl get applications -n ${ARGOCD_NAMESPACE} -o wide 2>/dev/null || echo "Sem applications"

# 8. Testar saudação de serviços
echo -e "${YELLOW}[TEST 8]${NC} Testando saúde dos serviços..."
SERVICES=("analytics-service" "auth-service" "evaluation-service" "flag-service" "target-service")
for service in "${SERVICES[@]}"; do
    if kubectl get deployment ${service} -n ${TEST_NAMESPACE} &>/dev/null; then
        READY=$(kubectl get deployment ${service} -n ${TEST_NAMESPACE} -o jsonpath='{.status.readyReplicas}' || echo "0")
        DESIRED=$(kubectl get deployment ${service} -n ${TEST_NAMESPACE} -o jsonpath='{.spec.replicas}' || echo "0")
        if [ "${READY}" == "${DESIRED}" ] && [ "${READY}" != "0" ]; then
            echo -e "${GREEN}✓ ${service}: ${READY}/${DESIRED} replicas prontas${NC}"
        else
            echo -e "${YELLOW}⚠ ${service}: ${READY}/${DESIRED} replicas${NC}"
        fi
    else
        echo -e "${YELLOW}⚠ ${service} não encontrado${NC}"
    fi
done

# 9. Verificar volume de logs
echo -e "${YELLOW}[TEST 9]${NC} Coletando logs do ArgoCD..."
RECENT_LOGS=$(kubectl logs -n ${ARGOCD_NAMESPACE} -l app.kubernetes.io/name=argocd-server --tail=5 2>/dev/null | wc -l)
if [ $RECENT_LOGS -gt 0 ]; then
    echo -e "${GREEN}✓ ${RECENT_LOGS} linhas de log coletadas${NC}"
else
    echo -e "${YELLOW}⚠ Sem logs recentes${NC}"
fi

# 10. Verificar recursos de cluster
echo -e "${YELLOW}[TEST 10]${NC} Verificando uso de recursos do cluster..."
echo -e "${BLUE}CPU e Memória (top nodes):${NC}"
kubectl top nodes 2>/dev/null | head -3 || echo "Metrics Server não instalado"

echo ""
echo -e "${BLUE}╔════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║              Testes Concluídos!                     ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${GREEN}Próximos passos:${NC}"
echo "  1. Configure seu repositório Git"
echo "  2. Implante as Applications: kubectl apply -f gitops/apps/"
echo "  3. Monitore o sincronismo em tempo real"
echo ""
