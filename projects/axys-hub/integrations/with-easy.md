# AxysHub ← → AxysEasy

**Status:** 🟢 Ativa e Confiável  
**Padrão:** SSO via JWT (ADR-029)

---

## Fluxo de Integração

```
AxysEasy Client
    ↓
Clica "Login"
    ↓
POST /auth/login (Hub)
    ↓
Hub emite JWT
    ↓
Easy armazena em cookie httponly
    ↓
Easy requisições: Bearer Token
    ↓
Hub valida e retorna claims resolvidos por usuário
    ↓
Easy usa claims para autorização
```

---

## JWT Claims (de Hub)

Quando Easy valida o token com Hub, recebe:

```json
{
  "sub": "user-uuid",
  "email": "user@example.com",
  "name": "John Doe",
  "tenant_uuid": "tenant-uuid",
  "tenant_code": "ACME",
  "tenant_name": "ACME Inc",
  "tenant_role": "admin",
  "is_staff": false,
  "role": "admin",
  "apps_licenciadas": ["easy-cpu", "easy-price-1", "easy-orca"],
  "iat": 1622505600,
  "exp": 1622534400
}
```

---

## Validação em Easy

### Backend (FastAPI)

```python
from backend.core.security import require_auth

@router.get("/main")
def main_page(claims: dict = Depends(require_auth)):
    # claims vem do Hub via JWT validation
    tenant_id = claims.get("tenant_uuid")
    is_staff = claims.get("is_staff")
    # ... use claims para autorizar
```

### Frontend (JavaScript)

```javascript
// Token está em cookie httponly (seguro)
// Headers adicionados automaticamente

fetch("/api/fontes-base", {
  headers: { "Authorization": "Bearer <token>" }
})
```

---

## Fluxo de Logout

```
Easy → GET /logout?app=easy&redirect_uri=<callback-do-easy>[&state=...]
    ↓
Hub encerra a sessão web
    ↓
Hub audita LOGOUT
    ↓
Hub redireciona para /login?msg=logout&app=easy&redirect_uri=...
    ↓
Usuário reloga e volta para a app correta
```

Observações:

- o Hub **não** faz revogação server-side do JWT já emitido;
- o `redirect_uri` do logout é validado contra a mesma allowlist do SSO de login;
- sem `app`/`redirect_uri`, o Hub mantém o comportamento genérico: `303 -> /login?msg=logout`.

---

## Tratamento de Erros

### Token Expirado

```
HTTP 401
{ "detail": "Token expired" }

Ação: Easy redireciona para /login
```

### Sem Licença para Módulo

```
HTTP 403
{ "detail": "App not licensed for user" }

Ação: Easy mostra página "sem contrato"
```

---

## Configuração Easy

### .env

```
HUB_URL=https://axys-hub.com
JWT_SECRET=<shared-secret-dev> ou <public-key-prod>
JWT_ALGORITHM=HS256 (dev) ou RS256 (prod)
```

### Middleware de Autenticação

Veja: `backend/core/security.py`

---

## ⚠️ TODO

- [ ] Documentar webhook para licensa expirada
- [ ] Fluxo de refresh token automático
- [ ] Tratamento de multitenant simultâneo
- [ ] Rate limiting na integração
