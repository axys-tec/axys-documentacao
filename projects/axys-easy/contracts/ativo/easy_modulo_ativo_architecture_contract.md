# Contrato Arquitetural — Módulo Ativo (AxysEasy)

**Versão:** 0.1  
**Data:** 2026-05-31  
**Status:** Canônico para implementação inicial  
**Escopo:** Domínio Ativo do AxysEasy — estrutura hierárquica dinâmica de orçamentos, integração com catálogo, microapps operacionais e diretriz de UX fluida.

---

## 1. Finalidade deste Documento

Este contrato consolida as decisões estruturais do módulo Ativo do AxysEasy — não é resumo de conversa, mas referência canônica para produto, banco de dados, backend, frontend, integrações e automações futuras de IA.

O objetivo principal é evitar dois erros recorrentes:

1. **Modelar engenharia como cadastros rígidos** — quando a realidade demanda estruturas flexíveis.
2. **Reproduzir apenas a aparência do Excel** — sem sua liberdade operacional, que é o que mantém o Excel dominante entre orçamentistas.

O módulo Ativo **não é uma tela isolada**. É uma camada estrutural que organiza dados executivos da obra e sustenta:

- orçamento (analítico e sintético)
- EAP/WBS
- cronograma (4D)
- medição (físico-financeira)
- curva ABC e histograma
- composições próprias do tenant
- documentação técnica derivada
- contratos e controle executivo

---

## 2. Tese Central

O número exibido em uma planilha de orçamento — `1`, `1.2`, `1.2.3` ou `7.4.1.9` — **não é o dado**. É apenas representação visual de uma posição em uma árvore.

O dado real é:

- quem é o pai do item (`parent_id`)
- qual a ordem relativa entre irmãos (`ordem`, esparsa)
- qual o tipo da linha (`tipo`: GRUPO, SERVIÇO, SUBTOTAL, etc.)
- qual o conteúdo técnico-financeiro (quantidade, unidade, custo, BDI, composição vinculada)
- qual o contexto da obra: edição de preços, base, modalidade, UF

**Consequência:** Se o sistema tratar `1.2.3` como chave de negócio, fica rígido, frágil e caro de evoluir. Se tratar como numeração renderizada sobre uma árvore ordenada, ganha a maleabilidade que torna o Excel forte na montagem de orçamentos.

---

## 3. Visão Estratégica do Módulo Ativo

O módulo Ativo é onde a obra ganha forma executiva dentro do AxysEasy.

O **schema `catalogo`** (fontes, edições, insumos, composições) representa conhecimento de referência curado por Axys. O **módulo Ativo** representa a materialização desse conhecimento em contexto específico: tenant, obra, versão de trabalho.

**Separação de responsabilidade:**

| Schema | Responde | Quem alimenta | Quem edita |
|---|---|---|---|
| `catalogo` | "O que existe de referência?" | Axys (autoritativo) | Axys apenas |
| `ativo` | "O que esta obra usa? Como foi estruturada?" | Implicado pelo tenant | Tenant (própria obra) |

Essa separação é decisiva para manter rastreabilidade, reproducibilidade, auditoria, versionamento, liberdade de montagem e abertura futura para IA assistiva sem corromper a base de verdade.

---

## 4. Objetivos do Módulo Ativo

O módulo Ativo deve atender simultaneamente a seis objetivos.

### 4.1 Liberdade Operacional

Usuário capaz de montar, reorganizar, copiar, colar, inserir, mover e indentar blocos com fluidez similar ao Excel ou Notion.

### 4.2 Estrutura Hierárquica Ilimitada

Sem limites estruturais como `GRUPO > SUBGRUPO > ITEM`. Esses nomes podem existir como convenção visual ou semântica, mas a árvore suporta profundidade arbitrária e reorganização dinamicamente.

### 4.3 Vínculo Técnico Confiável

Linhas de serviço apontam inequivocamente para composições (`catalogo.composicoes`), insumos, critérios, BDI, cronograma, medição — com snapshots versionáveis para reproducibilidade.

### 4.4 Recálculo Determinístico

Totais, subtotais, curvas ABC, histogramas e derivados recalculam de forma previsível, sem depender da numeração textual persistida.

### 4.5 Escalabilidade de Produto

A mesma estrutura de árvore sustenta orçamento, EAP, cronograma, medição e documentação técnica — não fragmentação entre microapps.

### 4.6 Preparação para IA Assistiva

Domínio modelado para que agentes possam:
- interpretar estrutura da obra (semântica de tipos, hierarquia, contexto)
- propor inserções, reorganizações, validações
- gerar documentação derivada
- operar sobre entidades estruturadas, não texto solto

---

## 5. Princípios Arquiteturais

### 5.1 Numeração Derivada, Não Persistida

Nenhuma regra de negócio central depende do texto `1.2.3.4`. É renderização, não chave.

### 5.2 Árvore Primeiro, Renderização Depois

Persistência, API e regras internas pensam em termos de `parent_id`, `ordem`, `path`. A interface renderiza numeração, indentação, agrupamentos — artefatos de visualização.

### 5.3 Uma Tabela Estrutural por Domínio

Linhas heterogêneas coexistem numa estrutura única, tipadas por coluna (`tipo`), não por proliferação prematura de tabelas quase idênticas (tabela por nível, e.g., `grupos`, `subgrupos`, `itens`).

### 5.4 Ordem Esparsa

