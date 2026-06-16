# AxysEasy — Módulo Ativo · Descritivo de Telas

**Versão:** 1.0
**Data:** 2026-06-13
**Status:** Norte de implementação das telas (comportamento e fluxo).
**Escopo:** O que cada tela faz, o que recebe, o que entrega adiante (passa-bastão) e a que dado se liga.

> **Nível de detalhe (proposital):** este documento crava **comportamento, fluxo e vínculo de dados** — o que é caro de mudar depois. **Não** crava layout de pixel, componente CSS ou wireframe fechado — o acabamento visual fica livre. É, na camada de telas, o equivalente ao que os contratos de schema são na camada de dados. Convenção visual herdada do catálogo (padrões de tabela, densidade, congelar coluna, botões antes de atalhos) se aplica sem ser reespecificada aqui.

> **Premissa fundadora:** a navegação tem **dois níveis** — o **EMPREENDIMENTO** é o guarda-chuva (agrupador puro: agrupa ativos e consolida; sem ficha, sem orçamento, sem tab própria), e o **ATIVO** é a porteira do trabalho (todo módulo opera sobre um ativo). Um ativo pertence a 0..1 empreendimento; **obra avulsa existe sem empreendimento** e é de primeira classe. Não existe "main por produto" — os cards de módulo na home são **status de licença** (o que o tenant possui), não atalho de acesso. Price 1, Price 2 e CPU **não são módulos** — são **formas de o orçamento nascer**. Depois que o orçamento existe, opera-se sempre o mesmo `ativo_itens`.

---

## 1. Topologia das Telas

Quatro camadas de tela, cada uma com um papel único:

```
LISTAGEM DE EMPREENDIMENTOS  (entrada/saída)
   │  cada linha: empreendimento (com consolidado R$ e nº de ativos)
   │  ▸ expansão inline → links diretos para cada ativo-filho
   │  avulso aparece como "empreendimento de um" (badge avulso)
   │
   ├─ clica no empreendimento ─► VISTA DO EMPREENDIMENTO (lista de ativos + consolidado)
   │                                   │ clica num ativo
   └─ ou salta direto pelo link ───────┤
                                       ▼
┌──────────────────────────────────────────────────────────┐
│ WORKSPACE DO ATIVO  (hub)                                 │
│ ── header de DOIS NÍVEIS (guarda-chuva persistente) ──    │
│ EMPREENDIMENTO: {nome}                          (fixo)    │
│ ATIVO: [ {nome} ▾ ]  · status · UF · ficha   (seletor)    │
│ ──────────────────────────────────────────────────────── │
│ [Dados][Orçamento][Memória][Cronograma][Custos][Docs][Fin]│
└──────────────────────────────────────────────────────────┘
        │  "abrir bancada" (Orçamento / Custos / Cronograma)
        ▼
┌──────────────────────────────────────────────────────────┐
│ BANCADA  (modo foco — tela cheia)                         │   ← edição viva, Excel-like, sidebar própria
│  sidebar de funções + grade/instrumentos                  │
└──────────────────────────────────────────────────────────┘
```

- **Listagem de empreendimentos** = entrada do módulo. Lista **empreendimentos** (não ativos), cada um com consolidado (R$ somado dos filhos, via `WHERE emp_id` — barato) e contagem de ativos. Botão de **expansão inline** abre os ativos-filhos com **link direto** para cada um (salta pro ativo sem entrar no empreendimento). Avulso = "empreendimento de um", linha própria com badge.
- **Vista do empreendimento** = painel de agrupamento (lista de ativos + relatório consolidado). **Não tem tabs, não tem ficha, não tem orçamento** — é agrupador puro. Só lista filhos e consolida.
- **Workspace do ativo** = o hub do trabalho. Header de **dois níveis**: empreendimento em cima (guarda-chuva persistente), ativo embaixo. **Se o empreendimento tem >1 ativo, o ativo vira um seletor (▾)** — troca de ativo pelo próprio header, sem voltar à listagem. As 7 tabs são do ativo; o empreendimento nunca abre tab.
- **Bancada** = modo foco em tela cheia para o trabalho que pede espaço (grade viva do orçamento, manipulação de custos, cronograma). A **sidebar de funções** vive **aqui**, não no workspace.

