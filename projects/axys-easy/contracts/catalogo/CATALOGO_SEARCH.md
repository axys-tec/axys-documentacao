# CATÁLOGO — Busca textual inteligente (SearchService)

> **Status:** Fase A + **Passo 5 implementados** (índice + indexer + carga + busca elástica plugada na listagem de insumos).
> Decisão Renan 2026-06-11. Governança: **Contrato governa · Schema suporta · Código implementa · Tela opera.**

## 0. Objetivo
Preparar a app (FastAPI + PostgreSQL) para **busca inteligente do catálogo** — hoje 100% PostgreSQL,
com a **arquitetura pronta** para escalar/migrar para Elasticsearch/OpenSearch **sem refatorar telas**.

## 1. Doutrina (inegociável)
- **PostgreSQL é a FONTE DA VERDADE.** O motor de busca **nunca** substitui o dado oficial.
- A busca devolve **CANDIDATOS** (`entity_type`, `entity_id`, `score`, `match_reason`) — **não** o objeto oficial.
- A app **reidrata** o oficial nas tabelas-fonte a partir do `(entity_type, entity_id)`. (É o que a listagem de insumos já faz: candidatos → `get_insumos(ids)` reidrata preço/tipo/etc.)
- **Motor plugável** por `SEARCH_BACKEND` (`postgres` hoje · `elastic` amanhã). Trocar o motor = trocar o **adapter**; o contrato e as telas não mudam.

## 2. Contrato estável (`backend/core/search/`)
```
base.py            Candidate (entity_type, entity_id, score, match_reason) · SearchResult · SearchAdapter (ABC)
service.py         SearchService.search_catalog(query, filters, page, per_page) → SearchResult · get_search_service() (factory por SEARCH_BACKEND)
postgres_adapter.py PostgresSearchAdapter (hoje) — busca real = PASSO 5
elastic_adapter.py  ElasticSearchAdapter (Fase C — stub; mesmo contrato)
indexer.py         SearchIndexer.rebuild_all() / rebuild(entity_type, id)
```
- **Telas chamam `SearchService`, nunca SQL de busca direto.** `query` vazia = browse (match_all ordenado por descrição); `query` preenchida = ranqueado.
- `filters` = **facetas**: `entity_type`, `fte_id`, `tipo`, `unidade`, `is_active`.

## 3. Índice — `catalogo.search_document` (prefixo `sd_`, 1×1 por entidade ATIVA)
- **Só TEXTO PESQUISÁVEL + FACETAS.** **NUNCA** duplica preço, composição analítica, coeficientes ou regra de negócio (esses vivem nas tabelas-fonte).
- Campos: `sd_entity_type` (INS|CPU), `sd_entity_id` (ins_id|cmp_id vigente), `sd_codigo`, `sd_descricao_original`, `sd_descricao_normalizada` (`upper(unaccent)` p/ trigram), `sd_texto_busca` (haystack: código+descrição+aliases), `sd_aliases` (sinônimos/curadoria — MVP vazio), `sd_tokens` (palavras normalizadas), `sd_search_vector` (`tsvector` pt p/ full-text).
- **Facetas** (denormalização barata, NÃO regra): `sd_fte_id`, `sd_tipo` (ti_codigo p/ INS; NULL p/ CPU), `sd_unidade`, `sd_is_active`.
- `sd_source_hash` (md5 das fontes) → detecta mudança (skip reindex) e é a **base do delta worker** futuro. `sd_indexed_at`.
- `UNIQUE (sd_entity_type, sd_entity_id)`. Índices: GIN(`sd_search_vector`), GIN trigram em `sd_descricao_normalizada`/`sd_texto_busca`, btree facetas, btree código.
- **UF/preço NÃO entram** — é dimensão de exibição (fica na reidratação).

