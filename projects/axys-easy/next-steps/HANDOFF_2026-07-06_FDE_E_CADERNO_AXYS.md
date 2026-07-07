# Handoff — 2026-07-06 · FDE scraper fechado + bug do Caderno AXYS

> Chat anterior chegou no limite de contexto. Este doc é o ponto de retomada.
> Foco do próximo chat: **destravar o Caderno AXYS** (não carrega em nenhuma edição).

## 1. O que fechou neste chat (FDE / edi 56 = FDE 04-26)

### 1.1 Scraper de preços — caractere especial com maestria (o grande fix)
Problema real (provado via curl ao vivo no portal): o insumo garble `8.01.93`
(`CAMINHAO MUNCK 6 TONELADAS … 150CM<DIAM<250CM`) **achava** a linha na busca mas o
`get_price` levava **HTTP 500** — o `<` de `150CM<DIAM<250CM` dispara o
*request-validation do ASP.NET* ("A potentially dangerous Request.Form value was detected").
Resultado: preço voltava vazio → o insumo caía em SEM_CUSTO.

**Correção (2 partes que compõem):**
1. `portal_safe()` em [fde_insumos_to_csv.py](../../../../backend/core/import_cpu/fde_novo/fde_insumos_to_csv.py)
   — `<` e `>` viram `%` (curinga do LIKE) na **origem**, aplicado a TODO texto em
   `build_search_queries`/`build_percent_query`. Nenhuma query dispara o 500, e o `%`
   ainda casa a linha (`150CM<DIAM<250CM` → `150CM%DIAM%250CM`). Lição do Codex codificada:
   **caractere especial não some, vira curinga.**
2. `_consultar` em [fde_mod_novo.py](../../../../backend/core/import_cpu/fde_mod_novo.py)
   — passa a **query que casou** (já sanitizada) pro `get_price`, não `ins.descricao` crua.
   Sem isso o `get_price` re-injetaria o `<` e levaria 500 de novo.

**PARTIDO MANTIDO (decisão do Renan):** a ordem de queries continua
`(1) texto completo · (2) %palavra em tudo · (3..N) encurtada como fallback` (pelo fim E pelo
começo). A `%tudo` é boa, mas **a encurtada é essencial** — houve caso em que só a encurtada
pegava. Não remover o fallback de encurtamento.

Prova ao vivo: `8.01.93 = 222.15` capturado pelo scraper (query `%tudo` sanitizada). edi 56
está `IGUAL 3375 / SEM_CUSTO 0`.

### 1.2 Limpeza de lixo (originais stale da edi 56)
Removidos 4 docs `original` de runs antigos (sem vínculo a CPU):
`relatorio_…`, `honorarios_TABELA DE HONORÁRIOS` (dup antigo), `html_catalogos_…`,
`html_componentes_…`. Ficaram os **5 limpos**: sintética, analítica, `bdi_BDI`, `ls_LS`,
`honorarios_2026_04_HONOR`.
- ⚠️ Os **blobs no R2** desses 4 ficaram **órfãos** (inofensivos, não linkados). Limpar depois.

### 1.3 Trava delete-then-insert dos originais
[import_service.py](../../../../backend/modules/catalogo/import_service.py) — no bloco
`documentos` do `importar_fde_novo`, agora faz
`DELETE FROM catalogo.documentos WHERE doc_edi_id=%s AND doc_tipo='original'` **antes** de
reinserir o upload atual. Não afeta fichas (têm ON CONFLICT próprio). Contagem `n_orig`
dinâmica (não mais "6 originais" hardcoded).

## 2. BUG ABERTO — Caderno AXYS não carrega (SINAPI, CDHU e FDE)

Sintoma (Renan): abrir o Caderno Técnico AXYS **não carrega em nenhuma das 3 edições**,
mesmo sem o pedido de IA (deveria mostrar a estrutura + "Descritivo em revisão").

### O que JÁ foi descartado (validado estaticamente neste chat):
- ✅ **Data layer OK**: `montar_axys_desc(cur, 17349)` via `easy_conn()` (cursor de TUPLA)
  retorna certo — `codigo 01.01.001, status em_revisao, 1 item, 1 doc`.
- ✅ **Wiring OK**: `btn-ficha` em [easy_composicoes.js:163-166](../../../../backend/frontend/static/js/easy_composicoes.js#L163)
  faz `window.open(window.AE_AXYS_DESC_BASE + "/" + cmpId)`; a base é setada por
  `easy_axys_desc_internal.js` (carregado em composicoes.html:474).
- ✅ **Blocos do template OK**: `axys_desc.html` usa `{% block main_content %}`/`page_css`,
  e `base_app.html` os define (linha 42/33). base_app é usado pelo `doc_view.html` que FUNCIONA.

### ⚠️ FOOTGUN LATENTE achado (pode ser a causa, confirmar):
`montar_axys_desc` desempacota `row` como **tupla** (`codigo, descricao, … = row`). Se for
chamado com um **RealDictCursor** (é o factory do POOL `get_conn`!), `row` é dict → o unpack
pega as CHAVES → `desc = "cmp_descritivo"` → `json.loads("cmp_descritivo")` **estoura**.
Hoje a rota usa `easy_conn()` (tupla) e passa — MAS qualquer caminho que use `get_conn()`
quebra. **Blindar** `montar_axys_desc` p/ aceitar os dois (ou forçar cursor de tupla).

### Próximo passo (precisa do APP RODANDO — não dá p/ reproduzir estático):
1. Subir o Easy em dev, logar como **internal** (`is_staff`).
2. Na tela de Composições de uma edição, selecionar um CPU → botão "Ver ficha".
3. Capturar o que acontece em `GET /axys-desc/{cmp_id}`:
   - **404/blank** → provável: `easy_axys_desc_internal.js` não carregou (cache `?v=` ou a
     página não o inclui) → `AE_AXYS_DESC_BASE` undefined → cai no fluxo legado. Conferir se
     a tela onde o Renan clicou realmente carrega esse JS.
   - **500** → capturar o traceback (render do base_app faltando contexto, ou o footgun do
     cursor acima se algum caminho usar get_conn).
   - **carrega mas "em branco"** → checar `main_content` no runtime real.
4. Rota: [routes.py:1233 `ver_axys_desc`](../../../../backend/modules/catalogo/routes.py#L1233)
   → `_axys_desc_data` (1217) → `montar_axys_desc`.

## 3. Pendências (backlog)
- [ ] **Reiniciar o worker Celery** p/ os fixes do scraper valerem no próximo import (sem hot-reload).
- [ ] Destravar o Caderno AXYS (seção 2) — **prioridade do próximo chat**.
- [ ] SINAPI/CDHU adotarem `is_public` por-arquivo (mesmo modelo da FDE) — Renan confirmou
      "vale p/ todas as fontes-base".
- [ ] Limpar blobs R2 órfãos da edi 56 (4 arquivos do §1.2).
- [ ] Migração grande (Fase 2-3): rodar dev→prod, publicar como "versão 0".

## 4. Credenciais / operação
- Portal FDE: `z_search_repos/find_fde/login_data.env` (gitignored). O parser real
  `load_login_config` faz **strip de aspas** (`'…'`) — o valor no env vem aspado.
  No app de verdade a senha é **token efêmero no Redis** (nunca persistida/nunca arg de Celery).
- DB dev: `EASY_DB_URL=postgresql://localhost/axys_easy_db` (edi 56 = FDE 04-26, **PUBLICADA**).
