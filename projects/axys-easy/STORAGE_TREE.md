# Estrutura do Storage (object storage) — Ecossistema Axys

**Status:** v1.0 — 2026-07-14
**Escopo desta versão:** buckets + namespace **`easy/`** (AxysEasy). `hub/`, `pro/`, etc. são irmãos sob os mesmos buckets.
**Provider:** Cloudflare **R2** em produção; espelho **local em disco** em dev (`storage/{bucket}/{path}`, `backend/storage/local_storage.py`).

---

## Visão Geral

O storage do Axys é organizado em **três buckets por SENSIBILIDADE de acesso**, cada um com o namespace do ecossistema (`easy/`, `hub/`, …) na raiz. O bucket **não** aparece na URL (igual ao R2: `base_url/{path}`).

| Bucket | Acesso | Serve via | Guarda |
|---|---|---|---|
| **`axys-public`** | Público, **sem auth** | `public.axys-tec.com.br/{path}` (mount `/storage/{path}`) | Vitrine e estáticos — favicon/assets, índices de catálogo, docs marcados `fte_public`. |
| **`axys-private`** | **Login exigido** (cliente OU interno) | `/doc-file/{path}` (`require_auth` + rate-limit) | Catálogo documental da fonte (originais do import, fichas, CTC, cadernos, livros) — client-facing porém autenticado. |
| **`axys-restrict`** | **Tenant/usuário**, isolado | (por tenant; sob auth de tenant) | Dados do usuário/obra — uploads de orçamento/memória, arquivamentos, propostas/certidões (§3.5). Sensibilidade máxima. |

**Princípios** (ver `foundation/adrs/AXYS-ADR-008` armazenamento · `AXYS-ADR-022` minimalismo):
- ✅ Bucket = **sensibilidade** (público / autenticado / por-tenant), não tipo de arquivo.
- ✅ Namespace do ecossistema na raiz do bucket (`easy/`, `hub/`…); isolamento por projeto.
- ✅ **Manifestos e status de processamento** (JSON `_index`, `_versoes`, `_state`) vivem no storage, **não** no banco (ADR-022 §3.2).
- ✅ **Path determinístico** (`backend/modules/catalogo/storage_paths.py`) — o path não se guarda no banco, computa-se.
- ✅ **Vigência por versão** de ficha/CTC/caderno_cpu vive na **identidade** (`external_path`), apontando para o canônico ou o `_old/` (BUSINESS_RULES §11.10).
- ⚠️ Detalhe canônico do layout `easy/fontes/` em **`projects/axys-easy/contracts/catalogo/CATALOGO_STORAGE_LAYOUT.md`** — este arquivo é o **mapa**; o contrato é a **regra**.

---

## Árvore — `axys-public` (sem auth · vitrine/estáticos)

```
axys-public/
├── assets/                                    # favicon.png e estáticos (public.axys-tec.com.br/assets/…)
└── easy/                                       # namespace AxysEasy
    └── catalogos/
        └── {fonte}.html                        # índice navegável por fonte ("guia de bolso" / vitrine)
```

---

## Árvore — `axys-private` (login exigido · catálogo documental)

