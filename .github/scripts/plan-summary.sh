#!/usr/bin/env bash
# Gera o resumo visual de um plan (Job Summary + markdown para comentário no PR).
#
# Uso: plan-summary.sh <ambiente> <ação> <exit-code-do-plan>
# Espera no diretório atual: tfplan (binário) e plan.txt (saída do terraform show).
# Produz: plan.json, summary.md e as outputs `has_changes`, `add`, `change`, `destroy`.
set -euo pipefail

env_name="$1"
action="$2"
plan_exit="$3"

terraform show -json tfplan > plan.json

count() {
  jq --arg a "$1" '[.resource_changes[]? | select(.change.actions | index($a))] | length' plan.json
}

add=$(count create)
change=$(count update)
destroy=$(count delete)

# exit 2 = há mudanças (terraform plan -detailed-exitcode)
if [[ "$plan_exit" == "2" ]]; then
  has_changes=true
  status="🟡 mudanças pendentes"
else
  has_changes=false
  status="🟢 sem mudanças"
fi

# Plan grande é truncado para caber no limite de 65k caracteres do comentário.
max_chars=20000
# `|| true`: com pipefail, o head fechando o pipe cedo (SIGPIPE) não pode falhar o step.
plan_body=$(grep -vE '^\s*$' plan.txt | head -c "$max_chars" || true)
truncated=""
if [[ $(wc -c < plan.txt) -gt $max_chars ]]; then
  truncated=$'\n… (truncado — veja o artefato do plan)'
fi

{
  echo "### 🏗️ Terraform · \`${env_name}\` · ${action}"
  echo
  echo "| Status | ➕ Criar | 🔄 Alterar | 🗑️ Destruir |"
  echo "|---|---:|---:|---:|"
  echo "| ${status} | ${add} | ${change} | ${destroy} |"
  echo
  echo "<details><summary>Ver plan</summary>"
  echo
  echo '```hcl'
  echo "${plan_body}${truncated}"
  echo '```'
  echo
  echo "</details>"
} > summary.md

cat summary.md >> "$GITHUB_STEP_SUMMARY"

{
  echo "has_changes=${has_changes}"
  echo "add=${add}"
  echo "change=${change}"
  echo "destroy=${destroy}"
} >> "$GITHUB_OUTPUT"
