# CI/CD Pipeline - FIAP Stage 3

Esteira automatizada de CI/CD com GitHub Actions, incluindo build, testes, linting, SAST, SCA e push para ECR.

## 📋 Visão Geral

### Arquitetura da Pipeline

```
┌─────────────────────────────────────────────────────────────────┐
│                        Git Push / Pull Request                  │
└──────────────────────────────┬──────────────────────────────────┘
                               │
                    ┌──────────┴──────────┐
                    │                     │
           ┌────────▼────────┐   ┌────────▼────────┐
           │  Python Services│   │   Go Services   │
           │  (3 serviços)   │   │  (2 serviços)   │
           └────────┬────────┘   └────────┬────────┘
                    │                     │
        ┌───────────┴───────────┐ ┌───────┴─────────────┐
        │                       │ │                     │
   ┌────▼─────┐ ┌──────────┐ ┌──▼──────┐ ┌───────────┐
   │ Lint     │ │ SAST     │ │ Unit    │ │ Security  │
   │ (Black,  │ │ (Bandit) │ │ Tests   │ │ (Gosec)   │
   │ isort,   │ │          │ │ (pytest)│ │           │
   │ flake8)  │ │          │ │         │ │           │
   └────┬─────┘ └──────────┘ └─────────┘ └───────────┘
        │                                  (Linting)
        └──────────────────────┬──────────────────────┘
                               │
                    ┌──────────▼──────────┐
                    │  SCA (Trivy fs)     │
                    │  - Filesystem scan  │
                    │  - Bloqueia CRÍTICO │
                    └──────────┬──────────┘
                               │
                    ┌──────────▼──────────┐
                    │ Docker Build & Scan │
                    │  - Build image      │
                    │  - Trivy image scan │
                    │  - Bloqueia CRÍTICO │
                    └──────────┬──────────┘
                               │
                    ┌──────────▼──────────┐
                    │  Push to ECR        │
                    │  - ${IMAGE}:${SHA}  │
                    │  - ${IMAGE}:latest  │
                    └─────────────────────┘
```

## 🎯 Microserviços

### Python Services (3)
| Serviço | Caminho | Dockerfile |
|---------|---------|-----------|
| **Analytics** | `analytics-service/` | Dockerfile |
| **Flag** | `flag-service/` | Dockerfile |
| **Target** | `target-service/` | Dockerfile |

### Go Services (2)
| Serviço | Caminho | Dockerfile |
|---------|---------|-----------|
| **Auth** | `auth-service/` | Dockerfile |
| **Evaluation** | `evaluation-service/` | Dockerfile |

## 🔧 Workflows & Triggers

### 1. CI - Analytics Service (Python)
**Arquivo:** `.github/workflows/ci-analytics.yml`

**Triggers:**
- Push em `main` ou `develop`
- Pull Requests em `main` ou `develop`
- Mudanças em `analytics-service/**`

**Etapas:**
1. Checkout do código
2. Setup Python 3.11
3. Instalar dependências + ferramentas
4. **Lint com Black** (formatação de código)
5. **Lint com isort** (ordenação de imports)
6. **Lint com flake8** (estilo e qualidade)
7. **Bandit** (SAST - segurança Python)
8. **Trivy fs** (SCA filesystem)
9. Unit tests com pytest
10. Build Docker image
11. **Trivy** scan de imagem Docker
12. **Push para ECR**

### 2. CI - Flag Service (Python)
**Arquivo:** `.github/workflows/ci-flag.yml`

Identicamente ao Analytics Service.

### 3. CI - Target Service (Python)
**Arquivo:** `.github/workflows/ci-target.yml`

Identicamente ao Analytics Service.

### 4. CI - Auth Service (Go)
**Arquivo:** `.github/workflows/ci-auth.yml`

**Triggers:** Iguais aos serviços Python

**Etapas:**
1. Checkout do código
2. Setup Go 1.21
3. Download modules com cache
4. Verify go modules
5. **golangci-lint** (linting, formatação, análise estática)
6. **gosec** (SAST - segurança Go)
7. **Trivy fs** (SCA filesystem)
8. Unit tests com race detector
9. Build binário Go
10. Build Docker image
11. **Trivy** scan de imagem Docker
12. **Push para ECR**

