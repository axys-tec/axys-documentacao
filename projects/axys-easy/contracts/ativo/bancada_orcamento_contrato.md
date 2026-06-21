# Bancada de Orçamento — Contrato de Montagem (Tela de Produção + easy-to-excel)

> **Escopo:** este documento especifica a **tela de produção** do orçamento — a grade dinâmica, reposicionável, estilo Excel-web — e o **contrato de ida-e-volta com o Excel** (easy-to-excel). Não trata da tab de exibição (resumo no workspace), que só mostra estado. Cronograma é documento separado.
>
> **Princípio que costura tudo:** tela, Excel e API são **três portas para a mesma `ativo_itens`**. O que se faz numa porta tem que aparecer igual na outra. Round-trip sem perda. A garantia disso é **uma só**: cada item carrega uma **chave estável** (`ati_id`) que viaja em toda representação.

---

## 1. A verdade e suas três portas

```
                    ativo_itens  (a árvore — única fonte de verdade)
                    parent_id · ordem esparsa · path · tipo · cmp · qtd · bdi
                          ▲              ▲                ▲
                          │              │                │
                    ┌─────┴────┐   ┌─────┴─────┐    ┌─────┴──────┐
                    │ BANCADA  │   │ easy-to-  │    │  IMPORT    │
                    │ (tela)   │   │  excel    │    │ (3os)      │
                    └──────────┘   └───────────┘    └────────────┘
                     edição viva     round-trip       carga inicial
```

- A **árvore** manda. Numeração `1.2.3` é **render**, nunca dado (deriva de `parent_id`+`ordem`).
- Preço é **resolvido ao vivo** (nunca gravado na linha) contra o contexto (`orcamento_parametros` + LS + BDI). Só a emissão de revisão congela snapshot.
- As três portas leem e escrevem a mesma estrutura. Nenhuma porta tem "seu próprio formato de verdade".

---

## 2. A chave estável — o que faz "não quebrar"

Cada linha, em qualquer representação, carrega o **`ati_id`** (o id real do item na árvore) — e ele fica **exposto**, não escondido. É a identidade que vincula a linha à API e aos geradores de memória (AxysCAD/Revit): ver a chave ensina o usuário a confiar nela como o registro de verdade. No Excel ela ocupa uma **coluna própria visível** (ex.: coluna `A`), **protegida contra edição** e fora da **área imprimível** (não suja o orçamento impresso, mas está lá para o usuário e para o round-trip). Na tela aparece como identificador da linha.

Regra de ouro do round-trip:

- Linha **com `ati_id`** → é um item **existente**. Na volta, o sistema **atualiza no lugar** (qtd, descrição, cmp, bdi, posição). Reposicionar = mudar `parent_id`/`ordem`, **nunca** apagar-e-recriar.
- Linha **sem `ati_id`** (em branco) → é um item **novo**. Na volta, o sistema **cria** (gera `ati_id`, calcula `path`).
- `ati_id` que **existia e sumiu** do Excel/tela → item **removido** (deleta subárvore, primitiva "deletar").

Sem a chave, mover uma linha no Excel viraria "apaguei o item X e criei o item Y" — perderia memória de cálculo, histórico, vínculos. **Com a chave, mover é mover.** É isto que torna o round-trip idempotente.

> Implicação de produto: o usuário **vê** a coluna do `ati_id` (ela é a identidade do registro, útil para suporte, API e vínculo com o AxysCAD), mas **não pode editá-la** — é protegida no template e fica fora da área imprimível. Se ele apagar/alterar por engano, a linha vira "nova" na volta (cria duplicata). O template blinda a coluna contra escrita, mas a mantém à vista.

---

## 3. A grade — estrutura de colunas

Espelha a `Plan Orçamentária` da planilha-alvo, já com a sua compactação de colunas:

