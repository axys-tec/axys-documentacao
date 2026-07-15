# Catálogo — Capability: Listagem / Consulta (insumos e CPUs)

**Status:** Contrato Canônico (v1.0 · 2026-07-14 — nasce da dissolução do ex-`CATALOGO_BUSINESS_RULES` + fusão de `CATALOGO_INSUMOS` + `CATALOGO_SEARCH`)
**Tabelas:** `catalogo.insumos` (+ `insumos_preco`, `insumos_equivalencias`, `insumos_historico`), `catalogo.composicoes` (+ `composicoes_custo`, `composicoes_itens`, `composicoes_historico`), `catalogo.search_document`.
**Princípio de governança:** Contrato governa · Schema suporta · Código implementa · Tela opera.
**Capabilities vizinhas:** import (como o dado nasce) → [imports/](imports/) · publicação de docs → [publicacao.md](publicacao.md) · cadastro de fonte → [fontes.md](fontes.md) · ciclo da edição → [edicoes.md](edicoes.md).

> Esta capability governa **o que o usuário consulta**: a identidade de insumos/CPUs, seus preços/custos por época, a busca e as telas de listagem. O **modelo-núcleo do catálogo** (conceitos, armazenamento de preço, custo, retroação) mora aqui — é o que a consulta lê. A **computação** desse dado (derivação SD/CD, conferência, diff) é da capability [imports/](imports/).

---

## 1. Conceitos fundamentais

| Conceito | Definição canônica |
|---|---|
| **Insumo** | Identidade do que o insumo É (código, descrição, unidade, tipo), sem preço. Mutável — "identidade vigente", upsert por reimport. |
| **Preço** | Valor do **insumo** por UF/edição/modalidade. Insumo tem PREÇO (não custo). |
| **Composição (CPU)** | Conjunto de itens (insumos e/ou subcomposições) com coeficientes, p/ 1 unidade de serviço. Composição tem CUSTO. |
| **Item de composição** | Linha filha: tipo `INSUMO` ou `COMPOSICAO` (subcomposição/auxiliar). |
| **Composição auxiliar** | Composição empregada como item de outra (ex.: argamassa). |
| **Edição** | Recorte temporal/versão da fonte. Preços e custos são densos **por edição**; identidade (insumo/composição) é **vigente** (evolução em `*_historico`). |
| **Situação** | Estado do preço/custo. Enum pequeno/fixo → **`CHECK`-text** (não há mais tabela `catalogo.situacoes` — dropada 2026-07-14). INSUMO: `COM PREÇO`/`SEM PREÇO`; COMPOSICAO: `COM CUSTO`/`SEM CUSTO`/`SUSPENSO`/`EM ESTUDO`. |

---

## 2. Modelo-núcleo do catálogo (o que a consulta lê)

### 2.1 Preço do insumo — armazenamento "pelado + LS" (`insumos_preco` é **SE-only**)
Encargos sociais incidem **só sobre mão de obra**, e o preço "com encargos" publicado **é** `pelado × (1 + LS%)` truncado. Logo **não se armazena SD/CD** como preço de insumo — grava-se só o **pelado (SE)** e derivam-se SD/CD no cálculo (derivação = [imports/estagios.md](imports/estagios.md)).
- `insumos_preco` grava **apenas modalidade `SE`** para todo insumo (MO e não-MO), por UF/edição. SD/CD seguem válidas no cadastro/lookup para visualização, mas **não** como linhas de preço.
- **Não-MO**: sem encargo → SE = SD = CD; 1 linha (SE). **MO**: grava o pelado; SD/CD derivados.
- `pri_valor` recebe o valor publicado **exatamente, inclusive `0`** (zero **nunca** é "sem preço"). Fonte sem preço p/ a UF → `pri_valor = NULL` + `pri_situacao = 'SEM PREÇO'`. **Toda UF da edição tem linha** (ausência de linha = falha de processamento, **nunca** "sem preço").
- Coerência valor × situação é contrato do parser — **sem trigger**.

