# AxysPro — Arquitetura e Design

**Status:** 🟡 Planejado  
**Tipo:** ERP Modular Enterprise  
**Padrão:** Django monolítico (single-tenant) + PostgreSQL

---

## Visão Geral

AxysPro é um **ERP completo para gestão de escritórios de engenharia, construtoras e empresas de prestação de serviços**.

Diferentemente do AxysEasy (ferramenta especializada para orçamentos), Pro é:
- ✅ Multifuncional (financeiro, RH, projetos, documentos, contratos)
- ✅ Multidepartamental (integra silos operacionais)
- ✅ Single-tenant por instalação (cada cliente = um banco isolado)
- ✅ Desktop-like UX (produtividade de ERPs tradicionais)
- ✅ Extensível (novos módulos sem refatoração estrutural)

---

## Arquitetura de Alto Nível

```
┌─────────────────────────────────────────────────────┐
│           AxysPro Core (Django)                      │
│  single-tenant, banco exclusivo por empresa         │
├─────────────────────────────────────────────────────┤
│ ┌───────────────────────────────────────────────┐   │
│ │  Módulos Funcionais                           │   │
│ │  ┌─────────────────────────────────────────┐  │   │
│ │  │ SysCost         │ Financeiro   │ RH      │  │   │
│ │  │ Documentos      │ Projetos     │ Auditoria│  │   │
│ │  └─────────────────────────────────────────┘  │   │
│ └───────────────────────────────────────────────┘   │
│                                                      │
│ ┌───────────────────────────────────────────────┐   │
│ │  Camada Estrutural Compartilhada              │   │
│ │  • Identidade & RBAC                          │   │
│ │  • Documentação & Contratos                   │   │
│ │  • Auditoria Obrigatória                      │   │
│ │  • Integrações Externas                       │   │
│ └───────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────┘
           ↓
┌─────────────────────────────────────────────────────┐
│         PostgreSQL (Dedicated per Tenant)            │
│  • Um banco por cliente                             │
│  • Schemas por domínio funcional                    │
│  • Migrações versionadas                            │
└─────────────────────────────────────────────────────┘
           ↓
┌─────────────────────────────────────────────────────┐
│  Integrações Externas                              │
│  • AxysHub (licenciamento, tenant management)      │
│  • AxysEasy (integração de orçamentos)             │
│  • ERP Externos (RH, Fiscal, Bancos)               │
└─────────────────────────────────────────────────────┘
```

---

## Módulos Principais (Fase 1)

### 1. **SysCost** — Gestão de Custos & Orçamentos

Controlaria custos de obras/projetos:
- Composição de preços unitários (CPU)
- Análise de custos por atividade
- Comparativo orçamento vs. realizado
- Integração com AxysEasy (importar CPUs/composições)

**Entidades:**
- `syscost.custo_item` — itens de custo
- `syscost.custo_composicao` — composições
- `syscost.analise_realizado` — tracking vs. orçado

---

### 2. **Documentação & Contratos**

Gerenciamento centralizado de documentos legais e técnicos:
- Contratos (clientes, fornecedores, RH)
- Memoriais descritivos
- Especificações técnicas
- Anexos com versionamento
- Sensibilidade e redaction (ADR-006)

**Entidades:**
- `doc.documento` — metadados
- `doc.documento_versao` — histórico
- `doc.documento_sensibilidade` — tarjamento
- `doc.anexo` — storage controlado

---

### 3. **RH & Pessoal**

Gestão de equipes, folha de pagamento, registros:
- Cadastro de funcionários
- Folha de pagamento
- Contratos de trabalho
- Histórico salarial
- Integração com externos (fiscal, previdência)

**Entidades:**
- `rh.pessoa` — dados pessoais
- `rh.funcionario` — vínculos
- `rh.folha_mes` — payroll
- `rh.contrato` — vínculos contratuais

---

### 4. **Projetos & Acompanhamento**

Estrutura de projetos/obras com phases e tarefas:
- Cadastro de projeto/obra
- Phases (fundação, alvenaria, etc)
- Atividades e marcos
- Designação de equipes
- Acompanhamento de progresso