| Col | Campo | Origem | Editável? |
|-----|-------|--------|-----------|
| (chave) | `ati_id` | árvore | **não** (visível, protegida) |
| Nível | `ati_tipo` (NÍVEL 1–5 / SERVIÇO) | usuário escolhe | sim — define comportamento |
| Item | numeração `1.2.3` | **derivada** (render) | não (calculada) |
| Base | `ati_cmp_origem` (CATALOGO/TENANT) | usuário | sim (no serviço) |
| Código | `ati_cmp_id` → código | usuário (busca catálogo) | sim (no serviço) |
| Descrição | resolvida da composição | **resolvida** | não (vem da base) |
| Unid. | resolvida | **resolvida** | não |
| Qtd | `ati_quantidade` (2 casas, ≥ 0) | usuário **ou** memória | sim, se não tiver memória |
| Custo unit. | custo unit. resolvido | **resolvido ao vivo** | não |
| BDI | **seletor** (N/D/Reduzido) + % | usuário (`ati_bdi_id`) | sim (no serviço) |
| Unit. c/ BDI | unit. c/ BDI resolvido | **resolvido** (TRUNC) | não |
| Preço c/ BDI | subtotal (qtd × unit c/BDI) | **resolvido** (TRUNC cascata) | não |

> **Tela (implementado):** a coluna **`id` é a 1ª (à esquerda)** e funciona como **cabeçalho/seletor de linha** (estilo Excel). **Não há coluna "Custo total"** nem coluna **"Obs."** na grade (decisões de tela). Ordem das colunas de valor: Custo unit. · BDI · Unit. c/BDI · Preço c/BDI.

Dois comportamentos por tipo de linha (a mecânica central, vinda da planilha):

- **SERVIÇO** (folha): **calcula** o próprio valor (`custo_unit × qtd`, com TRUNC). Tem base/código/qtd/bdi.
- **NÍVEL 1–5** (cabeçalho/nó): **agrega** — soma os serviços abaixo dele. Não tem base/código/qtd próprios; o valor é a soma da subárvore (derivada, não digitada).

> A coluna **BDI não é só %** — é o **seletor de qual BDI** da obra aquela linha usa (`ati_bdi_id` → `ativo_bdi`, que é múltiplo: ONERADO/DESONERADO/REDUZIDO). O % exibido é consequência da seleção. Sem o seletor, perde-se o BDI-por-linha.

---

## 4. A mecânica de nível — "selecionar nível para descer o serviço"

A grade renderiza a **árvore inteira** (numeração derivada). Cada **grupo é colapsável/expansível** pelo caret (▾/▸) — colapso **manual, sob demanda**; **não** há colapso forçado no nascimento nem render preguiçoso *(decisão de tela 2026-06: render completo + colapso manual)*. O usuário monta descendo nos níveis e inserindo serviços/níveis abaixo.

Fluxo de produção (tela, implementado):
1. **"+ linha" / Enter no fim / menu "Incluir acima/abaixo"** abre uma linha **rascunho client-side sem `ati_id`** (nada gravado ainda — não estoura id). A nova linha **repete o nível da linha acima** (1ª linha = Nível 1).
2. No rascunho, escolhe o **NÍVEL** no dropdown (define o `ati_tipo`/profundidade). **SERVIÇO sempre enrabicha no grupo acima** (nunca fica na raiz); nível N = filho do nível N-1 mais próximo acima.
3. No SERVIÇO, busca a composição no catálogo (base+código) → a API resolve descrição/unid./custo. No NÍVEL, digita o nome.
4. Informa **quantidade** (digitada — 2 casas, ≥ 0 — ou herda da memória se `ati_have_memory_calc`).
5. Escolhe o **BDI** da linha (ou herda o default da obra).
6. **Enter grava** o rascunho (gera 1 `ati_id`, calcula `path`) e abre o próximo abaixo; **Esc descarta**. O cabeçalho do nível **autossoma** sozinho (derivado).

Reposicionar (o "dinâmico"): arrastar/recortar uma linha ou subárvore para outro pai muda `parent_id`+`ordem`; a numeração re-renderiza; o `path` recalcula; **o `ati_id` não muda** → nada se perde.

---

## 4-bis. Origem da quantidade (independe — três vias para o mesmo campo)

A `ati_quantidade` pode nascer de **três** lugares, e isso **independe** do resto (não muda preço, não muda estrutura — só de onde o número veio). O discriminador é `ati_have_memory_calc`:

