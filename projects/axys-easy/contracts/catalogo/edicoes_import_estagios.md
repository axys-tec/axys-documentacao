# Edições — o que a app faz em cada estágio do import

> Referência **comportamental** (o que o código realmente executa), por fonte.
> Companheira do contrato [`IMPORT_ESTAGIOS.md`](IMPORT_ESTAGIOS.md) (que governa estados/cascata)
> e dos contratos por fonte (`CATALOGO_SINAPI/CDHU/FDE_IMPORT_CONTRACT.md`).
> Fonte da verdade do código: `backend/modules/catalogo/import_service.py`
> (tasks `importar_sinapi` / `importar_cdhu` / `importar_fde` / `importar_fde_novo` / `gerar_caderno_edicao`).

## Pipeline canônico (4 estágios)

```
preparar ──▶ precos ──▶ dados ──▶ documentos
(sobe/valida  (constrói   (docs      (caderno técnico
 /mapeia)      preços)     derivados)  + AxysDocs → publicável)
```

- **Cascata** (`estagios.py`): um estágio fica `pronto` quando TODOS os anteriores estão `ok`.
  `locked`/`pronto` são derivados; `rodando`/`ok`/`erro`/`pendente_user` são explícitos.
- **Suspensões** (`pendente_user`): **Preços** suspende quando há insumo SEM PREÇO (modal:
  informar ou publicar sem preço); **Documentos** suspende quando há **unidade a descrever** (gate 4 DURO).
- **Documentos** é task à parte (`gerar_caderno_edicao`) — o import termina no `dados`; o caderno é o fechamento.
- **Nomes internos legados**: SINAPI ainda usa `["preparar, precos, links, fichas, cadernos"]`
  (todos mapeiam a `dados` no painel canônico via `_ESTAGIO4_MAP`). CDHU/FDE já usam `preparar/precos/dados`.
- **FDE** tem dois modos: **dist** (`importar_fde`, parse-free de um ZIP já pronto) e
  **novo** (`importar_fde_novo`, 4 PDFs + 2 HTMLs + scrape do portal com login/senha). Onde diferem, há nota.

---

## Estágio 1 — PREPARAR

Sobe os arquivos ao worker, **trava contra arquivo trocado**, registra os **originais** e captura os
**documentos-fonte** (livros/notas/LS/fichas/cadernos), escreve o **MANIFESTO** (`_state/links.json`).
Não parseia preço. `estagio='preparar'` para aqui e destrava o Preços.

- **Trava anti-troca**: lê o carimbo de referência no próprio arquivo e compara com a edição informada —
  SINAPI = *Mês de Referência* em `B3`; CDHU = *Versão NNN* no topo; FDE = `manifest.json.edicao`.
  Não bate (ou não leu) → **aborta antes de tocar no banco**.
- **Manifesto** = NoSQL do estado dos docs (origem/status/key por doc); é o *driver* dos estágios seguintes
  (que leem os `pendente` e preenchem `key`+`status:ok`) e da tela **[ver manifesto]**.
- **Fichas-fonte** (`ISE!A9`, SINAPI): baixadas p/ ORIGINAIS e registradas aqui; o parse é no Dados.
- **Cadernos** (hyperlinks da aba CCD, SINAPI): são da **FONTE** (não por edição). O Preparar decide por
  **HTTP condicional (ETag)** o que mudou — `If-None-Match` → **304 ⇒ reusa (não baixa)**; só a versão
  nova é estacionada em `fontes/sinapi/cadernos/{slug}/`. O índice `cadernos/_versoes.json` governa o
  dedup; o parse (só das novas) é no Dados. Link morto ⇒ reusa o arquivado (não quebra o lote).
- **FDE-novo**: a **captura de preço** (scrape do portal) vive AQUI — a senha é efêmera (Redis `setex/getdel`)
  e só existe no Preparar; produz os CSVs que o Preços relê.

## Estágio 2 — PREÇOS

Constrói o preço da edição sob **advisory lock por fonte** (serializa contra *publicar* e contra outro import).
Faz snapshot + edição anterior (p/ o **diff**), roda a cadeia de parsers e fecha contando **insumos sem preço**.

- **Conferência** recalcula o custo das composições a partir de insumo×coeficiente×LS (e, no FDE,
  **des-BDIniza** o custo-fonte cru — BUSINESS_RULES §4.3).
- **Diff de edição** (`aplicar_diff_edicao`) marca novo/alterado/inalterado vs a edição anterior.
- **Fecha**: se sobrar insumo com `pri_valor IS NULL` → `pendente_user` (modal por-insumo, dedup por `ins_id`);
  senão `ok`. Status persistido em `_state/precos_pendentes.json`.

## Estágio 3 — DADOS