**Entidades:**
- `proj.projeto` — obra/projeto
- `proj.fase` — fases do projeto
- `proj.atividade` — tasks
- `proj.alocacao` — equipe ↔ atividade

---

### 5. **Financeiro & Billing**

Contas a receber, contas a pagar, caixa:
- Faturas/NF
- Contas a pagar (fornecedores)
- Contas a receber (clientes)
- Movimentação de caixa
- Conciliação bancária

**Entidades:**
- `fin.nf` — notas fiscais (saída)
- `fin.conta_pagar` — contas a pagar
- `fin.conta_receber` — contas a receber
- `fin.movimento_caixa` — cash flow

---

### 6. **Auditoria Obrigatória**

Rastreamento de todas as operações críticas:
- Quem fez o quê, quando e onde
- Justificativa de alterações críticas
- Acompanhamento de permissões
- Retenção conforme lei

**Entidades:**
- `audit.log_operacao` — todas as alterações
- `audit.log_documento_acesso` — acesso a docs sensíveis
- `audit.log_sistema` — eventos técnicos

---

## Banco de Dados

### Estratégia de Isolamento

```sql
-- Um banco PostgreSQL por cliente
CREATE DATABASE axyspro_cliente_001;
CREATE DATABASE axyspro_cliente_002;
-- ... etc
```

**Não há tenant_id** dentro do banco (single-tenant = banco isolado).

### Schemas por Domínio

```sql
-- Estrutura dentro de cada banco
CREATE SCHEMA IF NOT EXISTS public;     -- core
CREATE SCHEMA IF NOT EXISTS syscost;    -- módulo custos
CREATE SCHEMA IF NOT EXISTS doc;        -- documentação
CREATE SCHEMA IF NOT EXISTS rh;         -- RH
CREATE SCHEMA IF NOT EXISTS proj;       -- projetos
CREATE SCHEMA IF NOT EXISTS fin;        -- financeiro
CREATE SCHEMA IF NOT EXISTS audit;      -- auditoria
```

### Convenções (Obrigatórias)

Aplicar padrões definidos em [contrato_geral_axyspro.md](contracts/contrato_geral_axyspro.md):

- ✅ Tabelas no **singular**: `doc_documento`, `rh_pessoa`, não `documentos`
- ✅ Campos: `tabela_campo` (ex: `doc_documento_criado_em`)
- ✅ Valores monetários: `NUMERIC(14,2)`
- ✅ Datas: `YYYY-MM-DD` (ISO)
- ✅ Soft-delete (inativação lógica, não deletar)
- ✅ Sem `ENUM` PostgreSQL → `TEXT` com `CHECK`

---

## Integração com Ecossistema Axys

### Com AxysHub

```
AxysPro
   ↓ (valida licença)
AxysHub (Control Plane)
   ↓ (autoriza features)
retorna JWT + claims
```

- Pro valida token JWT emitido por Hub
- Hub define quais módulos estão licenciados
- Operação offline por período tolerado

---

### Com AxysEasy

```
AxysPro SysCost
   ↓ (consulta composições)
AxysEasy (microapp)
   ↓ (retorna CPUs)
importa orçamentos
```

- Pro integra composições de Easy para análise
- API de Easy disponibiliza catálogos
- Contrato definido em `integrations/with-easy.md`

---

### Com Sistemas Externos

- **ERP Fiscal:** integração NF-e, sped fiscal
- **Sistema RH Externo:** sincronização de folha
- **Bancos:** conciliação automática
- **Conformidade:** auditoria regulatória (LGPD, Lei Geral de Proteção de Dados)

---

## Framework & Stack Técnico

### Backend

- **Framework:** Django (ORM, auth, admin)
- **Web:** Gunicorn / WSGI
- **Banco:** PostgreSQL (único SGBD oficial)
- **Autenticação:** Django auth + JWT
- **Permissões:** RBAC (role-based access control)

### Frontend

- **Renderização:** Jinja2 templates (HTML server-side)
- **Estilo:** CSS + Design System centralizado
- **Interatividade:** JavaScript vanilla (sem framework pesado)
- **UX:** Desktop-like (produtividade, não mobile-first)

### Deployment

