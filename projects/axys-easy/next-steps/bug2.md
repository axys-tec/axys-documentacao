# bug2 — identidade de fonte, tenant com edição mínima, edição por item

> **Arquivo de trabalho.** Lista o que precisa ser feito e o critério de pronto. Some quando tudo
> estiver feito e testado; o que for regra durável vai para o contrato (passo 1), não fica aqui.
>
> Nasceu do bug 2 da revisão da bancada (25/10/2026): nos ativos 22, 23 e 38 (dev) a fonte própria
> não aparecia na Consulta e era recusada na entrada do item, porque `opa_fonte='PROPRIA'` (texto)
> divergia de `PRÓPRIA` (a fonte de verdade, apontada certo por `opa_tenant_edicao_id`). O mapeamento
> de 25-26/10 mostrou que o defeito não é pontual: a app decide pelo texto da fonte em ~150 lugares.

---

## 1. Decisões (Renan, 25-26/10/2026)

### 1.1 Catálogo global: o código é o identificador, e é imutável
- `catalogo.fontes.fte_codigo` (`SINAPI`, `CDHU`, `FDE`…) é **identificador**: único e imutável. Decidir
  por ele não é decidir por nome. O nome é `fte_nome`, só exibição.
- **Renomear não existe.** Se a fonte muda de nome (já aconteceu: CPOS → CDHU), cadastra-se uma fonte
  nova. A correlação antecessora → sucessora (para a série de preços atravessar) fica **desenhada no
  contrato** e é construída no primeiro caso real.
- A guarda é do **banco**, não da memória de alguém: gatilho que recusa `UPDATE` de `fte_codigo`.
- Comportamento específico de fonte (`if fonte == 'SINAPI'`) vira **atributo da fonte** no banco.

### 1.2 Tenant: rótulo de fonte + edição mínima do tenant
- O tenant **continua cadastrando fonte-base**, mas só como **perfumaria de nome**:
  `tenant_catalogo.fontes` vira lista de rótulos (ORSE, SBC, D&C…). A CPU/insumo guarda o **id** do
  rótulo; o rótulo **não decide nada**. Unicidade: `(tenant, rótulo_id, código)`. A "PRÓPRIA" padrão
  é a marcada `fte_bootstrap`. O **tipo** do rótulo (`fte_tipo` PRÓPRIA | EXTERNA) continua: é
  atributo e alimenta as flags dos entregáveis ("detalhar próprias / externas").
- **Edição mínima, do TENANT** (D5): `tenant_catalogo.edicoes` fica, só com o mês de referência; a
  descrição deriva do mês (como no catálogo). Uma série de meses para todo o catálogo próprio — não
  uma por rótulo. Sem L.S. Preço = `(insumo, edição)`, UF no insumo.
- **Custo da própria** (D6, D8): por edição, **sem encargos**, guardado como cache e recalculado para
  todas as composições **ATIVAS** quando uma edição é cadastrada ou um preço muda. Filho sem preço na
  edição → **sem custo** naquela edição, como no catálogo. A tela oferece **inativar** composição.
  Filho do catálogo global dentro da própria (D4): edição mais recente da fonte dele, UF da linha.
- **"O que o usuário criou é dele, para sempre."** Insumo/CPU própria criada em qualquer lugar vai
  para o catálogo do tenant. Some o "só neste orçamento" para própria no import (D11). Editar a
  receita de uma própria **dentro da bancada** continua valendo só para aquele orçamento (é o estado
  da bancada); guardar no catálogo é ação explícita.

### 1.3 Bancada: uma linha PRÓPRIA, favorita obrigatória, preço conforme a configuração
- **Uma linha PRÓPRIA** na configuração de fontes (D2), identificada pela **origem**: libera todas as
  composições próprias, de qualquer rótulo, e escolhe a **edição própria** (o mês). Sem UF, sem
  converter L.S. (a MO própria leva sempre a L.S. do ativo, na modalidade da favorita), não pode ser
  favorita (D3). Item próprio sem preço na edição declarada entra **sem preço**.
- **Favorita obrigatória**, do catálogo global (D1). **Data-base do orçamento** = mês da edição da
  favorita — derivada, não gravada.
- **Preço exibido dentro do ativo** (D7, Consulta e busca da bancada): o que o item vai ter **com a
  configuração do ativo** — conversão de L.S. ligada → L.S. do ativo; desligada → L.S. da própria
  fonte. Não converter é direito do usuário.
