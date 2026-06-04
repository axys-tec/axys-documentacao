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
| `SINAPI_Referência` → aba **ISE** | **Preço pelado** (sem encargos) dos insumos COM preço, por 27 UFs — **única aba de preço gravada** (`insumos_preco` é SE-only). |
| `SINAPI_Referência` → **cabeçalhos de ISD / ICD** | **Leis sociais** (LS Horista/Mensalista por UF) → `edicoes_leis_sociais` (`SD`/`CD`). **Corpo não importado** — SD/CD são derivados. |
| `SINAPI_Referência` → abas **CSD / CCD / CSE** | **Custo de referência** das composições por UF/modalidade. Custo `0` = **R$0,00 REAL** (ex.: equipamento de depreciação ínfima), **não** sem custo. Sem custo vem da **Situação do Analítico**, nunca do valor 0. Código é fórmula `HYPERLINK` (vem 0 em `data_only`) → casa por ordem com o Analítico. |
| `SINAPI_Referência` → aba **Analítico** | **Estrutura** das composições (item, coeficiente, situação declarada) e **universo real de insumos** (inclui os SEM PREÇO). Código real das composições. |
| `SINAPI_familias_e_coeficientes` | Família homogênea: representativo (origem `C`) × representados (origem `CR`) + coeficientes. (Não usado para precificar — preço já vem derivado.) |
| `SINAPI_Manutenções` | Changelog mensal entre edições (criação/desativação/alteração), insumo e composição → `catalogo.sinapi_manutencoes` (**SINAPI-Diff**). Reconciliado com o **Axys-DIFF** (série histórica computada pela Axys edição-a-edição) — ver [CATALOGO_BUSINESS_RULES.md §9](CATALOGO_BUSINESS_RULES.md). |

---

## 2. Universo de insumos é BIPARTIDO (regra crítica)

As abas de preço **só listam insumos COM preço**. Insumos **SEM PREÇO existem apenas dentro do Analítico** (nunca nas abas de preço). Parsear só as abas **perde** esses insumos → FKs órfãs ao importar composições.

> Universo real = (insumos das abas de preço) ∪ (insumos órfãos do Analítico).

---

## 3. Hierarquia/ordem de import (obrigatória)

1. **Identidade** — ler **ISE** (universo de identidade = ISD/ICD; só MO muda preço entre abas). Popular `catalogo.insumos` com classificação **nativa** → `ins_ti_origem='FONTE'`.
2. **Órfãos** — varrer o **Analítico apenas por linha INSUMO** (descartar COMPOSICAO). Insumo não mapeado na ISE = **novo registro** → fuzzy (§5) → `ins_ti_origem='REGRA'` (ou `NC`).
3. **Preços** — corpo da **ISE** → `insumos_preco` (SE-only); cabeçalhos de **ISD/ICD** → `edicoes_leis_sociais` (§4).
4. **Composições** — CSD/CCD/CSE (custo de referência) + Analítico (estrutura) → `composicoes`, `composicoes_itens`, `composicoes_custo`. **Conferência** calculado×fonte (BUSINESS_RULES §4.1) — **gate de convergência** que valida o modelo SE-only (esperado: SINAPI converge ao centavo).

Sem essa ordem, item de composição não tem insumo onde ancorar.

---

## 4. Preço (`insumos_preco`) — **SE-only** (pelado + LS)

Regra canônica em [CATALOGO_BUSINESS_RULES.md §3.1–3.3](CATALOGO_BUSINESS_RULES.md). Resumo SINAPI:

- **Grava só o pelado** (`SE`), 27 UFs por insumo/edição. Lê o **corpo da aba `ISE`** (sem encargos); **NÃO grava** SD/CD como preço de insumo — eles são **derivados** (`trunc(pelado×(1+LS/100),2)`).
- Valor publicado (inclui `0`) → `pri_valor` exato, situação `COM_PRECO`. UF sem coleta / órfão → `pri_valor = NULL`, `SEM_PRECO`. Ausência de linha = falha/não-processado.
- **LS dos cabeçalhos:** das abas **ISD** e **ICD** lê-se **apenas o cabeçalho** (LS Horista/Mensalista por UF) → `edicoes_leis_sociais` (`SD` e `CD`). **O corpo de ISD/ICD não é importado** (reduz dados; derivamos).
- **Origem** (`pri_origem`): `C` (representativo) | `CR` (representado). `AS` **não** entra aqui (artefato de composição — §7).
- **Horista × mensalista** são insumos distintos (códigos próprios); a CPU referencia um deles e o cálculo aplica a LS correspondente pela unidade (`H`/`MES`). As CPUs-padrão SINAPI usam a versão **horista**.

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

