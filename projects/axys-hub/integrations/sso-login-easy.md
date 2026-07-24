# SSO Hub → Easy — contrato de login (o que o AxysHub deve entregar)

**Status:** 🟡 Contrato para implementação no Hub
**Padrão:** AXYS-ADR-021 (SSO via JWT entre Hub e aplicações)
**Handshake:** ✅ **Decidido — Opção A2 (authorization code + exchange)** — ver seção 5
**Origem:** levantado a partir do código real do AxysEasy (paths abaixo são do repo `axys-easy`)
**Escopo:** login de usuário em `easy.axys-tec.com.br` via SSO do AxysHub

> Este documento substitui, como fonte de verdade do contrato SSO, as descrições
> parciais/desatualizadas em `integrations/with-easy.md`. Em caso de divergência,
> vale o que está aqui (validado contra o código).

---

## 1. Princípio (ADR-021)

O **Easy NUNCA emite token**. Ele apenas **valida** JWTs assinados pelo Hub.
Autenticação é centralizada no Hub; autorização é descentralizada e *offline-first*
(o Easy valida localmente, sem chamar o Hub a cada request).

Referência: `backend/core/security.py` — *"O AxysEasy NUNCA emite tokens. Apenas valida JWTs assinados pelo AxysHub."*

> ⚠️ Os docs antigos diziam que o Easy chama o Hub para validar e que o Hub
> "retorna claims". **Isso está errado.** A validação é local (assinatura + `exp`)
> usando a chave pública do Hub obtida via JWKS.

---

## 2. O que o Hub precisa expor

### 2.1 Endpoint JWKS (chave pública)

```
GET {HUB_BASE_URL}/.well-known/jwks.json
```

- Construção da URL no Easy: `backend/core/runtime_config.py` (`hub_jwks_url`).
- Resposta: um **JWKS** padrão (RFC 7517) com a(s) chave(s) pública(s) RS256.
- O Easy **cacheia por 1h** (`backend/core/security.py`, `_JWKS_TTL = 3600`).
- **Rotação de chave:** use `kid` nos tokens e no JWKS. Ao rotacionar a privada,
  mantenha a pública anterior no JWKS por pelo menos 1h (idealmente até expirar
  todos os tokens — 8h), senão tokens em voo são invalidados.
- **Criticidade:** se o JWKS cair, o Easy responde **503** em todas as rotas
  autenticadas. É dependência dura.

### 2.2 Algoritmo de assinatura

- **Produção: RS256** (assimétrico). Hub assina com a privada; Easy valida com a
  pública do JWKS. Nenhum segredo compartilhado.
- HS256 existe **só para dev local** (segredo compartilhado `EASY_JWT_SECRET`) e
  **não deve** ser usado em produção.

---

## 3. Contrato do token (claims)

Claims que o Easy **lê e usa**. O Hub deve emitir todas com **estes nomes exatos**:

| Claim | Tipo | Uso no Easy | Obrigatória |
|---|---|---|---|
| `sub` | string (UUID) | id do usuário (auditoria) | ✅ |
| `email` | string | identificação / exibição | ✅ |
| `name` | string | exibição | ✅ |
| `tenant_uuid` | string (UUID) | tenant atual (multitenancy) | ✅ |
| `tenant_code` | string | código curto do tenant | ✅ |
| `tenant_name` | string | exibição do tenant | ✅ |
| `role` | string (`user`/`admin`/`owner`) | papel normalizado para compatibilidade | ✅ |
| `tenant_role` | string (`internal_*`/cliente) | papel exato do vínculo no Hub | ✅ |
| `is_staff` | boolean | time interno Axys (acesso total) | ✅ |
| `apps_licenciadas` | array de slugs | apps efetivas do usuário atual (`tenant ∩ vínculo`) | ✅ |
| `iat` | int (unix) | emissão | ✅ |
| `exp` | int (unix) | expiração — **TTL 8h** | ✅ |

Exemplo:

```json
{
  "sub": "550e8400-e29b-41d4-a716-446655440000",
  "email": "renan@axys-tec.com.br",
  "name": "Renan Dias",
  "tenant_uuid": "9f1c...-uuid",
  "tenant_code": "AXYS",
  "tenant_name": "Axys Tecnologia",
  "role": "owner",
  "tenant_role": "internal_owner",
  "is_staff": true,
  "apps_licenciadas": ["easy-cpu", "easy-price-1", "easy-orca"],
  "iat": 1748908800,
  "exp": 1748937600
}
```

Consumo no Easy: `backend/modules/pages/routes.py` (`_user_ctx`),
`backend/modules/auth/routes_auth.py`; validação em `backend/core/security.py`
(`decode_token`).