1. **Digitada** — o usuário bate o número direto na célula Qtd. `ati_have_memory_calc = FALSE`. Morreu ali, sem memória associada.
2. **Memória de cálculo — livre digitação** — o usuário cadastra uma memória manual (texto/conta livre). `memo_calc` com `mc_origem = 'MANUAL'`, `mc_json_cru = NULL` (a verdade são os `memo_calc_item` digitados). A qtd do item = Σ dos blocos linkados.
3. **Memória de cálculo — importada (gerador)** — AxysCAD (1ª versão a sair) e seus sucessores (AxysRevit, "AxysStrator"…) **geram** memória e passam um **JSON estruturado**. `memo_calc` com `mc_origem = 'CAD'|'RVT'|'IFC'`, `mc_json_cru` = o payload bruto (a verdade). A qtd = Σ dos blocos.

> **JSON agnóstico de plataforma:** o contrato AxysCAD já define a estrutura, e ela é **sempre a mesma** independente da ferramenta de origem (AutoCAD, Revit, IFC, futuros). O `platform` viaja **dentro** do JSON; a API **nunca ramifica** por plataforma. O gerador evolui; o contrato do JSON não muda.

No fluxo de tela: ao definir a quantidade de um serviço, o usuário escolhe **digitar direto** ou **cadastrar memória**; se cadastrar, o sistema pergunta **"formato livre ou importou?"** — livre abre o editor de memória manual; importou recebe/vincula o JSON do gerador. Em ambos, a Qtd da grade passa a ser **derivada** (Σ dos blocos) e a célula fica read-only com um indicador "tem memória" (atravessa para a tab Memória de Cálculo).

Resumo da coluna Qtd: editável quando digitada; **read-only + indicador** quando vem de memória (livre ou importada). O vínculo item↔memória é `memo_item_link` (1×1 no caso direcionado, N:N no global).

> **Decisão de tela (a detalhar ao projetar Memória — pós-fechamento da bancada):** quando a Qtd vem de memória (`ati_have_memory_calc = TRUE`), a célula é um **link clicável** que abre a memória daquela linha (tab/registro de Memória de Cálculo) — vale para memória **manual-livre E importada** (ambas são registro `memo_calc`; o que muda é o editor por trás). Qtd **digitada direto** (sem memória) é célula comum, **sem link**.

---

## 5. Edição estilo Excel-web — primitivas

A bancada é **planilha viva**, não "read-only + popup". Comportamentos esperados:

- **Teclado:** Tab/⇧Tab entre células · setas ↑/↓ entre linhas · **Enter** confirma e desce (no fim, cria) · **Tab no campo Nível** indenta / ⇧Tab desindenta (re-parenteia **mantendo a posição**).
- **Seleção pela coluna `id`** (cabeçalho de linha, estilo Excel): clique = seleciona · Ctrl = alterna · Shift = intervalo · **arrastar** (segurar e mover) = intervalo · **Esc** desseleciona. Cursor: seta → no hover, cruz ao arrastar.
- **Inserir = rascunho:** "+ linha" / Enter no fim / menu "Incluir acima/abaixo" → linha **sem `ati_id`**; grava só no **Enter**, descarta no **Esc** (§4).
- **Delete/Backspace = LIMPA os dados** da(s) linha(s) selecionada(s) (mantém a linha/tipo/posição). **Excluir** (deleta subárvore) = menu botão-direito "Excluir".
- **Clipboard de linhas:** Ctrl+C / Ctrl+X / Ctrl+V; no menu, **Copiar / Colar** e **"Inserir células copiadas/recortadas"**. Cópia duplica a subárvore; recorte move.
- **Arrastar** (alça ⠿) reordena/reparenteia: soltar num **grupo** = 1ª filha; soltar num **serviço** = irmã.
- **Edição inline** (qtd, descrição livre); base/código por **autocomplete** do catálogo. **Colar bloco TSV** do Excel; **preencher série** (Ctrl+⇧+D na Qtd).

Toda edição é uma **primitiva de árvore** sobre a `ativo_itens`:

| Ação na tela | Primitiva na árvore |
|--------------|---------------------|
| nova linha | rascunho (sem id) → **INSERT no Enter** (ordem esparsa); Esc não grava |
| mover/arrastar | UPDATE `parent_id`+`ordem` (path recalcula) |
| indentar/desindentar (Tab) | UPDATE `parent_id`+`ordem` (mantém posição) |
| **limpar dados (Delete)** | UPDATE → null em `cmp`/`qtd`/`bdi`/descrição (linha permanece) |
| excluir (menu) | DELETE subárvore (cascade) |
| trocar base/código | UPDATE `cmp_origem`+`cmp_id` |
| editar qtd | UPDATE `ati_quantidade` (2 casas, ≥ 0) |

