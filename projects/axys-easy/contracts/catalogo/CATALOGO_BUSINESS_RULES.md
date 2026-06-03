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
- Tipos (`catalogo.insumos_tipo`): `MO`, `EQUIP_AQ`, `EQUIP_LOC`, `MAT`, `SERV`, `ESP`, `NC`.
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

### 3.1 Armazenamento "pelado + LS" — `insumos_preco` é **SE-only**
Encargos sociais incidem **só sobre mão de obra**, e o preço "com encargos" publicado pelas fontes **É** `pelado × (1 + LS%)` truncado. Logo, **não se armazena SD/CD** como preço de insumo — armazena-se só o **pelado (SE)** e derivam-se SD/CD no cálculo.

- `insumos_preco` grava **apenas modalidade `SE`** para **todo** insumo (MO e não-MO), por UF/edição. (`pri_modalidade` é mantida = `'SE'`; SD/CD permanecem como modalidades **válidas no cadastro/lookup** para visualização e processamento dinâmico, mas **não** como linhas de preço de insumo.)
- **Não-MO**: não tem encargo → SE = SD = CD; 1 linha (SE).
- **MO**: grava o pelado (SE); SD/CD são **derivados** (§3.2).
- Fonte que não distingue modalidade no insumo (ex.: **CDHU**) → também SE.

### 3.2 Derivação SD/CD e arredondamento (ESPECÍFICO DA FONTE)
Para insumo de **mão de obra**: `preco = ARRED( pelado × (1 + LS%/100), 2 )`, com `LS%` de `edicoes_leis_sociais` por **(edição, UF, modalidade)** e pela **unidade** do insumo (`H` → horista; `MES` → mensalista). O método de arredondamento `ARRED` é **o da fonte** — escolhido para casar **ao centavo** com o publicado:

- **SINAPI — preço de insumo SD/CD: `trunc(2)`.** Prova (SP 08/2024): 6114 SE=10,45 → SD `trunc(10,45×2,1554)=22,52`, CD `19,41`; 40912 SE=2.300,88 → SD `trunc(2300,88×1,7146)=3.945,08` (round daria 3.945,09 → seria errado).
- **CDHU — custo de composição: `round half-up (2)` em DUAS passagens** (decisão 2026-06-03):
  `unit_mo = round( (1 + LS%/100) × pelado, 2 )` e `custo_cpu = Σ round( unit × coef, 2 )`.
  Converge **100% ao centavo** com a fonte (CDHU 201: 3560/3560). Truncar dava viés sistemático negativo (até −R$12,91 em CPUs grandes); a CDHU arredonda.

> O método é **declarado por fonte** no contrato de import respectivo. SINAPI (custo de composição CSD/CCD) será confirmado na Fase 3. Política conservadora de orçamento (se houver) é da camada **ativo** (§3.4), não do catálogo.

### 3.3 Leis sociais (`edicoes_leis_sociais`)
- LS por **(edição, UF, modalidade ∈ {SD, CD})** — **não** se grava `SE` (SE = 0% implícito). Guarda `els_mensalista` e `els_horista` como percentual (`14,2`), dividido por 100 no cálculo.
- **Fonte das LS:** SINAPI = cabeçalhos dos arquivos SD e CD (LS por UF, horista/mensalista); CDHU = cabeçalho do arquivo de serviços (um único % horista; mensalista NULL).
- **Sanidade no import:** LS real é alta (>100% típico); valor que chegue como fração (~1,28) deve ser normalizado/abortado.

### 3.4 Fronteira catálogo × orçamento
- No **catálogo**, LS é a **oficial da edição** (imutável); `composicoes_custo.cc_custo_calculado` é computado 1× no import.
- No **orçamento** (módulo ativo), o usuário pode usar LS customizada / base mensalista → computado **ao vivo** sobre o SE. Nada a "reprocessar" no catálogo; cache de orçamento invalida ao mudar LS.
- **Horista ↔ mensalista** não é linear (a CPU mensalista tem itens diferentes, não é `horista × 220`) → resolve-se por **mapeamento de CPUs** (`composicoes_mapeamento_mdo`, por edição), consumido no orçamento.

---

## 4. Composição e custo

