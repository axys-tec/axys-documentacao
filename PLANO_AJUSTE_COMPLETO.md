# Plano de Ajuste Completo — Docs Repository

**Data:** 01/06/2026  
**Escopo:** Reorganizar docs para maximizar reuso, clareza e manutenibilidade  
**Foco:** Hub (produção) + Easy (confiável, fresco)

---

## 1️⃣ Análise Atual

### Hub (32 ADRs + 2 Contratos + Schemas)
**Status:** 🟢 Produção  
**Avaliação:** Conteúdo abundante, merece reajuste

```
projects/axys-hub/
├── adrs/                    # 32 ADRs (muito volume)
│   ├── ADR-000 — Arquitetura inicial executável
│   ├── ADR-001 — Tenancy e isolamento
│   ├── ADR-002 — Licenciamento centralizado
│   ├── ... (29 mais)
│   └── ADR-030 — Ferramentas Excel/AutoLISP/API
├── contracts/
│   ├── axys_ecossistema_contrato_arquitetural.md
│   └── easy_modulo_ativo_architecture_contract.md  ← ERRADO (não é Hub!)
└── schemas/
    ├── schema.sql           ✅
    ├── seed.sql             ✅
    └── migrations/          ✅
```

### Easy (5 ADRs + 3 Contratos + UI/UX + Modules + Next-Steps + Schemas)
**Status:** 🟢 Confiável e Fresco  
**Avaliação:** Bem estruturado, bom ponto de partida

```
projects/axys-easy/
├── adrs/                    # 5 ADRs (bem focado)
│   ├── ADR-003 — Separação core/módulos
│   ├── ADR-011 — Seed mínimo
│   ├── ADR-014 — UX e consistência
│   ├── ADR-022 — Licenciamento
│   └── ADR-030 — Ferramentas Excel/API
├── contracts/               # 3 bem focados
│   ├── axys_ecossistema_contrato_arquitetural.md
│   ├── easy_modulo_ativo_architecture_contract.md  ✅
│   └── modulo_ativo_sumario_executivo.md           ✅
├── modules/
│   └── catalogo_work_pages.md                       ✅
├── ui-ux/                   # 2 canônicos
│   ├── config_ui_ux_easy.md                         ✅
│   └── prompt_nova_tela.md                          ✅
├── next-steps/              # Roadmap claro
│   ├── PROMPT_PROXIMA_SESSAO_INSUMOS.md
│   ├── next_step_app.md
│   └── next_step_map.md
└── schemas/
    ├── schema.sql           ✅
    ├── seed.sql             ✅
    └── migrations/          (vazio — por criar)
```

### Pro (14 ADRs + 5 Contratos + AxysPro_R00.md)
**Status:** 🟡 Planejado  
**Avaliação:** Documentação especulativa (projeto nem iniciado)

```
projects/axys-pro/
├── adrs/                    # 14 ADRs (especulativos)
├── contracts/
│   ├── 00_regra_mae_axys.md
│   ├── axys_core.md
│   ├── checklist_documentacao_axys.md
│   ├── contrato_geral_axyspro.md
│   └── template_revisao_pr.md
└── AxysPro_R00.md           # Documento principal
```

### Outros (Lisp, Rvt, Ifc, Pro)
**Status:** 🟡 Placeholders  
**Conteúdo:** Apenas READMEs

---

## 2️⃣ Duplicações Identificadas

### ❌ ADRs Duplicadas em Hub + Easy + Pro

