# Plano Canônico — Import do Catálogo (CDHU e SINAPI)

**Status:** Fase 0 em andamento · demais fases planejadas
**Data:** 2026-06-03
**Governança:** Contrato governa · Schema suporta · Código implementa · Tela opera.
**Ponteiro de governança:** contratos em `docs/projects/axys-easy/.../contracts/catalogo` (CATALOGO_BUSINESS_RULES, CATALOGO_CDHU_IMPORT, CATALOGO_SINAPI_IMPORT, CATALOGO_EDICOES e contratos novos listados na Fase 0). Código e SQL referenciam o contrato no topo.

> Este documento consolida e substitui os `next_step_map.md` / `next_step_app.md` (raiz e `docs/.../next-steps/`). Aqueles arquivos estão desatualizados — o que sobrevive deles (estratégia de parser, dependências de layer, localização dos arquivos/abas, resolução em dois passos da SINAPI, máquina de estados CDHU) foi incorporado aqui; o que conflita com as decisões abaixo (preço gravado como SD, classificação CDHU por prefixo, "só ISD/ICD") foi descartado.

---

## Tabela-resumo das fases

| Fase | Tema | Status |
|---|---|---|
| 0 | Contratos (regra de negócio, sem código) | Em andamento |
| 1 | Schema + rebuild | Planejado |
| 2 | Parser CDHU (o simples primeiro) | Planejado |
| 3 | SINAPI (dois estágios + convergência) | Planejado |
| 4 | Imports de cadernos (PDF/R2) | Planejado |
| 5 | UI — modal de import na tela `/edicoes` | Planejado |
| 6 | Templates de import para outras fontes + testes | Planejado |
| 7 | Catálogo Público Colaborativo (outros tenants) | Planejado |
| 8 | Módulo ATIVO (orçamento) | Planejado |

**Escopo:** até a Fase 6 tudo é administração da Axys — nada é de cliente. A Fase 7 fecha a parte preliminar da app. A Fase 8 (orçamento) não deve ser tocada agora.

---

## Decisões fechadas (doutrina)

Estas decisões estão **fechadas**. Este documento as registra; não reabre discussão.

### D1 — Armazenamento "pelado + LS"
`catalogo.insumos_preco` guarda **apenas a modalidade SE** (preço pelado) para **todos** os insumos — mão de obra (MO) e não-MO. SD e CD **não** são gravados como preço de insumo: são **derivados** no cálculo via

```
preco_modalidade = trunc(pelado * (1 + LS%), 2)
```

A coluna `pri_modalidade` é **mantida** e fica sempre `'SE'`. CD e SD permanecem como **modalidades válidas no cadastro** (lookup), para visualização e processamento dinâmico ao usuário. O **unique efetivo** de `insumos_preco` passa a ser **(ins, edi, uf)**.

### D2 — Prova de convergência (evidência)
Registro de evidência (SP, SINAPI 08/2024) de que a derivação é a fórmula oficial e não perde nada:

| Insumo | Unidade | SE (pelado) | Derivado | Publicado |
|---|---|---|---|---|
| 6114 ajudante armador | horista | 10,45 | SD = trunc(10,45 × (1+1,1554)) = 22,52 | 22,52 |
| 6114 ajudante armador | horista | 10,45 | CD = trunc(10,45 × (1+0,8580)) = 19,41 | 19,41 |
| 40912 (mensalista) | mensalista | 2300,88 | SD = trunc(× 1,7146) = 3945,08 | 3945,08 |
| 40912 (mensalista) | mensalista | 2300,88 | CD = trunc(× 1,4774) = 3399,32 | 3399,32 |

Cross-check 1 mês = 220 h: `trunc(2300,88 / 220) = 10,45` = horista SE. **Conclusão:** a derivação SE→SD/CD é a fórmula oficial.