Ordenação entre irmãos usa espaçamento amplo (1000, 2000, 3000) para inserção intermediária com risco mínimo de renumeração em massa.

### 5.5 Snapshot de Referência

Tudo que depende de custos de catálogo preserva contexto de edição, base, modalidade, UF para reproducibilidade futura — mesmo que catálogo evolua.

### 5.6 UX Operacional acima de UX Formulaica

Experiência de montagem (grade viva) sobrepesa formulários administrativos — isso é o que differencia AxysEasy de cadastros tradicionais.

### 5.7 Evolução Segura

O schema atual `orca.servicos` é **transitório**. Este contrato assume que refatoração será necessária — planejamos para mudança.

---

## 6. Relação com o Ecossistema

Este contrato **complementa** o documento principal [docs/contratos/axys_ecossistema_contrato_arquitetural.md](docs/contratos/axys_ecossistema_contrato_arquitetural.md).

**Verdades já estabelecidas:**

- AxysHub: dono de identidade, tenant (`hub_tenant`), roles (`hub_user_tenant`), licenças (`hub_microapp_instance`), billing
- AxysEasy: ambiente operacional do engenheiro — lê JWT do Hub, expõe apps de engenharia
- Schema `catalogo`: base curada (fontes, edições, insumos, composições) — somente leitura para tenant, escrita exclusiva Axys
- Universo de orçamentos: pertence ao espaço operacional do tenant (`orca` schema, posse do tenant)
- Schema `orca` atual: marcado como "revisão pendente" — este contrato define a direção

**Escopo deste contrato:** aprofunda o domínio Ativo dentro do Easy — não invalida o contrato de ecossistema, especializa-o.

---

## 7. Conceitos Fundamentais

### 7.1 Ativo

Entidade operacional editável pelo tenant — agregação de itens estruturados hierarquicamente para um propósito (orçamento, EAP, cronograma). Vinculado a uma obra e versão de trabalho.

### 7.2 Obra (`obr_*`)

Container superior de contexto de negócio: tenant, nome, data-base, edição, modalidade, UF, tipologia, parâmetros, metadados executivos. Raiz semântica do ativo.

### 7.3 Estrutura Ativa

Árvore ordenada de itens que materializa decomposição da obra para um uso específico. Mesma árvore pode ser consultada como orçamento, EAP, cronograma, medição — perspectivas diferentes, dados únicos.

### 7.4 Item Ativo (`ati_*`)

Cada linha editável da árvore. Pode representar: grupo, fase, serviço, subtotal, observação, texto, marco, cabeçalho, título, separador — tipo define comportamento, não profundidade.

### 7.5 Linha de Serviço

Item ativo com semântica técnico-financeira: quantidade, unidade, composição vinculada, custo unitário, custo total, BDI. Aponta para `catalogo.composicoes` ou composição própria do tenant.

### 7.6 Linha Estrutural

Item ativo cujo papel é organizar ou comunicar: grupo, observação, subtotal, divisor. Pode agregar custos de descendentes, mas não carrega valor próprio necessariamente.

### 7.7 Snapshot

Registro congelado de dados para reproducibilidade de cálculo — mesmo que catálogo original evolua depois. Preserva edição, base, modalidade, composição, preços.

---

## 8. Decisão Estrutural Principal

### 8.1 Modelo Conceitual Correto

❌ **Errado:**
```text
orcamento
└── itens numerados [1.1, 1.2, 1.3]
```

✅ **Correto:**
```text
obra / ativo
└── itens em árvore (parent_id, ordem, path)
    ├── pai
    ├── filho
    ├── irmão
    └── ...
```

### 8.2 Estrutura Mínima de Persistência

Cada item precisa, no mínimo, de:

**Estrutura:**
- `ati_id` (PK)
- `ati_atv_id` (FK → ativo)
- `ati_parent_id` (FK → ati_id, self-reference, NULL para raízes)
- `ati_ordem` (INTEGER, esparsa: 1000, 2000, 3000…)
- `ati_path` (TEXT, hierárquico: "0001", "0001.0002", "0001.0002.0001")
- `ati_tipo` (VARCHAR, enum-like: GRUPO, SERVIÇO, SUBTOTAL, OBSERVAÇÃO, TEXTO, MARCO…)
- `ati_descricao` (TEXT)

**Cálculo e referência (conforme tipo):**
- `ati_cmp_id` (FK → `catalogo.composicoes`)
- `ati_unidade` (VARCHAR: m, m², m³, kg, un, etc.)
- `ati_quantidade` (DECIMAL)
- `ati_custo_unitario` (DECIMAL, snapshot ou live)
- `ati_custo_total` (DECIMAL, derived ou persistido)
- `ati_bdi_id` (FK → BDI table, futuro)
- `ati_regras_json` (JSONB, metadados por tipo)
- `ati_meta_json` (JSONB, flexibilidade futura)
- `ati_criado_em`, `ati_criado_por` (auditoria)
- `ati_atualizado_em`, `ati_atualizado_por` (auditoria)

### 8.3 Exemplo Conceitual

| `ati_id` | `parent_id` | `ordem` | `path` | `tipo` | `descricao` |
|---|---:|---:|---|---|---|
| 1 | `null` | 1000 | `0001` | GRUPO | Serviços preliminares |
| 2 | 1 | 1000 | `0001.0001` | GRUPO | Limpeza |
| 3 | 1 | 2000 | `0001.0002` | GRUPO | Locação |
| 4 | 3 | 1000 | `0001.0002.0001` | SERVIÇO | Gabarito |
| 5 | 3 | 2000 | `0001.0002.0002` | SERVIÇO | Topografia |