> **Distinção central:** o **empreendimento é a porteira da navegação**; o **ativo é a porteira do trabalho**. Entra-se por um empreendimento para ver/agrupar/consolidar, mas o workspace (tabs) só abre sobre um **ativo** — porque o empreendimento é agrupador puro e não teria o que pôr numa tab.

> **Regra de ouro de navegação:** workspace manda por **tabs**; bancada manda por **sidebar**. Nunca os dois ao mesmo tempo no mesmo nível.

---

## 2. As Sete Tabs do Workspace

| Tab | Papel | Bancada? | Profundidade detalhada neste doc |
|---|---|---|---|
| **Dados** | Ficha do ativo (parâmetros/atributos) | não (opera no workspace) | ✅ completa |
| **Orçamento** | A grade `ativo_itens` — o coração | ✅ tela cheia | ✅ completa |
| **Memória de Cálculo** | Acervo/auditoria de quantitativo | não (consulta) | ✅ completa |
| **Cronograma** | Visão temporal físico | ✅ tela cheia | ⏳ esboço (slot) |
| **Custos** | Bancada de construção do preço | ✅ tela cheia | ✅ completa |
| **Documentos** | Peças, paradigmas, futura estrutura PM | não | ⏳ esboço (slot) |
| **Finalização** | Bloqueio, revisão, relatórios | não | ✅ completa |

> **Fronteira que o doc crava:** *Memória de Cálculo* = trilha de quantitativo (capturas, conciliações, evidência CAD/IFC, vínculo captura↔item, sobre `memo_calc`). *Documentos* = biblioteca de peças/paradigmas e futura estrutura PM (slot `ativo_docs`). **Não se misturam.** Evidência de captura nunca migra para Documentos; documento de projeto nunca entra em Memória de Cálculo.

---

## 3. Listagem e Vista de Empreendimento

### 3.1 Listagem de Empreendimentos (entrada do módulo)

**Recebe o bastão:** o tenant logado (`tenant_uuid`) e seus contratos licenciados (do Hub).

**O que faz:** lista os **empreendimentos** do tenant, cada linha com nome, **consolidado** (R$ somado dos ativos-filhos), contagem de ativos e status. Botão de **expansão inline (▸)**: se o empreendimento tem ativos, abre os filhos ali mesmo, cada um como **hyperlink direto** para o workspace daquele ativo. Avulso aparece como linha própria com badge "avulso" (um ativo sem empreendimento, de primeira classe). Ações: criar empreendimento, criar ativo (com ou sem empreendimento).

**Passa o bastão adiante:** clicar no empreendimento → vista do empreendimento; clicar no link de um ativo (na expansão) → workspace do ativo direto.

**Liga-se a:** `empreendimentos`, `ativos` (agrupados por `atv_emp_id`, com avulsos onde `atv_emp_id IS NULL`), consolidado por `WHERE emp_id` (+ resumo de `ativo_revisoes`).

### 3.2 Vista do Empreendimento (agrupador puro)

**Recebe o bastão:** `emp_id`.

**O que faz:** painel de agrupamento — lista os ativos-filhos e oferece o **relatório consolidado** (soma dos orçamentos dos filhos). Dados próprios do empreendimento são modestos e coerentes com "agrupador": nome, código interno, identificação do cliente/local. **Não tem tabs, não tem ficha técnica, não tem orçamento próprio** — se tivesse, deixaria de ser agrupador puro.

**Passa o bastão adiante:** clicar num ativo → workspace do ativo (com o empreendimento já no guarda-chuva do header).

**Liga-se a:** `empreendimentos`, `ativos` (filhos), consolidado por `WHERE emp_id`.

---

## 4. Workspace do Ativo (hub)

**Recebe o bastão:** a identidade do ativo (`atv_id` + `atv_tenant_uuid`), o empreendimento-pai (se houver, para o guarda-chuva) e os contratos licenciados do tenant.