### D3 — Leis sociais
Nova tabela conceitual `edicoes_leis_sociais` por **(edição, UF, modalidade)**. Modalidade ∈ {SD, CD} — **não grava SE** (SE = 0 implícito). Guarda LS de **mensalista** e de **horista** como percentual numérico no padrão de divulgação (ex.: `14,2`), dividido por 100 no cálculo.

| Fonte | Origem da LS |
|---|---|
| SINAPI | Cabeçalhos dos arquivos SD e CD (LS por UF, horista e mensalista) |
| CDHU | Cabeçalho do arquivo de serviços (um único % horista; mensalista NULL) |

**Check de sanidade no import:** a LS real é alta (> 100%). Se vier como fração (~1,28), **normalizar ou abortar**.

### D4 — Horista × mensalista
Definido pela **unidade do insumo**: `H` = horista (aplica `els_horista`), `MES` = mensalista (aplica `els_mensalista`). A SINAPI monta CPUs com a versão **horista**; a mensalista existe mas não é usada nas CPUs padrão.

### D5 — Truncamento (orçamento público; evita superfaturamento em escala)
- `trunc(2)` no preço de MO carregado;
- `trunc(2)` por linha (`preco_unit × coef`);
- `trunc(2)` na soma final da CPU.

### D6 — Motor de conferência
Após o import, comparar `custo_calculado` da CPU com `custo_fonte` (publicado):

| Condição | Status |
|---|---|
| `|dif| <= 0,5%` ou `|dif| <= R$ 0,01` | `DIVERGENTE_ARREDONDAMENTO` |
| acima do limiar | `DIVERGENTE_RELEVANTE` |

Esperado: **CDHU diverge** (sob controle), **SINAPI converge**.

### D7 — Custo × alerta (casa única dos números)
`catalogo.composicoes_custo` é a **casa única** dos números, por (cmp, uf, modalidade): `custo_fonte`, `custo_calculado`, `diferença`, `status_conferencia`, `pct_sp`. A antiga `composicoes_alertas_custo` (que **espelhava** custo) é **substituída** por `composicoes_custo_alerta` **enxuta**: registra só a **causa** (`tipo_alerta` + referência do item culpado + observação), **sem repetir custo**, persistida **só** para casos relevantes (divergência relevante / sem custo). A causa item-a-item é derivável; persiste-se o relevante.

### D8 — Mapeamento horista ↔ mensalista
Nova tabela conceitual `composicoes_mapeamento_mdo` por **edição** (CPU horista ↔ CPU mensalista). A conversão **não** é linear (a CPU mensalista tem itens diferentes, não é horista × 220). Populada por **fuzzy pós-import** (par por descrição + unidade ~100%). O **consumo** (montar orçamento mensalista / LS custom) é do **módulo ativo/orçamento**, não do import.

### D9 — Fronteira catálogo × orçamento
- **No catálogo:** LS é a **oficial** da edição (imutável); `composicoes_custo.custo_calculado` é computado **1× no import**.
- **No orçamento:** o usuário pode usar LS customizada / base mensalista — computado **ao vivo** sobre o SE. Nada a "reprocessar" no catálogo. Se cachear no orçamento, invalida ao mudar a LS.

### D10 — Parser de composições CDHU (máquina de estados)
Lê a **coluna A**. Discrimina **primeiro pela estrutura do código**; unidade/coeficiente **corroboram**:

| Padrão do código | Significado |
|---|---|
| `NN` | Grupo |
| `NN.NN` | Subgrupo |
| `NN.NN.NNN` com unidade e **sem** coef (ou coef = 1 espúrio, ignorar) | Composição (header) |
| Código fora desse padrão (insumo `B...` ou subcomposição) **com** unidade **e** coef | Item da composição corrente |

Ao voltar a um dos 3 padrões, **reclassifica**. Grupo/subgrupo vêm **com descrição** no analítico ⇒ o arquivo `subgrupos.xlsx` é **descartado**. Grupo/subgrupo vinculam à **CPU** (`composicoes.cmp_sub_id`), **nunca** ao insumo.