```
axys-private/
└── easy/                                       # namespace AxysEasy   (hub/, pro/ = irmãos)
    └── fontes/
        └── {fonte}/                            # sinapi · cdhu · fde · proprias
            │
            ├── {edicao}/                        # POR EDIÇÃO DE PREÇO (edi_codigo_versao: 08-24, 201…)
            │   ├── originais/                    # FONTE do import (trilha de auditoria):
            │   │   ├── {arquivos}.xlsx            #   planilhas do import (referência, MO, composições…)
            │   │   ├── fichas_insumos_{ed}.pdf     #   PDF das fichas (hyperlink do xlsx)
            │   │   ├── criterio_{ed}.pdf           #   critério de medição (CDHU)
            │   │   ├── leis_sociais_{ed}_{n}.pdf   #   cadernos de LS
            │   │   └── notas_{ed}.pdf              #   notas da edição
            │   ├── cadernos/_apresentacao/{slug}.html   # apresentações por subgrupo → edicoes.edi_capa_path
            │   ├── precos/{arquivo}                # artefatos de preço da edição
            │   ├── construcao/prompts/{cat}/{cod}.md    # prompts POR-EDIÇÃO (não-CTC: mdo_h_mes, unidades)
            │   ├── _state/{arquivo}                # status de processamento da edição (manifesto)
            │   ├── mdo_h_mes_conversao.json        # manifesto da conversão MDO H↔MÊS confirmada
            │   └── caderno_tecnico_{edicao}.html   # caderno técnico COMPLETO gerado (cache, 1/edição)
            │
            ├── fichas/                          # FONTE-LEVEL (identidade — SEM nível de edição)
            │   ├── {cod}.html                    # ficha vigente (o que a app serve)
            │   ├── _index.json                   # MANIFESTO de import: cod → sha (governa "mudou?")
            │   └── _old/{cod}_{sha}.html          # versões superadas — vigência via external_path.versoes
            │
            ├── ctc/                             # CTC | AxysDoc — FONTE-LEVEL (estático por cmp_codigo)
            │   ├── doc/{cod}.md                   # MD-fonte do CTC (recebe o fill da IA via get_md/put_md)
            │   ├── prompt/{cod}.md                # prompt do CTC (PERSISTE, pareado ao doc — NÃO fica no banco)
            │   ├── {cod}.html                     # CTC renderizado
            │   ├── _index.json                    # MANIFESTO: cod → req_hash (governa o delta:hash)
            │   └── _old/                           # versões superadas (pareadas MD+prompt), 1 par/revisão
            │       ├── {cod}_{ref}.md
            │       └── {cod}_{ref}.prompt.md
            │
            ├── cadernos/                        # cadernos-FONTE (PDF da Caixa) — dedup por ETag, FONTE-level
            │   ├── {slug}/cpu/{cod}.html          # CPU parseada do caderno
            │   ├── {slug}/apresentacao.html
            │   ├── _versoes.json                  # índice do dedup (slug→{data,etag,keys}) — governa reuso
            │   └── inativos/{slug}/{versao}/…      # versão superada do caderno
            │
            └── livros/                          # metodologia / cálculos e parâmetros / catálogos de referência
                └── {livro}_{ed_livro}.pdf         # PDF original (edição PRÓPRIA do livro, não a de preço)
```

> **Nota de estado (2026-07-14):** no rebuild em dev com `EASY_SKIP_CADERNOS_PDF`, `cadernos/` fica vazio (parse pulado) e `ctc/_old/`/`fichas/_old/` só aparecem quando houve revisão real entre edições.

---

## Árvore — `axys-restrict` (por tenant · sensibilidade máxima)

```
axys-restrict/
└── easy/                                       # namespace AxysEasy
    └── tenants/{tenant_uuid}/                   # isolamento por tenant (ADR-002)
        ├── ativos/{atv_id}/memoria/…            # arquivos da memória de cálculo do orçamento
        ├── orcamentos/…                          # anexos/rascunhos de orçamento do usuário
        ├── propostas/…                           # propostas de fornecedor / certidões (justificativa de cotação, §3.5)
        └── arquivamentos/…                        # backups/arquivamentos do tenant (ADR-009)
```

> ⚠️ **`axys-restrict` está DECLARADO** como bucket (por-tenant, sensibilidade máxima); o **layout acima é o alvo** — parte do wiring hoje ainda passa pelo `axys-private`. Consolidar em `axys-restrict` é dívida rastreada (ADR-008/ADR-002). Não inventar paths aqui sem contrato.

---

## Roteamento de URL

| Bucket | URL (prod) | Rota (app) | Auth |
|---|---|---|---|
| `axys-public` | `public.axys-tec.com.br/{path}` | mount `/storage/{path}` | nenhuma |
| `axys-private` | — | `GET /doc-file/{path}` | `require_auth` (cliente/interno) + rate-limit |
| `axys-restrict` | — | (por tenant) | auth de tenant |

O bucket **nunca** aparece na URL (paridade com o R2). `get_public_url` → `/storage/{path}`; `get_private_url` → `/doc-file/{path}` (`doc_url` dos documentos).

---

## Referências

- `backend/storage/local_storage.py` · `backend/storage/storage_provider.py` — provider (R2/local).
- `backend/modules/catalogo/storage_paths.py` — **fonte única dos paths** (determinísticos).
- `projects/axys-easy/contracts/catalogo/CATALOGO_STORAGE_LAYOUT.md` — layout canônico de `easy/fontes/`.
- `projects/axys-easy/contracts/catalogo/CATALOGO_BUSINESS_RULES.md §11` — governança de documentos + vigência por versão.
- `foundation/adrs/AXYS-ADR-008` (armazenamento) · `AXYS-ADR-002` (tenancy) · `AXYS-ADR-022` (minimalismo).
