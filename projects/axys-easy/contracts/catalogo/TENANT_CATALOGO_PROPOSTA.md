# Proposta — `tenant_catalogo` (biblioteca técnica do usuário)

> Status: **DECISÕES CRAVADAS** (Renan, inline) · nada existe em local nem prod (prod em homologação) → seguro dropar e recriar.
> Objetivo: o tenant cadastra/importa **fontes, edições, insumos, pesquisa de preço e composições próprias** —
> comportamento **muito próximo do `catalogo`**, mas **enxuto**: sem CTC, sem path/R2, sem grupos, sem BDI,
> sem conferência, sem cadernos, sem equivalências. **L.S. mínima** (1 número por edição, só p/ MO).
> Multi-tenant, escala → **poucas tabelas, isolamento na raiz.**

---

## 0. Princípios (cravados)

1. **`tenant_uuid` é a raiz de isolamento** em toda tabela-mãe (fontes, edições, insumos, composições). Sem FK física — resolvido pelo app (futuro RLS). Denormalizado nas filhas só se a query exigir.
2. **FK física só para `catalogo.insumos_tipo`** (lookup global MO/MAT/EQ…). **NÃO** fazemos FK para `catalogo.unidades` nem para o resto do global. Unidade é **texto livre** (como o próprio catálogo trata na prática).
3. **Sem colunas/tabelas de fonte pública**: ciclo de publicação, docs R2, cadernos, CTC, grupos/subgrupos, encargos itemizados/BDI, conferência fonte×calculado, equivalências, família, NF-e, search_document.
4. **Versionado por EDIÇÃO** (linha nova por edição = a "história"). **Sem tabela de histórico/auditoria.** O **único histórico guardado é PREÇO** — a série de `insumos_preco` por edição.
5. **Custo da composição é SEMPRE CALCULADO** (Σ coef × preço-do-filho) **e ARMAZENADO** (cache) em `composicoes_custo`. **Não há custo importado** e **não há conferência** fonte×calculado.
6. **L.S. mínima, só p/ MÃO DE OBRA:** insumo de MO entra **PELADO** (SE). A edição carrega **1 número** — `edi_ls_horista` (opcional). Com-encargos = `trunc2(pelado × (1+LS))` — **regra SINAPI (truncate geral)**. Demais insumos: valor **final** como fornecido. Sem `modalidade`, sem tabela de encargos. Divergência de arredondamento no import → **paciência**.

---

## 1. Comparativo lado a lado (tabela a tabela)