A ordem **esparsa** (1000, 2000…) é o que permite inserir no meio sem renumerar tudo — mesma razão da ordem esparsa das etapas.

---

## 6. A regra TRUNC(2) em cascata (cravada — padrão obra pública)

**Nunca `ROUND`. Sempre `TRUNC(2)`. E em CADA etapa, não só no fim.** Cada operação trunca; a próxima consome o **já-truncado** (como na planilha-alvo):

```
custo_total      = TRUNC(custo_unit × qtd, 2)
unit_c_bdi       = TRUNC(custo_unit × (1 + bdi), 2)
preco_total_cbdi = TRUNC(qtd × unit_c_bdi, 2)     ← usa o unit_c_bdi JÁ truncado
```

O cabeçalho de nível soma os `preco_total_cbdi` (já truncados) dos serviços abaixo. Se a API truncar só no final, o número **diverge** do esperado pelo órgão — e em licitação, centavo divergente vira impugnação. Esta regra vale **igual** na tela, no Excel e na API — é o que faz os três baterem ao centavo.

---

## 7. easy-to-excel — o contrato de ida e volta

### 7.1 Ida (árvore → Excel)
A API exporta a árvore atual num template fixo da Axys. Cada linha leva:
- **`ati_id`** (coluna visível e protegida, fora da área imprimível — a chave/identidade do registro) · **Nível** · **Base** · **Código** · **Qtd** · **BDI (seletor)**
- E, **só como exibição** (read-only, resultado que no Excel antigo vinha de VLOOKUP): Descrição, Unid., Unitário, Preço c/ BDI. Esses campos a API **resolve** — o Excel não os carrega como verdade.

> O Excel deixa de ter o catálogo embutido. Os VLOOKUP morrem. A planilha vira "burra no dado, fiel na estrutura"; a resolução é da API.

### 7.2 Volta (Excel → árvore)
O parser lê **apenas o núcleo editável**: `ati_id` (chave) + Nível + Base + Código + Qtd + BDI. Descrição/unid./custo do Excel são **ignorados na volta** (a API re-resolve do catálogo). Reconciliação pela chave (§2):

```
para cada linha do Excel:
   tem ati_id existente?  → UPDATE no lugar (qtd, cmp, bdi, posição)
   ati_id em branco?      → CREATE (gera id, calcula path)
ati_id que sumiu?         → DELETE subárvore
```

A posição (nível + ordem das linhas no arquivo) reconstrói `parent_id`/`ordem`. A numeração `1.2.3` do Excel é **descartada** na leitura (é render; a árvore a recalcula).

### 7.3 Regra de colisão / atualização
Reimportar o **mesmo** arquivo é **idempotente** (a chave garante: atualiza no lugar, não duplica). Conflito real (duas edições simultâneas — uma na tela, outra no Excel) resolve por **last-write** no nível do item, com o evento registrado em `ativo_eventos`. Não há merge automático de célula; a chave garante que o conflito seja item-a-item, não arquivo-inteiro.

### 7.4 Vínculo de composição vindo do Excel
A célula Base+Código no Excel vira `ati_cmp_origem`+`ati_cmp_id` na volta (a API resolve o código contra o catálogo da origem indicada). Código inexistente na origem → linha entra em **conciliação** (não quebra a importação; sinaliza para o usuário decidir — mesma filosofia do AxysCAD e do "conferir parâmetros").

### 7.5 O arquivo `Axys_Easy_Orca_Plan.xlsx` — estrutura e dois modos de partida

O arquivo é **um só**, com duas formas de começar:

- **Modo 1 — planilha crua que se vincula.** Abre com uma aba "Início". O usuário loga → a API vincula ao ativo → o arquivo monta as abas (cabeçalho do ativo, estrutura pronta). Se o ativo já tem dados, eles vêm preenchidos.
- **Modo 2 — baixada já preenchida.** O usuário baixa pela tela do ativo e ela vem **pronta**, com o orçamento atual já lançado.

Mesma planilha, dois pontos de partida. Abas:

