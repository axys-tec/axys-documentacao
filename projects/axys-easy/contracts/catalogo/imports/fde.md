# Catálogo — Contrato de Importação FDE

**Status:** Contrato Canônico (v1.0 · 2026-07-15 — completo: dados + BDI/LS + **documentos técnicos**)
**Fonte-base:** FDE — Fundação para o Desenvolvimento da Educação (SP).
**Índice das capabilities:** [../README.md](../README.md). **Espelhos:** [cdhu.md](cdhu.md) · [sinapi.md](sinapi.md). **Onde os docs moram:** [../publicacao.md](../publicacao.md).

> Implementação: `backend/core/import_cpu/parser_fde.py` (parser Fase-2, validado — `valida_amostra_fde.py`) + `backend/core/import_cpu/fichas_fde.py` + estágio DADOS de `importar_fde`. **Este contrato GOVERNA; o código o persegue** — onde o código de hoje diverge, o contrato é a verdade.

---

## 0. Origem dos dados
Extração feita FORA do app (sandbox `z_search_repos/find_fde/`), produzindo CSVs no formato-alvo (`tabela_insumos.csv`, `tabela_composicoes.csv`, `tabela_servicos.csv`, `fde_catalogo_extraido.csv`, `fde_componentes_extraido.csv`, `saida_fichas/fichas_vinculo.csv`). **Esses CSVs são a fonte de verdade da carga.** A extração das fichas foi via **curl do HTML do portal** (`fde_catalogo.html`); o que o portal expõe é o teto do que se importa (ver §7.5, incompletude de origem).

## 1. Características da fonte
- **Mono-UF** (São Paulo); MO **horista**. Edição por mês.
- **PUBLICA CUSTO COM BDI EMBUTIDO** — raro (SINAPI/CDHU publicam sem BDI) → §2.
- Publica **Leis Sociais** e **BDI** em PDF (§4, §5).
- **Publica os docs técnicos em formato de PRANCHA (PDF), não em doc-texto** — isso muda a estratégia de CTC (§7.6).

## 2. BDI — a regra que diferencia a FDE
`cc_custo_fonte` guarda o **publicado CRU (COM BDI)** — nunca se limpa (auditoria ao centavo). `cc_custo_calculado` = Σ itens×coef + LS = **LIMPO** (o que a app exibe e o orçamento usa). O BDI é **uniforme** (família toda) → `catalogo.edicoes_bdi`; a **presença** dessa linha sinaliza "fonte com BDI". A des-BDInização (`cc_custo_fonte ÷ (1+ebd_percent/100)`) é só no **momento de comparar/exibir** — a conferência compara o calculado contra o fonte des-BDInizado (senão toda linha marca DIVERGENTE pelo BDI). Método FDE: precisão cheia, trunc só no total (`fonte = trunc2(base×(1+BDI))`, base = MO×(1+LS)+materiais; só `MO` recebe LS). Ref: `fde_precifica_composicoes_diff.py`. Regra transversal em [estagios.md §A.4](estagios.md).

## 3. Preço / custo
Segue as regras globais ([../listagem.md §2](../listagem.md) · [estagios.md](estagios.md)): insumo preço NULL quando ausente (nunca 0); `pri_situacao` derivado; identidade CAIXA ALTA; idempotente por edição. BDI **não** incide sobre insumo (só serviço/composição).

## 4. BDI publicado → `catalogo.edicoes_bdi`
Header `ebd_` (edi_id, uf, classe NORMAL|REDUZIDO, regime, `ebd_percent`, UNIQUE edi+uf+classe) + parcelas `ebdc_` (Acórdão 2622/2013). Serve de referência + default do `ativo_bdi` quando o orçamentista usa FDE. Não aplicado ao custo de consulta.

## 5. Leis Sociais
`catalogo.edicoes_leis_sociais` (`els_`) + `_itens` (`elsi_`), padrão SINAPI/CDHU. O PDF inteiro de LS entra como **documento** de edição (não parseado).

## 6. Reimport
Idempotente por edição (`pg_advisory_xact_lock(fte_id)`); reimportar substitui, não duplica.

---

## 7. Documentos técnicos da FDE

