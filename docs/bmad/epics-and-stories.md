---
title: "Epics & Stories: tf-painel"
status: in-progress
created: 2026-10-20
inputs: [architecture.md, briefs/brief-tf-painel-2026-10-20/brief.md]
---

# Épicos e stories — tf-painel

Legenda: ✅ entregue na v1 · ⏭️ backlog

## E1 — Fundação (bootstrap)
- ✅ **S1.1** Como operador, quero um bucket de state versionado e criptografado com lock nativo, para que execuções concorrentes não corrompam o state.
  - AC: `use_lockfile = true`; public access block; TLS obrigatório; versionamento.
- ✅ **S1.2** Como operador, quero que o GitHub Actions assuma roles AWS via OIDC, para não guardar access keys.
  - AC: role de plan só leitura; role de apply só via `environment:dev|prod`.
- ✅ **S1.3** Como dono da conta, quero alerta de orçamento, para não ser surpreendido na fatura.

## E2 — Infraestrutura
- ✅ **S2.1** Módulo `network` com subnets públicas/privadas multi-AZ e NAT opcional.
  - AC: testes `terraform test` cobrindo cálculo de CIDR e toggle de NAT.
- ✅ **S2.2** Módulo `compute` com EC2 gerenciada por SSM, IMDSv2, EBS criptografado e ALB opcional.
  - AC: sem ingress quando ALB desligado; testes cobrindo posicionamento de subnet.
- ✅ **S2.3** Ambientes `dev` e `prod` compondo os módulos com backend parcial.

## E3 — Painel de CI/CD
- ✅ **S3.1** Quality gate reutilizável (fmt, validate, tflint, test) em matrix.
- ✅ **S3.2** Segurança com checkov ligável por flag.
- ✅ **S3.3** PR mostra plan de dev/prod e custo (infracost) em comentário único atualizado.
- ✅ **S3.4** Merge na `main` aplica dev e pausa em prod esperando aprovação.
- ✅ **S3.5** Painel manual (`workflow_dispatch`) com ambiente, ação e checkboxes de estágios.
- ✅ **S3.6** Job Summary com resumo do plan (add/change/destroy) em todas as execuções.
- ✅ **S3.7** Drift detection diário abrindo/atualizando issue.
- ✅ **S3.8** Destroy noturno do dev controlado por flag.

## E4 — Disciplina e vitrine
- ✅ **S4.1** commitlint no PR + hook local.
- ✅ **S4.2** release-please gerando CHANGELOG e tags semver.
- ✅ **S4.3** README PT-BR/EN com diagrama, tabela de flags e guia de setup.
- ⏭️ **S4.4** Prints/GIF do painel no README (após primeira execução real).

## Backlog (pós-v1)
- ⏭️ Auto Scaling Group com launch template no lugar de instância única.
- ⏭️ HTTPS no ALB com ACM + Route 53 (`lcaoficial.com.br`).
- ⏭️ NAT instance (fck-nat) como alternativa barata ao NAT Gateway.
- ⏭️ Multi-conta com AWS Organizations.
- ⏭️ Terratest para testes de integração reais.