### 2.2 Custo da composição — `composicoes_custo` é a casa única dos números
- **Custo é montado pela app** a partir dos preços de insumo na UF/modalidade — a fonte é referência/conferência, não verdade de cálculo.
- **SEM CUSTO** ⟺ a composição contém algum insumo SEM PREÇO ou subcomposição SEM CUSTO. A indisponibilidade **propaga pela árvore**.
- Os **números** (`cc_custo_fonte`, `cc_custo_calculado`, diferença, `cc_status_conferencia`, `cc_pct_sp`) vivem **só** em `composicoes_custo` (1 linha por cmp/uf/modalidade). `composicoes_custo_alerta` guarda **só a causa** (tipo + item culpado + observação), sem repetir custo, só p/ casos relevantes.
- **Exibição:** a app mostra `cc_custo_calculado` (processado pela app); `COALESCE(cc_custo_calculado, cc_custo_fonte)` (fonte só fallback). A semântica de `cc_custo_fonte` cru / fontes com BDI (FDE) é da conferência de import — ver [imports/fde.md](imports/fde.md).
- **Fidelidade dos itens:** a receita é gravada **exatamente como a fonte apresenta** (N itens, código/descrição/unidade/coef/ordem). Coeficiente 0 é válido (item presente, quantidade não atribuída) — `CHECK ci_coef >= 0`. Insumo SEM PREÇO com coef 0 **ainda propaga SEM CUSTO** (basta a presença na árvore).

### 2.3 Modelo contínuo — identidade vigente + série densa + histórico esparso
Espelha insumo e composição no mesmo formato (APLICADO 2026-07-14):
- **`insumos` / `composicoes` = identidade vigente** (1 linha por `(fonte, código)`; composição **sem `cmp_edi_id`**, UNIQUE `(cmp_fte_id, cmp_codigo)`). Descrição/unidade/situação/flags/`external_path` = estado vigente.
- **`insumos_preco` / `composicoes_custo` = série densa por edição** (`pri_edi_id` / `cc_edi_id`; UNIQUE inclui a edição). Retroação de preço/custo = **lê, não recalcula**.
- **`composicoes_itens` = receita VIGENTE** (`ci_cmp_id` → identidade; **sem** `ci_*_fonte_original` — o filho é resolvido pela identidade). `insumos`/composição não duplicam por edição (a busca não retorna a mesma CPU N vezes por época).
- **`*_historico` = snapshot-na-mudança** (esparso): grava evento **só quando muda** descrição/unidade/receita; `ch_dados_novos`/snapshot = "como era na edição E" em 1 lookup. **Custo/preço nunca** entram no histórico (a série vive nas tabelas densas).
- **Nomenclatura preço × custo é distinção de DOMÍNIO** (insumo tem preço; composição tem custo) — **não** renomear.

### 2.4 Retroação — leitura ponto-no-tempo
- **Insumo@E = TRINCA ATÔMICA `(preço@E, unidade@E, descrição@E)`** — nunca o preço sozinho nem pareado com a unidade vigente. `obter_insumo_em_edicao(ins, E)`: preço de `insumos_preco@E` (lookup direto); unidade/descrição reconstruídas de `insumos_historico` (`E ENTRE [inicio, fim)`), fallback ao vigente. Retroação O(1).
  - *Por que atômica:* preço histórico sem a unidade da época **engana** (vergalhão `barra→kg`: lido com a unidade vigente diria "barateou" quando encareceu).
- **Composição@E:** custo@E = lookup direto em `composicoes_custo@E`; receita@E = snapshot do `*_historico` que cobre E (ou a vigente); analítico@E = explosão recursiva as-of-E (cada filho pela trinca / receita@E).
- **Conversão de unidade NÃO é automática — é app-dependente.** Ao detectar divergência de unidade (unidade@E ≠ vigente), a app **não converte**: notifica o usuário a definir o **fator** e registra como **observação** no artefato. Mudança só de descrição = aviso informativo (não bloqueia). O gatilho de conversão é **unidade**.

---

## 3. Tela Insumos

