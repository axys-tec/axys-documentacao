# AxysEasy — Mapa de Produtos (módulos)

> Catálogo dos produtos/módulos do Easy. Cada módulo **opera sobre o ATIVO** (não é entidade
> isolada — contrato `ativo/EASY_ATIVO_CONTRATO.md` §11). A **liberação por tenant vem da licença no
> HUB**. Este doc é a fonte do texto de vitrine **e** do mapeamento técnico (qual slot/tabela cada
> módulo usa, e o que já está modelado vs reservado).

---

## Visão geral

| Módulo | Em uma linha | Opera sobre (schema) | Estado da modelagem |
|---|---|---|---|
| **Easy Price** | Gerador de orçamento por **parâmetros/drivers** | ficha + `drivers`/`ativo_itens_drivers` + modelo (`is_catalog_source`) | ✅ tabelas no schema |
| **Easy CPU** | Importe seu Excel → analítico + cronograma + histograma | `ativo_itens` (import) + `tenant_catalogo` + histórico (catalogo) | ✅ tabelas no schema |
| **Easy Orça** | Price + CPU + documentação técnica amarrada | tudo do Price/CPU + descritivo/caderno (docs) | ✅ base; docs a evoluir |
| **EasyDocs** | Memoriais e especificações (IFC ou guiado) | `memo_calc` (IFC) + ficha + diversidades · slot `ativo_docs` | ⏳ slot reservado |
| **Easy ProjectManager** | Estrutura projeto (ASBEA/próprio): pastas + checklists | slot `ativo_pm` | ⏳ slot reservado |
| **Easy BuildDiary** | Diário de obra objetivo + evidência + PDF | slot `ativo_diario` (+ cronograma p/ físico) | ⏳ slot reservado |
| **Easy FinControl** | Medições + evolução físico-financeira + export | slot `ativo_fin` (+ `cronograma`) | ⏳ slot reservado |
| **Easy LicitPlan** | Planejamento de licitações: checklist + cronograma-base | slot `ativo_licit` (pode existir avulso) | ⏳ slot reservado |

> ✅ = tabelas já no `schema.sql` · ⏳ = namespace reservado (DDL entra quando o microapp nascer).
> **Composição:** Orça ⊃ Price + CPU + documentação.

---

## Easy Price™
**Gerador automatizado de orçamento por parâmetros — do rápido ao refinado.**

Gera um orçamento estimativo completo com poucos cliques, usando parâmetros simples e **modelos por
tipologia de projeto**.

- **5 tipologias:** escolar, hospitalar, residencial médio padrão, residencial alto padrão e fabril.
- Entrega **planilha itemizada + cronograma de serviços**.
- **Easy Price 2 (avançado):** o usuário sobe **o próprio orçamento parametrizado** (modelo do tenant).
- Regras com parâmetros **simples (single)** ou **compostos (complex)** para maior refinamento.
- Automação apoiada por **IA**, mantendo flexibilidade e controle do usuário.

**Mapa técnico:** é o **gerador por DRIVERS**. As 5 tipologias = **modelos Axys** (`ativos` com
`atv_is_catalog_source=TRUE`); Price 2 = **modelos do próprio tenant**. Parâmetros = `ficha_parametros`
(single) e composição de drivers (complex) via `drivers` + `ativo_itens_drivers`. Saída = `ativo_itens`
(+ `cronograma`).
**Price vs Price 2:** Price = modelos prontos da Axys; **Price 2 = o tenant cria/sobe o próprio modelo.**

---

## Easy CPU™
**CPU (Composições de Preços Unitários) para complementar o orçamentista — sem substituir o Excel.**

Integra-se ao Excel e ao fluxo real do orçamentista: você importa um orçamento criado por você e o
transforma em entregáveis analíticos e gerenciais.

- **Importe** seu orçamento em Excel.
- Gere **orçamento analítico** completo, **cronograma** e **histograma de mão de obra**.
- Atualize preços ao longo do tempo: **para frente** (atualização) ou **para trás** (histórico).
- Ideal para reaproveitar bases antigas e reduzir retrabalho.

**Mapa técnico:** import total → `ativo_itens` (mesma árvore); composições/insumos próprios em
`tenant_catalogo`; histograma de MO via classificação `insumos_tipo`; atualização frente/trás resolve
contra edições do `catalogo` (custo@edição) + série histórica.

---

## Easy Orça™
**A versão mais completa: Easy Price + Easy CPU + documentação técnica amarrada.**