**O que faz:** apresenta o ativo em panorama e direciona para o modo de trabalho. **Header de dois níveis (guarda-chuva persistente):** empreendimento em cima (fixo), ativo embaixo. **Se o empreendimento tem >1 ativo, o ativo é um seletor (▾)** — troca de ativo pelo próprio header, sem voltar à listagem; se há um ativo só (ou é avulso), o seletor mostra o ativo único sem oferecer troca. Complementa com status · UF · botão editar ficha, linha de contexto de preço resumida (`SINAPI 04/26 · SP · desonerada · LS X% · BDI Y%`), resumo do estado (total R$, ABC em miniatura, última revisão, nº de itens) e as tabs como portas.

**Comportamento-chave:** o contexto **nunca se perde** — empreendimento e ativo sempre visíveis; trocar de ativo dentro do mesmo empreendimento é um clique no seletor. As tabs **não rolam para fora** do ativo: trocar de tab nunca troca o ativo; trocar de ativo (no seletor) recarrega as tabs para o novo ativo, mantendo o empreendimento.

**Passa o bastão adiante:** ao clicar numa tab, entrega `atv_id` + contexto de preço para a tab; ao "abrir bancada", entrega o mesmo para o modo foco.

**Liga-se a:** `ativos`, `empreendimentos` (guarda-chuva), `orcamento_parametros` (contexto), `ativo_revisoes` (resumo), e leitura do que o Hub libera.

---

## 5. Tab Dados

**Recebe o bastão:** `atv_id` e a **origem** do ativo (como nasceu — Price 1, Price 2, CPU/Orça).

**O que faz:** é a ficha técnica parametrizável (parâmetros + atributos, `ficha_*`). Apresenta os parâmetros agrupados por `par_grupo`, tipados (número/booleano/lista/texto). Subdivisão "gerais × específicos" acontece **dentro** da tab (seções ou sub-abas), não como tabs próprias — é profundidade, não largura.

**Comportamento-chave (o asterisco do "ativo\*"):** a ficha **se adapta à origem**. Ativo nascido de Price 1 mostra só os parâmetros que os drivers daquele modelo consomem (ficha enxuta, guiada). Ativo de Orça pleno mostra a ficha completa. **Mesma tab, profundidade variável** — uma estrutura só servindo do estimativo rápido ao orçamento pericial.

**Passa o bastão adiante:** os valores preenchidos alimentam os drivers (no fluxo Price) e ficam disponíveis para Custos, Documentos e futuros motores (estimativa paramétrica, alertas).

**Liga-se a:** `ativo_ficha_tecnica`, `ficha_parametros`, `ficha_atributos`.

---

## 6. Tab Orçamento + Bancada de Orçamento

O coração do módulo. A tab no workspace mostra **estado**; a bancada em tela cheia é onde se **orça**.

### 6.1 Tab Orçamento (no workspace)

**Recebe o bastão:** `atv_id` + contexto de preço.

**O que faz:** mostra o resumo do orçamento (total, ABC, nº de itens, última revisão) e o botão **"Abrir bancada de orçamento"**. Não é read-only por filosofia — é **panorama**; a edição vive na bancada porque a planilha quer tela cheia (como o Excel), não um pedaço espremido entre breadcrumb e tabs.

### 6.2 Seletor de Origem (quando o orçamento ainda não existe)

**Recebe o bastão:** `atv_id` de um ativo sem orçamento.

**O que faz:** ao abrir a bancada vazia, pergunta **"Como quer começar?"** com as três origens:

- **Estimativo de modelo global (Price 1)** — clona um ativo-paradigma (`atv_is_catalog_source = TRUE`) aplicando drivers pré-setados sobre os parâmetros da ficha. Antes de processar, exibe uma **tela descritiva dos modelos-alvo** (o que cada tipologia gera) e coleta os parâmetros que aquele modelo consome. Resultado: orçamento-clone pronto.
- **Subir o meu + drivers (Price 2)** — o tenant sobe o próprio orçamento, seta seus drivers nos itens, e aplica a mesma mecânica do Price 1 sobre a base dele.
- **Subir o meu / montar do zero (CPU/Orça)** — import total (Excel → árvore) ou montagem direta na grade.

**Passa o bastão adiante:** qualquer origem **escreve no mesmo `ativo_itens`**. Depois disso, a origem **some** — ninguém quer ver "você entrou por Price 1"; quer ver o orçamento. A bancada passa a ser só "Orçamento".