| `catalogo.*` (global, 37 tabelas) | `tenant_catalogo.*` (proposto, 7 tabelas) | O que muda |
|---|---|---|
| **`fontes`** (12 cols: ordem_edição, tem_catalogo_insumos, tem_caderno, contínuos, public…) | **`fontes`** (tenant_uuid, código, nome, **tipo PRÓPRIA\|EXTERNA**, ativa, +stamps) | Some tudo de publicação/caderno/público. Ativa mantida (liga/desliga a fonte inteira). |
| **`edicoes`** (16 cols: ciclo 4-estados, docs_status, estagios, paths, uf_padrão, revisao…) | **`edicoes`** (tenant_uuid, fte_id, **referência DATE + código/versão TEXT**, **`edi_ls_horista` opc.**, situação **RASCUNHO\|PUBLICADA\|ARQUIVADA**, +stamps) | **Sem `uf_padrão`** (UF vive no preço). Sem pipeline/R2/mensal. Ganha a **L.S. da edição** (1 número, p/ MO). Import **mono-fonte**. |
| **`insumos`** (ti_origem, external_path, ativo…) | **`insumos`** (tenant_uuid, fte_id, ti_id→global, código, descrição, unidade, **`ins_uf`**, +stamps) | Some external_path **e `ativo`**. **UF vive no insumo** (não no preço). `ti_id` FK ao lookup global. Único **(fte, código, UF)**. |
| **`insumos_preco`** (edi, uf, **modalidade SD/CD/SE**, situação, origem C/CR/CT) | **`insumos_preco`** (ins, edi, valor, situação, origem, **`cotacoes` JSONB opc.**, +stamps) | **Sem `uf`** (herda do insumo) e **sem `modalidade`**. Grão = **(insumo, edição)**. MO = pelado; encargos saem da `edi_ls_horista` no motor. Cotação **JSONB inline**. |
| **`insumos_cotacoes`** (tabela própria + certidão R2) | *(inline em `insumos_preco.cotacoes`)* | JSON guarda **mais que preço**: `[{empresa, site, telefone, email, responsavel, data, valor}]` (≈3-4/insumo, só na 1ª vez). Mediana → `pri_valor`. |
| **`composicoes`** (grupo/sub, descritivo CTC, external_path, motivo_sem_custo, situação, ativa, pubs…) | **`composicoes`** (tenant_uuid, fte_id, código, descrição, unidade, +stamps) | Some CTC, path, grupos, flags **e `situação`/`ativa`**. Único (fte, código). |
| **`composicoes_itens`** (ci_tipo_filho, ci_ins_id, ci_cmp_filho_id) | **`composicoes_itens`** (**ref polimórfica**: ref_origem CATALOGO\|TENANT + ref_tipo INSUMO\|COMPOSICAO + ref_id, coef, **`ci_uf` opc.**, +stamps) | Item aponta p/ insumo **ou** CPU, do **global ou do tenant**, **de qualquer UF**. `ci_uf` só precifica filho **GLOBAL** (filho-tenant herda a UF do insumo). FK resolvida pelo app (a "bucha" a.3). |
| **`composicoes_custo`** (fonte, calculado, diferença, conferência, pct_sp…) | **`composicoes_custo`** (cmp, **edi**, **custo único CALCULADO**, +stamps) | **1 custo por (composição, edição)** — sem `cc_uf` (composição é UF-agnóstica; cada filho traz sua UF). Sem `origem`/conferência/`modalidade`. |
| `composicoes_historico` / `insumos_historico` | *(nenhuma)* | **Sem auditoria.** Histórico = série de **preço** por edição. |
| `insumos_tipo` (lookup MO/MAT/EQ…) | *(reusa o GLOBAL)* | FK física ao global. Não replica. |
| `composicoes_grupos`/`subgrupos`, `edicoes_bdi*`, `edicoes_leis_sociais*`, `equivalencias_*`, `composicoes_mapeamento_mdo`, `documentos*`, `indices*`, `insumos_atributos`/`classificacao`/`codigos_externos`/`familia`/`nfe*`, `parametros_normativos`, `search_document`, `sinapi_manutencoes`, `bdi_tcu_param`, `unidades` | *(nenhuma)* | **Fora do escopo do tenant.** |

**Resultado: 37 → 7 tabelas.** (`fontes`, `edicoes`, `insumos`, `insumos_preco`, `composicoes`, `composicoes_itens`, `composicoes_custo`.)

---

## 2. Como o custo é resolvido (sempre calculado)

- **UF vem do insumo** (`ins_uf`). O preço (`insumos_preco`) é por **(insumo, edição)** — a UF é implícita.
- **Insumo NÃO-MO:** `pri_valor` = **valor final**.
- **Insumo MO** (`ti_id` = MO): `pri_valor` é **PELADO** (SE) → com-encargos = `trunc2(pelado × (1 + edi_ls_horista/100))`; `edi_ls_horista` NULL → usa o pelado. **Truncate SINAPI, 2 casas.**
- **Composição (UF-agnóstica):** aceita filho de **qualquer UF**. Custo **SEMPRE CALCULADO** = Σ (coef × preço-do-filho), truncando à regra SINAPI. Cada filho é precificado na **sua** UF: **tenant** → `ins_uf` do insumo; **global** → `ci_uf` do item (default SP se NULL). Um custo por **(composição, edição)**, armazenado em `composicoes_custo` (cache), **recalculado** quando o preço de um filho muda.
- **Sem custo importado.** Fonte externa traz **insumos + preços**; as composições são montadas com **itens** (é o que permite calcular). Composição sem itens ⇒ sem custo.
- **Motor único:** estende o resolvedor da bancada para `origem = TENANT` (hoje só `CATALOGO`). Mesma assinatura; a única "conversão" é a L.S. da edição sobre MO.

