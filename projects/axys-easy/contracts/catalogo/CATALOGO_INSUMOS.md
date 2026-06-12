# Catálogo — Contrato Funcional: Tela Insumos

**Status:** Contrato Funcional (v0.1)
**Data:** 2026-06-12
**Tabelas:** `catalogo.insumos` (+ `insumos_preco`, `insumos_equivalencias`, `insumos_historico`)
**Regras globais:** ver [CATALOGO_BUSINESS_RULES.md](CATALOGO_BUSINESS_RULES.md) — classificação (§2), preço (§3), situação (§6), reimport (§7), gate de manipulação (§8.1), unidades (§8.2).
**Comportamento/UX da tela:** `backend/frontend/templates/catalogo/catalogo_work_pages.md` (seções "Tela: Listagem de Insumos" e "Tela: Edição/Cadastro de Insumo").
**Busca:** ver [CATALOGO_SEARCH.md](CATALOGO_SEARCH.md).
**Acesso:** módulo interno (`is_staff=True`).

> Insumo = item unitário (material, mão de obra, equipamento…) de uma fonte-base. A tela cobre **identidade** (Fase 1), **equivalências entre fontes** (curadoria nossa), **série histórica** de preço e o **registro manual de preço SE por UF/edição** (fontes próprias). Preço por cotação (`CT`) e ficha de insumo seguem na Fase 2.

---

## 1. Modelo (identidade — `catalogo.insumos`)

| Campo | Regra |
|---|---|
| `ins_fte_id` | FK p/ `fontes`. Imutável após criação. |
| `ins_codigo` | Único por fonte (`uq_insumos_fte_codigo`). **Gerado automaticamente** no cadastro manual (padrão da fonte). Não vazio. |
| `ins_descricao` | Texto livre (maiúsculas no front). Não vazio. |
| `ins_unidade` | FK lógica p/ `unidades` (**upsert verbatim** no import — BUSINESS_RULES §8.2). Não vazio. |
| `ins_ti_id` | FK p/ `insumos_tipo` (MAT, MO, EQUIP_AQ, EQUIP_LOC, ENC_COMP, ESP, SERV, `NC`=Não Classificado). |
| `ins_ti_origem` | `FONTE` \| `REGRA` \| `MANUAL`. Precedência no reimport **FONTE > MANUAL > REGRA** (BUSINESS_RULES §2.2). Cadastro manual = `MANUAL`. |
| `ins_ativo` | Vigência (inativar/reativar; ver §9). |
| `ins_external_path` | JSONB — ficha do insumo no R2 (publicação Fase 2; BUSINESS_RULES §11). |

Auditoria de cadastro: `ins_criado_*` / `ins_atualizado_*`. Evolução cadastral entre edições → `catalogo.insumos_historico` (append-only).

---

## 2. Identidade & gate de manipulação (Fase 1)

- **Cadastro/edição de identidade** (descrição, unidade, tipo) exige **`internal_admin` E `fte_permite_manipular_dados = true`** (gate BUSINESS_RULES §8.1). Insumo de fonte de terceiro (importada) abre **somente leitura** — banner explícito.
- **Por que read-only em terceiro:** dado importado é canônico/imutável; correção = **reprocesso da edição** (não edição registro-a-registro). Doutrina em [CATALOGO_EDICOES.md §5](CATALOGO_EDICOES.md) (recall → `EM_REVISAO` → re-import). Sem perfil que dê UPDATE livre em linha importada.
- **Código** é gerado automaticamente; **origem do tipo** de cadastro manual é sempre `MANUAL`. (Não há nota disso no form — é comportamento, não entrada do usuário.)
- **Unidade nova:** o cadastro permite "Outra (digitar)…" → upsert em `unidades` (auditado, `registro_id = codigo`).

---

## 3. Listagem, filtros e busca

Listagem **server-side** (busca + ordenação + paginação, 50/página). Filtros:

- **Funil (básico):** `termo` (descrição) · `fonte-base` (Todas/uma) · **Tipo busca** (Exata × Elástica) · **UF** (define a coluna **Preço**).
- **Régua (avançado):** `tipo` · `unidade` · `modalidade` (SE/SD/CD) · **Apenas inativos** (exibe SÓ inativos).
- **Coluna Preço** = série da `(UF, modalidade)` selecionadas. **SE** é o preço gravado (pelado); **SD/CD** são **derivados** da LS da edição (BUSINESS_RULES §3.1–3.3), nunca linha própria.

**Modos de busca** (detalhe em [CATALOGO_SEARCH.md](CATALOGO_SEARCH.md)):
- **Exata** = `catalogo.unaccent(descricao) ILIKE %palavra%` — *contém a palavra* (grafia exata, sem aproximação). Não é igualdade do termo inteiro.
- **Elástica** = `catalogo.search_document` via `word_similarity` **multi-palavra OR** (cada palavra conta; rankeia por cobertura; tolera erro de digitação). Só sobre **ATIVOS** (o índice de busca só tem entidades ativas) → quando "Apenas inativos" está ligado ou o termo é vazio, cai no SQL tradicional.

---

## 4. Equivalências entre fontes (curadoria NOSSA)

