# Contrato Arquitetural — Ecossistema Axys
**Versão:** 1.0  
**Data:** 2026-05-28  
**Escopo:** AxysHub + AxysEasy + apps do ecossistema

---

## 1. Visão Geral do Ecossistema

O ecossistema Axys é uma plataforma SaaS multitenante voltada para engenharia civil, composta por serviços independentes com responsabilidades bem delimitadas.

```
axys-tec.com.br          → site institucional / comercial
hub.axys-tec.com.br      → AxysHub (identidade, billing, licenças)
easy.axys-tec.com.br     → AxysEasy (apps de engenharia)
```

---

## 2. Responsabilidades por Serviço

### 2.1 AxysHub (`hub.axys-tec.com.br`)
**É o dono da identidade e do contrato comercial.**

| Responsabilidade | Detalhe |
|---|---|
| Usuários | Cadastro, autenticação, senha, perfil |
| Tenants | Criação, ativação, suspensão |
| Vínculos user↔tenant | Roles, ativação, remoção |
| Licenças | Quais apps cada tenant contratou e quais apps cada usuário pode usar (`hub_licenca` + `hub_user_app`) |
| Billing | Cotas, limites de usuários, planos |
| Audit log | `hub_audit_log` — registro de todas as ações sensíveis |
| JWT | Emissor do token que os demais serviços consomem |

**Regra:** Nenhum outro serviço do ecossistema pode criar usuários, alterar roles ou manipular licenças. Toda ação dessas categorias passa pelo Hub.

---

### 2.2 AxysEasy (`easy.axys-tec.com.br`)
**É o ambiente de trabalho do engenheiro.**

| Responsabilidade | Detalhe |
|---|---|
| Apps de engenharia | CPU, Orça, Docs, Project Manager, BuildDiary, FinControl, LicitPlan |
| Catálogo de insumos | Schema `cpu` — somente leitura para tenants (escrita exclusiva Axys) |
| Modelos e orçamentos | Schema `orca` — criação e gestão pelo usuário do tenant |
| Redefinição de senha | Fluxo próprio via link seguro + Zapi, registrado em `hub_audit_log` |
| Sessão | Cookie `easy_token` (JWT HS256 em dev, RS256 em produção) |

**Regra:** Easy não cria usuários, não altera roles, não gerencia billing. Lê `apps_licenciadas` do JWT para determinar o que exibir. Toda ação sensível sobre o Hub é registrada em `hub_audit_log`.

---

### 2.3 Schema `cpu` — Catálogo de Insumos (futuro: `public_cpu`)
**Dois universos distintos:**

| Schema | Quem alimenta | Quem lê | Curadoria |
|---|---|---|---|
| `cpu` | Axys Tecnologia | Todos os tenants | Axys (autoritativo) |
| `public_cpu` (futuro) | Tenants (opcional, explícito) | Todos os tenants | Axys pode promover para `cpu` |

O `public_cpu` permitirá que tenants publiquem composições próprias com atribuição ao tenant de origem. A publicação é um ato voluntário e explícito — nunca automático. A Axys poderá promover itens de `public_cpu` para `cpu` após curadoria.

---

### 2.4 Schema `orca` — Modelos e Orçamentos
Estado atual: **revisão pendente**. O schema existente foi desenhado em fase anterior e não reflete a maturidade atual do produto. Deve ser revisado antes da implementação das funcionalidades de orçamento.

---

## 3. A Porteira — Login e Acesso

### 3.1 Princípio
**Uma única porteira para todos os perfis.** Não existem portais separados para staff Axys e para clientes. O mesmo `/login` e o mesmo `/main` atendem a todos — o conteúdo se adapta pelo perfil do usuário no JWT.

Referência de mercado: Salesforce, Linear, Notion — mesma URL, experiência adaptada por role.

### 3.2 Identificação do Tenant no Login
O campo **Num. Doc. Cliente (CNPJ ou CPF)** é obrigatório e serve para identificar em qual tenant o usuário está entrando. Um mesmo usuário pode pertencer a múltiplos tenants — o documento do tenant é o seletor.

```
Login com doc 38060729810 (AXYS) → perfil staff/admin
Login com doc [CNPJ cliente]       → perfil user convencional
```

