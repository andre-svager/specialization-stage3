# GitHub Actions CI/CD Pipeline

Esteira automatizada de **CI/CD, DevSecOps** para os 5 microserviços FIAP Stage 3.

## 🚀 Quick Start

```bash
# 1. Adicionar GitHub Secrets (Settings → Secrets)
AWS_ACCOUNT_ID
AWS_REGION
AWS_ACCESS_KEY_ID
AWS_SECRET_ACCESS_KEY

# 2. Fazer push de código
git add .
git commit -m "Initial commit"
git push origin main

# 3. Acompanhar em GitHub → Actions
```

## 📁 Conteúdo desta Pasta

### Workflows (`.github/workflows/`)

**Trigger Workflows:** (acionam os reusable workflows)
- `ci-analytics.yml` - Analytics service (Python)
- `ci-auth.yml` - Auth service (Go)
- `ci-evaluation.yml` - Evaluation service (Go)
- `ci-flag.yml` - Flag service (Python)
- `ci-target.yml` - Target service (Python)

**Reusable Workflows:** (implementação compartilhada)
- `ci-python-reusable.yml` - Template para Python (black, isort, flake8, bandit, pytest, docker, trivy, ecr)
- `ci-go-reusable.yml` - Template para Go (golangci-lint, gosec, go test, docker, trivy, ecr)

### Documentação

| Arquivo | Objetivo | Tempo | Público |
|---------|----------|-------|---------|
| **CICD_GUIDE.md** | Guia completo da pipeline | 15-20 min | Devs |
| **SETUP_CHECKLIST.md** | Checklist de setup | 10 min | DevOps |
| **ARGOCD_INTEGRATION.md** | Integração GitOps | 20-25 min | DevOps/Arquitetos |
| **FILES_SUMMARY.md** | Resumo de arquivos | 5-10 min | Referência |

## 📊 Pipeline Visual

```
┌─────────────────────────────┐
│  Git Push / Pull Request    │
└──────────────┬──────────────┘
               │
    ┌──────────┴────────┐
    │                   │
 ┌──▼───┐           ┌──▼───┐
 │Python│           │ Go   │
 │ (3x) │           │ (2x) │
 └──┬───┘           └──┬───┘
    │                  │
    │  ┌────────────────┼────────────────┐
    │  │                │                │
 ┌──▼──▼──┐  ┌─────────▼──────┐  ┌─────▼──────┐
 │ Lint   │  │ SAST           │  │ Security   │
 │ Black  │  │ Bandit/gosec   │  │ Test       │
 │ isort  │  │ SCA Trivy      │  │            │
 │ flake8 │  │ (bloqueia ❌)  │  │ pytest/go  │
 │        │  │                │  │ test       │
 └──┬─────┘  └────────┬───────┘  └─────┬──────┘
    │                 │                │
    └─────────────────┼────────────────┘
                      │
         ┌────────────▼────────────┐
         │  Docker Build & Scan    │
         │  - Trivy image          │
         │  - Bloqueia se CRÍTICO  │
         └────────────┬────────────┘
                      │
         ┌────────────▼────────────┐
         │  Push para ECR          │
         │  - SHA + latest tag     │
         └────────────┬────────────┘
                      │
         ┌────────────▼────────────┐
         │  🟢 Deployment Ready    │
         │  (ArgoCD can deploy)    │
         └─────────────────────────┘
```

## ✨ Recursos

### Code Quality
✅ Black (formatação Python)
✅ isort (imports Python)
✅ flake8 (estilo Python)
✅ golangci-lint (linting Go)
✅ goimports (Go)

### Security (SAST)
✅ Bandit (Python security)
✅ gosec (Go security)

### Dependency Analysis (SCA)
✅ Trivy filesystem scan
✅ Trivy image scan
✅ Bloqueia vulnerabilidades CRÍTICAS

### Testing
✅ pytest (Python)
✅ go test com race detector (Go)
✅ Coverage reports (ambos)

### Build & Deploy
✅ Docker build
✅ ECR push
✅ deployment-info.json (para ArgoCD)

## 🔐 Security Features

| Check | Python | Go | Bloqueia |
|-------|--------|----|----|
| Lint | ✅ | ✅ | SIM |
| SAST | ✅ Bandit | ✅ gosec | NÃO* |
| SCA | ✅ Trivy | ✅ Trivy | ✅ CRÍTICO |
| Tests | ✅ pytest | ✅ go test | SIM |
| Docker | ✅ Trivy | ✅ Trivy | ✅ CRÍTICO |

*SAST gera relatório, não bloqueia automaticamente (pode ser configurado)

## 📚 Como Começar

### Para Desenvolvedores
1. Ler: `CICD_GUIDE.md`
2. Entender: Os 5 workflows específicos
3. Fazer: Push de código para triggerar CI

### Para DevOps
1. Ler: `SETUP_CHECKLIST.md`
2. Configurar: GitHub Secrets
3. Validar: Estrutura de arquivos
4. Testar: Primeira execução

### Para Arquitetos
1. Ler: `ARGOCD_INTEGRATION.md`
2. Desenhar: Infraestrutura GitOps
3. Implementar: ApplicationSet no ArgoCD

## 🔗 Arquivos de Configuração

Localizados na raiz do repositório:

- `.golangci.yml` - Config golangci-lint (Go)
- `.trivy.yaml` - Config Trivy scanning
- `.trivyignore` - Exceções Trivy
- `pyproject.toml` - Config Python (Black, isort, flake8, pytest)

## 🎯 Próximos Passos

1. ✅ Adicionar GitHub Secrets
2. ✅ Fazer primeiro push para triggerar CI
3. ✅ Validar que ECR recebeu nova imagem
4. 🔲 Integrar com ArgoCD
5. 🔲 Adicionar notificações Slack
6. 🔲 Configurar SBOM generation

## 📞 Documentação Completa

Abra os arquivos .md nesta pasta para:

- **CICD_GUIDE.md** → Tudo sobre a pipeline (15 min read)
- **SETUP_CHECKLIST.md** → Setup passo-a-passo (10 min)
- **ARGOCD_INTEGRATION.md** → GitOps com ArgoCD (20 min)
- **FILES_SUMMARY.md** → Referência de arquivos (5 min)

## 🚨 Problemas?

Consultar a seção "Troubleshooting" em `CICD_GUIDE.md` ou `SETUP_CHECKLIST.md`.

---

**Última atualização:** Maio 2026
**Status:** ✅ Pronto para Produção
**Total de Workflows:** 7 (5 triggers + 2 reusable)
**Cobertura:** 5 microserviços (3 Python + 2 Go)