> A FDE **não tem** um caderno técnico 1:1 por CPU como SINAPI (`caderno_tecnico`) / CDHU (`criterio_medicao`). Tem **2 catálogos** de docs externos, com **vínculo N-para-CPU já extraído**. Por isso a **CTC (AxysDoc)** existe — padroniza e referencia esse conjunto. O destino de cada doc segue o **princípio de dominialidade** ([../publicacao.md](../publicacao.md)): spec-de-CPU → composição · spec-de-insumo → insumo · genérico de fonte → `documentos`.

### 7.1 Os 2 catálogos
- **Catálogo de SERVIÇOS** (`fde_catalogo_extraido.csv`) — **hierárquico por disciplina** (`S`=civil, `H`=hidráulica, `E`=elétrica, `G`=generalidades/sustentabilidade). **32 códigos nível-1** = as **ETAPAS de obra** (S1=MOVIMENTO DE TERRA, H2=ÁGUA FRIA, E1=ENTRADA DE ENERGIA…) — são **cabeçalho/agrupador**, não spec. **~191 nível-2** = os serviços de fato (S1-01=Aterro…), que mapeiam CPU.
- **Catálogo de COMPONENTES** (`fde_componentes_extraido.csv`) — ~100 componentes físicos (`AC`,`AE`,`BR`,`CA`…: abrigo, entrada de energia…).

### 7.2 Vínculo ficha↔CPU — JÁ EXTRAÍDO (`saida_fichas/fichas_vinculo.csv`)
Não se recalcula no import — lê-se deste CSV: colunas `ficha_codigo, ficha_tipo (SERVICO|COMPONENTE), item_id, version, filename, pdf_url, cpu_codigo, origem`.
- **Cardinalidade:** ficha→CPU é **1:N** (média ~4,5 CPU/ficha, máx 78); CPU→ficha é **quase 1:1** (média ~1,1; só ~6% das CPUs têm >1 ficha). **Não é N:N fundamental** — é 1:N com cauda de N:N. A cardinalidade **não decide o lugar** (o domínio decide, §7.3).
- **Comportamento DIVERGE por catálogo:**
  - **Serviço** casa **só por token** `NN.NN.NNN` no texto do PDF → **PODE orfanar** (as etapas nível-1, que são cabeçalho sem token; + alguns nível-2 não-mapeados).
  - **Componente** casa por token **OU text-match** (o código `AC-04`… procurado na descrição da CPU) → **NUNCA orfana** (100% vinculados; é peça física intrínseca a alguma CPU). `origem ∈ {ficha, textmatch}`.

### 7.3 Onde cada doc mora (dominialidade)
| Doc FDE | Domínio | Lugar |
|---|---|---|
| ficha de **serviço** (spec-de-CPU) | composição | `cmp_external_path.caderno_tecnico.descritivo_tecnico` |
| ficha de **componente** | composição | `cmp_external_path.caderno_tecnico.detalhe_tecnico` |
| **G** (generalidades/sustentabilidade — §7.5) | genérico de fonte | `catalogo.documentos` (`referencia`) |
| CTC (AxysDoc) | composição (autoral AXYS) | `cmp_external_path.ctc` |

`descritivo_tecnico` = a linha textual/spec (serviços FDE · caderno SINAPI · critério CDHU — mesma casa multifonte, ver [../publicacao.md](../publicacao.md)); `detalhe_tecnico` = componente (**só FDE**; null nas outras fontes).

### 7.4 Agrupamento em storage (único-doc, versionado, path determinístico)
Como uma ficha serve ~4,5 CPUs, **NÃO se expandem os paths de ficha dentro de cada CPU** (inflaria o JSON e feriria fonte-única). Em vez disso:
- **Ficha PDF guardada UMA vez**, path determinístico por código: `easy/fontes/fde/{edicao}/fichas/{servico|componente}/{cod}_{data}.pdf`. **Versionada:** a ficha carrega a data no nome (`S101_20_08_02`); ao mudar, o anterior vai pro `_old/` (TUDO tem versionamento).
- **O vínculo CPU→fichas é UM JSON em storage** (edição-scoped, determinístico), gerado do `fichas_vinculo.csv`:
  ```jsonc
  // easy/fontes/fde/{edicao}/fichas_agrupamento.json
  { "11.02.066": { "descritivo": ["S10","S10-04","S10-05","S15","S15-01"],
                   "detalhe":    [] }, … }
  ```
  Os **cabeçalhos (S10, S15) entram de graça** — são o prefixo do código; dão o agrupamento por etapa sem storage extra.
