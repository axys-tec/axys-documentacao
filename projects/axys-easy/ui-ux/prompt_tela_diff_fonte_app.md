# Briefing de Tela — Diferença Fonte × App (conciliação de custo por edição)

> **Como usar:** cole `docs/projects/axys-easy/ui-ux/prompt_nova_tela.md` (template canônico) +
> este briefing no início da sessão. Ler os arquivos da "LEITURA OBRIGATÓRIA" ANTES de codar.
> Regra de negócio-mãe desta tela: **[CATALOGO_BUSINESS_RULES.md](../contracts/catalogo/CATALOGO_BUSINESS_RULES.md) §4.3**
> (semântica fonte cru × calculado × BDI). Espelha o layout de `catalogo/edicao_form.html`.

---

## Nome da funcionalidade
Diferença Fonte × App — conciliação de custo publicado (fonte) contra o custo processado pela app, por edição.

## Módulo
Catálogo

## Tipo de tela
**LIST somente-leitura** (diagnóstico/conciliação). Sem cadastrar, editar, inativar/reativar,
sem modal de confirmação. Herda `base/base_sidebar.html`, `sidebar_catalogo.html`.

## URL
`GET /edicoes/{edi_id}/diff-fonte-app`  (query opcional `?uf=SP`)

## Breadcrumb
`Início › Edições › Diferença`  (Edições → `/edicoes`)

## Ponto de entrada
Botão **"Ver Diff"** na listagem `/edicoes` (por linha de edição), abrindo esta rota com o `edi_id`.

## Tabela(s) do banco envolvida(s)
- `catalogo.composicoes_custo` (cc_) — números da conferência (fonte, calculado, diferença, status)
- `catalogo.composicoes` (cmp_) — identidade (código/descrição/unidade); junção `cc_cmp_id = cmp_id`
- `catalogo.edicoes` (edi_) — cabeçalho da edição (data-ref, fonte, código-versão)
- `catalogo.fontes` (fte_) — fonte-base abreviada; junção `cmp_fte_id = fte_id`
- `catalogo.edicoes_leis_sociais` (els_) — badge de LS
- `catalogo.edicoes_bdi` (ebd_) — **badge de BDI + chave da des-BDInização** (LEFT JOIN; pode não existir)

## Layout (espelha `edicao_form.html`, porém somente-leitura)
1. **Breadcrumb** (acima).
2. **Linha 1 (identidade da edição)**, após o mapa: **Fonte-Base (abreviada)** · **Data-Ref** · **Código-Versão**
   (read-only, estilo da 1ª linha do `edicao_form.html`; não é `<form>`).
3. **Tabs de UF** — uma aba por UF vinculada à edição; troca a UF re-consulta (querystring `?uf=`).
   UF ativa = a `?uf=` (default `SP`).
4. **Badges** (abaixo das tabs): **Leis Sociais** (label da LS da edição/UF) **+ BDI padrão da fonte**
   (de `edicoes_bdi.ebd_percent`; **se a edição não tem BDI publicado → não renderiza o badge**).
5. **Filtro — Modo de exibição** (barra `.cpu-filter-bar`, ANTES da listagem) — ver seção "Filtro" abaixo.
6. **Listagem** (tabela padrão `catalogo_work_pages.md`: `ae-table-wrap` rola, `thead` sticky,
   `AXYS.makeSortable`):

| Código | Descrição | Unid | Custo Easy | Custo Fonte | Custo Fte c/ BDI ⁽¹⁾ | Diferença |
|---|---|---|---|---|---|---|

⁽¹⁾ **A coluna "Custo Fte c/ BDI" só existe (é renderizada) quando a edição tem BDI publicado.**
Sem BDI (SINAPI/CDHU), a tabela tem 6 colunas.

## Filtro — Modo de exibição (listbox, na `.cpu-filter-bar`, antes da listagem)

`<select>` simples **"Modo de exibição"** que filtra por `cc_status_conferencia`. **Usar a
terminologia PERSISTIDA no banco + os rótulos canônicos da app** — dict **`_CONF_LABEL`** em
[composicoes_service.py:806](../../../../backend/modules/catalogo/composicoes_service.py) (NÃO
inventar rótulo novo). **Default = "Com diferença".**

| Opção (rótulo exibido) | `modo` (querystring) | Filtra `cc_status_conferencia` IN |
|---|---|---|
| **Com diferença** ⟵ DEFAULT | `com_diff` | `DIVERGENTE_RELEVANTE`, `DIVERGENTE_ARREDONDAMENTO` |
| Todas | `todas` | (sem filtro) |
| Divergência relevante | `relevante` | `DIVERGENTE_RELEVANTE` |
| Divergência de arredondamento | `arredondamento` | `DIVERGENTE_ARREDONDAMENTO` |
| Sem custo (calculado) | `sem_custo_calc` | `SEM_CUSTO_CALCULADO` |
| Sem custo (fonte) | `sem_custo_fonte` | `SEM_CUSTO_FONTE` |
| Igual | `igual` | `IGUAL` |
| Derivado | `derivado` | `DERIVADO` |

