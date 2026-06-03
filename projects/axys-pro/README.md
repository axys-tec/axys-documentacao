# AxysPro — ERP Enterprise

**Status:** 🟡 Planejado  
**Tipo:** ERP Modular para Engenharia  
**Versão:** —  
**Repositório:** axys-pro (futuro)  

---

## O que é?

AxysPro é o **sistema ERP completo para escritórios de engenharia, construtoras e empresas de prestação de serviços**.

**Diferentemente do AxysEasy** (ferramenta especializada de orçamentos), Pro integra:
- 🏗️ **Gestão de Projetos** — obras, phases, atividades, timeline
- 💰 **Custos & Orçamentos** — SysCost, análise orçado vs. realizado, integração Easy
- 📄 **Documentação** — contratos, memoriais, especificações com versioning
- 👥 **RH & Folha** — funcionários, payroll, alocação de equipes
- 💵 **Financeiro** — contas a pagar/receber, NF-e, bancos
- 🔐 **Auditoria** — rastreamento completo de operações
- 🔗 **Integrações** — ERP fiscal, bancários, sistemas externos

**Arquitetura:**
- Single-tenant por instalação (cada cliente = banco PostgreSQL dedicado)
- Framework Django (produtividade, ORM robusto, admin automático)
- Single-page-like UX (desktop ERPs tradicionais)
- Extensível por módulos (novos módulos sem refatoração)

---

## 📋 Documentação

| Documento | Descrição |
|-----------|-----------|
| [ARCHITECTURE.md](ARCHITECTURE.md) | ✅ Arquitetura de módulos, stacks, infraestrutura |
| [contracts/contrato_geral_axyspro.md](contracts/contrato_geral_axyspro.md) | ✅ Contrato normativo (regras obrigatórias) |
| [contracts/00_regra_mae_axys.md](contracts/00_regra_mae_axys.md) | ✅ Regra-mãe (referência histórica) |
| [adrs/](adrs/) | 📋 Decisões específicas de Pro |
| [schemas/](schemas/) | 🔄 Database schema + migrations |
| [modules/](modules/) | 🔄 Documentação por módulo funcional |

---

## 🚀 Fases de Implementação

### Fase 1 — Core + SysCost
- Infraestrutura Django
- Autenticação & RBAC
- Módulo SysCost (gestão de custos)
- Documentação & contratos
- **Status:** 🟡 Planejado

### Fase 2 — Projetos & Equipes
- Módulo Projetos (obras, phases, atividades)
- Alocação de RH
- Integração SysCost ↔ Projetos

### Fase 3 — Financeiro
- Contas a pagar/receber
- Notas fiscais & NF-e
- Conciliação bancária

### Fase 4 — RH & Folha
- Cadastro de funcionários
- Folha de pagamento
- Integração ESOCIAL / fiscal

### Fase 5 — Integrações Externas
- ERP Fiscal
- Bancos (API)
- AxysEasy (importar orçamentos)

---

## 📁 Estrutura do Projeto

```
docs/projects/axys-pro/
├── README.md                    # este arquivo
├── ARCHITECTURE.md              # ✅ arquitetura completa
│
├── contracts/                   # contratos normativos
│   ├── contrato_geral_axyspro.md    # ✅ regras obrigatórias
│   ├── 00_regra_mae_axys.md         # histórico
│   └── ...
│
├── adrs/                        # decisões específicas
│   └── AxysPro_R00.md           # histórico
│
├── schemas/                     # database
│   ├── schema.sql               # 🔄 por criar
│   └── migrations/              # 🔄 versionadas
│
├── modules/                     # 🔄 por definir
│   ├── syscost.md               # gestão de custos
│   ├── documentacao.md          # contratos & docs
│   ├── projetos.md              # obras & fases
│   ├── rh.md                    # recursos humanos
│   └── financeiro.md            # contas & NF
│
├── integrations/                # 🔄 por criar
│   ├── with-hub.md              # licenciamento
│   └── with-easy.md             # orçamentos
│
├── operations/                  # 🔄 por criar
│   └── deployment.md            # render, env vars
│
└── ui-ux/                       # 🔄 por criar
    └── design_system.md         # padrões visuais
```

---

## 🔗 Integrações no Ecossistema Axys

```
AxysPro (ERP Central)
   ├─ AxysHub (Control Plane)
   │  └─ licenciamento, billing, tenant management
   │
   ├─ AxysEasy (MicroApp Orçamentos)
   │  └─ integra CPUs, composições, análise
   │
   └─ Sistemas Externos
      ├─ ERP Fiscal (NF-e, SPED)
      ├─ Sistema Bancário (conciliação)
      └─ Externo RH (folha, ESOCIAL)
```

---

## 🎯 Próximos Passos

**Quando Pro for iniciado:**

1. **Estrutura Django** — app inicial, settings, migrations
2. **Database schema.sql** — tabelas da Fase 1
3. **Módulo SysCost** — primeiro módulo funcional
4. **Teste de integração** — validação com AxysHub
5. **Documentação de implementação** — README por módulo

Consulte [ARCHITECTURE.md](ARCHITECTURE.md) para detalhes técnicos.

---

## 📚 Referências

- [AxysEasy — ERP Light (orçamentos)](../axys-easy/README.md)
- [AxysHub — Control Plane (licenciamento)](../axys-hub/README.md)
- [Foundation — Decisões Globais](../../foundation/)
- [Contrato Geral AxysPro](contracts/contrato_geral_axyspro.md) — **LEITURA OBRIGATÓRIA**
