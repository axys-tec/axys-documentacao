# Plano — Rebuild do Catálogo → Migração para PROD (versão 0)

**Status:** RASCUNHO p/ aprovação do Renan (2026-07-04). **Não executar antes de aprovar.**
**Escopo:** master do rebuild — inclui SINAPI/CDHU (feitos em dev), FDE (a fazer) e a migração
dev→prod que produz a "versão 0" da app. **Supersede** a versão anterior deste doc.

---

## 0. Estado atual (2026-07-04)

- **SINAPI (22 edições, 08/2024→05/2026)** e **CDHU (18 boletins, 184→201)** construídos e validados
  em **DEV** via loaders automáticos (`carregar_edicoes_sinapi.py` / `carregar_edicoes_cdhu.py`), com
  **gate de conferência** (para no 1º `DIVERGENTE_RELEVANTE ≥ tol`), publicados em dev.
  - Já feitos (commits desta sessão): **trava de edição por fonte** (SINAPI mês-ref `B3` / CDHU versão
    `A5` — aborta arquivo trocado antes do parse), **get-or-create** (não queima id), **delete-then-insert**
    de itens, **fix RESTRICT** do reimport CDHU (limpa alertas antes do delete), `client_min_messages` no schema.
  - CDHU **195/196**: a fonte-serviço da própria CDHU é inconsistente com a composição dela — **aceito**
    (o valor é a soma do publicado = calc; o Custo Total do serviço é secundário/auditoria). Ver
    [[project_conferencia_divergencia]].
- **PROD** ainda roda os catálogos ANTIGOS (SINAPI/CDHU), com os **documentos publicados no R2** e os
  **paths persistidos no banco** (`ins_external_path`, `cmp_external_path`, `documentos`, `edi_capa_path`).
- **FDE:** pendente. Sandbox `z_search_repos/find_fde/` tem os parsers + os `dist` de várias edições prontos.

## 1. Princípios

- Construir o **histórico (1…n-1)** em **DEV**, validar com o gate, **migrar `catalogo`+`audit` dev→prod**.
- A **edição vigente (n) de cada fonte entra pela ROTA de import da app, em PROD** (operação normal). A
  feature FDE é **forward-only** — **não** há fork/tela para "boletim antigo" (histórico é só script).
- **R2 nunca é reprocessado.** SINAPI/CDHU já têm tudo lá → **preservar** os paths. **FDE não tem NADA
  no R2 → subir novo** (passo-extra, ver §3).

## 2. FDE — o que falta (nesta ordem)

> ⚠️ **RESSALVA (Renan, 2026-07-04): os `dist` históricos (1…n-1) foram STAGED/"maqueados" pelo Codex** —
> não são a saída crua do pipeline real (que parseia PDF direto + pega insumos/cadernos via curl
> autenticado). O terreno foi pavimentado de propósito (import histórico parse-free). Isso **vai pra
> prod** assim. **Implicação:** o **gate de conferência é a GARANTIA de fidelidade** — valida cada `dist`
> comparando o `calc` (Σ itens da composição) contra o `fonte` publicado (des-BDInizado). Artefato de
> staging (coef/preço/BDI inferido torto) = `DIVERGENTE_RELEVANTE` → o loader para (como pegou CDHU
> 195/196). O **pipeline real (PDF+curl) é a fase PREP** (§2.3), para a edição vigente **n** em prod.

**2.1. Loader FDE** (`carregar_edicoes_fde.py`, espelha o do CDHU) — **PRIMEIRO.**
- Consome os `dist` do sandbox (`manifest.json` + `csv/` + `originais/`), importa **parse-free**,
  `pg_advisory_xact_lock(fte_id)`, idempotente por edição, **gate de conferência** ao fim.
- **BDI (a particularidade da FDE — publica CRU com BDI):** `cc_custo_fonte` = publicado CRU **com BDI**
  (auditoria, não se limpa); `cc_custo_calculado` = Σ itens×coef + LS **(limpo)** = o que a app exibe/usa;
  BDI% → `catalogo.edicoes_bdi` (a **presença** da linha sinaliza "fonte com BDI"); a conferência
  **des-BDIniza** o fonte pra comparar: `calc` vs `fonte ÷ (1 + ebd_percent/100)` (BUSINESS_RULES §4.3,
  FDE_IMPORT_CONTRACT §2/§7).
- **PASSO-EXTRA FDE (R2) — diferente de SINAPI/CDHU:** a FDE **não tem NADA no R2 hoje**. O loader FDE
  **sobe os originais/docs da FDE pro R2** (bucket público, layout `CATALOGO_STORAGE_LAYOUT`) **e grava
  os paths no banco** (`ins/cmp_external_path`, `documentos`, `edi_capa_path`). Não há o que preservar — é
  carga nova. (Nas outras fontes o loader não sobe nada; só os dados.)
- **Trava de versão FDE** (análoga a SINAPI/CDHU): validar a edição carimbada no `dist`/`manifest` contra
  a edição informada, antes de gravar.
- **Testar em DEV** (SINAPI/CDHU já validados; só a FDE falta).

**2.2. Tela de import FDE em DEV** (rota in-app IMPORT) — **DEPOIS do loader.**
- Consome um `dist` do **R2 por referência** (edição+versão), parse-free, mesmo status/feedback otimista
  das outras fontes. É a "funcionalidade a partir da edição vigente".
