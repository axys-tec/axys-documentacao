# Contrato Arquitetural — Módulo Ativo (AxysEasy)

**Versão:** 0.2 — ⚠️ evoluída por **v0.3** (`EASY_ATIVO_v0.3.md`): drivers, `is_catalog_source`,
BDI/LS, cronograma, diversidades, memória plugin|MANUAL, `tenant_catalogo` polimórfico,
arquivamento e limpezas. Onde houver conflito, **v0.3 prevalece**. A tese central deste doc segue válida.
**Data:** 2026-06-13
**Status:** Canônico (tese) — deltas em v0.3
**Aprovado por:** Renan Dias (Product + Architecture)
**Escopo:** Domínio Ativo do AxysEasy — estrutura hierárquica dinâmica de orçamentos, ficha técnica parametrizável, catálogo do tenant, memória de cálculo, revisões congeladas, isolamento por tenant e diretriz de UX fluida.

> **Sobre a v0.2:** evolui a v0.1 (2026-05-31) **sem abandonar a tese central** (árvore por `parent_id + ordem + path`, numeração derivada, `tipo` define comportamento). A v0.2 incorpora as decisões tomadas após o fechamento conceitual do Catálogo: separação empreendimento/ativo, ficha técnica como parâmetros+atributos, catálogo do tenant, materialização de orçamento por exceção, contexto de preço rotacionável, memória de cálculo enxuta (JSON cru = verdade) e revisões como snapshots congelados. As DDLs deste documento são **propostas a validar a cada import** — não schema definitivo.

---

## 1. Finalidade deste Documento

Este contrato consolida as decisões estruturais do módulo Ativo do AxysEasy — não é resumo de conversa, mas referência canônica para produto, banco de dados, backend, frontend, integrações e automações futuras de IA.

O objetivo principal é evitar três erros recorrentes:

1. **Modelar engenharia como cadastros rígidos** — quando a realidade demanda estruturas flexíveis.
2. **Reproduzir apenas a aparência do Excel** — sem sua liberdade operacional, que é o que mantém o Excel dominante entre orçamentistas.
3. **Nascer com dívida disfarçada de escala** — criar tabelas vazias para o futuro (overengineering) ou deixar decisões críticas implícitas (que cobram refatoração depois).

O módulo Ativo **não é uma tela isolada**. É uma camada estrutural que organiza dados executivos da obra e sustenta orçamento (analítico e sintético), EAP/WBS, cronograma (4D), medição (físico-financeira), curva ABC e histograma, composições próprias do tenant, documentação técnica derivada, contratos e controle executivo.

### 1.1 Princípio Reitor (não-negociável)

> **Refatoração quase proibida.** O módulo nasce escalável, mas sem overengineering. Toda decisão de schema é avaliada por: "isso me obriga a reescrever o núcleo quando a app crescer?" Se sim, resolve-se agora. Se é só reservar um nome, reserva-se — não se cria tabela vazia.

---

## 2. Tese Central

O número exibido em uma planilha de orçamento — `1`, `1.2`, `1.2.3` ou `7.4.1.9` — **não é o dado**. É apenas representação visual de uma posição em uma árvore.

O dado real é: quem é o pai do item (`parent_id`), a ordem relativa entre irmãos (`ordem`, esparsa), o tipo da linha (`tipo`), o conteúdo técnico-financeiro (quantidade, unidade, composição vinculada) e o contexto da obra (edição de preços, base, modalidade, UF, LS, BDI).

**Consequência:** se o sistema tratar `1.2.3` como chave de negócio, fica rígido, frágil e caro de evoluir. Se tratar como numeração renderizada sobre uma árvore ordenada, ganha a maleabilidade que torna o Excel forte na montagem de orçamentos.

---

## 3. Empreendimento, Ativo e a Separação de Responsabilidade

### 3.1 O nome "Ativo"

O módulo se chama **Ativo** porque é a camada que se vincula a objetos do mundo real do tenant. Para uma empresa de projetos, o ativo é um projeto; para uma construtora, é uma obra/edificação; para um contrato, é o objeto contratado. O termo é deliberadamente agnóstico de vertical.

### 3.2 Empreendimento = agrupador puro

O **empreendimento** é apenas agrupador. Não possui parâmetros técnicos próprios, não possui ficha técnica e não participa de motores paramétricos. Serve para agrupamento, relatórios consolidados e organização de escopo.

```
UBS Centro (empreendimento)
├── Prédio Principal      (ativo)
├── Reservatório          (ativo)
├── Guarita               (ativo)
├── Urbanização           (ativo)
└── Abrigo GLP            (ativo)
```