> **`iss` / `aud`:** hoje o Easy decodifica com `verify_aud=False` e **não** valida
> `iss`/`aud`. Funciona sem essas claims, mas recomendamos o Hub já emitir
> `iss` (ex.: `https://hub.axys-tec.com.br`) e `aud` (ex.: `easy`) para
> endurecermos a validação depois sem quebrar compatibilidade.

---

## 4. Regras de integração que o Easy aplica sobre as claims

Definem se o usuário **entra** ou cai em `/sem-contrato`:

1. O Easy só considera apps cujo slug **começa com `easy`**
   (`backend/modules/pages/routes.py`).
2. Acesso liberado se houver ≥1 app `easy-*` em `apps_licenciadas`.
   `is_staff` continua útil para contexto interno, mas não substitui o vínculo efetivo
   do usuário às apps. Caso contrário → redireciona para `/sem-contrato`.
3. Gate de acesso por app específico via `apps_licenciadas`
   (`backend/core/security.py`, `require_app`).

> O que cada `role`/`tenant_role` pode fazer **dentro do Easy** não pertence a este documento do Hub.
> Essa matriz funcional deve morar no contrato e na implementação do próprio Easy.

### 4.1 Lista canônica de slugs — fechada em 2026-07-24

A lista oficial Hub + Easy está definida com base no código vigente do `axys-easy`.
O Hub deve emitir em produção exatamente estes slugs, sem formas curtas paralelas,
tanto em `apps_licenciadas` quanto em `licencas[].app`:

| Conceito | Slug canônico |
|---|---|
| CPU | `easy-cpu` |
| Price | `easy-price-1` |
| Price+ | `easy-price-2` |
| Orça | `easy-orca` |
| Docs | `easy-docs` |
| PM | `easy-pm` |
| Diário | `easy-build-diary` |
| Financeiro | `easy-fin-control` |
| Licitação | `easy-licit-plan` |

Decisão registrada por Renan em `2026-07-24`.

Regra prática:

- não emitir `easy-diary`;
- não emitir `easy-fin`;
- não emitir `easy-licit`;
- não manter apelidos paralelos no catálogo de licenças do Hub.

---

## 5. ✅ Handshake — Opção A2 (authorization code + exchange) — DECIDIDO

Decidido entre Hub e Easy: **redirect com código de uso único + troca server-to-server**
(padrão *authorization code* do OIDC). Mantém cada app self-contained (ADR-021), o Easy
dono do próprio cookie, e o **JWT nunca trafega pela URL/logs**.

> Hoje o Easy ainda **não** tem essa implementação para produção: ele valida token de
> cookie `easy_token`/Bearer (`backend/core/security.py`) e tem um login local dev-only
> (`POST /login`). O `/sso/callback` e o cliente de exchange serão implementados no Easy.

### 5.1 Fluxo

```
1. User → https://easy.axys-tec.com.br/<algo>   (sem cookie easy_token válido)
   Easy 302 →
     {HUB_BASE_URL}/login?app=easy&redirect_uri=https://easy.axys-tec.com.br/sso/callback

2. Hub autentica o usuário (login próprio do Hub).

3. Hub gera um CODE de uso único e redireciona:
   302 → https://easy.axys-tec.com.br/sso/callback?code=<code>[&state=<state>]

4. Easy (server-to-server, sem browser):
   POST {HUB_BASE_URL}/auth/exchange
   → recebe o JWT (RS256), valida via JWKS, seta cookie easy_token (host-only), 302 → /main
```

### 5.2 O que o Hub precisa implementar

**(a) `GET /login`** — aceitar os parâmetros e, após autenticar, redirecionar para o
`redirect_uri` com o `code`:

| Param (entrada) | Descrição |
|---|---|
| `app` | slug da aplicação chamadora (`easy`). Permite ao Hub montar `apps_licenciadas` e validar o `redirect_uri`. |
| `redirect_uri` | URL de callback do Easy. **Deve ser validada contra allowlist** no Hub (evita open redirect). |
| `state` | (opcional, recomendado) string opaca anti-CSRF gerada pelo Easy; o Hub devolve igual no callback. |

**(b) `POST /auth/exchange`** — troca o `code` pelo JWT, server-to-server:

- **Request (JSON):** `{ "code": "<code>", "app": "easy" }`
- **Autenticação do cliente:** o Hub deve confirmar que quem chama é o Easy. Usar
  **client credentials por app** — header `Authorization: Basic base64(client_id:client_secret)`
  ou body `{ client_id, client_secret }`. O Hub emite ao Easy um `client_id`/`client_secret`
  (ver seção 7: `EASY_HUB_CLIENT_ID` / `EASY_HUB_CLIENT_SECRET`).
- **Response 200 (JSON):** `{ "token": "<jwt RS256>" }` (JWT conforme contrato da seção 3).
- **Erros:** `400` code inválido/expirado/já usado; `401` client credentials inválidas.

**(c) Propriedades do `code`:**