**Tabelas:** `catalogo.insumos` (+ `insumos_preco`, `insumos_equivalencias`, `insumos_historico`). **Acesso:** módulo interno (`is_staff=True`). **UX:** `backend/frontend/templates/catalogo/catalogo_work_pages.md`.

### 3.1 Modelo (identidade)
| Campo | Regra |
|---|---|
| `ins_fte_id` | FK p/ `fontes`. Imutável após criação. |
| `ins_codigo` | Único por fonte (`uq_insumos_fte_codigo`). Gerado automaticamente no cadastro manual. Não vazio. |
| `ins_descricao` | Texto livre (maiúsculas no front). Não vazio. |
| `ins_unidade` | Unidade **verbatim** da fonte (upsert no import — vocabulário controlado `catalogo.unidades`; **não normalizar** dado de fonte). Não vazio. |
| `ins_ti_id` | FK p/ `insumos_tipo` (MAT, MO, EQUIP_AQ, EQUIP_LOC, ENC_COMP, ESP, SERV, `NC`). Classificação/precedência = [imports/estagios.md](imports/estagios.md). |
| `ins_ti_origem` | `FONTE` \| `REGRA` \| `MANUAL`. Cadastro manual = `MANUAL`. |
| `ins_ativo` | Vigência (§3.7). |
| `ins_external_path` | JSONB — ficha do insumo no R2 (vigência por versão; ver [publicacao.md](publicacao.md)). |

### 3.2 Identidade & gate de manipulação
- Cadastro/edição de identidade exige **`internal_admin` E `fte_permite_manipular_dados = true`** (gate em [fontes.md](fontes.md)). Insumo de fonte de terceiro (importada) abre **somente leitura** — correção = **reprocesso da edição** (recall → `EM_REVISAO`, ver [edicoes.md](edicoes.md)).
- Código gerado automaticamente; origem do tipo em cadastro manual = `MANUAL`. Unidade nova via "Outra (digitar)…" → upsert em `unidades` (auditado).

### 3.3 Listagem, filtros e busca
Listagem **server-side** (busca + ordenação + paginação, 50/página).
- **Funil:** `termo` (descrição) · `fonte-base` · **Tipo busca** (Exata × Elástica) · **UF** (define a coluna Preço).
- **Régua:** `tipo` · `unidade` · `modalidade` (SE/SD/CD) · **Apenas inativos**.
- **Coluna Preço** = série da (UF, modalidade). **SE** é o gravado (pelado); **SD/CD** são **derivados** da LS da edição (§2.1), nunca linha própria.

### 3.4 Equivalências entre fontes (curadoria NOSSA)
- `catalogo.insumos_equivalencias` (`ie_*`). Tipos: `EXATA` \| `APROXIMADA` \| `SUBSTITUTA` \| `COMERCIAL` \| `SEMANTICA`. `ie_score`/`ie_metodo` p/ origem automática (fuzzy); curadoria manual entra com tipo.
- **Editável por `internal_admin` em QUALQUER fonte** — inclusive terceiro (é curadoria nossa, **sem** o gate de manipulação).
- Modal de vínculo: busca elástica (opcionalmente isolada na fonte), multi-seleção; o código do equivalente é link → `/insumos/{id}/editar`.

### 3.5 Cadastrar "clonando"
Insumo selecionado → **Cadastrar** abre `/insumos/novo` pré-preenchido com `descrição/unidade/tipo`, **sem a fonte** (usuário escolhe a fonte própria). Acelera itens análogos em fonte AXYS.

### 3.6 Série Histórica (modal)
Modal grande por linha selecionada. Subtítulo `fonte | código | descrição | unidade`. Controles: Índices · faixa de data · **UF** · **Modalidade**. Gráfico (Chart.js, eixo Y em R$): preço real + índice sobreposto em R$ (`base × índice/índice_âncora`, não base-100). Tabela `Data | Valor | LS% | variação dos índices`. Histórico de Registros = eventos de `insumos_historico` (exclui CRIACAO). Fontes: `insumos_preco` + `edicoes_leis_sociais` + `indices`/`indices_historico`. "Gerar Análise" = placeholder (IA).

