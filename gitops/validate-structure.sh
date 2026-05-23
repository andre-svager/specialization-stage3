#!/bin/bash

set -e

# Script de validação da estrutura GitOps completa

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}╔════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║         GitOps Structure Validation                ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════╝${NC}"
echo ""

ERRORS=0
WARNINGS=0

# Check directories
echo -e "${YELLOW}[1]${NC} Verificando estrutura de diretórios..."

REQUIRED_DIRS=(
    "argocd"
    "helm/analytics-service"
    "helm/auth-service"
    "helm/evaluation-service"
    "helm/flag-service"
    "helm/target-service"
    "apps"
    "kustomize/base"
    "kustomize/overlays/dev"
    "kustomize/overlays/staging"
    "kustomize/overlays/prod"
    "tests"
)

for dir in "${REQUIRED_DIRS[@]}"; do
    if [ -d "$dir" ]; then
        echo -e "  ${GREEN}✓${NC} $dir"
    else
        echo -e "  ${RED}✗${NC} $dir (MISSING)"
        ((ERRORS++))
    fi
done

# Check required files
echo ""
echo -e "${YELLOW}[2]${NC} Verificando arquivos obrigatórios..."

REQUIRED_FILES=(
    "argocd/install.sh"
    "argocd/namespace.yaml"
    "argocd/rbac.yaml"
    "argocd/values.yaml"
    "argocd/config.yaml"
    "argocd/secret-management.yaml"
    "apps/analytics-app.yaml"
    "apps/auth-app.yaml"
    "apps/evaluation-app.yaml"
    "apps/flag-app.yaml"
    "apps/target-app.yaml"
    "apps/argocd-root.yaml"
    "helm/analytics-service/Chart.yaml"
    "helm/analytics-service/values.yaml"
    "helm/auth-service/Chart.yaml"
    "helm/auth-service/values.yaml"
    "kustomize/base/kustomization.yaml"
    "kustomize/overlays/dev/kustomization.yaml"
    "kustomize/overlays/staging/kustomization.yaml"
    "kustomize/overlays/prod/kustomization.yaml"
    "tests/test-argocd-workflow.sh"
    "tests/test-e2e-workflow.sh"
    "tests/manage-applications.sh"
    "README.md"
    "WORKFLOW_GUIDE.md"
)

for file in "${REQUIRED_FILES[@]}"; do
    if [ -f "$file" ]; then
        echo -e "  ${GREEN}✓${NC} $file"
    else
        echo -e "  ${RED}✗${NC} $file (MISSING)"
        ((ERRORS++))
    fi
done

# Check Helm charts
echo ""
echo -e "${YELLOW}[3]${NC} Validando Helm charts..."

HELM_CHARTS=(
    "analytics-service"
    "auth-service"
    "evaluation-service"
    "flag-service"
    "target-service"
)

for chart in "${HELM_CHARTS[@]}"; do
    if command -v helm &> /dev/null; then
        if helm lint "helm/$chart" &>/dev/null; then
            echo -e "  ${GREEN}✓${NC} helm/$chart"
        else
            echo -e "  ${YELLOW}⚠${NC} helm/$chart (lint warnings)"
            ((WARNINGS++))
        fi
    else
        echo -e "  ${YELLOW}⚠${NC} helm/$chart (helm not installed)"
    fi
done

# Check scripts
echo ""
echo -e "${YELLOW}[4]${NC} Verificando scripts..."

SCRIPTS=(
    "argocd/install.sh"
    "tests/test-argocd-workflow.sh"
    "tests/test-e2e-workflow.sh"
    "tests/manage-applications.sh"
)

for script in "${SCRIPTS[@]}"; do
    if [ -x "$script" ]; then
        echo -e "  ${GREEN}✓${NC} $script (executable)"
    else
        echo -e "  ${YELLOW}⚠${NC} $script (not executable)"
        chmod +x "$script"
    fi
done

# Check YAML syntax
echo ""
echo -e "${YELLOW}[5]${NC} Validando YAML syntax..."

if command -v yq &> /dev/null; then
    YAML_FILES=$(find . -name "*.yaml" -type f | grep -E "(argocd|apps|helm)")
    for yaml_file in $YAML_FILES; do
        if yq eval '.' "$yaml_file" &>/dev/null; then
            echo -e "  ${GREEN}✓${NC} $yaml_file"
        else
            echo -e "  ${RED}✗${NC} $yaml_file (invalid YAML)"
            ((ERRORS++))
        fi
    done
else
    echo -e "  ${YELLOW}⚠${NC} yq not installed, skipping YAML validation"
fi

# Check kustomize
echo ""
echo -e "${YELLOW}[6]${NC} Validando Kustomize..."

if command -v kustomize &> /dev/null; then
    KUSTOMIZE_BASES=(
        "kustomize/base"
        "kustomize/overlays/dev"
        "kustomize/overlays/staging"
        "kustomize/overlays/prod"
    )
    
    for base in "${KUSTOMIZE_BASES[@]}"; do
        if kustomize build "$base" &>/dev/null; then
            echo -e "  ${GREEN}✓${NC} $base"
        else
            echo -e "  ${RED}✗${NC} $base (invalid kustomization)"
            ((ERRORS++))
        fi
    done
else
    echo -e "  ${YELLOW}⚠${NC} kustomize not installed, skipping validation"
fi

# Summary
echo ""
echo -e "${BLUE}╔════════════════════════════════════════════════════╗${NC}"
if [ $ERRORS -eq 0 ]; then
    echo -e "${BLUE}║              Validação Completa!                  ║${NC}"
else
    echo -e "${BLUE}║              Validação com Erros!                 ║${NC}"
fi
echo -e "${BLUE}╚════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${GREEN}Erros: $ERRORS${NC}"
echo -e "${YELLOW}Avisos: $WARNINGS${NC}"
echo ""

if [ $ERRORS -gt 0 ]; then
    echo -e "${RED}✗ Estrutura GitOps inválida${NC}"
    exit 1
else
    echo -e "${GREEN}✓ Estrutura GitOps válida${NC}"
    echo ""
    echo -e "${BLUE}Próximos passos:${NC}"
    echo "  1. bash gitops/argocd/install.sh"
    echo "  2. kubectl apply -f gitops/apps/"
    echo "  3. bash gitops/tests/test-argocd-workflow.sh"
    exit 0
fi
