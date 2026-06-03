# Catálogo — Regras de Negócio (Contrato Canônico)

**Status:** Contrato Canônico (v0.1)
**Data:** 2026-06-02
**Escopo:** schema `catalogo` (insumos, preços, composições, custos, situações, tipos).
**Princípio de governança:** Contrato governa · Schema suporta · Código implementa · Tela opera.

> Nenhuma regra de negócio relevante pode existir apenas em parser, schema, controller, service ou tela. Este documento é a fonte canônica. Código e SQL referenciam-no no topo.

Contratos irmãos:
[CATALOGO_SINAPI_IMPORT_CONTRACT.md](CATALOGO_SINAPI_IMPORT_CONTRACT.md) ·
[CATALOGO_CDHU_IMPORT_CONTRACT.md](CATALOGO_CDHU_IMPORT_CONTRACT.md) ·
[CATALOGO_FONTES.md](CATALOGO_FONTES.md) ·
[CATALOGO_EDICOES.md](CATALOGO_EDICOES.md)

---

## 1. Conceitos fundamentais

| Conceito | Definição canônica |
|---|---|
| **Insumo** | Identidade do que o insumo É (código, descrição, unidade, tipo), sem preço. Mutável — "identidade vigente", upsert por reimport. |
| **Preço** | Valor do **insumo** por UF/edição/modalidade. Insumo tem PREÇO (não custo). |
| **Composição (CPU)** | Conjunto de itens (insumos e/ou subcomposições) com coeficientes, p/ 1 unidade de serviço. Composição tem CUSTO. Versionada por edição (imutável). |
| **Item de composição** | Linha filha: tipo `INSUMO` ou `COMPOSICAO` (subcomposição/auxiliar). |
| **Composição auxiliar** | Composição empregada como item de outra (ex.: argamassa). |
| **Edição** | Recorte temporal/versão da fonte. Preços, composições e custos são **imutáveis por edição**; insumos são identidade vigente. |
| **Situação** | Estado declarado pela fonte (auditoria), via lookup `catalogo.situacoes`. Domínios: `INSUMO`, `COMPOSICAO`. |

---

## 2. Classificação de insumos

- **Todo insumo é classificado** — `catalogo.insumos.ins_ti_id` é **NOT NULL**.
- Tipos (`catalogo.tipos_insumo`): `MO`, `EQUIP_AQ`, `EQUIP_LOC`, `MAT`, `SERV`, `ESP`, `NC`.
- Fonte da classificação por origem (`ins_ti_origem`):
  - **`FONTE`** — classificação nativa confiável da fonte-base (ex.: classificação SINAPI);
  - **`REGRA`** — inferida pela app: léxico (CDHU) ou fuzzy (órfão SINAPI);
  - **`MANUAL`** — curadoria humana (tela), nunca por parser.

### 2.1 `NC` — Não Classificado (fallback controlado)
- `NC` **não é categoria técnica real** da fonte. É fallback técnico de curadoria.
- Existe para permitir **import completo sem abortar** quando regra/fuzzy não atinge confiança mínima, preservando `ins_ti_id NOT NULL`.
- Insumo `NC` **entra em fila de curadoria** e **não deve alimentar histogramas gerenciais** como tipo técnico normal.

### 2.2 Precedência no reimport — **FONTE > MANUAL > REGRA**
Regra operacional ao reencontrar um insumo:
1. Se a fonte trouxer classificação nativa confiável → prevalece e grava `ins_ti_id` + `ins_ti_origem='FONTE'`, **mesmo que antes estivesse `MANUAL`**.
2. Se a fonte **não** classificar:
   - registro `MANUAL` → **mantém** a classificação manual (regra não sobrescreve);
   - registro `REGRA` ou `NC` → **reaplica** regra/fuzzy (descrição/unidade podem ter mudado);
   - fuzzy sem confiança → mantém ou aplica `NC`.

`MANUAL` **não é absoluto** — só prevalece quando não há classificação de fonte. A prevalência é **garantida pelo parser** (no `ON CONFLICT`), não pelo banco. Campos cadastrais (descrição/unidade) são **sempre** atualizados no reimport.

---

## 3. Preço (insumo)

