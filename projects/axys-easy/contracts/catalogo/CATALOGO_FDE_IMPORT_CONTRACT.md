# Catálogo — Contrato de Importação FDE

**Status:** Contrato Canônico (v0.1)
**Data:** 2026-06-30
**Fonte-base:** FDE — Fundação para o Desenvolvimento da Educação (SP).
**Regras globais:** ver [CATALOGO_BUSINESS_RULES.md](CATALOGO_BUSINESS_RULES.md).
**Espelhos de referência:** [CATALOGO_CDHU_IMPORT_CONTRACT.md](CATALOGO_CDHU_IMPORT_CONTRACT.md) e
[CATALOGO_SINAPI_IMPORT_CONTRACT.md](CATALOGO_SINAPI_IMPORT_CONTRACT.md).

> Implementação derivada deste contrato: `backend/core/import_cpu/parser_fde.py` (migrado Fase-2 +
> R1/R3 em 2026-07-14, validado — ver `valida_amostra_fde.py`).
> Princípio: **import ADITIVO** — não cria formato novo, não altera comportamento existente.
> Em qualquer ambiguidade de regra → **PARAR e perguntar**, não improvisar.

---

## 0. Origem dos dados (sandbox)

A extração dos PDFs (analítica/sintética/BDI/LS) já foi feita FORA do app, em
`z_search_repos/find_fde/`, e produziu CSVs **já no formato-alvo**: `tabela_insumos.csv`,
`tabela_composicoes.csv`, `fde_catalogo_extraido.csv`, etc. **Esses CSVs são a fonte de
verdade da carga** — o parser do app lê deles e insere; não reparseia PDF dentro do app.

## 1. Características da fonte

- Mono-UF: **São Paulo**. MO em **horista**.
- **PUBLICA COM BDI EMBUTIDO** — particularidade rara (SINAPI/CDHU publicam custo *sem* BDI).
  É o ponto que diferencia este contrato → ver §2.
- Publica também **Leis Sociais** e **BDI** em PDF (ver §3 e §4).
- Edição atual: **abril/2026**.

## 2. BDI — A REGRA QUE DIFERENCIA A FDE (decisão Renan 2026-06-30, **REVISTA 2026-07-03**)

> ⚠️ **REVISÃO 2026-07-03** — o modelo mudou. A v0.1 mandava *limpar* o `cc_custo_fonte` no
> import (strip). **NÃO é mais assim.** A regra canônica agora é [CATALOGO_BUSINESS_RULES.md](CATALOGO_BUSINESS_RULES.md)
> **§4.3** — `cc_custo_fonte` guarda SEMPRE o publicado cru; a app **exibe o calculado**; a
> des-BDInização é só no MOMENTO de comparar/exibir. O que segue reflete o modelo novo.

O catálogo **exibe** CUSTO limpo (sem BDI) — mas via `cc_custo_calculado`, não limpando o fonte.
O BDI é aplicado no orçamento, **por ativo**. A FDE publica COM BDI; o import grava:

- **`cc_custo_fonte` = o publicado CRU (COM BDI)** — é o que a fonte registrou (auditoria ao
  centavo). **NÃO** se limpa essa coluna. (SINAPI/CDHU guardam limpo só porque publicam limpo.)
- **`cc_custo_calculado` = Σ itens×coef + LS = custo LIMPO** (montagem normal da app, como as
  outras fontes). É o que a app **exibe** e o que o orçamento usa (sem risco de BDI-sobre-BDI,
  porque a precificação parte do calculado, não do fonte).
- **O BDI da FDE é UNIFORME** (um BDI para a família toda; pode haver NORMAL + REDUZIDO) →
  grava em **`catalogo.edicoes_bdi`** (ver §4). A **presença** dessa linha é o sinal de que o
  `cc_custo_fonte` da edição está com BDI.