- **Custo da composição é montado pela app** a partir dos preços de insumo na UF/modalidade — não é "lido cru" da fonte como verdade de cálculo (a fonte é referência/conferência).
- **SEM CUSTO** ⟺ a composição contém **algum insumo SEM PREÇO** ou **alguma subcomposição SEM CUSTO**. A indisponibilidade **propaga pela árvore**.
- **Aferição** (`AF_MM/AAAA`) é atividade técnica (dimensionar coeficientes) **ortogonal** a ter custo. Composição pode ser aferida e sem custo.
- Situação da composição (domínio `COMPOSICAO`): `COM_CUSTO` | `SEM_CUSTO` | `SUSPENSO` | `EM_ESTUDO`.
- Custo de referência da fonte é guardado lado a lado com o calculado (`composicoes_custo.cc_custo_fonte` × `cc_custo_calculado`) — divergência é **conferência/alerta**, nunca mascarada e **sem trigger**.

### 4.1 Motor de conferência (calculado × fonte)
- Logo após o import, para cada (composição, UF, modalidade) calcula-se `cc_custo_calculado` (montagem §3.2/§3.4 com a LS **oficial** da edição) e compara-se com `cc_custo_fonte` (publicado).
- **Limiar:** `|diferença|` ≤ **0,5%** (ou ≤ R$0,01) → `cc_status_conferencia = DIVERGENTE_ARREDONDAMENTO`; acima → `DIVERGENTE_RELEVANTE`. Esperado: **SINAPI converge**; **CDHU diverge** (sob controle, classificado).

### 4.2 Custo × alerta — `composicoes_custo` é a casa única dos números
- Os **números** (`cc_custo_fonte`, `cc_custo_calculado`, diferença, `cc_status_conferencia`, `cc_pct_sp`) vivem **só** em `composicoes_custo` (1 linha por cmp/uf/modalidade). É o "headline" do alerta.
- `composicoes_custo_alerta` guarda **apenas a CAUSA** (tipo do alerta + referência do item culpado + observação), **sem repetir custo**, e **só para casos relevantes** (divergência relevante / sem custo). A causa item-a-item é derivável; persiste-se o que merece fila de revisão.

---

## 5. %AS (Atribuído São Paulo)

`%AS` é **artefato da composição**, não origem de preço de insumo (origens de preço seguem só `C`/`CR`). Na montagem da composição por UF:
1. insumo com preço `NULL` na UF → **adota preço de SP**;
2. se SP também é `NULL` → item fica sem preço → composição **sem custo**;
3. **%AS do item** = 100% quando substituído por SP; **%AS da CPU** = Σ(valor dos itens AS) / valor total.

Persistido em `composicoes_custo.cc_pct_sp`.

---

## 6. Situação como lookup

- `catalogo.situacoes` — lookup por **domínio** (`INSUMO`, `COMPOSICAO`); situações são **FK**, não texto repetido.
- Não há domínio `PRECO` (situação de preço É do insumo) nem `ITEM` (item é só insumo ou composição dentro de composição).
- A situação guardada é a **declarada pela fonte** (auditoria). A **situação efetiva** (para cálculo) é **derivada em runtime** pela app — não persistida, não confiada cegamente.
- Integridade de domínio garantida por **FK composta** `(sit_id, dominio)` — sem trigger.

> **Estado de implementação (schema atual, 2026-06-03):** apenas **`insumos_preco.pri_sit_id`** (domínio `INSUMO`) está implementado. As situações **declaradas do lado composição** (`composicoes_itens.ci_sit_id` e `composicoes.cmp_sit_id`) estão **conceitualmente previstas, porém DEFERIDAS** — a natureza do item (INSUMO vs COMPOSICAO) e a forma de guardar a situação declarada serão decididas **antes do parser de composição**. Hoje `composicoes`/`composicoes_itens` ainda usam o campo de situação textual herdado, a ser refatorado nessa frente.

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

---

## 9. Época / Diff (evolução entre edições)

- **No import**, após parsear e **antes de gravar**: "este registro já existe?" → se **sim**, computa **diff cadastral** (descrição/unidade) e grava em `*_historico`; se **não**, grava e pula auditoria.
- **Preço nunca vai para histórico** — a série temporal vive em `insumos_preco` por edição; composições são versionadas por edição (`cmp_edi_id`).
- Insumos = identidade vigente (upsert; diff vs. o registro atual). Composições = versionadas por edição (diff vs. a versão da edição anterior).
- **Dois diffs no SINAPI:** **SINAPI-Diff** (`catalogo.sinapi_manutencoes`, changelog publicado) e **Axys-DIFF** (série histórica computada pela Axys edição-a-edição). A app apresenta ambos e **reconcilia** ("a manutenção cobre tudo que o Axys-DIFF achou?"). CDHU não publica changelog → só Axys-DIFF.
- **Sequenciamento:** o diff é estágio **posterior** ao import "puro" funcionar (ver `PLANO_IMPORT_CATALOGO.md`, Fases 2.2 e 3.4).
