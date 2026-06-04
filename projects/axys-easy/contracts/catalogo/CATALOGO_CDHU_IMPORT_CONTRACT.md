# Catálogo — Contrato de Importação CDHU

**Status:** Contrato Canônico (v0.1)
**Data:** 2026-06-02
**Fonte-base:** CDHU — Companhia de Desenvolvimento Habitacional e Urbano (SP).
**Regras globais:** ver [CATALOGO_BUSINESS_RULES.md](CATALOGO_BUSINESS_RULES.md).

> Implementação derivada deste contrato: `backend/core/import_cpu/parser_cdhu.py`
> (inclui a regra de classificação `classificar_insumo_cdhu`).

---

## 1. Características da fonte

- Mono-UF: **São Paulo** (não publica 27 capitais). MO em **horista** (`H`).
- **Mono-coluna de custo**: um único custo por insumo — **não distingue encargos/desoneração** (insumo é pelado/`SE`).
- **Sem classificação nativa**: a planilha traz código, descrição, unidade e custo — não traz o tipo do insumo.
- **Sem marcador textual de SEM PREÇO**.

### 1.1 Arquivos e fluxo de import
A CDHU divulga **4 arquivos**: `insumos`, `composicao` (analítico), `servicos`, `subgrupos`. O import "tudo de uma vez" (tela `/edicoes` → caderno → "importar composições") exige **3 excels obrigatórios**: **insumos**, **composições**, **serviços**.
- **`subgrupos.xlsx` é DESCARTADO**: grupo/subgrupo (código **e descrição**) já vêm no analítico e convergem por codificação. Grupo/subgrupo vinculam à **CPU** (`composicoes.cmp_sub_id`), nunca ao insumo.
- **`servicos`** = custo de referência da CPU (`cc_custo_fonte`) + **cabeçalho** com modalidade (COM/SEM DESONERAÇÃO), versão, data-base e **LS%** (§5). A CDHU publica **DOIS arquivos de serviço por edição** (`servicos_sd_*` e `servicos_cd_*`) — **ambos são importados**, cada um detectando sua modalidade no cabeçalho. (O insumo é pelado/`SE` único; o desdobramento SD/CD é só no custo da composição, via LS de cada regime.)

---

## 2. Classificação — REGRA léxica (fonte única)

- A classificação é **inferida pela app** por **descrição + unidade**, via `classificar_insumo_cdhu(descricao, unidade)` — **regra de negócio única** que vive no parser CDHU.
- Resultado: `ins_ti_id` ∈ {MO, EQUIP_AQ, EQUIP_LOC, MAT, SERV, ESP} com `ins_ti_origem = 'REGRA'`.
- A regra é **total** (sempre retorna um tipo) → CDHU **não precisa** de `NC` na prática.
- A mesma regra é reaplicável a registros já gravados (reclassificação) — mesma função, sem duplicar lógica.

### 2.1 Precedência no reimport
Segue a regra global **FONTE > MANUAL > REGRA** ([CATALOGO_BUSINESS_RULES.md §2.2](CATALOGO_BUSINESS_RULES.md)):
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

- O arquivo **serviços** traz o **custo de referência** de cada CPU → `composicoes_custo.cc_custo_fonte` (custo `0`/vazio = **SEM CUSTO** → `NULL`, ver BUSINESS_RULES §4).
- O **cabeçalho** traz **modalidade** (COM/SEM DESONERAÇÃO = `CD`/`SD`), versão, data-base e **LS%** (um único %, **horista**) → `edicoes_leis_sociais` (`els_horista`; `els_mensalista` NULL na CDHU). **Importam-se os DOIS regimes** (arquivos `servicos_sd_*` e `servicos_cd_*`) → `edicoes_leis_sociais` e `composicoes_custo` ganham `SD` **e** `CD`. **Sanidade:** LS é alta (ex.: v184 SD=128,23%, CD=97,78%); valor que chegue como fração (~1,28) normaliza/aborta.
- **Conferência** calculado×fonte (BUSINESS_RULES §4.1): método CDHU = **round half-up**, duas passagens — `unit_mo = round(pelado×(1+LS/100),2)`; `custo_cpu = Σ round(unit_carregado×coef,2)`. **CDHU 201 converge 100% ao centavo** (3560/3560). Truncar gerava viés negativo sistemático — a CDHU arredonda.

---

## 6. Reimport

- Insumos: upsert por `(ins_fte_id, ins_codigo)` — identidade vigente. Classificação segue precedência (§2.1).
- Preços: imutáveis por edição; reimport da mesma (insumo, edição, UF, modalidade) é idempotente.
- Composições: versionadas por edição (imutáveis); diff cadastral entre edições → `composicoes_historico` (BUSINESS_RULES §9).

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
