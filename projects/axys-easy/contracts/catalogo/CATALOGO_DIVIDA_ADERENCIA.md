# Catálogo — Dívida de Aderência do Schema (roteiro sob ADR-22)

**Status:** Aberto — 2026-07-14
**Origem:** laudo crítico do `schema.sql` sob `foundation/adrs/AXYS-ADR-022` (design minimalista/sustentável), revisado com Renan.
**Regra do laudo:** `catalogo`/`audit` deveriam estar **fechados** → qualquer estranheza ali é dívida de refactor anterior. `ativo`/`tenant_catalogo` estão em obra ou são reserva proposital (fora do escopo).

> **Veredito honesto:** o `catalogo` **não tem dado errado nem regressão de comportamento**. Tem **dívida de comentário/foto** (a maior parte — higiene) e **2-3 decisões de enxugamento** que esperam o próximo ciclo de refactor. A marcação inicial de "🔴 regressão" foi dura demais; o correto é 🟡 higiene + 🟠 decisão.

**Legenda:** 🟠 refactor (toca schema+parser+service+tela, exige rebuild) · 🟡 higiene (só comentário/foto/ADR, zero risco) · 🟢 mantido (decisão de Renan).

---

## 🟠 Refactor — executa no próximo ciclo (junto com a migração Fase-2 da leitura + rebuild)

### R1 — Remover `composicoes_itens.ci_{codigo,descricao,unidade}_fonte_original`
- **O quê:** 3 colunas que guardam o texto BRUTO do item como a fonte apresentou, antes de resolver p/ FK.
- **Por que sai:** a associação item→insumo é **determinística por código** (`parser_sinapi.py` casa `ins_codigo`→`ins_id`, sem fuzzy) → não existe "casar no insumo errado", logo o verbatim não corrige nada. E **sobretensiona**: repete descrição por item×composição — **mais volume de texto de descrição que a própria `insumos`**. Fere ADR-22 #1 (minimalista) e #4 (diferenciado: mesma verdade em item vs identidade).
- **Auditoria fica coberta:** o **original (xlsx)** já está em `catalogo.documentos` (`doc_tipo='original'`, por edição, `is_public` pela fonte). Cruzamento fonte×banco = **tela sob demanda** (edição → path do original, targetável a um insumo/CPU) — não coluna em massa. (CSV é só do FDE, que é o input dele; o import já registra.)
- **Toca:** `schema.sql` (drop 3 col. + comentário), `parser_sinapi.py`/`parser_cdhu.py`/`parser_fde.py` (parar de escrever), `composicoes_service._itens` + `descritivo_request._itens` (parar de ler no COALESCE), `composicoes_historico.ch_dados_novos` (o verbatim histórico, quando quisermos, vive no snapshot).