```
Axys_Easy_Orca_Plan.xlsx
├── "Início"     → vincula ativo (login → API → monta as abas)
├── "CPUs"       → ÍNDICE de busca: Fonte | Código | Descrição | Unid | Custo-base
│                  (datado por edição; alimenta o VLOOKUP e a busca offline)
└── "Orçamento"  → a plan (a grade): ati_id · Nível · Base · Código · Qtd · BDI · valores
```

Onboarding da aba CPUs (passo a passo do modo 1): vincula ativo → define **fonte-base/edição/modalidade-LS** (a API pergunta, o usuário escolhe uma edição por fonte) → a API preenche a aba CPUs com o índice daquela(s) fonte(s).

### 7.6 VLOOKUP é só EXIBIÇÃO — a app é a fonte da verdade

O VLOOKUP da `plan` **não recalcula preço** — ele **puxa o que a app já resolveu**:
- preenche **descrição/unidade** a partir do código (busca);
- puxa o **unitário JÁ RESOLVIDO pela app** (com LS/BDI/recursão/swap mensalista) — não o reconstrói.

O custo-base da aba CPUs é o **provisório bruto** (conforto offline, rotulado "a resolver"); o **unitário resolvido** (verdade) vem da app. A "conferência de conta" da planilha-alvo permanece como **auditoria visual** (mostra `qtd × custo-base` ao lado do `valor_resolvido` e destaca divergência) — é conferência, não motor de preço.

### 7.7 Convergência app ↔ Excel ao centavo (TRUNC explícito nas fórmulas)

A app e o Excel só batem ao centavo se **cada célula que a app trunca, o Excel também trunque explicitamente** — porque o Excel calcula em ponto flutuante e *exibe* arredondado, mas a próxima fórmula consome o número cheio (escondido), divergindo da app que segue com o truncado.

Regra: **toda fórmula de subtotal na `plan` usa `TRUNC(...;2)` explícito**, espelhando a mesma cascata da app (§6):
```
unit_c_bdi       = TRUNC(custo_unit * (1 + bdi); 2)
preco_total_cbdi = TRUNC(qtd * unit_c_bdi; 2)     ← consome o unit_c_bdi já truncado
```
A quantidade é `numeric(14,2)` (2 casas) e os subtotais truncam em cada etapa → app e Excel convergem célula a célula. **Sem o TRUNC explícito na fórmula, a cascata desalinha** (Excel guarda o cheio). Não é VBA — é a função TRUNC na fórmula da Tabela estruturada.

### 7.8 Sem VBA-guardião — Tabela estruturada cuida das mexidas

O VBA que "reconstrói fórmula a cada inserir/mover linha" é a dívida da planilha antiga e **não é necessário**:
- A `plan` usa **Tabela estruturada** (ListObject) com fórmulas por **nome de coluna** (`[@Código]`, `Tabela_CPUs[...]`). O Excel **propaga e mantém a fórmula sozinho** ao inserir/mover linha — comportamento nativo, zero VBA.
- A verdade não mora na fórmula (mora na app, reconciliada pela chave). Fórmula que desalinhe numa mexida estranha **não corrompe** — a próxima sync sobrescreve com o valor resolvido. Sem pressão de "blindar fórmula".
- Comunicação (login, vincular, sync de delta): **Office.js (add-in)** de preferência — roda no Excel desktop **e** web, não quebra a cada update do Office. **VBA, se existir, é MÍNIMO** (só chamar API/sync) — **nunca** guardião de fórmula.

### 7.9 Locale pt-BR — o que quebra (e como neutralizar)

O Excel pt-BR tem três armadilhas que quebram número e fórmula silenciosamente:
- **Decimal = vírgula** (`2,74`, não `2.74`).
- **Separador de argumento = ponto-e-vírgula** (`=TRUNC(A1;2)`, não `,2`).
- **Função traduzida** (`TRUNCAR`/`PROCV`/`SE` em vez de `TRUNC`/`VLOOKUP`/`IF`).

**Neutralização (regra de geração):** a API **nunca escreve número nem fórmula como texto/string** — sempre como **número e fórmula nativos via biblioteca** (openpyxl/SheetJS/ClosedXML). A biblioteca grava no **formato interno do Excel** (sempre en-US, vírgula como separador de argumento), e o Excel pt-BR **abre e exibe traduzido** automaticamente (`TRUNCAR`, `;`, `2,74`) sem nenhum tratamento extra. Números gravados como número de verdade recebem o separador decimal do locale na exibição sozinhos.