**Liga-se a:** `drivers`, `ativo_itens_drivers`, `ficha_*` (Price); import → `ativo_itens` (CPU); `ativos` com `is_catalog_source` (modelos-alvo).

### 6.3 Bancada de Orçamento (tela cheia)

**O que faz:** a grade viva `ativo_itens`, estilo Excel, com sidebar de funções própria (`Planilha · Composições · Curva ABC · Cronograma(atalho) · Memória(atalho)`). Edição **inline** — esta é a tese central e não se negocia: editar célula, inserir linha, indentar (Tab), promover (⇧Tab), mover (↑↓), colar, com **numeração derivada no render** (`1.2.3` é calculado, nunca digitado).

**Comportamento-chave — expansão por clique a partir do nível 1 congelado:** a grade **abre congelada no nível 1** (só os totais de macrogrupo):

```
1   SERVIÇOS PRELIMINARES ........................... R$ ····
2   FUNDAÇÃO ......................................... R$ ····
3   ESTRUTURA ........................................ R$ ····
```

A expansão é **sob demanda, por clique**: o usuário abre só a Fundação, o resto fica fechado. Desce nível a nível até a folha. Na folha, a linha selecionada **revela** composição (explosão item→CPU→insumos) e memória de cálculo vinculada. Isso resolve o "peso" sem virtualização agressiva no primeiro load — só se renderiza o que foi pedido. (Virtualização entra como otimização técnica quando um nível expandido for muito grande — é problema de engenharia de render, nunca de mandar para outra janela.)

**Preço resolvido ao vivo:** `C.Unit` = resolução contra a edição do contexto (pelado + LS); BDI por linha ou default; total calculado. Nada de preço persistido enquanto vivo.

**Passa o bastão adiante:** o orçamento montado alimenta Custos (manipulação de preço), Cronograma (associação de prazo), Finalização (snapshot) e Memória de Cálculo (vínculo captura↔item).

**Liga-se a:** `ativo_itens` (+ origem CATALOGO/TENANT/LOCAL), `orcamento_parametros`, `orcamento_composicoes/itens` e `orcamento_insumos/preco` (forks locais por exceção), `memo_item_link`.

---

## 7. Tab Memória de Cálculo (Orça-only)

**Recebe o bastão:** `atv_id` + o acervo de `memo_calc` daquele ativo.

**O que faz — e o que NÃO faz:** **não** é tela de cadastro de memória. A memória *acontece* na bancada de orçamento (ao vincular captura a item, ao conciliar). Esta tab é a **vista de acervo e auditoria**: lista os JSONs importados (CAD/IFC, contrato `axys-cad-v1`), mostra as **conciliações já feitas**, o histórico de quais capturas alimentaram quais itens, e os documentos/evidências gerais de quantitativo. É o `memo_calc` ganhando face navegável.

**Por que existe separada do orçamento:** ela é mais viva *dentro* do orçamento, mas tem função clara como repositório — o orçamentista que quer auditar "de onde veio esse 85,32 m²" vem aqui ver a captura, as entidades, a procedência, sem precisar caçar na grade.

**Habilitação:** apenas contrato **Orça**.

**Passa o bastão adiante:** ao clicar numa conciliação/captura, pode levar à linha correspondente na bancada de orçamento (atravessa para o item).

**Liga-se a:** `memo_calc`, `memo_calc_item`, `memo_item_link`. (Detalhe de captura/contrato no `axys_cad_contract.md`.)

---

## 8. Tab Custos + Bancada de Custos

**A tab de atribuição mais rica do módulo.** Custos **não é configuração** — é a bancada onde o orçamentista **pega a fonte-base e a transforma na verdade dele**. Desonerar, rotacionar edição, aplicar LS, compor BDI, regredir/avançar preço contra a fonte, comparar com CUB — o verbo único é **construir o preço**.

### 8.1 Tab Custos (no workspace)

**O que faz:** resume o contexto de preço corrente (`edição-base · UF · modalidade · LS% · BDI%`) e abre a bancada.

### 8.2 Bancada de Custos (tela cheia)

**Recebe o bastão:** `atv_id` + orçamento montado + contexto de preço atual.

**O que faz:** instrumentos de transformação de preço, todos servindo ao mesmo ato (por isso **BDI e LS são instrumentos aqui dentro, não tabs próprias** — fragmentá-los quebraria a unidade do ato):

