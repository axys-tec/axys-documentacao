# Catálogo — Próximos passos (orientação)

> 🔁 **CORREÇÃO 2026-07-14 — a Fase 2 FOI aplicada** (o aviso 2026-06-14 abaixo ficou **stale**).
> O banco hoje **É** Fase 2: composição = identidade vigente (`cmp_edi_id` **removido**), série
> densa por `cc_edi_id`, snapshot em `*_historico`. O que resta de Fase 2 **não** foi cancelado —
> virou **dívida de aderência rastreada** em [`CATALOGO_DIVIDA_ADERENCIA.md`](CATALOGO_DIVIDA_ADERENCIA.md)
> (situacoes→CHECK, `ci_*_fonte_original`, alinhar historico). As seções "Fase 2" abaixo são
> **histórico de planejamento** — a verdade corrente está no schema + BUSINESS_RULES §9.6 + o doc de dívida.

> ⚠️ **ATUALIZAÇÃO 2026-06-14 — Fase 2 (drop+recriar banco) CANCELADA (Renan).** *(supersedida pela correção acima)*
> O Catálogo é usado **COMO ESTÁ** (módulo fechado em dev — ver `CATALOGO_FECHAMENTO.md`).
> As mudanças de schema descritas abaixo como "Fase 2 / recriação" (dropar `*_external_path`,
> `catalogo.situacoes`→CHECK-text, `cmp_edi_id`, `cc_edi_id`, FK `unidades` etc.) **não serão
> aplicadas** — custo@edição já é resolvível no modelo atual (composição é por edição), e o
> módulo **Ativos** parte do Catálogo como está. Trate as seções de "Fase 2" abaixo como
> **histórico**, não como pendência.

Estado em **2026-06-05**: o **import p/ o banco** (CDHU + SINAPI: parse → normalização →
armazenamento → conferência) e a **publicação dos documentos no R2** (fichas, cadernos +
apresentação, critérios + metodologia, livros) estão **completos e validados** (pipeline +
amostras, ao rigor metodológico). Ver `CATALOGO_BUSINESS_RULES.md` §10 (ciclo de vida) e §11
(publicação no R2, estrutura de diretórios, livros, metodologia).

## Devolutiva (o que de fato valida o trabalho)
As eventuais falhas pontuais no R2 (ex.: ~6 CPUs de caderno sem match na edição, contagens
3562/3560) são **pouco expressivas**. O que importa é que houve **convergência extrema dos
dados de preço** e que **tudo foi construído sobre a versão SE** (Sem Encargos sociais
destacados / "pelado + LS") — que é como o catálogo se orienta (ver §3.1 e
`project-import-sinapi-doctrine`). Essa é a validação real.

## Orientação para a evolução — CAMADA DE SERVIÇO

O princípio: **os parsers/geradores já existentes são a fonte da verdade super-validada —
IMPORTAR, não duplicar/reescrever.**

1. **Biblioteca (já pronta, modular, validada)** — `backend/core/import_cpu/`:
   - `parser_cdhu.py`, `parser_sinapi.py` (import p/ banco)
   - `fichas_sinapi.py`, `criterios_cdhu.py` (+ `parse_metodologia_cdhu`), `cadernos_sinapi.py`
     (PDF → HTML normalizado)
   Estes **não** são scripts de teste — são a camada de parsing. Reaproveitar como está.

2. **Orquestração — promover de script → serviço.** Hoje vive em `z_scripts_apoio/`
   (`import_*`, `gera_livros`, `restamp_css`, `migra_*`, `fix_audit_*`): download → parse →
   R2 → banco → skip-por-data → audit → livros. Extrair essa lógica para **serviços**
   (ex.: `ImportService`, `PublicacaoService`/`CatalogoDocsService`) que **importam os parsers**
   acima e expõem funções de alto nível (importar edição, publicar docs, gerar livros).

3. **Um service, dois consumidores.** As **rotas/telas** e os **runners CLI** chamam os
   **mesmos serviços** — uma lógica só. Os runners CLI permanecem como *thin wrappers*
   (útil p/ batch, cron, operação manual); as rotas plugam nas telas.

4. **Telas + ciclo de vida** (frente de app pendente, já suportada no schema/contrato §10):
   - import de fonte/edição (upload p/ `audit/`, disparo do import);
   - botão **Publicar** + validação dos gates (`edi_ins_catalogo_ok`, `edi_comp_catalogo_ok`),
     badge `RASCUNHO`/`PUBLICADA`, **lock** da edição publicada (camada app);
   - render responsivo (calibrar mobile/desktop na app, sobre o conteúdo puro do R2).

