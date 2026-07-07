# AxysEasy ← → AxysHub

**Status:** 🟢 Ativa (via SSO/JWT)  
**Padrão:** AXYS-ADR-021 (foundation)

---

## Fluxo de Autenticação

```
1. Usuário clica "Login" em Easy
   ↓
2. Redireciona para Hub: https://axys-hub.com/login
   ↓
3. Hub autentica (email + senha)
   ↓
4. Hub emite JWT token
   ↓
5. Redireciona de volta: easy.axys-tec.com.br?token=...
   ↓
6. Easy armazena token em cookie httponly
   ↓
7. Requisições: Authorization: Bearer <token>
```

---

## JWT Claims Recebidos do Hub

Quando Easy valida um token, recebe claims:

```json
{
  "sub": "user-uuid",
  "email": "renan@axys.com",
  "name": "Renan Dias",
  "tenant_uuid": "550e8400-e29b-41d4-a716-446655440000",
  "tenant_code": "AXYS",
  "tenant_name": "Axys Tecnologia",
  "is_staff": true,
  "role": "owner",
  "apps_licenciadas": ["easy-cpu", "easy-price", "easy-orca"],
  "iat": 1622505600,
  "exp": 1622534400  // 8 horas depois
}
```

---

## Implementação em Easy

### Backend Validation

Arquivo: `backend/core/security.py`

```python
def require_auth(request: Request) -> dict:
    """Extrai e valida JWT do header Authorization"""
    token = extract_token(request)
    claims = decode_token(token)  # Valida assinatura + exp
    return claims

def decode_token(token: str) -> dict:
    """Decodifica JWT com chave pública do Hub (produção)"""
    return jwt.decode(token, HUB_PUBLIC_KEY, algorithms=["RS256"])
```

### Permissões Baseadas em Claims

```python
from backend.core.permissions import exige_internal_user

@router.get("/fontes-base")
def fontes_base(request: Request, claims: dict = Depends(exige_internal_user)):
    # claims vem do Hub
    is_staff = claims.get("is_staff")  # False = cliente, True = Axys
    role = claims.get("role")           # user, admin, owner
    tenant_uuid = claims.get("tenant_uuid")
    
    # Autorizar baseado em claims
    if not is_staff and role not in ["admin", "owner"]:
        raise PermissionDenied(...)
```

---

## Fluxo de Logout

```
1. Usuário clica "Logout" em Easy
   ↓
2. Easy → POST /auth/logout (Hub)
   ↓
3. Hub invalida token (blacklist/revoke)
   ↓
4. Easy limpa cookie
   ↓
5. Redireciona para /login
```

---

## Tratamento de Erros

### Token Expirado (401)

```
Easy valida token
  ↓
Token expirado
  ↓
Easy redireciona para /login
  ↓
Usuário faz login novamente
```

### Sem Licença para Easy (403)

```
Hub retorna: "apps_licenciadas" não contém "easy-cpu"
  ↓
Easy mostra: "Seu contrato não inclui Easy"
  ↓
Página: /sem-contrato
```

---

## Multitenancy

Uma pessoa pode ter acesso a **múltiplos tenants**:

```json
Usuario: Renan Dias
  ├─ Tenant 1: AXYS (is_staff=true, role=owner)
  ├─ Tenant 2: ACME (is_staff=false, role=admin)
  └─ Tenant 3: XYZ Corp (is_staff=false, role=user)
```

Na requisição, o token inclui **apenas um tenant_uuid**. Easy usa esse tenant para:
- Filtrar dados: `WHERE tenant_uuid = ?`
- Validar permissões
- Segregar orçamentos

---

## Configuração

### .env

```
HUB_AUTH_URL=https://axys-hub.com
HUB_PUBLIC_KEY=-----BEGIN PUBLIC KEY-----...
JWT_ALGORITHM=RS256  (produção) ou HS256 (dev)
COOKIE_DOMAIN=axys-tec.com.br
```

### Middleware de Autenticação

Arquivo: `backend/core/security.py`

- Extrai token do header `Authorization: Bearer`
- Valida assinatura (RS256 com chave pública do Hub)
- Valida expiração (exp claim)
- Retorna claims para uso em permissões

---

## TODO

- [ ] Refresh token automático (antes de expirar) → ver **Design de referência** abaixo
- [ ] Webhook do Hub para "tenant deactivated" → coberto pelo **revoke-on-cancel** abaixo
- [ ] Cache de permissões (JTI blacklist)
- [ ] Multi-tenant switching UI

## Design de referência — lifecycle de token (resgatado do ADR-029, 2026-05-23)

> O handshake de SSO **já evoluiu no prod** para `code → exchange` (Fernet), mais avançado que
> o token-in-URL do ADR-029 original. Aproveite deste design **apenas o ciclo de vida do token**
> (refresh/revoke) — não o fluxo de handshake, que está superado. Ver [[reference_sso_hub_prod]].

**Vidas de token:**
- **Access token**: vida máxima **1h** (assinado RS256/ES256, validado localmente via JWKS, sem
  chamar o Hub). A janela curta é o trade-off aceito entre segurança (revogação) e disponibilidade.
- **Refresh token**: vida máxima **30 dias**, renovação por uso (**sliding window**).

**Revogação amarrada ao cancelamento de assinatura** (resolve o TODO "tenant deactivated" sem
depender de webhook): no cancelamento, o **Hub invalida o refresh token imediatamente**; o access
token **expira naturalmente** (janela ≤ 1h de acesso residual). Sem necessidade de blacklist
distribuída para o caso comum.

**Pré-condição no AxysHub** (refatoração — não urgente, executar quando o Easy for integrar o
refresh; o mecanismo de token opaco atual pode coexistir na transição):

| Componente (Hub) | Mudança |
|---|---|
| `service_auth.py` | emitir JWT assinado (RS256) em vez de token opaco |
| `security.py` | validar JWT além do hash atual |
| `POST /auth/token` | emissão de access + refresh token |
| `POST /auth/refresh` | renovação de access via refresh token |
| `POST /auth/revoke` | revogação de refresh token (acionada no cancelamento) |
| `GET /.well-known/jwks.json` | expor chave pública p/ o Easy validar sem redeploy |
| Banco do Hub | tabela de refresh tokens com flag de revogação |