---

## 3. Ligação com a bancada (já pronta no schema)

- `ativo.ativo_itens.ati_cmp_origem` já aceita **`CATALOGO | TENANT | NULL`** (CHECK). Falta só o **código** do resolvedor TENANT.
- **Preço isolado por obra (FUTURO, fora desta proposta):** editar preços sob a bancada (função superior a "fixar preço"), onde insumo/composição assumem valores **independentes por ativo** — vive **sob o `ativo`**, não em `tenant_catalogo`. (Provável reuso das órfãs `ativo.orcamento_insumos*` — §5.)

---

## 4. Auditoria — cravado

**Sem tabela de histórico/auditoria.** Toda linha tem `criado_em/por` + `atualizado_em/por` (carimbo). O **único histórico** é a **série de PREÇO** por edição em `insumos_preco`; o custo da composição é derivado (cache recalculável), então não precisa de trilha própria.

---

## 5. Legado — as "órfãs" `ativo.orcamento_insumos` / `ativo.orcamento_insumos_preco`

- **Órfã = tabela que existe no schema mas ninguém referencia** (0 uso no código). Eram o "fork **LOCAL**" (insumo por-orçamento, `origem='LOCAL'`), substituído por **TENANT**.
- **Não dropar** — marcar **NÃO USADAS por ora** (comentário no schema). Candidatas ao **preço isolado por obra** (§3, futuro).

---

## 6. Uso — cadastro (manual + import)

Cadastrar: fonte (própria/externa) · edição · insumo · pesquisa de preço (com cotações) · composição + itens. Dois caminhos:

- **Manual, um a um** (tela).
- **Import otimizado, mono-fonte:** cada arquivo traz UMA fonte. **Templates CSV padrão** por entidade: `fontes.csv`, `edicoes.csv`, `insumos.csv`, `insumos_preco.csv`, `composicoes.csv`, `composicoes_itens.csv`.
- **Prompts de IA genéricos** (testados em Gemini / Claude / ChatGPT): "pegue esta planilha e produza o CSV no template X" → o app **valida e importa**. `composicoes_itens` referencia por **código** (resolve p/ id no import; filho global ou tenant).

**Idempotência do import (documentar):** o import é sempre por **(FONTE, EDIÇÃO, UF)** e é **idempotente** — faz **"put"/update**. Reimportar o mesmo escopo **substitui** o que existia:
`DELETE FROM insumos_preco WHERE pri_edi_id=<edição> AND pri_ins_id IN (insumos da fonte com ins_uf=<UF>)` → `INSERT` do arquivo (get-or-create do insumo por (fonte, código, UF)). Insumo que sumiu da nova edição perde o preço daquela edição; insumo novo entra. Custos de composição são **recalculados** depois (nunca importados).

**Decisão histórico preço — filha vs JSON:** avaliado colar o histórico num JSON no insumo/composição (`*_historico_preco`) p/ economizar 2 tabelas. **Mantido separado** (`insumos_preco`/`composicoes_custo`): (1) o import idempotente acima é um `DELETE+INSERT` limpo — JSON exigiria varrer todos os insumos p/ limpar chaves; (2) reuso do motor do catálogo (lê preço linha-por-edição); (3) integridade no banco (UNIQUE + FK). Escala do tenant é pequena → as filhas não crescem em demasia.

---

## 7. DDL (final — seguro dropar/recriar em dev)