Reúne o fluxo do Price e do CPU num único sistema e adiciona documentação técnica amarrada ao orçamento.
Braço forte para propostas robustas e entregáveis completos.

- Inclui as funcionalidades do **Easy Price** e do **Easy CPU**.
- Gera **descritivo do orçamento** automatizado e **amarrado aos itens**.
- Entrega **caderno de encargos**.
- Entrega **critérios de medição e remuneração de serviços**.

**Mapa técnico:** superset de Price+CPU sobre o mesmo `ativo`; descritivo amarrado a `ativo_itens`;
caderno/critérios reusam o registro de documentos do `catalogo` + `ativo_diversidades_catalog`.

---

## EasyDocs™
**Memoriais e especificações técnicas — automatizado por IFC ou guiado por parâmetros.**

Gera memoriais descritivos e especificações técnicas com alto rigor. Opera automatizado via **IFC
(OpenBIM)** ou por **preenchimento guiado**.

- **Modo IFC:** leitura de parâmetros do modelo (quanto mais detalhado o BIM, melhor o texto).
- **Modo guiado:** checklists e parâmetros para textos altamente técnicos sem exigir maturidade BIM.
- Entrega rápida, robusta e padronizada — sem texto genérico.

**Mapa técnico:** modo IFC = `memo_calc` (origem `IFC`, mesmo contrato `axys-cad-v1`); modo guiado =
`ficha` (parâmetros) + checklists. Saída/peças em `ativo_diversidades_catalog`; lar definitivo = slot
`ativo_docs`.

---

## Easy ProjectManager™
**Organização de projeto com poucos cliques — estrutura, escopo e checklists.**

Cadastra um projeto e, com base em parâmetros, estrutura o programa e as entregas conforme **ASBEA**
(ou padrão próprio). Devolve um executável que monta pastas e checklists.

- Seleção de nomenclatura (ASBEA ou padrão próprio).
- Definição de programa e projetos conforme escopo.
- Geração automática de estrutura de pastas.
- Geração de checklists em Excel por disciplina.
- Suporte direto ao gestor de projetos: organização e fluxo de processos.

**Mapa técnico:** slot reservado `ativo_pm` (DDL quando nascer). Disciplinas = lookup
`ativo_diversidades_tipo_catalog`.

---

## Easy BuildDiary™
**Diário de obra direto ao ponto — evidência técnica, sem burocracia.**

Registra o que importa, com clareza, evidência e padrão técnico — sem textos longos nem subjetividade.
Bônus: acompanhar cronograma físico via import opcional da planilha/cronograma.

- Registro diário objetivo: atividades, condições, ocorrências e observações técnicas.
- Anexação de evidências (fotos, arquivos e comentários).
- Padronização do texto técnico, evitando descrições frágeis ou genéricas.
- Geração automática de **PDF profissional**, pronto para envio ou arquivo.
- Ideal para fiscalização, acompanhamento de obra e respaldo técnico.

**Mapa técnico:** slot reservado `ativo_diario`; cronograma físico reusa `ativo.cronograma`.

---

## Easy FinControl™
**Controle físico-financeiro simples, rastreável e exportável.**

Organiza medições e evolução físico-financeira sem virar um sistema pesado. Foca no acompanhamento real
da obra/contrato.

- Registro de **medições** por período, serviço ou etapa.
- Correlação entre avanço físico e impacto financeiro.
- Histórico rastreável de medições e ajustes.
- Exportação clara para Excel e relatórios gerenciais.
- Apoio à tomada de decisão e à gestão de contratos.

**Mapa técnico:** slot reservado `ativo_fin`; medição correlaciona `ativo_itens` × `cronograma`
(físico-financeiro).

---

## Easy LicitPlan™
**Organização e planejamento de licitações — antes do caos começar.**

Estrutura a participação em licitações (públicas/privadas) antes da fase crítica: prazos, documentos e
responsabilidades.

- Checklist completo de documentos e etapas da licitação.
- Organização por processo, órgão e modalidade.
- Cronograma-base com alertas de prazos críticos.
- Redução de riscos por esquecimento ou falha operacional.
- Ideal para equipes que lidam com múltiplas licitações simultâneas.

**Mapa técnico:** slot reservado `ativo_licit`. **Pode existir avulso**; quando associado a
contrato/obra, o núcleo é o ativo (contrato v0.2 §12).

---

## Licenciamento