Consequência: na **geração** trabalha-se sempre em `TRUNC(A1,2)` (interno); o usuário pt-BR vê `TRUNCAR(A1;2)` funcionando. O locale só viraria problema se alguém montasse fórmula como string crua — o que o contrato **proíbe**. Colunas de valor são **numéricas de verdade** (nunca texto), senão VLOOKUP/TRUNC falham silenciosamente.

---

## 7-bis. Tempo real e colaboração (WebSocket)

**Decisão MVP (2026-06):** o transporte do MVP é **API unidirecional** (request/response) com **JWT sobre TLS** (validade 8h / 28800s). **WebSocket fica adiado** como evolução — não é obstáculo, mas não entra no v1. O modelo de colaboração escolhido (§9-bis) **não depende** de WebSocket, então adiá-lo não trava nada.

- *JWT 8h:* cobre o dia de trabalho. **Acompanhar de refresh token** — sem ele, expirar no meio de um lançamento (sem reconexão automática, já que não há socket) pode perder trabalho não-sincronizado.
- *Sem tempo real no v1:* a principal vê o trabalho de uma bancada de apoio **on-demand** (ao sincronizar/atualizar), não ao vivo. Suficiente porque a colaboração é por **faixas separadas** (§9-bis) — a principal não precisa ver ao vivo o que não pode editar.

**Evolução futura (registrada, fora do MVP):**
- *Socket parcial:* notificar a principal "a faixa X foi atualizada" (um evento de aviso, não stream de deltas) — barato, dá vivacidade sem complexidade. Acima dele:
- *WebSocket completo:* presença + sync ao vivo + delta por `ati_id`. A chave estável já habilita o sync incremental (empurrar "item 47 mudou" e atualizar só aquela linha).
- *Edição célula-a-célula simultânea:* exige CRDT/OT **sobre árvore** — problema difícil, **conscientemente evitado** (ver §9-bis: particionamento elimina a necessidade).

**Fronteira tela × Excel (vale em qualquer fase):** tempo real (quando existir) vale para **tela** e **excel-web** (cliente do socket). O **`.xlsx` desktop NÃO** participa de tempo real — é sempre round-trip **discreto** (baixa, edita, sobe, reconcilia pela chave §7.2).

---

## 8. Bancada vazia — seletor de origem

Quando o orçamento ainda não tem itens, a bancada abre com o **seletor de origem** (como o orçamento nasce):
- **Price 1 / Price 2** (paramétrico — gera a árvore a partir da ficha + drivers)
- **CPU / Orça** (manual — começa do zero, monta na grade)
- **Importar** (easy-to-excel ou planilha de terceiro)

Escolhida a origem, ela **some** — tudo vira `ativo_itens` e a partir daí se opera a mesma grade, independente de como nasceu.

> **Tela (implementado):** uma vez **iniciada**, a bancada **não volta** ao seletor de origem. Excluir todos os itens deixa a grade **vazia com "+ linha"** (a origem não reaparece).

---

## 9. Resolução de preço (o motor por trás da grade)

Cada vez que a grade renderiza ou recalcula, a API resolve **ao vivo**:
1. Lê o vínculo (`cmp_origem`+`cmp_id`) e **explode a composição recursivamente até a folha** (insumo).
2. Na folha de **mão de obra**: aplica **LS** (global da obra, `ativo_ls`) e, se contexto = mensalista, faz o **swap horista→mensalista** (de-para do catálogo) + normaliza fonte (CDHU→SINAPI) se preciso.
3. Aplica **BDI** da linha (`ati_bdi_id`).
4. **TRUNC(2) em cascata** (§6).
5. Guardas: **anti-ciclo** (composição não pode conter a si mesma) e **memoização** (resolve a sub-receita uma vez por contexto).

Rotacionar contexto (edição, UF, LS, regime, BDI) **re-resolve tudo** sem tocar item nenhum. É isto que mantém "preço resolvido, não gravado".

---

## 9-bis. Colaboração por particionamento (bancada de apoio)

Padrão: **particionamento com trava pessimista e escritor único por faixa** — não há edição concorrente da mesma região, então não há conflito a resolver (dispensa CRDT/OT). Alinha-se ao ofício: dois orçamentistas nunca tocam a mesma disciplina ao mesmo tempo (um pega de cima, outro de baixo).