**Decisão de cardinalidade (responde à dúvida "isolar + agrupar" vs "core > derivação"):** vence o caminho **agrupador + FK nullable**. Derivação (core que deriva 1+ ativos) acopla ativos entre si e encarece exatamente o que se quer barato — o relatório consolidado. Com agrupador, consolidado é `WHERE emp_id = X` sobre índice. Um ativo pertence a **0 ou 1** empreendimento (obra avulsa existe sem empreendimento). Não há N:N agora.

### 3.3 Ativo = objeto técnico real

O **ativo** é o objeto técnico. Tudo na aplicação (orçamento, ficha, memória, revisões, microapps) se conecta ao ativo, nunca ao empreendimento.

### 3.4 Separação Catálogo / Tenant Catalog / Ativo

| Schema | Responde | Quem alimenta | Quem edita |
|---|---|---|---|
| `catalogo` | "O que existe de referência?" | Axys (autoritativo) | Axys apenas |
| `tenant_catalogo` | "Que biblioteca técnica este tenant mantém?" | Tenant | Tenant (isolado) |
| `ativo` | "O que esta obra usa? Como foi estruturada?" | Tenant | Tenant (própria obra) |

Essa separação é decisiva para rastreabilidade, reproducibilidade, auditoria, versionamento, liberdade de montagem e abertura futura para IA — sem corromper a base de verdade. **Tenants nunca tocam no `catalogo`.**

---

## 4. Objetivos do Módulo Ativo

1. **Lançar orçamento** via portal, import ou API.
2. **Gerar relatórios** (individuais e consolidados por empreendimento).
3. **Liberdade operacional** de montagem (grade viva, estilo Excel/Notion).
4. **Parâmetros de análise e ajuste de preço, sempre bidirecional** — aplica ajuste, volta ao estágio inicial sem perder a base.
5. **Memória de cálculo rastreável** — itens auditáveis via JSON normalizado (CAD agora, RVT/IFC futuro), com viewer e overlays derivados.
6. **Escalabilidade de produto** — a mesma árvore sustenta orçamento, EAP, cronograma, medição e documentação.
7. **Preparação para IA assistiva** — domínio modelado em entidades estruturadas, nunca texto solto.

---

## 5. Princípios Arquiteturais

1. **Numeração derivada, não persistida.** `1.2.3` é render, não chave.
2. **Árvore primeiro, renderização depois.** Persistência e API pensam em `parent_id`, `ordem`, `path`.
3. **Uma tabela estrutural por domínio.** Linhas heterogêneas tipadas por coluna (`tipo`), não por proliferação de tabelas por nível.
4. **Ordem esparsa.** Espaçamento amplo (1000, 2000, 3000) para inserção intermediária local.
5. **`tipo` define comportamento, nunca profundidade.** Profundidade vem de `parent_id`.
6. **Preço é resolvido, não gravado** (enquanto vivo). O que persiste é o **vínculo**; o preço é calculado contra a edição do contexto. A foto só acontece na emissão.
7. **Catálogo é dinâmico; orçamento é estado.** Orçamento emitido não muda sozinho — vira snapshot.
8. **Isolamento por tenant nas raízes + RLS.** `tenant_uuid` nas raízes; folhas derivam por FK.
9. **JSON cru é a verdade da memória de cálculo.** O relacional é projeção consultável dos campos estáveis.
10. **Namespace reservado ≠ tabela criada.** Microapp futuro reserva nome; cria schema quando chega.
11. **UX operacional acima de UX formulaica.** Grade viva é a experiência principal.

---

## 6. Árvore Estrutural Consolidada

Marcação: **(MVP)** nasce agora · **(reservado)** namespace reservado, sem DDL hoje.