### 3.3 Roles e Níveis de Acesso

| Role (`hub_user_tenant.role`) | Perfil | Acesso |
|---|---|---|
| `internal_owner` | Sócio/fundador Axys | Acesso total ao ecossistema |
| `internal_admin` | Funcionário Axys (admin) | Acesso administrativo ao ecossistema |
| `internal_user` | Funcionário Axys (uso interno) | Uso interno sem poderes administrativos sensíveis |
| `owner` | Responsável máximo do tenant cliente | Apps licenciadas + billing + gestão de admins |
| `admin` | Admin do tenant cliente | Apps licenciadas + gestão operacional de usuários |
| `user` | Usuário do tenant cliente | Apps licenciadas (uso operacional) |

**Regra de derivação no JWT:**
```python
is_staff = (tenant_code == "AXYS" and tenant_role == "internal_owner")
```

**Separação de responsabilidades nas apps:**  
O campo `tenant_role` preserva o papel bruto do vínculo no Hub, enquanto `role` é o papel normalizado de compatibilidade consumido pelo Easy (`owner`, `admin`, `user`). O Hub entrega apenas o contexto autenticado e o acesso macro por app. A matriz funcional interna de cada app deve morar na documentação e implementação da própria app.

### 3.4 JWT — Campos Relevantes

| Campo | Origem | Uso |
|---|---|---|
| `sub` | `hub_user.user_id` | Identificação do usuário |
| `email` | `hub_user.email` | Exibição |
| `name` | `hub_user.name` | Exibição |
| `tenant_uuid` | `hub_tenant.tenant_id` | Escopo de dados |
| `tenant_code` | `hub_tenant.tenant_code` | Referência curta |
| `tenant_name` | `hub_tenant.tenant_name` | Exibição |
| `tenant_role` | `hub_user_tenant.role` | Papel bruto do vínculo no Hub |
| `role` | derivado de `tenant_role` | Papel normalizado de compatibilidade (`owner`, `admin`, `user`) |
| `is_staff` | derivado de `tenant_code` + `tenant_role` | Flag contextual para uso interno Axys |
| `apps_licenciadas` | `hub_licenca ∩ hub_user_app` | Apps efetivas do usuário no tenant atual |

---

## 4. Maturidade Atual (maio 2026)

### Implementado e funcionando
- [x] Login com e-mail + senha + documento do tenant
- [x] JWT HS256 (dev) com cookie `easy_token` httponly
- [x] Logout com badge de confirmação
- [x] Redefinição de senha: link por e-mail (15 min, uso único) + código Zapi (5 min, 3 tentativas)
- [x] Audit log em `hub_audit_log` para redefinição de senha
- [x] Cliente Zapi: `send_text`, `send_image`, `send_file`
- [x] Cliente SMTP: `send_email`
- [x] Tela `/main` com launcher cards (todos em placeholder)
- [x] Header/footer com Menu e Sair
- [x] Estrutura CSS/JS canônica por escopo de página

### Pendente / Próximos passos
- [x] `tenant_role`, `role` e `is_staff` contextual no JWT
- [ ] `/main` diferenciada por perfil (staff vs cliente)
- [ ] `last_login` e `failed_attempts` no auth_service
- [ ] Schema `orca` revisado
- [ ] Implementação das apps (CPU, Orça, Docs, etc.)
- [ ] `public_cpu` schema
- [ ] Painel Hub para gestão de usuários e billing

---

## 5. Gestão de Usuários — Onde Mora

**No Hub, não no Easy.**

Easy expõe um link "Gerenciar usuários" para admins de tenant, que aponta para o painel Hub. A regra de negócio de cota de usuários é do Hub — Easy não tem visibilidade sobre o contrato comercial.

---

## 6. Comunicações com Usuário

| Canal | Uso | Brand |
|---|---|---|
| E-mail (SMTP) | Reset de senha, confirmações | "Axys Tecnologia" |
| WhatsApp (Zapi) | Código 2FA de reset | "Axys Tecnologia" |
| Contato suporte | contato@axys-tec.com.br | — |

---

*Este documento é vivo — deve ser atualizado a cada decisão arquitetural relevante.*
