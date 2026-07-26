# Estrutura do Repositório docs — Ecossistema Axys

**Status:** vivo — última reconciliação **26/07/2026**
**Repo:** `axys-tec/axys-documentacao` (embutido em cada projeto Axys como **git submodule** em `docs/`)

---

## Visão Geral

Repositório **centralizado** de documentação, decisões arquiteturais (ADRs), contratos técnicos, schemas de banco e runbooks do **ecossistema Axys**. É um repo **isolado**, consumido por todos os projetos via submodule — ver **[Fluxo de trabalho](README.md#-fluxo-de-trabalho-repo-é-submodule)** no README.

**Princípios:**
- ✅ **ADRs com prefixo de escopo:** `AXYS-ADR-*` (global, em `foundation/`), `HUB-ADR-*`, `EASY-ADR-*`, `PRO-ADR-*` (por projeto).
- ✅ Cada projeto tem seus próprios ADRs, schemas, seeds, migrations, contratos.
- ✅ `foundation/` reservado a decisões **realmente ecosystem-wide**.
- ✅ Schemas/migrations sempre em `projects/{project}/schemas/`.
- ✅ Doc **específico de um projeto vive dentro do projeto** — nada de projeto na raiz.
- ✅ Cross-references por markdown link com caminho relativo.

---

## Estrutura Atual (reconciliada com a árvore real)

```
docs/
├── README.md                           # Hub de navegação + fluxo de trabalho (submodule)
├── DOCS_TREE.md                        # Este arquivo — mapa do repo
├── ADR_INDEX.md                        # Índice consolidado de ADRs
│
├── foundation/                         # Decisões GLOBAIS do ecossistema
│   ├── adrs/                           # 22 ADRs AXYS-ADR-* (global)
│   ├── contracts/                      # contratos técnicos reutilizáveis
│   ├── domain-models/                  # conceitos de negócio
│   ├── governance/                     # padrões e convenções
│   └── patterns/                       # padrões técnicos
│
├── infrastructure/                     # Infraestrutura compartilhada
│   ├── databases/                      # schemas compartilhados (audit, hub)
│   ├── deployment/                     # deploy, CI/CD, Render
│   ├── security/                       # auth, secrets, TLS
│   └── monitoring/                     # logging, métricas, alertas
│
├── projects/                           # Cada projeto isolado (doc específico mora AQUI)
│   ├── axys-hub/                       # 🟢 Ativo — 5 ADRs
│   ├── axys-easy/                      # 🟢 Ativo — 6 ADRs · hospeda STORAGE_TREE.md
│   ├── axys-gestor/                    # 🟡 Concepção — ecossistema de micro-apps de varejo
│   ├── axys-pro/                       # 🟡 Planejado — 2 ADRs (ERP)
│   ├── axys-cad/                       # 🟡 Planejado — CAD/BIM (ex-"axys-lisp")
│   ├── axys-rvt/                       # 🟡 Planejado — plugin Revit
│   ├── axys-ifc/                       # 🟡 Planejado — processamento IFC
│   ├── axys-sync/                      # 🟢 Produção — bridge Contabilidade
│   └── axys-sync-loccitane/            # 🟢 Produção — especializado (L'Occitane)
│
├── integrations/                       # Mapas de fluxo entre projetos (por preencher)
│
└── archive/                            # Referência histórica
    └── retired-code/                   # código/estruturas aposentadas
```

> Doc específico de projeto **não** fica na raiz. Foi o caso do `STORAGE_TREE.md` (layout de storage do Easy) — **movido** para `projects/axys-easy/STORAGE_TREE.md` em 26/07/2026.

---

## Padrão: Schemas e Migrations

Cada projeto com banco segue:

```
projects/{project}/schemas/
├── schema.sql           # DDL completo (snapshot do estado atual — init do zero)
├── seed.sql             # dados essenciais (fontes de ref, usuários base)
└── migrations/
    ├── README.md        # instruções de aplicação
    ├── 001-initial-schema.sql
    └── ...              # ordem numérica, incremental
```

- `schema.sql` = foto do estado atual · `migrations/` = histórico incremental · `seed.sql` = mínimo obrigatório.

---

## ADRs por Escopo (contagem real — 26/07/2026)

| Escopo | Quantidade | Observação |
|--------|-----------|------------|
| foundation (global) | 22 | `AXYS-ADR-*` — valem para todo o ecossistema |
| axys-easy | 6 | `EASY-ADR-*` |
| axys-hub | 5 | `HUB-ADR-*` |
| axys-pro | 2 | `PRO-ADR-*` |
| axys-cad / rvt / ifc / gestor | 0 | ainda sem ADRs próprias |

Índice consolidado: **[ADR_INDEX.md](ADR_INDEX.md)**.

---

## Navegação Rápida

```
Você quer...
├─ Entender a arquitetura do Easy?
│  └─ projects/axys-easy/ARCHITECTURE.md
├─ Ver o layout de storage do Easy?
│  └─ projects/axys-easy/STORAGE_TREE.md
├─ Ver decisões globais?
│  └─ foundation/adrs/  (índice em ADR_INDEX.md)
├─ Saber o schema de um projeto?
│  └─ projects/{project}/schemas/schema.sql
└─ Como editar estes docs (submodule)?
   └─ README.md → "Fluxo de trabalho"
```

---

## Histórico de Mudanças

| Data | Mudança |
|---|---|
| 31/05/2026 | Estrutura inicial aprovada |
| 01/06/2026 | Limpeza de resíduos, READMEs por projeto, ADRs reorganizadas |
| 26/07/2026 | Reconciliação com a árvore real: +axys-gestor, +axys-sync/-loccitane, axys-lisp→axys-cad, `z_trash`→`archive/retired-code`, `STORAGE_TREE.md`→`projects/axys-easy/`, contagem de ADRs corrigida, fluxo de trabalho do submodule documentado |