### 5. CI - Evaluation Service (Go)
**Arquivo:** `.github/workflows/ci-evaluation.yml`

Identicamente ao Auth Service.

## 🔐 Segurança & DevSecOps

### Linting & Code Quality

#### Python
- **Black:** Formatação de código (linha máx 120)
- **isort:** Organização de imports
- **flake8:** Estilo e qualidade (complexidade máx 10)
- **Bandit:** SAST para encontrar problemas de segurança

#### Go
- **golangci-lint:** Linting combinado (15+ linters)
  - gofmt, goimports, govet
  - gosimple, staticcheck, unused
  - gocyclo, dupl, goconst
  - revive, stylecheck
- **gosec:** SAST para segurança em Go
  - SQL injection detection
  - Hardcoded credentials
  - Weak cryptography
  - Code injection

### SAST (Static Application Security Testing)

**Ferramentas:**
- **Python:** Bandit (segurança Python)
- **Go:** gosec (segurança Go)

**Output:** SARIF format → GitHub Security tab

**Falha a pipeline:** ❌ Não (apenas relatório)

### SCA (Software Composition Analysis)

**Ferramenta:** Trivy
- Escaneia dependências (pip, npm, composer, etc.)
- Detecta vulnerabilidades conhecidas em bibliotecas
- Gera relatório SARIF

**Scans:**
1. **Filesystem scan** (`trivy fs`)
   - Analisa `requirements.txt`, `go.mod`, `go.sum`
   - Bloqueia se vulnerabilidades **CRÍTICAS** encontradas
   
2. **Docker image scan** (`trivy image`)
   - Escaneia a imagem Docker construída
   - Bloqueia se vulnerabilidades **CRÍTICAS** encontradas

**Output:** SARIF format → GitHub Security tab

**Falha a pipeline:** ✅ SIM (se CRÍTICO)

### Configurações

#### `.golangci.yml`
Configuração centralizada para golangci-lint com:
- 20+ linters habilitados
- Tolerância a complexidade ciclomática: 15
- Duplication threshold: 150
- Exclusões para testes e mocks

#### `pyproject.toml`
Configurações Python com:
- Black: 120 caracteres por linha
- isort: profile black com sorting customizado
- flake8: max complexity 10, max line 120
- pytest: discovery automática
- Coverage: mínimo para testes

#### `.trivy.yaml`
Configuração de scanning:
- Severidades: CRITICAL, HIGH, MEDIUM, LOW
- Tipos: OS, library, npm, pip, composer, gem
- Timeout: 10 minutos
- Cache habilitado

#### `.trivyignore`
Exceções para Trivy (false positives, riscos aceitos).

## 📊 Outputs & Artefatos

### GitHub Actions

Cada workflow gera:

1. **Lint Reports** (se falhar)
   - Detalhes de erros em code review

2. **SARIF Reports** (carregados em Security)
   - golangci-lint → Code scanning
   - gosec → Code scanning
   - Bandit → Code scanning
   - Trivy fs → Code scanning
   - Trivy image → Code scanning

3. **Coverage Reports** (artefatos)
   - `htmlcov/` (Python)
   - `coverage.html` (Go)
   - Upload para Codecov (opcional)

4. **Deployment Info** (`deployment-info.json`)
   - Serviço, imagem, commit SHA
   - Usado para trigger do ArgoCD

5. **Run Summary**
   - Resumo visual de cada etapa completada

### ECR Push

```bash
# Imagens publicadas em:
<ACCOUNT>.dkr.ecr.<REGION>.amazonaws.com/<SERVICE>:<SHA>
<ACCOUNT>.dkr.ecr.<REGION>.amazonaws.com/<SERVICE>:latest
```

## 🚀 Configuração Inicial

### 1. Adicionar Secrets no GitHub

**Settings → Secrets → New repository secret**

```
AWS_ACCOUNT_ID       = 123456789012
AWS_REGION           = us-east-1
AWS_ACCESS_KEY_ID    = AKIA...
AWS_SECRET_ACCESS_KEY = wJalr...
```

### 2. Certificar que Dockerfiles existem

Cada serviço deve ter:
```
analytics-service/Dockerfile
auth-service/Dockerfile
evaluation-service/Dockerfile
flag-service/Dockerfile
target-service/Dockerfile
```

