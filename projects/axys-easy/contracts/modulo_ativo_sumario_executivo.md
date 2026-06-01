# Módulo Ativo — Sumário Executivo

**Status:** Contrato Canônico (v0.1)  
**Data:** 2026-05-31  
**Horizonte:** Implementação em fases (Ativa será após Catálogo concluído)

---

## Por Que o `orca.servicos` Atual é Inadequado

| Limite | Problema | Impacto |
|---|---|---|
| `srv_nivel IN ('GRUPO', 'SUBGRUPO', 'ITEM')` | 3 níveis semânticos fixos | Não suporta profundidade arbitrária (realidade de projetos) |
| Nível = profundidade | Confunde tipo com hierarquia | Impossível reutilizar para EAP, cronograma, medição |
| Sem `parent_id` + `path` | Não há índices de hierarquia | Movimentos de bloco custam rebalanceamento em massa |

## Decisão Canônica

```
Árvore orientada por (parent_id + ordem esparsa + path)
com numeração DERIVADA (não persistida)
e UX de grade operacional (não modal)
```

### Estrutura Alvo

```sql
orca.ativos              -- agregação de itens
orca.ativo_itens         -- linhas hierárquicas
  ati_parent_id          -- self-reference (NULL = raiz)
  ati_ordem              -- esparsa (1000, 2000, 3000…)
  ati_path               -- hierárquico (0001.0002.0003)
  ati_tipo               -- GRUPO, SERVIÇO, SUBTOTAL, OBSERVAÇÃO, TEXTO…
  ati_*                  -- custos, composição, quantidade
```

**Resultado:** inserir item entre dois irmãos = 1 INSERT, numeração visual auto-recalcula.

## Três Princípios Não-Negociáveis

### 1️⃣ Numeração é Derivada

`1.2.3` é **render**, não dado. Mover bloco não atualiza nenhuma coluna de texto — apenas `parent_id`, `ordem`, `path`.

### 2️⃣ Tipo Define Comportamento, Não Profundidade

`tipo = GRUPO` significa "agregável", não "nível 1". Profundidade vem de `parent_id`.

### 3️⃣ UX é Grade Viva, Não Formulário

Usuário não "cadastra serviço em modal". Monta estrutura na grade com teclado (Insert, Tab, Shift+Tab, Ctrl+C/V).

## Microapps Convergem para Mesma Árvore

| App | Entrada | Saída |
|---|---|---|
| **Easy Price** | Tipologia | Estrutura inicial (ativo) |
| **Easy CPU** | Catálogo + ativo | Análise de composições, ABC, histograma |
| **Easy Orca** | Ativo (rascunho) | Orçamento oficial (snapshots, emissão) |
| **Cronograma** | Ativo (itens) | Duração, predecessoras, calendário |
| **Medição** | Ativo (itens) | Medido anterior/atual, saldo, % executado |

Todos alimentam/consomem `orca.ativo_itens`. Sem fragmentação.

## Roadmap: 6 Fases

| Fase | Objetivo | Status |
|---|---|---|
| 1️⃣ Contrato + Schema | Definir `ativo_itens`, migrations | ✅ Contrato pronto |
| 2️⃣ Backend Estrutural | APIs de move/copy/indent | Futuro |
| 3️⃣ Grade Operacional | UI de planilha hierárquica | Futuro |
| 4️⃣ Derivados | ABC, histograma, exports | Futuro |
| 5️⃣ Convergência Microapps | Price, CPU, Orca integrados | Futuro |
| 6️⃣ IA Assistiva | Sugestões, validação, geração docs | Futuro |

## Integrações CAD/BIM — Rastreamento de Origem

Cada item rastreia origem de levantamento via `ati_memo_calc_tipo`:

**Fase 1 (Em andamento):**
- ✅ **AxysLisp** (CAD) — submodule, 2 fluxos (genérico / por-item)

**Fase 1 (Futuro):**
- ⏳ **AxysRVT** (Revit) — add-in próprio

**Fase 2 (Futuro):**
- ⏳ **AxysIFC** (IFC) — agnóstico de plataforma

### 🔐 Contrato de JSON Obrigatório

**Imperativo na implementação:**

Independente da origem (CAD, Revit, IFC), o JSON **deve seguir contrato único**. Easy lê TODOS da mesma forma.

| Aspecto | Regra |
|---|---|
| Estrutura | Padronizada (um só esquema) |
| Campos | Documentados, sem variações por origem |
| Leitura | Idêntica (CAD = Revit = IFC) |
| Rejeição | JSONs não-conformes são recusados |

Cada origem (AxysLisp, AxysRVT, AxysIFC) exporta o **mesmo contrato JSON** — detalhe a ser especificado em `docs/api/memo_calc_json_contract.md`.

Cada origem carrega provenance (CAD versão, RVT GUID, IFC checksum) para auditoria e validação de IA.

---

## Agora: Catálogo

✅ Fontes-Base (implementado)  
⏳ Insumos (próximo)  
⏳ Composições  
⏳ Cadernos, Critérios

Ativa vem **depois** do Catálogo fechado.

---

**Pergunta correta ao codificar:** 
> "Como preservo liberdade de montagem sem perder consistência estrutural, financeira e auditável?"

Não: "Como salvo essa linha?"
