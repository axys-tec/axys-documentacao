# bug2 — identidade de fonte, tenant sem fontes-base, edição por item

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

### 1.2 Tenant: sem fonte-base e sem edição
- O tenant não cadastra mais fonte-base nem edição: a maioria não teria estrutura para manter.
- O tenant **continua cadastrando fonte-base**, mas só como **perfumaria de nome**:
  `tenant_catalogo.fontes` vira uma lista de rótulos (granularidade: ORSE, SBC, D&C…), sem edição e
  sem comportamento. A CPU/insumo próprio guarda o **id** do rótulo; o rótulo **não decide nada**. Unicidade
  da própria: `(tenant, rótulo_id, código)`. A "PRÓPRIA" padrão é a marcada `fte_bootstrap`.
- Na bancada o usuário seleciona **PRÓPRIA** (rótulo da origem), sem escolher edição.
- O preço próprio é datado por **mês/ano** (`mm/aaaa`), que funciona como a "edição" do preço = a
  data-base dele. Não é ERP: um preço por insumo por mês (ver 1.5-B sobre UF).
- A bancada pega o preço **mais recente até a data-base do orçamento**, e o congela no estado ao
  capturar (como já faz).
- **"O que o usuário criou é dele, para sempre."** Não existe mais "entrou no orçamento mas não no
  catálogo": insumo/CPU própria criada em qualquer lugar (bancada, import, cadastro) vai para o
  catálogo do tenant.

### 1.3 Cotação: um lugar só, conforme de quem é o insumo
- **Insumo próprio:** o preço (inclusive a cotação — `pri_cotacoes` já guarda) vive **só** no catálogo
  do tenant. A cotação feita na bancada (função irmã) passa a **escrever no catálogo do tenant**, no
  mês, e só traz o preço para a bancada.
- **Insumo do catálogo global** (SINAPI etc.): a bancada é o armazenamento da própria bancada. A
  cotação e o ajuste de preço ficam **no orçamento** (como hoje, `azp`). O usuário pode guardar no
  catálogo dele por ação explícita (como já existe).
- **Ver cotações anteriores** (entra neste arquivo — é barato): na bancada, botão direito no item →
  "Ver cotações anteriores" → lista das cotações daquele insumo/serviço em orçamentos anteriores do
  tenant → clicar expande o formulário com duas ações: **Copiar para o orçamento** (traz a anterior
  para esta bancada) e **Acessar** (abre a página da cotação, que já existe). Guardar no catálogo
  próprio continua sendo ação da página da cotação da bancada.

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

### 1.5 Os dois pontos que dependiam da troca de edição por mês
- **A. L.S. da MO própria — DECIDIDO.** Na bancada, a MO própria leva a **L.S. declarada na
  bancada** (a do ativo); a da edição do tenant (`edi_ls_horista_sd/cd`) deixa de existir. Fora da
  bancada (Dados Próprios), o custo da CPU própria sai **sem encargos**, rotulado assim.
  **Endurecer o cadastro:** ao escolher o tipo MÃO DE OBRA, a tela diz, sem ambiguidade, que o preço
  é **SEM ENCARGOS** e que cadastrar com encargos faz a bancada **duplicar** os encargos.
- **B. UF no preço próprio — RESOLVIDO pelo contrato existente.** A UF vive no insumo (`ins_uf`,
  TENANT_CATALOGO_PROPOSTA §8.5); o mês é adotado no lugar da edição. Preço = `(insumo, mês)`.

---

## 2. O que fazer, em ordem

Cada passo termina com os vigias da seção 3 iguais à linha de base. Migration nasce no mesmo commit
do `schema.sql`, idempotente, e roda em dev (onde tudo já existe tem de ser no-op) antes do commit.

1. **Contrato** — `contracts/catalogo/identidade_fonte.md` (escrito 26/10, aguarda aprovação): 1.1 a 1.4 como regra durável (código =
   identificador imutável; nome = exibição; rótulo próprio não decide; preço próprio por mês;
   cotação conforme o dono do insumo; edição por item). Aprovação do Renan antes do código.
   Atualizar a memória: `feedback_id_nao_nome` (código global é identificador) e
   `feedback_espelhar_estrutura_catalogo` (superada para fonte/edição do tenant).
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
4. **Bancada: a chave do contexto** — `ctx["fontes"]` (`orcamento_service._params_por_fonte:94`) deixa
   de misturar catálogo e próprias: catálogo por código (identificador), própria pela origem.
   - `opa`: coluna de origem; a linha da própria sem edição; unicidade `(revisão, origem, fonte)`.
   - `_fonte_de_cmp` / `_fonte_de_cmp_tenant`, `fontes_utilizaveis`, `_fontes_do_ativo`,
     `fontes_tenant_do_ativo`, `_gravar_params` (hoje escolhe catálogo×tenant **pelo nome**),
     `listar_fontes_edicoes` (hoje some com a própria cujo código colide), `_criar_item`.
   - A função única de edição por item (1.4) em: `captura_estado` (`_ctx_fonte`, `_insumo`, `_sub`,
     `_do_historico`), `orcamento_composicao_edit` (`_ls_aplicada`, `preco_de_linha`,
     `_linhas_para_catalogo`, `_criar_propria`), `preco_mo`, `conversao_detalhe`,
     `routes.composicao_original:2380`, `orcamento_busca`, `orcamento_estrutura`.
   - Tabela de dependências entre edições, vazia. Migration.
   - Front (`easy_workspace.js`, `easy_bancada.js`, `easy_ls_editor.js`) e MCP (`config_orcamento.py`)
     mandando origem; nome só como entrada traduzida uma vez.
   - **O bug 2 fecha aqui.**
5. **Atributo de fonte usado pela bancada** — o que hoje é `'SINAPI'` fixo no mensalista
   (`orcamento_service.py:404-433, 718, 748, 762, 839, 1518, 1608, 1627`; `preco_mo.py:487-514`;
   `conversao_detalhe.py:253, 328`; `easy_workspace.js:93, 130, 412-422`). Atributo proposto:
   `fte_publica_mensalista` (nome a confirmar). Migration.
6. **Tenant sem fontes-base** (1.2, 1.3, 1.5):
   - preço próprio por mês (UF no insumo); fim de `tenant_catalogo.edicoes`, de
     `composicoes_custo` (custo da própria passa a ser calculado pelo motor) e da escolha de edição
     própria na config do ativo;
   - cotação de insumo próprio na bancada escreve no catálogo do tenant; o relatório de cotações
     (`cotacoes_pdf`) lê de um lugar só por insumo;
   - import de arquivo: some o "só neste orçamento" para insumo/CPU própria;
   - "Ver cotações anteriores" na bancada (1.3);
   - aviso de SEM ENCARGOS no cadastro de insumo de MÃO DE OBRA (1.5-A);
   - migração dos dados: recombinar o que existir (fontes → rótulos; edições → mês; preço da edição
     → preço do mês). Contar o que há em prod antes (script pronto, leitura só).
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

Os passos 1 a 8 feitos, a seção 3 verde, migrations aplicadas em dev, commit e push. Então este
arquivo é apagado, e o que sobrou de futuro ("ver cotações anteriores", fonte derivada de verdade)
vai para `pendencias.md`.
