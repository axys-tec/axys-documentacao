# Catálogo — Capability: Import (estágios + regras de importação)

**Status:** Contrato Canônico (v1.0 · 2026-07-14 — funde `IMPORT_ESTAGIOS` + `edicoes_import_estagios` + as regras de import do ex-`CATALOGO_BUSINESS_RULES` §2/§3.2/§3.3/§4.1/§6/§7/§9)
**Implementa:** `backend/modules/catalogo/estagios.py` (máquina de estados) · `backend/modules/catalogo/import_service.py` (tasks) · `backend/core/import_cpu/parser_*.py`. Coluna: `catalogo.edicoes.edi_estagios` (JSONB).
**Por fonte:** [sinapi.md](sinapi.md) · [cdhu.md](cdhu.md) · [fde.md](fde.md) · [sbc.md](sbc.md). **Modelo do dado importado:** [../listagem.md](../listagem.md).

> Governa **como cada fonte importa**: a máquina de estados dos 4 estágios (com cascata) e as regras de negócio do import (classificação, derivação de preço, conferência, situação, reimport, diff). Validado por `z_scripts_apoio/valida_amostra*.py` (Excel/CSV × banco, 0 divergências).

---

## PARTE A — Regras de importação (governança)

### A.1 Classificação de insumos
- **Todo insumo é classificado** (`insumos.ins_ti_id` NOT NULL). Tipos: `MO`, `ENC_COMP`, `EQUIP_AQ`, `EQUIP_LOC`, `MAT`, `SERV`, `ESP`, `NC`.
  - **`ENC_COMP`** = encargos complementares (EPI, ferramentas, transporte…): labor-add-on, **mas NÃO recebe leis sociais** (só o salário-base `MO` recebe — §A.2). É o que o distingue de `MO`.
- Origem (`ins_ti_origem`): **`FONTE`** (nativa confiável, ex.: SINAPI) · **`REGRA`** (léxico CDHU / fuzzy órfão SINAPI) · **`MANUAL`** (curadoria, nunca por parser).
- **Import bloqueia classificação sem tipo cadastrado:** classificação-de-fonte que não mapeia p/ nenhum `ti_codigo` → o import **aborta** (nada gravado), devolve p/ cadastrar o tipo. **Não inventa `NC`** p/ isso.
- **`NC`** = fallback controlado (não categoria técnica): permite import completo sem abortar quando regra/fuzzy não atinge confiança; entra em **fila de curadoria**; não alimenta histogramas gerenciais como tipo real.
- **Precedência no reimport — FONTE > MANUAL > REGRA** (garantida pelo parser no `ON CONFLICT`, não pelo banco): fonte classifica → prevalece (mesmo sobre `MANUAL`); fonte não classifica → `MANUAL` mantém, `REGRA`/`NC` reaplica regra/fuzzy. Cadastrais (descrição/unidade) **sempre** atualizam.

### A.2 Derivação SD/CD e arredondamento (ESPECÍFICO DA FONTE)
Insumo de **mão de obra**: `preco = ARRED( pelado × (1 + LS%/100), 2 )`, com `LS%` de `edicoes_leis_sociais` por (edição, UF, modalidade) e pela **unidade** (`H`→horista; `MES`→mensalista). O método `ARRED` é **o da fonte** — escolhido p/ casar **ao centavo**:
- **SINAPI — preço de insumo SD/CD e custo de composição: `trunc(2)`** em todas as etapas. (Ver [sinapi.md](sinapi.md).)
- **CDHU — custo de composição: `round half-up (2)` em duas passagens.** (Ver [cdhu.md](cdhu.md).)
- **FDE — custo publicado COM BDI**, base limpa `MO×(1+LS)+materiais`, trunc só no total. (Ver [fde.md](fde.md).)
- **SBC — catálogo emula a fonte:** linhas peladas arredondadas, LS aplicada
  sobre a soma das linhas MO e convergência auditável por centavos no modelo D.
  A bancada transformada continua no perfil uniforme TRUNC. Ver [sbc.md](sbc.md).

**A LS incide SÓ no salário-base (`ti=MO`).** `ENC_COMP`, `MAT`, `EQUIP_*`, `SERV`, `ESP` entram a **valor de face** (sem LS). **%AS** (montagem por UF de insumo sem preço na UF) = artefato de composição SINAPI (ver [sinapi.md](sinapi.md)).