**Visualização no browser** (renderizado no frontend a partir da árvore):
```text
1     Serviços preliminares
1.1   Limpeza
1.2   Locação
1.2.1 Gabarito
1.2.2 Topografia
```

**Banco não depende disso.** Inserir novo item entre Limpeza e Locação? Apenas cria novo registro com `parent_id=1, ordem=1500` — numeração visual auto-recalcula. Nenhuma coluna de texto precisa ser atualizada.

---

## 9. Limitações do Schema Atual

O schema atual (`orca.servicos` com `srv_nivel IN ('GRUPO', 'SUBGRUPO', 'ITEM')`) foi útil como etapa inicial, mas não atende a visão canônica:

1. **Congela profundidade em três níveis semânticos** — não permite 4, 5 ou N níveis
2. **Mistura papel estrutural com profundidade** — `srv_nivel` tenta fazer duas coisas: descrever tipo (GRUPO vs ITEM) e profundidade (que deve vir de `parent_id`)
3. **Fragmenta reutilização** — dificulta mesma árvore servir para EAP, cronograma, medição

**Decisão:** `srv_nivel` deixa de ser o pilar estrutural.

**Modelo alvo:**

| Aspecto | Responsável | Fonte |
|---|---|---|
| Profundidade | `parent_id` + `path` | Estrutura lógica |
| Semântica (tipo) | `tipo` | Coluna de tipo |
| Exibição (numeração) | Renderizador frontend | Cálculo dinâmico |
| Regras de cálculo | Tipo + atributos | Serviço backend |

---

## 10. Modelo de Dados Alvo

### 10.1 Tabelas Principais

**Entidade Ativo (agregação de itens):**
```sql
orca.ativos
  atv_id          INTEGER PK
  atv_obr_id      INTEGER FK → obra
  atv_tenant_uuid UUID   FK → hub_tenant
  atv_tipo        VARCHAR (ex: 'orcamento', 'eap', 'cronograma')
  atv_nome        VARCHAR
  atv_status      VARCHAR (ex: 'rascunho', 'emitido', 'arquivado')
  atv_versao      INTEGER (versionamento para auditoria)
  atv_criado_em   TIMESTAMP
  atv_criado_por  VARCHAR
  atv_atualizado_em TIMESTAMP
  atv_atualizado_por VARCHAR
```

**Entidade Item Ativo (linhas da árvore):**
```sql
orca.ativo_itens
  ati_id          INTEGER PK
  ati_atv_id      INTEGER FK → orca.ativos
  ati_parent_id   INTEGER FK → ati_id (self, NULL para raízes)
  ati_ordem       INTEGER (esparsa: 1000, 2000, 3000…)
  ati_path        TEXT    (hierárquico: "0001", "0001.0002"…)
  ati_tipo        VARCHAR (GRUPO, SERVIÇO, SUBTOTAL, OBSERVAÇÃO, TEXTO…)
  ati_descricao   TEXT
  ati_cmp_id      INTEGER FK → catalogo.composicoes (opcional)
  ati_unidade     VARCHAR (m, m², kg, un, h…)
  ati_quantidade  DECIMAL
  ati_custo_unitario DECIMAL (snapshot ou live de catálogo)
  ati_custo_total DECIMAL (persistido ou calculado)
  ati_bdi_id      INTEGER FK (futuro)
  ati_regras_json JSONB   (metadados por tipo)
  ati_meta_json   JSONB   (flexibilidade futura)
  ati_criado_em   TIMESTAMP
  ati_criado_por  VARCHAR
  ati_atualizado_em TIMESTAMP
  ati_atualizado_por VARCHAR
```

### 10.2 Tipos de Linha Recomendados

**Fase 1 (MVP):**
- `GRUPO` — linha organizadora, pode agregar custo de filhos
- `SERVIÇO` — linha técnico-financeira, aponta para composição
- `TEXTO` — informativo, sem cálculo
- `SUBTOTAL` — agregação explícita de descendentes
- `OBSERVAÇÃO` — observação livre

**Fase 2+ (futuro):**
- `FASE`, `ETAPA`, `MARCO` — semântica de cronograma
- `TÍTULO`, `SEPARADOR` — apresentação
- `MEDICAO` — acumula medições
- `COMPOSICAO_PROPRIA` — insumo próprio do tenant

**Regra crítica:** `tipo` define **comportamento**, nunca define **profundidade**. Profundidade vem de `parent_id`.

### 10.3 Ordem Esparsa

`ati_ordem` **não** é `1, 2, 3, 4…` sequencial. Usa espaçamento amplo:

```
1000, 2000, 3000, 4000…
```

Inserção intermediária:
- Entre 1000 e 2000 → 1500
- Entre 1500 e 2000 → 1750
- E assim por diante

**Rebalanceamento:** quando espaço local esgota, o sistema rebalanceia apenas entre irmãos daquele pai — nunca na árvore inteira. Operação rara, determinística.

### 10.4 Path Hierárquico

`ati_path` é texto imutável que representa a posição na hierarquia:

```
0001              (raiz 1)
0001.0001         (filho 1 de raiz 1)
0001.0002         (filho 2 de raiz 1)
0001.0002.0001    (neto, filho 1 de 0001.0002)
```