- **O valor limpo do fonte é DERIVADO na hora de comparar/exibir:** `cc_custo_fonte ÷ (1 + ebd_percent/100)`.
  Não criar campo/JSON de proveniência para isso.
- **Conferência (des-BDInizada):** o import compara `cc_custo_calculado` (Σ itens, limpo) contra
  `cc_custo_fonte ÷ (1 + BDI%)` (fonte des-BDInizado) → grava `cc_diferenca_valor`/`cc_status_conferencia`.
  Se comparar contra o fonte cru, **toda linha marca DIVERGENTE pelo BDI** (errado). Divergência
  expressiva **após** des-BDInizar = erro de parse/strip de fato → PARAR. (É a mesma conta que o
  `fde_precifica_composicoes_diff.py` já faz: `base × (1+BDI) ≈ publicado`.)

## 3. Preço / custo (regras globais valem)

Segue as regras globais e os contratos SINAPI/CDHU — sem desvio:
- **Insumos** (`catalogo.insumos` + `insumos_preco`): preço é **NULL** quando não há preço
  (nunca 0); "custo 0" pode significar SEM CUSTO — tratar conforme business rules.
- **`ci_situacao` é DERIVADO** (COM PREÇO / SEM PREÇO) — não inventar estado.
- **Identidade em CAIXA ALTA** (descrição/subgrupo/unidade); verbatim `ci_*_fonte_original` cru.
- **Composições** (`composicoes` + `composicoes_itens` + `composicoes_custo`): custo limpo (§2).
- **Idempotência por chave de negócio**: reimport da mesma edição sobrescreve, não duplica.

> BDI **não incide sobre insumo** (incide no serviço/composição). Logo o strip do §2 atua no
> custo das composições; insumos entram como custo pelado normal.

## 4. BDI publicado → `catalogo.edicoes_bdi`

Tabela nova (DDL já no `schema.sql`), espelha `ativo.ativo_bdi`:
- `edicoes_bdi` (`ebd_`): header — `ebd_edi_id` (FK `catalogo.edicoes`), `ebd_uf`, `ebd_classe`
  (NORMAL | REDUZIDO), `ebd_regime`, `ebd_percent` (BDI %), `UNIQUE (edi_id, uf, classe)`.
- `edicoes_bdi_composicao` (`ebdc_`): parcelas do **Acórdão 2622/2013** (AC|SG|R|DF|L|CP|ISS|CPRB).

Popular com o BDI que a FDE publica. Serve de **referência** e de **default do `ativo_bdi`**
quando o orçamentista usa FDE (em vez do TCU genérico). **Não** é aplicado ao custo de consulta.

## 5. Leis Sociais

A FDE publica LS → grava em `catalogo.edicoes_leis_sociais` (`els_`) + `_itens` (`elsi_`),
mesmo padrão de SINAPI/CDHU (ver [project_ls_encargos]). O PDF inteiro de LS entra como
**documento** da edição (não parseado), como no CDHU §5.1.

## 6. Reimport

Idempotente por edição: reimportar a mesma edição/UF substitui (não duplica). Mesma serialização
da carga das outras fontes (`pg_advisory_xact_lock(fte_id)`).

## 7. Definição de pronto (verificação anti-regressão OBRIGATÓRIA)

- Contagens batendo: nº de insumos/composições inseridos == nº dos CSVs de `find_fde`.
- **`cc_custo_fonte` = publicado CRU (com BDI)**; **`cc_custo_calculado` = LIMPO** (Σ itens); `edicoes_bdi` populado com o %.
- Conferência **des-BDInizada** grava status limpo: `cc_custo_calculado` ≈ `cc_custo_fonte ÷ (1+ebd_percent/100)` (amostral).
- **SINAPI e CDHU inalterados**: rodar os imports/telas deles e confirmar zero diff de
  comportamento. Qualquer alteração neles = erro → reverter.
- Trabalho em **branch** (`feat/import-fde`), **PR para revisão humana**, nunca main/deploy.
