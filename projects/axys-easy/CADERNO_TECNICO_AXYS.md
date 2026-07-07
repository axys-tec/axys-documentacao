# Caderno Técnico como AXYS Screen — descritivo unificado + fichas N:N

**Status:** SPEC (2026-07-05). Direção travada com Renan. Base para: schema, parser de cadernos FDE,
teste de IA (Gemini/Codex) e a AXYS Screen. Contrato relacionado: CATALOGO_BUSINESS_RULES, FDE_IMPORT.

## 0. Motivação

- **Unificar** o "Caderno Técnico" das 3 fontes numa **AXYS Screen** — o que o botão exibe passa a ser
  **texto da AXYS**, não o doc cru da fonte.
- **FDE é N:N** (cataloga por **grupo/tipo de serviço**, não por serviço) → composição/insumo ↔ docs é
  muitos-para-muitos. SINAPI/CDHU são 1:1. O schema tem que **aguentar as duas formas** (N:N contém 1:1).
- **BLINDAGEM AUTORAL (crítico):** o caderno técnico atual da edição **INFRINGE** — expõe a users docs que
  **não são públicos**. A AXYS Screen (texto próprio) + um flag `is_public` corrige: doc não-público não
  sobe pro user cliente; some do link (`<acesso restrito>`) pra perfil ≠ internal.

## 1. O modelo — AXYS Screen (mesma para todas as fontes)

Uma tela por composição, renderizada pela app (não é o PDF da fonte):

```
{codigo} - {descricao}

1) Forma de medição                              ← IA (o script passa a UNIDADE a destacar)
2) Descritivo do que remunera                    ← IA
3) Composição {cpu: codigo, desc, unid, coef}    ← app (composicoes_itens)
4) Documentos vinculados {links → public.axys-tec.com.br/…}   ← app (composicao_documento)
```

- As seções **1-2 (`axys_desc`)** ocupam o lugar do conteúdo atual do caderno. O conteúdo atual
  (parse CDHU/SINAPI) **é MANTIDO** — vira a **referência** que alimenta a IA.
- **Tom da escrita (gosto do CDHU):** técnico, impositivo, autoritativo, simples. **Sem** quebrar o texto
  com pensamentos ("isto não deve ser feito"). **Sem ponto-e-vírgula** em nenhum lugar. Marca só se a
  fonte-original citar — e em geral **não** precisa repetir.
- **Normas (critério de prompt):** **não citar normas** (NBR, etc.) **a menos que o doc de referência as
  cite**. A IA não inventa referência normativa — só repassa o que o texto-fonte trouxer.
- **UMA folha A4 (critério de prompt):** cada `axys_cpu_desc` (seções 1-4) deve caber em **1 A4** já
  descontados header+footer. A **composição (§3)** ocupa espaço proporcional ao nº de itens — o script
  **informa a contagem no prompt**. A IA dimensiona **§1+§2** para caber no espaço restante (mais concisa
  quanto maior a composição). **Extrapolar p/ 2ª página só é permitido em CPU com muitos insumos** (composição
  grande empurra a página) — nunca por texto prolixo.

## 2. Responsabilidade por seção

| Seção | Quem | Detalhe |
|---|---|---|
| 1) Forma de medição | **IA** | o script informa a unidade (m²/un/m³…) a destacar |
| 2) Descritivo do que remunera | **IA** | ancorado no texto de referência (§5) |
| 3) Composição | **app** | `composicoes_itens` (codigo, desc, unid, coef) |
| 4) Documentos vinculados | **app** | por fonte (abaixo) |

**Docs vinculados (seção 4) por fonte:**
- **CDHU:** o link do **critério** (doc atual).
- **SINAPI:** link da **ficha da composição** + **livro metodologia** + **livro cálculos e parâmetros**
  (quando existirem).
- **FDE:** na ordem — **ficha de componente** (quando existir) + **catálogo(s)** vinculado(s).

## 3. Schema

