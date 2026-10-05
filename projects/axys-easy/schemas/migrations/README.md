# AxysEasy — Database Migrations

**Status:** ✅ Pronto para uso  
**Sistema:** Incremental (numerado sequencialmente)

---

## Padrão de Migrations

Cada migration é um arquivo SQL numerado e incremental:

```
001-initial-schema.sql      # Estado inicial (equivalente schema.sql)
002-add-ativo-schema.sql    # Adiciona tabelas ativo.*
003-add-audit-tables.sql    # Adiciona audit.logs
...
```

### Regra Importante

- ✅ Cada migration **deve ser idempotente** (safe to run twice)
- ✅ Use `IF NOT EXISTS` / `ON CONFLICT DO NOTHING`
- ✅ Sempre inclua `DROP IF EXISTS` com cuidado
- ❌ Nunca delete dados sem backups

---

## Como Aplicar Migrations

### Desenvolvimento

```bash
# Aplicar todas as migrations pendentes
psql -d axys_easy_dev < 001-initial-schema.sql
psql -d axys_easy_dev < 002-add-ativo-schema.sql
# ... etc
```

### Produção

```bash
# Via tool (recomendado)
python scripts/run_migration.py --env prod

# Manual (com cuidado!)
psql -d axys_easy_prod -h render-host -U dbuser < 001-initial-schema.sql
```

---

## Criando Uma Nova Migration

### Passo 1: Preparar SQL

```sql
-- 004-add-my-feature.sql
-- Descrição: Adiciona suporte para XYZ

-- Tabela nova
CREATE TABLE IF NOT EXISTS catalogo.features (
  feat_id SERIAL PRIMARY KEY,
  feat_nome TEXT NOT NULL,
  feat_criado_em TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Alteração em tabela existente
ALTER TABLE catalogo.insumos
  ADD COLUMN IF NOT EXISTS ins_feature_id INTEGER
  REFERENCES catalogo.features(feat_id) ON DELETE SET NULL;

-- Rollback (documentar)
-- DROP TABLE catalogo.features CASCADE;
-- ALTER TABLE catalogo.insumos DROP COLUMN IF EXISTS ins_feature_id;
```

### Passo 2: Testar Localmente

```bash
# Aplicar migration
psql -d axys_easy_dev < migrations/004-add-my-feature.sql

# Verificar resultado
psql -d axys_easy_dev -c "\dt catalogo.*"
psql -d axys_easy_dev -c "\d catalogo.insumos"
```

### Passo 3: Documentar

Adicionar header à migration com:
- **Descrição:** O que mudou
- **Rollback:** Como desfazer
- **Data:** Quando foi criada

---

## Histórico de Migrations

O arquivo é nomeado por DATA, não por número sequencial — o número presumia uma fila única, e
migrations nascem em frentes paralelas. A data ordena sem fingir sequência.

| arquivo | o que faz | dev | produção |
|---|---|---|---|
| `001-initial-schema.sql` | estado inicial (= `schema.sql`) | ✅ 31/05/2026 | ✅ 31/05/2026 |
| `2026-09-20_fuzzystrmatch_para_busca.sql` | extensão `fuzzystrmatch` p/ o ranking da busca | ✅ | ✅ (conferida em 05/10) |
| `2026-10-04_responsavel_tecnico.sql` | conselhos, documentos de resp. técnica, profissões, RT e quem assina | ✅ 04/10/2026 | ✅ **05/10/2026** |

> **Como conferir, em vez de supor.** O estado desta tabela se verifica no banco, não na memória:
> extensão em `pg_extension`, tabela em `information_schema.tables`, coluna em
> `information_schema.columns`. Em 05/10 marquei a do `fuzzystrmatch` como não aplicada em
> produção por inferência — e ela estava lá desde sempre.

---

## ⚠️ Contingências

### Migration Falhou em Produção

1. **Verificar erro:** `psql ... -c "SELECT version();"`
2. **Revisar estado:** Quais migrations rodaram?
3. **Rollback:** Executar SQL de rollback da migration
4. **Investigar:** Por que falhou? Conflito de dados?
5. **Corrigir:** Ajustar migration e reapplicar

### Lock em Tabela

```
ERROR: relation "..." is locked
```

**Solução:**
```sql
SELECT * FROM pg_stat_activity WHERE state = 'active';
-- Identificar conexão bloqueada
-- CANCEL BACKEND de ser necessário
```

---

## TODO

- [ ] Automatizar aplicação de migrations
- [ ] Adicionar rollback automático em erro
- [ ] Versioning no schema_version table
- [ ] Notify para migrations críticas

