# CATÁLOGO — Layout de Storage (bucket público)

> **Status:** contrato vigente (decidido). Padronização aprovada para aplicar **agora**, em dev,
> **sem repopular** (tudo é teste; nada subiu para homologação — regenera no próximo import).
> Governança: o **import escreve**, o **app/livros leem** via registro `catalogo.documentos`
> (`doc_url`/`doc_path`). O app **sempre** linka pro storage (nunca pra fonte matriz).

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
│   │   ├── cadernos/{cod}.html               ← derivado per-composição (SINAPI/CDHU/OUTRO — UNIFICADO)
│   │   ├── cadernos/_apresentacao/{slug}.html← apresentação de subgrupo (SINAPI)
│   │   └── caderno_tecnico_{edicao}.html     ← CADERNO COMPLETO gerado (cache; 1 por edição)
│   │
│   └── livros/                               ← docs com EDIÇÃO PRÓPRIA (não mudam a cada edição de preço)
│         {livro}_{ed_livro}.pdf              metodologia · calculos_e_parametros · catálogos de
│                                             referência. Versão própria controlada no import →
│                                             `doc_versao`/`doc_data` no banco (edição/data/outro).
│
└── catalogos/{fonte}.html                    ← índice geral navegável ("catálogo axys"); aponta ao vigente
```

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
- O registro `catalogo.documentos` é a **fronteira**: guarda `doc_path` (key) + `doc_url` + (livros)
  `doc_versao`/`doc_data`. O app e o gerador de caderno leem **só** do registro (agnósticos ao layout).

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
  edição** (fichas/cadernos no formato aberto, com hierarquia CDHU e título SINAPI). Lê tudo do
  registro `documentos`.
