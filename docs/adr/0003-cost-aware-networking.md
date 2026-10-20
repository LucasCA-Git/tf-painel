# 0003 — Rede orientada a custo (NAT/ALB opcionais)

- **Status:** Aceita · **Data:** 2026-10-20

## Contexto
O padrão "de livro" (EC2 privada + NAT Gateway + ALB) custa ~US$ 50/mês parado por ambiente — inviável para laboratório. Ao mesmo tempo, o projeto quer demonstrar o desenho correto.

## Decisão
- `enable_nat_gateway` e `enable_alb` são variáveis booleanas, **desligadas por padrão**.
- Com NAT ligado, a EC2 vai para subnet **privada** sem IP público.
- Com NAT desligado, a EC2 vai para subnet **pública** com IP público apenas para saída (SSM, pacotes), **sem regra de entrada** alguma — exceto do security group do ALB quando ele existe.
- Acesso administrativo somente por SSM Session Manager (sem SSH, sem key pair).
- O dev é destruído toda noite por um workflow agendado.

Alternativas consideradas: VPC endpoints de interface para SSM (~US$ 22/mês, 3 endpoints) e NAT instance (fck-nat) — descartadas na v1 por custo e complexidade.

## Consequências
- ✅ Custo base próximo de zero (EC2 + IPv4 público).
- ✅ O mesmo código expressa o desenho de produção ao ligar as flags.
- ⚠️ Sem NAT a instância tem IP público; mitigado por SG sem ingress e IMDSv2.
