# EASY — Storage Privado por-Tenant (Contrato de Layout)

> **Escopo:** materializa o layout do bucket **privado** (`axys-private`) para todo dado **por-tenant** do Easy. É o irmão privado do `storage_paths.py` (`sp`), que governa o layout **público/global** do catálogo. **Nada de path de storage solto pelo código** — sempre por um helper que implementa este contrato.
>
> **Contrato governa · schema/storage suporta · código implementa.** Código que escreve nesses paths referencia este arquivo no topo.

---

## 1. Hierarquia canônica

```
axys-private/easy/{tenant_uuid}/{empreendimento_id}/{ativo_id}/{produto}/...
```

- **`{tenant_uuid}` = o DONO** do empreendimento (quem criou e libera acesso). É a **custódia** física do dado.
- **`{empreendimento_id}` / `{ativo_id}`** — a árvore de negócio.
- **`{produto}`** é **FILHO do ativo** (não avô). Produtos conhecidos: `orca`, `docs`, `build-diary` (extensível).

Produtos sob o ativo hoje:

```
{ativo}/orca/                                  ← universo Orça (easy-price · easy-cpu · easy-orca)
        orca/memo-calc/{mc_id}/levantamentos/{key}.json   ← payload axys-cad-v1 CRU (blob pesado; só aqui)
        orca/memo-calc/{mc_id}/midias/{uuid}_{nome}        ← fotos (WebP ~200KB)
        orca/memo-calc/{mc_id}/docs/{uuid}_{nome}          ← anexos (pdf/dwg… ≤1MB)
{ativo}/docs/                                  ← documentos do ativo (produto Docs)
{ativo}/build-diary/                           ← diário de obra (produto, futuro)
```

## 2. Princípios (o "porquê", pra não refatorar)

1. **Produto é filho do ativo** — um mesmo ativo tem `orca` + `docs` + `build-diary` lado a lado. Trabalho **integrado por-ativo** só é natural com o produto embaixo do ativo. (Produto acima do ativo — ex.: `{tenant}/orca/{emp}/{ativo}` — está **PROIBIDO**: quebra a integração e obriga refactor.)
2. **Ancorar no DONO** — `{tenant}` na raiz = quem criou o empreendimento. O dado físico mora sob o dono; **acesso é camada de permissão** por cima, não estrutura de path.
3. **Multi-tenancy integrada (BIM) é permissão, não pasta** — no futuro N tenants colaboram no MESMO ativo. Isso se resolve com **identidade estável do ativo** (DB) + permissão de acesso ao path do dono — **jamais** fragmentando o dado por tenant colaborador. O path permanece sob o dono.
4. **Blob pesado no storage, resumo no banco** — o payload CAD/BIM cru vai em `orca/memo-calc/{mc}/levantamentos/`; o banco guarda só o **manifesto** (`memo_calc.mc_levantamentos`) + o **resumo/qtd** (`memo_calc_item`). Ver o schema de `ativo.memo_calc*`.
5. **Privado de verdade** — usar `save_private_file`/`open_private_file`/`delete_private_file`; a URL (assinada no R2) é gerada **na leitura** a partir da `r2_key`. **Nunca persistir URL** (expira).

## 3. Fronteira com o público (INTOCÁVEL)

O **catálogo** (fontes/edições: xlsx, critérios, LS, fichas, cadernos, CTC) é **global/compartilhado entre tenants** — NÃO é por-tenant. Permanece **exatamente onde está**: `easy/fontes/...` no bucket **público** (`axys-public`), governado por `storage_paths.py`. **Este contrato não toca nisso.**

## 4. Implementação

- Helper único (hoje em `backend/modules/ativo/memoria_service.py`): `_priv_ativo(tenant, emp, atv, *parts)` → `easy/{tenant}/{emp}/{ativo}/<parts>`. Ex.: `_priv_ativo(t, e, a, "orca", "memo-calc", mc_id, "midias", nome)`.
- **Pendência:** quando um 2º produto precisar do layout, promover o helper a um módulo de paths privado (espelho do `sp` público), e este contrato passa a ser o ponto único citado por ambos.
