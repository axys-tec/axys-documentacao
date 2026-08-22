# Generalidades

O projeto EasyMobile tem o objetivo principal disseminar as boas práticas orçamentárias, bem como capacitar engenheiros, arquitetos e demais profissionais da cadeia produtiva da construção, sobretudo aqueles que trabalham com obras públicas.

O objetivo secundário é divulgar e posicionar a Axys como uma empresa produtora de conhecimento e suporte ao profissional, desencadeando confiança irrefutável.

O Easy Mobile é a **Base de Conhecimento Axys** para construção civil, engenharia de custos e obras públicas. Não é versão gratuita do Easy Web, não é editor de orçamento e não é ferramenta de produção. Sua função é **servir**.

> **Easy Mobile consulta, informa e dissemina conhecimento. Easy Web produz, analisa, orça e gere trabalho.**

Estratégia: utilidade real → recorrência → confiança → audiência qualificada → eventual interesse nas soluções profissionais. Receita direta não é objetivo primário.

## Objetivos

- ampliar a presença da Axys entre engenheiros, arquitetos, orçamentistas, fiscais, gestores e construtores;
- disponibilizar informação técnica gratuita e recorrente;
- transformar dados que a Axys já estrutura em informação de alto valor;
- criar canal próprio de relacionamento;
- formar audiência qualificada;
- construir base histórica de inteligência de custos;
- medir uso, retenção e interesses com privacidade e consentimento;
- conectar dados, conteúdo, canal e soluções Axys.

**Métricas centrais:** downloads, MAU/DAU, retenção, recorrência, consultas realizadas, leitura de newsletters, consumo de conteúdo e transição voluntária para as soluções.

Há uma qualidade econômica importante nesse desenho: **o custo marginal de manter o conteúdo é baixo**, porque boa parte nasce de dados que a Axys já precisa processar de qualquer maneira. A edição entra → o pipeline analisa → gera indicadores → vira conteúdo editorial → revisão → publicação. O mesmo trabalho que mantém o produto atualizado alimenta a Base de Conhecimento.

---

# Premissa Básica

O EasyMobile não é e nem nunca será cobrado de qualquer empresa e/ou profissional que desejar acessá-lo. Não é freemium, é free!

## Posicionamento

Não é *"use grátis até precisar pagar"*. É:

> **"Use grátis porque é útil; quando precisar produzir, analisar ou gerir, conheça as soluções Axys."**

Na prática isso proíbe paywall artificial, banner invasivo e excesso comercial. O app tem de ser valioso **inclusive para quem nunca vai comprar nada** — é essa gratuidade sem contrapartida que constrói a confiança que o objetivo secundário persegue.

---

# Easy, prático, ágil e sem fricção

Essa é a **ADR 0** do Easy Mobile. O aplicativo deve ser ágil e objetivo desde o primeiro contato, inclusive durante o cadastro e a autenticação.

A tela de cadastro solicitará apenas:

- **Nome completo**
- **Telefone**
- **E-mail**
- **Senha**
- **Confirmação da senha**

Ao avançar, será realizada a validação da identidade por **MFA**, utilizando e-mail ou notificação via WhatsApp, a ser decidido pelo User. Concluída a validação, o cadastro estará ativo e o usuário terá acesso imediato ao aplicativo.

Informações complementares que possam agregar valor à experiência, como **UF e profissão/área de atuação**, não farão parte do cadastro inicial. Esses dados poderão ser solicitados posteriormente, de forma contextual e não impeditiva, por meio da funcionalidade **Complete seu perfil**.

Depois da autenticação, toda a experiência deve seguir a mesma premissa: **simples, rápida, intuitiva e objetiva.**

**Sempre assim.**

---

# O Core

O CORE/Núcleo principal que ditará as telas do app/funcionalidades (módulos), é composto de:

1. CENTRAL DE CUSTOS: pesquisa, detalhamento, histórico e simulação de insumos e composições
2. BASE DE CONHECIMENTO AXYS: dados, aplicativos, planilhas que visam capacitar o usuário
3. SOLUÇÕES AXYS: detalhamento das soluções do ecossistema Axys
4. SOBRE A AXYS: apresentação da empresa (Por que Axys / Missão & Valores)
5. ROADMAP: apresentação da expectativa de disponibilidade das soluções
6. CANAL AXYS: acesso aos materiais publicados no YouTube — **fora da V0**, não haverá vídeo publicado
7. MINHA CONTA: governança individual, atualização do nome, rotação de senhas, etc.

**Vocabulário:** os nomes acima são os canônicos e valem em todo lugar — menu, telas, contrato de API e analytics. Não usar sinônimos ("Pesquisa de Preços", "Central de Perguntas", "Central do Usuário") em nenhum outro documento.

**Dúvidas & Perguntas deixou de ser módulo** (22/08/2026): virou **pilar da Base de Conhecimento**, junto de Terminologia, Casos práticos e Acórdãos. O usuário não distingue "dúvida que eu leio" de "dúvida que eu envio" a ponto de justificar duas entradas no menu de um app cujo lema é abrir e resolver na hora. Enviar a própria pergunta continua previsto, como funcionalidade V1 dentro da Base de Conhecimento.

Essa estrutura, colocada em tela/menu, ficaria organizado conforme abaixo.

EASY MOBILE

HOME
│
├── CENTRAL DE CUSTOS
│
├── BASE DE CONHECIMENTO AXYS
│      ├── Terminologia
│      ├── Dúvidas rápidas
│      ├── Casos práticos
│      ├── Acórdãos e jurisprudência
│      ├── Easy Newsletter
│      ├── Artigos & Matérias
│      └── Downloads & Utilitários
│
└── MAIS
     ├── Soluções Axys
     ├── Roadmap
     ├── Sobre a Axys
     └── Minha conta

## HOME

A HOME é a primeira tela depois da autenticação e a única que o usuário vê todos os dias. Ela existe para cumprir a **ADR 0** no caso de uso principal: *abrir o app e tirar a dúvida na hora*. Por isso a busca não fica escondida atrás de um menu — ela **é** a HOME.

Composição, de cima para baixo:

1. **Logo Axys** no topo. Sem texto de boas-vindas e sem explicação do que o app faz.

2. **Campo de busca ativo**, em destaque. O usuário digita direto daqui, sem passar pela Central de Custos. Ao submeter, cai na listagem de resultados da Central de Custos com os filtros no default (última edição por fonte, SP, Todos, sem desoneração). Quem quiser refinar, refina lá.

3. **Faixa de edições vigentes**, logo abaixo da busca, em formatação discreta: `SINAPI 08/2026 · CDHU 194 · FDE 09/2026`. Serve de contexto para a busca e, de quebra, responde sem custo uma pergunta que o orçamentista faz toda semana. Clicável — leva ao seletor de edição.

4. **Consultados recentemente** (máx. 5 itens). Persistido no próprio aparelho, sem servidor e sem escrita. A seção não é exibida quando estiver vazia — usuário novo não vê caixa vazia.

5. **Últimas publicações** (3 itens), no mesmo formato da Base de Conhecimento. É o que traz o usuário de volta nos dias em que ele não tem dúvida nenhuma para tirar.

6. **Atalho para a Base de Conhecimento**, em uma linha.

**Não entra na HOME:** carrossel de soluções, banner comercial, roadmap ou qualquer chamada de venda. Essa camada mora em MAIS e é acessada por quem quiser — nunca empurrada a quem veio trabalhar.

Recorte: **V0**.

## 1. CENTRAL DE CUSTOS

Essa seção será a responsável por exibir informações de composições e insumos ao usuário. É uma pesquisa rápida / guia de bolso. 

Situação/melhor tipo de uso: fiscal de obra com dúvida da composição e o que ela remunera. Acessa app, tira dúvida, na hora.

Demais usos: curiosidades/pesquisas em geral.

Nota: Aqui nenhum dado novo. Vamos consumir do que temos no banco.

### Funcionalidade 1: Pesquisa básica — **V0**

a) User vai selecionar:
 - *Edição*: Se user quiser alguma edição em específico, pega de catalogo.edicoes. Default, ultima edicao por fonte. Se filtrar fonte, a edicao obedece o filtro (para caso de retroagir análise).
 - UF: {uf_lista}, default SP.
 - *Tipo*: insumo/composição, default Todos.
 - Regime: com desoneração, sem desoneração, default sem desoneração.
 - *Termo*: termo de busca.

b) Após a seleção, o motor de busca fará a busca elástica no banco, exibindo a lista de itens prováveis. Mas tem um ponto importante aqui. A busca elástica atual está isolada em insumos/composições. A partir do momento que entrar em comunidade, vai ficar difícil encontrar, então, é imperativo que, mesmo com o ranqueamento elástico, possamos fazer a busca elástica e, dentro dos alvos, fazer um refino mais próximo duma busca estática, para efeitos do ranqueamento. Isso é apenas uma ressalva importante.

c) App vai exibir a lista de insumos e/ou serviços, que serão clicáveis. Ao clicar, abre nova tela de detalhamento. A listagem vai exibir o nome do insumo/composição, na seguinte estrutura: 
 - linha principal: Descrição | R$ /un
 - linha secundária: Fonte | Código | %LS/BDI/regime
 - Exemplo: 
 2 INTERRUPTORES 1 TECLA BIPOLAR EM CAIXA 4X4 - ELETROD PVC Ø 25MM FLEXIVEL NBR 15465 | R$ 276,19/un
 FDE | 09.08.038 <<esse texto numa formatação menos impactante>>

Nota: a tela tem rolagem vertical pela listagem e, ao cair na tela de detalhamento, deve haver função retornar.

### Funcionalidade 2: Detalhamento & Histórico — **V0**, com ressalvas de recorte

