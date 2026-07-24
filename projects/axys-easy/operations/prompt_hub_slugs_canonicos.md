# Prompt para o AxysHub — lista canônica de slugs de app (Hub ↔ Easy)

> **Origem:** repositório `axys-easy` (código = fonte canônica dos slugs).
> **Decisão:** Renan, 2026-07-24 — as 9 formas longas abaixo são oficiais.
> **Simétrico a** `docs/projects/axys-hub/operations/claude_prompt_update_easy.md`.

---

## Contexto

Quando um usuário faz login, o Hub emite no JWT a lista de apps licenciadas:

```json
"apps_licenciadas": ["easy-cpu", "easy-price-1", "easy-orca", ...]
```

O Easy compara esses slugs **literalmente** para liberar/trancar cada app
(`backend/core/security.py` → `require_app`; `backend/modules/pages/routes.py` → navegação).
Se o Hub emitir um slug diferente do que o Easy espera, o app fica trancado para quem tem direito.

**Estado real do código do Easy (verificado em 2026-07-24):** os dois pontos do Easy que leem
slugs — `_DEV_CLAIMS` (`security.py:67-75`) e `_APP_LABELS` (`pages/routes.py:27-35`) — **já estão
idênticos e unificados nas formas longas**. Não há divergência interna no Easy. O que estava
desatualizado era a **tabela §4.1 do `sso-login-easy.md`** (que ainda listava formas curtas
`easy-diary`/`easy-fin`/`easy-licit` do lado Easy — isso não existe mais no código).

---

## Lista canônica (fonte de verdade)

O Hub deve emitir **exatamente** estes 9 slugs (nenhuma forma curta):

| Slug canônico | App | Abbr (nav Easy) |
|---|---|---|
| `easy-cpu` | Easy CPU | CPU |
| `easy-price-1` | Easy Price | PR1 |
| `easy-price-2` | Easy Price 2 | PR2 |
| `easy-orca` | Easy Orça | ORÇ |
| `easy-docs` | Easy Docs | DOC |
| `easy-pm` | Easy ProjectManager | PRJ |
| `easy-build-diary` | Easy BuildDiary (Diário de Obra) | DIA |
| `easy-fin-control` | Easy FinControl (Financeiro) | FIN |
| `easy-licit-plan` | Easy LicitPlan (Licitação) | LIC |

Regras que o Easy aplica sobre a lista (não mudam):
- só conta slug que **começa com `easy`**;
- acesso liberado com ≥1 app `easy-*` ACTIVE (ou contexto `is_staff`), senão `/sem-contrato`.

---

## O que o Hub precisa fazer

1. **Emitir os slugs canônicos no token de produção** — o `apps_licenciadas` (ou o molde novo
   `licencas: [{app, plano, status}]`) deve usar **exatamente** as 9 formas longas acima.
   Nenhuma forma curta (`easy-diary` / `easy-fin` / `easy-licit`) deve aparecer.

2. **Corrigir a tabela §4.1 do `sso-login-easy.md`** (repo `docs`, lado Hub): substituir as formas
   curtas do lado Easy pelas formas longas canônicas e remover o alerta de "inconsistência a
   reconciliar" (já reconciliada — o Easy está unificado). Trocar a linha "Ação: definir a lista
   oficial" por "✅ Lista oficial definida (ver tabela acima) — Renan, 2026-07-24".

3. **Garantir que o catálogo de produtos/licenças do Hub** (o que popula `apps_licenciadas`) use
   esses slugs como chave — sem apelidos paralelos.

---

## Validação (como saber que ficou certo)

- Um usuário com Diário/Financeiro/Licitação contratados recebe no token
  `easy-build-diary` / `easy-fin-control` / `easy-licit-plan` e **abre** esses apps no Easy
  (não cai em `/sem-contrato` nem fica trancado).
- `grep` no emissor do Hub não retorna `easy-diary`, `easy-fin`, `easy-licit` (formas curtas).
- `sso-login-easy.md §4.1` não lista mais divergência.

---

## Fora de escopo (não fazer)

- Não renomear os slugs para formas curtas — a decisão é pelas **longas**.
- Não tocar em `Gestor` nem em nada não-`easy-*`.
- Não alterar o handshake SSO (A2 já vigente) nem o contrato de analytics.