### 3.7 Preço SE por UF / edição (registro manual)
- **27 abas de UF**; campo único = **preço SE (R$)** da UF ativa. Grava em `insumos_preco`: `pri_modalidade='SE'`, `pri_origem='C'`, `pri_situacao='COM PREÇO'`, por `(pri_ins_id, pri_edi_id, pri_uf, 'SE')` (upsert na UNIQUE).
- Listbox de edição (default = mais recente); trocar re-busca os preços daquela edição. Salvar afeta **só a UF editada** (nunca cria linha zerada). Gate = `fte_permite_manipular_dados` (terceiro = read-only). Auditado (só se mudou).
- SD/CD seguem **derivados** das LS. Preço por cotação (`CT` + `insumos_cotacoes`) = §3.8.

### 3.8 Preço por COTAÇÃO de mercado (`pri_origem='CT'`)
Para insumos **próprios** (AXYS) ou **sem preço de fonte**, o preço vem de cotação de mercado.
- Lastro em `catalogo.insumos_cotacoes` (`ic_*`, SE-only): `ic_preco_mediano`, `ic_certidao_path`, `ic_cotacoes` (array de fornecedores). Fluxo: junta cotações → **mediana** → grava em `insumos_preco` (`pri_origem='CT'`, SE, na UF). A verdade do preço continua em `insumos_preco`; `insumos_cotacoes` é o detalhe/auditoria.
- Docs (propostas/certidão) = justificativa do usuário → **R2 privado** (não o registro público de docs da fonte).
- **Estado:** tabela criada + `'CT'` no CHECK. Wiring (mediana→preço, UI, upload) entra com a tela de insumos próprios (AXYS) — gate `fte_permite_manipular_dados`.

### 3.9 Vigência, permissões, auditoria
- **Vigência** (`ins_ativo`): inativar/reativar otimista no front, auditado, evento em `insumos_historico`. Inativo não aparece na busca elástica (índice só ativo) — use "Apenas inativos".
- **Permissões:** GET = `internal_user`; cadastrar/editar identidade + preço = `internal_admin` **+** gate; equivalências = `internal_admin` (sem gate). **Paridade:** o que não se pode em `/insumos`, também não em `/edicoes`.
- **Auditoria:** `audit.logs` (`insumos`/`insumos_preco`/`insumos_equivalencias`/`unidades`), snapshot antes/depois, na mesma transação. `log_registro_id` TEXT — preço = `f"{ins_id}/{edi_id}/{uf}"`; unidade = o código.

---

## 4. Busca textual inteligente (SearchService)

> **Status:** Fase A + Passo 5 **implementados** (índice + indexer + carga + busca elástica plugada na listagem de insumos). Decisão Renan 2026-06-11.

### 4.1 Doutrina (inegociável)
- **PostgreSQL é a FONTE DA VERDADE.** O motor de busca nunca substitui o dado oficial.
- A busca devolve **CANDIDATOS** (`entity_type`, `entity_id`, `score`, `match_reason`) — a app **reidrata** o oficial nas tabelas-fonte a partir do `(entity_type, entity_id)`.
- **Motor plugável** por `SEARCH_BACKEND` (`postgres` hoje · `elastic` amanhã) — trocar o motor = trocar o adapter; contrato/telas não mudam.

### 4.2 Contrato estável (`backend/core/search/`)
```
base.py             Candidate · SearchResult · SearchAdapter (ABC)
service.py          SearchService.search_catalog(query, filters, page, per_page) · get_search_service()
postgres_adapter.py PostgresSearchAdapter (hoje)
elastic_adapter.py  ElasticSearchAdapter (Fase C — stub; mesmo contrato)
indexer.py          SearchIndexer.rebuild_all() / rebuild(entity_type, id)
```
- **Telas chamam `SearchService`, nunca SQL de busca direto.** `query` vazia = browse (match_all por descrição); preenchida = ranqueado. `filters` = facetas (`entity_type`, `fte_id`, `tipo`, `unidade`, `is_active`).

