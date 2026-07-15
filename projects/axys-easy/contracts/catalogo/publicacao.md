# CATÁLOGO — Layout de Storage (bucket público)

> **Status:** contrato vigente (decidido). Padronização aprovada para aplicar **agora**, em dev,
> **sem repopular** (tudo é teste; nada subiu para homologação — regenera no próximo import).
> **Revisto 2026-07-13** (repense doc/path — `as capabilities (README) §11.9/§11.10/§11.11`):
> ficha/caderno_cpu/CTC resolvem pela **identidade** (`external_path.versoes`, vigência por versão),
> **não** por `catalogo.documentos` — que fica só p/ docs de **edição/fonte** sem dono 1:1.
> Governança: o **import escreve**; o **app** lê ficha/CTC do `external_path` e os **livros/originais**
> do registro `documentos`. O app **sempre** linka pro storage (nunca pra fonte matriz).

---

## 1. Buckets e ambiente

| | Produção (R2) | Dev (disco) |
|---|---|---|
| **Público** | `axys-public` (`EASY_STORAGE_PUBLIC_BUCKET`), servido por `R2_PUBLIC_BASE_URL` | `LOCAL_STORAGE_PUBLIC_ROOT` (`storage/public/`) |
| **Privado** | `axys-private` (`EASY_STORAGE_PRIVATE_BUCKET`) | `LOCAL_STORAGE_PRIVATE_ROOT` (`storage/private/`) |

- O **`key`** passado a `save_public_file(key, …)` **É** o caminho dentro do bucket.
- **Namespace do app:** tudo do Easy fica sob **`easy/`** (o bucket `axys-public` é compartilhado
  entre apps Axys). Prefixo único, centralizado no storage/constante — callers usam `fontes/…`.
- Todos os documentos do catálogo (originais + HTMLs derivados + caderno completo) vivem no
  **bucket público** `axys-public`, sob `easy/`.

---

## 2. Layout canônico — `axys-public/easy/`

```
axys-public/easy/
│
├── fontes/{fonte}/                           ← {fonte} = fte_codigo minúsculo (sinapi, cdhu, …)
│   │
│   ├── {edicao}/                             ← o que muda A CADA edição de preço (imutável/auditável)
│   │   │                                        {edicao} = edi_codigo_versao (ex.: 05-26, 201)
│   │   ├── originais/                        ← ARQUIVOS-FONTE da edição → "Ver / Baixar"
│   │   │   ├── insumos_{edicao}.xlsx         ← Excel do import (TODAS as fontes)
│   │   │   ├── composicoes_{edicao}.xlsx
│   │   │   ├── servicos_sd_{edicao}.xlsx · servicos_cd_{edicao}.xlsx
│   │   │   ├── criterio_{edicao}.pdf         ← CDHU (critérios, fonte)
│   │   │   ├── leis_sociais_{edicao}_{n}.pdf ← CDHU (1+ PDFs de encargos)
│   │   │   └── notas_{edicao}.pdf            ← release da edição (quando houver)
│   │   ├── fichas/{cod}.html                 ← derivado per-insumo
│   │   ├── cadernos/{cod}.html               ← derivado per-composição (CDHU/FDE). SINAPI migrou p/ fonte-level ↓
│   │   ├── cadernos/_apresentacao/{slug}.html← apresentação de subgrupo (LEGADO; SINAPI usa fonte-level ↓)
│   │   └── caderno_tecnico_{edicao}.html     ← CADERNO COMPLETO gerado (cache; 1 por edição)
│   │
│   ├── cadernos/{slug}/                      ← CADERNOS TÉCNICOS da FONTE (SINAPI) — fonte-level, versionados
│   │     ├── {arquivo}.pdf                     por ETag/data (NÃO por edição); a edição referencia o vigente
│   │     ├── apresentacao.html
│   │     └── cpu/{cod}.html
│   ├── cadernos/_versoes.json                ← índice do dedup (slug→{data,etag,doc_id,keys}) — governa reuso
│   ├── cadernos/inativos/{slug}/{versao}/    ← versões superadas (histórico p/ retroagir pesquisas)
│   │
│   └── livros/                               ← docs com EDIÇÃO PRÓPRIA (não mudam a cada edição de preço)
│         {livro}_{ed_livro}.pdf              metodologia · calculos_e_parametros · catálogos de
│                                             referência. Versão própria controlada no import →
│                                             `doc_versao`/`doc_data` no banco (edição/data/outro).
│
└── catalogos/{fonte}.html                    ← índice geral navegável ("catálogo axys"); aponta ao vigente
```

### 2-bis. Pipeline de import (bucket PRIVADO) — `axys-private/easy/`

Introduzido no plano de reimport (R1). Servidos **só pela app** (nunca URL de R2); acesso `exige_internal_user` + rate-limit. Builders em `storage_paths.py`; estados em `imports/estagios.md`.

```
axys-private/easy/fontes/{fonte}/{edicao}/
├── originais/…                    ← (mesmo conteúdo de hoje; migra public→privado no R8)
├── _state/links.json              ← Preparar: mapa de links externos (SINAPI/CDHU)
├── _state/estagios.json           ← snapshot de edi_estagios (auditoria/retomada)
├── precos/insumos.csv             ← AxysDocs — Docs de Preço
├── precos/composicoes.csv
├── construcao/prompts/{cat}/{cod}.md ← prompts POR-EDIÇÃO das análises NÃO-CTC (mdo_h_mes, unidades)
└── caderno_tecnico_{edicao}.html  ← caderno completo gerado (cache; 1 por edição)

axys-private/easy/fontes/{fonte}/ctc/    ← CTC AxysDoc: FONTE-LEVEL (estático por cmp_codigo)
├── _index.json                    ← cod → req_hash (MANIFESTO de import: governa o delta:hash; NÃO é vigência — §11.10)
├── doc/{cod}.md                   ← MD-fonte do CTC (editável; fill da IA via get_md/put_md)
├── prompt/{cod}.md                ← prompt do CTC (PERSISTE, pareado ao doc — não é andaime)
├── {cod}.html                     ← CTC renderizado (o que a app serve)
└── _old/{cod}_{ref}.md + {cod}_{ref}.prompt.md ← versões SUPERADAS (MD+prompt pareados, 1 par por revisão)
```