- **Cotação no lugar do dono do insumo:**
  - insumo **próprio**: só no catálogo do tenant (`pri_cotacoes`); a cotação da bancada grava na
    **edição própria declarada no orçamento** (D9) e traz o preço; edição que já tem preço → a tela
    pergunta se substitui. As cotações de insumo próprio já gravadas nos orçamentos **migram** para o
    catálogo do tenant;
  - insumo do **catálogo global**: fica no orçamento (`azp`), como hoje; guardar no catálogo próprio
    é ação explícita da página da cotação.
- **Ver cotações anteriores:** botão direito no item → lista das cotações daquele insumo/serviço em
  orçamentos anteriores do tenant → clicar expande, com **Copiar para o orçamento** e **Acessar**.
- **"PRÓPRIA · edição mm/aaaa"** é o que aparece no caderno, no rodapé dos exports e no MCP (D10).

### 1.4 Fonte derivada (SBC, ORSE, COMPESA) — preparar agora, construir depois
- Hoje o motor precifica **todos** os insumos de uma composição com **uma** edição, a da fonte da
  composição (`custo_composicao.carregar_ctx_fonte`); o item de composição não tem edição. Em dev há
  **zero** itens de outra fonte dentro de composições do catálogo.
- Fonte derivada (ex.: COMPESA 7/26 usando insumos SICRO 4/26) exige que a edição declare de quais
  edições de outras fontes consome.
- **Agora:** uma função única "qual edição vale para este item, dado de qual composição ele é",
  usada em todo lugar que hoje assume "a edição vem da config do ativo para a fonte do item"; e a
  tabela de dependências entre edições criada **vazia**. Hoje a função responde como sempre.
- **Depois** (quando a 1ª derivada entrar): parser da fonte e a pergunta da L.S. (a MO da SINAPI
  dentro da COMPESA leva a L.S. de quem?).

### 1.5 MÃO DE OBRA própria sem encargos
- Na bancada, a MO própria leva a **L.S. declarada na bancada** (a do ativo). Fora dela, o custo da
  CPU própria sai **sem encargos**, rotulado assim.
- **Endurecer o cadastro:** ao escolher o tipo MÃO DE OBRA, a tela diz, sem ambiguidade, que o preço
  é **SEM ENCARGOS** e que cadastrar com encargos faz a bancada **duplicar** os encargos.

---

## 2. O que fazer, em ordem

Cada passo termina com os vigias da seção 3 iguais à linha de base. Migration nasce no mesmo commit
do `schema.sql`, idempotente, e roda em dev (onde tudo já existe tem de ser no-op) antes do commit.

1. ✅ **Contrato** — `contracts/catalogo/identidade_fonte.md` (aprovado 26/10; revisto com D1-D12): 1.1 a 1.4 como regra durável (código =
   identificador imutável; nome = exibição; rótulo próprio não decide; preço próprio por mês;
   cotação conforme o dono do insumo; edição por item). Memória atualizada.
2. ✅ **Guarda do código global** (26/10) — gatilho `BEFORE UPDATE OF fte_codigo` em `catalogo.fontes`; tirar o
   campo da edição de fonte (`catalogo/service.py:254`). Migration.
3. ✅ **Bugs de id sem origem e de segurança** (26/10):
   - ✅ `captura_estado._ins_id_por_codigo` — insumo procurado em `tenant_catalogo` **sem filtro de
     tenant** (em dev só 1 tenant tem própria: nenhum vazamento gravado; em prod pode).
   - ✅ `routes.bancada_buscar_api` — a Base própria chegava `T1` e ia para coluna inteira: **erro 500**
     ao buscar com a linha fixada numa própria. A origem agora viaja no id.
   - ✅ `dados_proprios_import` estágio 3 — mapa por `_unac` consultado com chave acentuada.
   - ✅ `catalogo/composicoes_service.adicionar_item` — desempacotava 4 de 3: nenhum item entrava.
   - ➜ passo 6 (somem com a edição própria; corrigir agora seria escrever a regra antiga):
     `orcamento_service.py:1348` (`tenant_edicao_id` nunca existe), `orcamento_service.py:1420/1436`
     e `captura_estado.py:139` / `conversao_detalhe.py:382` (edição própria lida no catálogo global).
     **Achado:** os ids de edição COLIDEM — a edição própria 1 (L.S. 128,23%) tem o mesmo id da
     SINAPI 08-24, com L.S. publicada; MO própria declarada na bancada leva a L.S. da SINAPI 08-24.
     Em dev nenhum orçamento tem MO própria; em prod, medir no passo 6.
