# Catálogo — Contrato de Importação CDHU

**Status:** Contrato Canônico (v0.1)
**Data:** 2026-06-02
**Fonte-base:** CDHU — Companhia de Desenvolvimento Habitacional e Urbano (SP).
**Regras globais:** ver [CATALOGO_BUSINESS_RULES.md](CATALOGO_BUSINESS_RULES.md).

> Implementação derivada deste contrato: `backend/core/import_cpu/parser_cdhu.py`
> (inclui a regra de classificação `classificar_insumo_cdhu`).

---

## 1. Características da fonte

- Mono-UF: **São Paulo** (não publica 27 capitais).
- **Mono-coluna de custo**: um único custo por insumo — **não distingue encargos/desoneração**.
- **Sem classificação nativa**: a planilha traz código, descrição, unidade e custo — não traz o tipo do insumo.
- **Sem marcador textual de SEM PREÇO**.

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

## 3. Preço (`precos_insumo`)

- **Modalidade fixa `SE`** — CDHU não distingue encargos; toda linha é `SE`.
- UF fixa **`SP`**.
- `pri_valor` = custo publicado **exatamente, inclusive `0`** (zero **não** é inferido como sem preço).
- Custo vazio/ausente → `pri_valor = NULL`, situação `SEM_PRECO`. (CDHU não tem marcador SEM PREÇO; vazio = sem registro.)
- Situação (`pri_sit_id`, domínio `INSUMO`): `COM_PRECO` (valor) | `SEM_PRECO` (sem valor).
- Origem (`pri_origem`): CDHU não usa C/CR → `NULL`.

---

## 4. Reimport

- Insumos: upsert por `(ins_fte_id, ins_codigo)` — identidade vigente. Classificação segue precedência (§2.1).
- Preços: imutáveis por edição; reimport da mesma (insumo, edição, UF, modalidade) é idempotente.

---

## 5. Estado de implementação

| Item | Estado |
|---|---|
| Classificação léxica (`classificar_insumo_cdhu`) | **Implementada** |
| Modalidade `SE`, não pular custo `0`, lock de curadoria no `ON CONFLICT` | **Implementado** (rodada anterior) |
| `pri_sit_id` (COM_PRECO/SEM_PRECO) no parser | **Pendente** (schema já exige `pri_sit_id`) |
| `ins_ti_origem='REGRA'` explícito + prevalência FONTE>MANUAL>REGRA no `ON CONFLICT` | **Pendente** (ajuste de alinhamento ao contrato) |

> Nota: após a fundação de schema (2026-06-02), `pri_sit_id` é `NOT NULL`. O parser CDHU **precisa** passar a setá-lo antes do próximo import.
