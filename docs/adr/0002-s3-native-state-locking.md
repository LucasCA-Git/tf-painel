# 0002 — Lock nativo do S3 no lugar de DynamoDB

- **Status:** Aceita · **Data:** 2026-10-20

## Contexto
Historicamente o backend S3 exigia uma tabela DynamoDB para lock. Desde o Terraform 1.10 (e OpenTofu 1.10) o backend suporta `use_lockfile = true`, usando escrita condicional no próprio S3; o lock via DynamoDB está depreciado.

## Decisão
Usar `use_lockfile = true`, sem DynamoDB.

## Consequências
- ✅ Um recurso a menos para criar, pagar e dar permissão.
- ✅ Alinhado com a direção oficial do backend.
- ⚠️ Exige Terraform ≥ 1.10 (`required_version`).
