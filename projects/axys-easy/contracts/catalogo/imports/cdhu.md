# Catálogo — Contrato de Importação CDHU

**Status:** Contrato Canônico (v0.1)
**Data:** 2026-06-02
**Fonte-base:** CDHU — Companhia de Desenvolvimento Habitacional e Urbano (SP).
**Índice das capabilities:** [../README.md](../README.md).

> Implementação derivada deste contrato: `backend/core/import_cpu/parser_cdhu.py`
> (inclui a regra de classificação `classificar_insumo_cdhu`).

---

## 1. Características da fonte

- Mono-UF: **São Paulo** (não publica 27 capitais). MO em **horista** (`H`).
- **Mono-coluna de custo**: um único custo por insumo — **não distingue encargos/desoneração** (insumo é pelado/`SE`).
- **Sem classificação nativa**: a planilha traz código, descrição, unidade e custo — não traz o tipo do insumo.
- **Sem marcador textual de SEM PREÇO**.

### 1.1 Arquivos e fluxo de import (tela — decisão Renan 2026-06-13)
A CDHU divulga **4 arquivos**: `insumos`, `composicao` (analítico), `servicos`, `subgrupos`.
**Obrigatórios no import (tela):**
- **`insumos`** (excel) — obrigatório.
- **`composições`/analítico** (excel) — obrigatório.
- **`serviços`** (SD e/ou CD) — **pelo menos 1 obrigatório**. Espelha o padrão de docs do SINAPI:
  cada modalidade (SD, CD) tem um **checkbox "disponível" (default marcado)**; desmarcar = aquela
  modalidade não veio (edições com só uma versão). Importa-se a(s) que vier(em); a modalidade
  ausente fica **sem custo** (e a LS dela vem do manual, ver §5).
- **`critério`** (PDF) — **OBRIGATÓRIO, sem opção de indisponível**. É o documento técnico de
  medição da CDHU (PDF), análogo ao caderno do SINAPI, porém **sempre exigido**.
- **`subgrupos.xlsx` é DESCARTADO**: grupo/subgrupo (código **e descrição**) já vêm no analítico e convergem por codificação. Grupo/subgrupo vinculam à **CPU** (`composicoes.cmp_sub_id`), nunca ao insumo.
- **`servicos`** = custo de referência da CPU (`cc_custo_fonte`) + **cabeçalho** com modalidade (COM/SEM DESONERAÇÃO), versão, data-base e **LS%** (§5). Cada arquivo detecta sua modalidade no cabeçalho. (O insumo é pelado/`SE` único; o desdobramento SD/CD é só no custo da composição, via LS de cada regime.)

---

## 2. Classificação — REGRA léxica (fonte única)

- A classificação é **inferida pela app** por **descrição + unidade**, via `classificar_insumo_cdhu(descricao, unidade)` — **regra de negócio única** que vive no parser CDHU.
- Resultado: `ins_ti_id` ∈ {MO, EQUIP_AQ, EQUIP_LOC, MAT, SERV, ESP} com `ins_ti_origem = 'REGRA'`.
- A regra é **total** (sempre retorna um tipo) → CDHU **não precisa** de `NC` na prática.
- A mesma regra é reaplicável a registros já gravados (reclassificação) — mesma função, sem duplicar lógica.

### 2.1 Precedência no reimport
Segue a regra global **FONTE > MANUAL > REGRA** ([estagios.md §A.1](estagios.md)):
- CDHU não tem classificação de fonte → entra como `REGRA`;
- no reimport, **respeita `MANUAL`** (não sobrescreve curadoria humana);
- reaplica sobre `REGRA`/`NC`.
- Cadastrais (descrição/unidade) sempre atualizam.

---

## 3. Preço (`insumos_preco`)

- **Modalidade fixa `SE`** — CDHU não distingue encargos; toda linha é `SE`.
- UF fixa **`SP`**.
- `pri_valor` = custo publicado **exatamente, inclusive `0`** (zero **não** é inferido como sem preço).
- Custo vazio/ausente → `pri_valor = NULL`, situação `SEM_PRECO`. (CDHU não tem marcador SEM PREÇO; vazio = sem registro.)
- Situação (`pri_sit_id`, domínio `INSUMO`): `COM_PRECO` (valor) | `SEM_PRECO` (sem valor).
- Origem (`pri_origem`): CDHU não usa C/CR → `NULL`.

---

## 4. Composições — parser stateful (máquina de estados)

O analítico é lido sequencialmente pela **coluna A**, discriminando **primeiro pela estrutura do código** (unidade/coef corroboram):

| Padrão col. A | unid | coef | Classificação |
|---|---|---|---|
| `NN` | — | — | **grupo** (`composicoes_grupos`) |
| `NN.NN` | — | — | **subgrupo** (`composicoes_subgrupos`) |
| `NN.NN.NNN` | sim | — (ou `1` espúrio, **ignorar**) | **composição** (header) |
| código fora do padrão (insumo `B…` / subcomposição) | sim | **sim** | **item** da composição corrente |
| volta a um dos 3 primeiros padrões | | | reclassifica / novo bloco |