**Usos:**
- Ordenação eficiente em SQL (`ORDER BY path`)
- Consultas de descendência (`path LIKE '0001.0002%'`)
- Colapso/expansão de subtrees
- Movimentação de subárvores (um UPDATE)
- Auditoria e sincronização com UI

**Nota:** `path` complementa `parent_id` — não o substitui. Ambos têm propósitos: `parent_id` para joins, `path` para ordenação e hierarquia.

### 10.5 Payload Flexível (JSON)

`ati_regras_json` e `ati_meta_json` armazenam metadados que podem variar por tipo de linha, sem inflacionar schema com colunas especializadas.

**Disciplina obrigatória:**
- Contrato claro por tipo (quais campos esperados)
- Núcleo de cálculo não depende de dados arbitrários invisíveis
- Campos essenciais (busca, filtro, join) continuam relacionais, nunca exclusivamente em JSON

---

## 11. Regras de Numeração

### 11.1 Numeração Visual é Derivada

Numeração exibida (`1`, `1.2`, `1.2.3`) é **cálculo**, não dado persistido. Calculada no frontend com base em `parent_id` + `ordem` + quantidade de irmãos anteriores.

### 11.2 Renumeração Automática

Inseriu item entre dois irmãos? Numeração visual muda automaticamente — nenhuma coluna de texto atualiza. Backend apenas insere novo registro com `ordem=1500` (exemplo).

### 11.3 Numeração Contextual

Mesma árvore, múltiplas políticas de exibição:

- Numeração completa: `1.2.3`
- Bullets: `• Nível 2` sem número
- WBS: `0001.0002.0003`
- Compacta: sem números
- Exportação para cronograma: apenas marcos

Isso só é possível se numeração não for verdade persistida — é uma **política de renderização**, não estrutura.

---

## 12. UX Canônica de Montagem

### 12.1 Princípio

**Não transformar orçamento em formulário.**

Usuário edita uma grade viva, inspirada em Excel, Notion, MS Project — com fluidez operacional.

### 12.2 Comportamentos Obrigatórios

- Inserir linha nova no contexto atual (após seleção)
- Criar linha acima ou abaixo
- Indentar linha (transformar em filha)
- Promover linha (mover para nível superior)
- Duplicar linha
- Copiar e colar blocos inteiros
- Arrastar e soltar subtrees
- Expandir/recolher subárvores
- Editar in-line (sem deixar foco)
- Navegar por teclado (setas, Tab, Shift+Tab)
- Recalcular totais/agregados em tempo real

### 12.3 Atalhos Recomendados

| Tecla | Ação |
|---|---|
| `Insert` | Nova linha |
| `Tab` | Indentar (criar filha) |
| `Shift+Tab` | Promover (mover para nível superior) |
| `Ctrl+C` | Copiar |
| `Ctrl+V` | Colar |
| `Ctrl+D` | Duplicar |
| `Delete` | Remover linha |
| `Enter` | Editar ou confirmar |
| `Esc` | Cancelar edição |

### 12.4 Filosofia da Interface

Usuário **não quer "cadastrar um serviço"** — quer **montar uma estrutura** rapidamente.

**Unidade principal:** grade hierárquica, não modal administrativo. Modais podem existir para detalhes (composição, critério, BDI), mas experiência principal é a grade.

---

## 13. Fluxos de Negócio Prioritários

### 13.1 Criação de Orçamento Analítico

1. Usuário cria obra (nome, data-base, edição, UF, modalidade)
2. Abre grade vazia de ativo/orçamento
3. Insere grupos, subgrupos, serviços livremente (Tab, Insert, Shift+Tab)
4. Para cada serviço, associa composição de catálogo (autocomplete/busca)
5. Sistema popula quantidade, unidade, custo unitário (snapshot de catálogo)
6. Custos totais calculam automaticamente
7. Usuário reorganiza, copia blocos, reorganiza novamente (sem limitações)
8. Clica "Emitir" → sistema gera orçamento oficial com snapshots + derivados (ABC, histograma, insumos detalhados, exportação)

### 13.2 Criação via Paradigma (Futuro)

1. Usuário seleciona tipologia ou paradigma (ex: "Construção residencial 10 pavimentos")
2. Motor gera estrutura inicial (grupos de serviços sugeridos)
3. Estrutura entra na **mesma grade canônica** (não "modo especial")
4. Usuário ajusta manualmente como orçamento nativo — sem diferença de UX

**Regra crítica:** não existem dois mundos de UX. Paradigma é semente; edição é a mesma.

### 13.3 Reorganização Tardia

Percebi depois que faltou item entre dois existentes? Insiro no lugar certo:
- Sistema insere com `ordem=1500` (entre os irmãos)
- Numeração visual auto-renumera
- Nenhuma coluna de texto é tocada

### 13.4 Cópia entre Obras

Blocos inteiros copiáveis entre ativos compatíveis, preservando:
- Subárvore completa (parent_id, ordem, path)
- Tipos de linha
- Referências a serviços/composições (se existem no tenant destino)
- Metadados (`regras_json`, `meta_json`)

---

## 14. Relação com o Catálogo

O schema `catalogo` (fontes, edições, insumos, composições) é a base de referência curada por Axys. O módulo Ativo consome desse catálogo.

**Dinâmica:**

| Ação | Onde | Como |
|---|---|---|
| Consultar composição | Ativo (grade) | Autocomplete em `catalogo.composicoes` |
| Vincular composição | Ativo item | `ati_cmp_id` → `catalogo.composicoes` |
| Copiar custo | Ativo item | Snapshot de catálogo na edição selecionada |
| Atualizar custo | Ativo item | Manual (ajuste tenantspecífico) ou reimportar edição |

