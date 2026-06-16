# Seed inicial (dev) — Tenants, Users, Vínculos e Licenças

**Data:** 2026-06-14 · **Onde aplica:** **banco do HUB** (tenants/users/vínculos/licenças vivem no
Hub; o Easy só lê via JWT). **Status:** spec para o time do Hub semear; o Easy já lê o resultado
(molde novo `licencas` — `EASY_HUB_LICENCIAMENTO.md` §7).

> Objetivo: sem esses vínculos/licenças o Easy não mostra nada (a porteira e os cards dependem do
> que o Hub assina). Lunalo **não** é tocado por ora.

## Tenants

| Tenant | UUID | Natureza |
|---|---|---|
| **AXYS**  | `7847231a-4ba3-5138-b2d6-6943beb8e3f9` | interno (Axys) — dogfood + modelos |
| **DCENG** | `d47aef9a-299d-5b8a-9fa2-b58a6050a4b0` | cliente |
| Lunalo | (não mexer) | — |

## Users

| User | UUID |
|---|---|
| **Renan** | `a40bdb6c-c47b-5ad0-bb36-8c89641005e7` |
| **Thais** | `279ae6ae-52e1-52e0-ad90-df80cbf5cd1b` |
| **D&C**   | `733fa25d-157e-596f-9f86-4ad8db423881` |

## Vínculos (hub_user_tenant: user × tenant × role)

> **Convenção (porteira):** `is_staff` = role começa com **`internal_`**. Cliente = `owner|admin|user`.

| User | Tenant | role | is_staff | Sentido |
|---|---|---|---|---|
| Renan | AXYS  | `internal_owner` | **true**  | permissão máxima (interno) |
| Thais | AXYS  | `internal_user`  | **true**  | user no interno |
| Renan | DCENG | `owner`          | false | admin/owner (cliente) |
| Thais | DCENG | `admin`          | false | admin (cliente) |
| D&C   | DCENG | `user`           | false | user simples (cliente) |

- **AXYS:** vincula **Renan + Thais** (interno).
- **DCENG:** **exclusivamente cliente** — Renan (owner), Thais (admin), D&C (user). Sem papéis internos.

## Licenças (hub_microapp_instance: tenant × app × plano × status)

**Ambos** os tenants (AXYS e DCENG) recebem **todos os apps `easy-*` em `unlimited` / `ACTIVE`**
(por ora). Códigos canônicos (`EASY_HUB_LICENCIAMENTO.md` §7.1):

```
easy-price-1 · easy-price-2 · easy-cpu · easy-orca · easy-docs
easy-pm · easy-build-diary · easy-fin-control · easy-licit-plan
```
Cada um: `plano=unlimited`, `status=ACTIVE`, `periodo_fim` = renovação mensal.

> **Resultado esperado no Easy:**
> - Login em **AXYS** (Renan/Thais) → `is_staff=true` → **home única** + porta **"Catálogo (Axys)"** +
>   9 cards ACTIVE.
> - Login em **DCENG** (Renan/Thais/D&C) → `is_staff=false` → **home única** (sem porta de catálogo) +
>   9 cards ACTIVE.
> - O `tenant_uuid` do token isola os dados (`ativo.*`).

## O que o Easy já faz (pronto)
- Lê o molde novo `licencas` (+ fallback do antigo) e roteia: `_licencas_from_claims` / `_user_ctx`
  (`backend/modules/pages/routes.py`); `licensed_apps` / `require_app` (`backend/core/security.py`).
- Porteira: home única p/ todos; `is_staff` acende "Catálogo (Axys)".
- `_DEV_CLAIMS` (bypass) já no molde novo p/ teste local.