### Papéis assimétricos (o que simplifica)

- **Bancada principal** — dona do orçamento e do lock. Pode **empurrar** e **atualizar** (bidirecional com a web). Vale para web **ou** Excel.
- **Bancada de apoio** — **deriva** da principal, **nasce regrada** (já travada na faixa que recebeu). **Só empurra**, nunca puxa. O que está nela é o que está na web (mesmo sem fluxo bidirecional). Ao empurrar, a web faz o **delta** e garante unicidade.

A assimetria mata o conflito na origem: a apoio só escreve sua faixa (região disjunta), a principal edita o resto. Territórios separados → empurrões nunca colidem.

### Lock por path — leva tudo que está amarrado abaixo

O lock é ancorado num **nó** (um `ati_id`) e trava **a subárvore inteira** dele: o nó **e todos os descendentes**, por prefixo de path.

```
Lock no item 6 (path 0006):
  trava  0006              (o nó-âncora)
   e     0006.%            (TODOS os descendentes: 0006.0001, 0006.0001.0003, … até 5 níveis + serviço)
```

Regra: `lock(âncora)` ⇒ trava `path = âncora.path` **OU** `path LIKE âncora.path || '.%'`. **Leva tudo que pende abaixo** — exatamente "fiz lock no 6, então 6 e 6.x.x.x.x.x estão travados".

- **Mãe da âncora:** trava **estruturalmente** na principal (não pode mover/deletar o nó-âncora enquanto a apoio trabalha dentro), mas o **valor agregado continua resolvendo** (a mãe soma os filhos que a apoio mexe). Lock estrutural, não de leitura.
- **Fora da subárvore:** a principal edita normalmente.

### Persistência do lock (decisão: coluna em `ativo_itens`)

O lock é **persistido em coluna** na `ativo_itens`, marcando o **nó-âncora travado** (quem é o dono/sessão da apoio). O escopo (a subárvore) é **derivado por path** em tempo de consulta — não se marca linha a linha; marca-se a âncora, e o `path LIKE` resolve o alcance.

> **[CONSIGNADO — schema a cravar depois]** provável: `ati_lock_owner` (sessão/usuário que segura) + `ati_lock_em` (quando) na âncora; descendentes herdam por path. SQL fica para a rodada de schema; aqui só se registra a necessidade e a forma.

- **Sem TTL (decisão):** o lock **fica até a apoio liberar explicitamente** (não expira sozinho).
- **[ATENÇÃO — risco a mitigar]** sem TTL, se a apoio fechar mal (crash/queda), o lock vira **órfão** e ninguém edita aquela faixa. Mitigação obrigatória: **liberação forçada** pelo dono da principal (ou admin) — um "destravar faixa" manual. Sem isso, faixa órfã trava o orçamento até intervenção de banco.

### Fluxo de escrita — "atualizar" é merge em DUAS fases (nunca overwrite)

Na principal, **atualizar** torna a web fonte da verdade e muda o Excel. O cuidado central:

```
ATUALIZAR (na principal) =
  1. EMPURRA primeiro o que é LOCAL-novo (existe aqui, não na web)   ← protege trabalho não-sincronizado
  2. SÓ ENTÃO puxa o que é WEB-novo (existe na web, não aqui)         ← tipicamente o que a apoio empurrou
```

Nunca **sobrescrever** o Excel com a web direto — isso apagaria o local não-empurrado. Como apoio e principal mexem em **regiões disjuntas** (lock por path), o merge é trivial: "web tem e aqui não" = trabalho da apoio chegando; "aqui tem e web não" = trabalho local subindo. Reconciliação por `ati_id` (item novo local sem id → sobe; item da faixa travada criado pela apoio → desce). Nenhum pisa no outro.

### Múltiplas bancadas

Pode haver **N** bancadas de apoio, cada uma ancorada num nó **disjunto** (apoio-1 no nó A, apoio-2 no nó B, principal no resto). A regra de disjunção é garantida pelo path: **uma âncora não pode estar dentro da subárvore de outra âncora já travada** (senão sobreporia). O sistema recusa abrir apoio num nó cujo path esteja sob um lock vigente.

---

## 10. Invariantes (cravados — valem nas três portas)