**Princípios:**

- Composições e insumos vêm de fonte curada (`catalogo`)
- Cada obra seleciona edição de preços (data, modalidade, fonte)
- Ajustes locais (BDI, desconto, quantidade) ficam no `ativo`, nunca modificam `catalogo`
- Cadernos, critérios, documentação técnica podem ser herdados do catálogo ou gerados do ativo
- Snapshots preservam contexto de catálogo no momento da emissão (mesmo que catálogo evolua depois)

**Ativo não substitui catálogo. O instancia em contexto de obra.**

---

## 14.5 Integrações CAD/BIM — Origem de Levantamentos

O Ativo rastreia a origem dos dados estruturais via `ati_memo_calc_tipo`:

| Tipo | Origem | Fornecido por | Status |
|---|---|---|---|
| `MANUAL` | Digitação | Usuário | ✅ Ativo |
| `TEXTO_LIVRE` | Observação | Usuário | ✅ Ativo |
| `PLANILHA` | Upload | Usuário | ✅ Ativo |
| `AUTOLISP` | CAD levantamento | AxysLisp (submodule) | ✅ Em andamento |
| `REVIT` | BIM modelo | AxysRVT (futuro) | ⏳ Fase 1 |
| `IFC` | Arquivo IFC | AxysIFC (futuro) | ⏳ Fase 2 |

### Contrato de JSON Obrigatório

**Imperativo:** Independentemente da origem (CAD, Revit, IFC ou futura), o JSON exportado pela plataforma de origem **deve seguir um contrato único e padronizado** que o Easy consegue ler de forma idêntica.

**Estrutura esperada (a detalhar em `docs/api/memo_calc_json_contract.md`):**

```json
{
  "memo_calc": {
    "origem": "AUTOLISP|REVIT|IFC",
    "versao_contrato": "1.0",
    "arquivo_origem": "...",
    "timestamp": "...",
    "checksum": "...",
    "itens": [
      {
        "id": "...",
        "descricao": "...",
        "quantidade": 123.45,
        "unidade": "m²",
        "observacoes": "..."
      }
    ]
  }
}
```

**Não será aceito:** JSONs heterogêneos, campos adicionais não-documentados, ou lógica diferente por origem. Cada integração (AxysLisp, AxysRVT, AxysIFC) **exporta exatamente este contrato**.

### Dois Fluxos de AxysLisp

1. **Genérico:** Baixa AxysLisp genérico → levanta valores → depois no Orca associa aos itens
2. **Por-item:** Baixa AxysLisp vinculado ao item → levantamento já contextualizado

### Provenance e Auditoria

Cada origem carrega metadados críticos:
- `arquivo_origem`: nome/GUID do CAD/RVT/IFC
- `timestamp`: quando foi exportado
- `checksum`: para rastrear mutação do arquivo original

Permite auditar se levantamento é ainda válido (arquivo fonte evoluiu?).

### Uso em IA Assistiva

Agente sabe se dado é autorizado (CAD/BIM) vs. manual, aplica validação apropriada. Sugestões são contextualizadas por origem.

---

## 15. Microapps: Easy Price, Easy CPU, Easy Orca

### 15.1 Easy Price

**Responsabilidade:** Gerar estruturas parametrizadas iniciais e estimativas rápidas com base em tipologia/paradigma.

**Saída:** Ativo inicial (estrutura hierárquica) que entra na grade canônica para edição manual.

### 15.2 Easy CPU

**Responsabilidade:** Consulta, análise de composições, histogramas de insumos, inteligência de custos, comparação de fontes.

**Entrada:** Catálogo + ativo de obra  
**Saída:** Insights sobre custos, composições compatíveis, sugestões de insumos

### 15.3 Easy Orca

**Responsabilidade:** Montagem executiva do orçamento — grade principal onde usuário estrutura obra.

**Inclui:**
- Montagem analítica (grade viva, operacional)
- Ajustes técnico-financeiros e BDI
- Emissão oficial (snapshots + versionamento)
- Derivados (ABC, histograma, exportação)
- Conexão com cronograma e medição

### 15.4 Regra de Convergência

**Todos os microapps geram ou alimentam a MESMA espinha dorsal: árvore de itens (`orca.ativo_itens`).**

Exemplo: Easy Price gera estrutura → entra em Easy Orca → usuário refina → mesmo objeto, mesma grade, mesma árvore.

---

## 16. Dominialidade das Entidades

### 16.1 AxysHub

**Dono de:**
- Usuários (`hub_user`)
- Tenants (`hub_tenant`, `hub_user_tenant`)
- Roles e permissões
- Licenças (`hub_microapp_instance`)
- Billing, cotas, planos

### 16.2 Schema `catalogo`

**Dono de:**
- Fontes de preços
- Edições mensais
- Insumos (identidade + preços por edição)
- Composições de preços unitários
- Cadernos de encargos padrão
- Critérios técnicos autoritativos

**Caractere:** curado por Axys, somente leitura para tenant, referência imutável.

### 16.3 Módulo Ativo (schema `orca`)