| ADR | Hub | Easy | Pro | Deve ficar em |
|-----|-----|------|-----|---|
| ADR-000 — Arquitetura | ✅ | ❌ | ✅ | **foundation/** (é global) |
| ADR-003 — Core/módulos | ✅ | ✅ | ✅ | **foundation/** (é global) |
| ADR-005 — Versionamento | ✅ | ❌ | ✅ | **foundation/** (é global) |
| ADR-006 — Segurança | ✅ | ❌ | ✅ | **foundation/** (é global) |
| ADR-007 — Auditoria | ✅ | ❌ | ✅ | **foundation/** (é global) |
| ADR-008 — Armazenamento | ✅ | ❌ | ✅ | **foundation/** (é global) |
| ADR-014 — UX | ✅ | ✅ | ✅ | **foundation/** (padrão UI) |
| ADR-015 — Performance | ✅ | ❌ | ✅ | **foundation/** (é global) |
| ADR-016 — i18n | ✅ | ❌ | ✅ | **foundation/** (é global) |
| ADR-017 — Suporte/SLA | ✅ | ❌ | ✅ | **foundation/** (é global) |
| ADR-018 — Comercial | ✅ | ❌ | ✅ | **foundation/** (é global) |
| ADR-019 — Roadmap | ✅ | ❌ | ✅ | **foundation/** (é global) |
| ADR-020 — LGPD | ✅ | ❌ | ✅ | **foundation/** (é legal/global) |
| ADR-030 — Ferramentas | ✅ | ✅ | ❌ | **foundation/** (afeta todos) |

**Total:** ~13 ADRs devem ir para `foundation/adrs/`

### ❌ Contratos Duplicados

```
axys_ecossistema_contrato_arquitetural.md
├── em projects/axys-hub/contracts/
├── em projects/axys-easy/contracts/
└── em z_trash/old_docs_repo/contratos/

easy_modulo_ativo_architecture_contract.md
├── em projects/axys-hub/contracts/  ← ERRADO!
├── em projects/axys-easy/contracts/  ← CORRETO
└── em z_trash/old_docs_repo/contratos/
```

---

## 3️⃣ Plano de Reorganização

### **FASE 1: Limpar Duplicações (Foundation)**

**Ação:** Mover ADRs globais para `foundation/adrs/`

```
foundation/adrs/
├── ADR-000-arquitetura-inicial-executavel.md
├── ADR-001-tenancy-e-isolamento.md
├── ADR-002-licenciamento-centralizado.md
├── ADR-003-separacao-core-modulos-microapps.md
├── ADR-004-operacao-offline-e-modo-degradado.md
├── ADR-005-versionamento-e-compatibilidade.md
├── ADR-006-seguranca-e-gestao-de-segredos.md
├── ADR-007-auditoria-e-logging.md
├── ADR-008-armazenamento-de-arquivos-e-anexos.md
├── ADR-009-backup-e-disaster-recovery.md
├── ADR-010-observabilidade-metricas-e-alertas.md
├── ADR-012-integracao-com-erps-externos.md
├── ADR-013-extensibilidade-e-plugins.md
├── ADR-014-ux-e-consistencia-de-interface.md
├── ADR-015-performance-e-estrategia-de-cache.md
├── ADR-016-internacionalizacao-i18n-l10n.md
├── ADR-017-suporte-e-sla.md
├── ADR-018-politica-comercial-e-precificacao.md
├── ADR-019-roadmap-e-governanca-de-produto.md
├── ADR-020-compliance-lgpd-e-retencao-de-dados.md
├── ADR-024-atualizacao-e-deploy-cloud-onprem.md
└── ADR-030-ferramentas-excel-autolisp-api.md
```

**Ação:** Remover duplicatas de Easy/Pro (linkar para foundation)

**Ação:** Limpar contratos duplicados
- Mover `axys_ecossistema_contrato_arquitetural.md` → `foundation/contracts/`
- Remover de Hub e Easy (linkar)
- Remover de Pro (linkar)

### **FASE 2: Ajustar Hub (Produção)**

**Status:** 🔄 Em reajuste

#### ADRs Específicas do Hub (ficam em `projects/axys-hub/adrs/`)
```
✅ ADR-011 — AxysHub Seed Mínimo
✅ ADR-023 — Hub Control Plane
✅ ADR-025 — Licenciamento Lease Token
✅ ADR-027 — Arquitetura Push-Only ERP para Hub
```

#### Remover de Hub
- ADR-001, 002, 003... (todas as globais listadas acima)

#### Revisar Hub
- ⚠️ `contracts/easy_modulo_ativo_architecture_contract.md` — REMOVER (é do Easy!)
- ✅ `schemas/schema.sql` — REVISAR (produção ativa)
- ✅ `schemas/seed.sql` — REVISAR (produção ativa)
- ❌ `contracts/axys_ecossistema_contrato_arquitetural.md` — MOVER para foundation

### **FASE 3: Validar Easy (Confiável)**

**Status:** ✅ Mantém estrutura (é a melhor)

#### Já está bom
- ✅ `adrs/` — 5 bem focadas
- ✅ `contracts/` — 3 específicas do módulo Ativo
- ✅ `modules/catalogo_work_pages.md`
- ✅ `ui-ux/` — 2 canônicos
- ✅ `next-steps/` — roadmap claro

#### Revisar
- ⚠️ `contracts/axys_ecossistema_contrato_arquitetural.md` — REMOVER (linkar de foundation)
- ⚠️ `schemas/migrations/` — CRIAR (tá vazio)
- ✅ `schemas/schema.sql` — REVISAR (correto)
- ✅ `schemas/seed.sql` — REVISAR (correto)

### **FASE 4: Tratar Pro (Especulativo)**

**Status:** 🤔 Decidir futuro

**Opção A: Manter como referência**
- Limpar para apenas ADRs globais (linkadas de foundation)
- Manter AxysPro_R00.md como specs para quando iniciar
- Limpar contracts (apenas templates)

**Opção B: Considerar com cautela**
- Risco: será refutado quando projeto realmente iniciar
- Ganho: documentação de contexto histórico

**Recomendação:** Opção A (manter limpo, referencial)

---

## 4️⃣ Tarefas Específicas

### Imediato (HOJE)
- [ ] Mover ~13 ADRs globais para `foundation/adrs/`
- [ ] Revisar `foundation/adrs/ADR-029-SSO-JWT-hub-easy.md` (está bem? ou precisa ajuste?)
- [ ] Remover contrato duplicado `easy_modulo_ativo_architecture_contract.md` de Hub

### Curto Prazo (Hub)
- [ ] Revisar `projects/axys-hub/schemas/schema.sql` (produção, importante!)
- [ ] Revisar `projects/axys-hub/schemas/seed.sql` (dados iniciais)
- [ ] Criar READMEs para `projects/axys-hub/adrs/`, `contracts/`, `api/`, `operations/`
- [ ] Documentar integrações: como Easy consome Hub?

### Curto Prazo (Easy)
- [ ] Criar `projects/axys-easy/schemas/migrations/README.md`
- [ ] Revisar `projects/axys-easy/schemas/schema.sql`
- [ ] Revisar `projects/axys-easy/schemas/seed.sql`
- [ ] Validar `contracts/axys_ecossistema_contrato_arquitetural.md` (copia ou referência?)
- [ ] Completar `projects/axys-easy/ARCHITECTURE.md` (tá placeholder)

### Médio Prazo (Foundation)
- [ ] Criar `foundation/contracts/ecosystem-architecture.md` (ou usar existente?)
- [ ] Criar `foundation/contracts/tenant-model.md`
- [ ] Criar `foundation/contracts/auth-model.md`
- [ ] Criar `foundation/governance/CODING_STANDARDS.md`
- [ ] Criar `foundation/governance/DATABASE_CONVENTIONS.md`
- [ ] Criar `foundation/patterns/hierarchical-trees.md` (parent_id, order, path)

### Longo Prazo (Pro)
- [ ] Decidir: manter ou revisar?
- [ ] Se manter: limpar para apenas template
- [ ] Se revisar: integrar aprendizados de Hub/Easy

---

## 5️⃣ Métricas de Sucesso

| Item | Antes | Depois |
|------|-------|--------|
| ADRs globais duplicadas | 13 | 0 |
| Contratos duplicados | 2+ | 0 |
| foundation/adrs/ preenchido | 0% | 100% |
| foundation/contracts/ preenchido | 0% | 70% |
| Hub com ARCHITECTURE.md | ❌ | ✅ |
| Easy com ARCHITECTURE.md | ❌ | ✅ |
| Easy migrations/ preenchido | ❌ | ✅ |
| Links/referências cruzadas | 0 | 15+ |

---

## 6️⃣ Roadmap de Execução

```
HOJE      → Fase 1 (movimentar ADRs globais)
           + Limpar contratos duplicados

SEMANA 1  → Fase 2 (ajustar Hub)
           + Fase 3 (validar Easy)

SEMANA 2  → Fase 4 (tratar Pro)
           + Começar foundation/contracts

SEMANA 3+ → Evolução gradual de foundation/
           + Preparar integrations/ (Hub ↔ Easy, etc)
```

---

## 📋 Próximo Passo

**Quer que eu comece com a FASE 1?** (Reorganizar ADRs globais)

Vou:
1. Mover 13 ADRs para `foundation/adrs/`
2. Remover duplicatas de Easy/Pro (criar links)
3. Limpar contratos duplicados
4. Atualizar DOCS_TREE.md


---

## 7️⃣ Projetos Adicionais Descobertos

### Axys_Sync (8 documentos)
**Localização:** `/Users/rdias07/Documents/GitHub/axys-sync/docs/`  
**Status:** 🟢 Produção  
**Conteúdo:**
```
axys_sync/docs/
├── axys_sync_ascont_regras_vendas.md
├── axys_sync_baseline_operacional.md
├── axys_sync_business_matrix.md
├── axys_sync_business_rules.md
├── axys_sync_continuous_redesign.md
├── axys_sync_documentacao.md
├── axys_sync_runtime_environment.md
└── axys_sync_smoke_test_checklist.md
```

**Análise:**
- ✅ Documentação de domínio bem focada (contabilidade/vendas)
- ⚠️ Não segue padrão foundation/projects/schemas
- ❌ Sem ADRs estruturadas
- ❌ Sem contratos técnicos
- ⚠️ Business rules soltas (não em código)

**Ação:** Deixar onde está (repo independente) MAS fazer bridge com axys-easy/docs

### Axys_Sync_Loccitane (13 documentos + dados)
**Localização:** `/Users/rdias07/Documents/GitHub/axys-sync-loccitane/docs/`  
**Status:** 🟢 Produção (especializado)  
**Conteúdo:**
```
axys-sync-loccitane/docs/
├── axys_sync_*.md                  # 7 padrão (compartilhado com sync)
├── contas_pagar_receber_vo.txt     # Implementação (dados reais)
├── custo_mercadoria_doutrina.md
├── expansao_futura_custo_vo.md
├── validacao_empirica_saidas.md
├── varejonline_api_endpoints.txt
└── vo_*.{json,txt}                 # Dados de VO mapeamento
```

**Análise:**
- ✅ Especializado para domínio Loccitane
- ⚠️ Mistura docs com dados brutos (VO mapping, endpoints)
- ⚠️ Sem estrutura de projeto
- ❌ Sem ADRs, schemas, migrations
- ✅ Business validações bem documentadas

**Ação:** Deixar onde está MAS considerar refatorar dados para JSON/SQL estruturado

---

## 8️⃣ Visão de Ecossistema Completo

```
Ecossistema Axys
│
├─ axys-easy/                       ← COORDENADOR
│  └─ docs/ (subrepo)               # Central de documentação
│     ├─ foundation/                # Decisões globais
│     ├─ projects/axys-hub/
│     ├─ projects/axys-easy/
│     ├─ projects/axys-pro/
│     ├─ projects/axys-sync/        ← Link para axys-sync/docs
│     ├─ projects/axys-sync-loccitane/  ← Link para axys-sync-loccitane/docs
│     └─ integrations/              # Fluxos entre projetos
│
├─ axys-hub/                        # Auth central + tenants (produção)
│  └─ (docs gerenciados em axys-easy/docs)
│
├─ axys-sync/                       # Engine de contabilidade (produção)
│  ├─ docs/                         # Business rules locais
│  ├─ backend/                      # Implementação
│  └─ frontend/
│
├─ axys-sync-loccitane/            # Sync + especialização Loccitane (produção)
│  ├─ docs/                         # Specs + dados VO (precisa refactorar)
│  ├─ backend/
│  ├─ frontend/
│  └─ data/                         # Raw VO data
│
└─ axys-pro/                        # (Planejado, não iniciado)
   └─ (documentação especulativa)
```

**Estratégia:**
1. **axys-easy/docs/** = Hub centralizado (foundation + projects)
2. **axys-sync/docs/** = Fica lá (é especializado, foco: sales/accounting)
3. **axys-sync-loccitane/docs/** = Fica lá MAS refatorar dados para estrutura clara
4. **axys-sync & loccitane** no axys-easy/docs = Links de integração apenas

---

## 9️⃣ Plano Estendido (Incluindo Sync)

### FASE 1: Limpar Duplicações (Foundation)
✅ MESMO (sem mudança)

### FASE 2: Ajustar Hub (Produção)
✅ MESMO (sem mudança)

### FASE 3: Validar Easy (Confiável)
✅ MESMO (sem mudança)

### FASE 4: Tratar Pro (Especulativo)
✅ MESMO (sem mudança)

### **FASE 5: NOVO — Integrar Sync (Bridge)**

**Ação:** Criar `projects/axys-sync/` em axys-easy/docs com:
```
projects/axys-sync/README.md        # O que é Sync, documentação local
projects/axys-sync/integrations/
├── with-easy.md                    # Como Easy consome Sync? (financeiro)
├── with-hub.md                     # Como Sync autentica no Hub?
└── data-flows.md                   # Fluxo de dados contábeis
```

**Link para docs originais:**
```
projects/axys-sync/docs-reference.md
└── "Documentação original em: /Users/rdias07/Documents/GitHub/axys-sync/docs/"
```

### **FASE 6: NOVO — Refatorar Loccitane (Dados)**

**Ação:** Criar estrutura clara em axys-sync-loccitane/docs:
```
docs/
├── business-rules/                 # Docs MD
│   ├── *.md (existentes)
├── vo-mapping/                     # Dados estruturados (JSON)
│   ├── contas_pagar.json
│   ├── plano_contas.json
│   └── provisoes.json
└── integration/
    └── with-easy-sync.md
```

**SQL Schema:** Criar `docs/schemas/` com DDL do VO (plano de contas)

---

## 🔟 Métricas Estendidas

| Item | Antes | Depois |
|------|-------|--------|
| Projects documentados | 3 | 5 |
| Integration docs | 0 | 5+ |
| Sync/Loccitane dados estruturados | 0% | 80% |
| Cross-repo links funcionando | 0 | 15+ |
| foundation/ preenchido | 0% | 100% |

---

## Roadmap Estendido

```
HOJE      → FASE 1 (movimentar ADRs globais)
           + Limpar contratos

SEMANA 1  → FASE 2 (ajustar Hub)
           + FASE 3 (validar Easy)

SEMANA 2  → FASE 4 (tratar Pro)
           + FASE 5 (criar bridge Sync)

SEMANA 3  → FASE 6 (refatorar Loccitane dados)
           + Construir integrations/

SEMANA 4+ → Evolução contínua de foundation/
```

---

## 📋 Próximo Passo (Atualizado)

**Quer começar ainda com FASE 1?** (Reorganizar ADRs globais)

Com os 5 projetos mapeados, a estratégia é:
1. **Fase 1-4:** Reorganizar axys-easy/docs (centralizado)
2. **Fase 5-6:** Integrar Sync + Loccitane (bridges + dados estruturados)
3. **Resultado:** Ecossistema coeso com documentação centralizada + especializações locais