Documentos **derivados** (HTML por insumo/CPU), **parse do detalhamento de LS** (`els_itens`), vínculos,
`edi_docs_status` (libera "disponível p/ publicação") e **materialização dos prompts** `.md`
(`construcao/prompts/`, 1 por CPU) para o descritivo AXYS (enriquecimento fora do gating, via get_md→put_md).

- **LS detalhamento**: SINAPI lê o *Caderno de LS* vigente (flag marcada) ou o apêndice do *Cálculos e
  Parâmetros*; CDHU auto-identifica SD/CD nos PDFs. Doutrina: **header é canônico**, os itens são
  **fidelidade** do PDF → gravam mesmo com total divergente (aviso só p/ auditoria).
- **Cadernos** (SINAPI): parseia **só as versões novas** (as reusadas só re-ligam a edição — só DB);
  grava HTML/CPU fonte-level (`fontes/sinapi/cadernos/{slug}/`), registra doc de fonte (`doc_fte_id`/
  `doc_versao`/`doc_vigente`, arquiva anterior→`inativos`). **Commit + registro incrementais** (memória
  plana no worker 512MB + retomável).
- **Vínculo composição→caderno-fonte** (SINAPI): `composicao_documento` papel `caderno_fonte`,
  casando `doc_fte_id + doc_vigente` (não mais por edição) ao subgrupo por `unaccent(upper(...))`. N:N (escala p/ FDE).

## Estágio 4 — DOCUMENTOS  *(task `gerar_caderno_edicao`)*

**Gate 4 DURO**: `sincronizar_unidades` faz get-or-create das unidades da edição em `catalogo.unidades`;
se sobrar sigla **a descrever** (sem `un_descricao`), **trava** (`pendente_user`), escreve o `.md`
(`construcao/prompts/unidades_a_descrever`) + espelha no manifesto e **não gera o caderno**.
Passando o gate, monta o **caderno técnico da edição** (Apresentação + originais + encargos + [BDI] + CTCs),
sobe ao storage (`caderno_tecnico`, `no-cache`) e marca `documentos=ok` (**não purga os prompts**).

- **CTCs**: cada CTC abre **isolado** (`/axys-desc`); o caderno **aglomera** (índice), não embute.
- **Composição do caderno por fonte**: SINAPI = apres + originais + encargos + CTCs;
  CDHU = apres + encargos + CTCs; FDE = apres + encargos + **BDI** + CTCs.

---

## Matriz: passo × fonte

Legenda: ✅ faz · ⬜ não faz · 🅟 só neste modo. FDE = dist / novo (quando diferem).

### PREPARAR
| # | Passo | SINAPI | CDHU | FDE |
|---|-------|:------:|:----:|:---:|
| 1 | Baixa arquivos do storage p/ o worker (streaming) | ✅ 4 Excel | ✅ Excel(s) | ✅ ZIP dist / PDFs+HTML |
| 2 | Trava anti-arquivo-trocado | ✅ `B3` mês-ref | ✅ `Versão NNN` | ✅ `manifest.edicao` |
| 3 | Salva params do form (`salvar_params`) | ✅ | ✅ | ✅ |
| 4 | Registra ORIGINAIS (uploads) como doc | ✅ | ✅ | ✅ |
| 5 | Captura livros externos (metodologia / cálculos) → `sp.livro` + doc | ✅ | ⬜ | ⬜ |
| 6 | Captura notas (form) → originais + doc `nota` | ✅ | ⬜ | ⬜ |
| 7 | Captura Caderno de LS → originais + doc `leis_sociais` | ✅ (form) | ✅ (upload `ls_pdfs`) | ⬜ |
| 8 | Captura fichas-fonte (`ISE!A9`) → originais + doc `ficha_fonte` | ✅ | ⬜ | ⬜ |
| 9 | Captura cadernos técnicos (hyperlinks CCD) → originais + doc `caderno` | ✅ | ⬜ | ⬜ |
| 10 | Sobe originais do dist (PDFs) → doc `original` | ⬜ | ⬜ | ✅ |
| 11 | SCRAPE do portal (login/senha) → CSVs de preço no storage | ⬜ | ⬜ | 🅟 só **novo** |
| 12 | Escreve MANIFESTO (`_state/links.json`) | ✅ | ✅ | ✅ |
| 13 | Fecha Preparar em `ok` (resumo X/Y cadernos honesto) | ✅ | ✅ | ✅ |