4. ✅ **Reforma do tenant e da bancada** (1.2, 1.3, 1.5) — 26/10, provada numa cópia do dev e depois
   no dev (migration 2026-10-26_tenant_edicao_minima rodada 2×; `recalcular_custos_proprios.py`; vigias
   iguais à linha de base; unittest só com as 2 falhas pré-existentes). **O bug 2 fechou** (ativos 22,
   23 e 38 aceitam a própria). Decisões tomadas no caminho (26/10, Renan):
   - preço próprio no **Dados Próprios** = o último registrado ATÉ o mês da edição em vista, com a
     data-base mostrada na linha; na **bancada** = o da edição declarada, ou — com a flag
     `opa_propria_ultimo_preco` ("FONTES PRÓPRIAS: … incluir insumo com último preço registrado") — o
     último até o mês dela. Nunca preço de mês posterior;
   - CPU própria com insumo sem preço entra **sem custo** na bancada (era total parcial);
   - entrada de item numa composição já capturada **não regrava** a árvore (`capturar(entrada=True)`):
     o item novo herda árvore e preço dos irmãos — o analítico do ativo 23 deixava de fechar;
   - orçamento só com a PRÓPRIA: sem favorita, data-base = mês da edição própria.
   Pendente deste passo: **Ver cotações anteriores** (aguarda a forma: botão direito no serviço × seção
   na tela do insumo).
   - **A. Schema e migração de dados.**
     - `tenant_catalogo.edicoes`: do tenant, não da fonte (`edi_fte_id` sai; unicidade
       `(tenant, mês)`); saem `edi_ls_horista_sd/cd` e `edi_codigo_versao` (descrição derivada do mês).
       Edições de rótulos diferentes no mesmo mês se fundem numa só; os preços se remapeiam (o insumo
       é de um rótulo só, então `(insumo, edição)` não colide). Preço de edição inativa também migra.
     - `tenant_catalogo.composicoes_custo`: um custo só, **sem encargos** (`cc_custo_sd/cd` → um).
     - `tenant_catalogo.composicoes_itens.ci_edi_id` sai (D4); `ci_uf` fica.
     - `ativo_orcamento_parametros`: coluna de **origem**; a linha PRÓPRIA é uma só por revisão,
       com `opa_tenant_edicao_id`; unicidade por origem, não pelo texto. Ativos com mais de uma linha
       própria (um rótulo por linha) se fundem numa.
     - Tabela de dependências entre edições do catálogo (1.4), **vazia**.
     - Antes de migrar: contar o que há em prod (script `prod_tenant.py`, leitura só — precisa de
       permissão) e as cotações de insumo próprio gravadas em orçamentos.
   - **B. Motor da bancada e captura** — o bug 2 fecha aqui.
     - `ctx["fontes"]` (`orcamento_service._params_por_fonte:94`) separa catálogo (por código, que é
       identificador) e própria (pela origem); `_fonte_de_cmp_tenant`, `fontes_utilizaveis`,
       `_fontes_do_ativo`, `fontes_tenant_do_ativo`, `_gravar_params`, `listar_fontes_edicoes`,
       `_criar_item`, `_validar_fontes_edi` — nenhum compara o texto do rótulo.
     - Favorita obrigatória no salvar da configuração (front e back); data-base derivada dela.
     - MO própria com a L.S. do ativo (`_arvore_tenant`, `_arvore_tenant_mes`, `_ctx_origem`,
       `preco_mo`, `orcamento_composicao_edit._ls_aplicada`, `conversao_detalhe`); some o
       `converter_ls` da própria. Isso fecha os três itens herdados do passo 3 (`tenant_edicao_id`
       inexistente; L.S. e rótulo de edição própria lidos no catálogo global — ids colidem).
     - A função única de edição por item (1.4) em `captura_estado`, `orcamento_composicao_edit`,
       `preco_mo`, `conversao_detalhe`, `routes.composicao_original:2380`, `orcamento_busca`,
       `orcamento_estrutura`.
     - Preço exibido dentro do ativo conforme a configuração (D7): `orcamento_busca`,
       `routes:1421-1434`, `routes:2763-2766`.
     - Front da configuração de fontes (`orca_fontes.html`, `easy_workspace.js`, `easy_ls_editor.js`:
       clonar L.S. só do catálogo).
   - **C. Dados Próprios.** Tela de edição mínima (só o mês); rótulo de fonte com o tipo e sem a
     contagem de edições; preço do insumo por edição; analítico sem a coluna EDIÇÃO nas linhas
     próprias e sem SD/CD; custo "sem encargos"; histórico de custo calculado por edição; **inativar**
     composição; recálculo das ATIVAS ao cadastrar edição ou mudar preço; aviso de MO SEM ENCARGOS;
     caderno "PRÓPRIA · edição mm/aaaa".
   - **D. Cotação.** Insumo próprio cotado na bancada grava no catálogo do tenant, na edição própria
     declarada (substituir com confirmação); migração das cotações já gravadas; relatório de
     cotações lendo de um lugar só; **Ver cotações anteriores** (botão direito).
   - **E. Import de arquivo.** PRÓPRIA sem seletor de edição na conferência (usa a edição do mês-ref);
     some o "só neste orçamento" para própria; fica para o catálogo global.
   - **F. MCP e textos.** `proprios_cadastro`, `anexos`, `proprios`, `proprios_receita`,
     `config_orcamento` (PRÓPRIA uma linha, favorita obrigatória), `instrucoes_ia.md`; testes
     `tests/mcp/*` que mockam edição.