**SE é SEMPRE emitido em `composicoes_custo` (custo nunca zera).** `SE` (pelado, LS=0) é a **base de de/recomposição**, não o regime de orçamento. Como o pelado está 100% em `insumos_preco` (SE-only), `calcular_custos` **sempre emite SE**; SD/CD entram quando há LS. Ex.: edição só-SD (CDHU/FDE) ainda tem custo (SD conferido + SE **DERIVADO**).

### A.3 Leis sociais (`edicoes_leis_sociais`)
- LS por (edição, UF, modalidade ∈ {SD, CD}) — **não** se grava `SE` (SE=0% implícito). `els_horista`/`els_mensalista` em percentual (`14,2`), ÷100 no cálculo.
- **Fonte:** SINAPI = cabeçalhos dos arquivos SD e CD (por UF, horista/mensalista); CDHU = cabeçalho de cada arquivo de serviços (SD e CD), um % horista por regime; FDE = CSV do dist.
- **Sanidade:** LS real é alta (>100% típico); fração (~1,28) deve ser normalizada/abortada.

### A.4 Conferência (calculado × fonte) — validação em DUAS camadas
- **Modalidades:** `SD`, `CD` (com LS) **e `SE`** (pelado). `composicoes_custo` guarda as três p/ consulta direta. **INVARIANTE: toda edição tem `SE`** (publicado — SINAPI aba CSE — ou `DERIVADO`); é a base pelada que permite o orçamento **rotacionar a LS**.
- Após o import, p/ cada (composição, UF, modalidade): calcula `cc_custo_calculado` (com a LS oficial) e compara com `cc_custo_fonte`. **Se a edição tem BDI publicado (`edicoes_bdi`), compara contra `cc_custo_fonte ÷ (1 + ebd_percent/100)`** (des-BDInizado — [fde.md](fde.md)); senão, contra o fonte cru. **Limiar:** `|dif|` ≤ **0,5%** (ou ≤ R$0,01) → `DIVERGENTE_ARREDONDAMENTO`; acima → `DIVERGENTE_RELEVANTE`.
- **Camada 1 (interna):** `cc_custo_fonte` × `cc_custo_calculado` (ambos do MESMO parse) — não pega bug de parse do próprio Excel.
- **Camada 2 (externa/independente):** `z_scripts_apoio/valida_amostra.py` (SINAPI), `valida_amostra_cdhu.py` (CDHU, Excel×DB) e `valida_amostra_fde.py` (FDE, CSV×DB dentro do dist.zip) — releem o fonte com leitor **próprio** (não o parser) e comparam com o banco. Tolerância ±R$0,01. Pegam a classe de bug que a interna não vê.
- **Trava do e2e:** `e2e_sinapi.py`/`e2e_cdhu.py` reprovam (rc=1) se qualquer estágio ficar em `erro` **ou** se o caderno vier com `n_itens < MIN` (mata o falso-verde de edição vazia).

### A.5 Situação — DECLARADA (fonte) × DERIVADA (nós), por fonte
Situação é **`CHECK`-text** (a tabela `catalogo.situacoes` foi **dropada** 2026-07-14): `insumos_preco.pri_situacao ∈ {'COM PREÇO','SEM PREÇO'}`; composição `cmp_situacao`/`ci_situacao ∈ {'COM CUSTO','SEM CUSTO','SUSPENSO','EM ESTUDO'}`.

| Campo | CDHU | SINAPI |
|---|---|---|
| **Situação do PREÇO** por UF (`pri_situacao`) | **Derivada por nós** (presença do custo). CDHU só publica COM PREÇO. | **Derivada por nós** por UF (presença da célula ISE). |
| **Situação do ITEM/COMPOSIÇÃO** | **Computada por nós** (CDHU não declara; vem do cálculo). | **Declarada pela fonte** (coluna "Situação" do Analítico → verbatim). |
| **Custo calculado + conferência** | Nosso. | Nosso. |

> A situação guardada é a declarada; a situação **efetiva** (p/ cálculo) é derivada em runtime, não confiada cegamente. *(A separação limpa declarada×efetiva no lado composição segue como refino futuro, sem gatilho.)*

