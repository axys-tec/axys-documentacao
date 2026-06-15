# Módulo Ativo — Sumário Executivo

**Status:** Contrato Canônico (v0.2) — ⚠️ evoluído por **v0.3** (`EASY_ATIVO_v0.3.md`); onde houver conflito, v0.3 prevalece.
**Data:** 2026-06-13
**Horizonte:** Implementação em fases (Ativa após Catálogo concluído)

> **v0.2:** evolui a v0.1 preservando a tese central (árvore por `parent_id + ordem + path`, numeração derivada). Incorpora: empreendimento/ativo, ficha como parâmetros+atributos, catálogo do tenant, orçamento por exceção, contexto de preço rotacionável, memória de cálculo enxuta e revisões congeladas. DDLs são **proposta a validar a cada import**.

---

## Tese em Uma Frase

O número `1.2.3` é **render, não dado**. A verdade mora na árvore (`parent_id + ordem + path`); o preço é **resolvido**, não gravado; a memória de cálculo é **JSON cru**; a revisão é **snapshot congelado**.

## Empreendimento × Ativo

- **Empreendimento** = agrupador puro (sem ficha, sem motor). Relatório consolidado = `WHERE emp_id = X`.
- **Ativo** = objeto técnico real (obra, projeto, edificação, contrato). Tudo se conecta a ele.
- Um ativo pertence a **0..1** empreendimento (`atv_emp_id` nullable — obra avulsa existe).

## Três Camadas de Conhecimento

| Schema | É | Quem edita |
|---|---|---|
| `catalogo` | Conhecimento canônico (SINAPI, CDHU…) | Axys (global, read-only p/ tenant) |
| `tenant_catalogo` | Biblioteca técnica do tenant (CPUs/insumos próprios) | Tenant (isolado) |
| `ativo` | Contexto operacional (obra concreta) | Tenant |

**Tenants nunca tocam no catálogo.**

## Princípios Não-Negociáveis

1. **Refatoração quase proibida** — nasce escalável, sem overengineering.
2. **Numeração derivada** — `1.2.3` é cálculo no render.
3. **`tipo` define comportamento, não profundidade.**
4. **Preço resolvido, não persistido** — só a emissão congela.
5. **Catálogo dinâmico / orçamento estado** — emitido não muda sozinho.
6. **JSON cru = verdade da memória de cálculo.**
7. **Isolamento por tenant nas raízes + RLS**, decidido na origem.
8. **Namespace reservado ≠ tabela criada.**

## Decisões-Chave (o que evita refactor)

- **Discriminador de origem da composição** (`ati_cmp_origem ∈ CATALOGO|TENANT|LOCAL`) — resolve a FK polimórfica antes de virar dívida.
- **Sem `custo_base` imutável** — o imutável é o vínculo; preço resolve contra a edição do contexto.
- **Contexto de preço rotacionável** (`orcamento_parametros`: edição-base, LS, BDI, UF, modalidade) — LS muda preço, BDI é margem acima.
- **Memória enxuta** — `memo_calc` (JSON cru) + `memo_calc_item` (bloco) + ponte **N:N** `memo_item_link`. Sem entidades/overlays relacionais (overlay é derivado no viewer).
- **Revisão = JSON snapshot + resumo denormalizado** — não espelha 7 tabelas-gêmeas.
- **Ficha = parâmetros + atributos** com valor tipado — cresce sem migration; análise por view pivotada.

## Árvore Consolidada

**(MVP)** nasce agora · **(reservado)** sem DDL hoje.

```
catalogo  (global, Axys)
  fontes · edicoes · unidades · insumos(+preco) · composicoes(+itens,+custo) · search_document

tenant_catalogo  (MVP)
  insumos(+preco) · composicoes(+itens,+custo)

ativo
├── empreendimentos                  (MVP · agrupador puro)
└── ativos                           (MVP · objeto técnico)
    ├── ativo_ficha_tecnica          (MVP)
    │   ├── ficha_parametros
    │   └── ficha_atributos
    ├── ativo_itens                  (MVP · árvore canônica + origem CATALOGO|TENANT|LOCAL)
    ├── orcamento_parametros         (MVP · contexto de preço rotacionável)
    ├── orcamento_composicoes        (MVP · fork local)
    │   └── orcamento_composicoes_itens
    ├── orcamento_insumos            (MVP · fork local)
    │   └── orcamento_insumos_preco
    ├── memo_calc                    (MVP · json_cru imutável)
    │   └── memo_calc_item           (bloco · qtd_calculada + entidades)
    ├── memo_item_link               (MVP · ponte N:N)
    ├── ativo_revisoes               (MVP · snapshot_json + resumo)
    ├── ativo_eventos                (MVP · trilha)
    │  ──── reservado (entra com o microapp) ────
    ├── ativo_docs · ativo_pm · ativo_diario
    └── ativo_fin · ativo_licit · ativo_repo

audit  logs · api_logs · login_logs
```

## Objetivos do Módulo

