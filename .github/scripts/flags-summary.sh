#!/usr/bin/env bash
# Escreve no Job Summary a "fotografia" das flags do painel usadas nesta execução.
# Variáveis esperadas: ENV_NAME, ACTION, TF_VAR_enable_nat_gateway, TF_VAR_enable_alb, TF_VAR_instance_type
set -euo pipefail

# Falha cedo se o workflow não exportou as flags.
: "${ENV_NAME:?}" "${ACTION:?}"
: "${TF_VAR_enable_nat_gateway:?}" "${TF_VAR_enable_alb:?}" "${TF_VAR_instance_type:?}"

icon() { [[ "$1" == "true" ]] && echo "🟢 on" || echo "⚪ off"; }

{
  echo "### 🎛️ Painel · \`${ENV_NAME}\` · ${ACTION}"
  echo
  echo "| Flag | Valor |"
  echo "|---|---|"
  echo "| NAT Gateway | $(icon "${TF_VAR_enable_nat_gateway}") |"
  echo "| ALB | $(icon "${TF_VAR_enable_alb}") |"
  echo "| Instance type | \`${TF_VAR_instance_type}\` |"
  echo
} >> "$GITHUB_STEP_SUMMARY"
