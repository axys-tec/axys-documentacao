# Easy MCP — o que o Hub precisa entregar

**Data:** 2026-10-20 · **De:** time Easy (Renan) · **Para:** time Hub
**Contrato do lado Easy:** [`EASY_MCP_CONTRATO.md`](EASY_MCP_CONTRATO.md)

> **Fronteira:** identidade, sessão e licença são do Hub. O Easy **não** cria usuário, role, senha
> nem token de identidade próprio para o MCP. Ele coordena o OAuth que os clientes MCP exigem e
> repassa o JWT que o Hub assina. Nada do que existe no Hub é descartado.

## Contexto

O Easy vai expor um servidor MCP (Model Context Protocol) para o usuário operar o Easy pela
própria IA (ChatGPT, Claude). O cliente MCP exige OAuth, e quem identifica o usuário tem de ser o
Hub. Do lado Easy, o fluxo é: `/mcp/oauth/authorize` → redirect ao `HUB/login?app=easy-mcp` →
callback no Easy → `HUB/auth/exchange` → JWT `aud=easy-mcp` entregue ao cliente MCP como
`access_token`.

## Estado atual do Hub (levantado no código em 2026-10-20)

- Apps de SSO hard-coded em `SUPPORTED_SSO_APPS = {"easy","easy-mobile","gestor"}`
  (`easy_sso.py:34`). Client id, secret e allowlist de redirect vêm de env por app
  (`easy_sso.py:234-289`).
- Code do SSO: Fernet, TTL 30–300 s, hash em `auth.hub_auth_token`, uso único no
  `POST /auth/exchange` (`router.py:827-873`). O `redirect_uri` gravado no code **não** é comparado
  no exchange.
- JWT RS256 + JWKS em `/.well-known/jwks.json`, `aud` por app, TTL `easy` 8 h. **Sem `jti`, sem
  `sid`, sem refresh.**
- **Não existe sessão única.** A sessão do Hub é cookie assinado (`SessionMiddleware`), sem tabela.
  `POST /login` não derruba sessão anterior, e o downstream não tem como saber se um token foi
  revogado. Resultado: **um usuário (inclusive de plano unlimited) consegue estar logado em vários
  lugares ao mesmo tempo.**

## Pedidos

| # | O quê | Prioridade | Bloqueia |
|---|---|---|---|
| P1 | App de SSO `easy-mcp` | **alta** | a V0 do MCP (dev e prod) |
| P2 | Sessão única por usuário × app, com `sid` no JWT e consulta de status | **alta** (é falha de licenciamento hoje, independente do MCP) | revogação do MCP; fecha o furo do login múltiplo |
| P3 | Refresh token para `easy-mcp` | média | nada (sem ele, o cliente refaz o login ao vencer) |

---

## Prompt P1 — app de SSO `easy-mcp`

```text
Contexto: repositório axys-hub. O Easy vai expor um servidor MCP que autentica usuários via SSO
do Hub. Precisamos de um quarto app de SSO, "easy-mcp", com o MESMO comportamento do app "easy"
(mesmo usuário, mesmo tenant, mesmas claims, mesma checagem de licença/vínculo), mas com client
próprio e audiência própria. Não remover nem alterar o comportamento de "easy", "easy-mobile" ou
"gestor".

Tarefas:
1. easy_sso.py: incluir "easy-mcp" em SUPPORTED_SSO_APPS.
2. Config por env, no mesmo padrão dos outros apps:
   - EASY_MCP_SSO_CLIENT_ID / EASY_MCP_SSO_CLIENT_SECRET
   - EASY_MCP_SSO_ALLOWED_REDIRECT_URIS (lista separada por vírgula; match exato como hoje)
       dev:  https://mcp-dev.axys-tec.com.br/mcp/oauth/hub-callback
       prod: https://<host do Easy em prod>/mcp/oauth/hub-callback
   - audiência: "easy-mcp" (env-overridable como as outras)
   - TTL do JWT: EASY_MCP_JWT_TTL, default 28800 (8 h), mínimo 300.
3. Claims: reusar exatamente o builder de claims do app "easy" (services.py, sub, email, name,
   tenant_uuid, tenant_code, tenant_name, role, tenant_role, access_context, is_staff,
   apps_licenciadas, emitido_em, licencas, ia_creditos, personalizacao), trocando só o aud.
   Só emitir se o usuário tiver licença do Easy (mesma regra do "easy").
4. GET /login?app=easy-mcp&redirect_uri=...&state=... e POST /auth/exchange com {code, app:"easy-mcp"}
   e Basic com as credenciais easy-mcp devem funcionar como para "easy". Se houver
   GET /sso/{app}/start, incluir easy-mcp.
5. audit.login_log: registrar o login com origin = "easy-mcp".
6. Aproveitar e corrigir: no POST /auth/exchange, comparar o redirect_uri gravado no code com o
   redirect_uri do app/cliente (hoje não compara). Vale para todos os apps.
7. Testes: login + exchange para easy-mcp; token easy-mcp tem aud="easy-mcp"; redirect_uri fora da
   allowlist é recusado; code usado duas vezes é recusado; os apps existentes seguem iguais.

Entregar também: os valores de client id/secret de DEV (o Hub local roda em 127.0.0.1:8000) para o
time Easy pôr no .env.local, e a lista de envs novas para o Render de prod.
```

