# 0001 — GitHub OIDC com duas roles (plan/apply)

- **Status:** Aceita · **Data:** 2026-10-20

## Contexto
O pipeline precisa de credenciais AWS. Access keys estáticas em secrets vazam, não expiram e não diferenciam quem pode ler de quem pode alterar.

## Decisão
Usar o provedor OIDC do GitHub com **duas roles**:
- `tf-painel-gha-plan` — leitura (`ReadOnlyAccess`) + leitura do state; escrita **apenas** nos arquivos `*.tflock` (lock). Um PR não consegue alterar nem apagar o state. Trust: `repo:<owner>/tf-painel:pull_request` e `repo:<owner>/tf-painel:ref:refs/heads/main`.
- `tf-painel-gha-apply` — permissões de escrita restritas ao que os módulos criam. No IAM, só cria roles `tf-painel-{dev,prod}-*` **com o permissions boundary** `tf-painel-workload-boundary` (teto: SSM + flow logs), e tem *Deny* explícito sobre as roles `tf-painel-gha-*` e sobre remoção de boundary — fecha o caminho de escalada "criar role admin e assumi-la". Trust: **somente** `repo:<owner>/tf-painel:environment:dev|prod`.

Como o claim `sub` muda para `environment:<nome>` quando o job declara `environment:`, só jobs atrelados a um GitHub Environment (e, em prod, aprovados) conseguem assumir a role de escrita.

## Consequências
- ✅ Zero segredos AWS no GitHub; credenciais de 1h.
- ✅ Um PR malicioso consegue no máximo *ler* a conta.
- ⚠️ O claim de environment não carrega a branch: os Environments `dev` e `prod` devem ter *deployment branch policy* restrita à `main` (passo do README).
- ⚠️ `ec2:*` e `elasticloadbalancing:*` são limitados por região, não por tag. Aceitável numa conta dedicada ao laboratório; em conta compartilhada, restringir por `aws:ResourceTag/Project`.
- ⚠️ `ReadOnlyAccess` ainda lê muito (ex.: objetos S3). Aceitável numa conta pessoal de laboratório; em produção real, usar política de leitura sob medida.
