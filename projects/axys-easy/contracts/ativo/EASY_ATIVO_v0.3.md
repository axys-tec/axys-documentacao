# Módulo Ativo — Evoluções v0.3 (consolidação canônica)

**Status:** Canônico. Complementa (não substitui) o contrato arquitetural v0.2 e o sumário
executivo v0.2 — registra as decisões tomadas em **2026-06-14** que já estão no `schema.sql`.
**Data:** 2026-06-14
**Fonte da verdade do schema:** `docs/projects/axys-easy/schemas/schema.sql` (bloco "MÓDULO ATIVO").
**Rascunho/história da negociação:** `docs/projects/axys-easy/schemas/proposta_ativo.sql`.

> Lê-se assim: o v0.2 (arquitetural + sumário) continua valendo na **tese** (árvore por
> `parent_id + ordem + path`, numeração derivada, preço resolvido, JSON = verdade da memória,
> isolamento por tenant). Este v0.3 registra **o que mudou/entrou** desde então. Onde houver
> conflito, **v0.3 prevalece**.

---

## 0. Contexto

- **Catálogo é consumido COMO ESTÁ.** A "Fase 2 (drop+recriar banco)" do
  `CATALOGO_NEXT_STEPS.md` foi **CANCELADA** (Renan, 2026-06-14). Custo@edição já é resolvível
  no modelo atual (composição é por edição). Ativos não exige nenhuma mudança no Catálogo.
- **Schema promovido.** O domínio Ativo foi escrito como proposta validada (parse formal OK;
  revisada contra `DDM JALES.xlsm` e `axysCAD_contract.md`) e **promovido para o `schema.sql`**.

## 1. Aplicação em dev (importante)

> **NÃO recriar o banco.** Aplicar em dev = **criar apenas** os 3 schemas novos
> (`ativo`, `tenant_catalogo`, `arquivo`). `catalogo` e `audit` **permanecem intactos**.

O bloco "MÓDULO ATIVO" do `schema.sql` é **independentemente executável**: tudo é
`CREATE ... IF NOT EXISTS` e as únicas FKs cross-schema apontam para tabelas que **já existem**
(`catalogo.edicoes`, `catalogo.insumos_tipo`). Rodar esse bloco cria só o novo, sem tocar o resto.
**RLS:** políticas **adiadas** (as colunas `tenant_uuid` já entram; habilitar quando liberar tenants).

## 2. "Catálogo de Ativos" — árvore única + drivers

- **Árvore ÚNICA, sem espelhar/duplicar.** O **orçamento-modelo é um ATIVO comum** marcado
  `ativos.atv_is_catalog_source = TRUE`. Gerar orçamento = copiar a subárvore do modelo para o
  ativo do tenant + rodar os drivers contra a ficha. (Descartado o enum `atv_origem`/`MODELO_AXYS`.)
- **`atv_tenant_uuid` NUNCA nulo** — a Axys tem **tenant próprio (role interna)**; modelos usam
  esse tenant, não linhas órfãs.
- **Drivers** (produto vendável; única frente que a Axys popula): `ativo.drivers`
  (`drv_regra_json` JSONB = a regra/fórmula; `drv_tenant_uuid` NULL = global Axys) +
  **tabela-ponte** `ativo.ativo_itens_drivers` (N:N — só existe linha quando o item usa driver,
  sem NULL em massa). Um item soma vários drivers; um driver serve vários itens.
- **Dogfood:** o modelo é editado na MESMA grade do Ativo (a Axys usa o próprio produto); o
  gerador é "copy-subtree + drivers", sem importador separado.

## 3. Ficha técnica — enxuta (tipo + valor)

- `ficha_parametros` = **lookup GLOBAL** (vocabulário semeado pela Axys; entrada que os drivers
  leem). **Removidos** `par_tenant_uuid` (é para todos) e `par_meta_json` (evoluir = migration).
- `ficha_atributos` = valores por ativo (colunas tipadas).
- É o **mesmo padrão tipo+valor** de `ativo_diversidades_*` — não EAV elástico. Não se colapsa
  porque os drivers precisam do **vocabulário compartilhado** (`par_codigo`).

## 4. `ativo_itens` — validado contra orçamento real (DDM Jales)

- Coluna M do Excel (NÍVEL 1–5 / SERVIÇO) = **profundidade derivada** de `ati_parent_id` +
  `ati_tipo` (GRUPO p/ os níveis-título, SERVIÇO p/ a folha). Numeração "1.2.3" = **render**
  (`ati_path`), não dado.
- **5 níveis + serviço** é a **convenção de produto**; o schema permite mais (parent_id).
- A planilha **mistura fontes por linha** (CDHU+SINAPI+FDE+PRÓPRIA+COT) → `ati_cmp_origem`
  (CATALOGO/TENANT/LOCAL) + multi-`orcamento_parametros` (`UNIQUE(atv_id, fonte)`) já suportam.

## 5. BDI e Leis Sociais (novos)

- **BDI** — `ativo.ativo_bdi` (+ `ativo_bdi_composicao`): **composto** (parcelas) e **MÚLTIPLO**
  por obra (1+). `abd_tipo ∈ ONERADO|DESONERADO|REDUZIDO` (normal onerado/desonerado + reduzido
  p/ equipamento). **Default por obra** (`abd_default`). **Cada linha recebe um BDI**
  (`ativo_itens.ati_bdi_id`; NULL em título/não-precificável).
- **Leis Sociais** — `ativo.ativo_ls` (+ `ativo_ls_composicao`): **composta** e **ÚNICA por obra**
  (`UNIQUE(atv_id)`). `als_tipo ∈ ONERADA|DESONERADA`; % horista/mensalista.