Quais módulos cada tenant vê/usa vem da **licença no HUB** (fronteira: Hub manda, Easy renderiza). O
main-client monta os cards a partir do que o Hub libera. Ver `next-steps/PLANO_CLIENTE.md` (Ciclo 1).

---

# Estrutura das telas (proposta)

> Como cada tela se estrutura, ancorado no que o produto faz e no schema. Convenção transversal:
> header com **breadcrumb de contexto** `Empreendimento › Ativo › Módulo`; o **ativo é o eixo**
> (persiste ao trocar de módulo); cada módulo tem **sidebar própria** (estende
> `partials/sidebar_catalogo.html`); reuso dos padrões de tabela do catálogo (ordenação, congelar
> coluna, densidade); botões antes de atalhos de teclado. Os 3 primeiros (Price/CPU/Orça) são
> construíveis já; os 4 últimos são esboço até o slot nascer.

## Shell

### main-client (home do tenant)
```
┌─────────────────────────────────────────────────────────────┐
│ [logo] AxysEasy        busca global         [tenant ▾] [user]│
├─────────────────────────────────────────────────────────────┤
│  Bem-vindo, {user}                                           │
│  ┌── MÓDULOS LIBERADOS (cards, vêm da licença do Hub) ─────┐ │
│  │ [Price] [CPU] [Orça] [Docs] [PM] [Diary] [Fin] [Licit]  │ │
│  │  (card aceso = licenciado · apagado = "assinar")        │ │
│  └─────────────────────────────────────────────────────────┘ │
│  Projetos recentes            │  Avisos / últimas versões     │
│  • Ativo A  (UBS Centro)      │  • novidade X                 │
│  • Ativo B  (avulso)          │  Preferências ▸               │
│  + Novo ativo / empreendimento│                               │
└─────────────────────────────────────────────────────────────┘
```
- **Dados:** `empreendimentos` + `ativos` do tenant; cards = licença Hub.
- **Ação-chave:** abrir um projeto (→ sub-main) ou criar ativo.

### sub-main do projeto (= o ATIVO) — porta de entrada, curta
```
┌─────────────────────────────────────────────────────────────┐
│ Empreendimento › ATIVO: {nome}   [status]  UF  [editar ficha]│
├─────────────────────────────────────────────────────────────┤
│  Contexto de preço: SINAPI 04/26 · SP · LS desonerada · BDI ▾│
│  ┌── Entre por um módulo (só os liberados) ───────────────┐  │
│  │ [Price] [CPU] [Orça] [Docs] [PM] ...                   │  │
│  └────────────────────────────────────────────────────────┘ │
│  Resumo: total R$ ··· · última revisão R01 · itens ···      │
│  Peças/Docs do ativo (diversidades): ARQ, EST, ...          │
└─────────────────────────────────────────────────────────────┘
```
- **Dados:** `ativos` + `orcamento_parametros` (contexto) + `ativo_revisoes` (resumo) + `ativo_diversidades_catalog`.
- **Papel:** direcionar para o módulo, mantendo o ativo em contexto.

## Módulos com schema pronto (Price / CPU / Orça)

### Easy Price — gerador por parâmetros (wizard)
- **Sidebar:** `1. Escolher modelo` · `2. Ficha de parâmetros` · `3. Gerar` · `4. Resultado` · `Meus modelos (Price 2)`.
- **Área principal (passo a passo):**
  - **1 Modelo:** galeria das 5 tipologias (escolar/hospitalar/resid. médio/alto/fabril) = modelos Axys (`is_catalog_source`) + "Meus modelos" (Price 2).
  - **2 Ficha:** parâmetros agrupados por `par_grupo`, tipados (número/bool/lista) — single; "refinamento" expõe os compostos (complex).
  - **3 Gerar:** roda os **drivers** contra a ficha → barra de progresso.
  - **4 Resultado:** **planilha itemizada** (preview da grade) + **cronograma** + "abrir no Orça para refinar".
- **Price 2 (autoria):** tela de **amarração** `parâmetro → driver → item do modelo` (dogfood: monta o modelo na própria grade e vincula via `ativo_itens_drivers`).
- **Dados:** `drivers`, `ativo_itens_drivers`, `ficha_*`, gera `ativo_itens` + `cronograma`.