5. **Atributo de fonte usado pela bancada** — o que hoje é `'SINAPI'` fixo no mensalista
   (`orcamento_service.py:404-433, 718, 748, 762, 839, 1518, 1608, 1627`; `preco_mo.py:487-514`;
   `conversao_detalhe.py:253, 328`; `easy_workspace.js:93, 130, 412-422`). Atributo proposto:
   `fte_publica_mensalista` (nome a confirmar). Migration.
6. *(absorvido pelo passo 4.)*
7. **Catálogo e o resto: comportamento por fonte vira atributo** — a lista de atributos levantada no
   mapa (perfil de arredondamento, preço publicado com BDI, MDO como composição, fonte de referência
   das vinculações, fichas por agrupamento, parser, ordem na newsletter etc.). Antes, resolver com o
   Renan a divergência da FDE: o perfil do oráculo diz conta CHEIA no unitário, a conta de MO × L.S.
   da listagem de insumos (`insumos_service.py:171/248/887/894`) usa TRUNC.
   Usar os atributos que já existem e são ignorados: `fte_public` (`descritivo_request.py:350`) e
   `fte_tem_catalogo_insumos` (`descritivo_request.py:359`).
   Storage montado com o código da fonte: **fica** — o código é imutável (1.1).
8. **Vigia novo** em `z_scripts_apoio/sanidade/`: acusa comparação com literal de fonte (`== 'SINAPI'`
   etc.) fora das exceções (parsers do import, seeds), e decisão pelo rótulo de fonte própria.
   Ajustar os vigias que dependem de nome (`fluxo_orcamento`, `fluxo_bancada`, `acoes_bancada`) e o
   que pula em silêncio (`catalogo_custos.py:81-93`).

---

## 3. Prova (a cada passo e no fim)

Linha de base tirada em 25/10/2026, antes de qualquer mudança:

| vigia | linha de base |
|---|---|
| totais numéricos (retrato próprio no scratchpad, 40 ativos) | idêntico |
| `fluxo_bancada` | 24 ok · 0 falha |
| `acoes_bancada` | 23 ok · 3 falhas (pré-existentes) |
| `custo_vs_publicado` | 51 pontos (pré-existentes) |
| `documento_pdf` | 44 de 51 (pré-existentes) |
| `analitico_bancada` | 5 ativos que não fecham (pré-existentes) |

Além disso:
- os ativos 22, 23 e 38 aceitam a própria na Consulta e na entrada do item;
- teste de renome: renomear uma fonte em dev numa transação desfeita — o gatilho recusa a global; a
  bancada não muda com o rótulo próprio renomeado;
- migration rodada duas vezes em dev: a segunda é no-op.

## 4. Pronto quando

Os passos 1 a 8 feitos (4 em seis estágios — ✅ menos "ver cotações anteriores"), a seção 3 verde, migrations aplicadas em dev, commit e push. Então este
arquivo é apagado, e o que sobrou de futuro vai para `pendencias.md`:
- fonte derivada de verdade (parser + L.S. da MO de outra fonte) e as telas de composições, cliente e
  interna, mostrando a edição de cada item quando a fonte é multifonte;
- correlação de fonte sucessora (no primeiro renome real);
- no detalhe da composição na bancada: "ver últimos preços" do item e trocar (ex.: SINAPI 08/26 sem
  preço, 05/26 com — a janela de 6 meses do TCU);
- os orçamentos de homolog com CPU própria capturada pela regra antiga: ao recalcular, mudam (em dev,
  Σ 76,0 mi → 60,5 mi se todos fossem recalculados; a maior parte é preço próprio registrado DEPOIS do
  mês da edição). Ficam congelados até alguém recalcular.