### 3. Certificar que temos dependências

**Python:** `requirements.txt` com pytest, black, isort, flake8, bandit
**Go:** `go.mod` e `go.sum` presentes

### 4. (Opcional) Certificar que ECR repos existem

Ou deixar o Terraform criar os repositórios ECR.

## 📝 Exemplo de Execução

### Cenário: Push em analytics-service/app.py

1. ✅ Trigger: `ci-analytics.yml` ativado
2. ✅ Checkout código
3. ✅ Setup Python 3.11
4. ✅ Instalar deps
5. ✅ Black ✓ (passed)
6. ✅ isort ✓ (passed)
7. ✅ flake8 ✓ (passed)
8. ✅ Bandit ✓ (passed)
9. ✅ Trivy fs ✓ (passed, nenhum CRÍTICO)
10. ✅ Testes ✓ (3/3 passed)
11. ✅ Docker build ✓
12. ✅ Trivy image ✓ (passed)
13. ✅ ECR push ✓ (pushed `analytics-service:abc123def456`)

**Status:** 🟢 **SUCCESS**

---

### Cenário: Vulnerabilidade CRÍTICA detectada

1. ✅ Trigger: `ci-evaluation.yml` ativado
2. ✅ Checkout, setup, deps
3. ✅ golangci-lint ✓
4. ✅ gosec ✓
5. ⚠️ Trivy fs: **CRÍTICO encontrado!**

**Status:** 🔴 **FAILED** (bloqueado)

**Ação:** Dev deve corrigir a vulnerabilidade e fazer novo push.

---

## 🔄 Fluxo de Aprovação

```
Feature Branch
     │
     ▼
Push / Pull Request
     │
     ▼
GitHub Actions CI
     │
     ├─ [❌ FALHA] ─────► Fix → Push
     │
     ├─ [✅ PASSA] ──────► Code Review
     │
     ▼
Merge para main/develop
     │
     ▼
Trigger ArgoCD
     │
     ▼
Deploy em EKS
```

## 📚 Ficheiros da Esteira

```
.github/
├── workflows/
│   ├── ci-analytics.yml          # Analytics Python CI
│   ├── ci-auth.yml               # Auth Go CI
│   ├── ci-evaluation.yml         # Evaluation Go CI
│   ├── ci-flag.yml               # Flag Python CI
│   ├── ci-target.yml             # Target Python CI
│   ├── ci-python-reusable.yml    # Template Python (reutilizável)
│   └── ci-go-reusable.yml        # Template Go (reutilizável)
├── .golangci.yml                 # Config Go linting
├── .trivy.yaml                   # Config Trivy
├── .trivyignore                  # Exceções Trivy
└── pyproject.toml                # Config Python (Black, isort, flake8, pytest)
```

## 🐛 Troubleshooting

### Black falha com erro de formatação
```bash
# Fix automaticamente
cd <service>
black .
```

### Flake8 reclama de complexidade
Quebrar função em funções menores ou aceitar complexidade se necessário.

### Bandit dá falso positivo
Adicionar comentário:
```python
# nosec B101
```

### golangci-lint muito lento
Aumentar timeout em `.golangci.yml`:
```yaml
run:
  timeout: 10m  # aumentar
```

### Trivy bloqueia por false positive
Adicionar a exceção em `.trivyignore`:
```
CVE-2021-12345  # False positive reason
```

## 🎯 Próximas Etapas

1. **ArgoCD Integration** - Trigger deploys baseado em deployment-info.json
2. **Slack Notifications** - Notificar status de builds
3. **Dependabot** - Auto-update de dependências vulneráveis
4. **SBOM Generation** - Gerar Software Bill of Materials (Cyclone DX)
5. **Performance Testing** - Load tests em staging

## 📞 Suporte & Contato

Para dúvidas sobre a pipeline, consultar:
- GitHub Docs: https://docs.github.com/en/actions
- Trivy Docs: https://aquasecurity.github.io/trivy/
- golangci-lint: https://golangci-lint.run/
- Black: https://black.readthedocs.io/

---

**Última atualização:** Maio 2026
**Status:** ✅ Produção Pronto