## Registro central de documentos (FEITO fase 1 — 2026-06-05)
Adotado o **Caminho 2**: `catalogo.documentos` + `documentos_origem` (ver BUSINESS_RULES §11.9).
Fronteira de governança: import escreve, app/livros lêem. Backfill do estado atual feito
(`backfill_documentos.py`: ~21.978 docs + 177 origens) e **livros já lêem do registro**.
- **Fase 2 (a fazer — JUNTO DA UI):** reescrever os runners (`import_fichas`, `import_cadernos`,
  `import_criterios`) p/ gravar direto em `documentos`/`documentos_origem` (em vez dos JSONB).
  > **DIRETRIZ (Renan):** para avançar, **DROPAR e RECRIAR o banco do zero** — o `schema.sql` novo
  > já nasce com `documentos`/`documentos_origem` como **fonte única** e **SEM** as colunas
  > `ins_external_path`/`cmp_external_path`/`edi_capa_path`. Re-importar tudo do **audit/R2 (que NÃO
  > se limpa)** já gravando no registro. Não há migração in-place: recria limpo. (Backfill atual é
  > ponte só enquanto o banco vigente existir.)
- **Equipamento por-insumo:** ajustar `parse_caderno` p/ detectar CPU pelo cabeçalho de metadados
  (árvore opcional) e gerar per-CPU dos 2 cadernos de equipamento, linkando ao insumo — hoje estão
  como `referencia` (PDF) no registro.

## fontes / edicoes — reconciliação com o registro (desenho p/ a recriação, Fase 2)
Como a Fase 2 **recria o banco**, as mudanças de coluna vão pro `schema.sql` (não ALTER no vivo).
Decisão de coerência com o registro `documentos` (§11.9), p/ **não re-misturar governança**:
- **NÃO** criar `fontes.metodologia`/`metodologia_old` — metodologia é `documentos(tipo='metodologia')`
  com `doc_vigente` (atual) + linhas `vigente=false` (histórico). (Ideia anterior superada pelo registro.)
- **NÃO** criar `composicoes_subgrupos.apresentacao_path` — apresentação é `documentos(tipo='apresentacao', sub_id, edi_id)`.
- **Dropar** `edicoes.edi_capa_path` e os `*_external_path` (eram cache da fase 1).
- **Manter** as colunas de GOVERNANÇA já existentes (não são doc): `fontes.fte_catalogos_continuos`,
  `fontes.fte_tem_catalogo_insumos`; `edicoes.edi_situacao_ciclo`, `edi_ins_catalogo_ok`,
  `edi_comp_catalogo_ok`. ⚠️ **A confirmar com Renan:** se há OUTRA coluna de governança desejada
  em fontes/edicoes (fora docs) — p/ docs, o registro já cobre.
- **Origem das fontes-base** (links de import) → `documentos_origem` (não em `fontes`).

## insumos / composições — modelo contínuo (desenho Fase 2, decisão Renan 2026-06-07)
Regra canônica: `CATALOGO_BUSINESS_RULES.md §9.5 (insumos) e §9.6 (composições)`. Aplicar no `schema.sql`
(CREATE TABLE) **junto** com os parsers na recriação — não mexer no banco vivo nem nos parsers agora.

**Insumos:** já está OK no schema (`insumos` vigente + `insumos_preco` denso/edição + `insumos_historico`
esparso). Só **doutrina nova** (sem mudança de tabela): leitura histórica = **trinca atômica**
`(preço@E, unidade@E, descrição@E)`; conversão de unidade é **app-dependente** (não auto-converte).

**Composições — mudanças de SCHEMA (Fase 2):**
- `composicoes`: remover `cmp_edi_id` (+FK/idx); UNIQUE → `(cmp_fte_id, cmp_codigo)` (identidade vigente).
- `composicoes_itens`: dropar `ci_codigo_fonte_original`, `ci_descricao_fonte_original`,
  `ci_unidade_fonte_original` (filho resolvido pela identidade); vira **receita vigente**.
- `composicoes_custo`: **adicionar `cc_edi_id`** (+FK→edicoes); UNIQUE → `(cc_cmp_id, cc_edi_id, cc_uf, cc_modalidade)`.
- `composicoes_historico`: usar `ch_dados_novos` como **snapshot completo** `{descricao, unidade, receita[]}`
  + `ch_diff` (delta); padronizar regra de validade vs `insumos_historico` (`origem/nova` × `inicio/fim`).
- **Manter** os nomes `insumos_preco` (preço) × `composicoes_custo` (custo) — distinção de domínio, não renomear.

**Situação → CHECK-text (BUSINESS_RULES §6, decisão 2026-06-07):**
- **Dropar `catalogo.situacoes`**. `insumos_preco`: trocar `(pri_sit_id, pri_sit_dominio)` + FK composta + CHECK de domínio por `pri_situacao TEXT CHECK (… IN ('COM PREÇO','SEM PREÇO'))` (null = sem preço).
- Composições já usam CHECK-text (`cmp_situacao`/`ci_situacao`) — sem mudança lá. Migrar dado vivo: `pri_sit_id` → texto via lookup, na recriação.

