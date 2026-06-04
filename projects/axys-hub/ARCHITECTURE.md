# AxysHub — Arquitetura

**Status:** 🟢 Produção  
**Versão:** 1.0  
**Data:** 01/06/2026

---

## Visão Geral

AxysHub é o **sistema central de autenticação e gestão de tenants** para o ecossistema Axys.

**Responsabilidades:**
- ✅ Autenticação de usuários (SSO via JWT)
- ✅ Gestão de tenants (multitenancy)
- ✅ Gestão de usuários e papéis
- ✅ Emissão de tokens (HS256/RS256)
- ✅ Auditoria de login/logout
- ✅ Gestão de permissões e licenças

---

## 📊 Banco de Dados

### Estrutura Principal

```sql
Hub Database (tabelas hub_*)
├── hub_user              -- Usuários globais do ecossistema
├── hub_tenant            -- Empresas/organizações (multitenancy)
├── hub_user_tenant       -- Mapeamento usuário ↔ tenant (papel/role no vínculo)
├── hub_plano             -- Planos comercializáveis
├── hub_assinatura        -- Assinaturas por tenant
├── hub_licenca           -- Licenças por tenant
├── hub_microapp_instance -- Apps licenciados por tenant (→ claim apps_licenciadas)
├── hub_auth_token        -- Tokens emitidos (autenticação / refresh)
├── hub_audit_log         -- Mudanças em dados (audit imutável, evento + payload_json)
└── hub_login_log         -- Eventos de login/logout e origem (SSO, LOCAL, OAuth…)
```

> Lista ilustrativa das tabelas principais — não exaustiva. Todas seguem o
> prefixo `hub_*` no schema público (não há schema `audit` separado no Hub).

### Schemas & Migrations

- **[schema.sql](schemas/schema.sql)** — DDL completo (38 KB)
- **[seed.sql](schemas/seed.sql)** — Dados iniciais (9.4 KB)
- **[migrations/](schemas/migrations/)** — Histórico de evolução

**Status:** ⚠️ REVISAR (produção ativa)

---

## 🔐 Autenticação & Autorização

### Fluxo de Autenticação

```
Cliente (Easy/Pro/Sync)
         ↓
    POST /auth/login
         ↓
Hub valida credenciais
         ↓
Hub emite JWT (HS256/RS256)
         ↓
Cliente armazena token
         ↓
Requisições futuras: Bearer Token
         ↓
Hub valida assinatura + expiração
```

**Configuração:**
- HS256 (simétrica): desenvolvimento
- RS256 (assimétrica): produção
- TTL: 8 horas
- Refresh: via refresh_token

### Multitenancy

Toda requisição autenticada inclui `tenant_id`:

```json
{
  "tenant_id": "550e8400-e29b-41d4-a716-446655440000",
  "user_id": "...",
  "is_staff": false,
  "role": "admin",
  ...
}
```

Isolamento garantido em queries: `WHERE tenant_id = ?`

---

## 🏗️ Módulos

### Específicos do Hub (5 ADRs)

| ADR | Propósito |
|-----|-----------|
| **HUB-ADR-001** | Seed Mínimo (dados iniciais) |
| **HUB-ADR-002** | Hub Control Plane (gestão central) |
| **HUB-ADR-003** | Licenciamento Lease Token |
| **HUB-ADR-004** | Arquitetura Push-Only para ERP |

### Globais (referência de foundation/)

Veja [foundation/adrs/](../../foundation/adrs/) para decisões arquiteturais que afetam todos os projetos.

---

## 🔗 Integrações

### Clientes do Hub

| Projeto | Como consome | Ref |
|---------|-------------|-----|
| **AxysEasy** | Valida JWT, obtém tenant/user | [integrações](integrations/) |
| **AxysPro** | (futuro) Mesma autenticação | — |
| **AxysSync** | (futuro) Autentica contadores | — |

---

## 📚 Documentação

| Item | Local | Status |
|------|-------|--------|
| **ADRs Hub-específicas** | [adrs/](adrs/) | ✅ 5 documentadas |
| **Contratos** | [contracts/](contracts/) | ⚠️ Vazio (revisar) |
| **API Endpoints** | [api/](api/) | ⚠️ Por documenter |
| **Operações** | [operations/](operations/) | ⚠️ Por documenter |
| **Schema** | [schemas/schema.sql](schemas/schema.sql) | ✅ Existe |
| **Seed** | [schemas/seed.sql](schemas/seed.sql) | ✅ Existe |

---

## 🚀 Próximos Passos

### Curto Prazo (FASE 2)
- [ ] Revisar `schema.sql` (produção ativa)
- [ ] Revisar `seed.sql` (dados iniciais)
- [ ] Criar [api/endpoints.md](api/endpoints.md)
- [ ] Criar [operations/deployment.md](operations/deployment.md)
- [ ] Documentar fluxo OAuth/SSO completo

### Médio Prazo
- [ ] Adicionar testes de integração com Easy
- [ ] Documentar webhook flow para tenants
- [ ] Criar runbook de incident response

---

## 📞 Referências

- @see [AXYS-ADR-021 — SSO JWT Hub/Easy](../../foundation/adrs/AXYS-ADR-021-SSO-JWT-hub-easy.md)
- @see [HUB-ADR-002 — Hub Control Plane](adrs/HUB-ADR-002-hub-control-plane.md)
- @see [Tenant Model](../../foundation/contracts/axys_ecossistema_contrato_arquitetural.md)
