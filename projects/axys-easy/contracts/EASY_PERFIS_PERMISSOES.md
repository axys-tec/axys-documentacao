# Perfis e Permissões no Easy

**Data:** 2026-06-14 · Companheiro de `EASY_HUB_LICENCIAMENTO.md` (claims §7.0) e
`next-steps/PLANO_CLIENTE.md` (porteira). **Status:** doutrina — gate interno **JÁ implementado** (`core/permissions.py`).

> **Fronteira:** o Easy **não faz** billing, assentos (seats), vínculo de user↔app nem edição de
> perfis — **tudo isso é do Hub**. O Easy **recebe credenciais** e **o que o user pode acessar**, e
> só **interpreta** isso para liberar tela/ação.

## 1. O que o Easy lê do token

| Claim | Uso no Easy |
|---|---|
| `is_staff` | **porteira** (acende o back-office "Catálogo (Axys)") |
| `licencas` | **apps que ESTE user pode abrir** — o Hub já resolve `licença-do-tenant ∩ vínculo-do-user`. O Easy mostra o que vier (ex.: user com Price e sem Orça → token só traz Price). |
| `role` | **só pesa no internal** (catálogo). No client é ignorado para features. |
| `tenant_uuid` | raiz de isolamento dos dados (`ativo.*`) |

## 2. Client (produtos) — **role-agnóstico**

owner / admin / user se comportam **igual** dentro dos produtos. Acesso = os apps em `licencas`.
Não há camada de permissão de feature por role no client.

- Poderes de owner/admin (**comprar mais, gerir assentos, vincular user a app, editar perfis**) são
  **do portal Hub**, não do Easy. (No Hub, o user comum cai num dashboard "teletransporte" + seus
  próprios dados.)
- Logo, no Easy **não** se programa distinção owner/admin/user no client. Só "tem o app? entra."

## 3. Internal (catálogo / back-office) — **3 níveis**

Aqui o `role` importa. Convenção: roles internos começam com `internal_` (→ `is_staff=true`).

| Ação no catálogo | `internal_user` | `internal_admin` | `internal_owner` |
|---|:---:|:---:|:---:|
| VER/consultar (listagens, formulários, viewer de docs, históricos, status de import) | ✅ | ✅ | ✅ |
| ESCREVER — criar/editar/inativar/reativar insumos·composições·fontes-base·edições; preços, LS, equivalências, itens; **disparar import**; **publicar** edição | — | ✅ | ✅ |
| **Reabrir** edição publicada | — | — | ✅ |

- **user** = leitura (acompanha/consulta). **admin** = toda a escrita + publica. **owner** = + **reabre**.
- **Decisão Renan (2026-06-14):** no back-office o **user é read-only**; a escrita ("mão na massa") é do **admin**.

## 4. Como está implementado (JÁ existe — não é TODO)

- `backend/core/permissions.py`: `exige_internal_user` (is_staff) · `exige_internal_admin` (is_staff +
  role∈{admin,owner}) · `exige_internal_owner` (is_staff + role=owner). `_role` normaliza `internal_*`
  (ex.: `internal_admin`→`admin`). Há também `exige_client_*` (espelho p/ o client).
- Rotas do catálogo (`backend/modules/catalogo/routes.py`) já aplicam:
  - **GET** (listagens/forms/consultas/viewer/status) → `exige_internal_user`.
  - **POST** mutações (CRUD insumo·composição·fonte·edição, preços, LS, equivalências, itens,
    import SINAPI/CDHU, **publicar**) → `exige_internal_admin`.
  - **reabrir** edição → `exige_internal_owner`.
- **Client: sem** gate por role — só `require_app`/licença (role-agnóstico).
- **Nenhuma** rota do catálogo usa `require_auth` solto → client **não** acessa o back-office.

## 5. Assentos por assinatura (referência — é do Hub, não do Easy)

O Hub trava o nº de usuários por plano (o Easy **não** valida isso):

| Plano | Usuários |
|---|---|
| single | 1 (owner only — sem editar perfis) |
| starter | 2 (owner + user — sem editar perfis) |
| advanced | 4 (owner + 1 admin + 2 users **ou** owner + 3 users) |
| unlimited | 5 (owner + 1 admin + 3 users **ou** owner + 4 users) |
| 5+ | só no unlimited + billing específico |

## 6. A confirmar com o Hub

- **`licencas` = apps EFETIVOS do user** (tenant ∩ vínculo-do-user), não só do tenant — o Easy
  depende disso para mostrar o conjunto certo por usuário.
- Valores de `role` exatos (`internal_owner|internal_admin|internal_user` · `owner|admin|user`).