- **Contexto de preço** — edição-base, UF, modalidade. **Rotacionável**: trocar a edição re-resolve todo o orçamento sem tocar item algum. Item descontinuado na edição-alvo é sinalizado, não quebra.
- **Leis Sociais** — a LS da obra, aplicada **sobre o pelado** (a base SE do catálogo já separa pelado de encargo). **Muda o preço.**
- **BDI** — composição de BDIs (onerado/desonerado/reduzido, default), por linha ou global. **Margem acima do custo** — não muda o custo, compõe o preço de venda.
- **Histórico / CUB / regressão-avanço** — acesso à série histórica da fonte; avançar preço (atualizar) ou regredir (histórico) contra a fonte-base; comparar com CUB.

**Comportamento-chave:** é a **interface visível da resolução de preço** do contrato — o orçamentista mexe nas camadas (contexto, LS, BDI, ajuste) e vê o preço se reconstruir ao vivo. Espelha a tese do schema: preço **resolvido, não gravado**. Pede tela cheia para comparar edições, compor BDI por grupo e cruzar histórico.

**Passa o bastão adiante:** o preço-verdade construído aqui reflete imediatamente na bancada de orçamento (re-resolução) e congela na Finalização (snapshot).

**Liga-se a:** `orcamento_parametros` (contexto), `ativo_bdi`/`ativo_ls`, `catalogo` (custo@edição + série histórica), `ati_ajuste_json` (ajuste reversível por item).

---

## 9. Tab Finalização

**Recebe o bastão:** o estado vivo completo do ativo (orçamento + custos resolvidos + memória + parâmetros).

**O que faz:** é o **bloqueio e a saída**. Emite revisão (congela snapshot write-once), gera relatórios e os entregáveis amarrados ao orçamento (descritivo, caderno de encargos, critérios de medição — nos contratos que os incluem). "Voltar ao estágio inicial" de ajustes acontece antes daqui; uma vez emitida, a revisão é foto imutável.

**Comportamento-chave:** estado vivo continua editável; a revisão é uma **fotografia** (`rev_snapshot_json` para fidelidade + `rev_resumo` para o que se consulta). Não há "versão viva 1/2/3" — há o ativo vivo e as fotos R01, R02…

**Passa o bastão adiante:** o snapshot emitido vira o registro auditável/reproduzível; os relatórios saem para fora do sistema (download/export).

**Liga-se a:** `ativo_revisoes`, e os registros de documento (descritivo/caderno) conforme contrato.

---

## 10. Tabs em Slot Reservado (esboço)

DDL entra quando o microapp nascer (namespace reservado ≠ tabela criada).

### 10.1 Cronograma (bancada futura)
Resumo no workspace; **editor Gantt em tela cheia** quando entra para trabalhar (visão temporal é ferramenta-à-parte, justifica bancada própria). Físico reusa o cronograma do ativo; correlaciona com `ativo_itens` para o físico-financeiro. Slot operacional quando o microapp de cronograma nascer.

### 10.2 Documentos (slot `ativo_docs`)
Casa das peças, dos **orçamentos-paradigma** (incl. os `is_catalog_source` que o Price 1 consome e os que o tenant guarda como baliza) e da futura estrutura do Easy ProjectManager (pastas/checklists). Tab visível agora; DDL quando o microapp nascer.

---

## 11. Passa-Bastão (visão de fluxo consolidada)