## 4. Indexação — `SearchIndexer`
- `rebuild_all()` → reindexa todos os insumos (ins_ativo) + composições (cmp_ativa) **ativos**. SQL **set-based** (`INSERT…SELECT…ON CONFLICT`) — 22.301 docs em ~4s.
- `rebuild(entity_type, id)` → reindexa uma entidade após CRUD; se ficou inativa/removida, **tira do índice**.
- `sd_source_hash` no `ON CONFLICT … WHERE hash IS DISTINCT` → update só quando o conteúdo muda (idempotente).
- **Atualização (MVP):** chamar `rebuild()` após cadastro/edição/inativação de insumo/composição (= **passo 5**, junto da busca na tela). **Import** (lote) chama `rebuild_all()`/batch no fim — **nunca** por linha.
- Preparado p/ **worker delta** futuro (via `updated_at`/`source_hash`/outbox).

## 5. Configuração / extensões
- `SEARCH_BACKEND=postgres` (default). No futuro `=elastic` sem mexer em controllers/telas.
- **Extensões `unaccent` + `pg_trgm` instaladas NO schema `catalogo`** (este banco dev — PG 18 local — **não tem `public`**). Por isso os usos são **qualificados**: `catalogo.unaccent(...)`, `catalogo.gin_trgm_ops`, `catalogo.similarity(...)`, e o operador trigram `OPERATOR(catalogo.%)`. (Se um ambiente tiver `public`, manter em `catalogo` p/ consistência.)

## 6. Decisões travadas (Renan 2026-06-11)
- **(a)** Facetas **no índice** (não filtrar pós-SQL) → paridade com Elastic (query+filtros+paginação+ranking no motor).
- **(b)** Naming **`sd_` + PT** (alinhado à convenção do schema catalogo).
- **(c)** Escopo: **INS + CPU** já (CPU usa o dado de composição que já existe; a tela de composições vem depois).

## 7. Faseamento
- **Fase A — FEITO:** contrato + `search_document` + `SearchIndexer` + extensões + **carga inicial** (INS+CPU). Schema.sql atualizado.
- **PASSO 5 — FEITO:** `PostgresSearchAdapter.search`. **Multi-palavra = OR por palavra** (não AND): cada palavra entra isolada via full-text (stem) **e** fuzzy `word_similarity` (typo); o **score SOMA a contribuição de cada palavra** → +palavras casando = rankeia mais alto (cobertura). Ranking: código exato `1000` > descrição exata `500` > Σ`word_similarity ×10` (cobertura) > `ts_rank` full-text `×100`; corte fuzzy **0.5** (pega "tijlo"→tijolo). Plugado na **listagem de insumos**: `busca='elastica'` + termo + só ATIVOS → `SearchService` → IDs ranqueados → `get_insumos(ids=…)` reidrata preço/UF/modalidade preservando a ordem. **Exata** = `unaccent ILIKE %termo%` (CONTÉM a palavra, grafia exata, sem fuzzy). **"apenas inativos"** → SQL tradicional (índice só tem ativos). Hook `_reindex('INS', id)` (best-effort) no criar/editar/inativar/reativar.
  - **Amplo por design** (recall alto): "concretagem forma estrutura" traz ~1000 (qualquer palavra casando), **best-first**. `_TRGM_THRESHOLD` e os pesos em `postgres_adapter.py` são os botões de ajuste.
- **Fase B:** quando a tela de composições existir, ela consome o mesmo `SearchService` (índice já tem CPU).
- **Fase C:** `ElasticSearchAdapter` + indexer-backend ES quando a escala pedir — só o adapter/indexer, zero refatoração de tela.

### Esboço da query do passo 5 (PostgresSearchAdapter)
```
q := upper(catalogo.unaccent(query))
WHERE facetas (sd_entity_type, sd_fte_id, sd_tipo, sd_unidade, sd_is_active)
score = maior peso aplicável:
  código exato (sd_codigo = query)                              → reason 'codigo'
  full-text  ts_rank(sd_search_vector, plainto_tsquery('portuguese', catalogo.unaccent(query))) → 'descricao'
  trigram    sd_descricao_normalizada OPERATOR(catalogo.%) q / catalogo.similarity(...)          → 'similaridade'
  alias      q = ANY(sd_aliases)                                → 'alias'
query vazia → match_all ORDER BY sd_descricao_original (browse). ORDER BY score DESC; LIMIT/OFFSET; COUNT.
```