- **NOVA `catalogo.composicao_documento` (N:N):** `cd_cmp_id` · `cd_doc_id` · `cd_papel`
  (`criterio` | `ficha` | `componente` | `catalogo` | `livro_metodologia` | `livro_calculos`) · `cd_ordem` ·
  audit. **Delete-then-insert por edição** (idempotente, padrão canônico). SINAPI/CDHU geram 1-N linhas;
  FDE gera N. **É o que faltava** para o N:N sem tabela exclusiva de fonte.
- **`catalogo.documentos` (rework):** vira o **registro puro** dos arquivos no R2. O vínculo à composição
  **sai do `doc_cmp_id`** e vai para `composicao_documento` (assim uma ficha compartilhada aponta a N comps
  sem duplicar). **+ novo `doc_is_public` BOOLEAN NOT NULL DEFAULT FALSE** (restrito por padrão). `false` =
  não sobe no caderno de user CLIENTE (perfil ≠ internal vê `<acesso restrito>`); user AXYS sempre vê.
  **Regra por fonte:** **SINAPI = público** (docs sempre `is_public=True`, sem flag). **CDHU e FDE = não-
  públicas** → uma **flag no import** (checkbox, default OFF, `docs_publicos`) controla todos os PDFs
  daquela edição. Blindagem autoral: o caderno atual INFRINGE ao expor doc não-público — a AXYS Screen
  (texto nosso) + `is_public` corrige.
- **`catalogo.documentos_origem` (finalmente usada):** **proveniência** — arquivo-matriz (FDE/Caixa, que
  pode sumir) + cópia R2 de auditoria + sha. Casa com "persistir os crus (PDFs/CSVs) como auditoria".
- **`catalogo.composicoes.cmp_descritivo` JSONB (o `axys_desc`):** `{medicao, remunera}` por comp/edição.
  **Upsert** (idempotente). CDHU/SINAPI vêm do parse (referência); FDE vem da IA. **Cacheado** — regenera
  só se as fichas de referência mudarem (hash) → não re-chama IA à toa.

## 4. FDE — parser dos cadernos (pré-requisito do teste)

- **Baixar as 325 fichas** (224 catálogo de serviço + 101 componentes) dos URLs públicos
  (`catalogostecnicospublico`) → **storage** → registrar em `documentos` (+ `documentos_origem`).
  [CHECAR: a lógica "PDF→storage" já existe? é preliminar ao parser de vínculo.]
- **Parsear a pág. 1 de cada ficha → a seção `SERVIÇOS` → lista de CPUs** → popular `composicao_documento`.
  Exemplo `S3.07` (estaca raiz, Item/934/V4): a pág. 1 lista `02.02.114/115/116/117`, `16.31.030/031` →
  esses 6 códigos vinculam-se àquele PDF.
- **Componente → serviço** por **text-match** (código do componente na descrição do serviço, ex.:
  `09.02.061` = "AE-21 …"). **Necessário** — validado: ~50 fichas de componente (AC-04, AE-19, AG-04…)
  **NÃO** trazem "Código de listagem" no PDF, então o vínculo delas só sai pelo text-match.
- **STATUS (parser `fde_fichas_parser.py`, FECHADO):** 322/323 fichas → **1253 vínculos, 1170 CPUs**
  (text-match resolveu 46 componentes). Saídas em `saida_fichas/`.
- **COBERTURA:** 3375 CPUs na sintética → **1057 (31%) com ficha**, 2318 (69%) SEM. N:N modesto (1 ficha:992,
  2:57, 3:8 — máx 3). Os 47 serviços sem-CPU são **fichas-grupo** (S1/S2/S3…) — ok não vincular. 113 vínculos
  a CPU fora da edição = ruído (fichas citam códigos de outras edições) — filtrar no FK.
- **⚠️ CONSEQUÊNCIA:** em **69% dos CPUs FDE a referência (b) é magra** (só descrição+composição) — onde a IA
  tem menos ancoragem. O teste PRECISA cobrir esse caso (não só CPUs com ficha rica).
- **RESSALVA:** os catálogos/componentes FDE **NÃO** são parseados para montar TEXTO — são parseados para
  (a) passar info à IA (o **texto do componente**) e (b) o **vínculo** (código-serviço → link). **Dos
  catálogos de serviço, só o par (código-serviço, link)** — nada de corpo.