```
hub
└── tenants

catalogo                              (global · Axys · read-only p/ tenant)
├── fontes
├── edicoes
├── unidades
├── insumos / insumos_preco
├── composicoes / composicoes_itens / composicoes_custo
└── search_document

tenant_catalogo                       (biblioteca própria do tenant · MVP)
├── insumos / insumos_preco
└── composicoes / composicoes_itens / composicoes_custo

ativo
├── empreendimentos                   (agrupador puro · MVP)
│
└── ativos                            (objeto técnico real · MVP)
    │
    ├── ativo_ficha_tecnica           (cabeçalho da ficha · MVP)
    │   ├── ficha_parametros          (catálogo de parâmetros · valor tipado)
    │   └── ficha_atributos           (valores do ativo)
    │
    ├── ativo_itens                   (ÁRVORE canônica: parent_id+ordem+path · MVP)
    │                                  (origem da composição: CATALOGO|TENANT|LOCAL)
    │
    ├── orcamento_parametros          (CONTEXTO de preço por fonte · MVP)
    │                                  (edição-base, LS, BDI, UF, modalidade · rotacionável)
    │
    ├── orcamento_composicoes         (fork local — exceção · MVP)
    │   └── orcamento_composicoes_itens
    │
    ├── orcamento_insumos             (fork local — exceção · MVP)
    │   └── orcamento_insumos_preco
    │
    ├── memo_calc                     (1 por import de JSON · json_cru imutável · MVP)
    │   └── memo_calc_item            (1 por bloco/coletor · qtd_calculada + entidades)
    │
    ├── memo_item_link                (ponte N:N memo_calc_item ↔ ativo_item · MVP)
    │
    ├── ativo_revisoes                (header + rev_snapshot_json + rev_resumo · MVP)
    │
    ├── ativo_eventos                 (trilha de eventos do ativo · MVP)
    │
    │  ──────── namespace reservado — NÃO criar agora (entra com o microapp) ────────
    ├── ativo_docs                    (reservado)
    ├── ativo_pm                      (reservado)
    ├── ativo_diario                  (reservado)
    ├── ativo_fin                     (reservado)
    ├── ativo_licit                   (reservado)
    └── ativo_repo                    (reservado)

audit
├── logs
├── api_logs
└── login_logs
```

---

## 7. Conceitos Fundamentais

- **Empreendimento** — agrupador puro de ativos (sem ficha, sem motor).
- **Ativo** — objeto técnico editável pelo tenant (obra, projeto, edificação, contrato).
- **Estrutura Ativa** — árvore ordenada de itens (`ativo_itens`); mesma árvore vista como orçamento, EAP, cronograma ou medição.
- **Item Ativo** — cada linha da árvore; `tipo` define comportamento.
- **Linha de Serviço** — item com semântica técnico-financeira (quantidade, composição, custo).
- **Composição vinculada** — referência resolvível para `catalogo`, `tenant_catalogo` ou fork local de orçamento.
- **Contexto de preço** — edição-base, LS, BDI, UF, modalidade do orçamento (rotacionável).
- **Memória de cálculo** — JSON normalizado (CAD/RVT/IFC) que asseverou a quantidade de um item, com evidência auditável.
- **Revisão** — snapshot congelado emitido a partir do estado vivo.
- **Snapshot** — registro write-once para reproducibilidade de cálculo.

---

## 8. Modelo de Dados — PROPOSTA (a validar a cada import)

> ⚠️ **Status das DDLs:** as definições abaixo são **proposta de trabalho**, descritas para que cada coluna tenha função documentada. Devem ser **validadas a cada import/iteração** de schema e ajustadas conforme a realidade dos parsers e da app. Tipos são indicativos (Postgres). Auditoria (`*_criado_em/por`, `*_atualizado_em/por`) é padrão em todas as tabelas e omitida das listagens para foco.

### 8.1 `ativo.empreendimentos` (MVP)

Agrupador puro de ativos do tenant.

| Coluna | Tipo | Função |
|---|---|---|
| `emp_id` | PK | Identidade do empreendimento. |
| `emp_tenant_uuid` | UUID FK → hub_tenant | **Raiz de isolamento** — define a quem pertence; base do RLS. |
| `emp_codigo_interno` | VARCHAR null | Código próprio do tenant (cadastro interno do cliente); nullable. |
| `emp_nome` | VARCHAR | Nome de exibição. |
| `emp_descricao` | TEXT null | Descrição livre. |
| `emp_meta_json` | JSONB | Metadados livres (sem inflar schema). |

### 8.2 `ativo.ativos` (MVP)

O objeto técnico real. Núcleo ao qual tudo se conecta.

| Coluna | Tipo | Função |
|---|---|---|
| `atv_id` | PK | Identidade do ativo. |
| `atv_tenant_uuid` | UUID FK → hub_tenant | **Raiz de isolamento**; base do RLS. |
| `atv_emp_id` | FK → empreendimentos **null** | Empreendimento agrupador (0..1). Null = obra avulsa. |
| `atv_codigo_interno` | VARCHAR null | Código próprio do tenant; nullable. |
| `atv_tipo` | VARCHAR | Vertical/natureza (obra, projeto, edificação, contrato…). |
| `atv_nome` | VARCHAR | Nome de exibição. |
| `atv_status` | VARCHAR | Estado operacional (rascunho, ativo, arquivado…). |
| `atv_uf` | CHAR(2) null | UF default do ativo (pode ser sobreposta no contexto de preço). |
| `atv_meta_json` | JSONB | Metadados executivos livres. |