### R2 — Padronizar a convenção temporal dos dois `_historico`
- **O quê:** `insumos_historico` usa `ih_edi_id_inicio/fim` (range); `composicoes_historico` usa `ch_edi_id_origem/nova` (evento). Mesmo papel, formas diferentes (ADR-22 #4).
- **Decisão (Renan):** padronizar na convenção que dá **query mais assertiva + menor custo** = **append-only com edição-de-efeito única** (o `nova`/`inicio`): as-of E = `max(edi_efeito) ≤ E` num único index scan; sem mutar linha antiga (o `fim`/`origem` é o limite derivável, redundante → eliminar). Alinhar ambas a **um** nome/coluna.
- **Nota:** o `edi_id` de efeito **não** é descartável (é o índice temporal do snapshot — o JSON guarda o *conteúdo*, o `edi_id` guarda o *quando*); descartável é só o **limite redundante**.
- **Toca:** `schema.sql` (colunas dos dois historico), o código que grava o histórico (diff do parser), leitores (`get_historico_custos`, insumos equivalente).

### R3 — Eliminar `catalogo.situacoes` → `pri_situacao TEXT CHECK`
- **O quê:** `situacoes` é tabela-lookup de domínio. Composições **já não** a usam (`cmp_situacao TEXT CHECK`); só `insumos_preco` ainda usa (`pri_sit_id` FK composta **+** `pri_sit_dominio`, coluna NOT NULL presa a um único valor 'INSUMO' por CHECK, existindo só p/ fechar a FK).
- **Por que sai:** situação de preço tem **2 valores** (com/sem preço). Enum pequeno/fixo como tabela+FK-composta+coluna-morta = ADR-22 #1/#2 feridos; composições já mostram o jeito enxuto (CHECK inline). O próprio comentário do schema já marcava isso como ALVO.
- **Como (com maestria):** trocar `pri_sit_id`/`pri_sit_dominio` por `pri_situacao TEXT CHECK (pri_situacao IS NULL OR pri_situacao IN ('COM PREÇO','SEM PREÇO'))`; então **dropar** `catalogo.situacoes` inteira (nada mais a referencia).
- **Toca:** `schema.sql` (col. em `insumos_preco` + drop tabela + seed), parser de preço (`parser_sinapi`/`parser_cdhu` param de gravar `pri_sit_id`), qualquer leitor de `pri_sit_*`.

> **Sequência:** R1/R2/R3 entram **junto** com a migração Fase-2 da leitura (`composicoes_service`/`ativo`/viewer/`_docs_vinculados`) — um ciclo só de refactor, fechado por **rebuild + `valida_amostra`** (preço/custo × Excel = 0 divergências, como já validado hoje em 9 edições).

---

## 🟡 Higiene — feita AGORA (só comentário/foto/ADR, zero risco)

- **H1** (A.2) — `composicoes_itens`: comentário "cmp_id **inclui edição**" (Fase-1) → corrigido p/ Fase-2 (identidade sem edição).
- **H2** (A.3) — `composicoes_historico`: rótulo "[EXPANSÃO FUTURA] / não populada / não usar" → corrigido (é o **snapshot ATIVO** da Fase-2; import grava, `get_historico_custos` lê).
- **H3** (C.1) — blocos "ALVO FASE 2" embutidos no schema (situacoes, unidades, composições §9.6) → **removidos da foto**; o plano vive **aqui** (este doc) + `CATALOGO_BUSINESS_RULES §9.6`. A foto descreve o que **É**.
- **H4** (C.2) — cabeçalho JSONB stale (bloco `external_path` antigo `{bucket,vigente,revisoes}`) → **apagado** (a spec real é §11.10 + comentários de coluna). A parte **audit** do cabeçalho (log_dados_antes/depois) é válida e **fica**.
- **H5** (C.3) — nota de convenção "PKs INTEGER" → corrigida ("PKs IDENTITY; tabelas de volume = BIGINT").

---

## 🟢 Mantido (decisão de Renan)

- **M1** (B.1) — Reservas "EXPANSÃO FUTURA" (`insumos_classificacao/atributos/codigos_externos/nfe_itens_precos`): **mantidas** — pendência com **gatilho nomeado** (Lei 14.133, pesquisa de preço por NF-e). Não é especulação; é reserva planejada. → ADR-22 recebe a cláusula: *reserva estrutural é aceitável quando carrega gatilho concreto documentado*.
- **M2** (F) — `tenant_catalogo.*` (biblioteca do tenant) e `ativo.ficha_tec_*` (etapas construtivas): **propositais**, permanecem.

---

## Precedente e referências
- `foundation/adrs/AXYS-ADR-022` — princípios (minimalista/não-generalista/diferenciado/sustentável; "simples sem sofrimento").
- `CATALOGO_BUSINESS_RULES.md §9.6` (modelo contínuo Fase-2) · **§11.9/§11.10/§11.11** (repense doc/path — precedente canônico de aplicação da ADR-22).
- ⚠️ `CATALOGO_NEXT_STEPS.md` tem cabeçalho **stale** ("Fase 2 cancelada") — a Fase 2 **foi aplicada**; ver aviso lá + este doc é a verdade corrente da dívida.
