# specialization-stage3
Repository to store tech challenge of devops specialization stage 3
![Project definition steps](docs/devops_project_phases.svg)


Fase 0 — Preparação (1–2 dias)
1. Definir ambiente AWS

Se for AWS Academy: anote a LabRole ARN (vai ser usada no Terraform para EKS)
Se for conta pessoal: crie um usuário IAM com permissões de admin para o Terraform

2. Criar repositórios no GitHub

togglemaster (monorepo com os 5 microsserviços + código Terraform)
togglemaster-gitops (repositório separado só com manifests Kubernetes/Helm)

3. Instalar ferramentas locais

terraform, aws cli, kubectl, helm, docker


Fase 1 — Terraform / IaC (1–1.5 semana)
Passo 1 — Backend remoto

Crie um bucket S3 manualmente (só esta vez) para guardar o tfstate
Configure o backend "s3" no main.tf com use_lockfile = true

Passo 2 — Estrutura de módulos
infra/
  modules/
    networking/   → VPC, subnets pub/priv, IGW, route tables
    eks/          → cluster EKS + node groups (LabRole para Academy)
    databases/    → 3x RDS PostgreSQL, ElastiCache Redis, DynamoDB
    messaging/    → SQS
    ecr/          → 5 repositórios ECR
  main.tf
  variables.tf
  outputs.tf
Passo 3 — Implementar módulo a módulo, testando com terraform plan a cada etapa
Passo 4 — terraform apply final e validar na console AWS

Fase 2 — Pipeline CI / DevSecOps (1–1.5 semana)
Para cada microsserviço crie .github/workflows/ci-<serviço>.yaml com estes jobs em sequência:
Job 1 — Build & Test
yaml- uses: actions/setup-go@v5
- run: go build ./...
- run: go test ./...
Job 2 — Linter
yaml- uses: golangci/golangci-lint-action@v6
Job 3 — SAST + SCA
yaml# SCA com Trivy (modo filesystem)
- uses: aquasecurity/trivy-action@master
  with:
    scan-type: fs
    exit-code: 1          # falha se CRÍTICO
    severity: CRITICAL

# SAST com gosec
- run: go install github.com/securego/gosec/v2/cmd/gosec@latest
- run: gosec ./...
Job 4 — Docker Build, Scan e Push ECR
yaml- name: Build image
  run: docker build -t $IMAGE_TAG .

- name: Trivy container scan
  uses: aquasecurity/trivy-action@master
  with:
    image-ref: $IMAGE_TAG
    exit-code: 1
    severity: CRITICAL

- name: Login ECR
  uses: aws-actions/amazon-ecr-login@v2

- name: Push ECR
  run: docker push $ECR_REGISTRY/$SERVICE:${{ github.sha }}

Fase 3 — GitOps + ArgoCD (1 semana)
Passo 1 — Repositório GitOps
Estrutura em togglemaster-gitops/:
apps/
  auth/deployment.yaml
  flag/deployment.yaml
  targeting/deployment.yaml
  evaluation/deployment.yaml
  analytics/deployment.yaml
Passo 2 — Instalar ArgoCD no EKS
bashhelm repo add argo https://argoproj.github.io/argo-helm
helm install argocd argo/argo-cd -n argocd --create-namespace
Passo 3 — Auto-update da tag no CI
Adicione ao final do workflow CI um passo que edita o deployment.yaml do repo GitOps:
yaml- name: Update image tag in GitOps repo
  run: |
    git clone https://x-token:${{ secrets.GITOPS_TOKEN }}@github.com/seu-user/togglemaster-gitops
    cd togglemaster-gitops
    sed -i "s|image: .*auth.*|image: $ECR/$SERVICE:${{ github.sha }}|" apps/auth/deployment.yaml
    git commit -am "ci: update auth to ${{ github.sha }}"
    git push
Passo 4 — Configurar ArgoCD Application
Crie um Application no ArgoCD apontando para cada pasta do repo GitOps, com syncPolicy: automated.

Fase 4 — Entregáveis (2–3 dias)
Vídeo de demonstração (≤20 min)

Mostrar terraform plan + terraform apply (ou console AWS com recursos criados)
Inserir dependência vulnerável propositalmente → mostrar pipeline falhando no Trivy
Corrigir → mostrar pipeline passando
Mostrar o CI fazendo o push da nova tag para o repo GitOps
Mostrar ArgoCD detectando a mudança e fazendo sync automático dos 5 microsserviços

Relatório PDF

Nomes dos participantes
Links do repo + vídeo
Resumo dos desafios e decisões
Print do AWS Cost Estimator (use o AWS Pricing Calculator)