### 8.3 `ativo.ativo_ficha_tecnica` (MVP)

Cabeçalho da ficha técnica parametrizável. **Não** é tabela de N colunas físicas — é o ponto de entrada para parâmetros+atributos.

| Coluna | Tipo | Função |
|---|---|---|
| `ficha_id` | PK | Identidade da ficha. |
| `ficha_atv_id` | FK → ativos | Ativo dono da ficha (1:1 lógico). |
| `ficha_versao` | INTEGER | Versão da ficha (evolução de preenchimento). |
| `ficha_status` | VARCHAR | Estado (rascunho, consolidada…). |

### 8.4 `ativo.ficha_parametros` (MVP)

Catálogo de parâmetros possíveis. Cresce **sem migration** — adicionar parâmetro é INSERT, não ALTER.

| Coluna | Tipo | Função |
|---|---|---|
| `par_id` | PK | Identidade do parâmetro. |
| `par_tenant_uuid` | UUID **null** | Null = parâmetro semeado pela Axys (global). Preenchido = customização do tenant. |
| `par_grupo` | VARCHAR | Agrupamento semântico (AREA, ESTRUTURA, HIDRO…). |
| `par_codigo` | VARCHAR | Código estável (AREA_TERRENO, QTD_SANITARIOS, TEM_SPDA…). |
| `par_descricao` | VARCHAR | Rótulo legível. |
| `par_tipo` | VARCHAR | Tipo do valor (NUMERO, TEXTO, BOOL, DATA, LISTA). |
| `par_unidade` | VARCHAR null | Unidade (m², un, …) quando aplicável. |
| `par_ordem` | INTEGER | Ordem de exibição dentro do grupo. |
| `par_meta_json` | JSONB | Metadados futuros (driver, peso, regra) sem inflar schema. |

### 8.5 `ativo.ficha_atributos` (MVP)

Valores preenchidos por ativo. **Valor em colunas tipadas** (indexável/computável), nunca tudo em JSON.

| Coluna | Tipo | Função |
|---|---|---|
| `atr_id` | PK | Identidade do atributo preenchido. |
| `atr_ficha_id` | FK → ativo_ficha_tecnica | Ficha dona do valor. |
| `atr_par_id` | FK → ficha_parametros | Qual parâmetro este valor preenche. |
| `atr_valor_numero` | DECIMAL null | Valor numérico (indexável/computável). |
| `atr_valor_texto` | TEXT null | Valor textual. |
| `atr_valor_bool` | BOOLEAN null | Valor booleano. |
| `atr_valor_data` | DATE null | Valor data. |
| `atr_meta_json` | JSONB | Apenas o genuinamente livre (ex.: lista, payload de driver). |

> **Nota analítica:** filtragem por parâmetro ("obras com AREA_CONSTRUCAO > 1000") **não** se faz por EAV no OLTP — resolve-se por **view pivotada / projeção materializada** na camada analítica. EAV é ótimo para armazenar e evoluir; ruim para filtrar em massa.

### 8.6 `ativo.ativo_itens` (MVP) — a árvore canônica

Coração do módulo. Árvore por `parent_id + ordem esparsa + path`, com discriminador de origem da composição.

| Coluna | Tipo | Função |
|---|---|---|
| `ati_id` | PK | Identidade do item. |
| `ati_atv_id` | FK → ativos | Ativo dono. |
| `ati_parent_id` | FK → ati_id **null** | Pai na árvore; NULL = raiz. **Profundidade vem daqui.** |
| `ati_ordem` | INTEGER | Ordem **esparsa** entre irmãos (1000, 2000…). Inserção local sem renumeração global. |
| `ati_path` | TEXT | Caminho hierárquico ("0001.0002.0001") para ORDER BY e consulta de descendência. |
| `ati_tipo` | VARCHAR | GRUPO, SERVIÇO, SUBTOTAL, TEXTO, OBSERVAÇÃO… **define comportamento, não profundidade.** |
| `ati_descricao` | TEXT | Descrição da linha. |
| `ati_cmp_origem` | VARCHAR CHECK ('CATALOGO','TENANT','LOCAL') null | **Discriminador de origem** da composição vinculada. Resolve a FK polimórfica. Null = linha estrutural sem composição. |
| `ati_cmp_id` | INTEGER null | Id da composição **na origem indicada** por `ati_cmp_origem`. |
| `ati_quantidade` | DECIMAL null | Quantidade. Se há memória vinculada, é derivada dela; senão, digitada. |
| `ati_unidade` | VARCHAR null | Unidade de medida da linha. |
| `ati_ajuste_json` | JSONB null | **Camada de ajuste reversível** sobre o preço resolvido (ver §10). Descartar = volta ao estágio inicial. |
| `ati_have_memory_calc` | BOOLEAN | Flag: quantidade vem de memória de cálculo (true) ou digitação (false). |
| `ati_regras_json` | JSONB | Metadados por tipo de linha. |
| `ati_meta_json` | JSONB | Flexibilidade futura. |