**Dono de:**
- Obras do tenant (`orca.obras`)
- Ativos/versões de trabalho (`orca.ativos`)
- Árvores operacionais e seus itens (`orca.ativo_itens`)
- Quantidades e ajustes locais
- Composições próprias do tenant (quando aplicável)
- Snapshots executivos (versionamento)
- BDI aplicado localmente
- Cronograma derivado
- Medição física-financeira
- Documentos gerados (memorial, caderno, etc.)

**Caractere:** editable pelo tenant, operacional, versionável para auditoria.

### 16.4 Futuro: `public_cpu`

Espaço de publicação voluntária onde tenants compartilham composições próprias. **Não substitui Ativo** — apenas oferece biblioteca compartilhável. Ativo permanece local, operacional, editável; `public_cpu` é bibliográfico.

---

## 17. Versionamento e Snapshot

O Ativo deve ser versionável para permitir:

- Reabrir obra na data-base histórica (edição, preços, critérios originais)
- Comparar revisões (diff de estrutura e custos)
- Congelar orçamentos emitidos (snapshot imutável)
- Reprocessar derivados sem recalcular base
- Auditar alterações (humanas ou automáticas)

**Requisitos:**

| Entidade | Campo | Propósito |
|---|---|---|
| Obra | `obr_versao` | Rastreio de revisões |
| Ativo | `atv_versao` | Rastreio de emissões |
| Item | `ati_criado_em`, `ati_criado_por` | Autoria |
| Item | `ati_atualizado_em`, `ati_atualizado_por` | Trilha de mudanças |
| Item | (auditoria em `audit.logs`) | Movimento estrutural (move, copy, indent) |
| Emissão | snapshot | Custos congelados no momento de emissão |

**Fluxo típico:**
1. Usuário cria ativo (rascunho)
2. Edita, reorganiza, refina
3. Clica "Emitir" → sistema cria snapshot (custos, composições, estrutura naquele momento)
4. Ativo entra em "emitido" (somente leitura)
5. Usuário clona para revisão → novo ativo, nova versão, mesmos dados base

---

## 18. Integrações com Cronograma, Medição e Documentação

A mesma árvore sustenta expandibilidades naturais sem fragmentação.

### 18.1 Cronograma

Itens selecionados recebem atributos de agendamento:
- Duração (dias)
- Predecessoras e dependências
- Produtividade (man-hours, recursos)
- Equipes alocadas
- Calendário (dias úteis, feriados)

**Dados:** armazenados em tabela separada, linkados por `ati_id`. Mesma estrutura hierárquica.

### 18.2 Medição

Linhas de serviço acumulam:
- Medido anterior (revisão N-1)
- Medido atual (estado da obra hoje)
- Saldo a medir
- Percentual executado (%)
- Comparativo com previsto

**Dados:** tabela `orca.medicao_itens`, linkada por `ati_id`.

### 18.3 Curva ABC

Derivada de agregação de custos:
- Por serviço (maior ticket)
- Por insumo (itens mais caros da estrutura)
- Por família (aço, concreto, mão-de-obra)
- Por etapa/fase (cronológico)

**Cálculo:** a partir da árvore, não tabela separada.

### 18.4 Histograma

Agregação de insumos necessários ao longo da estrutura (e futuramente, do tempo):
- Necessidades mensais de concreto, aço, mão-de-obra
- Recursos por período
- Capacidade vs. demanda

**Entrada:** itens + composição + cronograma.

### 18.5 Documentação Técnica Derivada

Memorial descritivo, caderno de encargos, critério de medição, descritivo de etapas — todos nascem da mesma base:
- Seleção de grupos/etapas
- Formatação em template (Markdown, PDF, Word)
- Links automáticos para composições, critérios, normas

---

## 19. API e Operações Estruturais

APIs não expõem apenas CRUD genérico. Expõem operações semânticas de árvore — primitivas que garantem integridade estrutural.

### 19.1 Operações Elementares

| Operação | Entrada | Saída | Efeito |
|---|---|---|---|
| criar_item | `atv_id, tipo, descricao` | novo `ati_id` | Insere como filho de raiz com `ordem=1000` |
| inserir_abaixo | `ati_id` | novo `ati_id` | Sibling após, com `ordem` entre seleção e próximo |
| inserir_acima | `ati_id` | novo `ati_id` | Sibling antes, com `ordem` entre anterior e seleção |
| criar_filho | `ati_id` | novo `ati_id` | Filho com `ordem=1000` |
| indentar | `ati_id` | atualização | `parent_id` = sibling anterior, `ordem=1000`, `path` recalcula |
| promover | `ati_id` | atualização | `parent_id` = pai atual, `ordem` entre siblings, `path` recalcula |
| mover_para | `ati_id, novo_parent_id` | atualização | Muda `parent_id`, rebalanceia `ordem`, recalcula `path` |
| reordenar | `ati_id, nova_ordem` | atualização | Ajusta `ordem`, preserva `parent_id` |
| duplicar | `ati_id` | nova subárvore | Clona item + descendentes, nova `ordem` |
| copiar_para | `ati_id, ativo_destino_id` | nova subárvore | Copia para outro ativo, valida referências |
| excluir | `ati_id` | — | Soft-delete (marca `ati_deletado_em`) ou hard-delete (conforme política) |
| recalcular_subtree | `ati_id` | atualização | Recalcula custos de `ati_id` e ancestrais |
### 19.2 Garantias de Consistência

Todas as operações preservam:

