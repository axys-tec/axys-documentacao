# Plano — Reimport desmembrado (4 estágios) + Tela de Documentos

> Data: 2026-07-06 · Status: **APROVADO — executar** · Decisões travadas (ver §Decisões).
> **Ordem aprovada:** R0 (estado) → R1 (storage/privado) → **Frente A (Documentos, R2-R3)** →
> Frente B (import 4 estágios, R4-R7) → R8 (migração). Persistência: **JSON + `edi_estagios`,
> docs nascem no privado** (D1/D2/D3 = recomendações do plano).
> Contexto anterior: [[project_caderno_axys_bug]] (refactor do CTC/AxysDoc + caderno da edição já
> feito). Este doc é o "prompt novo" do item (d) do plano do caderno.

## 0. Problema & objetivos

O import contínuo/corrido é grande, roda tudo de uma vez e **não fecha 100%** (ex.: FDE depende de
curl; um preço falta → cai em SEM_CUSTO silencioso). Objetivos:

1. **Desmembrar** o import em estágios independentes → assertividade quando uma fonte muda algo.
2. **Tirar responsabilidade do back**: onde o back não consegue fechar sozinho (preço faltante,
   conexão cai), **devolver a decisão ao user** via modal, com estado durável.
3. **Documentos acessíveis ao user interno como um diretório** — nunca R2/bucket direto. A app
   serve, controlado por permissão (+ rate-limit anti-scraping).
4. Toda edição **nasce com o AxysDoc/caderno pronto em storage privado**; clicar só **renderiza** o
   que já está pronto (menos back em runtime).

Script de back pode ser comunitário (sem problema). Tudo assíncrono (Celery).

---

## FRENTE A — Tela de Documentos (árvore)

### A.1 Acesso e endpoint único
- Botão **"Documentos"** em `/fontes-base` **e** `/edicoes`.
- **Um só endpoint** monta a árvore (HTML análogo ao CTC, retrátil via `<details>`):
  - Sem filtro (via fontes): abre **N edições** da fonte.
  - `?fonte={id}&edicao={id}` (via edição): monta só aquela edição. **Única diferença** = filtro.
- Hierarquia: **Fonte › Edição › Tipo de documento › Documento**. Tudo expansível/retrátil.

### A.2 O que a edição traz (camadas — nem toda fonte terá todas)
1. **Documentos originais** — TODOS em lista Ver/Baixar (independe de extensão; aqui vão os milhões
   da SINAPI). Sem curadoria: mostra tudo.
2. **AxysDocs — Docs de Preço**: `CSV Insumos`, `CSV CPUs`, (+ outros a definir).
3. **AxysDocs — Construção de Caderno**: `Prompts` (.md), `Retornos de prompt` (.md), `CPUs-md`
   (.md que geram os .html).
4. **CTCs** — lista dos CTC já prontos.

### A.3 Acesso controlado (não-R2)
- Docs vivem em **bucket privado**. O user **nunca** recebe URL de R2.
- A app serve por um endpoint gated (estilo `/doc/{id}` atual, mas lendo do **privado** e exigindo
  `exige_internal_user`) → 1 indireção por doc.
- **Rate-limit no back** (anti-scraping): teto de req/min por sessão/IP, patamar "não-humano".
  Necessário porque vamos liberar testadores free ao caderno.

---

## FRENTE B — Import desmembrado em 4 estágios

Mantém **integralmente** a tela de import atual. Troca o único botão "Processar" por **4 botões que
nascem LOCKED**; cada estágio concluído destrava o próximo. O **último** (Documentos) marca a edição
**disponível para publicação**.

Estado por estágio persistido em `catalogo.edicoes.edi_estagios` (JSONB) — fonte de verdade
transacional/queryável — espelhado num artefato de status no **storage privado** por edição (auditoria
+ retomada). Job durável em `core.jobs`.

### Estágio 1 — Preparar
- **Carrega os originais para o storage** (todos, independe de extensão). Concluído → destrava Preços.
- Para **SINAPI/CDHU** (links externos): incluir aqui o **mapeamento dos links** persistido em
  storage (formato a decidir — ver §Decisões D1).

