# AxysEasy ← → AxysHub

**Status:** 🟢 Ativa (SSO via JWT — handshake A2)
**Padrão:** AXYS-ADR-021 (SSO) · ADR-029 (foundation)
**Fonte de verdade do contrato SSO:** [`docs/projects/axys-hub/integrations/sso-login-easy.md`](../../axys-hub/integrations/sso-login-easy.md)
**Fonte de verdade do domínio comercial/analytics:** [`docs/projects/axys-hub/contract/axys_mkt_analytics.md`](../../axys-hub/contract/axys_mkt_analytics.md)

> Este documento descreve a integração **do lado Easy**. O contrato SSO em si vive no repo
> do Hub (link acima) e vale sobre qualquer divergência. Aqui só refletimos o que o Easy
> implementa de fato (validado contra o código em `backend/`).

---

## Princípio (ADR-021)

O **Easy NUNCA emite token.** Ele apenas **valida** JWTs assinados pelo Hub, **localmente**
(assinatura + `exp` via chave pública do JWKS do Hub — sem chamar o Hub a cada request).
Autenticação é centralizada no Hub; autorização é descentralizada e *offline-first*.

Código: `backend/core/security.py` — *"O AxysEasy NUNCA emite tokens. Apenas valida JWTs assinados pelo AxysHub."*

---

## Handshake A2 — authorization code + exchange (vigente)

O modelo antigo de **token na URL** (`easy...?token=...`) está **superado**. O fluxo real é
*authorization code* (OIDC-like): o JWT **nunca** trafega pela URL/logs.

```
1. User → easy.axys-tec.com.br/<algo>   (sem cookie easy_token válido)
   Easy 302 → {HUB_BASE_URL}/login?app=easy&redirect_uri=.../sso/callback&state=<state>

2. Hub autentica o usuário (login próprio do Hub) e gera um CODE de uso único (TTL 60–120s)

3. Hub 302 → easy.axys-tec.com.br/sso/callback?code=<code>&state=<state>

4. Easy (server-to-server, sem browser):
     POST {HUB_BASE_URL}/auth/exchange  (client credentials EASY_HUB_CLIENT_ID/SECRET)
     → recebe o JWT (RS256), valida via JWKS, seta cookie easy_token (httpOnly,
       secure em prod, samesite=lax, host-only), 302 → /main
```

Implementação no Easy:
- `backend/modules/auth/routes_sso.py` — `GET /sso/login` (gera `state`, redireciona pro Hub)
  e `GET /sso/callback` (valida `state`, faz o exchange, valida o JWT, seta o cookie).
- `backend/core/runtime_config.py` — `hub_base_url()`, `hub_exchange_url()`,
  `EASY_HUB_CLIENT_ID` / `EASY_HUB_CLIENT_SECRET`.
- `backend/core/security.py` — validação JWT via **JWKS** (cache 1h), RS256 em prod.

---

## JWT Claims recebidos do Hub

Nomes exatos que o Easy lê (contrato completo na seção 3 do `sso-login-easy.md`):

```json
{
  "sub": "550e8400-e29b-41d4-a716-446655440000",
  "email": "renan@axys-tec.com.br",
  "name": "Renan Dias",
  "tenant_uuid": "9f1c...-uuid",
  "tenant_code": "AXYS",
  "tenant_name": "Axys Tecnologia",
  "role": "owner",              // user | admin | owner (papel normalizado)
  "tenant_role": "internal_owner", // papel exato do vínculo no Hub
  "is_staff": true,
  "apps_licenciadas": ["easy-cpu", "easy-price-1", "easy-orca"],
  "iat": 1748908800,
  "exp": 1748937600             // TTL 8h
}
```

Consumo: `backend/modules/pages/routes.py` (`_user_ctx`), validação em `backend/core/security.py` (`decode_token`).

> **Slugs canônicos pendentes:** há divergência interna no Easy entre `_DEV_CLAIMS`
> (security.py) e `_APP_LABELS` (pages/routes.py) — ex.: `easy-diary` vs `easy-build-diary`,
> `easy-fin` vs `easy-fin-control`, `easy-licit` vs `easy-licit-plan`. Fechar a **lista oficial
> Hub+Easy** antes de o Hub emitir (ver §4.1 do `sso-login-easy.md`). **Decisão humana pendente.**

---

## Regras de acesso (entra ou cai em `/sem-contrato`)

1. Só conta app cujo slug **começa com `easy`** (`backend/modules/pages/routes.py`).
2. Acesso liberado se houver ≥1 app `easy-*` em `apps_licenciadas` (ou contexto `is_staff`);
   caso contrário → `/sem-contrato`.
3. Gate por app específico via `apps_licenciadas` (`backend/core/security.py`, `require_app`).

---

## Logout

Logout no Easy é **client-side** (descarta o cookie `easy_token`) —
`backend/modules/auth/routes_sso.py` / `backend/modules/pages/routes.py`.
Como o token é self-contained e válido até `exp`, **não há revogação imediata** (ADR-021 §6.2);
logout forçado dependeria de blacklist no Hub (não existe hoje). Ver **Design de referência** abaixo.

---

## Auditoria de login — `origem = 'SSO'`

