# CI/CD Setup Checklist - FIAP Stage 3

Use este checklist para garantir que tudo está configurado corretamente.

## ✅ Pre-requisitos

- [ ] Repositório Git criado em GitHub
- [ ] Permissão para criar secrets e workflows
- [ ] AWS Account pronto
- [ ] ECR Repositories criados (pelo Terraform)

## 🔧 Configuração GitHub Secrets

No GitHub, ir em: **Settings → Secrets and variables → Actions**

- [ ] `AWS_ACCOUNT_ID` - Ex: `123456789012`
- [ ] `AWS_REGION` - Ex: `us-east-1`
- [ ] `AWS_ACCESS_KEY_ID` - AWS IAM User access key
- [ ] `AWS_SECRET_ACCESS_KEY` - AWS IAM User secret key

**Verificar:**
```bash
# Testar credenciais localmente
aws sts get-caller-identity
```

## 📁 Estrutura de Arquivos

- [ ] `.github/workflows/ci-*.yml` (5 files)
- [ ] `.github/workflows/ci-*-reusable.yml` (2 files)
- [ ] `.golangci.yml` (raiz do repo)
- [ ] `pyproject.toml` (raiz do repo)
- [ ] `.trivy.yaml` (raiz do repo)
- [ ] `.trivyignore` (raiz do repo)
- [ ] `.github/CICD_GUIDE.md` (documentação)

Verificar:
```bash
ls -la .github/workflows/
ls -la .golangci.yml
ls -la pyproject.toml
ls -la .trivy.yaml
```

## 🐍 Python Services

Para cada serviço Python (analytics, flag, target):

- [ ] `requirements.txt` existe
- [ ] `Dockerfile` existe
- [ ] Testes existem (ou criar `tests/__init__.py`)
- [ ] `app.py` é o entry point

**Adicionar ao requirements.txt:**
```
pytest>=7.4
pytest-cov>=4.1
black>=23.0
flake8>=6.0
isort>=5.12
bandit>=1.7
```

**Verificar:**
```bash
cd analytics-service
python -m pytest --version
black --version
flake8 --version
```

## 🐹 Go Services

Para cada serviço Go (auth, evaluation):

- [ ] `go.mod` existe
- [ ] `go.sum` existe
- [ ] `main.go` é o entry point
- [ ] `Dockerfile` existe
- [ ] Testes existem (patterns: `*_test.go`)

**Verificar:**
```bash
cd auth-service
go mod verify
go test ./...
```

## 🐳 Docker

Para cada serviço:

- [ ] Dockerfile tem `FROM` baseado em imagem segura
- [ ] Python: `python:3.11-slim` ou similar
- [ ] Go: `golang:1.21-alpine` para build, `alpine:latest` ou `distroless` para runtime
- [ ] Testar build local:

```bash
docker build analytics-service -t analytics-service:test
docker build auth-service -t auth-service:test
```

## 🏗️ ECR (Elastic Container Registry)

- [ ] 5 repositórios criados via Terraform:
  - `analytics-service`
  - `auth-service`
  - `evaluation-service`
  - `flag-service`
  - `target-service`

**Verificar:**
```bash
aws ecr describe-repositories --region us-east-1 | jq '.repositories[*].repositoryName'
```

## 🔐 IAM Permissions

O usuário AWS (access key) precisa de permissões:

- [ ] ECR:
  - `ecr:GetAuthorizationToken`
  - `ecr:BatchGetImage`
  - `ecr:GetDownloadUrlForLayer`
  - `ecr:PutImage`
  - `ecr:InitiateLayerUpload`
  - `ecr:UploadLayerPart`
  - `ecr:CompleteLayerUpload`

**Policy Example:**
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ecr:GetAuthorizationToken",
        "ecr:BatchGetImage",
        "ecr:GetDownloadUrlForLayer",
        "ecr:PutImage",
        "ecr:InitiateLayerUpload",
        "ecr:UploadLayerPart",
        "ecr:CompleteLayerUpload"
      ],
      "Resource": "*"
    }
  ]
}
```

## 🧪 Testar Workflows Localmente

Use `act` para testar workflows:

```bash
# Install act
brew install act  # macOS
choco install act  # Windows

# Teste um workflow
act -j build_and_test -s AWS_ACCOUNT_ID=123456789012 -s AWS_REGION=us-east-1
```

## ✍️ Primeiro Teste

1. Fazer mudança em um arquivo (ex: `analytics-service/app.py`)
2. Fazer commit e push para branch develop

```bash
git add analytics-service/app.py
git commit -m "test: trigger CI pipeline"
git push origin develop
```

3. Ir em **GitHub → Actions** e acompanhar o workflow
4. Verificar se:
   - ✅ Tests passaram
   - ✅ Linting passou
   - ✅ Docker image foi publicado em ECR
   - ✅ Nenhuma vulnerabilidade CRÍTICA

## 📋 Verificação Final

- [ ] Workflows aparecem em `.github/workflows/` e foram commitados
- [ ] Push em branch `develop` de um serviço dispara CI
- [ ] CI workflow completa com sucesso
- [ ] ECR repository tem nova imagem com tag `latest` e SHA do commit
- [ ] GitHub Security tab mostra relatórios de scanning (mesmo se zerados)

## 🚨 Problemas Comuns

### Erro: "ECR access denied"
- Verificar AWS credentials em GitHub Secrets
- Verificar IAM permissions
- Verificar se ECR repository existe

### Erro: "Docker build failed"
- Verificar Dockerfile
- Testar build localmente: `docker build <service>`

### Erro: "Trivy CRITICAL vulnerability blocked"
- Revisar a vulnerabilidade em `.trivyignore` se for false positive
- Ou atualizar dependência vulnerável

### Erro: "Black/flake8 failed"
- Rodar localmente para verificar
- Fix: `cd <service> && black . && isort .`

### Erro: "golangci-lint timeout"
- Aumentar timeout em `.golangci.yml`
- Ou rodar: `golangci-lint run --timeout=10m`

## 📞 Próximos Passos

1. **ArgoCD Integration**
   - Criar trigger que monitora `deployment-info.json`
   - Deploy automático quando imagem é publicada

2. **Slack Notifications**
   - Notificar em canal Slack quando CI falha/passa

3. **Coverage Reports**
   - Integrar com Codecov ou similar

4. **Security Dashboard**
   - Monitorar vulnerabilidades ao longo do tempo

---

**Atualizado:** Maio 2026
**Status:** ✅ Pronto para uso