A ideia desta tela é mostrar o histórico do insumo/composição, da série histórica disponível.

**Ordem em tela.** O bloco da composição analítica (descrito por último, mais abaixo) é o que responde *"o que essa composição remunera"* — ou seja, é a resposta ao caso de uso principal do app. Ele deve aparecer **antes** do gráfico, não depois. O gráfico é diferenciação; a analítica é a razão de o fiscal ter aberto o app.

O gráfico vai representar o gráfico atual que roda em http://localhost:8788/consulta-composicoes, no modal Histórico de Custos. No entanto, os índices que será exibido serão apenas alguns registrados pela app e sem possibilidade de ajuste, a saber:
 - IGP-M
 - INCC-M
 - INPC
 - IPCA
 - IPOP-IGE (se a UF for SP, senão ele não entra)
 - O gráfico será análogo ao exibido no modal citado.

Na sequencia, além do gráfico, será exibido uma tabela Histórico de Custos, igual no referido modal, bem como Histórico de Registros, do mesmo modal, que lista as alterações registrada para a composição e/ou insumo ao longo do tempo.

E por fim, depois da tabela, caso o item seja uma composição, será exibido a composição do item, tal como na rota http://localhost:8788/consulta-composicoes/detalhar/15666. Os insumos da listagem são hiperlinkados para, caso sejam clicados, abram o detalhamento deles, com opção voltar, para a tela anterior (detalhamento/histórico).

No topo, juntamente com a descrição do item nessa tela de histórico, haverá 3 botões:
 - Ver Caderno (**V0**): abre caderno técnico do serviço/insumo, se houver. Não havendo, exibe mensagem: Não existe caderno técnico para esse item/serviço. 
 - Simulador Preço (**V1**): Nova tela/funcionalidade
 - Gerar PDF (**V1**): Gera um PDf de 2+ folhas sendo, a primeira folha relativo ao detalhamento do item (Composição, se composição, acompanhada do histórico), seguido do gráfico de variação de preço e uma análise singela das variações. No easy web fazemos um request de IA para acertar esse texto. Na versão mobile, será feito via script. Então, cuidadosamente precisamos ser objetivos e muito assertivos nesse texto.

### Funcionalidade 3: Simulador — **V1**

 > **O que já existe.** O Simulador **não constrói cálculo novo** — ele expõe ao usuário a conversão que já roda na bancada de orçamento. O motor único aceita as alavancas como parâmetro:
 >
 > ```python
 > custo_composicao(cur, cmp_id, edi, uf="SP", mod="SD", ls_h=None, ls_m=None, subst=None)
 > ```
 >
 > - **%LS e regime horista→mensalista** → `ls_h` / `ls_m` (a bancada já injeta a LS do ativo por aí);
 > - **Fonte-destino** → `subst`, que já rotaciona MO/CPU por composição de outra fonte;
 > - **%BDI** → aritmética sobre o total, fora do motor;
 > - **Preço de insumo alterado** → único que ainda não é parâmetro; os preços vivem em `ctx.precos[(ins_id, uf)]` e injetar valor ali é extensão pequena;
 > - **PDF em cascata do H>MÊS** → `backend/modules/catalogo/conversao_pdf.py`, já implementado.
 >
 > **O que sobra é tela**, não motor. O recorte V1 é escolha de escopo do primeiro lançamento — não limitação técnica.

 Aqui, abrirá uma tela de simulação de ações. É uma funcionalidade de estudo rápido/dinâmico que apenas técnicos conseguirão entender/operar.

 O objetivo é o user alterar %LS, %BDI, Regime (horista > mensalista) e/ou preço de insumos, para avaliar a diferença de valor da simulação.

 Inputs do user:
  - % LS: default, % edição
  - % BDI: default, 0%.
  - Regime: listbox (horista > mensalista), default locked (destravado apenas se a fonte for SINAPI)
  - Fonte-destino: User tem que destravar e vai aparecer a lista de fontes (N-1, onde N = universo de fontes da app e 1 é a fonte do item em exibição)
  - edição de preços de insumo: clica no insumo, abre tela de digitação do preço de interesse, pressiona ok, insumo entra na CPU com preço ajustado.
  Nota: o simulador só pode ser acessado para composições. Insumos não faz sentido. todas as rotações (itens que modificam a simulação) devem ter flag para destravar. O default é travado.
  Ressalva: o simulador não faz qualquer escrita em banco/R2. É consulta pura/download do PDF.
  

Após a rotação do preço, abre a função Gerar PDF, onde apresenta um detalhamento da simulação, com texto destacado.