Cada login federado grava rastro **nos dois lados**, com origem explícita:
- **Easy:** no aceite do token, `audit.login_logs` com `log_origem = 'SSO'`
  (`backend/modules/auth/routes_sso.py` → `audit_service.registrar_login`).
- **Hub:** `hub_login_log` com `origem = 'SSO'`.

`'SSO'` é valor canônico — não reaproveitar `LOCAL`/`API_KEY`.

---

## Hub como porta pública / origem de jornada comercial

O Hub (site público `www.axys-tec.com.br`) é a **porta de entrada comercial** do ecossistema:
hero, CTAs (incl. **"Explorar AxysEasy"**), modais de produto, planos, form de contato e signup.

**O Easy NÃO é uma superfície de aquisição isolada.** Consequências para o Easy:

- **Analytics público, captura de interesse, `commercial.lead` e o vínculo
  `analytics.identity_link` (visitor → lead → user → tenant) são domínio do HUB**, capturados na
  landing pública e persistidos no **banco do Hub** (schema `analytics.*` / `commercial.*`).
  Ver `contract/axys_mkt_analytics.md`.
- O Easy **não coleta analytics de marketing nem cria/gerencia leads** (V1). Não criar modelo
  paralelo no Easy — o "nascimento" do interesse comercial acontece no Hub.
- Um visitante pode chegar ao Easy **já vindo de contexto comercial do Hub** (clicou "Explorar
  AxysEasy"). Na prática isso é transparente para o Easy: sem cookie válido → redireciona pro SSO;
  a continuidade visitor↔identidade é resolvida **no Hub, no momento da conversão** (SSO / criação
  de conta), onde o Hub conhece tanto o `visitor_id` (cookie do site) quanto o `user`/`tenant`.
- Qualquer propagação de `visitor_id`/contexto comercial para dentro do Easy só entraria se o
  **contrato do Hub** passar a exigir — hoje **não exige**. **Não inferir/inventar.**

---

## Multitenancy

Uma pessoa pode ter acesso a **múltiplos tenants**, mas o token carrega **um** `tenant_uuid`.
O Easy usa esse tenant para filtrar dados, validar permissões e segregar orçamentos.

---

## Configuração (vars do Easy)

Definidas em `backend/core/runtime_config.py` — os nomes corretos são `EASY_*` / `HUB_BASE_URL`
(**não** `HUB_URL`/`HUB_AUTH_URL`/`JWT_SECRET`/`HUB_PUBLIC_KEY`, que apareciam em docs antigos):

| Variável | Default | Função |
|---|---|---|
| `EASY_ENV` | `development` | `development` / `production` |
| `EASY_JWT_ALGORITHM` | `RS256` | algoritmo de validação |
| `EASY_JWT_SECRET` | `` | segredo HS256 (**dev only**) |
| `HUB_BASE_URL` | `http://localhost:8000` | base do Hub p/ JWKS, `/login` e `/auth/exchange` |
| `EASY_HUB_CLIENT_ID` | — | client id do Easy no exchange (A2) — emitido pelo Hub |
| `EASY_HUB_CLIENT_SECRET` | — | client secret do Easy no exchange (A2) — emitido pelo Hub |
| `EASY_AUTH_BYPASS` | `false` | bypass de auth (**dev only**; bloqueado em produção) |

JWKS: `GET {HUB_BASE_URL}/.well-known/jwks.json` (RS256, cache 1h no Easy). Se o JWKS cair,
o Easy responde **503** em rotas autenticadas (dependência dura).

---

## TODO

- [ ] Fechar lista canônica de slugs Hub+Easy (decisão humana).
- [ ] Refresh token automático → ver **Design de referência** abaixo.
- [ ] Endurecer validação com `iss`/`aud` (Hub emitir; Easy hoje decodifica com `verify_aud=False`).
- [ ] (Futuro) revogação/blacklist se logout forçado virar requisito.

## Design de referência — lifecycle de token (resgatado do ADR-029, 2026-05-23)

> O handshake **já é A2** (`code → exchange`) — o design abaixo aproveita **apenas o ciclo de
> vida do token** (refresh/revoke), não o handshake. Ver [[reference_sso_hub_prod]].

**Vidas de token:**
- **Access token**: alvo de vida curta (o contrato atual usa **TTL 8h**; o design de refresh
  miraria ~1h) — assinado RS256, validado localmente via JWKS, sem chamar o Hub.
- **Refresh token**: vida máxima **30 dias**, renovação por uso (**sliding window**).

**Revogação amarrada ao cancelamento de assinatura** (resolve "tenant deactivated" sem webhook):
no cancelamento, o **Hub invalida o refresh token imediatamente**; o access token **expira
naturalmente**. Sem blacklist distribuída para o caso comum.

**Pré-condição no AxysHub** (refatoração — executar quando o Easy for integrar o refresh):

| Componente (Hub) | Mudança |
|---|---|
| `POST /auth/refresh` | renovação de access via refresh token |
| `POST /auth/revoke` | revogação de refresh token (acionada no cancelamento) |
| `GET /.well-known/jwks.json` | expor chave pública p/ o Easy validar sem redeploy |
| Banco do Hub | tabela de refresh tokens com flag de revogação |