### A.6 Política de reimport
- **Insumos:** upsert (identidade vigente); classificação pela precedência §A.1; cadastrais sempre atualizam.
- **Preços / composições / itens / custos:** densos por edição — reimport da mesma (chave, edição) é **idempotente** (regravados iguais).
- **Reimport da MESMA edição** requer `rebuild` antes (senão a linha superada apareceria como `REATIVACAO`). Imports novos / fora de ordem estão corretos.

### A.7 Diff / época (evolução entre edições)
No import, após parsear e antes de gravar: "já existe?" → sim ⇒ computa diff e grava em `*_historico`; não ⇒ `CRIACAO`.
- **Diff por PRESENÇA em `edi_prior`** (edição imediatamente anterior COM DADOS) — **não** pelo flag de ativo (a vigência só é decidida no PUBLICAR; no import tudo nasce inativo). Ausente em `edi_prior` + presente agora → `REATIVACAO`; presente antes + ausente agora → `INATIVACAO`; em ambas → compara conteúdo; nunca existiu → `CRIACAO`. Implementação: `aplicar_diff_edicao` (compartilhado SINAPI/CDHU/FDE).
- **"Alteração verdadeira"** = só **descrição**, **unidade**, **coeficiente/itens**. **`null` ≠ alteração** (é dado que faltava naquela época). **Situação NÃO é gatilho** de alteração (é metadado de presença; se mudar por causa real, o gatilho é a mudança de itens).
- **Reconciliação SINAPI:** SINAPI-Diff (`sinapi_manutencoes`, changelog publicado) × Axys-DIFF (série computada) — a app apresenta ambos e reconcilia. CDHU/FDE não publicam changelog → só Axys-DIFF.

---

## PARTE B — Máquina de estados (`edi_estagios`)

### B.1 Estágios (ordem fixa) — `preparar → precos → dados → documentos`
| Estágio | Faz | Fecha quando |
|---|---|---|
| **preparar** | Sobe originais (privado) + trava anti-arquivo-trocado + captura docs-fonte + MANIFESTO (`_state/links.json`) | upload + mapa ok |
| **precos** | Constrói preços (advisory lock por fonte) + conferência + diff | docs suficientes → auto; senão `pendente_user` |
| **dados** | Docs derivados (HTML/insumo/CPU) + LS detalhamento + `edi_docs_status` + prompts `.md` | retornos gravados |
| **documentos** | `gerar_caderno_edicao`: gate de unidades + caderno técnico da edição + CTCs | caderno pronto → publicável |

### B.2 Estados & cascata
Estados: `locked` · `pronto` · `rodando` · `ok` · `erro` · `pendente_user`.
- **Cascata (invariante):** um estágio fica `pronto` sse **todos os anteriores == `ok`**. `preparar` (entrada) nunca fica `locked`. `locked`/`pronto` são **derivados** (recalculados a cada escrita, `_aplicar_cascata`); `rodando`/`ok`/`erro`/`pendente_user` são **explícitos** (a cascata nunca os sobrescreve). Estágio anterior que regride → posteriores voltam a `locked`.
- **`documentos == ok` ⇒ edição disponível para publicação.**
- **Suspensões (`pendente_user`):** **Preços** suspende quando há insumo SEM PREÇO (modal: informar / publicar sem preço); **Documentos** suspende quando há **unidade a descrever** (gate 4 DURO).
- **API (`estagios.py`):** `get_estagios(edi_id)` (cascata aplicada; NULL→default `preparar=pronto`, resto `locked`) · `set_estagio(edi_id, nome, estado, detalhe, job_id)` (grava + carimbo `em` UTC + reaplica cascata) · `disponivel_para_publicar(edi_id)` (`documentos==ok`).
- **Shape** (JSONB): cada estágio `{estado, job_id, em, detalhe}`.
- **Nomes internos legados:** SINAPI ainda usa `["preparar, precos, links, fichas, cadernos"]` (todos mapeiam a `dados` via `_ESTAGIO4_MAP`); CDHU/FDE já usam `preparar/precos/dados`.

---

## PARTE C — Comportamento por estágio (o que o código executa)

> Fonte da verdade: `import_service.py` (tasks `importar_sinapi`/`importar_cdhu`/`importar_fde`/`importar_fde_novo`/`gerar_caderno_edicao`). **FDE** tem 2 modos: **dist** (ZIP pronto) e **novo** (PDFs+HTML+scrape do portal).