### Easy CPU — importar + analítico
- **Sidebar:** `Importar` · `Analítico` · `Cronograma` · `Histograma de MO` · `Atualizar preços` · `Minhas CPUs/Insumos`.
- **Área principal:**
  - **Importar:** upload Excel → **mapeamento linhas→árvore** (preview com erros) → confirma → grava em `ativo_itens`.
  - **Analítico:** grade com **explosão das composições** (item → CPU → insumos com coef/preço).
  - **Histograma de MO:** gráfico de mão de obra por período/tipo (via `insumos_tipo`).
  - **Atualizar preços:** escolher edição-alvo → **para frente** (atualiza) ou **para trás** (histórico) → recalcula.
  - **Minhas CPUs/Insumos:** CRUD do `tenant_catalogo` (insumo com `pri_origem` = própria/pesquisa/cotação).
- **Dados:** `ativo_itens` (import), `tenant_catalogo`, `catalogo` (custo@edição + série histórica).

### Easy Orça — o coração (Price + CPU + docs)
- **Sidebar:** `Planilha` · `Contexto de preço` · `BDI / Leis Sociais` · `Composições` · `Curva ABC` · `Cronograma` · `Documentação` · `Revisões / Emitir`.
- **Área principal = A GRADE** (`ativo_itens`), planilha viva:
```
 #     Descrição                Base    Código    Un  Qtd   C.Unit   BDI    Total
 1     SERVIÇOS INICIAIS  (grupo)                                            ····
 1.1     Canteiro de obras (grupo)                                          ····
 1.1.1     Placa em lona        CDHU  02.08.050   M2   6    205,77   22,5%  1.512
 ▸ 2   CANTEIRO DE OBRAS  (grupo, colapsado)                                ····
 [+ linha] [Tab indentar] [⇧Tab promover] [↑↓ mover] [BDI ▾] [colar]
```
  - Numeração **derivada** (não digitada); indentar/mover/expandir; **C.Unit resolvido ao vivo** (SE + LS), **BDI por linha**, total calculado.
  - **Contexto de preço:** edição/UF/modalidade (rotacionável) → re-resolve tudo.
  - **BDI/LS:** compor BDIs (onerado/desonerado/reduzido, default) e a LS única da obra.
  - **Documentação:** descritivo amarrado aos itens + caderno de encargos + critérios de medição.
  - **Revisões/Emitir:** congela snapshot (`ativo_revisoes`).
- **Dados:** `ativo_itens` + `orcamento_parametros` + `ativo_bdi`/`ativo_ls` + `cronograma` + `ativo_revisoes` + docs.

## Módulos em slot reservado (telas-esboço; DDL entra quando nascerem)

### EasyDocs — memoriais/especificações
- **Sidebar:** `Modo (IFC | Guiado)` · `Memoriais` · `Especificações` · `Peças` · `Gerar`.
- **Principal:** *IFC* → upload modelo → parâmetros lidos → preview do texto; *Guiado* → checklist/parâmetros (ficha) → preview. Saída versionada nas diversidades / `ativo_docs`.
- **Dados:** `memo_calc` (IFC), `ficha_*`, `ativo_diversidades_catalog`.

### Easy ProjectManager — estrutura de projeto
- **Sidebar:** `Programa/Escopo` · `Nomenclatura (ASBEA/próprio)` · `Pastas` · `Checklists` · `Gerar`.
- **Principal:** configurar escopo → **preview da árvore de pastas** + **checklists por disciplina** → baixar executável/Excel.
- **Dados:** slot `ativo_pm`; disciplinas = `ativo_diversidades_tipo_catalog`.

### Easy BuildDiary — diário de obra
- **Sidebar:** `Novo registro` · `Linha do tempo` · `Evidências` · `Cronograma físico` · `PDF`.
- **Principal:** form **objetivo** (atividades/condições/ocorrências/obs) + anexos → timeline → **gerar PDF**.
- **Dados:** slot `ativo_diario`; físico reusa `cronograma`.

### Easy FinControl — medições / físico-financeiro
- **Sidebar:** `Medições` · `Evolução físico-financeira` · `Histórico` · `Exportar`.
- **Principal:** tabela de **medições por período/serviço/etapa** (correlaciona `ativo_itens` × `cronograma`) + **curva físico-financeira** + export Excel.
- **Dados:** slot `ativo_fin`.

### Easy LicitPlan — planejamento de licitações
- **Sidebar:** `Processos` · `Checklist de documentos` · `Cronograma-base / prazos` · `Alertas`.
- **Principal:** lista por **órgão/modalidade**; checklist de documentos; cronograma com **alertas de prazo**.
- **Dados:** slot `ativo_licit` (pode existir avulso; quando vira obra, núcleo = ativo).