- Saíram de `orcamento_parametros`: `opa_ls_percent`, `opa_bdi_percent`.
- **[VALIDAR]** `opa_modalidade` (SD/CD) pode ser redundante com `ativo_ls.als_tipo` — manter por ora.

## 6. Cronograma físico-financeiro (novo)

- `ativo.cronograma` (+ `cronograma_itens`): fasiamento do valor por **período**. Feito por
  **NÍVEL, até o limite n-1** do orçamento (`cro_nivel_corte`): tudo abaixo do "guarda-chuva"
  segue o padrão dele. (Curva ABC, Capa, Resumo permanecem **derivados** — sem tabela.)

## 7. Documentos do ativo / "repo-paradigma" (novo)

- **Registro REAL, não JSONB de cabeçalho** (mesma lição do `catalogo.documentos` que substituiu
  `ins_external_path`): `ativo.ativo_diversidades_tipo_catalog` (lookup; seed = disciplinas
  ARQ/EST/ELE/HID/MEC/GAS) + `ativo.ativo_diversidades_catalog` (`adc_atv_id`, `adc_adt_id`,
  `adc_descricao`, `adc_path`). (Descartado o `atv_docs_json`.)
- PM (Easy ProjectManager) **não agora** — reservado `ativo_pm`.
- **[VALIDAR]** sufixo `_catalog` (EN) vs `_catalogo` (PT).

## 8. `tenant_catalogo` — biblioteca do tenant (a "bucha" resolvida)

- **Replicação MÍNIMA:** `insumos` + `insumos_preco` + `composicoes` + `composicoes_itens`.
  **SEM `composicoes_custo`** — custo de CPU do tenant é **calculado ao vivo** (Σ coef × preço).
- **Cotação (5.a):** sem tabela própria — é insumo do tenant com `insumos_preco.pri_origem`
  (PROPRIA/PESQUISA/COTACAO…).
- **Classificação:** `insumos.ins_ti_id` FK ao lookup **global** `catalogo.insumos_tipo`
  (MO/MAT/EQUIP… — consistência p/ histograma).
- **A bucha (a.3):** item de composição do tenant referencia **insumo OU composição**, vindo do
  **catálogo GLOBAL ou do TENANT** → dois discriminadores `ci_ref_origem` (CATALOGO|TENANT) +
  `ci_ref_tipo` (INSUMO|COMPOSICAO) + `ci_ref_id` (FK **polimórfica resolvida pelo app**, sem FK
  física). Mesmo `oci_ref_tipo` no fork local de orçamento.

## 9. Memória de cálculo — plugin/API **ou** manual

- **Duas origens, MESMO schema.** `memo_calc.mc_origem ∈ CAD|RVT|IFC|MANUAL`.
  - **Plugin/API:** `mc_json_cru` (payload `axys-cad-v1` bruto) = verdade; CHECK exige json.
    Colunas de `memo_calc_item` alinhadas ao **axysCAD §8**: `mci_capture_id`, `mci_local`
    (location_or_floor — âncora obrigatória), `mci_collector`, `mci_quantity_type`,
    `mci_coeficiente_json`, `mci_status` (SYNCED|**SUPERSEDED**). `UNIQUE(atv_id, arquivo)` =
    UPSERT idempotente por arquivo (axysCAD §9).
  - **MANUAL:** `mc_json_cru` NULL (verdade = os `memo_calc_item` digitados); colunas de plugin NULL.
- Vínculo bloco↔item = `memo_item_link` N:N (`mil_tipo` DIRECIONADO|GLOBAL). Entidade **sem
  unicidade** (cláusula fidelidade-não-correção do axysCAD §1.1).

## 10. Arquivamento por tenant (desconstrução/reconstrução)

- Schema `arquivo` + `arquivo.arquivamentos` (registro: status ARQUIVADO/RESTAURADO/PURGADO,
  destino R2/schema-frio, hash, `tabelas_json`, `expira_em` = +5 anos).
- **Fronteira:** o **Hub manda** (regra de licença/limites/cadência/cobrança/purga); o **Easy
  apenas executa** `desconstruir(tenant)` / `reconstruir(tenant)`. Detalhe em
  `docs/projects/axys-easy/contracts/EASY_HUB_ARQUIVAMENTO.md`.
- **Recorte determinístico:** `tenant_uuid` só nas raízes + folhas por FK; `catalogo` é global
  (nunca entra). **Reconstrução preserva IDs** (PKs `GENERATED BY DEFAULT` → reinsert com id original).

## 11. Convenções e limpezas

- **`meta_json` removidos** (`emp_meta_json`, `atv_meta_json`, `par_meta_json`) — anti
  escape-hatch ("não ligo de ter, ligo de nunca usar"). Os JSONB que ficam são **verdade
  estrutural** (`mc_json_cru`, `rev_snapshot_json`, `ati_ajuste_json`, `drv_regra_json`,
  `mci_*`/entidades), não balde.
- **PKs `GENERATED BY DEFAULT`** (não ALWAYS) — permitem reinsert na reconstrução.
- **`ati_path` TEXT** zero-padded (ltree não instalado); índice de navegação **derivado**.
- **`tenant_uuid` UUID sem FK física** (Hub é banco separado, `EASY_HUB_DB_URL`).

## 12. Pendências conscientes (não bloqueiam)

- Banco dev ainda **não aplicado** (criar só os 3 schemas novos — §1).
- RLS adiada. `drv_regra_json` (formato da fórmula) a detalhar quando o gerador nascer.
- `opa_modalidade` × `als_tipo`; sufixo `_catalog`/`_catalogo`; lógica fina do cronograma.

---

**Próximo (combinado com Renan):** montar **uma tela + abrir discussão** antes do plano de ataque.