## 5. Texto de referência (b) por fonte (entra no prompt da IA)

- **SINAPI:** **caderno da composição** (`cadernos_sinapi.py`, HTML→`cmp_external_path`) [doc atual, em texto].
  ⚠️ **NÃO** usar `fichas_sinapi.py` — aquelas são fichas de **INSUMO** (vinculam a insumos). **Nosso alvo é
  CPU. Insumo NÃO é alvo — ignorar.** SINAPI é a única fonte com fichas de insumo (irrelevantes aqui).
- **CDHU:** caderno de medição [doc atual da app, em texto] — critério já sai `1=medição/2=remuneração`.
- **FDE:** **componente** (se existir) parseado, **sem imagem** e **sem** os cadernos vinculados à cpu.
- **FDE sem ficha (o caso magro, 69%):** buscar **CPU análogo na CDHU** por **match descrição×descrição
  ≥ 85%** de semelhança → passar o critério CDHU como **DICA DE TOM**, não como conteúdo. Deixar
  **explícito à IA** que a associação pode estar errada e serve só para calibrar o **tom** (não é fonte).

## 6. O teste (alto em escala, motor = Gemini LOCAL)

- **60 itens:** 20 CDHU + 20 SINAPI + 20 FDE **aleatórios** (FDE: 20 CPUs, podem puxar 1+ cadernos).
- **60 prompts `.md`** num diretório do repo. Cada prompt contém:
  - **a)** instrução (o que a IA faz + a **unidade** a destacar + o **nº de itens da composição** e o
    **critério de 1 A4** — §1) — **prompt-base, não pode ser tocado**.
  - **b)** texto parseado de referência (§5).
  - **c)** composição.
  - **d)** lista dos docs que a app vai vincular (orientativo à IA).
- **Prompt genérico p/ Gemini (VSCode):** NÃO tocar no prompt-base; salvar em `./gemini/cpu_{codigo}_desc.md`.
- **v2 (Codex):** idem → `./codex/cpu_{codigo}_desc.md`.
- **Validação:** conferir o serviço Gemini/Codex e validar o método (assertividade × tom × custo).

### VEREDITO DO TESTE (2026-07-05) — motor PAGO justificado
- **Método validado.** Prompt-base + regra de **fidelidade à composição** funcionam: descritivo fiel, tom
  CDHU, **0 `;`**, **0 norma inventada** (as citadas batem com a referência), cabe em A4.
- **Codex (pago) × Gemini (local), mesmo prompt reforçado, corridas independentes (0/58 idênticos):**
  boilerplate vazio **Codex 0 × Gemini 32**; nos 32 casos magros a seção 2 tem **76 palavras (Codex) × 23
  (Gemini)**. O Gemini genérica exatamente onde está o valor (SINAPI + 69% FDE) — não lê a composição.
  Nos casos ricos (CDHU) empatam (ambos copiam a fonte).
- **Decisão:** adotar motor **pago** para o gerador (exceção justificada à doutrina "sem API paga";
  custo limitado — 1×/serviço/edição, cacheado). Reforço de fidelidade fica no contrato do prompt.
- 1ª rodada Gemini foi DESCARTADA (leu `codex/` e copiou 58/58) — comparação só vale cega.

## 6b. Modo de geração + request no import (FECHA o import antes da IA)

- **`AXYS_CPU_DESC_MODO`** (`runtime_config.cpu_desc_modo`): `IA_local` (default, nosso caso — request p/
  codex-LOCAL, sem custo de token) | `IA_auto` (FUTURO — IA via token no fluxo). **Em ambos, o request é
  montado no import.**
- **Request montado no import da edição** (`descritivo_request.montar_request`/`gerar_requests_edicao`,
  plugado no fim das 3 tasks): por CPU, monta o prompt **a/b/c/d** (referência dos docs vinculados +
  composição + links) e grava **`composicoes.cmp_descritivo = {status:"em_revisao", modo, request}`**.
  Mora no próprio JSONB (evita 10k+ arquivos/edição). `exportar_requests_md()` materializa os `.md` sob
  demanda p/ o codex-local. A AXYS Screen mostra **"em revisão"** enquanto o texto não é gerado.