---

## Prompt P2 — sessão única por usuário × app

```text
Contexto: repositório axys-hub. Hoje o Hub NÃO limita sessões: a sessão é um cookie assinado sem
tabela, POST /login não derruba nada, e o JWT não tem sid/jti. Um usuário (inclusive de plano
unlimited) consegue usar o mesmo login em vários lugares ao mesmo tempo. Precisamos de SESSÃO
ÚNICA POR USUÁRIO × APP: o mesmo usuário pode estar ao mesmo tempo no Easy web, no Easy MCP e no
Gestor (um por produto, IPs distintos permitidos), mas NÃO em duas sessões do mesmo app. Não
remover nada do fluxo atual de SSO.

Regra de negócio:
- Chave da sessão: (user_id, tenant_id, app). `app` separa explicitamente `easy`, `easy-mcp` e
  `gestor`: uma sessão ativa em cada produto pode coexistir.
- Login novo no mesmo (user, tenant, app) DERRUBA a sessão anterior desse app (último login vence),
  inclusive o login silencioso do GET /login com cookie do Hub ativo.
- Sessões de apps diferentes não se derrubam.
- Logout encerra só a sessão daquele app.
- `easy-mobile` é a exceção: permite até 3 sessões simultâneas por identidade/tenant. A quarta
  emissão revoga a sessão Mobile ativa mais antiga.

Tarefas:
1. Tabela de sessão (ex.: auth.hub_sessao: sid UUID PK, user_id, tenant_id, app, ip, user_agent,
   criada_em, ultima_vista_em, revogada_em, motivo_revogacao). Índice único parcial em
   (user_id, tenant_id, app) WHERE revogada_em IS NULL. Migration junto com o schema.
2. No exchange/emissão de JWT de qualquer app: abrir a sessão nova e revogar a anterior do mesmo
   (user, tenant, app) numa transação só. Incluir a claim "sid" no JWT (e "jti").
3. Endpoint de status para os produtos consultarem (server→server, Basic com as credenciais do
   app): GET /auth/sessoes/{sid}/status → {ativa: bool, motivo?}. Deve ser barato (índice por sid).
   O Easy vai consultar com cache curto (60 s) por sid. Alternativa aceitável, se o Hub preferir
   push: notificar o produto da revogação (no mesmo padrão do /api/internal/licensing/access-mode
   do Easy), mas o pull é o mínimo exigido.
4. Endpoint para o usuário/owner desconectar uma sessão específica (ex.: desconectar o MCP sem
   derrubar a web): POST /auth/sessoes/{sid}/revogar, com a autorização do próprio usuário ou do
   owner do tenant.
5. audit.login_log: novo evento SESSAO_DERRUBADA (sid antigo, sid novo, app, ip) e SESSAO_REVOGADA.
6. Testes: dois logins do mesmo usuário no mesmo app → o primeiro sid fica inativo; logins em apps
   diferentes coexistem; logout de um app não afeta outro; status de sid revogado = ativa:false.

Quando o endpoint de status estiver fora do ar, o consumidor pode usar o último status conhecido
por no máximo 5 minutos. Sem status anterior, ou depois de 5 minutos, deve recusar o acesso.
```

