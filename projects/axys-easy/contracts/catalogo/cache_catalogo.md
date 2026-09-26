# Cache do catálogo + ponto único de busca — CONTRATO

> **STATUS: EM PRODUÇÃO / VIGENTE.** Contrato que governa o cache do catálogo e a costura de cache do
> serviço de busca. Origem: rascunho de design 2026-08-23 (root `CACHE_CATALOGO_DESIGN.md`),
> **reconciliado com o código real e promovido a contrato** em 2026-09-26. O que o rascunho projetava
> como chaves/TTL mudou na implementação — este documento vale sobre o rascunho.
> Governa: [`backend/core/cache.py`](../../../../../backend/core/cache.py) (fronteira única) e a costura de
> cache em [`backend/core/search/service.py`](../../../../../backend/core/search/service.py) `SearchService.search_catalog`.
> Irmão de [listagem.md](listagem.md) · [cognatos_glossario.md](cognatos_glossario.md) ·
> [ranqueamento_perfil_CONGELADO.md](ranqueamento_perfil_CONGELADO.md).
> Doutrina: contrato governa · schema suporta · **código implementa e referencia este arquivo no topo**
> (ADR governança de contratos; ADR-022 minimalista/sustentável).

## 1. Fronteira única
Todo o cache mora em **um** módulo: `backend/core/cache.py`. Nada de acesso a Redis espalhado.
- Reusa o **Redis do Celery** (`REDIS_URL`, mesmo `db 0` do broker/result-backend) — **não** é serviço
  novo (ADR-022: mais infra/custo por zero benefício nesta escala). Redis gerenciado (Render) em geral
  não permite `SELECT` de outro db → o isolamento é por **prefixo de chave `easy:`**, não por db index.
  As chaves do Celery são namespaced (`celery-*`, `_kombu*`) → sem colisão.
- **Degrada gracioso:** Redis fora / erro → tudo vira miss/no-op (cai no banco). O cache **nunca**
  quebra a app. **Circuit-breaker** (`_BREAKER_S = 30s`): após uma falha, ignora o cache por 30s para
  não pagar timeout a cada chamada.
- Liga/desliga por `EASY_CACHE` (default ligado).

## 2. Dois regimes de validade (a distinção central)
| Regime | O que guarda | Validade | Invalidação autoritativa |
|---|---|---|---|
| **Catálogo** | dado imutável **por edição** (estrutura de CPU, preço pelado SE, LS da fonte, CPU resolvida) | **PERMANENTE** (sem TTL) | **purge-no-publicar/import/reindex** |
| **Busca** (`search:*`) | candidatos BASE de uma query | **TTL 48h** (`EASY_SEARCH_CACHE_TTL`) | purge no publish + TTL de rede |

Por quê catálogo é **permanente** (e não "TTL 24h", como o rascunho projetava): o dado é
**content-addressed pela edição** → o valor de `edição X` é *sempre* correto p/ `edição X`, nunca fica
stale; publicar edição nova gera chaves novas e o hook faz o purge das velhas. TTL viraria só despejo à
toa. `get_json/set_json` gravam sem TTL (`_TTL = None`); `EASY_CACHE_TTL` só entra se setado à mão.

Por quê busca tem **TTL**: o espaço de query é **infinito** → sem TTL a memória cresce sem teto. O TTL
(48h) limita memória; a correção autoritativa (mudou o que a busca retorna) continua sendo o purge.

## 3. Ponto único de busca — `SearchService.search_catalog`
**Todos os callers de busca cruzam aqui** (pickers web, API mobile, rotas de ativo). O cache mora
**dentro** de `search_catalog` — não há wire externo paralelo.
- Cacheia **candidatos BASE** ranqueados pela **query** (iguais p/ todos → compartilháveis): só
  `{entity_type, entity_id, score, match_reason}`. **Não** guarda o objeto oficial — o caller reidrata
  no PostgreSQL.
- **Ranking per-user e `excl` aplicam PÓS-read no caller, NUNCA entram na gaveta** (senão o cache
  deixaria de ser compartilhável). O plug pós-read já existe em `buscar_filhos`/`buscar_insumos`
  (candidatos BASE → boost/excl → reidrata). Ver [ranqueamento_perfil_CONGELADO.md](ranqueamento_perfil_CONGELADO.md).
- Roda sobre o **adapter com fallback fail-safe** (`SEARCH_BACKEND` postgres|elastic; primário → Postgres
  em erro; **vazio ≠ erro**; circuit-breaker + alerta ZAPI). Ver [listagem.md](listagem.md) e
  [cognatos_glossario.md](cognatos_glossario.md).

## 4. Namespaces e chaves REAIS (como implementadas)
### 4.1 Busca (`search:*`, com TTL)
```
search:cat:{hash}                # GLOBAL — catálogo público, compartilhável entre todos
search:tct:{tenant}:{hash}       # PRIVADO por tenant (tenant_catalogo), NUNCA cross-tenant
```
`hash = f(query, filters, page, per_page)`. O namespace decide **isolamento e purge**: `tenant`
presente (via `filters.tenant`) → `search:tct:{tenant}:…` (privada); ausente → `search:cat:…` (global).
Nas rotas públicas/mobile é onde mais paga: vira **escudo do banco contra raspagem/DDoS**
(mesmo Redis compartilhado). Ver [[project_easy_mobile]].

