---
title: "Product Brief: tf-painel"
status: final
created: 2026-10-20
updated: 2026-10-20
author: Lucas Cardoso Alecrim
---

# Product Brief: tf-painel

## Resumo executivo

O **tf-painel** é um repositório público de portfólio que demonstra, de ponta a ponta, como operar infraestrutura AWS com Terraform através de um **painel de controle de CI/CD** no GitHub Actions. O "painel" é o próprio grafo de execução do Actions: estágios encadeados (qualidade → segurança → custo → plan → aprovação → apply), com **controles para ligar e desligar** etapas e recursos via formulário de *Run workflow*, feature flags no repositório e gates de aprovação por ambiente.

A infraestrutura gerenciada é clássica — **rede + compute** (VPC, subnets, EC2, NAT/ALB opcionais) — em dois ambientes (**dev** e **prod**), autenticada por **OIDC** (sem access keys). Os controles do painel não são decorativos: eles governam custo real, ligando NAT/ALB só quando necessário e destruindo o dev automaticamente fora do horário.

O objetivo é que um recrutador ou tech lead entenda, em 2 minutos de README e 1 clique no Actions, que o autor domina Terraform idiomático, pipelines seguros, governança de custo e disciplina de engenharia (commits semânticos, releases versionadas, ADRs).

## O problema

- Portfólios DevOps costumam mostrar `.tf` soltos ou um pipeline "plan/apply" genérico — não provam julgamento sobre **segurança, custo, drift e operação**.
- Quem avalia um candidato quer ver **decisões** (por que OIDC, por que sem NAT por padrão, por que aprovação em prod), não só código.
- Estudar Terraform/CI em conta real assusta pelo custo; sem guardrails, o laboratório vira fatura.

## A solução

Um repositório onde o pipeline é o produto:

1. **Painel de controle (GitHub Actions)**
   - `workflow_dispatch` com checkboxes/choices: ambiente, ação (`plan`/`apply`/`destroy`), ligar NAT, ligar ALB, rodar checkov, rodar infracost.
   - **Feature flags** em Repository/Environment Variables (ex.: `ENABLE_INFRACOST`, `ENABLE_DRIFT`) que valem também para PR e push.
   - **Aprovação manual** via GitHub Environment `prod` (o grafo pausa esperando o clique).
   - **Job Summary** visual: tabela do plan (add/change/destroy), custo estimado, findings de segurança e status de cada estágio.
2. **Fluxo de entrega**
   - PR → fmt, validate, tflint, checkov, infracost, `terraform test`, plan comentado no PR.
   - Merge na `main` → apply em dev → (aprovação) → apply em prod.
   - Agendado: detecção de drift (abre issue) e auto-destroy noturno do dev.
3. **Infra Terraform** em módulos reutilizáveis (network, compute), versões fixadas, state remoto em S3 com lock nativo, bootstrap separado para state + role OIDC + budget alert.
4. **Disciplina**: Conventional Commits validados por commitlint, release-please gerando CHANGELOG e tags semver, pre-commit local.

## O que diferencia

Honestamente, nada aqui é inédito — o diferencial é **execução e coerência**:
- Controles do painel ligados a uma necessidade real (custo), não a um demo.
- Segurança por padrão: OIDC com least privilege, EC2 privada acessada por SSM (sem SSH/chave), IMDSv2, volumes criptografados.
- Documentação de decisões (ADRs) e README bilíngue (PT-BR/EN).

## Para quem

- **Primário:** recrutadores e tech leads avaliando o Lucas para vagas DevOps/Cloud/SRE. Sucesso = entendem o valor sem clonar o repo.
- **Secundário:** o próprio Lucas, como laboratório e template para trabalho real.

## Critérios de sucesso

- Um run completo (PR → dev → aprovação → prod) verde e visível no Actions.
- Zero credenciais estáticas da AWS no GitHub.
- Custo mensal com dev destruído à noite e NAT/ALB desligados: ≤ US$ 16 (prod 24/7 ~US$ 12 entre EC2, IPv4 público e EBS).
- 100% dos commits no padrão Conventional Commits, autor único: Lucas Cardoso Alecrim.
- Pelo menos uma release semver gerada automaticamente com CHANGELOG.
- checkov sem findings HIGH/CRITICAL não justificados (skips documentados inline).

## Escopo

**Dentro (v1):** bootstrap (state S3 + OIDC + budget), módulos `network` e `compute`, ambientes dev/prod, workflows de PR, deploy, painel manual, drift, auto-destroy, release; README PT-BR/EN com diagrama; ADRs.

**Fora (v1):** Kubernetes/EKS, multi-conta (AWS Organizations), aplicação real rodando no EC2 além de uma página de health, Terragrunt, Atlantis, LocalStack.

## Restrições e premissas

- Conta AWS pessoal real; free tier possivelmente por créditos (contas novas pós-jul/2025). `[ASSUMPTION]`
- Região `us-east-1`. `[ASSUMPTION]`
- Repo `LucasCA-Git/tf-painel`, público. `[ASSUMPTION]`
- Código em inglês, comentários em português; README em PT-BR e EN.

## Visão

Evoluir para multi-conta com Organizations, módulos publicados no Terraform Registry, e um segundo "payload" (EKS ou serverless) controlado pelo mesmo painel — mostrando que o pipeline é a plataforma, não o recurso.