### D11 — Época / diff (estágio separado)
Estágio **separado**, **depois** que o import "puro" funcionar. No import, após parsear e **antes** de gravar: "já existe?" → se sim, faz **diff cadastral** (descrição/unidade) → grava em `*_historico` e grava o registro; se não, grava e pula auditoria. **Preço nunca** vai para histórico (a série vive em `insumos_preco` por edição). Dois diffs na SINAPI:
- **SINAPI-Diff:** manutenções publicadas (`catalogo.sinapi_manutencoes`);
- **Axys-DIFF:** série histórica computada pela Axys edição-a-edição.

A app apresenta **ambos** e reconcilia (a manutenção cobre tudo o que achamos?).

### D12 — Import "tudo de uma vez" (CDHU)
Tela `/edicoes` → seleciona caderno →
- **(a) "importar composições":** modal com **3 Excels obrigatórios** (insumos, composições, serviços). `serviços` = `custo_fonte` + cabeçalho com modalidade / versão / data-base / LS.
- **(b) "importar caderno":** PDFs / R2 — fase própria, depois.

---

## Pré-requisito comum: `catalogo.edicoes`

Nenhum parser cria a edição. Ela é **selecionada ou criada** via tela/serviço **antes** de qualquer import. `edi_fte_id` é o `fte_id` da fonte (CDHU/SINAPI já no seed).

| Fonte | edi_mes_ref | edi_codigo_versao | edi_uf_padrao | Observação |
|---|---|---|---|---|
| CDHU 201 | 2026-02-01 | `'201'` | `'SP'` | Data base; versão = número do boletim |
| SINAPI ABR/2026 | 2026-04-01 | NULL | `'SP'` | Data base = 1º dia do mês de referência |

**Convenção de texto:** todo campo de texto inserido é normalizado para CAIXA ALTA (`.strip().upper()`), salvo exceções anotadas.

---

## Estratégia de parser (incorporada e atualizada)

### CDHU — parser stateful (máquina de estados)
Estrutura hierárquica embutida em um único arquivo de composição; nível determinado pela máquina de estados de **D10**. O arquivo `subgrupos.xlsx` é descartado (grupo/subgrupo já vêm com descrição no analítico).

### SINAPI — parser de contexto repetido + dois passos
No `Analítico`, grupo e código de composição se repetem em cada linha; discrimina pela coluna `Tipo Item` (vazio = header; `INSUMO` / `COMPOSICAO` = item). Composições podem referenciar outras composições:

- **Passo 1 (estrutural):** importa todos os headers e itens. `INSUMO` resolve `ci_ins_id` na hora; `COMPOSICAO` deixa `ci_cmp_filho_id` pendente (a filha pode ainda não existir).
- **Passo 2 (resolução):** resolve os `ci_cmp_filho_id` pendentes por código dentro da edição/fonte.

### Localização dos parsers
```
backend/core/import_cpu/
  base.py            ← interface comum (ImportResult, ImportConfig)
  parser_cdhu.py     ← CDHU (inclui classificar_insumo_cdhu — fonte única)
  parser_sinapi.py   ← SINAPI (referência, analítico, custos, manutenções, cabeçalhos LS)
  parser_template.py ← template genérico (Fase 6)
  service_import.py  ← orquestra, valida dependências, chama parsers
```

### Classificação de insumo CDHU (regra de negócio)
A CDHU **não** publica o tipo. A classificação é por **descrição + unidade** (não por prefixo do código — prefixo descartado), na função `classificar_insumo_cdhu(descricao, unidade)` em `parser_cdhu.py`, **fonte única** (script de apoio importa dela). A SINAPI lê a coluna `Classificação` publicada e faz lookup em `insumos_tipo`.

---

## Fases

### Fase 0 — Contratos (regra de negócio, SEM código)

