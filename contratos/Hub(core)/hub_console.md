# Hub Console (Axys Admin)

## O que é
Console interno da Axys para administrar tenants, licenças, billing e operações.
Usa o mesmo login do Hub, mas é separado do portal do cliente.

## Rotas
- Portal do cliente: `/app/*`
- Console Axys: `/console/*`

## Política de privilégios (NUNCA por nome/email)
- Privilégio **não** vem de nome, nick ou email.
- Acesso ao console **somente** para usuários vinculados ao tenant interno **AXYSHQ**
  com role interna:
  - `internal_owner`
  - `internal_admin`
  - `internal_support`
  - `internal_billing`

## Como um usuário vira staff
- Apenas via seed inicial ou via ação de grant por `internal_owner/internal_admin`.
- Cadastro público nunca cria roles internas.

Tenant interno padrão: `AXYSHQ` (configurável via `AXYSHUB_INTERNAL_TENANT_CODE`).

## Roles suportadas (hub_user_tenant.role)
- Cliente: `owner`, `admin`, `member`, `viewer`
- Interno Axys (somente AXYSHQ): `internal_owner`, `internal_admin`, `internal_support`, `internal_billing`

## Auditoria
Toda ação de grant/revoke registra em `hub_audit_log`:
- `rbac.grant`
- `rbac.revoke`

Payload mínimo:
```
{ actor_user_id, target_user_id, tenant_id, role, reason }
```

## Endpoints de staff
```
POST /console/users/{user_id}/grant
POST /console/users/{user_id}/revoke
```

Corpo:
```
{ "tenant_id": "...", "role": "...", "reason": "..." }
```

Somente `internal_owner` ou `internal_admin` podem executar.