- Tabela `catalogo.insumos_equivalencias` (`ie_*`). Tipos: `EXATA` \| `APROXIMADA` \| `SUBSTITUTA` \| `COMERCIAL` \| `SEMANTICA`. `ie_score`/`ie_metodo` p/ origem automática (fuzzy); curadoria manual entra com tipo.
- **Editável por `internal_admin` em QUALQUER fonte** — inclusive insumo de terceiro (é curadoria nossa, **não** usa o gate §8.1).
- **Modal de vínculo:** busca **elástica** (opcionalmente **isolada na fonte**), **multi-seleção** (cada item escolhido vira uma linha com seu próprio tipo; "Confirmar N"). O **código do equivalente é link** → `/insumos/{id}/editar`.

---

## 5. Cadastrar "clonando" (a partir de selecionado)

Com um insumo selecionado na listagem → botão **Cadastrar** abre `/insumos/novo` **pré-preenchido** com `descrição/unidade/tipo` do selecionado, **sem a fonte** (o usuário escolhe a fonte-base própria). Acelera cadastro de itens análogos em fonte AXYS.

---

## 6. Série Histórica (modal)

Modal grande (~80%) aberto por linha selecionada. Mostra a evolução de preço do insumo.

- **Subtítulo:** `fonte | **código** | **descrição** | unidade`.
- **Controles:** Índices · Máximo (toda a faixa) · Data inicial/final · **UF** · **Modalidade** (SE/SD/CD). Trocar **UF** re-busca a série (server); trocar modalidade/índice re-renderiza (client).
- **Gráfico (Chart.js, eixo Y sempre R$):** linha de preço real; **índice sobreposto em R$** = preço-âncora (1º preço) corrigido pela variação do índice (`basePreço × índice/índice_âncora`) — **não** base-100.
- **Tabela:** `Data | Valor | LS% | <variação dos índices selecionados>` (variação acumulada desde o 1º preço).
- **Histórico de Registros:** eventos de `insumos_historico` (ALTERACAO/INATIVACAO/REATIVACAO; **exclui** CRIACAO).
- **Fontes de dado:** `insumos_preco` (série) + `edicoes_leis_sociais` (LS p/ SD/CD) + `indices` / `indices_historico` (overlay). Botão **"Gerar Análise"** = placeholder (IA — Fase 2).

---

## 7. Preço SE por UF / edição (registro manual)

Entre o form principal e Equivalências, na tela de edição do insumo:

- **27 abas de UF**; campo único = **preço SE (R$)** da UF ativa. Grava em `catalogo.insumos_preco`: `pri_modalidade='SE'`, `pri_origem='C'`, `pri_sit_id` = COM_PRECO, por `(pri_ins_id, pri_edi_id, pri_uf, 'SE')` (upsert na UNIQUE).
- **Listbox de edição** (à direita): todas as edições da fonte-base (default = mais recente). Trocar a edição **re-busca os preços** daquela edição → permite **interoperar** preços entre edições. Edição inválida p/ a fonte cai na mais recente.
- **Salvar afeta SÓ a UF editada** — nunca cria linha zerada nas demais UFs. **Incluir** (sem preço) × **Editar** + **×** (com preço), ações à direita.
- **Gate:** só fonte com `fte_permite_manipular_dados` (terceiro = read-only). **Auditado** (só se o valor mudou).
- **SD/CD** continuam **derivados** das LS (não se gravam como preço de insumo). Cotação de mercado (`CT` + `insumos_cotacoes`) = Fase 2 (BUSINESS_RULES §3.5).

---

## 8. Permissões

| Ação | Permissão |
|---|---|
| Abrir listagem / form / histórico (GET) | `internal_user` |
| **Cadastrar/editar identidade** | `internal_admin` **+** `fte_permite_manipular_dados` (gate §8.1) |
| **Registrar/remover preço SE por UF/edição** | `internal_admin` **+** gate (idem) |
| Inativar/reativar | `internal_admin` **+** gate |
| **Equivalências** (criar/remover) | `internal_admin` (curadoria nossa — **sem** gate) |

**Regra de paridade:** o que o usuário **não pode** fazer com um insumo em `/insumos`, também **não pode** em `/edicoes` (mesmo gate, mesma permissão).

## 9. Vigência (inativar/reativar)
`ins_ativo`. Inativação/reativação são otimistas no front, auditadas, e registram evento em `insumos_historico` (INATIVACAO/REATIVACAO). Inativo não aparece na busca elástica (índice só ativo) — use "Apenas inativos".

## 10. Auditoria
Escrita em `audit.logs` (`log_tabela='insumos'` / `'insumos_preco'` / `'insumos_equivalencias'` / `'unidades'`), snapshot antes/depois, na **mesma transação** da escrita (atômico). `acao ∈ {INSERT, UPDATE, DELETE}`. `log_registro_id` é TEXT — preço usa chave composta `f"{ins_id}/{edi_id}/{uf}"`; unidade usa o `codigo`. Sem mudança = sem gravação/auditoria.

## 11. Pontos abertos (a revisar)
- **Ficha de insumo (R2):** `ins_external_path` + publicação/registro em `catalogo.documentos` (gate `edi_ins_catalogo_ok`) — pipeline em [CATALOGO_EDICOES.md §8.1](CATALOGO_EDICOES.md).
- **Preço por COTAÇÃO (`CT`)** + `insumos_cotacoes` + upload de propostas/certidão (R2 privado) — BUSINESS_RULES §3.5, entra com as telas de fonte própria (AXYS).
- **Modelo contínuo** de insumo/composição (identidade vigente + custo denso + histórico esparso) — BUSINESS_RULES §9.5–9.6, Fase 2.
- **"Gerar Análise"** (IA sobre a série) — placeholder.