### PREPARAR
Sobe ao worker, trava anti-troca, registra originais, captura docs-fonte, escreve o manifesto. Não parseia preço.
- **Trava anti-troca:** SINAPI = *Mês de Referência* em `B3`; CDHU = *Versão NNN* no topo; FDE = `manifest.json.edicao`. Não bate → **aborta antes de tocar no banco**.
- **Manifesto** (`_state/links.json`) = estado dos docs (origem/status/key); *driver* dos estágios seguintes + da tela [ver manifesto].
- **Cadernos SINAPI** (hyperlinks da CCD) são da **FONTE** (não por edição): dedup por **HTTP condicional (ETag)** — `If-None-Match` → **304 ⇒ reusa (não baixa)**; só a versão nova estaciona em `fontes/sinapi/cadernos/{slug}/`. Índice `cadernos/_versoes.json` governa; link morto ⇒ reusa o arquivado.
- **FDE-novo:** o **scrape do portal** (senha efêmera Redis `setex/getdel`) vive AQUI e produz os CSVs que o Preços relê.

### PREÇOS
Advisory lock por fonte (serializa contra *publicar* e outro import). Snapshot + edição anterior (diff), cadeia de parsers, fecha contando insumos sem preço.
- **Conferência** recalcula custo (insumo×coef×LS); no FDE **des-BDIniza** o custo-fonte cru (§A.4).
- **Diff** (`aplicar_diff_edicao`) marca novo/alterado/inalterado vs `edi_prior` (§A.7).
- **Fecha:** sobrou `pri_valor IS NULL` → `pendente_user` (modal por-insumo, dedup `ins_id`, em `_state/precos_pendentes.json`); senão `ok`.

### DADOS
Docs **derivados** (HTML/insumo/CPU), parse do **LS detalhamento** (`els_itens`), vínculos, `edi_docs_status` (libera "disponível p/ publicação") e **materialização dos prompts** `.md` (`construcao/prompts/`, 1 por CPU, p/ o descritivo AXYS via get_md→put_md).
- **LS detalhamento:** header é canônico, itens são fidelidade do PDF (gravam mesmo com total divergente; aviso só p/ auditoria).
- **Cadernos SINAPI:** parseia **só as versões novas** (reusadas só re-ligam a edição); grava HTML/CPU fonte-level, registra doc de fonte (arquiva anterior→`inativos`), **commit incremental** (worker 512MB, retomável).
- **Fichas/cadernos → identidade:** ficha → `ins_external_path`; caderno_cpu → `cmp_external_path` (vigência por versão — [../publicacao.md](../publicacao.md)). ⚠️ **Pendência:** o vínculo composição→caderno-fonte / fichas FDE é **N:N** e usava `composicao_documento` (dropada no repense doc/path); a modelagem N:N está **deferida** (o §11.9 do repense reserva o `composicao_documento` p/ esse "cross-ref real").

### DOCUMENTOS (`gerar_caderno_edicao`)
- **GATE 4 DURO:** `sincronizar_unidades` (get-or-create em `catalogo.unidades`); sigla **a descrever** (sem `un_descricao`) → **trava** (`pendente_user`) + `.md` `unidades_a_descrever` + manifesto, **não gera o caderno**. Retoma: preencher o `.md` → `aplicar_md_unidades` → regerar.
- Passando: monta o **caderno técnico da edição** (Apresentação + [originais] + Encargos + [BDI] + CTCs), sobe ao storage (`caderno_tecnico`, `no-cache`), `documentos=ok` (**não purga os prompts**).
- **CTCs** abrem **isolados** (`/axys-desc`); o caderno **aglomera** (índice), não embute. Composição por fonte: SINAPI = apres+originais+encargos+CTCs; CDHU = apres+encargos+CTCs; FDE = apres+encargos+**BDI**+CTCs.

### Matriz passo × fonte (resumo)
> A matriz detalhada (13 passos de PREPARAR, 13 de PREÇOS, 11 de DADOS, 9 de DOCUMENTOS × SINAPI/CDHU/FDE) segue no código (`import_service.py`) como fonte da verdade comportamental. Diferenças-chave: SINAPI captura livros/notas/fichas/cadernos + família/coeficientes (%AS); CDHU parseia serviços SD/CD + critérios + LS PDFs; FDE parseia custo-fonte cru (BDI) + BDI e, no modo **novo**, faz o scrape do portal.