1. **A árvore é a verdade**; numeração é render; preço é resolvido, não gravado.
2. **Chave estável (`ati_id`)** viaja **exposta** (visível, protegida contra edição, fora da área imprimível) em tela, Excel e API — é a identidade do registro e o que faz o round-trip não quebrar; também é o vínculo com os geradores (AxysCAD/Revit).
3. **TRUNC(2) em cascata**, nunca ROUND, nunca só no fim — igual nas três portas.
4. **Nível define comportamento** (folha calcula, nó soma), não profundidade por coluna.
5. **BDI é seletor por linha** (qual BDI), não só percentual.
6. **Descrição/unid./custo são resolvidos** — o Excel os exibe mas não os carrega como verdade.
7. **Reimportar é idempotente**; conflito resolve item-a-item (last-write + evento), nunca arquivo-inteiro.
8. **Código desconhecido vira conciliação**, não erro fatal.
9. **Ordem esparsa** permite inserir no meio sem renumerar.
10. **Origem (Price/CPU/import) some** após o nascimento — a grade é a mesma para todos.
11. **Quantidade tem três origens** (digitada / memória livre / memória importada via JSON agnóstico) — independe do preço e da estrutura; `ati_have_memory_calc` discrimina.
12. **MVP é API unidirecional** (JWT/TLS 8h + refresh token); WebSocket adiado como evolução. Tempo real (quando existir) vale para tela e excel-web; .xlsx desktop é sempre round-trip discreto.
13. **VLOOKUP é só exibição** — puxa o unitário JÁ RESOLVIDO pela app; nunca recalcula preço. A app é a fonte da verdade.
14. **Convergência por TRUNC explícito** — toda fórmula de subtotal na plan usa `TRUNC(...;2)`, espelhando a cascata da app; assim Excel e app batem ao centavo.
15. **Sem VBA-guardião** — Tabela estruturada mantém a fórmula nas mexidas (nativo); comunicação via Office.js, ou VBA mínimo só para API/sync.
16. **Geração locale-safe** — número e fórmula sempre nativos via biblioteca (formato interno en-US); o Excel pt-BR exibe traduzido (`TRUNCAR`/`;`/vírgula) sozinho. Nunca fórmula como string; colunas de valor sempre numéricas.
17. **Colaboração por particionamento** — trava pessimista + escritor único por faixa; sem edição concorrente da mesma região (dispensa CRDT). Apoio deriva da principal, nasce regrada, só empurra.
18. **Lock por path** — ancorado num nó; trava o nó + toda a subárvore (`path LIKE âncora.'.%'`). Persistido como coluna na âncora (`ativo_itens`); escopo derivado por path. Sem TTL → exige liberação forçada manual contra lock órfão.
19. **"Atualizar" é merge em duas fases** — empurra local-novo antes de puxar web-novo; nunca overwrite. Regiões disjuntas tornam o merge trivial (reconciliação por `ati_id`).

---

## 11. Decisões em aberto (para a próxima rodada)

- **Template Excel:** colunas exatas, qual aba, e se aceita 1 ou N abas (orçamento + memória + cronograma no mesmo arquivo?). *(Proteção da coluna-chave já decidida — §2 / §7.1: visível, protegida, fora da área imprimível.)*
- **Rota da bancada:** rota própria (`/ativos/{id}/orcamento/bancada`) vs modal widescreen — definir antes do front.
- **Granularidade do recálculo:** re-resolve a árvore inteira a cada edição, ou só a subárvore afetada (memoização incremental)?
- **Conciliação de código desconhecido:** fluxo de tela (fila de pendências? marca a linha?).
- **WebSocket — infra (evolução):** quando entrar, qual backend de tempo real, reconexão/replay de deltas, granularidade do canal.
- **Excel-web:** definir se a edição em planilha web é cliente de tempo real de 1ª classe (quando houver socket) ou só upload/download como o desktop.
- **Schema do lock [a cravar]:** colunas na `ativo_itens` para o lock por âncora (`ati_lock_owner`, `ati_lock_em`?), e a query de escopo por path. Liberação forçada (quem pode, como registra em `ativo_eventos`).
- **Refresh token:** política de renovação do JWT 8h sem perder trabalho não-sincronizado.
- **Abertura de apoio:** validação de disjunção (recusar âncora sob lock vigente) e UX de "abrir apoio a partir deste nó".