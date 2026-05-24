#!/bin/bash

# Script para gerenciar sincronização de aplicações

ARGOCD_NAMESPACE="argocd"
ARGOCD_CLI="${ARGOCD_CLI:-argocd}"

usage() {
    echo "Uso: $0 <comando> [aplicação]"
    echo ""
    echo "Comandos:"
    echo "  list              - Listar todas as aplicações"
    echo "  status [app]      - Verificar status de uma aplicação"
    echo "  sync [app]        - Sincronizar uma aplicação"
    echo "  sync-all          - Sincronizar todas as aplicações"
    echo "  refresh [app]     - Atualizar status de uma aplicação"
    echo "  logs [app]        - Ver logs de sincronização"
    echo "  diff [app]        - Ver diferenças entre repo e cluster"
    echo ""
    echo "Exemplos:"
    echo "  $0 list"
    echo "  $0 status analytics-service"
    echo "  $0 sync-all"
}

list_apps() {
    echo "Listando aplicações do ArgoCD..."
    kubectl get applications -n ${ARGOCD_NAMESPACE} -o wide
}

status() {
    local app=$1
    if [ -z "$app" ]; then
        echo "Erro: especifique uma aplicação"
        usage
        exit 1
    fi
    
    echo "Status da aplicação: $app"
    kubectl get application $app -n ${ARGOCD_NAMESPACE} -o jsonpath='{
        .metadata.name = "Aplicação"
        .status.operationState.phase = "Fase"
        .status.syncStatusCode = "Sync Status"
        .status.health.status = "Health"
    }' 2>/dev/null || echo "Aplicação não encontrada"
    
    echo ""
    kubectl describe application $app -n ${ARGOCD_NAMESPACE} 2>/dev/null || true
}

sync() {
    local app=$1
    if [ -z "$app" ]; then
        echo "Erro: especifique uma aplicação"
        usage
        exit 1
    fi
    
    echo "Sincronizando aplicação: $app"
    kubectl patch application $app -n ${ARGOCD_NAMESPACE} \
        -p '{"metadata":{"finalizers":["resources-finalizer.argocd.argoproj.io"]}}' --type merge
    
    # Trigger manual sync
    kubectl patch application $app -n ${ARGOCD_NAMESPACE} \
        --type merge -p '{"spec":{"syncPolicy":{"syncOptions":["Refresh=hard"]}}}'
    
    echo "Sincronização iniciada para: $app"
}

sync_all() {
    echo "Sincronizando todas as aplicações..."
    APPS=$(kubectl get applications -n ${ARGOCD_NAMESPACE} -o jsonpath='{.items[*].metadata.name}')
    
    for app in $APPS; do
        echo "  - Sincronizando: $app"
        sync "$app"
    done
    
    echo "Todas as aplicações foram sincronizadas"
}

show_logs() {
    local app=$1
    if [ -z "$app" ]; then
        echo "Erro: especifique uma aplicação"
        usage
        exit 1
    fi
    
    echo "Logs de sincronização para: $app"
    kubectl logs -n ${ARGOCD_NAMESPACE} -l app.kubernetes.io/name=argocd-controller-manager \
        | grep "$app" | tail -20
}

show_diff() {
    local app=$1
    if [ -z "$app" ]; then
        echo "Erro: especifique uma aplicação"
        usage
        exit 1
    fi
    
    echo "Diferenças para: $app"
    kubectl get application $app -n ${ARGOCD_NAMESPACE} -o jsonpath='{.status.resources}' 2>/dev/null || \
        echo "Nenhuma diferença encontrada ou aplicação não pronta"
}

# Main
if [ $# -eq 0 ]; then
    usage
    exit 1
fi

case "$1" in
    list)
        list_apps
        ;;
    status)
        status "$2"
        ;;
    sync)
        sync "$2"
        ;;
    sync-all)
        sync_all
        ;;
    refresh)
        refresh "$2"
        ;;
    logs)
        show_logs "$2"
        ;;
    diff)
        show_diff "$2"
        ;;
    *)
        echo "Comando desconhecido: $1"
        usage
        exit 1
        ;;
esac
