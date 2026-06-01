# Status: Reorganização do Repositório docs

**Data:** 01/06/2026  
**Status:** ✅ Skeleton montado e arquivos movidos

---

## O que foi feito

### 1. Skeleton de diretórios criado ✅

```
foundation/
  ├── adrs/                   # 14 ADRs globais copiadas
  ├── contracts/              # (vazio — será preenchido)
  ├── governance/             # (vazio — será preenchido)
  ├── domain-models/          # (vazio — será preenchido)
  └── patterns/               # (vazio — será preenchido)

infrastructure/
  ├── databases/              # migration scripts genéricos copiados
  │   └── migration-scripts/
  ├── deployment/
  ├── security/
  └── monitoring/

projects/
  ├── axys-hub/
  │   └── schemas/            # ✅ schema.sql, seed.sql + migrations
  ├── axys-easy/
  │   ├── schemas/            # ✅ schema.sql, seed.sql
  │   ├── ui-ux/              # ✅ config_ui_ux_easy.md, prompt_nova_tela.md
  │   ├── modules/            # ✅ catalogo_work_pages.md
  │   ├── next-steps/         # ✅ next_step_app.md, next_step_map.md
  │   ├── contracts/          # ✅ MODULO_ATIVO_ARCHITECTURE_CONTRACT
  │   ├── adrs/               # ✅ 5 ADRs do Easy copiadas
  │   └── ...
  ├── axys-pro/               # (vazio — pronto para futura implementação)
  ├── axys-lisp/              # (vazio)
  ├── axys-rvt/               # (vazio)
  └── axys-ifc/               # (vazio)

runbooks/
integrations/
```

### 2. Arquivos movidos / copiados

**ADRs:**
- ✅ 14 ADRs globais → `foundation/adrs/`
- ✅ 5 ADRs do Easy → `projects/axys-easy/adrs/`
- ⚠️ 2 ADRs do Dash → (aguardando projeto axys-dash)

**Schemas SQL:**
- ✅ `hub_schema.sql` → `projects/axys-hub/schemas/schema.sql`
- ✅ `hub_seed.sql` → `projects/axys-hub/schemas/seed.sql`
- ✅ `easy_schema.sql` → `projects/axys-easy/schemas/schema.sql`
- ✅ `easy_seed.sql` → `projects/axys-easy/schemas/seed.sql`
- ✅ Hub migrations → `projects/axys-hub/schemas/migrations/`
- ✅ Generic migration scripts → `infrastructure/databases/migration-scripts/`

**Documentação do Easy:**
- ✅ `config_ui_ux_easy.md` → `projects/axys-easy/ui-ux/`
- ✅ `prompt_nova_tela.md` → `projects/axys-easy/ui-ux/`
- ✅ `catalogo_work_pages.md` → `projects/axys-easy/modules/`
- ✅ `MODULO_ATIVO_ARCHITECTURE_CONTRACT_v0.md` → `projects/axys-easy/contracts/`
- ✅ `next_step_app.md` → `projects/axys-easy/next-steps/`
- ✅ `next_step_map.md` → `projects/axys-easy/next-steps/`
- ✅ `PROMPT_PROXIMA_SESSAO_INSUMOS.md` → `projects/axys-easy/next-steps/`

**Contratos:**
- ✅ Contratos do Easy → `projects/axys-easy/contracts/`
- ✅ Contratos compartilhados (possivelmente) → `projects/axys-hub/contracts/`

### 3. Estrutura antiga ainda presente

- `adr/` — cópias (originais ainda lá para referência)
- `AxysPro/` — estrutura antiga (será reorganizada depois)
- `db/` — estrutura antiga (esquemas foram copiados para projects)

---

## Próximos passos

1. ⬜ Validar estrutura (não há duplicação prejudicial?)
2. ⬜ Criar READMEs para cada projeto explicando seu propósito
3. ⬜ Avalizar documentação (completude e clareza)
4. ⬜ Decidir: deletar estrutura antiga ou manter como referência?

---

## Notas

- ✅ Todos os arquivos **importantes foram copiados**, não movidos (segurança)
- ✅ Estrutura segue o padrão aprovado em `DOCS_TREE.md`
- ✅ Schemas SQL com seus `migrations/` já estão no lugar certo
- ⚠️ Alguns diretórios estão vazios (runbooks, integrations) — serão preenchidos durante validação