---

## Prompt P3 — refresh token para `easy-mcp` (opcional)

Implementado no Hub com a migration `015-easy-mcp-refresh-token.sql`. O TTL padrão é de 30 dias
e pode ser configurado por `EASY_MCP_REFRESH_TTL` em segundos.

```text
Contexto: repositório axys-hub, depois de P1 e P2. Clientes MCP (ChatGPT, Claude) suportam
refresh_token. Sem ele, quando o JWT easy-mcp vence o usuário precisa reconectar. Queremos o
refresh DO HUB (o Easy não emite identidade).

Tarefas:
1. No exchange do app easy-mcp, devolver também um refresh_token opaco (aleatório; só o hash no
   banco), amarrado ao sid da sessão, com TTL EASY_MCP_REFRESH_TTL (sugestão: 30 dias) e rotação a
   cada uso (o antigo morre; reuso de refresh já usado revoga a sessão inteira).
2. POST /auth/refresh {refresh_token, app:"easy-mcp"} com Basic easy-mcp → JWT novo do MESMO sid,
   reavaliando usuário ativo, tenant ativo e licença (mesmas checagens do exchange).
3. Sessão revogada (P2) invalida o refresh.
4. Testes: refresh válido renova; refresh reusado revoga; sessão revogada recusa refresh; usuário
   sem licença recusa.
```

---

## P4 — licenciamento MCP por módulo

O MCP é um **add-on comercial de cada módulo Easy**, não uma licença genérica da plataforma. O
login e a sessão continuam únicos em `app="easy-mcp"`; a granularidade por módulo existe somente
na autorização das ferramentas/endpoints.

Regras:

- todos os endpoints MCP podem permanecer publicados;
- possuir a licença-base de um módulo não concede automaticamente seu add-on MCP;
- o JWT `aud="easy-mcp"` mantém `apps_licenciadas` e `licencas` sem alterações e acrescenta
  `mcp_licencas` com os add-ons efetivos daquele usuário/tenant;
- o JWT web `aud="easy"` e o retorno atual de `_whoami` não ganham esse campo;
- o Hub recusa o login/refresh `easy-mcp` quando não existir ao menos um add-on MCP ativo;
- o backend Easy decide se executa cada ferramenta comparando o módulo requerido com
  `mcp_licencas`; não se cria login, sessão ou audiência por módulo;
- `AXYS` e `DIASECARDOZO` recebem graça `unlimited` nos módulos Easy já licenciados;
- `LUNALO` permanece exclusivamente no Gestor e não recebe licença Easy ou Easy MCP.

Formato da claim:

```json
{
  "mcp_licencas": [
    {
      "app": "easy-orca",
      "plano": "unlimited",
      "status": "ACTIVE",
      "periodo_inicio": "2026-07-24",
      "periodo_fim": null
    }
  ]
}
```

Persistência no Hub:

- catálogo: um `product.addon` de código `MCP` ligado a cada produto Easy;
- contratação/concessão: `billing.hub_license_addon`, ligada à licença-base e ao add-on;
- migration: `016-easy-mcp-addon-por-modulo.sql`.

---

## Do lado Easy (para referência do Hub)

- Valida o JWT `easy-mcp` com o mesmo JWKS e o mesmo emissor da web, exigindo `aud="easy-mcp"`.
- Recusa no `/mcp` token de outra audiência, e recusa na web token `easy-mcp`.
- Com P2: consulta `GET /auth/sessoes/{sid}/status` com cache de 60 s. Com P2 entregue, o
  `require_auth` da web passa a fazer a mesma checagem (fecha o furo do login múltiplo também na
  tela).
- Com P3: repassa o refresh do Hub ao cliente MCP no `/mcp/oauth/token` (`grant_type=refresh_token`).