### Estágio 2 — Preços
- Constrói os preços. **Docs suficientes → fecha sozinho.**
- Caso **FDE/curl** (ou preço de insumo faltante / conexão cai): grava **status durável** e, no fim,
  **devolve ao user** via **modal simples**:
  - **"Informar dado"** (input do dado faltante), ou
  - **"Publicar sem preço"** (assume SEM_CUSTO consciente).
- Tira 100% da responsabilidade do back e ganha produtividade real.

### Estágio 3 — Dados  ← **ponto de ataque**
- Parseamento pesado + construção dos **markdowns preliminares** + request de IA.
- **Codex local** acessa os .md e cria os retornos. Enquanto local:
  - **Script `get_md(edi_id)`**: baixa do R2 os `.md` (prompt + AxysDoc estruturado/pronto).
  - IA **edita no próprio .md** (menos token: mais leitura/consulta, menos cópia).
  - **Script `put_md(edi_id)`**: substitui o .md placeholder pelo final.
- Em **IA_auto** → esse ciclo nem é usado.

### Estágio 4 — Documentos
- Gera os **AxysDocs** (CTCs + caderno da edição) → **storage privado**.
- Toda edição nasce com o caderno montado. Runtime = só **renderiza o pronto** (permissão controla).
- Concluído → edição **disponível para publicação**.

Todos os estágios rodam em **background (Celery-async)**.

---

## Ringue de execução (rounds)

| Round | Entrega | Depende de | Destranca |
|---|---|---|---|
| ✅ **R0** | Modelo de estado dos estágios (`edi_estagios` schema + helpers get/set) + contrato | — | todo o resto |
| ✅ **R1** | `storage_paths` estendido (Docs de Preço / Construção / CTCs) + layout privado documentado | R0 | A, B |
| ✅ **R1-bis** | Backfill `doc_edi_id` (caderno_cpu/ficha) → 100% dos docs pendurados na edição | R1 | R2 |
| ✅ **R2** | **Frente A** — árvore de Documentos (`/documentos`) + botão em fontes-base/edições + links /doc/{id} | R1-bis | — |
| ✅ **R3** | Rate-limit middleware (anti-scraping) — 30 req/min por identidade (env EASY_DOC_RATE_LIMIT), Redis, fail-open | R2 | liberar free |
| ✅ **R4** | Painel dos 4 estágios na tela + wrapper: import + caderno chamam `set_estagio` (preparar→preços/dados→documentos), panel reflete o real | R0,R1 | R5 |
| **R5** | **Estágio 2 (Preços)** + modal "Informar dado / Publicar sem preço" + status durável | R4 | R6 |
| **R6** | **Estágio 3 (Dados)** + scripts `get_md`/`put_md` + fluxo Codex-local | R5 | R7 |
| **R7** | **Estágio 4 (Documentos)** gera AxysDocs no privado + marca "disponível p/ publicar" | R6 | publicação |
| **R8** | Migração dos docs atuais public→private + regen dos 3 cadernos | R1,R7 | — |

Ordem sugerida de ataque: **R0 → R1 → (R2/R3 Documentos) ‖ (R4→R7 Import)** — Frente A e Frente B
compartilham R0/R1 e depois correm em paralelo.

---

## R5 — Split real do import (detalhamento de execução)

> O R4 (wrapper) faz o painel REFLETIR o monólito, mas o monólito roda tudo num job só (sem pausa).
> O R5 é o carve de verdade: cada estágio vira uma task stop-and-wait. Piloto **CDHU** (blocos limpos:
> preparar 737-768 · dados 772-821 · criterio 824-882 em import_service.py). Depois SINAPI/FDE.

**Crux 1 — handoff de estado:** os estágios rodam em invocações separadas do worker (o `tmp` some entre
elas). Cada estágio **re-baixa do storage** o que precisa (as keys em `arquivos`). Já é assim que o
monólito baixa (download_public_file por key) — só replicar por estágio.

