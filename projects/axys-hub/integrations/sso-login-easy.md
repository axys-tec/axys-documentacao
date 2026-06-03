# SSO Hub → Easy — contrato de login (o que o AxysHub deve entregar)

**Status:** 🟡 Contrato para implementação no Hub
**Padrão:** AXYS-ADR-021 (SSO via JWT entre Hub e aplicações)
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
| `role` | string (`user`/`admin`/`owner`) | papel do usuário | ✅ |
| `is_staff` | boolean | time interno Axys (acesso total) | ✅ |
| `apps_licenciadas` | array de slugs | apps que o tenant pode acessar | ✅ |
| `iat` | int (unix) | emissão | ✅ |
| `exp` | int (unix) | expiração — **TTL 8h** | ✅ |

Exemplo:

```json
{
  "sub": "550e8400-e29b-41d4-a716-446655440000",
  "email": "rodrigo@axys-tec.com.br",
  "name": "Rodrigo Dias",
  "tenant_uuid": "9f1c...-uuid",
  "tenant_code": "AXYS",
  "tenant_name": "Axys Tecnologia",
  "role": "owner",
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

## 4. Regras de negócio que o Easy aplica sobre as claims

Definem se o usuário **entra** ou cai em `/sem-contrato`:

1. O Easy só considera apps cujo slug **começa com `easy`**
   (`backend/modules/pages/routes.py`).
2. Acesso liberado se `is_staff == true` **OU** houver ≥1 app `easy-*` em
   `apps_licenciadas`. Caso contrário → redireciona para `/sem-contrato`.
3. Autorização por app específico via `apps_licenciadas`
   (`backend/core/security.py`, `require_app`).

### 4.1 ⚠️ Inconsistência de slugs a reconciliar

Há divergência **dentro do próprio Easy** entre dois pontos do código. O Hub precisa
emitir os slugs canônicos, então é preciso fechar a lista oficial antes:

| Conceito | `_DEV_CLAIMS` (security.py) | `_APP_LABELS` (pages/routes.py) |
|---|---|---|
| CPU | `easy-cpu` | `easy-cpu` ✅ |
| Price | `easy-price-1` | `easy-price-1` ✅ |
| Price+ | `easy-price-2` | `easy-price-2` ✅ |
| Orça | `easy-orca` | `easy-orca` ✅ |
| Docs | `easy-docs` | `easy-docs` ✅ |
| PM | `easy-pm` | `easy-pm` ✅ |
| Diário | `easy-diary` | `easy-build-diary` ❌ |
| Financeiro | `easy-fin` | `easy-fin-control` ❌ |
| Licitação | `easy-licit` | `easy-licit-plan` ❌ |

**Ação:** definir a lista oficial de slugs (Hub + Easy) e o Hub emitir exatamente ela.

---

## 5. ⚠️ Ponto em aberto — o "handshake" (decisão Hub + Easy)

Esta é a parte que **ainda não está implementada** no Easy para produção e que mais
depende do Hub. Hoje o Easy:

- valida token vindo do **cookie `easy_token`** (httpOnly) ou do header
  `Authorization: Bearer` (`backend/core/security.py`);
- possui um formulário de login local (`POST /login`, `backend/modules/pages/routes.py`)
  que é **dev-only** (HS256 batendo direto no banco do Hub) — **não serve para produção**.

Falta definir **como o Hub entrega o token ao navegador no domínio do Easy**.
Duas abordagens viáveis:

### Opção A — Redirect com callback (recomendada)
Usuário autentica no Hub → Hub redireciona para
`https://easy.axys-tec.com.br/sso/callback?token=<jwt>` → o Easy valida e seta o
cookie `easy_token` httpOnly e redireciona para `/main`.
- **Prós:** desacoplado; o Easy controla o próprio cookie; funciona mesmo se os
  domínios não forem irmãos.
- **Requer:** Easy implementar `/sso/callback` (não existe hoje) + Hub fazer o redirect.

### Opção B — Cookie de domínio compartilhado
Hub e Easy ambos sob `.axys-tec.com.br`; o Hub seta o cookie `easy_token` no domínio
pai e o Easy só lê.
- **Prós:** mais simples; próximo do código atual (o Easy já lê `easy_token`).
- **Requer:** alinhar nome do cookie (`easy_token`) e flags (httpOnly, `secure`,
  `samesite=lax`), e configurar `EASY_COOKIE_DOMAIN=.axys-tec.com.br`
  (`backend/core/runtime_config.py`). Acopla o Hub ao nome do cookie do Easy.

> **Decisão necessária:** A ou B. Recomendação: **A** (menor acoplamento).

---

## 6. Logout e revogação

- Logout no Easy é **client-side** (descarta cookie `easy_token`):
  `backend/modules/auth/routes_auth.py` (`/auth/logout`) e
  `backend/modules/pages/routes.py` (`/login/logout`).
- Como o token é self-contained e válido até `exp` (8h), **não há revogação imediata**
  (ADR-021 §6.2). Para logout forçado / bloqueio, o Hub precisaria de uma **blacklist**
  e de um endpoint que o Easy consulte — isso **não existe hoje** no Easy e seria
  trabalho adicional dos dois lados.

---

## 7. Variáveis de ambiente do Easy (referência)

Definidas em `backend/core/runtime_config.py`:

| Variável | Default | Função |
|---|---|---|
| `EASY_ENV` | `development` | `development` / `production` |
| `EASY_JWT_ALGORITHM` | `RS256` | algoritmo de validação |
| `EASY_JWT_SECRET` | `` | segredo HS256 (dev only) |
| `HUB_BASE_URL` | `http://localhost:8000` | base do Hub p/ JWKS |
| `EASY_COOKIE_DOMAIN` | `null` | domínio do cookie (handshake Opção B) |
| `EASY_AUTH_BYPASS` | `false` | bypass de auth (dev only; bloqueado em produção) |

> Os nomes corretos são os `EASY_*` / `HUB_BASE_URL` acima — **não** `HUB_URL`,
> `JWT_SECRET`, `HUB_PUBLIC_KEY` como apareciam em docs antigos.

---

## 8. Checklist para o Hub

- [ ] Expor `GET /.well-known/jwks.json` (RS256, com `kid`; manter pública antiga ≥1h na rotação).
- [ ] Assinar JWT em **RS256**, TTL **8h**, com **todas as claims** da seção 3 (nomes exatos).
- [ ] (Recomendado) incluir `iss` e `aud`.
- [ ] Emitir `apps_licenciadas` com os **slugs canônicos** (fechar a inconsistência da seção 4).
- [ ] Garantir `is_staff` e/ou ≥1 app `easy-*` para quem deve entrar.
- [ ] **Definir o handshake (seção 5)** — A ou B — e combinar a implementação dos dois lados.
- [ ] (Futuro) revogação/blacklist se logout forçado for requisito.