1. Lançar orçamento (portal, import, API).
2. Gerar relatórios (individuais e consolidados).
3. Liberdade operacional de montagem (grade viva).
4. Ajuste de preço **bidirecional** (aplica/volta sem perder a base).
5. Memória de cálculo rastreável (CAD agora, RVT/IFC futuro · idempotente, mesmo contrato JSON).
6. Escalabilidade (mesma árvore: orçamento, EAP, cronograma, medição).
7. Preparação para IA assistiva (entidades estruturadas, não texto).

## Métodos de Levantamento

- **Global (aberto):** LISP no cabeçalho, levanta livre, associa pela disciplina dos códigos (GLOBAL).
- **Direcionado:** LISP na linha, já programado com o item (DIRECIONADO), menor erro.
- Mesmo schema para ambos; muda só `mil_tipo`. Axys **não** fatia entidades no import — granularidade é a montante. LISP vs plugin é decisão futura que **não** afeta o schema.

## Microapps (operam sobre o Ativo)

Easy Price (ficha), Easy CPU (composições), Easy Orça (consolida/emite), Easy Docs (ficha+IFC+memórias), ProjectManager, BuildDiary, FinControl, LicitPlan. Cada um recebe schema no seu slot reservado **quando nascer** — sem refatorar placeholder.

## Roadmap

| Fase | Objetivo | Status |
|---|---|---|
| 1 Contrato + Schema | `ativos`, `ativo_itens`, ficha, orçamento, memória, revisões, tenant_catalogo | ✅ Contrato v0.2 |
| 2 Backend Estrutural | APIs move/copy/indent, resolução de preço, rotação de edição | Futuro |
| 3 Grade Operacional | UI planilha hierárquica | Futuro |
| 4 Derivados | ABC, histograma, exports | Futuro |
| 5 Convergência Microapps | Price, CPU, Orça integrados | Futuro |
| 6 IA Assistiva | Sugestões, validação, geração de docs | Futuro |

---

**Pergunta correta ao codificar:**
> "Como preservo a liberdade de montagem sem perder consistência estrutural, financeira e auditável?"

Não: "Como salvo essa linha?"



---

## MVP de Entrega — Terça (escopo congelado)

**Meta:** app capaz de **cadastrar um orçamento (CRUD simples)** e **importar orçamento (import total)**, ambos escrevendo na mesma `ativo_itens`.

**Regra do prazo:** modelo correto, features finas. O que não pode estar errado é o *data model* (não-refatorável). O resto é incremento.

### Sobe (a espinha vertical)

- **`ativos`** — CRUD simples (regramentos básicos de cadastro). Já com `atv_tenant_uuid` e `atv_emp_id` nullable.
- **`ativo_itens`** — a árvore canônica (`parent_id + ordem esparsa + path + tipo + descricao + cmp_origem + cmp_id + quantidade + unidade`). É o orçamento.
- **Primitivas de árvore (backend)** — criar (insert com ordem esparsa), indentar (`parent_id` + recalcula `path` do subtree), mover, deletar. **Maior risco técnico dos 3 dias — acertar estas quatro.**
- **`orcamento_parametros`** — uma linha: `fonte + edicao_id + uf + modalidade`. LS/BDI como coluna, podem nascer null/zero.
- **Resolução de preço ao vivo + autocomplete do catálogo** — vincula composição (`origem='CATALOGO'`), resolve `custo@edição`, `total = qtd × unit` (reusa o resolver do Catálogo).
- **Grade funcional** — adicionar linha, editar inline, botões indentar/promover, expandir/colapsar, numeração derivada no render.
- **Import total** — mapper "linhas → árvore" escrevendo na **mesma** `ativo_itens` (outra porta de entrada, não outro modelo).

### Corta para terça (sem gerar refactor)

| Corta | Por que é seguro |
|---|---|
| `ficha_*` (parâmetros/atributos) | Decidido: sobe depois, por INSERT. |
| `tenant_catalogo` + CPU própria | Usar só `origem='CATALOGO'`; coluna já prevê TENANT/LOCAL. |
| `orcamento_composicoes/insumos` (fork/override) | MVP só lê catálogo; `ati_ajuste_json` nasce null. |
| `memo_calc` + import CAD/JSON | Sistema à parte; não bloqueia cadastro/import de orçamento. |
| `ativo_revisoes` / emissão | Só estado vivo; snapshot depois. |
| Políticas RLS | Defere a *política*, **mantém a coluna** `tenant_uuid`. |
| Tela de empreendimento | `emp_id` nullable; tela depois. |
| Atalhos de teclado / drag-and-drop | Botões primeiro; teclado é polimento. |

### Seguro barato — colunas que nascem agora (custo quase zero)

Mesmo sem uso no MVP, deixar no schema desde já (são colunas, não features — retrofitá-las depois é o caro):
`tenant_uuid` nas raízes · `ati_cmp_origem` (mesmo só usando CATALOGO) · `ordem` esparsa · `path` · `emp_id` / `ati_ajuste_json` / `opa_ls_percent` / `opa_bdi_percent` nullable.

### Princípio do MVP

> Subir uma **fatia fina de um modelo correto**, nunca uma fatia gorda de um modelo errado. Import e cadastro escrevem na mesma `ativo_itens` — nenhum trabalho é descartado quando os módulos cortados entrarem.