**Objetivo:** fechar nos contratos toda a doutrina acima, antes de tocar schema/código.

**Entregável:** contratos atualizados/criados em `contracts/catalogo`:
- `CATALOGO_BUSINESS_RULES` — SE-only + derivação SE→SD/CD + truncamento + conferência + limiar + fronteira catálogo×orçamento.
- `CATALOGO_CDHU_IMPORT` — máquina de estados (D10), `subgrupos.xlsx` descartado, LS do arquivo de serviços.
- `CATALOGO_SINAPI_IMPORT` — pelado (SE) + cabeçalhos SD/CD para LS, manutenções, Axys-DIFF × SINAPI-Diff, CPUs horistas.
- `CATALOGO_EDICOES` — fluxo de import modal (a), `edicoes_leis_sociais`.
- Contratos novos: `edicoes_leis_sociais`, `composicoes_custo` / `composicoes_custo_alerta`, `composicoes_mapeamento_mdo`, doutrina de época/diff.

**GATE:**
- [ ] Aprovação do usuário em todos os contratos acima.

---

### Fase 1 — Schema + rebuild

**Objetivo:** alinhar o schema à doutrina dos contratos.

**Entregável (mudanças conceituais — sem DDL aqui):**
- `insumos_preco` **SE-only**: `pri_modalidade` mantida = `'SE'`; unique efetivo **(ins, edi, uf)**.
- `composicoes_alertas_custo` → `composicoes_custo_alerta` **enxuta** (só a causa, sem repetir custo).
- **Nova** `edicoes_leis_sociais` (`els_*`, sem SE, padrão `%14,2`, por edição/UF/modalidade).
- **Nova** `composicoes_mapeamento_mdo` (por edição, H ↔ MES).
- Conferir `composicoes_custo` (custo_fonte + custo_calculado por modalidade + status + diferença + pct_sp).
- Conferir `*_historico` (suportam diff cadastral descrição/unidade).

**GATE:**
- [ ] `rebuild_db.py` roda limpo.
- [ ] Schema bate com os contratos da Fase 0.

---

### Fase 2 — Parser CDHU (o simples primeiro)

#### 2.1 — Primeiro import + check
**Objetivo:** importar uma edição CDHU completa do modal (a) — 3 Excels.

**Entregável:**
- Insumos + preço **SE** (truncado).
- Composições + itens (máquina de estados D10); grupos/subgrupos **derivados** do analítico.
- `edicoes_leis_sociais` extraída do cabeçalho do arquivo de serviços (horista; mensalista NULL).
- `composicoes_custo` com `custo_fonte` + `custo_calculado` + `status_conferencia` + diferença.
- `composicoes_custo_alerta` apenas para casos **relevantes**.

**GATE:**
- [ ] FKs íntegras.
- [ ] Universo de insumos/composições completo.
- [ ] Relatório de convergência gerado (CDHU pode divergir, sob controle).

#### 2.2 — Segundo import + diff cadastral
**Objetivo:** importar uma segunda edição CDHU exercitando o diff de época (D11).

**Entregável:** 2 catálogos no banco + diff cadastral (descrição/unidade) → `*_historico` + check de integridade.

**GATE:**
- [ ] Diff não corrompe o 1º import.
- [ ] Reimport da mesma edição é idempotente.

---

### Fase 3 — SINAPI (dois estágios)

#### 3.1 — Primeiro import
**Objetivo:** importar uma edição SINAPI completa no modelo pelado.

**Entregável:**
- Corpo pelado → **SE** (truncado).
- Cabeçalhos SD/CD → `edicoes_leis_sociais` (horista e mensalista, por UF).
- Composições + itens (contexto repetido + dois passos).
- CSD / serviços → `custo_fonte` em `composicoes_custo`.

**GATE:**
- [ ] FKs íntegras e universo completo (1º import puro).

