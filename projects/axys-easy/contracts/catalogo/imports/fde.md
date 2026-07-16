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
  - **Serviço** nível-2 (folha) casa **por token** `NN.NN.NNN`. O **cabeçalho de etapa (nível-1) NÃO é sobra** — **cascateia COMUNITÁRIO** p/ a **união dos CPUs dos seus filhos** (materializado no mapeamento, `origem=cascata`); igual a G1-família cascateia por regra (§7.5). **Órfão real = só folha sem match** (fica *pendente de vínculo* — curadoria/transitivo, não vai pra documentos).
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
  - **Associação a CPU = materializada no MAPEAMENTO PRELIMINAR** (não derivada a cada read): a regra "CPU cuja descrição contenha **madeira** (exceto grupo **Demolições**) → G1" roda **junto do mapeamento de fichas** (§7.2, o passo que gera o `fichas_vinculo`/agrupamento, preliminar aos estágios/paths) e entra no `fichas_agrupamento.json` como as demais. Assim é determinística e pronta antes do import — não um text-match em runtime. (ADR-022: computado uma vez, mora na grouping em storage, não no banco.)
  - **Incompletude de origem (registrar como AVISO, não erro):** o doc G1 promete 40 espécies (G1.01–G1.40), mas o **portal público só publica 9** (Açacu…Bacuri, alfabético até "B"). Não é falha de download — as G1-10…G1-40 **não existem** no `fde_catalogo.html`. O import pega as que existem; **não** espera 40 nem marca erro. (Import aditivo captura naturalmente se a FDE publicar mais.)
- **G2 (Retrofit de lâmpadas/luminárias):** tem serviços que **mapeiam CPU** → tratado como serviço normal (§7.3, `descritivo_tecnico`), **não** vai pra documentos.

### 7.6 CTC (AxysDoc) — PDF nativo + pareamento de IA
- **A ficha FDE exibe-se como PDF NATIVO** (prancha) — link externo, aberto como é. Difere de SINAPI/CDHU (HTML parseado) **porque a FDE publica em prancha, não em doc-texto**. Em prática: **só ao abrir a ficha há link externo**.
- **O parse do PDF é EXCLUSIVO para o prompt de IA** (gerar o CTC), nunca para display.
- **Pareamento (dedup) obrigatório:** como uma ficha serve ~4,5 CPUs, montar o request por-CPU repetiria a mesma ficha. Estratégia: **parseia cada ficha ÚNICA uma vez → md** (`.../fichas/_md/{cod}.md`, cache dedup **por código**); o request do CTC de cada CPU **monta a partir do md** já pronto (pardear inteira, chamar o md depois). Zero re-parse da ficha compartilhada.
- O CTC resultante vive em `cmp_external_path.ctc` (autoral AXYS, versionado por `delta:hash`; prompt/doc só em storage — [../publicacao.md](../publicacao.md)).

### 7.7 Resolução de vínculo ficha→CPU e CURADORIA de órfãs
Separar **ficha-header** (etapa, cascata §7.2) da **ficha-serviço efetiva** (folha). Para a folha, o vínculo é uma **cascata de tentativas**:
1. **Token** `NN.NN.NNN` no texto do PDF — resolve o grosso (serviço folha + componente).
2. **Text-match** — componente: código do componente (`AE-21`) na descrição da CPU.
3. **Cascata comunitária** — cabeçalho de etapa → união dos CPUs dos filhos; G1-família → regra madeira (§7.5).
4. **Órfã → CURADORIA MANUAL** (nem silêncio, nem auto-match ruidoso). Princípio: **o item EXISTE** — a fonte é que está defeituosa (descrição diverge: "DISPENSER" na ficha × "SABONETEIRA DE LOUÇA" na CPU; ou PDF-fonte quebrado/placeholder). **Não existe "erro propositivo"** — é vínculo humano.
   - **Mecânica (= capability [../vinculacoes.md](../vinculacoes.md)) — carry-forward IDEMPOTENTE com change-check:** o user associa a(s) CPU(s) pós-import. Em **novo import**: se o **doc não mudou** (sha da ficha) **E a descrição não mudou** (ficha + CPU) → a associação manual **persiste sozinha, SEM incomodar o user**. Se **mudou qualquer coisinha** (sha do doc ou descrição) → o vínculo entra no **MANIFESTO** — *"não deu match · última associação = X · confira"* — pra re-confirmação (e2e/user). Mesmo espírito do ETag/sha dos cadernos: o vínculo humano é **durável e re-conferido só quando algo muda**, nunca recomputado do zero.
   - Descrição-match automática de **serviço** é **RUÍDO** (74 falsos p/ "corrugado", 17 p/ "elevador") → **não** se auto-associa serviço por descrição; vai pra curadoria.
- **Motivo da órfã (registrar — alimenta a curadoria):** `fonte_pdf_quebrado` (S16/H1: filename "-" no HTML FDE) · `fonte_imagem` (S8: prancha sem camada de texto) · `placeholder_XX` (H6-01: códigos não preenchidos) · `prosa_sem_codigo` (descreve, não cita CPU). **Nenhum é erro nosso** — é defeito da fonte, resolvido por curadoria.
- **Curadoria CODIFICADA (regras duráveis — `fde_transform._CURADORIA_ORFAS`):** as órfãs recorrentes cujo vínculo JÁ foi curado (Renan, lido da Sintética) viram **REGRA por ficha** — aplicadas após as cascatas (§7.2), `origem=curadoria`, **não recuram a cada import nem voltam como órfã**. As 7 conhecidas → **0 órfã**:
  - **S16 / S16-01** (elevador) → CPUs `ELEVADOR%` ou `MANUTENCAO…ELEVADOR%` (instalação **e** manutenção; subgrupo 16.20).
  - **S5-03 / S5-06** (revestimento contra fogo) → CPUs `%CORTA-FOGO%` (porta corta-fogo).
  - **E2-07** (eletroduto corrugado) → `ELETRODUTO…CORRUGADO` / `ELETRODUTO EM POLIETILENO`.
  - **S17-01** (ferragens p/ portas) → CPUs com código de componente `PF-`/`PM-` (portas de ferro/madeira).
  - **H6-01** (acessórios de louça) → subgrupos `08.15`/`08.16` (louça sanitária).
  Órfã NOVA (fora dessas 7) segue o fluxo normal: curadoria manual + carry-forward change-check.