- `pri_valor` recebe o valor publicado **exatamente, inclusive `0`**. Zero **nunca** é inferido como "sem preço".
- Se a fonte **não** publicou preço para a UF → `pri_valor = NULL`; o **motivo** fica na situação (FK), nunca solto.
- **Toda UF da edição tem linha** para cada insumo (SINAPI = 27 UFs; CDHU = UF SP). **Ausência de linha = falha de processamento / não importado — NUNCA "sem preço".**
- Situação do preço (`pri_sit_id` → `situacoes` domínio `INSUMO`): `COM_PRECO` | `SEM_PRECO`.
- Coerência **valor × situação** é contrato do parser — **não há trigger**.

### 3.1 Modalidade (encargos/desoneração)
Encargos sociais incidem **só sobre mão de obra**. Por isso:
- **não-MO** (material, equipamento, serviço, **e encargos complementares**) → sempre **`SE`** (sem encargos); **não duplicar** em SD/CD;
- **`MAO DE OBRA` (estrita)** → `SD`/`CD`/`SE` conforme a fonte publica;
- fonte que não distingue modalidade (ex.: **CDHU**) → **`SE`** para tudo.

---

## 4. Composição e custo

- **Custo da composição é montado pela app** a partir dos preços de insumo na UF/modalidade — não é "lido cru" da fonte como verdade de cálculo (a fonte é referência/conferência).
- **SEM CUSTO** ⟺ a composição contém **algum insumo SEM PREÇO** ou **alguma subcomposição SEM CUSTO**. A indisponibilidade **propaga pela árvore**.
- **Aferição** (`AF_MM/AAAA`) é atividade técnica (dimensionar coeficientes) **ortogonal** a ter custo. Composição pode ser aferida e sem custo.
- Situação da composição (domínio `COMPOSICAO`): `COM_CUSTO` | `SEM_CUSTO` | `SUSPENSO` | `EM_ESTUDO`.
- Custo de referência da fonte é guardado lado a lado com o calculado (`custos_composicao.cc_custo_fonte` × `cc_custo_calculado`) — divergência é **conferência/alerta**, nunca mascarada e **sem trigger**.

---

## 5. %AS (Atribuído São Paulo)

`%AS` é **artefato da composição**, não origem de preço de insumo (origens de preço seguem só `C`/`CR`). Na montagem da composição por UF:
1. insumo com preço `NULL` na UF → **adota preço de SP**;
2. se SP também é `NULL` → item fica sem preço → composição **sem custo**;
3. **%AS do item** = 100% quando substituído por SP; **%AS da CPU** = Σ(valor dos itens AS) / valor total.

Persistido em `custos_composicao.cc_pct_sp`.

---

## 6. Situação como lookup

- `catalogo.situacoes` — lookup por **domínio** (`INSUMO`, `COMPOSICAO`); situações são **FK**, não texto repetido.
- Não há domínio `PRECO` (situação de preço É do insumo) nem `ITEM` (item é só insumo ou composição dentro de composição).
- A situação guardada é a **declarada pela fonte** (auditoria). A **situação efetiva** (para cálculo) é **derivada em runtime** pela app — não persistida, não confiada cegamente.
- Integridade de domínio garantida por **FK composta** `(sit_id, dominio)` — sem trigger.

> **Estado de implementação (schema atual, 2026-06-03):** apenas **`precos_insumo.pri_sit_id`** (domínio `INSUMO`) está implementado. As situações **declaradas do lado composição** (`composicao_itens.ci_sit_id` e `composicoes.cmp_sit_id`) estão **conceitualmente previstas, porém DEFERIDAS** — a natureza do item (INSUMO vs COMPOSICAO) e a forma de guardar a situação declarada serão decididas **antes do parser de composição**. Hoje `composicoes`/`composicao_itens` ainda usam o campo de situação textual herdado, a ser refatorado nessa frente.

---

## 7. Política de reimport

- **Insumos**: upsert (identidade vigente). Classificação segue a precedência da §2.2; cadastrais sempre atualizam.
- **Preços / composições / itens / custos**: **imutáveis por edição** — reimport da mesma (chave, edição) é idempotente.
- Situação declarada pela fonte é regravada; situação efetiva é recomputada.

---

## 8. Fronteira Banco × App

| Banco garante | App/importador garante |
|---|---|
| FK válida; domínio válido da situação (FK composta) | Coerência valor × situação |
| `ins_ti_id NOT NULL` | Aplicação da regra de fonte e do fuzzy |
| Unicidade e integridade relacional | Precedência FONTE > MANUAL > REGRA |
| Domínio de `ins_ti_origem`, modalidade, origem | 27 UFs preenchidas por insumo/edição |
| — | Custo e situação **efetiva** das composições |

**Sem triggers.** Regra de coerência é responsabilidade do parser/importador.