- **Plataforma:** Render.com (cloud)
- **Alternativa:** On-premises (Docker/VM local)
- **Armazenamento:** S3-compatible (docs, anexos)
- **Backup:** Daily snapshots via Render

---

## Estrutura de Diretórios

```
axyspro/
├── backend/
│   ├── core/              # infraestrutura compartilhada
│   │   ├── auth.py        # autenticação & RBAC
│   │   ├── db.py          # conexão PostgreSQL
│   │   └── audit.py       # logging obrigatório
│   │
│   ├── modules/           # módulos funcionais
│   │   ├── syscost/       # gestão de custos
│   │   ├── doc/           # documentação & contratos
│   │   ├── rh/            # recursos humanos
│   │   ├── proj/          # projetos & acompanhamento
│   │   └── fin/           # financeiro
│   │
│   ├── templates/         # Jinja2 HTML
│   │   ├── base.html
│   │   ├── components/
│   │   └── pages/
│   │
│   └── static/            # CSS, JS, assets
│
├── docs/                  # documentação oficial
│   ├── ARCHITECTURE.md    # este arquivo
│   ├── contracts/         # contratos normativos
│   ├── adrs/              # decisões arquiteturais
│   ├── modules/           # doc de cada módulo
│   └── ui/                # documentação por tela
│
├── instance/              # runtime (não versionado)
│   ├── db_artifacts/      # migrações, dumps
│   ├── storage/           # documentos criptografados
│   ├── logs/              # auditoria & errors
│   └── uploads/           # entrada temporária
│
└── requirements.txt       # dependências Python
```

---

## Roadmap Implementação

### Fase 1 — Core + SysCost
- ✅ Infraestrutura Django
- ✅ Autenticação & RBAC
- ✅ Módulo SysCost (custos básicos)
- ✅ Documentação & contratos
- **Status:** 🟡 Planejado

### Fase 2 — Projetos & Equipes
- ⏳ Módulo Projetos
- ⏳ Alocação de RH
- ⏳ Integração com SysCost
- **Status:** 🟡 Planejado

### Fase 3 — Financeiro Completo
- ⏳ Contas a pagar/receber
- ⏳ Faturas & NF-e
- ⏳ Conciliação bancária
- **Status:** 🟡 Planejado

### Fase 4 — RH & Folha
- ⏳ Módulo RH completo
- ⏳ Folha de pagamento
- ⏳ Integração ESOCIAL
- **Status:** 🟡 Planejado

### Fase 5 — Integrações Externas
- ⏳ ERP fiscal
- ⏳ Bancos
- ⏳ AxysEasy (custos)
- **Status:** 🟡 Planejado

---

## Considerações Arquiteturais

### Por que Single-Tenant?

- ✅ Isolamento completo de dados (segurança legal)
- ✅ Performance previsível (sem query filtragem)
- ✅ Modelagem sem tenant_id (simplicidade)
- ✅ Backup independente por cliente
- ✅ Operação local possível

### Por que Django?

- ✅ ORM robusto (SQLAlchemy-like)
- ✅ Admin automático (acelerador dev)
- ✅ Middleware de permissões
- ✅ Ecossistema maduro (packages, docs)

### Por que não microserviços?

- ✅ Startup complexidade reduzida
- ✅ Transações ACID entre módulos
- ✅ Deploy simples (monolítico)
- ✅ Escala horizontal via múltiplas instâncias (por cliente)

---

## Próximos Passos

1. **Determinar primeiro cliente-piloto** para validar arquitetura
2. **Definir schema.sql** com tabelas da Fase 1
3. **Criar migrations/** estrutura
4. **Começar implementação** do core + SysCost
5. **Documentar** cada módulo conforme desenvolvido

---

## Referências

- [Contrato Geral AxysPro](contracts/contrato_geral_axyspro.md) — normas obrigatórias
- [AXYS-ADR-019 Deployment](../../foundation/adrs/AXYS-ADR-019-deployment-estrategia.md) — infraestrutura
- [AxysEasy ARCHITECTURE](../axys-easy/ARCHITECTURE.md) — padrão de documentação
- [Foundation — Decisões Globais](../../foundation/) — ADRs compartilhadas
