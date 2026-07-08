# Redefinição de senha — handoff Easy → Hub

> **Decisão (Renan, 2026-06-13):** redefinição de senha **NÃO** é responsabilidade do
> AxysEasy. O Easy passará a **redirecionar** para o portal do Hub; este fluxo (telas +
> lógica) deve **migrar para o Hub**. Este documento descreve **como funciona hoje no
> Easy** (lógica, ferramentas, arquivos) para servir de base à reimplementação no Hub.
>
> Motivação: o Easy hoje **lê e escreve direto no banco do Hub** (`hub_user`,
> `hub_audit_log`, e mantém a tabela de sessão `easy_password_reset` no Hub DB) — isso
> tem que sair. O Hub deve ser dono do dado e do processo.

---

## 1. Como funciona hoje (fluxo completo)

MFA de **dois fatores**: **(1) link por e-mail** (JWT 15 min, uso único) + **(2) código
de 6 dígitos por WhatsApp** (5 min, máx. 3 tentativas).

```
/recuperar-senha (GET)            → tela: pede e-mail
/recuperar-senha (POST email)     → request_reset(email)
        │  lookup hub_user(email) → user_id, name, phone, is_active
        │  gera JWT (HS256, type=password_reset, sub=user_id, exp=15min)
        │  envia E-MAIL com link {APP_BASE}/recuperar-senha/<token>   (SMTP)
        ▼
/recuperar-senha/<token> (GET)    → valida JWT + uso único (token_hash) → tela "nova senha"
/recuperar-senha/<token> (POST)   → valida política de senha
        │  lookup hub_user.phone
        │  store_pending_change(): bcrypt(nova senha), gera código 6 díg.,
        │     grava linha em easy_password_reset (session_id, pw_hash, code_hash,
        │     token_hash, attempts=0, expires_at=5min)  ← TABELA NO HUB DB
        │  envia CÓDIGO por WhatsApp (Zapi)
        ▼  redireciona p/ /recuperar-senha/confirmar?sid=<session_id>
/recuperar-senha/confirmar (GET)  → tela: pede o código
/recuperar-senha/confirmar (POST) → confirm_code(sid, code)
        │  confere expiração + code_hash + tentativas (máx 3)
        │  UPDATE hub_user.password_hash = bcrypt(...)   ← ESCRITA NO HUB DB
        │  INSERT hub_audit_log (evento easy.user.password_reset)
        │  apaga a sessão; envia E-MAIL de confirmação
        ▼  redireciona p/ /login?msg=senha_redefinida
```

**Política de senha** (validada no Easy, `routes_reset._validate_password`): mínimo 8
caracteres, ≥1 maiúscula, ≥1 caractere especial, confirmação igual.

**TTLs / limites:** link 15 min (`_RESET_TTL_MIN`), código 5 min (`_CODE_TTL_MIN`),
3 tentativas (`_MAX_ATTEMPTS`).

---

## 2. Ferramentas / dependências usadas

| Função | Lib / serviço | Onde |
|---|---|---|
| Token do link (JWT HS256) | `python-jose` | assinado com `EASY_JWT_SECRET` |
| Hash da senha | `passlib[bcrypt]` (`bcrypt`) | `_pwd_ctx.hash()` |
| Hash de código/token (uso único) | `hashlib.sha256` | `_hash()` |
| E-mail (link + confirmação) | SMTP via `email_client.send_email` | Titan (`PUBLIC_SMTP_*`) |
| Código 2FA | WhatsApp via `zapi_client.send_text` | Z-API (`ZAPI_*`) |
| Banco | `hub_conn` (Postgres do Hub) | leitura+escrita (a remover) |

---

## 3. O que o Easy toca no BANCO DO HUB (tem que virar API/responsabilidade do Hub)

- **`hub_user`** — *lê* (`user_id, name, email, phone, is_active`) e **escreve**
  (`password_hash`, `updated_at`) no `confirm_code`.