### PREÇOS
| # | Passo | SINAPI | CDHU | FDE |
|---|-------|:------:|:----:|:---:|
| 1 | Advisory lock por fonte (`pg_advisory_xact_lock`) | ✅ | ✅ | ✅ |
| 2 | Snapshot de insumos + edição anterior (p/ diff) | ✅ | ✅ | ✅ |
| 3 | Parse **insumos** | ✅ | ✅ | ✅ |
| 4 | Parse **leis sociais** (header `els`) | ✅ (Referência) | ✅ (cabeçalho serviços + manual) | ✅ (CSV `parse_ls`) |
| 5 | Parse **composições** | ✅ | ✅ | ✅ |
| 6 | Parse **família / coeficientes** | ✅ | ⬜ | ⬜ |
| 7 | Parse **serviços SD/CD** (modalidades) | ⬜ | ✅ | ⬜ |
| 8 | Parse **custo-fonte** cru (com BDI, des-BDIniza depois) | ⬜ | ⬜ | ✅ |
| 9 | Parse **custos** | ✅ | ✅ (via conferência) | ✅ (via conferência) |
| 10 | Parse **BDI** | ⬜ | ⬜ | ✅ |
| 11 | **Conferência** (recalcula custo das composições) | ✅ | ✅ | ✅ |
| 12 | **Diff** de edição (novo/alterado/inalterado) | ✅ | ✅ | ✅ |
| 13 | Fecha: conta insumos SEM PREÇO → `pendente_user`/`ok` | ✅ | ✅ | ✅ |

### DADOS
| # | Passo | SINAPI | CDHU | FDE |
|---|-------|:------:|:----:|:---:|
| 1 | Reflete status dos docs vigentes (metodologia/cálculos/notas) em `docs_status` | ✅ | ⬜ | ⬜ |
| 2 | Parseia **LS detalhamento** (`els_itens`) | ✅ (Caderno LS ou apêndice Cálculos) | ✅ (`importar_cdhu_auto` SD/CD) | ⬜ (LS já veio no Preços) |
| 3 | **Fichas técnicas** → HTML/insumo → storage + `ins_external_path` + doc `ficha` | ✅ (`ISE`) | ⬜ | ✅ (`fichas_fde` catálogo+componentes) |
| 4 | **Cadernos/CPUs** → HTML/CPU → storage + `cmp_external_path` + doc `caderno_cpu` | ✅ | ⬜ | ⬜ |
| 5 | **Vínculo** composição→caderno-fonte (`composicao_documento`, papel `caderno_fonte`) | ✅ | ⬜ | ⬜ |
| 6 | **Critérios de medição** → HTML/CPU → doc `criterio` | ⬜ | ✅ | ⬜ |
| 7 | **LS PDFs inteiros** → docs (registrados no Preparar) | ⬜ | ✅ | ⬜ |
| 8 | Monta **requests do descritivo** AXYS (`_montar_requests_descritivo`) | ✅ | ✅ | ✅ |
| 9 | Grava `edi_docs_status` (libera "disponível p/ publicação") | ✅ | ✅ | ✅ |
| 10 | **Reindex** da busca | ⬜ | ✅ | ⬜ |
| 11 | Materializa **prompts** `.md` (`construcao/prompts/`) + fecha `dados` em `ok` | ✅ | ✅ | ✅ |

### DOCUMENTOS  *(gerar_caderno_edicao)*
| # | Passo | SINAPI | CDHU | FDE |
|---|-------|:------:|:----:|:---:|
| 1 | **get-or-create unidades** da edição (rede de segurança) | ✅ | ✅ | ✅ |
| 2 | **GATE 4 DURO**: unidade a descrever → `pendente_user` + `.md`/manifesto (bloqueia) | ✅ | ✅ | ✅ |
| 3 | Caderno: **Apresentação** (template + placeholders + tabela de unidades) | ✅ | ✅ | ✅ |
| 4 | Caderno: **Lista de originais** (livro/metodologia/nota) | ✅ | ⬜ | ⬜ |
| 5 | Caderno: **Encargos sociais** (tabelas LS A/B/C/D) | ✅ | ✅ | ✅ |
| 6 | Caderno: **BDI** | ⬜ | ⬜ | ✅ |
| 7 | Caderno: **CTCs** (índice; cada abre isolado via `/axys-desc`) | ✅ | ✅ | ✅ |
| 8 | Sobe caderno ao storage + doc `caderno_tecnico` (`no-cache`) | ✅ | ✅ | ✅ |
| 9 | `documentos=ok` → edição publicável (**não purga os prompts**) | ✅ | ✅ | ✅ |

---

## Estados & suspensões (resumo)

| Estágio | Suspende em `pendente_user` quando… | Como retoma |
|---------|--------------------------------------|-------------|
| Preços | há insumo SEM PREÇO (`pri_valor NULL`) | modal: informar preço **ou** publicar sem preço |
| Documentos | há **unidade a descrever** (fora do vocabulário canônico) | preencher o `.md` `unidades_a_descrever` (IA/manual) → `aplicar_md_unidades` → regerar |

> Enriquecimento do **descritivo** (CTC) é separado do gating: os prompts `.md` ficam em `construcao/prompts/`
> e são preenchidos por get_md→put_md (ou IA_auto) quando quiser — o AxysDoc reflete `cmp_descritivo`.
