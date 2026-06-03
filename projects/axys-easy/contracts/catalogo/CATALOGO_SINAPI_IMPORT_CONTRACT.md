# Catálogo — Contrato de Importação SINAPI

**Status:** Contrato Canônico (v0.1)
**Data:** 2026-06-02
**Fonte-base:** SINAPI — Caixa Econômica Federal (boletim mensal).
**Referência metodológica:** SINAPI — Manual de Metodologias e Conceitos (Caixa/IBGE).
**Regras globais:** ver [CATALOGO_BUSINESS_RULES.md](CATALOGO_BUSINESS_RULES.md).

> Implementação derivada deste contrato: `backend/core/import_cpu/parser_sinapi.py`.

---

## 1. Artefatos da fonte

| Arquivo / aba | Papel no import |
|---|---|
| `SINAPI_Referência` → abas **ISD / ICD / ISE** | **Preço** dos insumos COM preço, por 27 UFs. ISD=sem desoneração, ICD=com desoneração, ISE=sem encargos. |
| `SINAPI_Referência` → abas **CSD / CCD / CSE** | **Custo de referência** das composições por UF/modalidade. Custo `0` = **SEM CUSTO** (sentinela), não zero real. Código é fórmula `HYPERLINK` (vem 0 em `data_only`). |
| `SINAPI_Referência` → aba **Analítico** | **Estrutura** das composições (item, coeficiente, situação declarada) e **universo real de insumos** (inclui os SEM PREÇO). Código real das composições. |
| `SINAPI_familias_e_coeficientes` | Família homogênea: representativo (origem `C`) × representados (origem `CR`) + coeficientes. (Não usado para precificar — preço já vem derivado.) |
| `SINAPI_Manutenções` | Changelog mensal entre edições (criação/desativação/alteração). Insumo e composição. Futuro: alimenta histórico. |

---

## 2. Universo de insumos é BIPARTIDO (regra crítica)

As abas de preço **só listam insumos COM preço**. Insumos **SEM PREÇO existem apenas dentro do Analítico** (nunca nas abas de preço). Parsear só as abas **perde** esses insumos → FKs órfãs ao importar composições.

> Universo real = (insumos das abas de preço) ∪ (insumos órfãos do Analítico).

---

## 3. Hierarquia/ordem de import (obrigatória)

1. **Identidade** — ler **ISE** (universo de identidade = ISD/ICD; só MO muda preço entre abas). Popular `catalogo.insumos` com classificação **nativa** → `ins_ti_origem='FONTE'`.
2. **Órfãos** — varrer o **Analítico apenas por linha INSUMO** (descartar COMPOSICAO). Insumo não mapeado na ISE = **novo registro** → fuzzy (§5) → `ins_ti_origem='REGRA'` (ou `NC`).
3. **Preços** — ISD/ICD/ISE → `precos_insumo` (§4).
4. **Composições** — CSD/CCD/CSE (custo de referência) + Analítico (estrutura) → `composicoes`, `composicao_itens`, `custos_composicao`.

Sem essa ordem, item de composição não tem insumo onde ancorar.

---

## 4. Preço (`precos_insumo`)

- **27 UFs sempre**, por insumo/edição/modalidade. Ausência de linha = falha/não-processado.
- Valor publicado (inclui `0`) → `pri_valor` exato, situação `COM_PRECO`.
- UF sem coleta → `pri_valor = NULL`, situação `SEM_PRECO` (motivo: sem registro na UF).
- Órfão (sem preço em lugar nenhum) → linhas com `pri_valor = NULL`, situação `SEM_PRECO`.
- **Modalidade**:
  - classificação `MAO DE OBRA` (estrita) → `SD` (ISD) + `CD` (ICD) + `SE` (ISE);
  - **todos os demais, inclusive `ENCARGOS COMPLEMENTARES`** → apenas **`SE`** (1 linha por UF; não duplicar em SD/CD).
  - Justificativa empírica: só `MAO DE OBRA` diverge entre SD/CD/SE; material/equip/serviço/encargos são idênticos nas 3 abas.
- **Origem** (`pri_origem`): `C` (representativo) | `CR` (representado). `AS` **não** entra aqui (é artefato de composição — ver §7).

---

## 5. Classificação dos órfãos — FUZZY

- Estratégia: durante o import, casar a descrição+unidade do órfão contra **insumos já classificados na mesma edição** (fuzzy matching).
- Match suficientemente confiável → herda o `ins_ti_id`; `ins_ti_origem='REGRA'`.
- Sem confiança mínima → **fallback `NC`**, `ins_ti_origem='REGRA'`. **Não gravar `ins_ti_id NULL`.**
- Premissa aceita: **não há mão de obra órfã** no SINAPI (MO segue sindicatos/CCT, anual) — erro de classificação aqui não quebra a app.
- Curadoria posterior (tela) pode promover `REGRA`/`NC` → `MANUAL`.
- Precedência de reimport: **FONTE > MANUAL > REGRA** (ver regras globais §2.2).

---

## 6. Composição, situação e custo

- **Item** (`composicao_itens`): tipo `INSUMO` ou `COMPOSICAO`, com coeficiente. Origem dos itens = aba **Analítico**.
- **Situação declarada** (Analítico) é guardada para **auditoria** (modelagem de `ci_sit_id`/`cmp_sit_id` será fechada antes do parser de composição). A **situação efetiva** é **derivada** pela app.
- **SEM CUSTO** ⟺ composição contém insumo SEM PREÇO ou subcomposição SEM CUSTO (propaga na árvore).
- **Custo de referência** (CSD/CCD/CSE): `custo = 0` = **SEM CUSTO → gravar `NULL`** em `cc_custo_fonte` (não 0). Situação autoritativa = Analítico.
- Aferição (`AF_`) é ortogonal a ter custo (composições de MO/encargos não têm `AF_` e ainda assim saem no boletim).

---

## 7. %AS (Atribuído SP)

Artefato de **composição** (não de preço de insumo). Montagem por UF: preço de insumo `NULL` → usa SP; SP `NULL` → sem custo. `%AS_item` = 100% se substituído; `%AS_CPU` = Σ(itens AS)/total. Persistido em `custos_composicao.cc_pct_sp`.

---

## 8. Estado de implementação

| Item | Estado |
|---|---|
| Schema fundação (situacoes, NC, ins_ti_id NOT NULL, pri_sit_id) | **Aplicado** (2026-06-02) |
| `ci_sit_id` / `cmp_sit_id` (situação declarada por FK) | **Deferido** — reavaliar natureza do item antes do parser de composição |
| Parser SINAPI redesenhado (identidade → órfãos → preços → composições) | **Pendente** |
| Import de composições + custos + %AS | **Pendente** |
| Import de Manutenções → histórico | **Pendente** |