- **REMOVER do `PLANO_UPLOAD_EDICOES_FDE.md` o fork de FRONT histórico** (§5.1 Boletim Antigo / §5.2
  Boletim Atual): não se cria tela de "boletim antigo". (§20 já matava o fork A/B; formalizar a remoção.)

**2.3. PREP (gerador automático do `dist`)** — **por último.** Pros `dist` que já existem, o loader
resolve; a PREP (scraper+parse no worker → `dist` → R2) entra quando for automatizar a edição vigente.

## 3. Preservação / criação dos mapeamentos de doc no R2

- **SINAPI/CDHU — PRESERVAR (já existem em prod):** **antes** do drop de prod, exportar um **CSV** por
  **chave natural** — `(fte_codigo, codigo|cmp_codigo, edi_mes_ref/versao, tipo) → path/url` — cobrindo
  `insumos.ins_external_path`, `composicoes.cmp_external_path`, `catalogo.documentos`, `edicoes.edi_capa_path`.
  **Baixar o CSV pro local.** Após o rebuild em dev, **overlay** desses paths por chave natural (id novo
  resolvido pelo código). O R2 **nunca é tocado** → os paths reacendem sozinhos. Mecanismo já existe em
  `puxar_edicao.py` (copia `cmp_external_path`/`documentos`).
- **FDE — SUBIR NOVO (não existe em prod):** resolvido no próprio loader FDE (§2.1) — sobe pro R2 + patheia.

## 4. Sequência de execução (ordem canônica)

1. **Loader FDE em dev** (com upload R2 + path + gate des-BDI + trava de versão). **Testar.**
2. **Tela de import FDE em dev.** **Testar.**
3. **Exportar o CSV de paths** SINAPI/CDHU de **PROD** (+ baixar pro local). [read-only em prod]
4. **Backup de PROD** (estado atual, antes de qualquer drop) — `gerar_backup_render.py`. **Inegociável.**
5. **DROP local E prod** completos (schemas `catalogo` + `audit`). `ativo`/`tenant_catalogo`/… ficam
   vazios/intactos; SSO/Hub são bancos externos (intocados).
6. **Local — rebuild 1…n-1:** subir todas as edições **HISTÓRICAS** de SINAPI+CDHU+FDE (loaders, gate),
   + **overlay dos paths** SINAPI/CDHU do CSV; FDE já sobe/patheia no próprio loader. (1…n-1 = **todas
   menos a vigente de cada fonte** — os loaders aceitam `--end` p/ excluir a última.)
7. **Migrar `catalogo` + `audit`** dev→prod (`pg_dump` dos 2 schemas → restore em prod; sequences limpos).
8. **Rotacionar o audit:** `criado_por`/`atualizado_por` e o email do rebuild → **"seed inicial" /
   `dev@axys-tec.com.br`** (não "Dev Local").
9. **Backup do prod = "versão 0"** (catalogo + audit) — estado da app ao subir para uso em escala.
10. **Em PROD, pela rota de import da app:** subir a edição **vigente (n) de cada fonte** (SINAPI/CDHU/FDE)
    — valida a operação normal e liga a feature FDE forward-only.
11. **Depois, ISOLADO:** migrar `ativo` (os orçamentos-paradigma do gerador de orçamento paramétrico).

## 5. Riscos / cuidados

- **Backup de prod ANTES do drop** (passo 4) — inegociável.
- **Não deployar durante import** (mata o worker). **Reiniciar o worker após mudar parser** (Celery sem
  hot-reload — a lição recorrente).
- **Segredos FDE em ENV/secret** (nunca `login_data.env` no repo). `restaurar_local.py` (senha) segue gitignored.
- **Conferência pós-carga obrigatória** — o gate dos loaders já faz (para no 1º relevante).
- Migração = **catalogo + audit apenas** (ativo isolado, passo 11).

## 6. Referências

- Loaders: `docs/projects/axys-easy/schemas/backup/carregar_edicoes_{sinapi,cdhu}.py` (FDE a criar).
- FDE: `z_search_repos/find_fde/PLANO_UPLOAD_EDICOES_FDE.md` (§20 vale; front fork a remover — §2.2 acima),
  `docs/.../contracts/catalogo/CATALOGO_FDE_IMPORT_CONTRACT.md`, `CATALOGO_BUSINESS_RULES.md §4.3`.
- Storage R2: `CATALOGO_STORAGE_LAYOUT.md`. Preservação de paths: `puxar_edicao.py`.
- Memórias: [[project_rebuild_catalogo]], [[project_conferencia_divergencia]], [[project_fde_catalogo]],
  [[project_catalogo_docs_r2]], [[project_easy_render_deploy]].

## 7. Decisões travadas (Renan, 2026-07-04)

- **"n" (edição vigente que entra em PROD pela rota) por fonte:**
  - **CDHU = 202 (mai/26)** → dev/migração carrega **184…201**; 202 entra em prod pela rota.
  - **FDE = 04/2026** → dev/migração até a **penúltima**; 04/26 em prod pela rota.
  - **SINAPI = 05/2026** _(Renan escreveu "05/25"; assumido 05/26 pois o dev já tem até 05/26 limpo —
    **confirmar de leve**)_ → dev/migração até **04/2026**; 05/26 em prod pela rota.
- **Ativo: 100% FORA da versão 0** — migra isolado (passo 11). Só `catalogo`+`audit` na versão 0.