- **`cmp_external_path` do CPU FDE NÃO guarda os paths** — resolve por dedução: `cmp_fte_id=FDE` + edição → o `fichas_agrupamento.json` (path determinístico) → `grouping[cpu]` → códigos → paths de ficha determinísticos. O único NÃO-derivável (a linha do tempo `_old`/data da ficha) mora **uma vez** no agrupamento/catálogo, não por-CPU. **Sem `fonte` no JSON** (deriva de `cmp_fte_id`).

### 7.5 G — Generalidades / Sustentabilidade (o outlier → `documentos`)
A letra **G** é o guarda-chuva **ambiental/sustentabilidade** (todo doc marcado "eco"), **não** spec-de-CPU:
- **G1 (Gestão de Madeira):** legislação de madeira legal (CADMADEIRA, Decreto Estadual 53.047/2008) + fichas botânicas de espécies (nome científico, ocorrência, densidade). É **referência-standalone** → `catalogo.documentos` (`doc_tipo='referencia'`, fonte/edição-level).
  - **Associação a CPU = regra DERIVADA, não stored:** qualquer CPU cuja descrição contenha **"madeira"** (exceto grupo **Demolições**) → exibe G1. Text-match no read (ADR-022: nada guardado).
  - **Incompletude de origem (registrar como AVISO, não erro):** o doc G1 promete 40 espécies (G1.01–G1.40), mas o **portal público só publica 9** (Açacu…Bacuri, alfabético até "B"). Não é falha de download — as G1-10…G1-40 **não existem** no `fde_catalogo.html`. O import pega as que existem; **não** espera 40 nem marca erro. (Import aditivo captura naturalmente se a FDE publicar mais.)
- **G2 (Retrofit de lâmpadas/luminárias):** tem serviços que **mapeiam CPU** → tratado como serviço normal (§7.3, `descritivo_tecnico`), **não** vai pra documentos.

### 7.6 CTC (AxysDoc) — PDF nativo + pareamento de IA
- **A ficha FDE exibe-se como PDF NATIVO** (prancha) — link externo, aberto como é. Difere de SINAPI/CDHU (HTML parseado) **porque a FDE publica em prancha, não em doc-texto**. Em prática: **só ao abrir a ficha há link externo**.
- **O parse do PDF é EXCLUSIVO para o prompt de IA** (gerar o CTC), nunca para display.
- **Pareamento (dedup) obrigatório:** como uma ficha serve ~4,5 CPUs, montar o request por-CPU repetiria a mesma ficha. Estratégia: **parseia cada ficha ÚNICA uma vez → md** (`.../fichas/_md/{cod}.md`, cache dedup **por código**); o request do CTC de cada CPU **monta a partir do md** já pronto (pardear inteira, chamar o md depois). Zero re-parse da ficha compartilhada.
- O CTC resultante vive em `cmp_external_path.ctc` (autoral AXYS, versionado por `delta:hash`; prompt/doc só em storage — [../publicacao.md](../publicacao.md)).

---

## 8. Definição de pronto (anti-regressão)
- Contagens batendo (insumos/composições == CSVs de `find_fde`).
- `cc_custo_fonte` cru (com BDI) · `cc_custo_calculado` limpo · `edicoes_bdi` populado · conferência des-BDInizada (amostral) → `valida_amostra_fde.py` 0 divergências.
- Docs: `fichas_agrupamento.json` gerado do `fichas_vinculo.csv`; fichas únicas no storage (por código, `_old` no versionamento); `descritivo_tecnico`/`detalhe_tecnico` resolvem via agrupamento; G1 em `documentos` + regra "madeira"; CTC do md deduplicado; PDF nativo no display.
- **SINAPI e CDHU inalterados** (o mesmo campo `caderno_tecnico`/`descritivo_tecnico` multifonte não pode regredir).
- Trabalho em branch + PR para revisão humana.