- O default **`com_diff`** já abre a tela mostrando só o que NÃO reconcilia (o caso de uso real:
  achar divergência). "Todas" traz tudo (pode ser dezenas de milhares → paginar).
- Trocar o select **re-consulta** (querystring `?modo=`, junto com `?uf=`). Sem restrição de perfil.
- Backend mapeia `modo → lista de status` (não confiar em string crua do cliente; validar contra o
  conjunto conhecido, cair no default se inválido). Reaproveitar `_CONF_LABEL` p/ os rótulos.

## Mapeamento das colunas (uma query, `LEFT JOIN edicoes_bdi`)
- **Código** → `cmp_codigo` (`.ae-tag-id`, monospace)
- **Descrição** → `cmp_descricao`
- **Unid** → `cmp_unidade`
- **Custo Easy** → `cc_custo_calculado` (valor processado pela app)
- **Custo Fonte** (limpo, comparável) → `CASE WHEN ebd_percent IS NOT NULL THEN cc_custo_fonte / (1 + ebd_percent/100) ELSE cc_custo_fonte END`
- **Custo Fte c/ BDI** → `cc_custo_fonte` (cru) — só quando `ebd_percent IS NOT NULL`
- **Diferença** → `Custo Easy − Custo Fonte(limpo)` (pode vir de `cc_diferenca_valor`, que já é des-BDInizado no import — BUSINESS_RULES §4.3)

Modalidade: expor seletor SD/CD/SE **ou** default SD (confirmar com Renan; a tela é por
(cmp, uf, modalidade) — `composicoes_custo` tem 1 linha por modalidade).

## Regra de cor (conciliação por linha) — o coração da tela
As **células** de **Custo Easy** e **Custo Fonte** (o limpo) recebem fill de fundo:
- **iguais** (|Easy − Fonte-limpo| ≤ tolerância) → **verde com alta transparência**
- **diferentes** → **vermelho com alta transparência**

Tolerância = a de conferência (BUSINESS_RULES §4.1: ≤ 0,5% **ou** ≤ R$ 0,01) — absorve o epsilon
de arredondamento do limpo derivado. A coluna "Custo Fte c/ BDI" **não** entra na cor (informativa).
Cores novas → registrar em `config_ui_ux_easy.md` (usar tokens de sucesso/erro com alpha; não inventar hex solto).

## Ações
Nenhuma de escrita. Apenas: trocar UF (tabs), trocar **Modo de exibição** (listbox — default
"Com diferença"), ordenar colunas.

## Regras de negócio específicas
- **Des-BDInização só quando `edicoes_bdi` existe** para a edição — senão fonte cru vira o "limpo".
- Linhas **sem `cc_custo_calculado`** (ex.: composição sem custo) → exibir Easy vazio; cor neutra
  (nem verde nem vermelho), não forçar divergência.
- É **somente leitura** — o JS para no início se `not pode_ver` (mas leitura é livre p/ o grupo interno).

## Permissões
- Acessar a tela/rota: **`exige_internal_user`** (equipe interna Axys — leitura livre).
- Não há escrita → sem `exige_internal_admin`.

## Backend
- Rota `GET /edicoes/{edi_id}/diff-fonte-app` → `Depends(exige_internal_user)`; params
  `uf: str = Query("SP")`, `modo: str = Query("com_diff")`, (opc.) `modalidade`; `_user_ctx(claims)`;
  `active_section` = catálogo/edições; contexto: edição (identidade), UFs disponíveis, uf atual,
  `modo` atual + opções (rótulos de `_CONF_LABEL`), badges (LS, BDI), linhas.
- Serviço novo: **`get_diff_fonte_app(edi_id: int, uf: str = "SP", modo: str = "com_diff", modalidade: str = "SD") -> dict`**
  em `composicoes_service.py` — devolve `{edicao:{...}, ufs:[...], ls:{...}, bdi:{...}|None, modo, linhas:[...]}`
  com a query única (`LEFT JOIN edicoes_bdi`) + o filtro de `cc_status_conferencia` conforme `modo`
  (mapear `modo → [status]`, validar contra o conjunto conhecido, default `com_diff` se inválido).
  **Não** recomputa custo (lê de `composicoes_custo`).
- Sem `conn.commit()` (leitura). Sem auditoria (nenhuma escrita).

## Observações
- Reaproveita o endpoint órfão `GET /api/composicoes/{id}/custo` (drill-down por composição no futuro).
- Performance: a edição pode ter milhares de composições → paginar/virtualizar como as outras
  listagens do catálogo (padrão `catalogo_work_pages.md`), e a query já filtra por edi_id+uf.
- **Não** confundir com a inversão da listagem principal de composições (passo separado): esta tela é
  o diagnóstico dedicado; a inversão do "número-manchete" da listagem é outra entrega.