- **`parent_id`:** referência válida ou NULL (raiz)
- **`ordem`:** monotônica dentro de cada `parent_id`
- **`path`:** hierárquico consistente (separador `.`, sem gaps)
- **Agregados de custo:** subtotals recalculados em O(n) do subtree, não toda árvore
- **Auditoria:** cada operação estrutural é logged em `audit.logs`

### 19.3 Escalabilidade de Cálculo

- Operação O(1) em item isolado (criar, deletar, renomear)
- Operação O(n) em subtree local (mover subárvore, duplicar com filhos)
- **Nunca** O(N) na árvore inteira — evita lock global desnecessário
- Índices em `(ati_parent_id, ati_ordem)` e `ati_path` para consultas eficientes

---

## 20. Regras de Cálculo

### 20.1 Linha Estrutural (GRUPO, OBSERVAÇÃO, TEXTO)

- **Não carrega** custo próprio (opcional, conforme tipo)
- **Pode agregar** custo de descendentes elegíveis (filhos diretos do tipo SERVIÇO ou grupos que agregam)
- **Renderização:** exibe custo agregado próximo ao nome

### 20.2 Linha de Serviço (SERVIÇO)

Carrega ou deriva:
- `ati_unidade` (m, m², kg, un, etc.)
- `ati_quantidade` (DECIMAL)
- `ati_custo_unitario` (DECIMAL, snapshot de catálogo ou ajuste local)
- `ati_custo_total` = `quantidade` × `custo_unitario`

### 20.3 Subtotal (tipo SUBTOTAL)

Pode ser:
- **Explícita:** linha de tipo SUBTOTAL que agrega seleção de filhos
- **Implícita:** GRUPO renderiza soma de descendentes

Se persistida (tipo SUBTOTAL), é **entidade semântica legítima**, não gambiarra de fórmula textual.

### 20.4 Agregação de Custos

**Regra principal:** custos de GRUPO = soma de filhos elegíveis (ex: filhos SERVIÇO + SUBTOTAL).

**Nunca** permite digitação livre de agregado sem controle — garante consistência aritmética.

**Exceto:** se existir tipo explícito de "valor manual" (futuro), que desabilita agregação automática para aquele item.

---

## 21. Anti-patterns Proibidos

Explicitamente **vedados** como arquitetura final:

### 21.1 Persistir `1.2.3` como Chave Estrutural

❌ **Proibido:** `ati_numeracao_textual = "1.2.3"` como chave ou referência

**Consequência:** acopla dado, exibição e ordem — quebra ao reorganizar.

### 21.2 Limitar Árvore a `GRUPO > SUBGRUPO > ITEM`

❌ **Proibido:** três níveis semânticos como limite rígido

**Consequência:** não suporta realidade de projetos reais (N níveis de detalhamento).

### 21.3 Tabela por Nível

❌ **Proibido:** `grupos`, `subgrupos`, `servicos`, `subservicos` em tabelas separadas

**Consequência:** estrutura inflexível, cara de manter, joins complexos.

### 21.4 Formularizar Montagem Principal

❌ **Proibido:** experiência central depender de modais/formulários administrativos

**Consequência:** usuário volta ao Excel — grade é a experiência principal.

### 21.5 Contaminar Catálogo com Ajustes Operacionais

❌ **Proibido:** mudanças locais de obra gravar em `catalogo.*`

**Consequência:** perda de autoridade, dificuldade de auditoria, reuso corrompido.

### 21.6 Recalcular Árvore Inteira

❌ **Proibido:** `UPDATE orca.ativo_itens SET ordem=... WHERE ati_atv_id=...` a cada inserção

**Consequência:** lock global, performance degradada, "stop the world" em cada operação.

**Correto:** ordem esparsa + rebalanceamento local (O(n) do subtree, não N).

### 21.7 IA Operando Sobre Texto Sem Entidade

❌ **Proibido:** automação que manipula strings de numeração, descrição, ou sem modelo estruturado

**Consequência:** caos, inconsistência, perda de auditoria — entidades estruturadas são pré-requisito para IA segura.

---

## 22. Roadmap Arquitetural

### Fase 1: Contrato e Refatoração de Schema

**Objetivo:** formalizar este contrato como base para Easy Orca.

- [ ] Formalizar este documento como referência canônica
- [ ] Revisar/depreciar `orca.servicos` (tabela transitória)
- [ ] Definir `orca.ativos` e `orca.ativo_itens` finais
- [ ] Introduzir `parent_id`, `ordem` esparsa, `path`
- [ ] Migration de dados (leitura compatível quando possível)
- [ ] Documentar decisões em `easy_schema.sql`

### Fase 2: Backend Estrutural

**Objetivo:** primitivas de manipulação de árvore com garantias de integridade.

- [ ] Serviço `ativo_tree_service` (criar, indentar, promover, mover, copiar, duplicar)
- [ ] APIs semânticas: `/api/ativo-items/criar`, `/api/ativo-items/{id}/indentar`, etc.
- [ ] Recálculo de agregados (subtree-local, não árvore inteira)
- [ ] Auditoria estrutural (cada movimento é logged)

### Fase 3: Grade Operacional (MVP Easy Orca)

**Objetivo:** experiência principal — grade viva, editável, com teclado.

- [ ] UI estilo planilha hierárquica (indentação, números derivados)
- [ ] Suporte de teclado (Insert, Tab, Shift+Tab, Ctrl+C/V/D, Delete)
- [ ] Drag and drop de linhas e subtrees
- [ ] Expansão/colapso de grupos
- [ ] Edição in-line (célula a célula)
- [ ] Autocomplete de composições (busca em `catalogo`)

