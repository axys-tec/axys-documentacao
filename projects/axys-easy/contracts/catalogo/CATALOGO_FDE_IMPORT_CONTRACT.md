# Catálogo — Contrato de Importação FDE

**Status:** Contrato Canônico (v0.1)
**Data:** 2026-06-30
**Fonte-base:** FDE — Fundação para o Desenvolvimento da Educação (SP).
**Regras globais:** ver [CATALOGO_BUSINESS_RULES.md](CATALOGO_BUSINESS_RULES.md).
**Espelhos de referência:** [CATALOGO_CDHU_IMPORT_CONTRACT.md](CATALOGO_CDHU_IMPORT_CONTRACT.md) e
[CATALOGO_SINAPI_IMPORT_CONTRACT.md](CATALOGO_SINAPI_IMPORT_CONTRACT.md).

> Implementação derivada deste contrato: `backend/core/import_cpu/parser_fde.py` (a criar).
> Princípio: **import ADITIVO** — não cria formato novo, não altera comportamento existente,
> schema CONGELADO. Em qualquer ambiguidade de regra → **PARAR e perguntar**, não improvisar.

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

## 2. BDI — A REGRA QUE DIFERENCIA A FDE (decisão Renan 2026-06-30)

O catálogo guarda **CUSTO (sem BDI)**; o BDI é aplicado no orçamento, **por ativo**. A FDE
publica COM BDI, então o import **TEM que remover o BDI** antes de gravar.

- **STRIP do BDI no import** → `composicoes_custo.cc_custo_fonte` **E** `cc_custo_calculado`
  ficam **LIMPOS** (sem BDI), exatamente como SINAPI/CDHU.
- **Por que `cc_custo_fonte` precisa ser limpo:** a consulta exibe
  `COALESCE(cc_custo_fonte, cc_custo_calculado)` (`composicoes_service.py`) → mostra o **fonte**.
  Se o fonte fosse com-BDI, a busca exibiria com-BDI, e ao aplicar o BDI do ativo daria
  **BDI-sobre-BDI**. Por isso **fonte = limpo**. (Inverter a consulta p/ exibir `calculado`
  mudaria o display de SINAPI/CDHU → regressão. PROIBIDO.)
- **O BDI da FDE é UNIFORME** (um BDI para a família toda; pode haver NORMAL + REDUZIDO) →
  grava em **`catalogo.edicoes_bdi`** (ver §4). Não vai em coluna de custo.
- **O valor original COM BDI NÃO é armazenado** — é **derivável**: `limpo × (1 + BDI%)`, com o
  BDI% vindo de `edicoes_bdi`. Não criar campo/JSON de proveniência para isso.
- **Conferência:** com o strip correto, `cc_custo_calculado` (Σ itens) deve **bater** com
  `cc_custo_fonte` (publicado-limpo) → `cc_status_conferencia` limpo. Divergência expressiva =
  erro de strip → PARAR.

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
- **`cc_custo_fonte` e `cc_custo_calculado` LIMPOS** (sem BDI); `edicoes_bdi` populado com o %.
- Reconstrução: `limpo × (1 + ebd_percent/100)` ≈ valor publicado original (amostral).
- **SINAPI e CDHU inalterados**: rodar os imports/telas deles e confirmar zero diff de
  comportamento. Qualquer alteração neles = erro → reverter.
- Trabalho em **branch** (`feat/import-fde`), **PR para revisão humana**, nunca main/deploy.
