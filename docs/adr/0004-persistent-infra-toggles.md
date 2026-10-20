# 0004 — Flags de infra como variáveis persistentes por ambiente

- **Status:** Aceita · **Data:** 2026-10-20

## Contexto
O painel deveria permitir ligar NAT/ALB. Se isso fosse um input do `workflow_dispatch`, o valor valeria só para aquela execução: o próximo deploy da `main` (com o padrão `false`) destruiria o recurso, e o drift detection reportaria falso positivo.

A primeira ideia foram *Environment Variables* do GitHub, mas elas só ficam visíveis para jobs que declaram `environment:` — e o job de **plan** propositalmente não declara (ele usa a role somente leitura, ver ADR-0001).

## Decisão
- Flags que **mudam infra** vivem em **Repository Variables com prefixo do ambiente**: `DEV_ENABLE_NAT_GATEWAY`, `DEV_ENABLE_ALB`, `DEV_INSTANCE_TYPE`, `PROD_...`. O workflow reutilizável resolve `vars[format('{0}_ENABLE_ALB', ENV)]` e exporta como `TF_VAR_*` tanto no plan quanto no apply.
- Flags que **mudam o pipeline** (`ENABLE_CHECKOV`, `ENABLE_INFRACOST`, `ENABLE_DRIFT_DETECTION`, `ENABLE_NIGHTLY_DESTROY`) também são Repository Variables e podem ser sobrescritas por execução via inputs do painel.

Para alterar uma flag de infra: `gh variable set DEV_ENABLE_ALB --body true` e depois rodar o painel com `apply` (ou fazer merge na `main`).

## Consequências
- ✅ Estado desejado único e consistente entre deploy, painel e drift.
- ✅ Plan e apply enxergam exatamente as mesmas flags.
- ✅ Alterações de flag ficam auditadas no GitHub.
- ⚠️ Flags fora do Git: o README documenta a tabela de flags e seus padrões.