- **Complemento** (desacoplado): codex-local roda sobre os `.md` → grava `cmp_descritivo={status:"ok",
  medicao, remunera}`. (Ou, no futuro, `IA_auto` preenche via token.)

## 7. Passos de execução

1. **Documentar** (este doc). ✅
2. **Parser dos cadernos FDE** ✅ (`z_search_repos/find_fde/fde_fichas_parser.py` → 1253 vínculos).
3. **Preparar os prompts** ✅ **58/60** em `z_search_repos/desc_teste/prompts/` (19 CDHU + 19 SINAPI +
   10 FDE-com-ficha + 10 FDE-sem-ficha). Montador: `desc_teste/montar_prompts.py`. Referências: CDHU
   critérios (prod R2, edição 202) + SINAPI cadernos (prod R2, 12-25) + FDE `fichas_texto` + análogo CDHU
   (limiar **50%**, 8/10). Composições do dev (CDHU edi51 · SINAPI edi48 · FDE edi49), itens resolvidos
   por JOIN. **Faltam 2** (CDHU 35.05.300, SINAPI 106701 — códigos só no prod, não na edição dev usada).
4. **Instruções** ✅ `INSTRUCAO_GEMINI.md` (→ `./gemini/`) + `INSTRUCAO_CODEX.md` (→ `./codex/`).
5. **Validar** — PENDENTE: Renan roda Gemini/Codex sobre `prompts/`, saída em `gemini/`/`codex/`; depois eu
   confiro assertividade × tom × A4 e validamos o método (e a decisão local × API paga).

## 8. Pendências a resolver na execução

- Extrair o **TEXTO** atual da ficha SINAPI / critério CDHU (a referência §5-b) — onde está (R2 HTML? re-parse?).
- Confirmar se a lógica **PDF→storage** da FDE já existe (§4).
- **Retro-marcar `is_public`** nos docs atuais (livros/LS/cadernos não-públicos) — quais são públicos.
- CPU FDE **sem** ficha de componente → material de referência mais magro (§5).
- Migração: popular `composicao_documento` a partir do `doc_cmp_id` atual (SINAPI/CDHU) — aditivo.

## 9. PENDÊNCIA ABERTA — bucket público × autoral (discussão 2026-07-05, a decidir)

**O problema:** hoje TODOS os docs vão pro `axys-public`. O `doc_is_public=False` **só esconde o link na
tela** — o objeto no R2 continua **world-readable** por quem tiver a URL. Logo o `is_public` é **cosmético**
e **não protege o conteúdo autoral** (critério CDHU, livros). A infração continua de pé.

**Direção proposta (infra JÁ existe: `EASY_STORAGE_PRIVATE_BUCKET` + `save_private_file`/`open_private_file`
+ presigned):** rotear por `is_public` no import — **público → `axys-public` (URL direta)** · **não-público →
`axys-private`, servido por PROXY autenticado (`is_staff`), nunca URL pública** (cliente vê `<acesso
restrito>`). Move a proteção da UI pro STORAGE → `is_public` vira real. Fazer no REBUILD (sem migração).

**Ligado a isto (fazer junto):**
- **AXYS Desc = a MESMA tela do caderno da edição.** Hoje "gerar caderno técnico" (/edicoes) liga as fichas
  em `/doc/{id}`; deve ligar em **`/axys-desc/{cmp_id}`** (caderno da edição = sumário + fichas → clica →
  AXYS Desc, a mesma da lista de composições).
- **Item 4 (docs vinculados) — nome canônico + hyperlink de verdade:** CDHU → "Critério de Medição e
  Remuneração" · SINAPI → "Caderno Técnico de Composições" · FDE → nome do arquivo. Link azul/sublinhado; o
  destino depende do bucket (público=URL direta · privado=proxy `is_staff` · cliente=`<acesso restrito>`).