> **Preço NÃO é coluna aqui.** O custo é **resolvido ao vivo** contra a edição do contexto (`orcamento_parametros`). O que o item guarda é o **vínculo** (`origem` + `cmp_id` + quantidade) e a **camada de ajuste** (`ati_ajuste_json`). Não existe `ati_custo_base` persistido — isso quebraria a rotação de edição.

### 8.7 `ativo.orcamento_parametros` (MVP) — contexto de preço

Contexto de precificação do orçamento por fonte. **Rotacionável**: trocar uma linha re-resolve todo o orçamento sem tocar item algum.

| Coluna | Tipo | Função |
|---|---|---|
| `opa_id` | PK | Identidade do parâmetro de contexto. |
| `opa_atv_id` | FK → ativos | Ativo/orçamento dono. |
| `opa_fonte` | VARCHAR | Fonte-base (SINAPI, CDHU, tenant…). |
| `opa_edicao_id` | INTEGER FK → catalogo.edicoes | **Edição-base selecionada** (imutável após publicada → resolução estável). |
| `opa_uf` | CHAR(2) | UF de precificação. |
| `opa_modalidade` | VARCHAR | Desonerada/Não-desonerada etc. |
| `opa_ls_percent` | DECIMAL null | Leis Sociais aplicadas sobre o pelado (base SE separa pelado de LS). **Muda o preço.** |
| `opa_bdi_percent` | DECIMAL null | BDI — margem **acima** do custo. **Não muda o custo**, compõe o preço de venda. |
| `opa_default` | BOOLEAN | Marca o contexto inicial herdado na criação do orçamento. |

> **Rotação de edição** = trocar `opa_edicao_id` → tudo re-resolve. Item descontinuado na edição-alvo é **skipado/sinalizado** (herda o comportamento de órfão/descontinuado do Catálogo), não quebra.

### 8.8 `ativo.orcamento_composicoes` / `orcamento_composicoes_itens` (MVP) — fork local

Materialização **por exceção**: só existe quando o usuário altera uma composição naquele orçamento. Mesma forma de `catalogo.composicoes` / `composicoes_itens`, porém local e isolada.

`orcamento_composicoes`:

| Coluna | Tipo | Função |
|---|---|---|
| `ocp_id` | PK | Identidade da composição forkada. |
| `ocp_atv_id` | FK → ativos | Orçamento dono (isolamento). |
| `ocp_origem_ref` | VARCHAR null | De onde veio o fork (origem+código original) para rastreio. |
| `ocp_codigo` | VARCHAR | Código local. |
| `ocp_descricao` | TEXT | Descrição (pode divergir do original — é o motivo do fork). |
| `ocp_unidade` | VARCHAR | Unidade. |

`orcamento_composicoes_itens`:

| Coluna | Tipo | Função |
|---|---|---|
| `oci_id` | PK | Identidade do item da composição forkada. |
| `oci_ocp_id` | FK → orcamento_composicoes | Composição dona. |
| `oci_ref_origem` | VARCHAR CHECK ('CATALOGO','TENANT','LOCAL') | Origem do insumo/subcomposição referenciado. |
| `oci_ref_id` | INTEGER | Id na origem. |
| `oci_coeficiente` | DECIMAL | Consumo/coeficiente na receita. |

### 8.9 `ativo.orcamento_insumos` / `orcamento_insumos_preco` (MVP) — fork local

Mesma lógica de exceção, para insumos alterados localmente.

`orcamento_insumos`:

| Coluna | Tipo | Função |
|---|---|---|
| `oin_id` | PK | Identidade do insumo forkado. |
| `oin_atv_id` | FK → ativos | Orçamento dono (isolamento). |
| `oin_origem_ref` | VARCHAR null | Origem+código original para rastreio. |
| `oin_descricao` | TEXT | Descrição local. |
| `oin_unidade` | VARCHAR | Unidade local. |