### 4.2 Catálogo (permanente) — prefixos `_CATALOGO_PREFIXOS`
`("search", "cpus", "ins", "cpu", "pel", "items", "els", "fte", "warm")` — invalidados juntos quando a
edição muda. Os que carregam corpo determinístico por edição:
```
cpu:{edi}:{uf}:{mod}:{cmp_id}    # composição RESOLVIDA (get_cpu_precificada) — resolução da FONTE,
                                 # sem input do ativo → determinística por edição, imutável, permanente
```
- `pel` = preço pelado SE por edição/UF · `items` = estruturas de composição · `els` = LS da fonte ·
  `fte` = edição vigente resolvida (curto) · `cpus`/`ins` = reidratação de consulta ·
  `warm` = **marcadores de pré-aquecimento** (Gaveta 1).
- **`warm` TEM de ser purgado junto** com o resto: senão o marcador sobrevive e o warm pula o re-warm.

## 5. Purges (hooks de invalidação)
| Função | Alvo | Quando chamar |
|---|---|---|
| `purge_catalogo()` | varre TODOS os `_CATALOGO_PREFIXOS` (`*:*`) | reindex / import / publicar (a edição mudou) |
| `purge_search_catalogo()` | `search:cat:*` | publish (mudou o que a busca global retorna) |
| `purge_search_tenant(tenant)` | `search:tct:{tenant}:*` | CRUD do `tenant_catalogo` daquele tenant |
| `purge(pattern)` | SCAN por padrão (**nunca `KEYS`**) | primitiva dos acima |
| `purge_keys(iter)` | chaves explícitas em pipeline | `items:{cmp}` (não escopável por SCAN → lista de cmp_ids da fonte) |

Full purge é seguro e simples; o cache re-aquece no uso.

## 6. Warm / auto-cura (Gaveta 1)
Pré-aquecimento em bulk das edições vigentes, idempotente por marcadores `warm:*`. **Auto-cura**: se o
Redis for limpo, o beat re-aquece sozinho.
- Beat `verificar-warm-cache` (300s) → um GET na sentinela; frio → re-aquece as vigentes. Cobre também o
  começo pós-boot (dentro de 5 min). Backup no boot do worker.
- Warm-on-create (tenant): ao criar/derivar composição própria, dispara warm do tenant.
- Ver `backend/core/celery_app.py` (beat + `worker_ready`) e `backend/modules/catalogo/jobs_async.py`.

## 7. Segurança do cache (o medo legítimo de "perder valor")
- **NUNCA cachear valor de orçamento.** Só catálogo **imutável por edição**. O `ati_custo_unit` gravado
  (a verdade da bancada — [[project_bancada_trunc_doutrina]]) **jamais** entra.
- **Modalidade na chave** (`cpu:{edi}:{uf}:{mod}:{cmp}`): o catálogo é **SE** (pelado); SD/CD nascem da
  LS na resolução. Cachear o RESOLVIDO com `mod` na chave (Opção A) é o vigente — o valor cacheado é
  exatamente o que a bancada consome, sem re-cálculo ao vivo que possa divergir. (Opção B — cachear SE
  e aplicar LS ao vivo — é refinamento futuro, não implementado.)
- **Fora do cache, sempre ao vivo:** conversões **por-ativo** (`converter_ls` com a LS do ativo,
  `converter_mdo`, mensalista) — dependem do ativo, não da edição → não cacheáveis por edição. O cache
  serve o **caso base** (fonte própria), que é o comum.
- Content-addressed por edição + degrada gracioso + purge-no-publicar = impossível servir dado de outra
  edição e impossível o cache travar a app.

## 8. Sizing (medido 2026-08-23 — referência)
- pelado SE por edição/UF ≈ **0,54 MB** (4.958 chaves); estruturas SINAPI (todas edições) ≈ **10,8 MB**.
- Homolog realista ≈ **40–80 MB**. Free 25 MB é insuficiente (estruturas já ~11 MB + broker no mesmo
  Redis → despejo pode matar fila de job). Piso recomendado: **Starter 256 MB**; Standard 1 GB só p/
  muitas edições×UFs.

## 9. Reconciliação com o rascunho (o que mudou de ago/23 → prod)
- Chaves de consulta `easy:ins/cmp` **não** foram para produção como projetado; o cache de consulta
  convergiu no **ponto único `search_catalog`** com os namespaces `search:cat` / `search:tct`.
- **TTL 24h** (rascunho) → **catálogo permanente** (invalidação real = purge) + **busca TTL 48h**.
- Nasceu o **isolamento por tenant** (`search:tct`) e o purge por-tenant — não existiam no rascunho.
- Nasceu a **auto-cura do warm** (beat + sentinela) — o rascunho só previa warm-on-publish/lazy.

## 10. Questões abertas / futuro
- Refinamento SE-base (Opção B, §7) — 1 entrada servindo SD/CD/LS-do-ativo. Adiar.
- Pré-aquecer queries POPULARES no cache de busca (seguro; **não** compor multi-termo a partir de
  single). Ver [project_busca_ranking].
- Busca da bancada e filtro por fonte-base (escopo, não latência) — investigar à parte se reaparecer.

## 11. Referências
- Código: `backend/core/cache.py` · `backend/core/search/service.py` · `backend/modules/catalogo/composicoes_service.py` (`get_cpu_precificada`)
- Busca: [listagem.md](listagem.md) · [cognatos_glossario.md](cognatos_glossario.md) · [ranqueamento_perfil_CONGELADO.md](ranqueamento_perfil_CONGELADO.md)
- Memória: `project_cache_catalogo` · `project_busca_elastic_tuning` · `project_busca_ranking`