**Unidades — vocabulário controlado (BUSINESS_RULES §8.2, decisão 2026-06-07):**
- **`catalogo.unidades` já criada** (schema + dev, PK natural = `un_codigo`, semeada com o vocabulário atual). FALTA (Fase 2): **FK** `insumos.ins_unidade` e `composicoes.cmp_unidade` → `unidades(un_codigo)`.
- **Unidade de fonte = VERBATIM** (fidelidade §9.5): import upserta a unidade como a fonte manda; **não normalizar** dado importado. A convenção canônica (X/sem acento/maiúsculas) é só **guia p/ criação manual** ("Outra"). Variantes de fonte (`M2/MES`, `M2XME`, `CJXDI`…) ficam no registro como publicadas; agrupamento/exibição é problema de UI, não transform de dado.

**Parsers — o que mexer (Fase 2, junto com os imports de tela):**
- **Unidades:** ao importar insumo/composição, **UPSERT em `unidades`** a unidade **verbatim** (como a fonte manda — sem normalizar).
- **Situação (insumo):** gravar `pri_situacao` texto (não mais `pri_sit_id`).
- **Composições (SINAPI/CDHU):** parar de gravar `composicoes` por edição → **upsert na identidade**
  (`fte+codigo`); gravar **receita vigente** em `composicoes_itens` (sem `*_fonte_original`); gravar
  **custo por edição** em `composicoes_custo` com `cc_edi_id`; ao detectar mudança de descrição/unidade/
  receita vs vigente, emitir evento em `composicoes_historico` com **snapshot completo** em `ch_dados_novos`.
- **Diff (§9.1–9.2):** continua contra o vigente; receita entra como snapshot (não item-a-item).
- **Insumos:** parser **inalterado** estruturalmente; garantir que `ALTERACAO_*` registra
  descrição/unidade em `insumos_historico` (já previsto em §9.2) — base da trinca de retroação.
- **App/serviço (telas de import + consulta):** função única `obter_insumo_em_edicao(ins, E)` (trinca) e
  equivalente p/ composição (custo@E direto; receita@E via histórico; explosão recursiva as-of-E).

## Busca inteligente do catálogo — SearchService (decisão Renan 2026-06-11)
Contrato: `CATALOGO_SEARCH.md`. **Fase A FEITA:** `catalogo.search_document` (índice 1×1 texto+facetas,
prefixo `sd_`), `backend/core/search/` (contrato + adapters + `SearchIndexer`), extensões `unaccent`/`pg_trgm`
em `catalogo`, **carga inicial** (8363 INS + 13938 CPU). PG fonte da verdade; busca devolve candidatos → app reidrata.
- **PASSO 5 (a alinhar antes):** implementar `PostgresSearchAdapter.search` (ts_rank + trigram `OPERATOR(catalogo.%)`
  + código exato + alias) e **plugar na listagem de insumos** (termo → `SearchService` → IDs → `get_insumos(ids)`),
  + hook `SearchIndexer.rebuild()` no CRUD de insumo/composição.
- **Import:** chamar `rebuild_all()`/batch no FIM do import (nunca por linha).
- **Fase C:** `ElasticSearchAdapter` (stub pronto) quando a escala pedir — só troca o adapter (`SEARCH_BACKEND=elastic`).

## Rollout de produção (obs Renan)
- Importar da edição SINAPI **mais antiga → mais nova**; se faltar item, a app **skipa** (casos de
  skip: sem links etc.) — sem ficar vaga em excesso.
- Sobe pra produção nos imports, mas **só libera p/ tenants** quando TODAS as tabelas do modelo
  recente (os 4 excels) estiverem no banco. Mapear esses docs também (já no registro como `referencia`).

## Pendências menores (não bloqueiam)
- **skip-por-data**: implementado, exercitado só na 1ª subida; validar numa virada de edição real.
- ~~6 CPUs de caderno órfãs~~ **RESOLVIDO**: CPU documentada no caderno mas fora da edição atual
  (descontinuada) → o runner linka na edição mais recente que tem o código (inativa) marcando
  `orfao=True` → aparece em **Cadernos descontinuados**. Códigos nunca importados ficam p/ a UI
  (criar inativo + auditar histórico) — ver sugestão Renan.
- **2 cadernos de EQUIPAMENTO** (*Custos Horários… dos Equipamentos*, *Depreciação… Operação dos
  Equipamentos*): têm apresentação mas **0 composição** (custo horário de equipamento não é
  `composicao` no modelo). Hoje a apresentação fica órfã (não listada). **Decisão pendente**:
  listar como caderno-referência (só apresentação) ou modelar o custo de equipamento.
- **descontinuados**: cadernos = 6 (pipe-PVC ed. antiga); fichas = 874 (insumos inativos com ficha).