`orcamento_insumos_preco`:

| Coluna | Tipo | Função |
|---|---|---|
| `oip_id` | PK | Identidade do preço local. |
| `oip_oin_id` | FK → orcamento_insumos | Insumo dono. |
| `oip_preco` | DECIMAL | Preço local definido pelo usuário. |
| `oip_situacao` | TEXT CHECK ('COM PREÇO','SEM PREÇO') | Coerente com a doutrina do Catálogo (null = sem preço). |

### 8.10 `ativo.memo_calc` / `memo_calc_item` (MVP) — memória de cálculo

Verdade da auditoria = **JSON cru imutável**. Estrutura enxuta: um registro por import, um filho por bloco/coletor do JSON. **Sem** tabela de entidades relacional, **sem** tabela de overlays (overlays são derivados no viewer a partir das entidades + `marker_layer`).

`memo_calc`:

| Coluna | Tipo | Função |
|---|---|---|
| `mc_id` | PK | Identidade do import de memória. |
| `mc_atv_id` | FK → ativos | Ativo dono. |
| `mc_origem` | VARCHAR CHECK ('CAD','RVT','IFC') | Plataforma de origem. Mesmo contrato JSON entre todas (idempotente). |
| `mc_arquivo` | VARCHAR null | Nome do arquivo de origem (ex.: dwg_filename) — referência, **opcional**. |
| `mc_hash` | VARCHAR null | Hash/checksum para provenance. |
| `mc_json_cru` | JSONB | **Imutável. A verdade.** Reproduz a trilha humana ao clicar "ver memo calc". |
| `mc_importado_em` | TIMESTAMP | Quando foi importado. |
| `mc_importado_por` | VARCHAR | Quem importou. |

`memo_calc_item` (1 por bloco/coletor — ex.: "BACIA = 4 UN"):

| Coluna | Tipo | Função |
|---|---|---|
| `mci_id` | PK | Identidade do bloco. |
| `mci_mc_id` | FK → memo_calc | Import dono. |
| `mci_codigo` | VARCHAR | `codigo_levantamento` — **agrupador/acumulador** e junção semântica com o item. |
| `mci_nome_amigavel` | VARCHAR | Nome legível do levantamento. |
| `mci_metodo` | VARCHAR | `method` do coletor (selection_count, soma_area…). |
| `mci_unidade` | VARCHAR | Unidade de medição. |
| `mci_qtd_calculada` | DECIMAL | **Quantidade asseverada pelo coletor.** Autoridade sobre o número (não recalculada das entidades). |
| `mci_entidades_consideradas` | JSONB | Evidência: as entidades CAD do bloco (handle, type, layer, coords). Prova, não fonte de cálculo. |

> **Regra de ouro:** quantidade é **persistida** (vem do coletor); overlay é **derivado** (recalcula no viewer). Divergência entre `qtd_calculada` e contagem de entidades é **alerta de auditoria**, nunca recálculo silencioso. O relacional só extrai campos **estáveis**; nada específico de plataforma — isso fica no `mc_json_cru`.

### 8.11 `ativo.memo_item_link` (MVP) — ponte N:N

O que faz **aberto e fechado caberem no mesmo schema**. Um item de planilha pode somar vários blocos; um bloco (global) pode alimentar vários itens.

| Coluna | Tipo | Função |
|---|---|---|
| `mil_id` | PK | Identidade do vínculo. |
| `mil_mci_id` | FK → memo_calc_item | Bloco de memória. |
| `mil_ati_id` | FK → ativo_itens | Item de orçamento. |
| `mil_tipo` | VARCHAR CHECK ('DIRECIONADO','GLOBAL') | DIRECIONADO = LISP baixado na linha (já nasce colado). GLOBAL = LISP do cabeçalho (associa depois). |

> **Quantidade do item** = Σ `mci_qtd_calculada` dos blocos linkados (quando `ati_have_memory_calc = true`); senão, valor digitado.

### 8.12 `ativo.ativo_revisoes` (MVP) — snapshots congelados

Estado vivo + revisões congeladas. **Não** há "versão viva 1/2/3"; há o ativo vivo e fotos emitidas. **Não** se espelham 7 tabelas-gêmeas: a foto fiel vive em JSON, o que se consulta vive em colunas de resumo.