```sql
DROP SCHEMA IF EXISTS tenant_catalogo CASCADE;
CREATE SCHEMA tenant_catalogo;

-- 1) FONTES próprias/externas do tenant
CREATE TABLE tenant_catalogo.fontes (
  fte_id            INTEGER GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
  fte_tenant_uuid   UUID NOT NULL,
  fte_codigo        TEXT NOT NULL,
  fte_nome          TEXT NOT NULL,
  fte_tipo          TEXT NOT NULL DEFAULT 'PROPRIA',      -- PROPRIA | EXTERNA
  fte_ativa         BOOLEAN NOT NULL DEFAULT TRUE,
  fte_criado_em     TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
  fte_atualizado_em TIMESTAMPTZ, fte_criado_por TEXT, fte_atualizado_por TEXT,
  CONSTRAINT uq_tcf_tenant_codigo UNIQUE (fte_tenant_uuid, fte_codigo),
  CONSTRAINT ck_tcf_tipo CHECK (fte_tipo IN ('PROPRIA','EXTERNA')),
  CONSTRAINT ck_tcf_codigo CHECK (btrim(fte_codigo) <> '')
);

-- 2) EDIÇÕES da fonte (sem UF padrão, sem pipeline; L.S. da edição p/ MO)
CREATE TABLE tenant_catalogo.edicoes (
  edi_id            INTEGER GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
  edi_tenant_uuid   UUID NOT NULL,
  edi_fte_id        INTEGER NOT NULL,
  edi_referencia    DATE NOT NULL,                        -- data efetiva da tabela de preços
  edi_codigo_versao TEXT,                                 -- número/rótulo livre ("184", "Tabela Jan/26")
  edi_ls_horista    NUMERIC(8,4),                         -- L.S. p/ MO (NULL = MO fica pelado)
  edi_situacao      TEXT NOT NULL DEFAULT 'RASCUNHO',     -- RASCUNHO | PUBLICADA | ARQUIVADA
  edi_criado_em     TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
  edi_atualizado_em TIMESTAMPTZ, edi_criado_por TEXT, edi_atualizado_por TEXT,
  CONSTRAINT fk_tce_fte FOREIGN KEY (edi_fte_id) REFERENCES tenant_catalogo.fontes(fte_id) ON DELETE CASCADE,
  CONSTRAINT uq_tce_fte_ref UNIQUE (edi_fte_id, edi_referencia),
  CONSTRAINT ck_tce_situacao CHECK (edi_situacao IN ('RASCUNHO','PUBLICADA','ARQUIVADA'))
);

-- 3) INSUMOS do tenant (UF vive aqui; sem ativo/inativo)
CREATE TABLE tenant_catalogo.insumos (
  ins_id            INTEGER GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
  ins_tenant_uuid   UUID NOT NULL,
  ins_fte_id        INTEGER NOT NULL,
  ins_ti_id         INTEGER NOT NULL,                     -- FK ao lookup GLOBAL (insumos_tipo)
  ins_codigo        TEXT NOT NULL,
  ins_descricao     TEXT NOT NULL,
  ins_unidade       TEXT NOT NULL,                        -- texto livre (sem FK unidades)
  ins_uf            CHAR(2) NOT NULL DEFAULT 'SP',        -- UF do insumo (o preço herda daqui)
  ins_criado_em     TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
  ins_atualizado_em TIMESTAMPTZ, ins_criado_por TEXT, ins_atualizado_por TEXT,
  CONSTRAINT fk_tci_fte FOREIGN KEY (ins_fte_id) REFERENCES tenant_catalogo.fontes(fte_id) ON DELETE CASCADE,
  CONSTRAINT fk_tci_ti  FOREIGN KEY (ins_ti_id)  REFERENCES catalogo.insumos_tipo(ti_id)  ON DELETE RESTRICT,
  CONSTRAINT uq_tci_fte_codigo_uf UNIQUE (ins_fte_id, ins_codigo, ins_uf),
  CONSTRAINT ck_tci_codigo CHECK (btrim(ins_codigo) <> '')
);

-- 4) PREÇO do insumo (UF herda do insumo; MO = pelado; cotação inline em JSONB)
CREATE TABLE tenant_catalogo.insumos_preco (
  pri_id            INTEGER GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
  pri_ins_id        INTEGER NOT NULL,
  pri_edi_id        INTEGER NOT NULL,
  pri_valor         NUMERIC(14,4),                        -- MO = PELADO (SE); demais = valor final
  pri_situacao      TEXT,                                 -- COM PREÇO | SEM PREÇO
  pri_origem        TEXT,                                 -- PROPRIA | PESQUISA | COTACAO | IMPORT
  pri_cotacoes      JSONB,                                -- [{empresa, site, telefone, email, responsavel, data, valor}]
  pri_criado_em     TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
  pri_atualizado_em TIMESTAMPTZ, pri_criado_por TEXT, pri_atualizado_por TEXT,
  CONSTRAINT fk_tcp_ins FOREIGN KEY (pri_ins_id) REFERENCES tenant_catalogo.insumos(ins_id) ON DELETE CASCADE,
  CONSTRAINT fk_tcp_edi FOREIGN KEY (pri_edi_id) REFERENCES tenant_catalogo.edicoes(edi_id) ON DELETE RESTRICT,
  CONSTRAINT uq_tcp UNIQUE (pri_ins_id, pri_edi_id),      -- grão: (insumo, edição) — UF vem do insumo
  CONSTRAINT ck_tcp_situacao CHECK (pri_situacao IS NULL OR pri_situacao IN ('COM PREÇO','SEM PREÇO'))
);

-- 5) COMPOSIÇÕES do tenant (sem situação/ativa)
CREATE TABLE tenant_catalogo.composicoes (
  cmp_id            INTEGER GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
  cmp_tenant_uuid   UUID NOT NULL,
  cmp_fte_id        INTEGER NOT NULL,
  cmp_codigo        TEXT NOT NULL,
  cmp_descricao     TEXT NOT NULL,
  cmp_unidade       TEXT NOT NULL,
  cmp_criado_em     TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
  cmp_atualizado_em TIMESTAMPTZ, cmp_criado_por TEXT, cmp_atualizado_por TEXT,
  CONSTRAINT fk_tcc_fte FOREIGN KEY (cmp_fte_id) REFERENCES tenant_catalogo.fontes(fte_id) ON DELETE CASCADE,
  CONSTRAINT uq_tcc_fte_codigo UNIQUE (cmp_fte_id, cmp_codigo),
  CONSTRAINT ck_tcc_codigo CHECK (btrim(cmp_codigo) <> '')
);

-- 6) ITENS da composição (ref polimórfica: global OU tenant, insumo OU composição)
CREATE TABLE tenant_catalogo.composicoes_itens (
  ci_id             INTEGER GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
  ci_cmp_id         INTEGER NOT NULL,
  ci_ref_origem     TEXT NOT NULL,                        -- CATALOGO | TENANT
  ci_ref_tipo       TEXT NOT NULL,                        -- INSUMO | COMPOSICAO
  ci_ref_id         INTEGER NOT NULL,
  ci_coeficiente    NUMERIC(14,10) NOT NULL,
  ci_uf             CHAR(2),                              -- UF só p/ precificar filho GLOBAL (tenant herda de ins_uf)
  ci_criado_em      TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
  ci_atualizado_em  TIMESTAMPTZ, ci_criado_por TEXT, ci_atualizado_por TEXT,
  CONSTRAINT fk_tcci_cmp FOREIGN KEY (ci_cmp_id) REFERENCES tenant_catalogo.composicoes(cmp_id) ON DELETE CASCADE,
  CONSTRAINT ck_tcci_origem CHECK (ci_ref_origem IN ('CATALOGO','TENANT')),
  CONSTRAINT ck_tcci_tipo   CHECK (ci_ref_tipo IN ('INSUMO','COMPOSICAO'))
);

-- 7) CUSTO da composição (cache; SEMPRE calculado; UF-agnóstico — 1 custo por (cmp, edição))
CREATE TABLE tenant_catalogo.composicoes_custo (
  cc_id             INTEGER GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
  cc_cmp_id         INTEGER NOT NULL,
  cc_edi_id         INTEGER NOT NULL,
  cc_custo          NUMERIC(14,4),
  cc_criado_em      TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
  cc_atualizado_em  TIMESTAMPTZ, cc_criado_por TEXT, cc_atualizado_por TEXT,
  CONSTRAINT fk_tccu_cmp FOREIGN KEY (cc_cmp_id) REFERENCES tenant_catalogo.composicoes(cmp_id) ON DELETE CASCADE,
  CONSTRAINT fk_tccu_edi FOREIGN KEY (cc_edi_id) REFERENCES tenant_catalogo.edicoes(edi_id) ON DELETE RESTRICT,
  CONSTRAINT uq_tccu UNIQUE (cc_cmp_id, cc_edi_id)
);

-- índices mínimos (tenant na frente p/ o isolamento)
CREATE INDEX ix_tcf_tenant   ON tenant_catalogo.fontes (fte_tenant_uuid, fte_ativa);
CREATE INDEX ix_tce_fte      ON tenant_catalogo.edicoes (edi_fte_id, edi_referencia DESC);
CREATE INDEX ix_tci_tenant   ON tenant_catalogo.insumos (ins_tenant_uuid, ins_codigo);
CREATE INDEX ix_tcp_ins_edi  ON tenant_catalogo.insumos_preco (pri_ins_id, pri_edi_id);
CREATE INDEX ix_tcc_tenant   ON tenant_catalogo.composicoes (cmp_tenant_uuid, cmp_codigo);
CREATE INDEX ix_tcci_cmp     ON tenant_catalogo.composicoes_itens (ci_cmp_id);
CREATE INDEX ix_tccu_cmp_edi ON tenant_catalogo.composicoes_custo (cc_cmp_id, cc_edi_id);
```

