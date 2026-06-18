# AxysHub — API Endpoints

**Status:** ⚠️ Por documenter completamente  
**Prioridade:** Alta (produção ativa)

---

## Autenticação

### POST /auth/login
```
Autentica um usuário e retorna JWT token.

Body:
  email: string
  password: string
  tenant_id?: string (opcional, descobre automaticamente)

Response (200):
  {
    "access_token": "eyJhbGc...",
    "token_type": "Bearer",
    "expires_in": 28800,
    "user": { ... },
    "tenant": { ... }
  }

Error (401):
  { "detail": "Invalid credentials" }
```

### POST /auth/logout
```
Revoga o token atual (invalidar no redis/blacklist).

Headers:
  Authorization: Bearer <token>

Response (200):
  { "detail": "Logged out successfully" }
```

### POST /auth/refresh
```
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