| Coluna | Tipo | Função |
|---|---|---|
| `rev_id` | PK | Identidade da revisão. |
| `rev_atv_id` | FK → ativos | Ativo dono. |
| `rev_codigo` | VARCHAR | Rótulo (R01, R02…). |
| `rev_status` | VARCHAR | Estado (emitida, arquivada…). |
| `rev_data` | TIMESTAMP | Data da emissão. |
| `rev_autor` | VARCHAR | Quem emitiu. |
| `rev_snapshot_json` | JSONB | **Fotografia completa write-once** (orçamento + composições + preços resolvidos + memória + parâmetros). Fidelidade total para reproduzir. |
| `rev_resumo_json` | JSONB | Resumo denormalizado (totais, ABC) — o que se consulta/diffa, barato. |

### 8.13 `ativo.ativo_eventos` (MVP) — trilha

Trilha de eventos estruturais e de negócio do ativo (auditoria de movimentos: criar, mover, indentar, emitir revisão, rotacionar edição…).

| Coluna | Tipo | Função |
|---|---|---|
| `evt_id` | PK | Identidade do evento. |
| `evt_atv_id` | FK → ativos | Ativo. |
| `evt_tipo` | VARCHAR | Tipo de evento. |
| `evt_payload_json` | JSONB | Dados do evento. |
| `evt_em` | TIMESTAMP | Quando. |
| `evt_por` | VARCHAR | Quem. |

### 8.14 `tenant_catalogo.*` (MVP) — biblioteca do tenant

Espelha a forma do `catalogo` (insumos/insumos_preco, composicoes/composicoes_itens/composicoes_custo), porém **isolada por tenant** (`tenant_uuid` na raiz + RLS). Permite que cada tenant mantenha CPUs/insumos próprios **sem tocar no catálogo**. Itens de `ativo_itens` referenciam esta biblioteca via `ati_cmp_origem = 'TENANT'`. As colunas seguem a doutrina do Catálogo (situação como CHECK-text, unidade verbatim, custo por edição) — DDL detalhada validada na implementação, contra o `schema.sql` do Catálogo.

---

## 9. Numeração, UX e Operações Estruturais

Mantidos integralmente da v0.1 (numeração derivada no render; grade viva com Insert/Tab/Shift+Tab/Ctrl+C/V/D; ordem esparsa com rebalanceamento local; operações estruturais de primeira classe). Ver §11–§13 da v0.1 — sem alteração de tese.

---

## 10. Preço Resolvido e Ajuste Bidirecional

Existem **três camadas de preço**, nunca colapsadas:

```
preço_catálogo   = resolve(composição, EDIÇÃO, UF, modalidade)   ← do catalogo/tenant_catalogo, "pelado/SE"
preço_base_ativo = preço_catálogo + LS (do contexto)             ← muda com rotação/LS
preço_ajustado   = preço_base ± ajuste manual (ati_ajuste_json)  ← reversível: descartar = volta à base
```

- **Rascunho** resolve **ao vivo** contra a edição escolhida (estável, porque edição publicada é imutável).
- **Emitido** vira **snapshot congelado** (`rev_snapshot_json`).
- **"Voltar ao estágio inicial"** = descartar `ati_ajuste_json` → cai na base resolvida (não recalcula do catálogo, que pode ter rotacionado).
- **LS muda preço, BDI não muda custo** — a base SE do Catálogo já separa pelado de encargo, então LS é camada sobre o pelado e BDI é margem acima do total.

Isso resolve a tensão "catálogo dinâmico / orçamento estado" sem persistir preço no item.

---

## 11. Métodos de Levantamento (CAD agora · RVT/IFC futuro)

Dois métodos de coleta convivem no **mesmo schema** (a tabela não muda; muda o `mil_tipo` e como o front monta o vínculo):

1. **LISP global (aberto)** — baixado no cabeçalho do orçamento, já semeado com código de empreendimento/ativo/pavimentos. O usuário levanta livremente; a disciplina dos `codigo_levantamento` é o que permite associar à planilha depois (GLOBAL). Mais flexível, maior margem de erro.
2. **LISP por linha (direcionado)** — baixado na linha do orçamento, já programado com código/descrição/unidade do item. Menor margem de erro, escalável, permite 1+ JSONs por orçamento (DIRECIONADO). Atrito: re-baixar a cada rodada.

**Diretriz de produto:** a Axys **não** contempla fatiar entidades manualmente em +1 item no import — granularidade se resolve **a montante** (mais códigos no levantamento), não com muleta de fatiamento (risco de quebra). O vínculo bloco→item é N:N (junta blocos num item); não se parte um bloco.