### 4.3 Índice `catalogo.search_document` (prefixo `sd_`, 1×1 por entidade ATIVA)
- **Só TEXTO PESQUISÁVEL + FACETAS** — nunca duplica preço, receita, coeficientes ou regra (esses vivem nas tabelas-fonte). UF/preço não entram (dimensão de exibição, fica na reidratação).
- Campos: `sd_entity_type` (INS|CPU), `sd_entity_id`, `sd_codigo`, `sd_descricao_*`, `sd_texto_busca`, `sd_aliases`, `sd_tokens`, `sd_search_vector` (tsvector pt). Facetas: `sd_fte_id`, `sd_tipo`, `sd_unidade`, `sd_is_active`. `sd_source_hash` (md5) → detecta mudança/skip. `UNIQUE (sd_entity_type, sd_entity_id)`; GIN(search_vector)+trigram, btree facetas/código.

### 4.4 Indexação (`SearchIndexer`)
- `rebuild_all()` reindexa insumos+composições **ativos** (set-based `INSERT…SELECT…ON CONFLICT`; ~22k docs em ~4s). `rebuild(type, id)` após CRUD (tira do índice se inativou). Idempotente por `sd_source_hash`. **Import** chama `rebuild_all()`/batch no FIM — **nunca** por linha.

### 4.5 Busca (Passo 5 — `PostgresSearchAdapter`)
- **Multi-palavra = OR por palavra:** cada palavra entra via full-text (stem) **e** fuzzy `word_similarity` (typo); o score **soma** a contribuição de cada palavra (cobertura). Ranking: código exato `1000` > descrição exata `500` > Σ`word_similarity ×10` > `ts_rank ×100`; corte fuzzy **0.5**. **Exata** = `catalogo.unaccent ILIKE %termo%` (contém a palavra, sem fuzzy). "Apenas inativos" → SQL tradicional (índice só ativos). Hook `_reindex('INS', id)` no CRUD.
- **Extensões `unaccent`+`pg_trgm` no schema `catalogo`** (uso qualificado: `catalogo.unaccent`, `OPERATOR(catalogo.%)`, `catalogo.similarity`).
- **Fase C:** `ElasticSearchAdapter` + indexer-backend ES quando a escala pedir — só o adapter, zero refatoração de tela.

---

## 5. Fronteira Banco × App

| Banco garante | App/importador garante |
|---|---|
| FK válida; domínio de situação por **`CHECK`-text** | Coerência valor × situação |
| `ins_ti_id NOT NULL` | Aplicação da regra de fonte e do fuzzy (classificação) |
| Unicidade e integridade relacional | Precedência FONTE > MANUAL > REGRA |
| Domínio de `ins_ti_origem`, modalidade, origem | 27 UFs preenchidas por insumo/edição |
| — | Custo e situação **efetiva** das composições |

**Sem triggers** — coerência é responsabilidade do parser/importador.

**Unidades de grandeza — vocabulário controlado (`catalogo.unidades`).** Tabela única (unidade é universal), **PK natural = o código** (`un_codigo` TEXT: `'M3'`,`'M3XKM'`). Enum pequeno fixo → `CHECK` (situação); vocabulário grande/extensível → **tabela** (unidade). Import faz **UPSERT verbatim** (não normaliza dado de fonte); criação manual só seleciona da lista (+ "Outra" restrita a admin). `un_categoria` prepara o fator de conversão da retroanálise (§2.4). *(FK `ins_unidade`/`cmp_unidade` → `unidades` = pendência, sem gatilho.)*

---

## 6. Pontos abertos
- **Modelo contínuo de composição na tela de Composições:** a tela espelha Insumos (identidade vigente + custo denso + histórico) — a construir.
- **Preço por cotação (`CT`)** + upload de propostas/certidão (R2 privado) — entra com as telas de fonte própria (AXYS).
- **"Gerar Análise"** (IA sobre a série) — placeholder.