### Fase 4: Derivados (Easy CPU integration)

**Objetivo:** inteligência a partir da estrutura.

- [ ] Curva ABC (por serviço, insumo, família)
- [ ] Histograma (necessidades de insumos)
- [ ] Composições detalhadas (breakdown de insumos)
- [ ] Exportação (Excel, PDF, Word)
- [ ] Caderno de encargos gerado

### Fase 5: Convergência de Microapps

**Objetivo:** Easy Price, CPU, Orca alimentam/consomem a mesma árvore.

- [ ] Easy Price → gera ativo inicial (estrutura paradigma) em Easy Orca
- [ ] Easy CPU → aprofunda análise de composições (mesmo ativo)
- [ ] Easy Orca → consolida edição e emissão oficial (mesma grade)
- [ ] Cronograma e medição consomem `ativo_itens` como base estrutural

### Fase 6: IA Assistiva (futuro)

**Objetivo:** sugestões e automação segura com trilha auditável.

- [ ] Sugestão de estrutura (paradigma, agrupamentos automáticos)
- [ ] Validação de lacunas (serviços faltando conforme tipologia)
- [ ] Detecção de inconsistências (composição faltando, custos zerados)
- [ ] Geração de documentação (memorial, caderno, descritivos)
- [ ] Automação segura (operações estruturais com provenance auditável)

---

## 23. Diretrizes para IA, Desenvolvedores e Arquitetos

Qualquer agente, pessoa ou processo implementando tarefas a partir deste contrato **deve respeitar:**

1. **Verdade estrutural mora na árvore**, não em numeração textual
2. **`tipo` define comportamento**, nunca profundidade
3. **Schema `orca` atual é transitório** — este contrato é a forma canônica
4. **UX principal é grade operacional** (não formulários, não modais de cadastro)
5. **Operações estruturais são de primeira classe** (não CRUD genérico)
6. **Custos e composições exigem snapshot** para reproducibilidade
7. **Mesma árvore sustenta múltiplos usos:** orçamento, EAP, cronograma, medição

### Pergunta Correta ao Implementar

❌ **Errado:** "Como salvo essa linha?"

✅ **Correto:** "Como preservo a liberdade de montagem sem perder consistência estrutural, financeira e auditável?"

### Checklist para Código Novo

- [ ] Operações estruturais preservam `parent_id`, `ordem`, `path` consistentes?
- [ ] Numeração é derivada no render, não persistida?
- [ ] Ordem é esparsa e local, não sequencial global?
- [ ] Snapshots existem para dados dependentes de catálogo?
- [ ] Auditoria rastreia todo movimento estrutural?
- [ ] UI é grade primeiro, modal segundo?
- [ ] Teclado funciona (Insert, Tab, Shift+Tab)?

---

## 24. Declaração Final

AxysEasy não vence Excel pela promessa abstrata de "digitalização".

Vence oferecendo:

- **Liberdade operacional** que Excel entrega
- **Consistência de dados** que Excel não entrega
- **Rastreabilidade** que engenharia precisa
- **Escalabilidade** que escritório moderno exige

### Decisão Canônica

**O núcleo do módulo Ativo é uma estrutura hierárquica dinâmica, ilimitada, orientada por `parent_id + ordem + path`, com numeração apenas visual e UX de grade operacional.**

Toda implementação futura do Easy Orca — e extensões que dela dependem (cronograma, medição, documentação, IA assistiva) — será avaliada contra essa regra.

---

## 25. Aprovação e Evoluções

**Versão:** 0.1  
**Aprovado por:** Renan Dias (Product + Architecture)  
**Data aprovação:** 2026-05-31

**Próximas etapas:**
1. Validação de coerência com ecossistema Hub/Easy (Fase 1)
2. Definição de schema SQL final em `docs/db/easy/easy_schema.sql` (Fase 1)
3. Implementação de `ativo_tree_service` (Fase 2)
4. Build da UI de grade (Fase 3)

**Mudanças futuras:** este documento é vivo. Evoluções mantêm a tese central (árvore, ordem esparsa, numeração derivada) e são documentadas como versões sucessivas.

---

## 25. Anexo de conciliacao com o estado atual do repositorio

Este documento conversa com os artefatos atuais do projeto da seguinte forma:

- [docs/contratos/axys_ecossistema_contrato_arquitetural.md](/Users/rdias07/Documents/GitHub/axys-easy/docs/contratos/axys_ecossistema_contrato_arquitetural.md:1): continua valido no escopo ecossistemico;
- [docs/db/easy/easy_schema.sql](/Users/rdias07/Documents/GitHub/axys-easy/docs/db/easy/easy_schema.sql:664): continua sendo referencia do estado atual, mas a parte `orca` deve ser considerada transitoria;
- [docs/apps/axys_easy-orca.md](/Users/rdias07/Documents/GitHub/axys-easy/docs/apps/axys_easy-orca.md:1): permanece como descricao comercial resumida do produto;
- [next_step_app.md](/Users/rdias07/Documents/GitHub/axys-easy/next_step_app.md:1) e [next_step_map.md](/Users/rdias07/Documents/GitHub/axys-easy/next_step_map.md:1): seguem relevantes para a camada de importacao e catalogo, que alimenta o modulo Ativo.

Este arquivo deve ser tratado como a referencia canonica para a proxima iteracao de modelagem do dominio orcamentario e estrutural do Axys Easy.
