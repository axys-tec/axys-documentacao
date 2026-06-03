# Estrutura do Repositório docs — Ecossistema Axys

**Status:** v1.0 — Finalizado (01/06/2026)  
**Fases:** ✅ FASE 1-6 completas (ADRs reorganizadas, 5 projetos documentados, integrações mapeadas)

---

## Visão Geral

Este repositório centraliza documentação, decisões arquiteturais (ADRs), contratos técnicos, schemas de banco de dados e migrations para o **ecossistema completo Axys** (5 projetos principais).

**Princípios:**
- ✅ **ADRs com prefixo de escopo:** `AXYS-ADR-*` (global), `HUB-ADR-*`, `EASY-ADR-*`, `PRO-ADR-*`
- ✅ Cada projeto tem seus próprios ADRs, schemas, seeds, migrations
- ✅ Foundation reservado para decisões **realmente ecosystem-wide** (21 ADRs)
- ✅ Schemas/migrations sempre dentro de `projects/{project}/schemas/`
- ✅ Integrações mapeadas em `projects/{project}/integrations/`
- ✅ Cross-references claras entre projetos

---

## Estrutura Atual (v1.0)

```
docs/
├── README.md                           # Hub de navegação
├── DOCS_TREE.md                        # Este arquivo
├── SKELETON_STATUS.md                  # Status da reorganização
│
├── foundation/                         # Decisões globais (em construção)
│   ├── adrs/                           # (vazio — por preencher)
│   ├── contracts/
│   ├── governance/
│   ├── domain-models/
│   ├── patterns/
│   └── glossary.md
│
├── infrastructure/                     # Infraestrutura compartilhada
│   ├── databases/
│   │   ├── audit_schema.sql
│   │   ├── hub_schema.sql
│   │   └── migration-scripts/
│   ├── deployment/
│   ├── security/
│   └── monitoring/
│
├── projects/                           # Cada projeto isolado
│   │
│   ├── axys-hub/                       # 🟢 Ativo
│   │   ├── README.md
│   │   ├── ARCHITECTURE.md (por criar)
│   │   ├── adrs/                       # 32 ADRs
│   │   ├── contracts/
│   │   ├── schemas/
│   │   │   ├── schema.sql
│   │   │   ├── seed.sql
│   │   │   └── migrations/
│   │   └── ...
│   │
│   ├── axys-easy/                      # 🟢 Ativo
│   │   ├── README.md
│   │   ├── ARCHITECTURE.md (por criar)
│   │   ├── adrs/                       # 5 ADRs
│   │   ├── modules/
│   │   ├── contracts/
│   │   ├── schemas/
│   │   │   ├── schema.sql
│   │   │   ├── seed.sql
│   │   │   └── migrations/
│   │   ├── ui-ux/
│   │   ├── next-steps/
│   │   └── ...
│   │
│   ├── axys-pro/                       # 🟡 Planejado (ERP)
│   │   ├── README.md                   # ✅ Atualizado
│   │   ├── ARCHITECTURE.md             # ✅ Criado
│   │   ├── adrs/                       # 5 ADRs específicas
│   │   ├── contracts/
│   │   │   └── contrato_geral_axyspro.md  # ✅ Normativo
│   │   ├── schemas/
│   │   │   ├── schema.sql              # 🔄 Por criar
│   │   │   ├── seed.sql                # 🔄 Por criar
│   │   │   └── migrations/
│   │   ├── modules/                    # 🔄 Por documentar
│   │   └── integrations/               # 🔄 Por criar
│   │
│   ├── axys-sync/                      # 🟢 Produção (Contabilidade)
│   │   ├── README.md                   # ✅ Bridge criado
│   │   ├── integrations/
│   │   │   ├── with-hub.md             # ✅ Autenticação & tenants
│   │   │   ├── with-easy.md            # ✅ Consumo de dados
│   │   │   └── data-flows.md           # ✅ Fluxos completos
│   │   └── docs-reference.md           # Link para docs remotas
│   │
│   ├── axys-sync-loccitane/            # 🟢 Produção (Especializado)
│   │   ├── README.md                   # ✅ Bridge criado
│   │   ├── integrations/
│   │   │   └── with-easy.md            # ✅ Futuro: orçamentos
│   │   └── docs-reference.md           # Link para docs remotas
│   │
│   ├── axys-lisp/                      # 🟡 Planejado
│   │   ├── README.md
│   │   ├── schemas/ (por criar)
│   │   └── ...
│   │
│   ├── axys-rvt/                       # 🟡 Planejado
│   │   ├── README.md
│   │   └── ...
│   │
│   └── axys-ifc/                       # 🟡 Planejado
│       ├── README.md
│       └── ...
│
├── runbooks/                           # Procedimentos operacionais
│   └── (por preencher)
│
├── integrations/                       # Mapas entre projetos
│   └── (por preencher)
│
└── z_trash/old_docs_repo/             # Referência histórica
    └── (estrutura antiga, preservada)
```

---

## Padrão: Schemas e Migrations

**Regra obrigatória:** Cada projeto que tem banco de dados segue este padrão:

```
projects/{project}/schemas/
├── schema.sql           # DDL completo (idempotente, DROP IF EXISTS)
├── seed.sql             # dados essenciais (fontes de ref, usuários base)
└── migrations/
    ├── README.md        # instruções de aplicação
    ├── 001-initial-schema.sql
    ├── 002-add-feature.sql
    └── ...              # em ordem numérica (incremental)
```

**Semântica:**
- `schema.sql` = snapshot do estado atual (usar para init do zero)
- `migrations/` = histórico incremental (evolução)
- `seed.sql` = dados mínimos obrigatórios

---

## ADRs por Projeto

| Projeto | Quantidade | Status |
|---------|-----------|--------|
| axys-hub | 32 | ✅ Reorganizadas (inclui 2 Dash para depois) |
| axys-easy | 5 | ✅ Reorganizadas |
| axys-pro | 14 | ✅ Reorganizadas |
| foundation | 0 | ⏳ Por definir (global) |

**Próximo passo:** Avaliar qual ADR é realmente ecosystem-wide → `foundation/adrs/`

---

## Navegação Rápida

```
Você quer...
├─ Entender a arquitetura do Easy?
│  └─ Abra: projects/axys-easy/README.md → ARCHITECTURE.md
├─ Ver decisões do Hub?
│  └─ Abra: projects/axys-hub/adrs/
├─ Saber o schema do Easy?
│  └─ Abra: projects/axys-easy/schemas/schema.sql
├─ Aprender padrões de UI?
│  └─ Abra: projects/axys-easy/ui-ux/config_ui_ux_easy.md
└─ Integração entre projetos?
   └─ Abra: integrations/ (em construção)
```

---

## Histórico de Mudanças

| Data | Versão | Mudança |
|---|---|---|
| 31/05/2026 | 0.1 | Estrutura inicial aprovada |
| 01/06/2026 | 0.2 | Limpeza de resíduos, READMEs por projeto, ADRs reorganizadas |

---

## Notas Importantes

- ✅ Estrutura antiga preservada em `z_trash/old_docs_repo/`
- ✅ Schemas SQL movidos para `projects/{project}/schemas/`
- ⚠️ `foundation/adrs/` vazio (aguardando classificação de ADRs globais)
- ⏳ `runbooks/` e `integrations/` prontos mas vazios