Aqui, vamos gerar um relatório PDF que deve descer em cascata, para caso haja diferença na LS simulada. Deve abrir o relatório pdf do modal H>MÊS (http://localhost:8788/consulta-composicoes), 


### API do Easy

O Easy Mobile **não fala com o banco**. Ele fala com a **Easy Mobile API** — serviço próprio, no mesmo repositório e no mesmo blueprint (3º `service` do `render.yaml`), entrypoint `backend/app_mobile_api.py`, pool de conexões próprio e credencial de banco **somente leitura**.

Três princípios governam este módulo:

1. **O banco entrega ingrediente; o serviço compõe.** O custo de uma composição não é uma coluna que se lê e devolve: o total oficial sai de `custo_composicao()`, que é Python (perfil de arredondamento por fonte — SINAPI trunca, CDHU arredonda, FDE precisão cheia). Nenhum objeto de banco reproduz isso. O SQL entrega o dado cru; o serviço FastAPI monta a resposta e decide o que entra no JSON.
2. **Um endpoint por intenção de tela, não por tabela.** O app pede "o detalhamento desta composição", não faz três chamadas e junta no cliente.
3. **Leitura pura.** A Central de Custos inteira — inclusive o Simulador da V1 — não escreve uma linha no banco do Easy. A credencial usada nem tem o verbo.

---

#### 1. O que já existe e será reaproveitado

Nada aqui precisa ser inventado. O Easy Web já resolve todas estas telas; a API mobile reusa as mesmas funções de serviço.

| Tela / ação | Função que já resolve | Tabelas envolvidas |
|---|---|---|
| Filtros da busca (fontes, UFs, edições) | `composicoes_service.get_filtros()` · `_edicoes_filtro()` | `fontes`, `edicoes`, `composicoes_custo`, `insumos_preco` |
| Busca elástica (ranqueada) | `core.search.SearchService.search_catalog()` → `PostgresSearchAdapter` | `search_document` (tsvector + trigram) |
| Reidratação dos resultados | `composicoes_service.get_composicoes(ids=…)` · `insumos_service.get_insumos(ids=…)` | `composicoes`, `composicoes_custo`, `insumos`, `insumos_preco`, `fontes`, grupos/subgrupos |
| Detalhamento analítico precificado | `composicoes_service.get_cpu_precificada()` | `composicoes_itens`, `insumos_preco`, `edicoes_leis_sociais`, `insumos_familia` + motor `custo_composicao()` |
| Série histórica de custo + eventos | `composicoes_service.get_historico_custos()` | `composicoes_custo`, `indices_historico`, `composicoes_historico` |
| Série histórica de preço (insumo) | `insumos_service.get_historico_precos()` | `insumos_preco`, `indices_historico`, `insumos_historico` |
| Custo em todas as UFs | `composicoes_service.get_cpu_custos_por_uf()` | `composicoes_custo` |
| Ver Caderno | `cmp_external_path` → `storage_paths.resolver_versao()/doc_url()` | — (path de bucket **privado**, servido por rota gated) |

**Nota de arquitetura sobre o Caderno — atenção, aqui há uma dependência a mais.** O caderno técnico é **privado**. `cmp_external_path` resolve um *path* de bucket privado. **Não existe URL pública para o caderno**: o Markdown pequeno é lido pela API autenticada e entregue na própria resposta, funcionando igualmente no Flutter Web, iOS e Android sem depender de CORS do bucket. Isso difere do conteúdo estático dos módulos 3 e 4.

Consequência prática: a Easy Mobile API precisa de uma rota própria e de uma **segunda credencial** — leitura do bucket privado do R2 — além da credencial de banco. O isolamento do §4 cobre o Postgres; **não cobre o storage**. Para o CTC, a rota devolve o Markdown pequeno na resposta autenticada; arquivos privados maiores continuam por URL assinada — ver §5.5.

**Atenção — dependência escondida da V0:** como o detalhamento analítico chama o motor de custo, o acesso a `edicoes_leis_sociais`, `insumos_familia` e `insumos_tipo` é necessário **já na V0**, mesmo o Simulador sendo V1. São ingredientes do motor, não do Simulador.

**Atenção — formato dos valores:** as funções atuais devolvem valor **formatado para HTML** (`_fmt_money` → `"R$ 276,19"`, string). API JSON deve trafegar **número**, e a formatação é responsabilidade do Flutter (locale do aparelho). Portanto a camada mobile precisa de acesso ao valor cru — seja por parâmetro `raw=True` nas funções existentes, seja por consulta própria. **Decisão a tomar antes de codar.**

---

#### 2. Endpoints da V0

Prefixo `/v0`. Todos `GET`. Todos exigem token do Hub com `aud=easy-mobile`.

##### `GET /v0/catalogo/filtros`
Bootstrap da tela. Uma chamada, cacheável na borda por horas.

```json
{
  "fontes": [ { "id": 1, "codigo": "SINAPI", "nome": "Sistema Nacional de Pesquisa de Custos e Índices" } ],
  "ufs": ["AC", "AL", "…", "SP", "TO"],
  "edicoes": [
    { "id": 100612, "fonte": "SINAPI", "versao": "08/2026", "mes_ref": "2026-08", "vigente": true }
  ],
  "modalidades": [
    { "codigo": "SD", "rotulo": "Sem desoneração" },
    { "codigo": "CD", "rotulo": "Com desoneração" }
  ],
  "defaults": { "uf": "SP", "modalidade": "SD", "tipo": "TODOS" }
}
```

##### `GET /v0/busca`
`q` · `tipo` (`INSUMO|COMPOSICAO|TODOS`) · `fonte` · `edicao` · `uf` · `modalidade` · `pagina`

```json
{
  "query": "interruptor bipolar",
  "pagina": 1,
  "por_pagina": 25,
  "total": 137,
  "contexto": { "uf": "SP", "modalidade": "SD", "edicoes": { "SINAPI": 100612, "FDE": 100640 } },
  "itens": [
    {
      "tipo": "COMPOSICAO",
      "id": 15666,
      "fonte": "FDE",
      "codigo": "09.08.038",
      "descricao": "2 INTERRUPTORES 1 TECLA BIPOLAR EM CAIXA 4X4 - ELETROD PVC Ø 25MM FLEXIVEL NBR 15465",
      "unidade": "un",
      "custo": 276.19,
      "sem_custo": false,
      "edicao": { "id": 100640, "versao": "09/2026" },
      "match": "descricao"
    }
  ]
}
```

`match` vem do adapter (`codigo` · `descricao` · `similaridade`) e é o gancho para o refino de ranqueamento previsto no item (b) — o app pode agrupar "achou pelo código" acima de "achou por semelhança" sem que o servidor mude de motor.

##### `GET /v0/composicoes/{id}`
Detalhamento analítico precificado. `edicao` · `uf` · `modalidade` opcionais.

```json
{
  "composicao": {
    "id": 15666, "fonte": "FDE", "codigo": "09.08.038",
    "descricao": "2 INTERRUPTORES 1 TECLA BIPOLAR…", "unidade": "un"
  },
  "contexto": { "edicao": { "id": 100640, "versao": "09/2026" }, "uf": "SP", "modalidade": "SD" },
  "edicoes_disponiveis": [ { "id": 100640, "label": "09/2026" } ],
  "modalidades_disponiveis": ["SD", "SE"],
  "total": 276.19,
  "incompleto": false,
  "itens": [
    {
      "tipo": "INSUMO", "id": 88309, "codigo": "88309",
      "descricao": "ELETRICISTA COM ENCARGOS COMPLEMENTARES",
      "unidade": "H", "coef": 0.35, "valor_unitario": 25.40, "total": 8.89
    }
  ],
  "caderno": { "disponivel": true, "url": "/v0/documentos/easy/fontes/sinapi/…" }
}
```

`modalidades_disponiveis` traz só o que está **registrado** para aquela fonte/edição (mais `SE`, sempre calculável) — não oferece regime que a fonte não publica, para não sugerir recálculo que não acontece.

##### `GET /v0/composicoes/{id}/historico`
`uf` · `inicio` · `fim` (AAAA-MM).

```json
{
  "composicao": { "id": 15666, "fonte": "FDE", "codigo": "09.08.038", "descricao": "…", "unidade": "un" },
  "uf": "SP",
  "periodo": { "inicio": "2024-01", "fim": "2026-08", "min": "2019-07", "max": "2026-08" },
  "labels": ["jan/24", "fev/24", "…"],
  "series": { "SD": [251.10, 253.44], "CD": [null, null] },
  "indices": { "IPCA": [], "INCC-M": [], "IGP-M": [], "INPC": [], "IPOP-IGE": [] },
  "indices_meta": [ { "codigo": "IPCA", "nome": "Índice de Preços ao Consumidor Amplo", "fonte": "IBGE" } ],
  "custos": [ { "mes": "ago/26", "SD": 276.19, "CD": null } ],
  "eventos": [ { "edicao": "08/2026", "tipo": "ALTERACAO_COEFICIENTE", "ocorrencia": "…" } ]
}
```

**Regra de servidor:** a restrição aos cinco índices (IGP-M, INCC-M, INPC, IPCA e IPOP-IGE) e a supressão do IPOP-IGE quando `uf ≠ SP` são aplicadas **na API**, não no app. Assim a regra é uma só e não depende de versão de binário instalado.

##### `GET /v0/insumos/{id}` e `GET /v0/insumos/{id}/historico`
Espelham as duas rotas acima, sem o bloco `itens` (insumo não tem analítica) e com `precos_por_modalidade` no lugar de `total`.

##### `GET /v0/composicoes/{id}/ufs`
Custo do item em todas as UFs registradas — tabela-resumo. Endpoint barato e altamente cacheável.

---

#### 3. Acesso ao banco — leitura direta, sem camada de views

**Decisão: não haverá schema de views para o mobile.** A leitura é direta nas tabelas de `catalogo`, com a proteção vindo inteiramente da role. Registrado aqui porque a alternativa (uma camada `public_api.*` / `mobile.*`) foi considerada e descartada — e o motivo importa para quem ler depois:

1. **A view protegeria um contrato que não existe.** O argumento clássico a favor dela é que binário publicado em loja não tem rollback rápido, então o que ele consome precisa ser estável. Só que **o app não consome o banco — consome a API**. Quem absorve mudança de schema é a camada FastAPI, e ela mora no mesmo repositório, sobe no mesmo blueprint e muda no mesmo commit que o `schema.sql`. Não há defasagem de versão entre serviço e schema para a view amortecer.

2. **A view brigaria com o reaproveitamento.** Todas as funções listadas no §1 — `get_cpu_precificada`, `get_historico_custos`, `get_composicoes`, `SearchService` — têm `catalogo.*` escrito no SQL. Uma role que só enxergasse `mobile.*` obrigaria a forkar cada uma delas, duplicando exatamente a lógica que se pretendia reusar e criando dois caminhos de SQL para manter.

3. **O recorte já está no código.** `_edicoes_filtro()` já restringe a `PUBLICADA`/`EM_REVISAO`; `get_composicoes()` já filtra `cmp_ativa`; `get_cpu_precificada()` já limita as modalidades ao que a fonte publica. Reescrever essas regras em view seria criar uma segunda fonte de verdade para regra que já existe e já é testada em produção pelo Easy Web.

**Onde passa a viver cada recorte:**

| Recorte | Onde vive | Como |
|---|---|---|
| Linha — edição em rascunho não aparece | função de serviço | `WHERE edi_situacao_ciclo IN ('PUBLICADA','EM_REVISAO')`, já implementado |
| Linha — item inativo não aparece | função de serviço | `WHERE cmp_ativa` / `ins_ativo`, já implementado |
| Coluna — dado interno não vaza | serializer da API | o payload é montado campo a campo; o que não está no schema Pydantic não sai |
| Tabela/schema — cliente pagante é inalcançável | **role do banco** | `GRANT` explícito, §4 |

**Campos que o serializer nunca inclui:** `cc_status_conferencia`, `cc_diferenca_valor`, `cc_diferenca_percentual`, `cc_pct_sp`, `cc_observacao_conferencia`, qualquer `*_criado_por` / `*_atualizado_por`, e o `external_path` bruto (sai só a URL já resolvida). São instrumentos internos de curadoria — expô-los entrega o método, não o conhecimento.

View **materializada** continua disponível como ferramenta de **desempenho**, caso apareça uma agregação cara. Como camada de permissão, não é necessária.

---

#### 4. Role e isolamento do banco

É aqui que mora a proteção inteira.

```sql
CREATE ROLE easy_mobile_reader LOGIN PASSWORD :'senha' CONNECTION LIMIT 8;

-- USAGE no schema: necessário para resolver nomes (inclusive as extensões). NÃO dá
-- acesso a tabela nenhuma por si só.
GRANT USAGE ON SCHEMA catalogo TO easy_mobile_reader;

-- Lista EXPLÍCITA. Nada de "ON ALL TABLES".
GRANT SELECT ON
    catalogo.fontes,
    catalogo.edicoes,
    catalogo.composicoes,
    catalogo.composicoes_custo,
    catalogo.composicoes_itens,          -- analítica servida (decidido — §5.1)
    catalogo.composicoes_grupos,
    catalogo.composicoes_subgrupos,
    catalogo.composicoes_historico,
    catalogo.insumos,
    catalogo.insumos_tipo,
    catalogo.insumos_preco,
    catalogo.insumos_familia,
    catalogo.insumos_historico,
    catalogo.edicoes_leis_sociais,
    catalogo.search_document,
    catalogo.indices,
    catalogo.indices_historico
  TO easy_mobile_reader;

-- Cinto de segurança.
ALTER ROLE easy_mobile_reader SET default_transaction_read_only = on;
ALTER ROLE easy_mobile_reader SET statement_timeout = '5s';
ALTER ROLE easy_mobile_reader SET idle_in_transaction_session_timeout = '10s';
```

Cinco observações que fazem a diferença entre funcionar e não funcionar:

1. **Lista explícita, e nenhum `ALTER DEFAULT PRIVILEGES` em `catalogo`.** Assim, tabela nova nasce **fora** do alcance do mobile, e incluí-la é ato consciente. O inverso — `GRANT SELECT ON ALL TABLES` — faria toda tabela futura vazar por omissão, que é a pior forma de vazar.

2. **`ativo`, `tenant_catalogo`, `audit` e `core` nunca são concedidos.** Este é o isolamento que realmente importa: mesmo com a API mobile inteiramente comprometida, não existe caminho até orçamento de cliente pagante, trilha de auditoria ou fila de jobs.

3. **A busca depende do `USAGE` em `catalogo`.** O adapter chama `catalogo.unaccent()`, `catalogo.word_similarity()` e o operador `catalogo.<%` — as extensões vivem nesse schema. Sem `USAGE`, a busca quebra. Conceder é seguro: `USAGE` dá o direito de *resolver nomes*, não de ler dado. Alternativa mais limpa, se um dia se quiser isolamento absoluto: mover as extensões para um schema neutro (`ext`).

4. **`CONNECTION LIMIT` é o que protege o produto pago.** O app gratuito não pode, num pico, consumir as conexões de que o Easy Web precisa. O teto vive na role, não na boa vontade do código. Vale também um pool próprio no serviço mobile — o pool de `backend/core/db.py` hoje é global.

5. **`statement_timeout` na role, não na aplicação.** Query ruim morre sozinha, mesmo que alguém esqueça o limite no serviço.

No `render.yaml`, o serviço mobile recebe `EASY_MOBILE_DB_URL` própria (role `easy_mobile_reader`), separada da `EASY_DB_URL` usada por web e worker.

---

#### 5. Decisões — fechadas em 16 e 21/08/2026

**5.1 — DECIDIDO (16/08/2026): a analítica completa é servida.**
`catalogo.composicoes_itens` entra no `GRANT`. O app exibe a árvore de itens com coeficientes e valores unitários — que é, afinal, o que responde *"o que essa composição remunera"*, o caso de uso principal do módulo. Segurar a analítica seria entregar um app que não responde à pergunta para a qual foi feito.

Razão de fundo, para quem ler depois: **o coeficiente não é segredo da Axys.** SINAPI, CDHU e FDE publicam suas composições — o dado é público na origem. O que a Axys produz de próprio é a **normalização**: equivalências entre fontes, mapeamento de mão de obra, conciliação, curadoria. Essas tabelas (`equivalencias_cpu`, `equivalencias_ins`, `equivalencias_subgrupos`, `composicoes_mapeamento_mdo`, `insumos_equivalencias`) **não estão na lista do §4 e não devem entrar**. É ali que mora o acervo; a analítica é o serviço.

Fica registrada também a posição do dono do produto: se um concorrente copiar, que copie — a preocupação não é essa.

**5.2 — DECIDIDO (16/08/2026): o JSON trafega número cru.**
Valor vai como número (`276.19`), nunca como string formatada. A formatação é do Flutter, pelo locale do aparelho. Data e mês em ISO (`2026-08`), não `ago/26`. Motivo: string formatada impede o app de ordenar, somar e comparar sem parsear de volta, e congela o formato brasileiro num produto que pode ganhar usuário fora do país.

Implicação prática: as funções de serviço atuais devolvem valor já formatado para HTML (`_fmt_money` → `"R$ 276,19"`). A camada mobile precisa do valor cru — via parâmetro `raw` nas funções existentes ou consulta própria. **Escolher na implementação; o contrato JSON não muda.**

**5.3 — DECIDIDO (16/08/2026): limites de busca e paginação.**

 - **Mínimo de 3 caracteres** no termo de busca.
 - **25 itens por página.**
 - **Teto de 10 páginas** — 250 itens por busca.

Racional: não é anti-raspagem (ver §5.1), é **proteção do banco e assertividade de produto**. Termo de 1–2 caracteres casa com meio catálogo, e `composicoes_custo` tem ~18 milhões de linhas — serializar isso estoura a memória do serviço. Paginação profunda é pior ainda: `OFFSET` no Postgres lê e descarta tudo o que veio antes, então a página 500 custa 500× a primeira.

E a regra de produto que sustenta o teto: **quem chegou à terceira página não vai achar paginando** — vai achar refinando. Consulta de preço é busca assertiva, não varredura.

**Os três limites valem no servidor, não só no app.** No app são UX; na API são blindagem — front pode ser burlado, e é a API que protege o banco.

**5.4 — DECIDIDO (16/08/2026): cache na borda (Cloudflare), desde o início.**

Descartado cachear no Redis: o `render.yaml` roda `maxmemoryPolicy: noeviction` de propósito, para não perder job de import. Cache quer o oposto (`allkeys-lru`). Misturar os dois faz a fila de import quebrar quando a memória enche — seria preciso outra instância, e ainda assim o alcance seria muito menor que o da borda.

> **REVISTO em 21/08/2026 — as rotas NÃO são públicas.** A versão anterior deste item as
> abria para que a borda pudesse cachear entre usuários. Isso foi revertido, e o motivo é o
> §5.6: **cota por IP quase não protege** (IP é barato — operadora rotaciona, VPS custa
> centavos), e **`cmp_id` é inteiro sequencial**, então detalhe público significa dump por
> iteração de 1 a 20.000, sem nem precisar buscar. Token obrigatório é o que permite cota
> **por pessoa**, onde abusar custa uma conta com MFA verificado.
>
> O que se perde: o cache **compartilhado** na borda. O que se mantém: o cache do próprio
> aparelho, que era a maior parte do ganho — por isso os cabeçalhos agora saem como
> `private`, e não `public`: com token, cache compartilhado poderia entregar a resposta de
> um usuário a outro.
>
> Quando o volume justificar borda de verdade, revisita-se **com número na mão**.

**A telemetria não é afetada.** O evento é chamada própria (`POST` do app → API do Easy → banco do Hub) e nunca dependeu do `GET` de leitura chegar à origem.

**Invalidação sai de graça, porque a edição está na URL.** `/v0/composicoes/15666?edicao=100612` é imutável: publicar a edição seguinte não invalida nada — gera chave nova. Sem purga, sem cache tag, sem depender do plano contratado.

| Rota | TTL | Por quê |
|---|---|---|
| `/v0/composicoes/{id}` · `/v0/insumos/{id}` com `edicao` explícita | **30 dias** | resposta imutável |
| `/v0/…/historico` · `/v0/…/ufs` | **7 dias** | muda só quando entra edição nova |
| `/v0/busca` | **1 h** | query livre, mas as buscas populares se repetem muito |
| `/v0/catalogo/filtros` | **5 min** | é a única que responde "qual é a edição vigente" |
| `/v0/composicoes/{id}/ctc` | **`no-store`** | conteúdo privado solicitado apenas na abertura |
| telemetria e `Minha conta` | **`no-store`** | variam por pessoa |

Dois complementos:

 - **`stale-while-revalidate` em todas as rotas cacheadas.** A borda serve o valor vencido enquanto busca o novo por trás — é isso que impede que a expiração de um item popular vire rajada de *cache miss* em cima do Postgres.
 - **Exceção da imutabilidade: `EM_REVISAO`.** Edição reaberta ainda muda. Requisição que resolva para uma edição nesse estado recebe TTL curto (5 min), não os 30 dias.

##### Implantação na Cloudflare

**Estado atual (verificado em 16/08/2026):** na zona `axys-tec.com.br`, apenas `public.axys-tec.com.br` (R2) está **Proxied**. `easy.axys-tec.com.br` está **DNS only** — ou seja, **o tráfego da aplicação não passa pela Cloudflare hoje**, e os números de cache do painel referem-se ao bucket público, não à app.

**Hostname da Easy Mobile API: `easy-mobile.axys-tec.com.br`.**

**Quando fazer: assim que a API estiver no ar, ANTES de começar o Flutter.** O app é desenvolvido consumindo a API real — se a borda entrar depois, o time mobile testa contra um comportamento (sem cache, sem os headers valendo) que não é o de produção, e os bugs de cache aparecem no fim, que é o pior momento.

Ordem — e a ordem importa:

1. Criar o serviço mobile no Render e apontar `easy-mobile.axys-tec.com.br` para ele.
2. Registrar o domínio no Render ainda como **`DNS only`** e esperar a emissão do certificado. Virar a nuvem laranja antes disso faz a emissão falhar.
3. Só então mudar o registro para **`Proxied`**.
4. Conferir **SSL/TLS da zona em `Full (strict)`**. É configuração *zone-wide* e hoje não afeta ninguém porque tudo está DNS-only; com o proxy ligado, `Flexible` produz loop de redirecionamento contra o Render.
5. Mudar **`Browser Cache TTL`** (hoje em `14400`) para **_Respect Existing Headers_**. Enquanto estiver com valor fixo, a Cloudflare sobrescreve o `Cache-Control` da API e todo o desenho acima vira decoração.
6. Criar a **Cache Rule**: `URI Path` começa com `/v0/` → *Eligible for cache*, Edge TTL = usar o cabeçalho da origem.

**`easy.axys-tec.com.br` permanece `DNS only`.** O web pago não é proxiado — a borda serve só o gratuito. Isolamento entre os dois produtos também no nível de rede.

Nada a contratar: *Cache Rules* está disponível no plano gratuito. *Cache Analytics* é pago e não é necessário — o painel de visão geral já mostra percentual de cache.

**5.5 — DECIDIDO (16/08/2026), revisto em 22/08/2026: acesso ao bucket privado.**

Arquivos privados grandes usam **URL assinada de curta duração — TTL de 5 minutos**. O CTC é a exceção: por ser um Markdown pequeno renderizado nativamente, a API autentica, autoriza, lê o objeto e entrega seu conteúdo na resposta `no-store`. Assim, Flutter Web, iOS e Android usam o mesmo fluxo sem depender do CORS do bucket. O path interno e as credenciais nunca chegam ao cliente.

Por que o bucket privado continua sendo privado, mesmo com a analítica servida (§5.1): os originais de **CDHU e FDE são material de terceiros** — republicá-los em bucket público é questão de **direito autoral**, não de estratégia comercial. O que é produção própria da Axys é o **CTC**, e mesmo ele é servido como documento, nunca como arquivo-fonte. Isso encerra em definitivo a hipótese de publicar cadernos no bucket público.

Aplica-se às duas portas do caderno — o botão *Ver Caderno* do módulo 1 e o grupo *Cadernos Técnicos* do módulo 2. Outros materiais privados continuam usando URL assinada.

Notas de implementação:

 - `get_private_presigned_url()` **já existe** em `backend/storage/r2_storage.py`, mas seu default é `expires_in=3600` (uma hora). O serviço mobile deve **passar o TTL explicitamente**; melhor ainda, criar um wrapper próprio com 300s fixo, para que ninguém herde a hora por esquecimento.
 - Credencial: token R2 **somente leitura**, escopado ao bucket privado — mesma lógica do `easy_mobile_reader` no §4.
 - O mobile não expõe uma rota genérica `/doc-file/{path}`; somente o endpoint específico do CTC pode ler o Markdown autorizado.
 - Consequência prática do TTL: a assinatura é verificada no início da requisição, então download já iniciado costuma concluir mesmo se o prazo virar. Mas **retomar** um download interrompido depois de expirado exige nova assinatura — o app deve pedir a URL de novo em vez de guardá-la.
 - URL assinada muda a cada emissão, logo **não cacheia em CDN**. É o custo aceito por manter o material controlado.

**5.6 — DECIDIDO (21/08/2026): cota por usuário.**

| Limite | Valor |
|---|---|
| Requisições / minuto | **60** |
| Requisições / dia | **3600** |
| Buscas / minuto | **30** |
| Buscas / dia | **400** |

**Por usuário (`sub`), nunca por IP.** O teto define o *preço por conta*; o MFA do cadastro
define *quantas contas* o sujeito consegue ter. Só as duas coisas juntas encarecem a varredura
— sozinho, nenhum dos dois resolve.

**A cota de busca é separada e bem mais apertada no dia** porque a busca é o vetor de
**descoberta**: sem ela, quem quer o acervo precisa adivinhar ids. Limitar requisição total
incomoda pouco o raspador; limitar busca/dia é o que trava a varredura. E quem faz 400 buscas
num dia não está consultando preço.

Dimensionamento contra uso real: uma sessão de consulta gasta 15 a 30 requisições; dez sessões
num dia dão ~300. O teto diário é ~10× um dia pesado — ninguém encosta.

**Honestidade sobre o alcance:** isto **não torna a raspagem impossível**. O acervo tem ~17 mil
composições e ~11 mil insumos; a 3600/dia, uma conta leva ~8 dias. O que encarece de verdade é
precisar de N contas com e-mail ou WhatsApp verificado, rastreáveis.

Implementação: `backend/api/mobile/rate_limit.py` — janela fixa no Redis, **fail-open** (cota é
defesa, não portão: Redis fora do ar não derruba acesso legítimo). Espelha
`backend/core/rate_limit.py`, que já existia com a mesma motivação para documentos. O contador
é minúsculo e expira sozinho, então convive com o `maxmemoryPolicy: noeviction` do Redis de
produção, onde a fila de import continua sendo a prioridade.

**Claims que sustentam tudo isso**, entregues pelo Hub: `sub` (uuid), **`subject_type`**
(`hub_user` | `mobile_client` — as duas bases de cadastro) e `client_hub_uuid` (o vínculo,
quando o cadastro mobile vira cliente). O `subject_type` não é enfeite: é o que faz a métrica
sair certa desde o primeiro evento.

---

## 2. BASE DE CONHECIMENTO AXYS

A base de conhecimento Axys é o maior serviço informativo diferenciado da aplicação. Ela vai fornecer análises, brainstorming, insights que darão ao engenheiro orçamentista e demais usuários indicadores privilegiados que, ao tomá-los como conhecimento, potencializarão seu trabalho.

A BASE DE CONHECIMENTO AXYS será uma seção do aplicativo mobile composta por três tipos de telas:
 - MAIN BASE DE CONHECIMENTO
 - SUB-MAIN GRUPO
 - MATÉRIA

> **Formato de cada conteúdo:** `conteudos_json_r2.md`. **Rotas de dado:**
> `endpoints_json_api.md`. Este documento decide **o que o app faz**; aqueles descrevem
> **como o dado chega**.


### MAIN

A tela dita main da base de conhecimento terá logo após o logo de topo o texto BASE DE CONHECIMENTO AXYS, seguida de uma seção Últimas Publicações (mínimo 3, máximo 5, hiperlinkadas), seguido de hiperlinks personalizados de grupo de informacoes. Os grupos serão:
A Base de Conhecimento tem **quatro pilares**, e cada um responde a uma pergunta
diferente — é isso que justifica formatos editoriais distintos:

 - *Terminologia* — **"O que significa?"** Verbete com conceito, função prática e, sobretudo,
   a **distinção dos termos vizinhos**, que é o que tira a dúvida real. V0: **82 verbetes**.
 - *Dúvidas rápidas* — **"Como funciona ou como faço?"** Resposta direta primeiro, explicação
   curta, exemplo e ressalva. De 150 a 350 palavras. V0: **30 dúvidas em 5 assuntos**.
 - *Casos práticos* — **"O que fazer nesta situação?"** Parte de situação concreta e **não
   responde só sim ou não**: regime de execução, matriz de riscos, edital, contrato e
   documentação mudam a conclusão. V0: **16 casos**.
 - *Acórdãos e jurisprudência* — **"Qual é o entendimento e seu fundamento?"** Ficha técnica
   com tese em linguagem simples, aplicação prática e **limites do entendimento** — não é
   pasta de PDF; o valor da Axys está na tradução. V0: **30 fichas**.

Além dos quatro pilares:

 - *Easy Newsletter*: análise e indicadores de cada edição de fonte-base publicada. Entra na V0.
 - *Artigos & Matérias*: análise do comportamento orçamentário, tipologias mais orçadas no mês,
   conteúdo enriquecido. **V1+** — na V0 fica vazio, porque os acórdãos, que eram seu conteúdo
   inicial, ganharam pilar próprio.
 - *Downloads & Utilitários*: planilha orçamentária inteligente, auto-lisps e coletores CAD.
   Na V0 entra apenas a planilha.

**O que NÃO é grupo da Base de Conhecimento**, e por quê:

 - *Cadernos Técnicos* — o mobile enxerga o **CTC**, produção da Axys em Markdown, e o acessa
   **pela Central de Custos**, no botão da composição. O caderno HTML **da fonte** é material
   de terceiros e não é exposto ao aplicativo (§5.5).
 - *Índices Inflacionários* — é **dado**, não conteúdo editorial: vem da API (`/v0/indices`),
   não de manifesto no R2. Aparece no menu, mas não segue o desenho de conteúdo.
 - *Calculadora de CUB* — é **funcionalidade**, não conteúdo. **Fora da V0**; entra quando
   houver base de dados sólida.
 - *Canal Axys* — módulo próprio (6), **fora da V0**: não haverá vídeo publicado.

Nota: A descrição acima é genérica mas a ordem de exibição no app mobile deverá respeitar a ordem abaixo:

Últimas publicações

Easy Newsletter · SINAPI Agosto/2026
Caso prático · Andaime não previsto na planilha
Acórdão TCU 2622/2013 · BDI e administração local

Explore
 - Terminologia
 - Dúvidas rápidas
 - Casos práticos
 - Acórdãos e jurisprudência
 - Easy Newsletter
 - Índices
 - Downloads & Utilitários

### Dúvidas rápidas — origem e regra editorial

O conteúdo inicial vem de casos reais: participo de uma comunidade sobre auditoria e obras
públicas, e os primeiros vieram de lá. Depois, os próprios usuários perguntam e o acervo
cresce. Sempre separado por assunto.

**Recorte.** O pilar nasce partido em dois:
 - **Ler** as perguntas já respondidas, navegando por assunto: **V0** — 30 dúvidas em 5 assuntos.
 - **Perguntar** — usuário enviar a própria dúvida: **V1**. Não é limitação técnica, é
   operação: cada pergunta recebida vira compromisso de resposta com o nome da Axys em cima.
   Abrir esse canal antes de existir rotina de triagem e prazo é criar dívida pública.

**Regra editorial dos quatro pilares.** Quando existir fonte normativa, **cite-a**. A
resposta sobre BDI diferenciado, por exemplo, tem respaldo no Acórdão TCU 2622/2013 — que já
é ficha nossa, então o vínculo aponta para **dentro do aplicativo**, não para o site do TCU.
Citar é o que transforma "opinião de um engenheiro experiente" em conhecimento Axys
verificável, e é exatamente a *confiança irrefutável* do objetivo secundário.

**Exemplos** (formato final em `conteudos_json_r2.md`):

**BDI** — *Posso aplicar BDI diferenciado sobre fornecimento de equipamentos?*
Sim, e é a melhor prática. Na composição do BDI entram parâmetros ligados à dificuldade de
execução e ao valor agregado da solução. Equipamentos costumam ter valor agregado elevado, e
a gestão da aquisição e instalação é mais simples e menos onerosa do que a execução das obras.

**SINAPI** — *Uma composição remunera perda de concreto em estaca hélice?*
Sim. Nas composições SINAPI de estacas hélice, as perdas decorrentes do sobreconsumo estão
presentes — na maior parte das composições, aliás. A recomendação prática é conferir o
caderno técnico e a analítica do item.

**Orçamento** — *Quando devo converter mão de obra horista para mensalista?*
Em obras de médio e longo prazo, a prática é a mão de obra do construtor não ser
terceirizada. Sabendo a Administração que o particular empregará mensalista, porque custos
indiretos e encargos pesam menos nesse regime, indica-se converter as composições.

**Aditivos** — *Como incluir serviço sem correspondente na planilha contratual?*
É imperativo consultar o contrato, os documentos vinculados, a matriz de riscos e a
legislação vigente. A depender do regime de execução, de quem deu causa e do que a matriz
aloca, o aditivo é possível.

### SUBMAIN GRUPO

Para cada grupo, abre uma segunda tela, com as especificidades de cada tela. Da submain, avança-se ao assunto/material, onde é verificado, visualizado e operado as demais funcionalidades.

### Easy Newsletter — produto editorial

Produto editorial central da Base de Conhecimento. As últimas edições ficam disponíveis e formam histórico. Cada edição começa com **resumo curto, chamativo e rico**, seguido da matéria completa, com referência de **5 a 10 páginas**.

**O gatilho é editorial, não de calendário:** uma edição nova de fonte-base relevante dispara a publicação. Preferencialmente uma **única notificação** informa a edição e leva à newsletter.

Conteúdo possível: boletins publicados, novas composições, desativações, alterações, variação média e distribuição, comparação com IPCA/INCC, ranking de altas e quedas, série de 12 meses, insumos explicativos, anomalias e destaques.

``` text
importação → estruturação Easy → cálculos determinísticos
→ payload editorial → IA de alta capacidade
→ redação/análise → revisão humana → publicação + push
```

> **O sistema calcula. A IA interpreta e redige. A IA não é fonte primária dos números.**

**Onde esse pipeline roda:** inteiramente no **Easy Web**. Nem a Easy Mobile API nem o aplicativo participam da geração — eles apenas distribuem e apresentam o resultado publicado. Ver *Infraestrutura de Conteúdo §9*.

### Tipologias e indicadores Axys

Evolução prevista para a Base de Conhecimento: residência, edifício, escola, creche, UBS, galpão, pavimentação, praça e afins, com custo/m², custo global, relação com o CUB, distribuição, grupos de serviços, séries e data-base.

**Separação metodológica obrigatória**, e ela não é detalhe de redação:

| Categoria | O que é |
|---|---|
| **Referencial oficial** | o que a fonte publica (SINAPI, CDHU, FDE, CUB) |
| **Indicador Axys** | número produzido pela Axys a partir de dados próprios |
| **Estudo de caso Axys** | observação de uma obra real, autorizada |

> **Nunca apresentar indicador próprio como se fosse oficial de terceiro.** A credibilidade que o app existe para construir é destruída de uma vez por uma única confusão dessas.

### Estudos de caso

Casos reais autorizados podem conter tipologia, área, características, custo, custo/m², relação com CUB, grupos de serviço, soluções adotadas, imagens, orçamento, execução, previsto × executado e aprendizados.

Observar sempre: sigilo contratual, cláusulas do contrato, direitos autorais e autorização expressa de quem é dono da obra.

## 3. SOLUÇÕES AXYS — **V0**

Aqui entra um carousel das soluções Axys, estática mesmo, em sequencia mesmo, iniciando pelos destaques, numa apresentação organizada assim

 - Ecossistema: AxysEasy
 - Produto: EasyPrice
 - Descrição: {descrição}
 - Disponibilidade: {para contratação/em desenvolvimento}

## 4. SOBRE A AXYS — **V0**

Assim como as soluções é uma tela/material estático. No entanto, quando dizemos estáticos nos referimos a textos destacados/persistidos em R2, consultados pela aplicação. Portanto, a atualização não vem no app em si mas sim nos documentos persistidos. Será composto de:

Por que Axys?
A Axys nasce da ideia de que a tecnologia deve entender como as pessoas trabalham para tornar operações complexas mais simples e intuitivas. Seu nome une axis (eixo) e system, representando uma plataforma que organiza, conecta e sustenta dados e processos. Desenvolvemos soluções para profissionais técnicos com foco em reduzir atritos, eliminar retrabalho e simplificar o dia a dia, porque, para nós, tecnologia só gera valor quando resolve problemas concretos e faz o trabalho ficar mais fácil.

A Axys não é um software
A Axys é uma infraestrutura digital modular para a engenharia, conectando documentos, processos e decisões à realidade de profissionais e empresas técnicas.

Missão & Valores
Missão: tornar a gestão de processos, tarefas e atividades mais simples e eficiente, com segurança, rastreabilidade e previsibilidade.

Praticidade
O sistema tem que servir a rotina, não virar um obstáculo.

Segurança
Permissões e desenho de proteção de dados desde a origem.

Confiabilidade
Rastreabilidade e contratos claros: sistema orientado a logs e auditoria.

Valorização de pessoas e parcerias
Time, cliente e parceiro: relação de longo prazo e constante crescimento.

Inovação contínua
Evolução controlada — sem quebrar o que já está funcionando.

Visão de ecossistema
Axys: Axis + System — o eixo central com módulos acopláveis.

## 5. ROADMAP — **V0**

Aqui vamos mostrar em linha do tempo quando cada solução Axys estará pronta.

A ideia é mostrar duas linhas do tempo.
 - Geral: 2026 | 2027 | 2028
 - Específica: 2026 > 2027

|----- EASY -----|--- EASY-EVOLUÇÃO ----|-----PRO----->
|----- 2026 -----|-------2027-----------|----2028----->

### Ano 2026
 - Out: EasyPrice, EasyCPU, EasyOrça
 - Nov: EasyProjectManager
 - Dez: EasyBuildDiary, EasyFinControl

### Ano 2027
 - Jan: EasyLicitPlan
 - Fev: EasyDocs
 - Mar-Jun: Evolução módulos EasyOrça: Coletores CAD, BIM, RVT + novas funções

### Ano 2028
 - AxysPRO: ERP, a base da operação


## 6. CANAL AXYS — **fora da V0**

Acesso aos materiais publicados no canal do YouTube. **Não entra na V0** porque não haverá
vídeo publicado — módulo que abre vazio ensina o usuário a não voltar nele.

Quando entrar, é apenas lista de links externos: o vídeo mora no YouTube, não no R2. O
grupo aparece no manifesto de raiz com `disponivel: false` até lá, então ligá-lo **não
exige versão nova do aplicativo**.

## 7. MINHA CONTA — **V0**

Governança do próprio cadastro. Módulo pequeno, mas **obrigatório na V0**: a partir do momento em que existe cadastro (ADR 0), existe o dever de deixar o usuário ver, corrigir e apagar o que é dele.

Composição:

 - **Meus dados**: nome completo, telefone e e-mail — visualizar e alterar. Alteração de e-mail ou telefone repete o MFA.
 - **Complete seu perfil**: UF e profissão/área de atuação. É aqui que moram os campos que a ADR 0 tirou do cadastro inicial. Sempre opcional, nunca impeditivo.
 - **Alterar senha**.
 - **Preferências de notificação**: liga/desliga por tipo (nova edição, nova publicação). Coerente com o princípio de push parcimonioso.
 - **Excluir minha conta**.
 - **Sair**.

> **Excluir a conta não é opcional.** A App Store exige que todo app que permite criar conta permita **apagá-la dentro do próprio app** — não vale mandar o usuário abrir chamado ou escrever e-mail. É motivo recorrente de reprovação em revisão. A LGPD aponta na mesma direção. Vale definir desde já o que "excluir" significa do lado do servidor: apagar o cadastro e desvincular a telemetria, mantendo o dado agregado que não identifica ninguém.

Nota: este módulo é o único do Core que **escreve** — e escreve no Hub, que é o dono da identidade, não no banco do Easy.

---

# Infraestrutura de Conteúdo

Camada-base de distribuição de **todo** conteúdo estático do Easy Mobile. Não é exclusiva da Newsletter — serve Artigos & Matérias, Terminologia, Downloads & Utilitários, Soluções, Sobre a Axys, Roadmap e Dúvidas & Perguntas. A Newsletter é apenas a primeira instância.

> **A origem informa onde está. O R2 entrega. O Flutter apresenta.**

*(Incorpora e substitui o ADR `easy_mobile_adr_newsletter_r2.md`, generalizando-o e ajustando-o às convenções deste repositório.)*

## 1. Princípio

Conteúdo editorial é **estático depois de publicado**. Não faz sentido a Easy Mobile API baixar objeto do R2 e retransmiti-lo ao aplicativo — isso gasta CPU e banda do serviço para entregar um byte que a CDN entregaria de graça.

O app baixa **direto do R2/CDN**. A API não é proxy de arquivo.

**Exceção única: o caderno técnico.** Ele fica no bucket privado e segue a regra específica do §5.5 da Central de Custos — conteúdo Markdown pela resposta autenticada `no-store`. Tudo o mais que este capítulo descreve é público.

## 2. Onde o conteúdo mora

**Bucket público existente, domínio existente.** Nada de hostname novo: `public.axys-tec.com.br` já aponta para o `axys-public` e já é o único hostname **proxiado** na Cloudflare.

Namespace próprio **`easy-mobile/`** — não `easy/`. O conteúdo existe só para o
aplicativo, e o nome acompanha o produto, que já se chama assim no repositório
(`axys-easy-mobile`), no hostname (`easy-mobile.axys-tec.com.br`) e na audience do token
(`aud=easy-mobile`). Criado em 21/08/2026.

``` text
easy-mobile/
├── _ultimas.json                    ← agregado, últimas N publicações de todos os grupos
├── newsletter/
│   ├── _manifest.json
│   └── 2026-08/
│       ├── conteudo.json            ← estruturado, renderizado nativamente
│       ├── completo.pdf             ← edição completa
│       ├── capa.webp
│       └── assets/…
├── artigos/
│   ├── _manifest.json
│   └── acordao-tcu-2622-2013/…
├── terminologia/_manifest.json
├── downloads/_manifest.json
├── duvidas/_manifest.json
└── institucional/_manifest.json     ← Soluções Axys · Sobre a Axys · Roadmap
```

**Path em slug ASCII**, sempre: `duvidas/`, não `dúvidas/`. Acento em URL vira
`d%C3%BAvidas`, quebra copiar-e-colar e cada cliente codifica de um jeito. O rótulo na
tela continua "Dúvidas & Perguntas" — nome de pasta e nome de tela são coisas diferentes.

**`institucional/`** guarda Soluções, Sobre e Roadmap, que hoje moram no binário. Migrar
para o R2 permite corrigir uma data do Roadmap sem passar pela revisão da App Store — que
leva dias, e é justamente a tela onde data errada mais custa credibilidade.

**Os paths nascem em `backend/modules/catalogo/storage_paths.py`**, não escritos à mão. É a regra da casa: nada de path de storage solto pelo código, para o layout ficar num lugar só.

## 3. Descoberta: manifesto estático, sem rota de API

O manifesto é **arquivo no R2**, não endpoint. Para o volume em questão — algo como uma dúzia de newsletters por ano — um JSON estático resolve, e a CDN o serve sem tocar em serviço nenhum.

Dois níveis:

 - **`_manifest.json` por grupo** — alimenta a tela SUBMAIN de cada grupo.
 - **`_ultimas.json` agregado** — alimenta "Últimas publicações" da HOME e da MAIN da Base de Conhecimento, misturando grupos e ordenado por data. É o que dispensa a rota de agregação na API.

Ambos são **regerados no ato de publicar**. Publicar é, essencialmente, escrever os objetos e reescrever os dois manifestos.

Item do manifesto:

```json
{
  "id": "2026-08",
  "grupo": "NEWSLETTER",
  "titulo": "Easy Newsletter — Agosto/2026",
  "chamada": "SINAPI sobe 0,8% no mês; mão de obra puxa a alta.",
  "publicado_em": "2026-08-10",
  "assuntos": ["SINAPI", "MAO_DE_OBRA"],
  "capa":     "easy/conteudo/newsletter/2026-08/capa.webp",
  "conteudo": "easy/conteudo/newsletter/2026-08/conteudo.json",
  "pdf":      "easy/conteudo/newsletter/2026-08/completo.pdf"
}
```

**`chamada` é obrigatória** e existe por um motivo prático: sem ela, montar uma lista de três itens obrigaria o app a baixar três `conteudo.json` inteiros.

**Os paths vão gravados, mesmo sendo determináveis por `(grupo, id)`.** É exceção consciente à doutrina de não guardar path determinístico: quem consome é um **binário publicado em loja**, que não pode ser corrigido rapidamente se a convenção de nomes mudar. O manifesto absorve a mudança; o app instalado, não.

## 4. Formato do conteúdo

**Estruturado, não PDF nem imagem.** O `conteudo.json` carrega manchete, subtítulo, resumo, números-chave, textos, rankings, tabelas, séries para gráficos simples, links internos, referências a assets e CTA. O Flutter renderiza nativamente.

Consequência que justifica a escolha: **publicar conteúdo novo não exige nova versão do aplicativo.**

Regra de ouro — **nunca transformar texto em imagem**:

| Tipo | Como vai |
|---|---|
| texto, números, rankings, tabelas | dados no `conteudo.json`, render nativo |
| gráficos simples | série no `conteudo.json`, render nativo |
| fotografia e ilustração | arquivo no R2 (WebP quando aplicável) |
| edição completa | PDF no R2 |

## 5. Rascunho e publicação

**O bucket público é publicação para o mundo, e o que saiu da CDN não volta.** Portanto:

 - material em redação e em revisão vive no **bucket privado**;
 - **publicar é mover** — copiar os objetos para o público e regerar os manifestos;
 - **nunca se edita direto no público.**

## 6. Métricas — o arquivo não passa pela API, o evento passa

Baixar da CDN **não isenta o app de reportar**. Ao abrir uma matéria, o aplicativo envia um evento próprio para a Easy Mobile API (`POST`), independente de onde o conteúdo veio.

```
app  →  CDN  →  conteúdo (não toca a API)
app  →  POST /v0/eventos  →  Easy Mobile API   (autenticado, nunca cacheado)
```

É a única coisa que **precisa** bater na porta da API neste fluxo — e sem ela não existe "quais matérias são lidas", que é metade da razão de o módulo existir. O vocabulário de eventos será definido junto com a telemetria, depois do mapeamento completo.

## 7. Cache

 - **Objetos de conteúdo** (`conteudo.json`, PDF, capa, assets): o path contém o `id` da edição, logo são **imutáveis** — cache agressivo, 30 dias ou mais. Conteúdo corrigido ganha path novo, não sobrescreve.
 - **Manifestos**: são o ponto de descoberta e mudam a cada publicação — **TTL curto, 5 minutos**. Mesma lógica de `/v0/catalogo/filtros`.

## 8. O que não fazer

 - `App → API → R2 → API → App` para entregar arquivo estático.
 - Resumo como PDF ou como imagem única.
 - Conteúdo editorial embutido no binário do aplicativo.
 - API como proxy permanente de PDF, imagem ou JSON.
 - Editar arquivo direto no bucket público.
 - Hostname de conteúdo novo — usar o `public.axys-tec.com.br` que já existe.

## 9. Fora de escopo desta API

**A produção do conteúdo não é deste projeto.** Redação, cálculo dos indicadores, geração do `conteudo.json` e do PDF, revisão humana e o ato de publicar são responsabilidade do **Easy** — este capítulo trata apenas de como o material publicado é descoberto, distribuído e medido.

---

# Autenticação & Identidade

Três pontos de contato — Hub, Easy Mobile API e app — e o desenho do trânsito entre eles é responsabilidade **deste** projeto.

```
app   →  navegador  →  Hub (login)  →  code
app   →  POST /v0/auth/exchange {code}  →  Easy Mobile API
              Easy Mobile API  →  /auth/exchange (client credentials)  →  Hub  →  JWT
              Easy Mobile API  →  valida via JWKS  →  devolve o JWT ao app
app   →  Keychain / Keystore  →  Authorization: Bearer …  nas chamadas seguintes
```

**O app nunca fala com o Hub para trocar o code.** Quem faz o exchange é a API, que roda no servidor e pode guardar o `client_secret` — exatamente como o `backend/modules/auth/routes_sso.py` já faz para o Easy Web. Consequências: o segredo nunca chega ao aparelho, **não é preciso PKCE**, e o Hub não precisa de nenhuma mudança para o handshake. A única diferença em relação ao web é a última linha — em vez de `set_token_cookie`, o token volta no corpo da resposta.

**Contexto que baixa o risco de tudo abaixo:** depois do §5.4 da Central de Custos, as rotas de catálogo são **públicas**. O token não protege preço nem composição. Ele serve para identificar quem gerou evento de telemetria, abrir Minha Conta e futuras rotas por pessoa.

## Decisões (16/08/2026)

**1. O app carrega o JWT do próprio Hub.** A Easy Mobile API apenas valida a assinatura via JWKS — mesmo caminho já usado pelo web. Sem token próprio, sem estado novo, coerente com a regra de que a API mobile não escreve no banco do Easy. Custo aceito: sem revogação de sessão (JWT é *stateless*); revogar exigiria estado e não vale a pena para o que o token protege.

**2. Isolamento por `aud = easy-mobile`.** O Easy Web **recusa** tokens com esse público. Token de app gratuito nunca vira chave do produto pago.

**3. Sessão longa, renovação em segundo plano.** Ao expirar, novo handshake silencioso pelo navegador — normalmente invisível, porque a sessão do Hub segue viva. Evita depender do endpoint de `refresh`, hoje não implementado no Hub.

**4. Token vencido degrada, não expulsa.** A consulta continua funcionando (rota pública); só telemetria e Minha Conta ficam indisponíveis enquanto o app renova por trás. Ninguém é jogado para a tela de login no meio de uma pesquisa — é a ADR 0 na prática.

**5. Cadastro do usuário gratuito em caminho isolado no Hub: `client_easy_mobile`.**
O cadastro de clientes do Hub tem três camadas (tenants → stores → users). Quem baixou o app não deve tocar nessa estrutura — **isolar é proteger**.

Fluxo, todo resolvido pela **API do Hub**: ao autenticar, olha primeiro a base de users; se não achar, cai na tabela isolada. Quem já é cliente e baixa o app **loga normalmente**; se tentar se cadastrar, recebe "você já tem cadastro". Quem não existe em lugar nenhum é criado na tabela isolada.

O Flutter **não sabe qual tabela o Hub usa** — conhece apenas o endpoint, o JSON que envia e o que recebe.

A tabela é **transitória**: quando o usuário vira cliente de produto, é promovido para a base de users.

**Chave de casamento: CPF.** É o que identifica a pessoa de forma estável — e-mail e telefone mudam, CPF não. É ele que mantém mensurável a conversão "veio do app → virou cliente", uma das razões de existir do projeto.

Regras:

 - **CPF não entra no cadastro inicial.** A ADR 0 mantém a porta com nome, telefone, e-mail e senha; pedir CPF ali é o campo que mais faz gente desistir num app gratuito. Ele é **opcional no "Complete seu perfil"** e vira **obrigatório no momento da contratação** — fluxo em que o CPF já é exigido de qualquer forma.
 - **Casamento por CPF quando houver; e-mail e telefone como reserva.** Cobre quem nunca preencheu o perfil.
 - **CPF não é chave primária** da tabela isolada — será nulo na maioria das linhas. Id interno como PK, CPF como campo de casamento, **com validação de dígito verificador** na entrada: CPF inválido guardado é match que falha justamente no dia em que se precisa dele.
 - **`client_easy_mobile.client_hub_uuid`, default `NULL`** — preenchido no momento em que o usuário vira cliente. CPF, e-mail e telefone são como se **encontra** o vínculo; esta coluna é onde ele fica **guardado**. Gravado uma vez, a conversão deixa de depender de inferência para sempre.

**6. Excluir conta = soft delete.** Nada é apagado fisicamente; o registro é inativado.

**O que a App Store efetivamente exige** (diretriz 5.1.1(v)) é o **fluxo**, não o destino do dado — a Apple não audita banco de ninguém. A verificação é feita por revisor humano, que instala o app, cria conta e procura a opção. São três requisitos observáveis:

 - existe **"Excluir minha conta"** dentro do app;
 - a exclusão **conclui sem suporte** (não vale "entre em contato", não vale só "desativar");
 - depois dela, **o login não funciona mais**.

Atendidos os três, **o soft delete passa na revisão** — é decisão de implementação, invisível para a loja.

> **Separado disso, e por outro motivo:** anonimizar os dados pessoais do registro inativado (nome, e-mail, telefone, CPF) é postura de **LGPD**, não de App Store. Fiscais diferentes, gatilhos diferentes: a Apple age na revisão, olhando a tela; a ANPD age por reclamação de titular, e o direito de eliminação está no art. 18. **Não é bloqueio de lançamento** — é decisão de risco jurídico, e pode vir depois.

## O que ainda depende do Hub

Os itens **1 a 4** se resolvem inteiramente deste lado. O **5** e o **6** são trabalho na API do Hub — e são os únicos deste projeto que dependem de outro cronograma.

---

# Notificações

Uso **parcimonioso**. Justificam push apenas:

- edição nova de fonte-base + a newsletter correspondente (preferencialmente **uma única** notificação para os dois);
- conteúdo técnico excepcional;
- material de altíssimo interesse.

> **Valor informacional acima de frequência.** Um app gratuito que notifica demais é desinstalado — e desinstalação é irreversível de um jeito que nenhuma métrica recupera.

O usuário controla o que recebe em *Minha Conta → Preferências de notificação*, por tipo.

---

# Telemetria

## Decisão de destino

A **Easy Mobile API escreve diretamente no banco do Hub** para analytics, sem criar API intermediária só por purismo arquitetural. São duas conexões distintas no mesmo serviço:

``` text
EASY_MOBILE_DB_URL     → banco do Easy → somente leitura (easy_mobile_reader)
HUB_ANALYTICS_DB_URL   → banco do Hub  → escrita restrita (easy_mobile_analytics_writer)
```

A role `easy_mobile_analytics_writer` recebe **apenas** o necessário para o analytics. **Nunca** a credencial ampla do Hub.

A escrita direta vale **só para eventos append-only**. Perfil global, tenant, licença, produto, billing, papéis, autorização e demais regras funcionais continuam passando pela API do Hub.

**O banco do Easy segue sem escrita alguma** — a promessa do §3 da Central de Custos permanece intacta.

## Fluxo

``` text
ação do usuário  →  app  →  POST /v0/eventos  →  Easy Mobile API
                                                      ↓
                                          track_event()  →  Hub Analytics
```

Vale inclusive quando o conteúdo veio direto da CDN sem tocar a API (*Infraestrutura de Conteúdo §6*): o arquivo não passa pela API, **o evento passa**.

## Abstração e tolerância a falha

Não espalhar SQL do Hub pelo código. Um ponto único — algo como `integrations/hub/analytics_repository.py`, expondo `track_event(...)`. Hoje faz `INSERT` direto; amanhã pode virar fila ou API sem que nada acima perceba.

> **Analytics nunca pode quebrar a experiência principal.** Falha de métrica é *best-effort*: registra-se no log e segue. Consulta válida jamais vira HTTP 500 por causa de telemetria.

## O que guardar — a decidir

O vocabulário de eventos será fechado **depois do mapeamento completo dos módulos**. Ponto de partida, a refinar:

`app_open` · `login` · `search` · `price_view` · `composition_view` · `history_view` · `simulation_run` · `newsletter_open` · `article_open` · `caderno_open` · `download` · `youtube_click` · `solution_click` · `notification_open`

Métricas pretendidas: DAU/MAU, retenção 7/30/90, UF, profissão declarada, fontes mais consultadas, buscas por usuário, leitura de newsletter, consumo de conteúdo e funil para as soluções.

**Princípio de recorte:** registrar **intenção**, não navegação. Se um dado não muda uma decisão, não merece existir. Isso descarta tempo de tela por segundo, scroll e ping periódico.

**Item de maior valor isolado: termo buscado que não retornou resultado.** É o público dizendo o que procurou na Axys e não encontrou — pauta editorial pronta, e vale mais que qualquer contador de acesso.

---

# Descritivo Axys

Os produtos de **produção** do ecossistema (Easy Orça e sucessores) poderão gerar um **Descritivo Axys** do orçamento: custo global, custo/m², relação com o CUB, distribuição entre mão de obra, materiais e equipamentos, curva ABC, data-base e fontes utilizadas. Ao final, CTA discreto para conhecer a plataforma ou solicitar avaliação.

Funciona como **distribuição orgânica da marca**: o documento circula entre pessoas que não são clientes, carregando método e credibilidade em vez de anúncio.

Não é funcionalidade do Easy Mobile — é do Easy Web. Está registrado aqui porque alimenta o mesmo funil e porque o app é um dos lugares onde esse material pode ser apresentado.

---

# Aquisição

App gratuito, distribuído por App Store e Google Play. Canais: SEO, site, Google Ads, Meta, TikTok, YouTube, o próprio conteúdo, documentos que circulam e indicação. Mídia paga pontual, não necessariamente agressiva.

**ASO/SEO** — termos de interesse: SINAPI, CDHU, obras públicas, orçamento de obras, preço, custo, estimativa de custo, construção civil, composição de custos, BDI, encargos sociais, engenharia civil, preços de referência.

Sem *keyword stuffing*: descrição de loja é lida por gente, e texto empilhado de palavra-chave depõe contra a seriedade que o produto quer transmitir.

---

# Premissas congeladas

- nome do projeto: **Easy Mobile**;
- **gratuito, não freemium**;
- Base de Conhecimento Axys — consulta e informa, não produz;
- **sete módulos** (nomes canônicos): Central de Custos · Base de Conhecimento Axys · Soluções Axys · Sobre a Axys · Roadmap · Dúvidas & Perguntas · Minha Conta;
- iOS + Android em **Flutter**, repositório próprio `axys-easy-mobile` (submódulo do `axys-easy`);
- backend **FastAPI**, serviço mobile no mesmo repositório do Easy, entrypoint `backend/app_mobile_api.py`;
- banco do Easy como **fonte canônica**, sem espelho e sem duplicação;
- **sem camada de views** — proteção por role `easy_mobile_reader` com `GRANT` nominal;
- **nenhuma escrita no banco do Easy**;
- autenticação central no **Hub**; app carrega o JWT do Hub, isolado por `aud=easy-mobile`;
- rotas de leitura do catálogo **públicas** — login identifica, não tranca;
- conteúdo estático distribuído por **R2/CDN**, com a API fora do caminho do arquivo;
- CTC privado pela resposta autenticada `no-store`; demais arquivos privados por URL assinada de 5 minutos;
- **cache é cabeçalho**, não subsistema; borda ligada antes do Flutter;
- telemetria escrita direto no banco do Hub, com credencial restrita e *best-effort*;
- **notificação só quando houver valor real**;
- recorte de escopo começa em **V0**.

---

# Não-objetivos

O Easy Mobile **não** deve:

- virar Easy Orça mobile, nem editar, nem produzir orçamento;
- expor **dump ou export integral** do acervo — consulta é assertiva, não varredura;
- duplicar o banco sem necessidade;
- possuir autenticação independente do Hub;
- compartilhar a credencial operacional do Easy (`axys_tec`);
- compartilhar credencial ampla do Hub;
- usar o token mobile para abrir o Easy Web ou o portal do cliente;
- bombardear o usuário com push;
- transformar analytics em dependência crítica da requisição;
- apresentar indicador próprio como referencial oficial de terceiro.

> **Nota sobre abertura.** O documento que originou este capítulo listava *"não fornecer API aberta para concorrentes"*. Isso foi **revisto em 16/08/2026**: a analítica é servida e as rotas de catálogo são públicas, porque o coeficiente já é público na origem e o ativo da Axys é a normalização, não o dado. O que permanece vedado é o **dump**, não a consulta.

---

# Ordem de implementação

1. **congelar este contrato**;
2. contrato de autenticação mobile no Hub — `aud=easy-mobile` e a tabela isolada `client_easy_mobile`;
3. criar a role `easy_mobile_reader` e aplicar o `GRANT` nominal;
4. criar `backend/app_mobile_api.py` e os endpoints V0 da Central de Custos;
5. **configurar a borda na Cloudflare — antes de começar o Flutter**;
6. montar a Infraestrutura de Conteúdo: paths em `storage_paths.py`, manifestos, fluxo privado→público;
7. criar `easy_mobile_analytics_writer` e a abstração `track_event`;
8. **só então iniciar as telas em Flutter**;
9. implementar push;
10. montar o pipeline editorial da Newsletter (no Easy Web);
11. testes de segurança e de carga;
12. publicação na App Store e no Google Play.

---

# Princípio final

O Easy Mobile deve ser **simples para o usuário e deliberadamente rigoroso por trás**.

A Axys disponibiliza gratuitamente **acesso ao conhecimento**, mas preserva a infraestrutura, os parseamentos, a organização dos dados, as regras de negócio e o banco operacional.

O ativo de longo prazo não é o aplicativo. É a combinação de **base histórica estruturada + inteligência editorial + indicadores + estudos de caso + audiência recorrente + identidade Axys integrada**.

---

*Documento único e canônico do Easy Mobile. Compila e substitui o rascunho `easy_mobile_projeto.md` (13/08/2026) e o ADR `easy_mobile_adr_newsletter_r2.md`. Alterações futuras devem preservar as premissas congeladas ou registrar explicitamente a decisão que as substituiu.*