```
LISTAGEM DE EMPREENDIMENTOS (entrada)
  │ entrega: tenant + contratos licenciados; consolidado por empreendimento
  │ ▸ expansão → link direto a cada ativo-filho;  avulso = "empreendimento de um"
  ├─► VISTA DO EMPREENDIMENTO ── lista de ativos + consolidado (agrupador puro, sem tabs)
  ▼
ATIVO (porteira do trabalho — sob o guarda-chuva do empreendimento no header)
  │ entrega: atv_id + emp (guarda-chuva) + contratos licenciados
  ▼
WORKSPACE (hub) — header de 2 níveis: EMPREENDIMENTO fixo · ATIVO ▾ (seletor se >1)
  │ entrega: atv_id + contexto de preço → para a tab/bancada escolhida
  ├─► DADOS ──── alimenta drivers e motores; valores da ficha
  │
  ├─► ORÇAMENTO
  │     │ se vazio → SELETOR DE ORIGEM (Price1 | Price2 | CPU/Orça)
  │     │ todos escrevem no MESMO ativo_itens; origem some depois
  │     └─► BANCADA: grade viva, nível 1 congelado, expande por clique,
  │                  folha revela composição + memória; preço resolvido ao vivo
  │
  ├─► MEMÓRIA ── acervo/auditoria de capturas e conciliações (Orça-only);
  │              atravessa para o item na bancada
  │
  ├─► CUSTOS ──► BANCADA: transforma fonte-base em preço-verdade
  │              (contexto rotacionável · LS sobre pelado · BDI acima ·
  │               histórico/CUB/regressão); re-resolve o orçamento ao vivo
  │
  ├─► CRONOGRAMA (slot) ── resumo + editor Gantt futuro
  ├─► DOCUMENTOS (slot) ── peças, paradigmas, futura estrutura PM
  │
  └─► FINALIZAÇÃO ── bloqueio: emite revisão (snapshot imutável) + relatórios
```

---

## 12. Mapa de Tabs por Contrato

Quais tabs cada contrato enxerga. Liberação vem da **licença no Hub**; o Easy renderiza só o permitido.

| Tab | Price 1 | Price 2 | CPU | Orça |
|---|---|---|---|---|
| **Dados** | ✅ (ficha enxuta, guiada) | ✅ | ✅ | ✅ (completa) |
| **Orçamento** | ✅ (resultado do clone) | ✅ (base própria + drivers) | ✅ (montagem/operação) | ✅ (operação plena) |
| **Memória de Cálculo** | — | — | — | ✅ |
| **Cronograma** | ✅ (gerado) | ✅ (gerado) | ✅ | ✅ |
| **Custos** | parcial (resultado) | parcial | ✅ (atualiza/regride preço) | ✅ (construção plena: LS, BDI, histórico, CUB) |
| **Documentos** | — | — | parcial | ✅ |
| **Finalização** | ✅ (download estimativo) | ✅ | ✅ (relatórios) | ✅ (revisão + caderno + descritivo) |

> Leitura do mapa: **Price** gera e mostra resultado (foco em Dados→Orçamento→download). **CPU** abre a operação (analítico, histograma, atualização de preço) mas sem a construção plena de preço/documentação. **Orça** abre tudo — é o alvo do qual os demais derivam, incluindo Memória de Cálculo, construção plena de Custos e os entregáveis de Finalização. A regra de habilitação por contrato é decidida **agora** para não virar retrabalho de permissão depois.

---

## 13. Comportamentos Transversais (cravados)

1. **Empreendimento agrupa, ativo trabalha.** Entrada = listagem de empreendimentos (guarda-chuva persistente no header); workspace só abre sobre um ativo. Avulso é de primeira classe (`atv_emp_id` NULL). Cards de módulo na home = status de licença, não atalho.
2. **Header de dois níveis.** Empreendimento fixo + ativo em seletor (▾ quando o empreendimento tem >1 ativo) — troca de ativo sem sair do empreendimento; contexto nunca se perde.
3. **Workspace por tabs; bancada por sidebar.** Nunca os dois no mesmo nível. A sidebar de funções vive na bancada.
4. **Orçamento, Custos e Cronograma têm bancada em tela cheia.** Edição viva pede espaço; resumo no workspace, trabalho no modo foco.
5. **Edição é inline (Excel-like).** Bancada não é "read-only + popup"; é a planilha viva em tela cheia.
6. **Nível 1 congelado, expansão por clique.** Só se renderiza o que o usuário pede ver; folha revela composição + memória.
7. **Origem do orçamento é escolha única** (seletor na bancada vazia) e some depois — tudo vira `ativo_itens`.
8. **Preço resolvido, não gravado.** Custos é a interface dessa resolução; só Finalização congela.
9. **Habilitação por contrato decidida agora** (mapa §12).
10. **Fronteira Memória × Documentos** preservada: trilha de quantitativo × biblioteca de peças.
11. **Slot reservado ≠ tela pronta.** Cronograma e Documentos visíveis agora; DDL quando o microapp nascer.
