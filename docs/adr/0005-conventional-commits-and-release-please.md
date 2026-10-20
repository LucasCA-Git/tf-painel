# 0005 — Conventional Commits + release-please

- **Status:** Aceita · **Data:** 2026-10-20

## Contexto
Queremos histórico legível, versionamento semântico e CHANGELOG sem trabalho manual.

## Decisão
- Mensagens no padrão [Conventional Commits](https://www.conventionalcommits.org/), validadas por commitlint no PR (todos os commits) e localmente por hook `commit-msg` do pre-commit.
- [release-please](https://github.com/googleapis/release-please) abre um *Release PR* acumulando as mudanças; ao fazer merge, cria tag `vX.Y.Z` e GitHub Release.
- Autoria: os commits do projeto são feitos apenas por Lucas Cardoso Alecrim. O release-please usa o secret opcional `RELEASE_PLEASE_TOKEN` (PAT fine-grained do próprio autor) para que o Release PR também saia em seu nome e dispare os checks; sem ele, cai no `GITHUB_TOKEN` (autor `github-actions[bot]`).
- Dependabot **não** é habilitado, para manter o histórico com autor único; atualizações de versão são feitas manualmente com `chore(deps):`.

## Consequências
- ✅ Versão e CHANGELOG derivados do histórico.
- ⚠️ Disciplina obrigatória no formato das mensagens (o CI barra).