- **Item** (`composicoes_itens`): tipo `INSUMO` ou `COMPOSICAO`, com coeficiente. Origem dos itens = aba **Analítico**.
- **Situação declarada** (Analítico) é guardada para **auditoria** (modelagem de `ci_sit_id`/`cmp_sit_id` será fechada antes do parser de composição). A **situação efetiva** é **derivada** pela app.
- **SEM CUSTO** ⟺ composição contém insumo SEM PREÇO ou subcomposição SEM CUSTO (propaga na árvore).
- **Custo de referência** (CSD/CCD/**CSE**): `cc_custo_fonte` = valor da aba **COMO ESTÁ** — `0` é **R$0,00 real**, gravado como 0 (NÃO vira NULL). **Sem custo vem da Situação do Analítico** (`cmp_situacao='SEM CUSTO'` → `cc_custo_fonte = NULL`), nunca do valor 0. (Correção 2026-06-03.) Célula vazia (sem coleta na UF) → NULL.
- **Três modalidades** em `composicoes_custo`: `SD` (CSD), `CD` (CCD) e **`SE`** (CSE = PELADO, sem encargos). O `SE` é gravado p/ consulta (telas leem direto, não recomputam) e o calculado do SE (Σ pelado×coef, **sem LS**, trunc) confere contra a CSE — fechando a doutrina SE-only no nível de composição. Ver [BUSINESS_RULES §4.1](CATALOGO_BUSINESS_RULES.md).
- **Fidelidade canônica:** grava-se TODOS os itens do Analítico, inclusive **coef 0** (`CHECK ci_coef >= 0`) — a fonte publica coef 0 em CPU incompleta; não se julga, repete-se. Insumo SEM PREÇO coef-0 propaga SEM CUSTO (ex.: 104871). Ver [BUSINESS_RULES §4](CATALOGO_BUSINESS_RULES.md).
- Aferição (`AF_`) é ortogonal a ter custo (composições de MO/encargos não têm `AF_` e ainda assim saem no boletim).

---

## 7. %AS (Atribuído SP)

Artefato de **composição** (não de preço de insumo). Montagem por UF, insumo sem preço `SE` na UF:
- **Representado (`CR`) com coeficiente de família** → `trunc( preço_SP × coef_UF/coef_SP, 2 )` (≡ `representativo_SP × coef_UF`), coef da tabela `insumos_familia` (arquivo `SINAPI_familias_e_coeficientes`, aba `Coeficientes`, por edição). MAT/EQUIP/SERV: coef igual entre UFs (ratio 1 → SP plano); efeito real só em **MO**.
- **Sem coef** → SP plano. SP `NULL` → sem custo.
- `%AS_item` = 100% se substituído; `%AS_CPU` = Σ(itens AS)/total → `composicoes_custo.cc_pct_sp`.

> **Correção 2026-06-04:** a premissa "%AS = SP plano" estava errada — ignorava o coef da UF e subcontava MO (−1% a −4% em UFs com buraco). O atribuído é preço → **truncado a 2 casas**. Prova e detalhe em [BUSINESS_RULES §5](CATALOGO_BUSINESS_RULES.md).

---

## 8. Estado de implementação

| Item | Estado |
|---|---|
| Schema fundação (situacoes, NC, ins_ti_id NOT NULL, pri_sit_id) | **Aplicado** (2026-06-02) |
| Doutrina SE-only (pelado + LS derivada) + `edicoes_leis_sociais` | **Implementado** (2026-06-03) |
| Tipo `ENC_COMP` (encargos complementares, sem LS) + import bloqueia classif sem tipo | **Implementado** (2026-06-03) |
| Grupo-guarda-chuva `GERAL` (SINAPI não publica grupo) | **Implementado** (2026-06-03) |
| Parser SINAPI (ISE pelado+classif FONTE → órfãos NC → LS CSD/CCD → composições/subcomps → custos) | **Implementado** (2026-06-03) — `parser_sinapi.py`, runner `import_sinapi.py` |
| **GATE 3.2 — convergência (método TRUNC)** | **CRAVADO** (2026-06-03): 445.122 células IGUAL, 0 divergência (27 UF × SD/CD) |
| **`%AS` por coeficiente de família** (`insumos_familia` + `parse_familia`; trunc 2 casas) | **Implementado** (2026-06-04) — corrige premissa "SP plano"; 08-24 RELEVANTE 68→0, ARRED→2 (MT) |
| **Modalidade `SE` em `composicoes_custo`** (lê CSE; pelado sem LS; conferência) | **Implementado** (2026-06-04) |
| **Fidelidade coef-0** (`CHECK ci_coef>=0`; não descarta; SEM PREÇO propaga) | **Implementado** (2026-06-04) |
| **Diff/ciclo de vida** (contra estado vigente do banco; situação não é gatilho) | **Implementado** (2026-06-04) — `parser_cdhu` genérico; 08-24→04-26 validado |
| `ci_sit_id` / `cmp_sit_id` (situação declarada por FK) | **Deferido** — hoje usa texto `ci_situacao`/`cmp_situacao` (declarado do Analítico) |
| Fuzzy de classificação dos órfãos (hoje NC) | **Pendente** |
| Manutenções (SINAPI-Diff) + Axys-DIFF | **Pendente** (Fase 3.4) |
| Mapa horista↔mensalista (`composicoes_mapeamento_mdo`) | **Pendente** (Fase 3.5) |