---

## 8. Dois caminhos de import — `old-fde` (dist) × `4-26+` (UI)

**Singularidade da FDE:** todas as edições **exceto a última** entram no banco **sem doc técnico** (só dados) — por isso os `dist`. Só a **última (a partir de 04/2026)** recebe o processamento completo de docs (2 HTMLs → CSVs → fichas → agrupamento → CTC).

**O pipeline é `TRANSFORMAR → PROCESSAR`** (dois estágios lógicos); os 2 caminhos diferem só em **onde entram**:

| Caminho | Entrada | UI? | Estágios | Docs |
|---|---|---|---|---|
| **`old-fde`** (histórico/seed) | **`dist.zip`** (já transformado) | **E2E** (in-app, sem tela) | **pula lê+transforma → PROCESSA direto** | dados-only (sem fichas/agrupamento) |
| **`4-26+`** (edição vigente) | **conjunto de arquivos** (2 HTMLs + PDFs + CSVs) | **sim** (tela) | **lê → TRANSFORMA → PROCESSA** | completos (fichas + agrupamento + CTC) |

> **É UM pipeline só, ambos DENTRO da app.** `old-fde` não é mecanismo diferente — é o **mesmo `PROCESSA`** alimentado com dado já-transformado (o `dist.zip` pula as 2 primeiras fases). Roda **via E2E** (não `.apply()` eager num script fora da app): os HTMLs **não servem por edição antiga** (o portal só expõe a estrutura da mais nova), por isso as antigas não transformam — entram no process direto. **Mesmos paths (hífen), mesmo _old/versionamento, mesmo `PROCESSA`** que a vigente.

> **Sem viagem no tempo (regra das antigas):** a FDE não expõe o histórico de estrutura/catálogos — só a edição **mais nova**. Logo:
> - **Catálogos de serviço/componente (fichas + agrupamento) SÓ entram na edição VIGENTE** (2026/4+, via UI). Edições antigas via `dist` são **data-only** — nunca ganham ficha/agrupamento (o portal não tem o histórico das fichas).
> - **CTC (AxysDoc) é autoral AXYS → SEMPRE montado, em TODA edição** (vive em `cmp_external_path.ctc`; ver §7.6). Não depende dos catálogos do portal — a Axys monta o CTC de cada CPU com o que há (composição + fichas quando houver). Data-only NÃO significa "sem CTC".
> - **Grupo/subgrupo das antigas = REPLICADO da vigente:** a estrutura é **fonte-level** (get-or-create em `composicoes_grupos/subgrupos`), populada pela vigente a partir da listagem do portal. O `dist` não traz `catalogo_estrutura.csv`; **herda** a estrutura já persistida (`parser_fde._upsert_estrutura` faz o fallback no banco). Assim a antiga ganha a MESMA hierarquia da 2026/4, sem precisar do dado de época.
> - **Compatibilidade dos dist antigos:** os `dist.zip` gerados antes da regra nova devem processar sem quebrar — a referência é a **2026/4 recém-feita**; o `PROCESSA` é o mesmo e o grupo/subgrupo vem do fallback, não do pacote.

- **TRANSFORMAR** (só o `4-26+`, na app): HTML→CSV, PDF→mapeamento/agrupamento (§7.2/§7.4, incl. cascata madeira §7.5), pareamento de md (§7.6). É o que hoje vive no sandbox `find_fde/` — migra pra dentro da app **só p/ a vigente**.
- **PROCESSAR** (ambos, **idêntico**): consome os dados-transformados (CSVs + `fichas_agrupamento.json`) → banco/storage/`external_path`/`documentos`. **A única diferença é a disponibilidade de docs** — o `old-fde` chega sem eles (data-only), o `4-26+` chega com eles.

> Mapeia os 2 tasks `importar_fde` (dist, `old-fde`) e `importar_fde_novo` (portal, `4-26+`) — **ambos tasks in-app**. O contrato formaliza o **corte transform/process** — o `PROCESSAR` não sabe de onde veio; só consome dado-transformado. O `old-fde` é disparado pelo **E2E** (seed histórico), não por script eager fora da app; e o `PROCESSAR` dele é o **mesmo código** do `4-26+` (paths hífen, `_old` por sha, agrupamento quando houver docs) — sem caminho paralelo.

---

## 9. Definição de pronto (anti-regressão)
- Contagens batendo (insumos/composições == CSVs de `find_fde`).
- `cc_custo_fonte` cru (com BDI) · `cc_custo_calculado` limpo · `edicoes_bdi` populado · conferência des-BDInizada (amostral) → `valida_amostra_fde.py` 0 divergências.
- Docs: `fichas_agrupamento.json` gerado do `fichas_vinculo.csv`; fichas únicas no storage (por código, `_old` no versionamento); `descritivo_tecnico`/`detalhe_tecnico` resolvem via agrupamento; G1 em `documentos` + regra "madeira"; CTC do md deduplicado; PDF nativo no display.
- **SINAPI e CDHU inalterados** (o mesmo campo `caderno_tecnico`/`descritivo_tecnico` multifonte não pode regredir).
- Trabalho em branch + PR para revisão humana.