#### 3.2 — Convergência (GATE DECISIVO do SE-only)
**Objetivo:** provar que derivar SD/CD do universo SE reproduz os corpos publicados.

**Entregável:** derivar SD/CD do universo (SE × LS, truncado) e comparar com os corpos SD/CD publicados; recompor CPUs e comparar com CSD.

**GATE:**
- [ ] Insumos: ~0 mismatch entre derivado e publicado (SD e CD).
- [ ] Composições: CPUs vs CSD batem "com maestria".

#### 3.3 — Drop & rebuild
**Objetivo:** limpar para o ciclo definitivo após validada a convergência.

**GATE:**
- [ ] Banco limpo e reconstruído sem resíduo.

#### 3.4 — Segundo import + diffs
**Objetivo:** segunda edição SINAPI com época/diff e manutenções.

**Entregável:** 2 catálogos + diff cadastral + check + `sinapi_manutencoes` populada + reconciliação **Axys-DIFF × SINAPI-Diff**.

**GATE:**
- [ ] Diff não corrompe o 1º import; reimport idempotente.
- [ ] App reconcilia os dois diffs (manutenções cobrem o que a Axys achou?).

#### 3.5 — Mapa H ↔ MES
**Objetivo:** popular `composicoes_mapeamento_mdo` por edição.

**Entregável:** pares horista ↔ mensalista por fuzzy (descrição + unidade ~100%).

**GATE:**
- [ ] Cobertura do fuzzy revisada; pares ambíguos sinalizados (não consumidos pelo import).

---

### Fase 4 — Imports de cadernos (PDF/R2)

**Objetivo:** modal (b) — anexar PDFs / R2 ao caderno da edição.

**Entregável:** pipeline de cadernos (não bloqueia os layers de Excel).

**GATE:**
- [ ] Cadernos vinculados à edição/fonte; armazenamento R2 íntegro.

---

### Fase 5 — UI (tela `/edicoes`)

**Objetivo:** operar o import pela tela.

**Entregável:** na tela `/edicoes`, seleciona caderno → modal (a) "importar composições" (3 Excels obrigatórios) e botão (b) "importar caderno" (PDF/R2). Seguir o padrão canônico de tela do projeto.

**GATE:**
- [ ] Fluxo (a) e (b) operáveis com validação de dependências e mensagens claras.

---

### Fase 6 — Templates de outras fontes + testes

**Objetivo:** abrir o import para fontes não nativas.

**Entregável:** template CSV/Excel (mesmo formato normalizado que os parsers produzem) + `parser_template.py` + bateria de testes de import.

**GATE:**
- [ ] Template documentado e validado contra ao menos uma fonte "OUTRA".

---

### Fase 7 — Catálogo Público Colaborativo (outros tenants)

**Objetivo:** schema/tabelas de composições elaboradas por **outros tenants**.

**Entregável:** avaliar em comunidade **somente ao chegar nesta fase**. Referência: `docs/projects/axys-easy/modules/catalogo/AXYS_CATALOGO_COLABORATIVO_v0.md`. Esta fase **fecha a parte preliminar** da app.

**GATE:**
- [ ] Modelo colaborativo definido e aprovado.

---

### Fase 8 — Módulo ATIVO (orçamento)

**Objetivo:** o orçamento mora aqui (consome `composicoes_mapeamento_mdo`, LS custom, base mensalista — cálculo ao vivo sobre o SE).

**Nota de escopo:** **não chegar perto agora.** Documentado apenas para fechar a fronteira (D9).

---

## Tabelas não populadas por import

| Tabela | Motivo |
|---|---|
| `catalogo.cadernos` | Pipeline separado (PDF/R2) — Fase 4 |
| `catalogo.insumos_tipo` | Seed fixo; não muda por import |
| `catalogo.fontes` | Seed fixo (SINAPI, CDHU, etc.) |
| `catalogo.edicoes` | Pré-requisito; criada via tela/serviço |
