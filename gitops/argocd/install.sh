#!/bin/bash

set -e

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configurações
ARGOCD_NAMESPACE="argocd"
ARGOCD_VERSION="${ARGOCD_VERSION:-v2.8.3}"
CLUSTER_NAME="${CLUSTER_NAME:-eks-cluster}"
AWS_REGION="${AWS_REGION:-us-east-1}"

echo -e "${BLUE}╔════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║        ArgoCD Installation Script                   ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════╝${NC}"

# 1. Verificar se kubectl está disponível
echo -e "${YELLOW}[1/7]${NC} Verificando kubectl..."
if ! command -v kubectl &> /dev/null; then
    echo -e "${RED}✗ kubectl não encontrado${NC}"
    exit 1
fi
echo -e "${GREEN}✓ kubectl encontrado${NC}"

# 2. Verificar conexão com cluster
echo -e "${YELLOW}[2/7]${NC} Verificando conexão com cluster..."
if ! kubectl cluster-info &> /dev/null; then
    echo -e "${RED}✗ Não foi possível conectar ao cluster${NC}"
    exit 1
fi
CURRENT_CLUSTER=$(kubectl config current-context)
echo -e "${GREEN}✓ Conectado ao cluster: $CURRENT_CLUSTER${NC}"

# 3. Criar namespace
echo -e "${YELLOW}[3/7]${NC} Criando namespace argocd..."
kubectl create namespace ${ARGOCD_NAMESPACE} --dry-run=client -o yaml | kubectl apply -f -
echo -e "${GREEN}✓ Namespace criado${NC}"

# 4. Adicionar Helm repo
echo -e "${YELLOW}[4/7]${NC} Adicionando Helm repository..."
helm repo add argo https://argoproj.github.io/argo-helm
helm repo update
echo -e "${GREEN}✓ Helm repository atualizado${NC}"

# 5. Instalar ArgoCD via Helm
echo -e "${YELLOW}[5/7]${NC} Instalando ArgoCD..."
helm upgrade --install argocd argo/argo-cd \
  --namespace ${ARGOCD_NAMESPACE} \
  --values argocd/values.yaml \
  --version ${ARGOCD_VERSION} \
  --wait

echo -e "${GREEN}✓ ArgoCD instalado${NC}"

# 6. Aplicar configurações adicionais
echo -e "${YELLOW}[6/7]${NC} Aplicando configurações..."
kubectl apply -f argocd/rbac.yaml
kubectl apply -f argocd/secret-management.yaml
echo -e "${GREEN}✓ Configurações aplicadas${NC}"

# 7. Obter senha inicial
echo -e "${YELLOW}[7/7]${NC} Obtendo informações de acesso..."
echo ""
echo -e "${BLUE}╔════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║           ArgoCD Installed Successfully!            ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════╝${NC}"
echo ""

# Aguardar serviço estar pronto
echo -e "${YELLOW}Aguardando serviços ficarem prontos...${NC}"
kubectl wait --for=condition=Ready pod -l app.kubernetes.io/name=argocd-server \
  -n ${ARGOCD_NAMESPACE} --timeout=300s 2>/dev/null || true

# Obter senha
ARGOCD_PASSWORD=$(kubectl -n ${ARGOCD_NAMESPACE} get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d)

echo -e "${BLUE}Acesso ao ArgoCD:${NC}"
echo -e "  ${YELLOW}Namespace:${NC} ${ARGOCD_NAMESPACE}"
echo -e "  ${YELLOW}Usuário:${NC} admin"
echo -e "  ${YELLOW}Senha:${NC} ${ARGOCD_PASSWORD}"
echo ""

# Port forward
echo -e "${BLUE}Para acessar o ArgoCD UI, execute:${NC}"
echo -e "  ${YELLOW}kubectl port-forward -n ${ARGOCD_NAMESPACE} svc/argocd-server 8080:443${NC}"
echo ""
echo -e "${BLUE}Então acesse:${NC} https://localhost:8080"
echo ""

# Próximos passos
echo -e "${BLUE}Próximos passos:${NC}"
echo "  1. Configure seu repositório Git como Source"
echo "  2. Crie Applications para seus serviços"
echo "  3. Ative sincronização automática"
echo ""