**Crux 2 — persistir os params do form:** o form é preenchido 1× (no Preparar); Preços/Dados/Documentos
rodam depois sem re-upload. Persistir `{arquivos, ls_manual, ls_pdfs, docs_publicos, fte_id, edi_versao}`
em **`edi_estagios.preparar.detalhe.import_params`** (o modelo R0 já guarda `detalhe`). Estágios seguintes
leem via `get_estagios(edi)["preparar"]["detalhe"]["import_params"]`.

**Passos (CDHU piloto, monólito MANTIDO ao lado até validar):**
1. `estagios.py`: helpers `salvar_params(edi, params)` / `carregar_params(edi)` (grava/lê em preparar.detalhe).
2. Carvar `importar_cdhu` em 3 tasks: `preparar_cdhu` (bloco 737-768 + salvar_params + set_estagio(preparar,ok)),
   `dados_cdhu` (bloco 772-821, re-baixa do storage + carregar_params), `documentos_cdhu` (824-882 + caderno).
   Cada uma re-abre store/conn e PARA no fim.
3. Rota: `POST /api/edicoes/{id}/estagios/{nome}/rodar` — dispara a task-estágio da vez (valida cascata:
   só roda se `estado==pronto`). O upload dos arquivos acontece no disparo do Preparar (como hoje no
   POST /api/import/cdhu, mas sem enfileirar o resto).
4. UI (import.js): os 4 chips viram BOTÕES; habilitados só quando `estado==pronto`; clicar → POST rodar →
   poll até `ok` → recarrega o painel (destrava o próximo). O "Processar" some (ou vira só o Preparar).
5. Validar: rodar CDHU estágio a estágio no worker (reiniciado), conferir pausa real + retomada + o
   caderno/publicável no fim. Só então remover o monólito e replicar p/ SINAPI/FDE.

**Preços isolado + modal (o "Informar dado/Publicar sem preço"):** só faz sentido onde há preço faltante
(FDE/curl). No CDHU os preços vêm do Excel (sem modal). Então o estágio Preços do CDHU é quase no-op
(preços saem no "dados"); o modal entra no split do FDE.

## Decisões abertas (preciso do seu aval antes de codar)

- **D1 — Persistência de estado/mapeamentos** (você disse "defina pelo maior desempenho):
  **Recomendo**: estado-de-verdade dos estágios em **`edi_estagios` JSONB** (transacional,
  queryável, dá pra checar lock/unlock numa query) + **snapshot `.json` no privado** por edição só
  p/ auditoria/retomada. O **mapa de links** SINAPI/CDHU (volumoso, chave→url) → **JSON no privado**
  (leitura O(1) por chave, sem inchar tabela). CSV só se você quiser abrir no Excel — mais lento p/
  lookup. **→ JSON, não CSV.**
- **D2 — Bucket privado + rate-limit**: confirmar que TODOS os docs (originais + AxysDocs + CTCs)
  vão pro privado, servidos só via app. Rate-limit: teto por sessão **e** por IP? Qual patamar
  inicial (ex.: 120 req/min)?
- **D3 — Migração public→private**: fazer no R8 (dev primeiro, depois prod) ou já nascer privado e
  deixar o legado public morrer? Recomendo **nascer privado + migrar o legado no R8**.
- **D4 — Ficha de insumo**: exceção sua (SINAPI, acessível também via busca de INSUMO). Ela fica no
  privado mas com endpoint próprio de busca? Confirmar.
- **D5 — Escopo do 1º corte**: fazer as **duas frentes** ou começar só pela **A (Documentos)** ou só
  pela **B (Import 4 estágios)**? Recomendo **R0+R1 primeiro** (base comum), depois você escolhe a
  frente.

## Contratos / schema a tocar
- `edi_estagios` (JSONB) — formalizar o shape dos 4 estágios (contrato novo).
- `storage_paths.py` + `CATALOGO_STORAGE_LAYOUT.md` — novas pastas (docs_preco/, construcao/, ctcs/)
  + bucket privado.
- `core.jobs` — reusar para os jobs por estágio.
- Novo contrato: `IMPORT_ESTAGIOS.md` (lock/unlock, o que cada estágio grava/lê).