---

## 8. Decisões — CRAVADAS ✅

1. **FK global:** só `catalogo.insumos_tipo`. **Sem** FK p/ `unidades` (unidade = texto).
2. **Auditoria:** sem tabela; carimbo por linha; **único histórico = preço** (série por edição).
3. **Cotação:** JSONB inline `pri_cotacoes` `[{empresa, site, telefone, email, responsavel, data, valor}]`.
4. **Edição:** `referencia` DATE + `codigo_versao` TEXT; **sem `uf_padrão`**; import **mono-fonte**.
5. **UF:** vive no **insumo** (`ins_uf`), não no preço. Insumo único **(fonte, código, UF)**; preço por **(insumo, edição)**. **Composição é UF-agnóstica** (aceita filho de qualquer UF; sem `cc_uf` → 1 custo por composição/edição). Filho global precificado por `ci_uf` (item).
6. **Insumo:** sem `ativo`. **Composição:** sem `situação`/`ativa`.
7. **Custo:** composição **sempre calculada** (Σ), armazenada como cache; **sem importado**, sem conferência.
8. **L.S.:** MO pelado + `edi_ls_horista` (truncate SINAPI); demais valor final.
9. **Histórico:** filha (`insumos_preco`/`composicoes_custo`), **não JSON** (import idempotente + reuso do motor + integridade).
10. **Import por (fonte, edição, UF):** **idempotente** (put/update = `DELETE+INSERT` do escopo). Custo recalculado depois.
11. **Órfãs `ativo.orcamento_insumos*`:** marcar NÃO USADAS; reservar p/ preço-por-obra futuro.

> **Flags de controle mantidos** (baixa cardinalidade, úteis, não crescem): `fontes.fte_ativa` (liga/desliga a fonte) e `edicoes.edi_situacao` (rascunho→publicada). Se quiser tirar, é só falar.

> Ao seu OK final nas DDLs, aplico o DROP+CREATE no `schema.sql` (dev) + comentário nas órfãs, e sigo p/ o motor (`origem=TENANT`) + telas/CSV.