- **`hub_audit_log`** — *escreve* o evento `easy.user.password_reset`.
- **`easy_password_reset`** — tabela de **sessão transitória do reset**, criada pelo
  Easy **dentro do Hub DB** (`_ensure_reset_table`). É estado do processo, não dado de
  domínio — no novo modelo deve viver no lado de quem dona o processo (o Hub). DDL atual:

```sql
CREATE TABLE IF NOT EXISTS easy_password_reset (
    session_id   TEXT PRIMARY KEY,
    user_id      TEXT NOT NULL,
    pw_hash      TEXT NOT NULL,        -- bcrypt da nova senha (pendente)
    code_hash    TEXT NOT NULL,        -- sha256 do código 6 díg.
    token_hash   TEXT,                 -- sha256 do token do link (uso único)
    attempts     SMALLINT NOT NULL DEFAULT 0,
    expires_at   TIMESTAMPTZ NOT NULL,
    created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
```

---

## 4. Árvore de arquivos envolvidos

```
backend/
├── modules/auth/
│   └── routes_reset.py                 # rotas /recuperar-senha (GET/POST),
│                                        #        /recuperar-senha/confirmar (GET/POST),
│                                        #        /recuperar-senha/{token} (GET/POST)
│                                        # + _validate_password (política)
├── core/
│   ├── password_reset.py               # NÚCLEO: request_reset, validate_reset_token,
│   │                                    #   check_token_not_used, store_pending_change,
│   │                                    #   confirm_code, _write_audit_log,
│   │                                    #   _send_confirmation_email, _ensure_reset_table
│   ├── email_client.py                 # send_email(to, subject, html_body, text_body) — SMTP
│   ├── zapi_client.py                  # send_text(phone, msg) — WhatsApp (Z-API)
│   ├── zapi_settings.py                # zapi_active / base_url / headers
│   ├── hub_db.py                       # hub_conn() — conexão Postgres do Hub
│   └── runtime_config.py               # jwt_secret(), app_base_url(), is_production()
└── frontend/templates/auth/
    ├── reset_request.html              # passo 1: informa e-mail
    ├── reset_form.html                 # passo 2: nova senha (após o link)
    └── reset_confirm.html              # passo 3: código 2FA (WhatsApp)
```

---

## 5. Config / env consumidas

- `EASY_JWT_SECRET` — assina o token do link (HS256). ⚠️ Em produção o Easy usa
  **RS256** (validação via JWKS do Hub) e esse segredo fica **vazio** → o token de reset
  **quebraria em prod**. Ao migrar pro Hub, usar um segredo próprio do Hub.
- `EASY_BASE_URL` / `app_base_url()` — monta o link do e-mail.
- `PUBLIC_SMTP_HOST/PORT/USERNAME/PASSWORD/USE_SSL` — envio de e-mail (Titan).
- `ZAPI_*` (`ZAPI_INSTANCE_ID`, `ZAPI_TOKEN`, `ZAPI_CLIENT_TOKEN`, `ZAPI_SENDER_ENABLED`) — WhatsApp.
- `is_production()` — em dev loga o código no console (`[RESET][DEV] código=...`).

---

## 6. Notas para a reimplementação no Hub

- **Dono do dado:** o `password_hash` (e o audit) devem ser escritos **pelo Hub**. O Easy
  não deve mais abrir `hub_conn`.
- **Sessão do reset:** mover `easy_password_reset` para onde o processo viver (Hub).
- **MFA:** hoje são 2 fatores (link e-mail + código WhatsApp). O Hub decide se mantém os
  dois e com quais provedores (o Easy usava Titan SMTP + Z-API).
- **Token:** usar segredo próprio do Hub (não o `EASY_JWT_SECRET`).
- **Telas:** `reset_request.html`, `reset_form.html`, `reset_confirm.html` (Easy) podem
  ser usadas como referência visual ao portar pro Hub.
- **No Easy (depois):** as rotas `/recuperar-senha*` viram **redirect** para o portal de
  redefinição do Hub; `password_reset.py` e os clients de e-mail/WhatsApp saem do caminho
  de auth do Easy.
