# AxysHub — API Endpoints

**Status:** ⚠️ Por documenter completamente  
**Prioridade:** Alta (produção ativa)

---

## Autenticação

### POST /auth/login
```
SSO password login para aplicações externas do ecossistema Axys.

Headers:
  Authorization: Basic base64(client_id:client_secret)

Body:
  email: string
  password: string
  document: string (somente dígitos; tenant por padrão, tenant/store para apps store-aware)
  app: string ("easy" | "gestor")

Response (200):
  {
    "token": "eyJhbGc...",
    "access_token": "eyJhbGc..."
  }

Erros:
  400 -> payload inválido / app não suportada
  401 -> client credentials inválidas ou credenciais do usuário inválidas
```

### POST /auth/exchange
```
Troca um authorization code de uso único por um JWT assinado pelo Hub.

Headers:
  Authorization: Basic base64(client_id:client_secret)

Body:
  code: string
  app: string ("easy" | "gestor")

Response (200):
  {
    "token": "eyJhbGc...",
    "access_token": "eyJhbGc..."
  }

Erros:
  400 -> code inválido, expirado, reutilizado ou emitido para outra app
  401 -> client credentials inválidas
```

Observação:
  Para o AxysGestor, o Hub aceita somente a app macro "gestor".
  Produtos internos como "sl", "loccitane" e "gestor" são resolvidos pelo próprio AxysGestor.
  O contrato do Gestor prevê `login_scope` tenant/store, com campos de store nulos quando o documento resolver tenant.

### GET /.well-known/jwks.json
```
Publica as chaves públicas RS256 do Hub para validação offline dos JWTs
emitidos para as aplicações integradas.
```

### GET /logout
```
Encerra a sessão web do Hub, registra LOGOUT em hub_login_log e
redireciona para a tela de login.

Query params opcionais:
  app: string           # ex: "easy" | "gestor"
  redirect_uri: string  # validada contra allowlist da app
  state: string         # devolvido ao login para reiniciar o fluxo SSO

Comportamento:
  - sem query params:
      303 -> /login?msg=logout
  - com app + redirect_uri válidos:
      303 -> /login?msg=logout&app=...&redirect_uri=...[&state=...]

Observação:
  Este endpoint encerra a sessão browser do Hub.
  Ele não faz revogação server-side de JWT já emitido.
```

### POST /auth/refresh
```
Não implementado no código atual do Hub.

O bloco abaixo descreve uma intenção/roadmap de API, não um endpoint disponível hoje.

Fluxo pretendido:
  Obtém novo access_token usando refresh_token.

Body:
  refresh_token: string

Response (200):
  { "access_token": "eyJhbGc..." }
```

---

## Usuários

### GET /api/users/me
```
Retorna dados do usuário autenticado.

Headers:
  Authorization: Bearer <token>

Response (200):
  {
    "id": "550e8400-...",
    "email": "user@example.com",
    "name": "John Doe",
    "is_staff": false,
    "role": "admin",
    "tenant_id": "550e8400-...",
    ...
  }
```

---

## Tenants

### GET /api/tenants
```
Lista tenants do usuário autenticado.

Headers:
  Authorization: Bearer <token>

Response (200):
  [
    {
      "id": "550e8400-...",
      "code": "ACME",
      "name": "ACME Inc",
      "created_at": "2026-05-01",
      ...
    }
  ]
```

---

## ⚠️ TODO

- [ ] Adicionar autenticação OAuth2
- [ ] Documentar webhook endpoints
- [ ] Documentar admin endpoints
- [ ] Adicionar exemplos de erro
- [ ] Versioning strategy
