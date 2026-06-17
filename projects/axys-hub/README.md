# AxysHub

**Status:** 🟢 Ativo  
**Versão:** 0.1  
**Repositório:** axys-hub  

---

## O que é?

AxysHub é o **sistema central de autenticação e gestão de tenants** do ecossistema Axys.

**Função principal:** Centralizar identidade, permissões e autorização para todos os projetos Axys (Easy, Pro, Gestor, etc).

**Responsabilidades:**
- Autenticação via SSO (OAuth/JWT)
- Gestão de usuários e tenants (multitenant)
- Emissão de tokens (HS256/RS256)
- Auditoria de login/logout
- Gestão de permissões e papéis

---

## 📊 Banco de Dados

```
Hub Database
├── users              # usuários globais do ecossistema
├── tenants            # empresas/organizações (multitenancy)
├── hub_user_tenant    # mapeamento usuário ↔ tenant
├── permissions        # papéis e permissões
├── hub_login_log      # login/logout eventos
└── hub_audit_log      # mudanças em dados
```

**Acessar schema:**
- [schema.sql](schemas/schema.sql) — DDL completo
- [seed.sql](schemas/seed.sql) — dados iniciais
- [migrations/](schemas/migrations/) — histórico de mudanças

---

## 🏗️ Arquitetura

Veja [ARCHITECTURE.md](ARCHITECTURE.md) para a visão canônica consolidada do Hub.

**Principais componentes:**
1. **API REST** — endpoints de autenticação e gestão
2. **Autenticação** — SSO integrado com Easy
3. **Auditoria** — registro de todos os eventos
4. **Multitenant** — isolamento de dados por empresa

---

## 🔗 Integração com Outros Projetos

| Projeto | Como consome |
|---------|-------------|
| **AxysEasy** | Valida JWT via [AXYS-ADR-021](../../foundation/adrs/AXYS-ADR-021-SSO-JWT-hub-easy.md) |
| **AxysPro** | (futuro) Usará mesma autenticação |
| **AxysGestor** | Autentica via client credentials |

Veja [integrations/](../../integrations/) para mapa completo.

**Documentos relacionados:**
- [integrations/sso-login-easy.md](integrations/sso-login-easy.md)
- [ARCHITECTURE.md](ARCHITECTURE.md)

---

## 📚 Documentação

| Arquivo | Propósito |
|---------|----------|
| [ARCHITECTURE.md](ARCHITECTURE.md) | Documento canônico do Hub: escopo, arquitetura, `client`, `internal`, billing, Gestor e arquivamento |
| [adrs/](adrs/) | Decisões específicas do Hub |
| [api/](api/) | Endpoints e fluxos |
| [schemas/](schemas/) | Banco de dados |
| [operations/](operations/) | Deploy e monitoramento |

---

## 🚀 Próximos Passos

- ⬜ Documentar endpoints em api/endpoints.md
- ⬜ Materializar no código o mapa formal `Client Portal` × `Internal Console`
- ⬜ Modelar billing/recebimentos com Asaas antes da refatoração profunda de telas
- ⬜ Consolidar o domínio `Internal` do Hub antes de expandir UI
- ⬜ Criar runbooks de operação

---

## 📞 Referências

- @see [AXYS-ADR-021 — SSO JWT](../../foundation/adrs/AXYS-ADR-021-SSO-JWT-hub-easy.md)
- @see [HUB-ADR-002 — Hub Control Plane](../../foundation/adrs/HUB-ADR-002-hub-control-plane.md)
- @see [Tenant Model](../../foundation/contracts/tenant-model.md)