**Idempotência:** RVT/IFC entram **sem tocar no schema**, pois o contrato JSON é o mesmo entre origens e o relacional só lê campos estáveis. Decisão futura (LISP vs plugin) não afeta o schema — afeta só o atrito de coleta. O vetor: como RVT exige plugin de qualquer forma, "plugin" tende a ser um *quando*, não um *se*; LISP global permanece como porta de entrada barata.

---

## 12. Microapps — operam sobre o Ativo (evolução, sem DDL agora)

Os microapps **não são entidades independentes**; operam sobre o ativo. Os slots de namespace reservado (`ativo_docs`, `ativo_pm`, `ativo_diario`, `ativo_fin`, `ativo_licit`, `ativo_repo`) recebem schema **quando o microapp nascer** — cada um traz o próprio DDL naquele slot, sem refatorar placeholder.

| Microapp | Opera sobre | Slot futuro |
|---|---|---|
| **Easy Price** | ativo + ficha técnica | (consome `ficha_*`) |
| **Easy CPU** | ativo + composições + orçamento | (consome `ativo_itens`, composições) |
| **Easy Orça** | ativo + CPU + Price | (consolida e emite) |
| **Easy Docs** | ativo + ficha + IFC + memórias | `ativo_docs` |
| **Easy ProjectManager** | ativo | `ativo_pm` |
| **Easy BuildDiary** | ativo | `ativo_diario` |
| **Easy FinControl** | ativo | `ativo_fin` |
| **Easy LicitPlan** | pode existir isolado; quando associado a contrato/obra, núcleo é o ativo | `ativo_licit` |
| **Repositório de arquivos** | arquivos pertencem sempre a um ativo (sem repositório global) | `ativo_repo` |

---

## 13. Isolamento por Tenant

- `tenant_uuid` nas **raízes**: `empreendimentos`, `ativos`, `tenant_catalogo.*`. Folhas derivam por FK (não se replica `tenant_uuid` em toda folha).
- **RLS no Postgres** como defesa de acesso.
- `catalogo` permanece **global** (read-only para tenant).
- Composições de orçamento (`tenant_catalogo` e forks locais) **nunca** tocam o `catalogo`.

Decidir isolamento **agora** (não depois) — retrofitar política de acesso é dos refactors mais caros.

---

## 14. Anti-patterns Proibidos

Além dos da v0.1 (persistir `1.2.3` como chave; limitar a GRUPO>SUBGRUPO>ITEM; tabela por nível; formularizar a montagem; contaminar catálogo; recalcular árvore inteira; IA sobre texto sem entidade):

- **Persistir preço no item como verdade** enquanto vivo — preço é resolvido; só snapshot congela.
- **`ati_custo_base` imutável** — quebra rotação de edição. O imutável é o vínculo.
- **FK polimórfica de composição sem discriminador** — exige `ati_cmp_origem`.
- **Tabelas-gêmeas de snapshot** espelhando o schema vivo — usar JSON + resumo.
- **Entidades CAD e overlays como tabelas relacionais** — entidades vivem em `mci_entidades_consideradas`/`json_cru`; overlay é derivado.
- **Criar tabela de microapp futuro vazia** — namespace reservado, não DDL.
- **Fatiar entidades manualmente no import** — disciplina é a montante.

---

## 15. Diretrizes para IA, Desenvolvedores e Arquitetos

1. Verdade estrutural mora na árvore, não em numeração textual.
2. `tipo` define comportamento, nunca profundidade.
3. Preço é resolvido contra a edição do contexto; só emissão congela.
4. Origem da composição é explícita (`CATALOGO|TENANT|LOCAL`).
5. JSON cru é a verdade da memória; relacional é projeção de campos estáveis.
6. Isolamento por tenant nas raízes + RLS, decidido na origem.
7. Mesma árvore sustenta orçamento, EAP, cronograma, medição.
8. Namespace reservado ≠ tabela criada.

### Pergunta correta ao implementar

❌ "Como salvo essa linha?"
✅ "Como preservo a liberdade de montagem sem perder consistência estrutural, financeira e auditável?"

---

## 16. Aprovação e Evoluções

**Versão:** 0.2 · **Data:** 2026-06-13 · **Aprovado por:** Renan Dias (Product + Architecture)

As DDLs são **proposta a validar a cada import**. Evoluções mantêm a tese central (árvore, ordem esparsa, numeração derivada, preço resolvido, JSON como verdade) e são documentadas como versões sucessivas. Este documento é vivo e canônico para a próxima iteração do domínio orçamentário e estrutural do AxysEasy.