- **opaco e aleatório** (não é o JWT; é uma chave de lookup no Hub);
- **uso único** — invalidado no primeiro `exchange`;
- **TTL curto** — 60–120s;
- **vinculado** a `app` + `redirect_uri` + usuário/tenant emitidos no passo 2
  (o exchange só devolve o JWT correspondente àquele code).

### 5.3 O que o Easy implementa (lado axys-easy — não é tarefa do Hub)

- redireciona para `/login` quando não há `easy_token` válido (com `state`);
- `GET /sso/callback?code=&state=` → valida `state`, chama `POST /auth/exchange`,
  valida o JWT via JWKS, seta `easy_token` (httpOnly, `secure` em prod, `samesite=lax`,
  host-only), 302 → `/main`.

---

## 6. Logout e revogação

- Logout no Easy é **client-side** (descarta cookie `easy_token`):
  `backend/modules/auth/routes_auth.py` (`/auth/logout`) e
  `backend/modules/pages/routes.py` (`/login/logout`).
- Como o token é self-contained e válido até `exp` (8h), **não há revogação imediata**
  (ADR-021 §6.2). Para logout forçado / bloqueio, o Hub precisaria de uma **blacklist**
  e de um endpoint que o Easy consulte — isso **não existe hoje** no Easy e seria
  trabalho adicional dos dois lados.

### 6.1 Auditoria de login — `'SSO'` como origem canônica

Cada login federado deixa rastro **nos dois lados**, com a origem explícita:

- **Hub:** registra o evento em `hub_login_log` (`acao` = `LOGIN`/`LOGOUT`/`LOGIN_FALHA`,
  `origem` = **`'SSO'`**). Tabela em `docs/projects/axys-hub/schemas/schema.sql`, com
  `CHECK (origem IN ('LOCAL','SSO','GOV_BR','APPLE','GOOGLE','API_KEY'))`.
- **Easy:** registra no aceite do token em `audit.login_logs` (`log_origem` = **`'SSO'`**)
  via `backend/core/audit_service.py`.

`'SSO'` é **valor canônico e explícito** — não reaproveitar `LOCAL`/`API_KEY`, que
misturaria canais e degradaria a rastreabilidade. Um login SSO gera **dois registros**
(Hub na autenticação + Easy no aceite do token) — perspectivas distintas, esperado.

---

## 7. Variáveis de ambiente do Easy (referência)

Definidas em `backend/core/runtime_config.py`:

| Variável | Default | Função |
|---|---|---|
| `EASY_ENV` | `development` | `development` / `production` |
| `EASY_JWT_ALGORITHM` | `RS256` | algoritmo de validação |
| `EASY_JWT_SECRET` | `` | segredo HS256 (dev only) |
| `HUB_BASE_URL` | `http://localhost:8000` | base do Hub p/ JWKS, `/login` e `/auth/exchange` |
| `EASY_HUB_CLIENT_ID` | — | client id do Easy no exchange (A2) — emitido pelo Hub |
| `EASY_HUB_CLIENT_SECRET` | — | client secret do Easy no exchange (A2) — emitido pelo Hub |
| `EASY_AUTH_BYPASS` | `false` | bypass de auth (dev only; bloqueado em produção) |

> `EASY_HUB_CLIENT_ID`/`EASY_HUB_CLIENT_SECRET` ainda não existem no Easy — entram junto
> com a implementação do `/sso/callback`. O Hub precisa **emitir esse par** para o Easy.

> Os nomes corretos são os `EASY_*` / `HUB_BASE_URL` acima — **não** `HUB_URL`,
> `JWT_SECRET`, `HUB_PUBLIC_KEY` como apareciam em docs antigos.

---

## 8. Checklist para o Hub

- [ ] Expor `GET /.well-known/jwks.json` (RS256, com `kid`; manter pública antiga ≥1h na rotação).
- [ ] Assinar JWT em **RS256**, TTL **8h**, com **todas as claims** da seção 3 (nomes exatos).
- [ ] (Recomendado) incluir `iss` e `aud`.
- [ ] Emitir `apps_licenciadas` com os **slugs canônicos** da seção 4.1.
- [ ] Garantir `is_staff` e/ou ≥1 app `easy-*` para quem deve entrar.
- [x] ~~Definir o handshake~~ → **A2 (code + exchange)** decidido (seção 5).
- [ ] **`GET /login`** aceitar `app`, `redirect_uri` (com allowlist) e `state`; redirecionar com `?code=`.
- [ ] **`POST /auth/exchange`** trocar `code` (uso único, TTL 60–120s) pelo JWT, autenticando o client.
- [ ] **Emitir `client_id`/`client_secret`** para o Easy usar no exchange.
- [ ] **Registrar login/logout em `hub_login_log`** com `origem = 'SSO'` (seção 6.1).
- [ ] (Futuro) revogação/blacklist se logout forçado for requisito.
