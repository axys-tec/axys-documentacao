# AxysDashDB — Schema mínimo absoluto (v0)
**Data:** 2026-02-06  
**Objetivo:** reduzir AxysDashDB ao mínimo (3–4 tabelas), mantendo: escopo (store), cache mês/dia por funcionalidade, trava de requisição e limpeza mensal.

---

## Princípio
- AxysDashDB é **cache descartável**.
- A API **não puxa** do ERP (push-only).
- Cada “funcionalidade” (ex.: `sales`, `finance`) pode ter dois tipos de ingest:
  - `month_snapshot` (raríssimo; até 3x/mês)
  - `day_update` (frequente; mínimo 5 min entre chamadas)
- **Não existem** tabelas específicas por domínio (vendas/financeiro).
- Existem **apenas 4 tabelas genéricas** com `feature_code`.

Para evitar explosão de tabelas (“uma tabela por feature”), usamos **tabelas genéricas** com coluna `feature_code`.

---

## Tabela 1 — dash_store_scope
Escopo mínimo de stores autorizadas no DashDB (sem depender do HubDB em runtime).

**Uso:**
- validação rápida de `store_id`
- vínculo `tenant_id → store_id`
- toggle `is_active`

Campos (sugestão):
- `tenant_id` UUID (obrigatório)
- `store_id` UUID (PK)
- `store_code` TEXT
- `store_name` TEXT
- `is_active` BOOLEAN
- `created_at` TIMESTAMPTZ

Índices:
- `(tenant_id, store_id)`

---

## Tabela 2 — dash_feature_month
Cache “snapshot” por mês e feature (ex.: vendas mês, financeiro mês).

**Chave natural:**
- `(tenant_id, store_id, feature_code, month_ref)`

Campos:
- `tenant_id` UUID
- `store_id` UUID
- `feature_code` TEXT  (ex.: `sales`, `finance`)
- `month_ref` TEXT (`YYYY-MM`)
- `payload` JSONB
- `version` INT
- `updated_at` TIMESTAMPTZ
- `etag` TEXT (opcional)

**Uso:**
- atende o app com resumo/boeing do mês
- “rodar no dia 1” ou quando cliente contratar no meio do mês (com quota)

---

## Tabela 3 — dash_feature_day
Cache diário por feature (ex.: vendas dia, financeiro dia).

**Chave natural:**
- `(tenant_id, store_id, feature_code, date_ref)`

Campos:
- `tenant_id` UUID
- `store_id` UUID
- `feature_code` TEXT
- `date_ref` DATE
- `payload` JSONB
- `version` INT
- `updated_at` TIMESTAMPTZ
- `etag` TEXT (opcional)

**Uso:**
- update diário (intraday) vindo do ERP
- atende cards e listas do dia

---

## Tabela 4 — dash_ingest_guard
Travas e quotas de ingest por store + feature + tipo.

**Chave natural:**
- `(tenant_id, store_id, feature_code, ingest_kind)`

Onde `ingest_kind` ∈:
- `month_snapshot`
- `day_update`

Campos:
- `tenant_id` UUID
- `store_id` UUID
- `feature_code` TEXT
- `ingest_kind` TEXT
- `month_ref` TEXT (`YYYY-MM`) — para controlar quota mensal
- `month_calls` INT DEFAULT 0        — conta quantas vezes month_snapshot foi chamado no mês
- `last_call_at` TIMESTAMPTZ         — trava (ex.: 5min em day_update)
- `last_anchor` TEXT                — opcional (ex.: last_sale_id, last_updated_at)
- `updated_at` TIMESTAMPTZ

**Regras (operacionais):**
- `month_snapshot`: permitir no máximo **3 chamadas por mês** (por store+feature)
- `day_update`: bloquear se `now - last_call_at < 5 minutos`

---

## Limpeza por reten??o (di?ria)
Em vez de ?jobs? por feature, a limpeza pode ser um ?nico processo interno do Hub:
- apaga dados com `day_ref` mais antigos que N dias (ex.: 30)
- apaga m?dias antigas (filesystem) na mesma janela

SQL (conceito):
- `DELETE FROM dash_summary_day WHERE day_ref < current_date - interval '30 days';`
- `DELETE FROM dash_ingest_guard WHERE updated_at < current_date - interval '30 days';`

---

## Observações importantes
- **Não há** `dash_delta_log` no schema mínimo: o app pode consumir sempre `/summary` (mês/dia) e confiar no cache.
  - Se depois você quiser “delta sync” real, aí volta com 1 tabela extra (`dash_delta_log`) e mantém o mesmo desenho.
- **Mídias** ficam fora do DB (filesystem/S3). DashDB só guarda `photo_key` no payload.
- Esse desenho escala para 1000+ empresas sem “crescer em tabelas”, só em linhas.