- O **código** é o discriminador primário; o `coef=1` espúrio em header de composição é ignorado (já classificado por código). Item sempre tem coef.
- Grupo/subgrupo (código + descrição) populam `composicoes_grupos`/`composicoes_subgrupos` a partir do próprio analítico.
- Coeficiente **único** por item (`ci_coef`).

## 5. Serviços, custo e leis sociais

- O arquivo **serviços** traz o **custo de referência** de cada CPU → `composicoes_custo.cc_custo_fonte` (custo `0`/vazio = **SEM CUSTO** → `NULL`, ver regras: listagem §2.2).
- O **cabeçalho** traz **modalidade** (COM/SEM DESONERAÇÃO = `CD`/`SD`), versão, data-base e **LS%** (um único %, **horista**) → `edicoes_leis_sociais` (`els_horista`; `els_mensalista` NULL na CDHU). Importa-se **cada regime presente** (`servicos_sd_*` / `servicos_cd_*`); a modalidade ausente fica sem custo. **Sanidade:** LS é alta (ex.: v184 SD=128,23%, CD=97,78%); valor que chegue como fração (~1,28) normaliza/aborta.
- **LS = parser + manual reconciliados (decisão Renan 2026-06-13).** O form de import permite **informar a LS% (SD/CD)** manualmente. Regra de precedência: o **parser do cabeçalho PREVALECE**; se o manual divergir do parser → vale o parser (o manual serve de conferência). **Se o parser NÃO tiver a LS** daquela modalidade (ex.: SD/CD ausente) → vale o **valor manual** do usuário. A LS afeta só o **custo carregado da composição** (SD/CD) — **não altera o "pelado" `SE`** do insumo, que entra cru no banco.
- **Conferência** calculado×fonte (regras: listagem §2.2): método CDHU = **round half-up**, duas passagens — `unit_mo = round(pelado×(1+LS/100),2)`; `custo_cpu = Σ round(unit_carregado×coef,2)`. **CDHU 201 converge 100% ao centavo** (3560/3560). Truncar gerava viés negativo sistemático — a CDHU arredonda.
- **`SE` sempre calculado** (custo nunca zera) — ver regras: listagem §2.1 Edição só-SD → SD conferido + **SE DERIVADO**.

### 5.1 PDF(s) de Leis Sociais (documento inteiro, não parseado) — 2026-06
- Além da LS lida do cabeçalho do serviço (para o cálculo), a CDHU publica o(s) **PDF(s) de encargos sociais** (ex.: `encargos sociais 128.23.pdf` / `97.78.pdf`). São guardados **inteiros** (não parseados), como livros/notas.
- O form de import aceita **lista de PDFs** (a CDHU às vezes tem mais de um — é o único campo multi-arquivo). Cada um vira um documento da edição: `doc_tipo='leis_sociais'`, `doc_edi_id`, em `easy/fontes/cdhu/{edicao}/originais/leis_sociais_{edicao}_{n}.pdf` (ver CATALOGO_STORAGE_LAYOUT). Entram na lista "Ver/Baixar" do caderno técnico.
- **Flag de disponibilidade:** desmarcar a modalidade (SD/CD) zera também a LS manual daquela modalidade — sem caderno técnico = sem LS.

---

## 6. Reimport

- Insumos: upsert por `(ins_fte_id, ins_codigo)` — identidade vigente. Classificação segue precedência (§2.1).
- Preços: imutáveis por edição; reimport da mesma (insumo, edição, UF, modalidade) é idempotente.
- Composições: versionadas por edição (imutáveis); diff cadastral entre edições → `composicoes_historico` (regras: estagios §A.7).

---

## 7. Estado de implementação

| Item | Estado |
|---|---|
| Classificação léxica (`classificar_insumo_cdhu`) | **Implementada** |
| Modalidade `SE`, não pular custo `0`, lock de curadoria no `ON CONFLICT` | **Implementado** (rodada anterior) |
| `pri_sit_id` (COM_PRECO/SEM_PRECO) no parser | **Implementado** (2026-06-03): custo numérico→COM_PRECO; vazio→SEM_PRECO (grava linha) |
| `ins_ti_origem='REGRA'` explícito + prevalência FONTE>MANUAL>REGRA no `ON CONFLICT` | **Implementado** (2026-06-03): rank FONTE=3>MANUAL=2>REGRA=1, entrada vence se rank ≥ gravado |
| Parser de composições (máquina de estados §4) | **Pendente** (Fase 2) |
| Serviços → `cc_custo_fonte` + `edicoes_leis_sociais` (§5) | **Pendente** (Fase 2) |
| Conferência calculado×fonte + alertas | **Pendente** (Fase 2.1) |
| Diff cadastral entre edições → histórico | **Pendente** (Fase 2.2) |

> Validado contra o schema pós-fundação (2026-06-02): `pri_sit_id NOT NULL` agora é setado pelo parser; cadastrais (descrição/unidade) sempre atualizam.
