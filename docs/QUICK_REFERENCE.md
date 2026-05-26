# 🚀 Quick Reference - CI/CD Pipeline

**Status:** ✅ PRONTO | **Arquivos:** 17 | **Linhas:** 2.600+ | **Tamanho:** 116KB

---

## ⚡ 5 Passos para Começar

```bash
# 1. Adicionar Secrets (GitHub → Settings → Secrets)
AWS_ACCOUNT_ID = xxx
AWS_REGION = us-east-1
AWS_ACCESS_KEY_ID = xxx
AWS_SECRET_ACCESS_KEY = xxx

# 2. Commit
git add .github/ .golangci.yml .trivy.yaml pyproject.toml .trivyignore
git commit -m "chore: add CI/CD pipeline"

# 3. Push
git push origin develop

# 4. Monitor
# GitHub → Actions → Ver workflows

# 5. Depois - ArgoCD
# Ler: .github/ARGOCD_INTEGRATION.md
```

---

## 📚 Documentação (por tempo)

| Tempo | Arquivo | Leitura | Público |
|-------|---------|---------|---------|
| **5 min** | `.github/README.md` | Overview | Devs |
| **10 min** | `.github/SETUP_CHECKLIST.md` | Setup passo-a-passo | DevOps |
| **15 min** | `.github/CICD_GUIDE.md` | Guia técnico | Devs + Arquitetos |
| **20 min** | `.github/ARGOCD_INTEGRATION.md` | GitOps com ArgoCD | DevOps + Arquitetos |
| **5 min** | `.github/FILES_SUMMARY.md` | Referência | Todos |

**Tempo total:** 55 minutos para entender tudo

---

## 🎯 Resposta Rápida

### "Como faço push de código?"
→ Faz push normal, workflows triggeram automático no `develop` e `main`

### "Aonde vejo os logs?"
→ GitHub → Actions → [service-name] → Click em run

### "Quando o Docker é feito?"
→ Se tudo passar antes (lint, tests, security)

### "Aonde vai a imagem Docker?"
→ ECR com tags: SHA (ex: `sha-abc123`) e `latest`

### "Como integro com ArgoCD?"
→ Ler: `.github/ARGOCD_INTEGRATION.md` (20 min)

### "E se falhar?"
→ Ler: `.github/SETUP_CHECKLIST.md` (seção Troubleshooting)

### "Preciso configurar mais algo?"
→ Não! Tudo pronto. Só adicionar os 4 GitHub Secrets.

---

## 🔧 Configurações Principais

### Python Services (analytics, flag, target)
```yaml
Black:       line-length=120
isort:       line_length=120
flake8:      max-complexity=10, line-length=120
Bandit:      SAST scanning
pytest:      Unit tests
```

### Go Services (auth, evaluation)
```yaml
golangci-lint: 20+ linters, complexity=15
gosec:         SAST scanning
go test:       With race detector
coverage:      HTML reports
```

### Todos
```yaml
Trivy FS:    Bloqueia se CRÍTICO
Trivy Image: Bloqueia se CRÍTICO
Docker:      Multi-stage builds
ECR Push:    SHA + latest tags
```

---

## ✨ Pipeline Visual

```
Push → Lint → SAST → SCA FS → Tests → Build → SCA Image → Push ECR
                ↓              ↓      ↓      ↓       ↓
               Fail?         Fail?  Fail?  Fail?   Fail?
```

**Crítico (Bloqueia):** Lint, Tests, Build, SCA CRÍTICO  
**Aviso (Relatório):** SAST  

---

## 📊 Checklist Final

- [ ] Ler README.md (5 min)
- [ ] Ler SETUP_CHECKLIST.md (10 min)
- [ ] Adicionar 4 GitHub Secrets (5 min)
- [ ] Fazer commit e push (2 min)
- [ ] Acompanhar primeira execução (5-10 min)
- [ ] Validar ECR recebeu imagem (2 min)
- [ ] Ler ARGOCD_INTEGRATION.md (20 min) - DEPOIS
- [ ] Setup ArgoCD (1-2 dias) - DEPOIS

---

## 🔗 Links Diretos

Arquivo | Abre em |
---------|---------|
.github/README.md | Seu editor |
.github/CICD_GUIDE.md | Seu editor |
.github/SETUP_CHECKLIST.md | Seu editor |
.github/ARGOCD_INTEGRATION.md | Seu editor |
.github/FILES_SUMMARY.md | Seu editor |
GitHub Actions | https://github.com/[seu-repo]/actions |

---

## 🆘 Problemas Comuns

**Problema:** "Workflow não triggerou"  
**Solução:** Verificar GitHub Secrets em Settings → Secrets

**Problema:** "Falha em AWS credentials"  
**Solução:** Verificar AWS_ACCESS_KEY_ID e AWS_SECRET_ACCESS_KEY

**Problema:** "ECR push falhou"  
**Solução:** Verificar repositórios já existem em ECR

**Problema:** "Quer ver os logs?"  
**Solução:** GitHub → Actions → [workflow] → Click no run

**Problema:** "Preciso mudar uma configuração"  
**Solução:** Editar arquivo correspondente (.golangci.yml, pyproject.toml, .trivy.yaml, etc)

---

## 📈 Próximas Fases

**Fase 1 (Agora):** Setup CI/CD ← Você está aqui  
**Fase 2 (1-2 dias):** Testar primeiro deploy  
**Fase 3 (1 semana):** Integrar ArgoCD  
**Fase 4 (2-4 semanas):** Adicionar monitoring/alertas  

---

## 💡 Dicas Pro

### Dica 1: Testar localmente
```bash
# Simular workflow local com 'act'
brew install act
act -j ci-analytics
```

### Dica 2: Entender cada etapa
```
Vê um workflow falhando?
→ Clica no job
→ Expande o step que falhou
→ Lê a mensagem de erro
→ Consulta troubleshooting na doc
```

### Dica 3: Customizar configurações
```
Quer alterar max-line-length?
→ Edit pyproject.toml [tool.flake8]
→ Commit e push
→ Próximo workflow usa nova config
```

### Dica 4: Adicionar novos serviços
```
Novo serviço Python?
→ Copy ci-analytics.yml → ci-newservice.yml
→ Alterar service_name e service_path
→ Done! Workflow já funciona
```

### Dica 5: GitHub Security
```
Vulnerability findings?
→ GitHub → Security → Code scanning
→ Vê SARIF reports com detalhes
→ Aprova exceções em .trivyignore
```

---

## 📞 Suporte Completo

**Pergunta:** "O que faz o workflow X?"  
**Resposta:** .github/CICD_GUIDE.md

**Pergunta:** "Como faço para...?"  
**Resposta:** .github/SETUP_CHECKLIST.md

**Pergunta:** "Qual arquivo configura Y?"  
**Resposta:** .github/FILES_SUMMARY.md

**Pergunta:** "Como integro com ArgoCD?"  
**Resposta:** .github/ARGOCD_INTEGRATION.md

---

## ✅ Resumo

| Item | Status |
|------|--------|
| Workflows | ✅ 7 criados |
| Configurações | ✅ 4 criadas |
| Documentação | ✅ 6 guias |
| Segurança | ✅ Configurada |
| Testes | ✅ Habilitados |
| Docker | ✅ Setup |
| ECR | ✅ Ready |
| ArgoCD | ✅ Documentado |
| Pronto? | ✅ **SIM!** |

---

**Criado com ❤️ para FIAP Stage 3**  
**Última atualização:** Maio 2026  
**Versão:** 1.0.0

👉 **Próximo passo:** Ler `.github/SETUP_CHECKLIST.md` (10 min) 🚀