Princípio: **TUDO que é CTC vive sob `ctc/` FONTE-LEVEL** (estático por `cmp_codigo`; doc+prompt só (re)geram em VERSÃO NOVA REAL — quando o texto-fonte muda via delta:hash — nunca 1 por edição; o anterior vai pro `_old` pareado). ⚠️ **REVISTO 2026-07-13 (§11.11):** o **prompt e o MD do CTC NÃO ficam no banco** — vivem **só aqui no storage** (`prompt/{cod}.md` + `doc/{cod}.md`). `cmp_descritivo` guarda **só** `{modo, status, req_hash}` (~40 bytes); o **vínculo durável** é o `req_hash` + o path em `cmp_external_path.ctc` (com vigência §11.10), não o texto no banco. O `{edicao}/construcao/prompts/` guarda só prompts de análise POR-EDIÇÃO (não-CTC). `originais` mantém o nome (não renomear).

### Regras de nomenclatura
- **`{arquivo}_{edicao}`** em todo original → cada edição é uma **foto** identificável; o
  `caderno_tecnico_{edicao}.html` é a **versão de divulgação/suporte** dessa foto (auditoria).
- `{edicao}` = `edi_codigo_versao` (humano: `05-26`, `201`). `{ed_livro}` = a versão PRÓPRIA do livro.
- **`cadernos/{cod}.html` é unificado** p/ todas as fontes (o "critério" CDHU é um caderno técnico
  de composição). O `doc_tipo` no registro segue a semântica da fonte (`criterio`/`caderno_cpu`); o
  **path** é o mesmo.

### Edição de PREÇO × edição de DOC (livro)
- **Per-edição-de-preço** (sob `{edicao}/`): insumos/composições/serviços (xlsx), critério, leis
  sociais, notas, e os derivados (fichas/cadernos) + caderno técnico.
- **Per-edição-própria** (sob `fontes/{fonte}/livros/`): metodologia, cálculos e parâmetros,
  catálogos de referência — versionados pela edição deles, **não** duplicados a cada edição de preço.

### Invariantes de governança
- Despublicar/arquivar a fonte **não apaga** `fontes/{fonte}/{edicao}/` → a **cópia vigente
  permanece** (o app continua servindo do storage).
- Reimport de uma edição **sobrescreve** sua pasta (mesmo `key`) — idempotente.
- O registro `catalogo.documentos` é a **fronteira** dos docs de **edição/fonte** (livros/notas/
  originais/cadernos-fonte/critérios/apresentações — §11.9): guarda `doc_path` (key) + `doc_url` +
  `doc_versao`/`doc_data`. **Ficha/caderno_cpu/CTC não passam por aqui** — a app os resolve pela
  identidade (`external_path.versoes`, §11.10). Vigência (as-of edição) = `external_path`, não registro.

---

## 3. Migração do layout atual (aplicar agora, sem repopular)

| Documento | Hoje | Alvo |
|---|---|---|
| Originais (import) | `fontes/{fonte}/audit/{versao|mes}/…` | `easy/fontes/{fonte}/{edicao}/originais/…` |
| Fichas/Cadernos SINAPI | `fontes/sinapi/fichas|cadernos/{cod}.html` | `easy/fontes/sinapi/{edicao}/fichas|cadernos/{cod}.html` |
| Critérios CDHU | `fontes/cdhu/{versao}/criterios/{cod}.html` | `easy/fontes/cdhu/{edicao}/cadernos/{cod}.html` |
| Leis Sociais CDHU | `fontes/cdhu/{versao}/leis_sociais/{arq}` | `easy/fontes/cdhu/{edicao}/originais/leis_sociais_{edicao}_{n}.pdf` |
| Metodologia/Cálculos/Catálogos | `fontes/sinapi/metodologia/…` (por edição) | `easy/fontes/{fonte}/livros/{livro}_{ed_livro}.pdf` |
| Índice geral | `livros/{fonte}.html` | `easy/catalogos/{fonte}.html` |
| Caderno técnico completo | (novo) | `easy/fontes/{fonte}/{edicao}/caderno_tecnico_{edicao}.html` |

> A pasta `audit/` deixa de existir: os **originais** SÃO a trilha de auditoria, sob `{edicao}/originais/`.
> Tudo ganha o prefixo de app **`easy/`**.

---

## 4. Caderno técnico completo (botão "Gerar caderno técnico")

- **Onde:** `easy/fontes/{fonte}/{edicao}/caderno_tecnico_{edicao}.html` (cache, 1 por edição publicada).
- **Geração assíncrona** (Celery), com **cache-serve síncrono**: clicou → existe? abre; senão
  enfileira job, acompanha pelo sino, abre ao concluir. Edição publicada nova = chave nova = regenera.
- **Conteúdo:** header (tarja+logo, Tenant→"Catálogo Técnico", user→"{FTE} — {nome} | {edição}")
  + **originais** (Ver/Baixar, incl. **Excel** dos imports **e os livros da fonte**) + **listagem da
  edição** (fichas/cadernos no formato aberto, com hierarquia CDHU e título SINAPI). Originais/livros
  vêm do registro `documentos`; a **listagem de fichas/cadernos_cpu/CTC** vem do `external_path`
  (as-of a edição do caderno, §11.10).
