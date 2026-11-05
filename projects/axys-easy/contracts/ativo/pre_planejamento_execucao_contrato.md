# Pré-planejamento de Execução — Contrato

**Status:** V1 em dev — fluxo completo em três passos, memorial e reconciliação. Ver §17.
**Data:** 2026-10-15, revisto em 2026-10-19 e 2026-11-02 (relações tipadas, ao longo da obra, formas de preencher, rascunho no banco)
**Escopo:** como o AxysEasy propõe o cronograma de uma obra a partir do orçamento, com método declarado e memorial auditável. Indicadores: **Δ** (regularidade da série) e **carga do mês**.
**Implementa (previsto):** `ativo.ativo_orcamento_cronograma`, `ativo.ativo_orcamento_cronograma_itens`, `backend/modules/ativo/cronograma_service.py`, `backend/modules/ativo/medicao_simulador.py`, `orcamento_service.get_histograma`.

> **Tese.** Hoje o engenheiro orçamentista preenche o cronograma à mão, item a item, e o resultado reflete o bom senso dele — que pode ser excelente e, ainda assim, é indefensável quando questionado, porque não tem método escrito. Este módulo troca o bom senso silencioso por um **método declarado**: a app propõe a distribuição, mostra de onde ela saiu e entrega o memorial. Para discordar do resultado, passa a ser preciso discordar do **critério** — que é exatamente a conversa que se quer ter.
>
> **Não é um planejador de obra.** É pré-planejamento: o que o orçamentista precisa para entregar um cronograma coerente, não o que a empreiteira precisa para tocar o canteiro.

---

## 1. Como se chegou aqui

Esta seção é o registro das premissas e das correções de rota. Ela existe porque daqui a seis meses ninguém lembra por que uma decisão foi tomada, e contrato sem motivo vira dogma.

**A hipótese inicial** foi: mão de obra é o gargalo da obra. Explodir as composições, apurar as horas de cada profissão, dimensionar equipes (1 pedreiro + 1 servente; 2 + 2) e daí tirar o prazo-base. Depois distribuir os serviços nesse prazo buscando homogeneidade de valor e de gente. O AxysEasy **já faz a explosão** — este módulo começa nos resultados dela.

**O primeiro desenho foi grande demais e foi recortado.** A proposta que chegou de volta tinha caminho crítico, rede de precedências completa (término-início, início-início, defasagem por cura), pacotes de trabalho por frente, nivelamento de recursos, NetworkX e OR-Tools. O recorte foi explícito: *"esse trabalho é mais de engenheiro orçamentista, e não de uma empreiteira de obra"*. Saíram da V1 o CPM, as precedências completas, a logística de canteiro e a produtividade de campo. Sobraram **duas amarras**: impeditivo e duração máxima.

**Três modos de entrada foram propostos e um deles quase se perdeu.** A primeira resposta oferecia: (A) tenho equipe, qual o prazo; (B) tenho prazo, quantas equipes; (C) qual o melhor equilíbrio. O recorte posterior guardou só o A. O modo C volta neste contrato porque é ele que sustenta a tese: comparar cenários e justificar é o que transforma a saída em argumento.

**Os pesos 6/3/1 nasceram e morreram.** A ideia era agrupar profissões (G1 pedreiro/servente, G2 eletricista/hidráulico, G3 demais) com pesos de predominância. Dois argumentos a derrubaram. O primeiro, técnico: uma composição que exige 1.000 horas de pedreiro exige 1.000 horas; multiplicar por 6 inventa 6.000. O segundo, de engenharia, e é o definitivo: **pedreiro e servente são o que mais tem e o mais fácil de repor; o gargalo real costuma ser a profissão rara**. Um peso fixo codifica volume fingindo que é escassez. A tripartição foi abandonada — não há schema para ela e não deve haver. O gargalo sai do dado, não da declaração.

**O 220 foi o erro mais caro, e ele já estava em produção.** Durante a discussão fixou-se "180 h/mês úteis" como capacidade. Ao conferir contra o código, descobriu-se que o histograma dividia a quantidade mensal de mão de obra por `JORNADA_H_MES` (220) para desenhar colaboradores/mês — e estava errado nos dois regimes. A correção veio antes deste contrato e está na §5.

**A posição mínima continua ambígua** e este contrato a fecha na §7, contra a inclinação da discussão original, pelo motivo que está lá.

---

## 2. O que já existe, e que este contrato não reinventa

| Peça | Onde | O que entrega |
|---|---|---|
| Árvore do orçamento | `ativo.ativo_orcamento_itens` (`ati_path`) | EAP com N níveis, valor e quantidade por item |
| Explosão de composições | `orcamento_service` | horas por função/insumo de cada serviço |
| Cronograma | `ativo.ativo_orcamento_cronograma` + `…_itens` | item-do-nível-de-corte × período → % do valor |
| Grade derivada | `cronograma_service.get_cronograma_grade` | valor por item e por período, já conciliado com o total |
| Histograma | `orcamento_service.get_histograma` | horas e colaboradores por mês, por função |
| Provisionador de medições | `medicao_simulador` | transforma % do nível em quantidade por item e devolve **o cronograma que isso realiza** |
| Identidade de MDO entre fontes | `catalogo.equivalencias_mo` (109 pares confirmados) | CDHU/FDE `PEDREIRO` → SINAPI `PEDREIRO` |
| Identidade de MDO entre regimes | `catalogo.composicoes_mapeamento_mdo` (94 pares) | `88309 (H)` ↔ `101445 (MES)` |

**A consequência é a mais importante deste contrato:** o motor de simulação **não desenha nada novo**. Ele propõe percentuais e pergunta às funções que já existem o que elas devolvem.

```
    propõe percents  ──►  get_cronograma_grade(percents=…)  ──►  valor por mês
            ▲                          │
            │                          ▼
            └──────────  get_histograma(grade=…)  ──►  horas e colaboradores por mês
                                       │
                                       ▼
                       Δ financeiro, Δ de mão de obra, carga do mês
```

`get_cronograma_grade` **já aceita** `percents` injetados — a costura foi aberta para o simulador de medições e serve igual aqui. `get_histograma` **já aceita** a `grade` pronta. O laço de otimização é essas duas chamadas dentro de um avaliador.

---

## 3. A unidade de planejamento é o nível de corte

O cronograma não é uma segunda árvore: é a projeção temporal da árvore do orçamento, **num nível de corte** (`cro_nivel_corte`). O grid é *item-do-nível × período*, e tudo abaixo do item de corte segue o padrão dele.

Isso decide, sem discussão, a pergunta que a especificação original deixou aberta ("qual é a unidade mínima do planejamento?"): **é o item do nível de corte**. O planejador não sequencia milhares de folhas; ele distribui as linhas que o cronograma já tem.

As horas de cada linha são a soma dos serviços descendentes — conta que o histograma já faz (`_etapa_id`: *"a linha do cronograma que governa o serviço é o GRUPO ancestral mais fundo com nível ≤ corte"*). Nada a reimplementar.

**Consequência para os parâmetros:** impeditivo, duração máxima, posição mínima e modo são atributos de **linha do cronograma**. Parâmetro sugerido para um item abaixo do corte é herdado pela linha que o governa; conflito entre descendentes da mesma linha resolve-se pela regra mais restritiva, e o memorial registra que houve conflito.

---

## 4. Fluxo e fronteiras

```
   orçamento ──► PRÉ-PLANEJADOR ──► curadoria ──► PROVISIONADOR DE MEDIÇÕES ──► CRONOGRAMA
                   (contínuo)       (engenheiro)      (realizável)              (gravado)
                                                                                    │
                                                            ┌───────────────────────┼───────────────┐
                                                            ▼                       ▼               ▼
                                                       histograma               medições        documentos
```

**O provisionador de medições entra ANTES de gravar, não depois.** Esta é a correção mais importante do fluxo, e ela vem do que o provisionador já é: ele *"resolve ao vivo e não escreve nada… entra cronograma + bancada, sai a planilha de medição por período"*, e devolve **"a planilha possível e o cronograma que ela realmente realiza"**.

A razão é física, não de arquitetura. O pré-planejador trabalha em percentual contínuo sobre o nível — "25% da etapa 1.5". Medir é virar isso em quantidade por item, e **não se mede 0,25 de uma caixa de derivação**. Um cronograma otimizado ao centésimo pode ser perfeitamente irrealizável, e descobrir isso depois de gravado é descobrir tarde. Então o percentual proposto passa pelo provisionador, que o reconcilia com as quantidades que de fato se medem — respeitando as três regras que ele já aplica: não fracionar o indivisível (`catalogo.unidades.un_categoria = 'unidade'`), convergir o total do nível em vez de ratear, e não usar quantidade inexpressiva para fechar conta (piso de 1% do item).

**O que se grava é o cronograma reconciliado**, não o proposto. E o desvio entre os dois é informação, não erro: ele entra no memorial, porque é a distância entre o ótimo matemático e o executável.

**A ordem é de mão única.** O pré-planejador escreve o cronograma **uma vez, na curadoria**, e nunca lê de volta o que ele mesmo escreveu para recalcular. Cada simulação parte do orçamento. É o mesmo cuidado que o código já carrega, pela mesma razão:

> *"o alvo continua sendo o cronograma COMO O USUÁRIO o definiu (o snapshot), não o que o próprio simulador escreveu — senão cada rodada miraria a anterior e a conta andaria sozinha, sem fim."*

Depois de gravado, o cronograma é a verdade da obra e dele derivam histograma, medições e documentos, como hoje.

---

## 5. O tempo: duas constantes que não se confundem

| Constante | Valor | O que é | Onde vive |
|---|---:|---|---|
| `JORNADA_H_MES` | 220 | Fator de **remuneração**: relaciona o salário-base horário ao mensal. É a constante que a CAIXA publica para converter regime | `catalogo.parametros_normativos`, as-of |
| `HORAS_UTEIS_MES` | 180 | Premissa de **produção**: converte horas de trabalho em gente no canteiro. Só o **último recurso** da fonte única `horas_uteis_obra` (§5.1) | `orcamento_service`, declarada na tela |

A fórmula oficial de conversão de regime é `custo mensalista = custo horista / (1 + ES_horista) × 220 × (1 + ES_mensalista)`, e o que atravessa a conversão é a remuneração-base. **O 220 não afirma que existam 220 horas produtivas no mês.** Usá-lo como fator de tempo produziu, no histograma, um mês com 9,89 MES de mão de obra — cerca de dez pessoas — desenhado como `0,04 colaborador`.

**A regra do efetivo sai da unidade**, porque o cronograma dilui por período e período é mês:

```
MES → a quantidade JÁ É gente-mês. 2 MES no mês são 2 colaboradores. Nada a dividir.
H   → horas de trabalho no mês ÷ horas úteis do mês.
```

Horista e mensalista convivem no mesmo ativo (a bancada roda o regime item a item): cada balde vira gente pela sua regra e os dois se somam. **A premissa é declarada onde o número aparece** — "Colaboradores por mês (horas ÷ 179,51 h úteis)", com o número da obra (§5.1) —, porque sem ela ninguém confere.

### 5.1 As horas úteis do mês não são uma constante

180 h/mês é **o último recurso**, não a premissa. Mês não tem todos o mesmo tamanho, e uma obra que começa em dezembro não tem a mesma capacidade de uma que começa em março. A cascata, em ordem de preferência:

| Nível | Fonte | O que entrega |
|---|---|---|
| 1 | **Calendário real.** A partir da data-alvo de início, contar os dias úteis de cada mês pelo calendário do MUNICÍPIO da obra — chaveado por código IBGE, que `catalogo.municipios.mun_id` já é. Fonte e persistência em [`conversao_mdo_bancada_contrato.md`](conversao_mdo_bancada_contrato.md) §4.3 | horas úteis por mês, específicas da obra |
| 2 | **Persistência local.** Guardar os feriados no banco, como se guarda o histórico de índices, e servir dali quando a API cair | o mesmo, sem depender da rede |
| 3 | **SINAPI, com férias repostas.** O livro publica 271,60 dias efetivos/ano para SP (Tabela 1.6) — mas eles descontam as férias, e férias se repõe. Devolvendo-as: 295,19 dias/ano = **180,39 h/mês** | média oficial corrigida, por UF |
| 4 | **180 h** | último recurso — e, por coincidência aritmética, o mesmo que o nível 3 dá em SP |

**Fonte única (2026-11-04).** Cronograma, histograma e pré-plano — régua (`avaliar`), nivelamento,
pergunta à IA, botões, provisão e memorial — leem as horas úteis de **uma** função,
`preplanejamento_service.horas_uteis_obra`. As premissas são as do pré-plano: município, início,
prazo e tipo de obra. O que a tela manda vem primeiro; o que faltar sai do rascunho do pré-plano, e o
prazo, da configuração do cronograma; o município do cadastro manda sobre os dois. Com município,
início e prazo, é o calendário do município; o tipo de obra acrescenta o desconto da chuva (a conta
avança a cada premissa informada). Faltando uma das três — cronograma montado à mão, sem pré-plano —
são **180 h fixas**, e o rótulo diz o que falta. **Horas informadas** pelo usuário (caixa "informar"
ao lado do valor, chave `hu_inf` do rascunho) mandam sobre tudo: a obra de jornada reduzida não cabe
em calendário nenhum. O pré-plano não
deixa faltar: o Continuar exige as quatro (§17.3). O início e o tipo de obra são do pré-plano, não
do cadastro: limpar o pré-plano os leva junto, e o cronograma volta às 180 h até novo pré-plano.

O nível 2 só entra se o dado for barato de guardar — feriado municipal é volumoso e muda. Se não for viável, o nível 3 assume o posto de primeiro fallback, e ele não é inferior por acaso: é a mesma referência que precifica a obra.

**As horas efetivas publicadas pela CAIXA não servem cruas, e a razão é de engenharia.** As 165,98 h/mês de SP descontam as férias (23,59 dias/ano). Férias se repõe: quando um colaborador sai, outro ocupa a vaga, a obra não para, e o custo das férias está no encargo social. O planejador conta **gente no canteiro**, não contrato-ano — descontar férias contaria uma ausência que o canteiro não sente. A reconciliação mostra que é só disso que se trata:

```
SINAPI/SP   271,60 dias efetivos/ano                       165,98 h/mês
  + férias (23,59 d, reposta)            295,19 dias/ano   180,39 h/mês
  + enfermidade, chuva, faltas, demais   304,20 dias/ano   185,90 h/mês
  calendário real de 2026 (SP, 44 h/sem)                   184,07 h/mês
```

O que **não** se repõe — chuva, falta justificada, doença, cerca de 5,5 h/mês — continua descontado em qualquer nível da cascata. E as 165,98 h têm o seu lugar, que não é este: é o rateio de encargo complementar, para o qual o livro as criou.

**Pendência registrada:** o nível 4 é inferência, e inferência não combina com um módulo que existe para ser defensável. Antes de fixar 180 como padrão, cabe um estudo técnico curto — qual é a jornada efetiva média no setor, o que as referências publicam, e qual número sustenta ser questionado. Até lá, 180 fica, declarado na tela e marcado no memorial como premissa não calibrada.

**Qualquer que seja o nível, a fonte é uma só para toda a app.** Hoje o histograma usa a constante; quando a cascata entrar, histograma e pré-planejador consomem o mesmo valor, ou a mesma obra mostra dois efetivos em duas telas — que foi exatamente o defeito que o 220 produziu.

### 5.2 A chuva, em quatro níveis

A chuva entra aqui e não na conversão de regime: ela é perda de produção, não de remuneração. Para o custo ela é neutra — o mensalista recebe igual, e a CAIXA tirou o `B7` do encargo dele dizendo que *"não há relação significativa entre as chuvas e os serviços prestados pelos trabalhadores mensalistas"*. Para o planejamento ela é a parada mais relevante que existe, e provavelmente a que mais vai descolar o cronograma da obra.

**Como a referência chega ao número.** *Cálculos e Parâmetros*, pág. 24, abre a memória inteira para São Paulo:

```
129 dias de chuva/ano            INMET, média de 10 anos, região de São Paulo
 × proporção de dias úteis    →  97,42 dias de chuva em dia útil
 × 20%   chuvas que caem de dia ou duram o bastante      (premissa IBEC)
 × 20%   atividades que exigem bom tempo, obra HABITACIONAL  (premissa IBEC)
 = 3,90 dias/ano    →  3,90 / 271,60 = 1,43%  (o B7 do horista)
```

Os 129 são medição. Os dois 20% são juízo técnico de terceiro, que a CAIXA adota, e é neles que mora quase toda a redução — de 97 para 3,90.

**O segundo fator é tipologia, e é onde o engenheiro sabe mais que a tabela.** Ele afirma que 80% dos serviços de uma obra habitacional seguem na chuva. Vale para alvenaria interna, instalação, revestimento. Não vale para terraplenagem, fundação ou cobertura. Medido em capacidade:

| tipologia | 2º fator | dias/ano | hora de produção (SP, 2026) |
|---|---:|---:|---:|
| habitacional (premissa IBEC) | 20% | 3,90 | 180,95 h/mês |
| vertical com estrutura exposta | 40% | 7,79 | 178,57 h/mês |
| infraestrutura / terraplenagem | 80% | 15,59 | 173,80 h/mês |

Quase 4% de capacidade entre a primeira linha e a terceira — meio mês de obra num cronograma de doze. Não é detalhe de premissa; é prazo.

**E o número da referência é da CAPITAL.** O livro é explícito: as localidades do SINAPI são *"as vinte e sete capitais estaduais e o Distrito Federal, onde o IBGE realiza coleta de preços"*. Uma obra em Fernandópolis orçada com `SP` carrega a chuva da região metropolitana de São Paulo. Não é defeito da app — é como a referência é construída —, mas o memorial **diz isso sempre**, inclusive quando ninguém mexeu em nada. Memorial que esconde a aproximação não é memorial.

**Os quatro níveis**, cada um opcional sobre o anterior e combináveis entre si:

| o usuário traz | a app faz | o memorial declara |
|---|---|---|
| nada | referência da capital da UF | *premissa da referência — capital da UF, não o município da obra* |
| **dias de chuva da região** + fonte + período | aplica a metodologia da CAIXA sobre o dado dele | *dado local, substituindo a referência da capital* |
| **tipologia** (o 2º fator) | troca os 20% de atividades que exigem bom tempo | *tipologia declarada: infraestrutura, 80%* |
| **dias de parada** diretos | só calcula | *parada informada pelo orçamentista* |

**Em uso hoje (2026-11-05): a referência e o percentual direto.** O passo 1 tem "Perdas por chuva" com
"Usar do SINAPI" marcado por padrão — mostra a perda da referência, ajustada ao tipo de obra.
Desmarcado, o percentual informado vale direto como redução das horas disponíveis (`chuva_inf`,
guardado no rascunho como as horas úteis informadas), o calendário e os feriados ficam, e o tipo de
obra deixa de entrar (só ajusta o índice da SINAPI) e de ser exigido. Horas úteis informadas mandam
sobre ela. O memorial diz: "utilizou-se a referência de X%, informada pelo responsável pelo
planejamento, sendo este o percentual aferido dos impactos das chuvas no cronograma do
empreendimento". Os níveis de dias de chuva da região e de tipologia livre seguem como desenho.

**O percentual direto não pede fonte (decisão de 2026-11-05).** Quem desmarca a referência sabe o que
está fazendo e anexa ao documento a origem do número; o memorial já diz que ele foi informado pelo
responsável pelo planejamento. A regra abaixo vale para o nível de dias de chuva da região, ainda não
implementado.

**Fonte e período são obrigatórios quando o dado é do usuário.** Sem eles, "143 dias" vale menos que os 129 da referência, porque tem cara de medição e é palpite. Com eles, vira o melhor dado do documento — e em obra pública isso é comum: quem vai a uma CAT, a uma Casa da Agricultura ou à defesa civil e traz a série do município está trazendo dado **melhor** que o da capital, não pior.

**O primeiro fator continua se aplicando sobre o dado local**, e a razão é que o usuário normalmente traz *dias com precipitação*, não *dias em que a obra parou* — e é exatamente isso que o fator traduz. Quem tiver diário de obra com paradas reais entra pelo último nível, e aí não há fator nenhum a aplicar.

**O campo nasce preenchido** com a referência e o rótulo dizendo de onde ela veio. Perguntar "quantos dias de chuva em dia útil na sua região?" com o campo vazio é pedir um número que quase ninguém tem — e campo vazio em memorial técnico se preenche com invenção. Pré-preenchido, ele se corrige; vazio, ele se chuta.

### 5.3 O manual de instrução

O módulo pede ao engenheiro premissas que ele **pode** conhecer mas raramente tem à mão — dias de chuva, tipologia, efetivo por profissão, prazo-alvo. Cada campo sem explicação vira um campo preenchido no chute, e chute num memorial técnico é pior do que premissa de referência, porque tem aparência de medição.

Então o módulo nasce com um **manual curto**, e ele é entregável, não documentação interna.

**O formato:** uma linha por dado, três colunas — *para que serve · onde conseguir · o que muda se mexer*. Objetivo, sem rodeio, sem explicar o que a tela faz. Exemplo da forma esperada:

> **Dias de chuva na região** — entra na capacidade de produção do mês, não no custo. Onde conseguir: CAT, Casa da Agricultura, defesa civil municipal, estação do INMET mais próxima; peça a série dos últimos dez anos. O que muda: mais dias de chuva alongam o prazo e reduzem o pico de equipe; a referência traz o número da capital da UF, que pode não ser o da sua obra.

**Onde vive:** fora da tela de execução, em ajuda opt-in — a tela não carrega texto explicando o que ela faz. O manual se abre quando o engenheiro pede, e acompanha o memorial quando o documento sai, porque quem lê o orçamento também precisa saber o que cada premissa significa.

**Quem escreve:** sai junto com cada campo, na mesma entrega. Campo que entra sem a sua linha de manual não entra — é a regra que impede o manual de nascer desatualizado.

### 5.4 A data-alvo

O cronograma é **abstrato**: períodos, não meses de calendário (`cro_periodo_dias`, default 30). Isso fica. O que entra é uma **data-alvo de início** (`cro_data_alvo`, opcional), e ela é o que torna o nível 1 possível: sem data não há feriado, não há dia útil, não há fevereiro diferente de março. Sem data-alvo, a cascata começa no nível 3.

---

## 6. Mão de obra: identidade, não família

O planejador trabalha com **profissões**, não com grupos. Antes de contar, ele unifica o que é a mesma profissão sob códigos diferentes, por dois eixos que já existem e são curados:

- **entre fontes** — `catalogo.equivalencias_mo`: o `PEDREIRO` da CDHU e o da FDE são o `PEDREIRO` da SINAPI;
- **entre regimes** — `catalogo.composicoes_mapeamento_mdo`: `88309 (H)` e `101445 (MES)` são o mesmo pedreiro.

Sem isso, um orçamento com duas fontes conta dois pedreiros diferentes e nenhum gargalo aparece.

### 6.1 O salto de vinculação

A correspondência H↔MÊS existe nativamente só dentro da SINAPI. Fora dela, chega-se ao mesmo lugar **em dois saltos**:

```
CDHU  B.01.000.010139 (PEDREIRO, H)
   │  salto 1 — equivalencias_mo (entre fontes, H → H)
   ▼
SINAPI 88309 (PEDREIRO, H)
   │  salto 2 — composicoes_mapeamento_mdo (entre regimes)
   ▼
SINAPI 101445 (PEDREIRO, MES)
```

Então a mão de obra de qualquer fonte tem leitura mensal, desde que o primeiro salto exista — e ele é curadoria, não inferência.

**Não havendo associação**, aplica-se o conceito da própria SINAPI: `q_mensalista = q_horista / 220`, que é a identidade publicada no livro de metodologia e a mesma que sustenta a conversão de regime. **A confirmar** antes de implementar: se o divisor nesse caso é de fato 220 ou se a referência de origem publica fator próprio. Enquanto não se confirmar, o memorial marca a linha como "equivalência por conceito", distinguindo-a das que vieram de par curado.

### 6.2 O que não se modela

Família ou substituibilidade (azulejista como "parente" do pedreiro). Isso é juízo de engenharia, varia por obra e por região, e declará-lo numa tabela seria fingir que é fato. O gargalo é **calculado**: a profissão com maior `horas ÷ capacidade` naquele cenário, seja ela pedreiro ou marmorista.

---

## 7. As amarras

| Parâmetro | Domínio | Semântica |
|---|---|---|
| `posicao_minima` | inteiro ≥ 1 | **Período absoluto** do cronograma. Primeiro período elegível para iniciar |
| `modo` | `sequencial` \| `intercalada` \| `aleatoria` | Padrão de ocupação dos períodos |
| `ao_longo` | booleano | A frente vai **ao longo da obra**: começa até o P2 e termina no último período (§7.1) |
| `relacoes` | lista de `{id, tipo}` | O que precede a frente, com o tipo da relação (§7.1) |
| `tmax_periodos` | inteiro ≥ 1 \| nulo | Máximo de períodos entre início e fim, **pausas incluídas**. Nulo em `ao_longo` |
| `origem` | `manual` \| `financeiro` \| `mao_de_obra` \| `ia` | Quem desenhou a janela por último (§17.4) |

`impeditivos` (lista de `ati_id`), o formato anterior a 02/11/2026, continua aceito e vale como
`relacoes` do tipo `so_depois`.

**Posição mínima é período absoluto, e isto fecha a pendência.** A discussão original inclinava para "etapa relativa", com o argumento de que permitiria recalcular o prazo sem invalidar a parametrização. O argumento é bom e perde para um fato: a app **não tem** o conceito de etapa executiva. O que ela tem é path e ordem, que organizam o orçamento e não declaram sequência de obra. Criar "etapa" seria inventar uma terceira estrutura para conviver com a EAP e com o cronograma. Período absoluto encaixa no que existe, e o custo — reparametrizar ao mudar o prazo — é real e pequeno: o memorial registra a posição e o recálculo é um clique.

**O par `posicao_minima` + `relacoes` É a sequência executiva.** Ele não a substitui nem a aproxima: ele é o único lugar onde ela passa a existir. A EAP *deveria* declará-la, e às vezes declara — mas com frequência não, seja porque quem montou não se deu ao trabalho, seja porque misturou serviço com etapa na mesma hierarquia. Uma EAP assim organiza o orçamento e não diz nada sobre a obra.

É por isso que a sequência **não se deriva** da EAP automaticamente. Derivar seria ler ordem visual como dependência, e uma EAP mal estruturada produziria um cronograma mal estruturado com cara de calculado. Quem preenche essa lacuna é a §10 — e é esse, não o preenchimento de campos, o trabalho principal da IA neste módulo.

**Os três modos**, com o padrão de ocupação:

| Modo | Padrão | Definição |
|---|---|---|
| Sequencial | `1,1,1,1` | Começou, só para quando terminar |
| Intercalada | `1,0,1,0,1` | Depois de iniciar, pula **exatamente um** período e retoma |
| Aleatória | `1,1,0,0,1` | Pausas e retomadas livres entre os períodos elegíveis |

"Aleatória" é nome de interface, não método: o motor escolhe deterministicamente. Havendo desempate por sorteio, a `seed` é persistida.

**A EAP organiza, não impede.** Itens na mesma posição podem andar juntos — estrutura, alvenaria, elétrica e hidráulica são o caso clássico. Impedimento só existe quando declarado.

**`tmax` conta períodos corridos, pausas incluídas.** Uma intercalada com três períodos ativos ocupa janela de cinco. Com `tmax=4`, isso é inviável e se declara: `TMAX_INCOMPATIVEL_COM_MODO`. O motor **não** troca o modo para caber.

### 7.1 Relações e "ao longo da obra" (2026-11-02)

"Só depois de" era a única relação, e presumia que uma frente só começa quando a anterior acaba.
Obra real não é assim: numa fundação de 60 dias, depois de uns 30 já há frente para alvenaria ou
estrutura. Por isso a relação ganhou tipo:

| Tipo | Regra | Exemplo |
|---|---|---|
| `so_depois` | começa no período seguinte ao **fim** da outra | cobertura só depois da estrutura |
| `ligeiramente_apos` | começa a partir do período seguinte ao **início** da outra | alvenaria ligeiramente após a estrutura |
| `concomitante` | começa **no mesmo período** que a outra; a duração de cada uma sai do tamanho de cada uma | impermeabilização com a cobertura |

O período é de 30 dias, e por isso "ligeiramente após" é sempre um período: menos que isso a grade
não representa. Só `so_depois` segura o fim do antecessor (é ele que tem sucessor esperando a
conclusão); as outras duas contam do início.

**Ao longo da obra é atributo, não relação.** Relação liga duas frentes ("A depois de B") e só existe
porque a outra existe. "Ao longo da obra" é da própria frente: ela começa cedo — até o P2 — e vai até
o fim, sem depender de ninguém. Instalações hidrossanitárias e elétricas são o caso clássico: a EAP as
põe depois da estrutura, mas a tubulação entra com a fundação. Escrevê-las como "concomitante com a
fundação" as prenderia a ela, e elas não dependem dela: acompanham a obra. O atributo combina com o
modo — "ao longo da obra" + "pode pausar" é a instalação que começa, para e volta.

---

## 8. Homogeneidade: o Δ da série e a carga do mês

Para a série mensal `Z`: `μ = ΣZ/T`, desvio-padrão populacional `s = √(Σ(Z−μ)²/T)`, e
`Δ = 100 s / μ`.

**Nada aqui se chama CV.** A sigla existe na estatística e é a mesma conta, mas em obra pública "CV" é currículo — e rótulo que precisa ser explicado antes de ser lido não serve num documento que vai a julgamento de edital.

Duas séries, dois Δ: **financeiro** (valor por mês, da grade) e **de mão de obra** (efetivo por mês, do histograma). O desvio-padrão cru `s` acompanha sempre, na unidade da série (R$ e colaboradores): é ele que o engenheiro reconhece. O Δ existe porque dividir pela média é o que torna obras comparáveis — R$ 100 mil de desvio pesam diferente numa obra de R$ 500 mil e numa de R$ 50 milhões.

A **carga do mês** é a leitura mensal das mesmas séries, como afastamento da média, com sinal:
`carga_m = 100 × (Z_m / μ − 1)`. Zero é a média, `+30%` é trinta por cento acima, `−25%` é vinte e cinco abaixo. Duas cargas independentes, financeira e de mão de obra.

O índice de base 100 que isto substitui dizia a mesma coisa e exigia saber, antes, que 100 era a média. Com sinal, lê-se sem legenda — e legenda é o que não existe quando outra pessoa abre o documento.

**Δ é global, carga é mensal** — e um Δ baixo esconde pico localizado, então registra-se também `max |Z_m/μ − 1|`. A homogeneidade do total de horas não substitui a checagem por profissão: um mês pode ter total regular e sobrecarregar eletricistas.

**Os limites de Δ são metas, não restrições.** Se a fundação é 30% do orçamento e ocupa o primeiro período, talvez não exista cronograma com Δ financeiro baixo. Nesse caso o sistema entrega o melhor viável, informa o Δ alcançado e **nomeia a restrição responsável**. Nunca distorce a sequência para produzir um gráfico bonito. O limite de partida é 20% para ambos, configurável e separado — valor de ensaio, não referência técnica.

**Por que a homogeneidade vale dinheiro:** um cronograma de Δ baixo permite combinar medições mensais fixas, em contrato comercial ou em edital, sem que nenhuma das partes esteja apostando. É boa prática antes de ser conveniência.

### 8.1 Prioridade das regras

```
conservação do valor da linha > impeditivos > posição mínima > modo e tmax >
capacidade informada > prazo global fixado > homogeneidade
```

Conflito entre restrições obrigatórias devolve **inviável** com a causa, não um cronograma aparentemente válido.

---

## 9. Os três modos de uso

| Modo | O engenheiro informa | O sistema responde |
|---|---|---|
| **A — tenho equipe** | efetivo por profissão | o prazo viável e o cronograma |
| **B — tenho prazo** | o prazo contratual | o efetivo necessário mês a mês, e onde ele é inviável |
| **C — qual o equilíbrio** | nada, ou uma faixa | cenários comparados, com prazo, efetivo de pico e os dois Δ |

O modo C é o que sustenta a tese do módulo. Exemplo do que ele entrega:

> *A execução em 10 períodos exige pico de 14 colaboradores no período 5. Em 11 períodos o pico cai para 11 e o Δ de mão de obra vai de 24% para 16%. A decisão depende do custo de permanência no canteiro e da disponibilidade de contratação.*

Isso é comparação, não promessa. O sistema não afirma economia nem prazo sem nova simulação.

---

## 10. A IA parametriza; ela não planeja

**O trabalho dela é declarar a sequência executiva que a EAP não declarou.** Essa é a tarefa, e o resto é consequência dela. Uma EAP bem feita já carrega a ordem da obra; muitas não carregam, porque misturam serviço com etapa ou foram montadas só para somar. Sem a sequência, o motor não tem o que respeitar e volta a distribuir por conta própria — que é exatamente o que este módulo existe para acabar. Preencher modo e duração máxima é a parte fácil; amarrar o que precede o quê é a parte que não dá para automatizar por regra.

A IA recebe a **planilha sintética** — código EAP, nível, descrição, agrupador/serviço, unidade, quantidade, valor — e, para as frentes do nível de corte, o peso e as **horas por profissão**. Não recebe composição, insumo, coeficiente nem id interno: o item é identificado pelo código da EAP.

**Implantado (2026-11-02), e mais estreito que o desenho abaixo.** A IA devolve só a *sequência*: por frente, `ao_longo_da_obra`, a `execucao` e as `relacoes` tipadas (§7.1), com `avisos`. **Não devolve janela, posição nem `tmax`**: as janelas saem do mesmo otimizador do "Distribuir pela EAP" (§17.4), com o peso financeiro × mão de obra que o engenheiro escolhe no modal. Assim a resposta da IA é medida pela mesma régua do resto da tela, e ela não precisa converter nada em percentual — o que o prompt abaixo já proibia ("não calcule cronograma"). Item desconhecido e relação que fecharia ciclo são descartados e contados num aviso. Prompt em `backend/modules/ativo/ativo_ia_requests.md`; serviço em `preplanejamento_ia_service.py`; modelo pela cadeia `EASY_IA_MODELO_PREPLAN`, e na falta dela a do CTC; o consumo é debitado em AxysCoins como as demais IAs.

**Superado em 2026-11-03 pela medição por serviço (§17.5).** Relação por frente não enxerga o que
a frente contém: "Dados e voz" ia cedo inteira ou tarde inteira, quando a obra põe o eletroduto
enterrado com a fundação e o cabeamento no fim. A IA passou a propor, serviço a serviço, as semanas
de execução — e com isso ela planeja o serviço no tempo, o que o título desta seção negava. O que se
mantém do mandato: ela não faz conta (semana vira percentual na app), não recebe composição nem id
interno, e as regras que o engenheiro declarou são duras.

O texto abaixo é o desenho original, mantido como referência do mandato.

```text
Você parametriza a execução de uma EAP de obra. Receberá ids, descrições,
quantidades, valores e horas por profissão de cada linha.

Retorne SOMENTE JSON válido: posição mínima, modo de execução, impeditivos,
duração máxima e origem=ia, por linha ou agrupador relevante.

Preserve os ids. Não invente serviços, quantitativos ou horas.
Ordem na EAP NÃO é dependência: itens da mesma posição podem andar juntos.
Sequencial = períodos ativos contínuos até concluir.
Intercalada = um período ativo, um de pausa, repetidamente.
Aleatória = pode pausar e retomar livremente.
Impeditivo exige conclusão integral antes do início.
Não calcule cronograma, caminho crítico ou curva financeira.
Sem efetivo informado, não afirme prazo: devolva tmax nulo e diga por quê.
Evite impedimentos circulares.

A ordem da EAP pode ou não refletir a sequência da obra: declare a sequência
que a execução exige, não a que a numeração sugere. Se a hierarquia misturar
serviço com etapa a ponto de impedir a leitura, diga isso num aviso em vez de
devolver impedimentos duvidosos.
```

A IA pode avisar que a EAP recebida não separa etapas de serviços, ou que o nível de corte do cronograma agrupa coisas que a obra executa em momentos diferentes. É um aviso ao engenheiro, não uma recusa: o módulo roda do mesmo jeito, e o memorial registra a ressalva.

**Sugestão de `tmax` é estimativa, nunca fato.** 9.000 horas de uma profissão são 50 colaboradores-mês: com dez, cinco meses; com cinco, dez meses. Sem efetivo de referência, horas não determinam prazo, e a IA deve poder responder `null` com um aviso em vez de inventar.

### 10.1 Dois canais: a IA da casa e a IA do cliente

| | **Interno** (Axys Inteligence) | **Externo** (a IA do próprio cliente) |
|---|---|---|
| Entrada | montada pela app, com ids internos | arquivo que o usuário leva e traz |
| Saída | devolvida direto ao motor | colada ou importada por ele |
| Identificação | ids internos reais | **chave opaca**, resolvida por consulta |
| Formato | JSON | CSV como primeira opção — o usuário abre no Excel, confere e corrige |

O canal externo **não expõe id interno nenhum** — não `ati_id`, não `ins_id`, não `cmp_id`, não id de composição, de insumo ou de edição. Ele leva uma chave opaca por linha, válida para aquela sessão de parametrização, e a app resolve a correspondência no banco ao importar. O custo é uma consulta a mais; se ela se mostrar pesada no tamanho real de orçamento, revisar — mas a ocultação não é negociável, e não por segurança apenas: id interno que sai da casa vira dependência de terceiro no dia em que alguém automatizar em cima dele, e aí a numeração interna não pode mais mudar sem quebrar quem está lá fora.

O formato do canal externo é decisão de usabilidade, não de engenharia. JSON é o que a IA devolve melhor; CSV é o que o engenheiro **abre, lê e corrige** sem ferramenta. Como esse arquivo passa pela mão dele — ele copia o prompt, cola na IA dele, salva o resultado e importa —, CSV tende a servir melhor. A decidir no protótipo, com JSON aceito nos dois casos.

**Sobre a percepção de velocidade.** O fluxo externo é naturalmente mais lento: tem a resolução de chave opaca e, principalmente, tem o minuto ou mais em que o usuário opera a IA dele. A comparação que ele fará não é do fluxo inteiro — é do que acontece **depois** de importar o arquivo, e aí o canal interno precisa ser rápido de verdade, não parecer.

**Não se acrescenta latência artificial.** A hipótese de somar 1–2 s ao canal externo foi levantada e descartada: latência fabricada é custo pago pelo usuário por uma percepção, e no dia em que for notada custa mais do que a comparação valia. A diferença honesta já existe e basta.

---

## 11. Contratos de dados

### 11.1 Parâmetros (entrada do motor)

```json
{
  "schema_version": "1.0",
  "atv_id": 26,
  "settings": {
    "modo_uso": "C",
    "periodos": 12,
    "data_alvo": "2027-03-01",
    "horas_uteis": {"origem": "calendario", "por_periodo": [168, 176, 184]},
    "delta_financeiro_max_pct": 20,
    "delta_mo_max_pct": 20,
    "efetivo_por_profissao": {"88309": 4, "88316": 4}
  },
  "linhas": [
    {"ati_id": 1402, "posicao_minima": 1, "modo": "sequencial",
     "impeditivos": [], "tmax_periodos": 2, "origem": "ia"}
  ]
}
```

`horas_uteis.origem` declara o nível da cascata da §5.1 (`calendario`, `persistido`, `sinapi`, `padrao`) e é por ele que o memorial sabe o que escrever. O efetivo é chaveado pelo **código do insumo de MDO**, já unificado pelas equivalências — não por nome de profissão, que não é chave.

### 11.2 Simulação (saída)

```json
{
  "schema_version": "1.0",
  "simulacao_id": "sim-001",
  "status": "viavel",
  "percents": {"1402": {"1": 40.0, "2": 60.0}},
  "percents_realizaveis": {"1402": {"1": 38.5, "2": 61.5}},
  "mensal": [
    {"periodo": 1, "valor": 20000.0, "horas": 400.0, "colaboradores": 2.22,
     "carga_financeira": -20, "carga_mo": -20}
  ],
  "metricas": {"delta_financeiro_pct": 20.0, "delta_mo_pct": 20.0,
               "s_financeiro": 4000.0, "s_mo": 0.44,
               "desvio_max_financeiro_pct": 20.0, "desvio_max_mo_pct": 20.0},
  "gargalo": {"codigo": "88309", "descricao": "PEDREIRO…", "periodos": 11.4},
  "avisos": [],
  "memorial": {"premissas": [], "etapas": [], "restricoes_ativas": []},
  "solver": {"metodo": "…", "seed": null, "otimalidade_provada": false}
}
```

Dois campos de percentual, de propósito: `percents` é o que o otimizador quis e `percents_realizaveis` é o que o provisionador de medições (§4) conseguiu realizar com quantidades inteiras. **A curadoria grava o segundo**, e a diferença entre eles vai para o memorial. Ambos saem no formato que `get_cronograma_grade` já consome.

Inviável: `status="inviavel"`, `percents={}`, `violacoes=[{codigo, ati_id, detalhe}]`. Não se produz cronograma de aparência válida.

---

## 12. O memorial de premissas e cálculos

É entregável de **primeira classe**, não anexo. É ele que troca "o engenheiro achou" por "o método diz", e é por ele que a proposta se defende num questionamento de edital.

O memorial declara, em ordem:

1. **as premissas** — horas úteis adotadas, **com o nível da cascata que as produziu** (§5.1) e a ressalva quando for o padrão não calibrado; a chuva, **com o nível, a fonte e o período** (§5.2) e sempre a ressalva de que a referência é da capital da UF; efetivo informado ou estimado; prazo imposto ou calculado; limites de Δ;
2. **a apuração** — horas por profissão, já unificadas pelas equivalências, com o que foi unificado explicitado (`CDHU B.01.000.010139 → SINAPI 88309 → 101445`) e com as linhas que caíram na equivalência por conceito (§6.1) marcadas como tal;
3. **a capacidade** — `T_p = horas ÷ (efetivo × horas úteis)` por profissão, e qual delas é o gargalo;
4. **as amarras aplicadas** — impeditivos, posições mínimas, modos e tmax, com a origem de cada um (`manual`, `eap`, `ia`) e os avisos que a IA tiver emitido sobre a EAP;
5. **o resultado** — distribuição por período, os dois Δ (com o desvio-padrão cru), as duas cargas mensais e o maior desvio;
6. **a reconciliação** — o desvio entre o percentual proposto e o realizável, e quais itens o provocaram;
7. **o que não foi atingido** — meta de Δ não alcançada, com a restrição responsável nomeada.

O memorial sai no papel da casa, pelo motor de documentos (`Relatorio` com escopo), como qualquer outra peça.

---

## 13. Caminho crítico: entregue, não prometido

O módulo pode derivar, dos impeditivos declarados, a cadeia mais longa e as folgas — e **exporta** em formato de planejamento (MS Project / XML), para quem quiser levar adiante em ferramenta própria.

O que ele **não faz** é se apresentar como planejamento executivo. Não há precedências parciais, nem início-início, nem defasagem, nem calendário de recursos. O export é um ponto de partida honesto; a tela não promete mais do que isso e não usa a palavra "planejamento" na interface.

---

## 14. Validações e critérios de aceite

| Código | O que exige |
|---|---|
| `VALOR_NAO_CONSERVADO` | Σ dos períodos de uma linha = 100% do valor dela, dentro da tolerância |
| `REFERENCIA_INVALIDA` | Impeditivo e parâmetro só apontam para `ati_id` existente |
| `IMPEDIMENTO_CIRCULAR` | Rejeitar A→B→A |
| `IMPEDIMENTO_VIOLADO` | Linha bloqueada só inicia após o predecessor concluir integralmente |
| `PARALELO_PERMITIDO` | Linhas sem impedimento entre si podem coexistir no mesmo período |
| `SEQUENCIAL_COM_BURACO` | Sequencial não pode ter pausa depois de iniciar |
| `INTERCALADA_FORA_DO_PADRAO` | Intercalada alterna ativo e pausa de um período |
| `TMAX_EXCEDIDO` | Janela início→fim, pausas incluídas, não supera `tmax` |
| `TMAX_INCOMPATIVEL_COM_MODO` | Modo que não cabe no `tmax` é recusado, não ajustado |
| `CAPACIDADE_EXCEDIDA` | Não exceder a capacidade informada por profissão |
| `META_DELTA_INALCANCAVEL` | Diagnóstico com a restrição nomeada, nunca adulteração |
| `UNIDADE_IGNORADA` | Efetivo calculado pela unidade da linha (H ÷ úteis; MES direto) |
| `HORAS_UTEIS_NAO_DECLARADAS` | A origem das horas úteis acompanha o resultado e o memorial |
| `CHUVA_SEM_ORIGEM` | Dia de chuva informado pelo usuário exige fonte e período da série |
| `CHUVA_CAPITAL_NAO_DITA` | Usando a referência, o memorial diz que o número é da capital da UF |
| `CAMPO_SEM_MANUAL` | Campo de premissa novo sem a sua linha no manual (§5.3) não entra |
| `RECONCILIACAO_NAO_APLICADA` | O cronograma gravado é o realizável, não o proposto |
| `IA_ID_INEXISTENTE` | JSON/CSV da IA não cria linha que não existe |
| `IA_ID_INTERNO_EXPOSTO` | O canal externo não carrega id interno nenhum (`ati_id`, `ins_id`, `cmp_id`…) |
| `ORCAMENTO_ALTERADO` | Parâmetros de orçamento revisado não se aplicam sem reconciliação |

**Cenários obrigatórios:** sequencial de 4 períodos; intercalada com 3 ativos em janela de 5; impedimento simples; duas linhas na mesma posição; ciclo; linha com valor e sem horas; linha com horas e sem valor; ativo só horista; ativo só mensalista; **ativo misto**; MDO de fonte sem par curado (equivalência por conceito); item indivisível que impede o percentual proposto; efetivo insuficiente; prazo imposto curto; Δ impossível; orçamento com muitas linhas.

---

## 15. O que permanece aberto

1. **Solver.** Heurística, CP-SAT ou MILP — decidir por benchmark no tamanho real de orçamento, não por preferência. Não alegar otimalidade sem prova.
2. **Horas úteis.** O estudo técnico da §5.1, e a decisão sobre persistir feriados no banco. Conferido em 16/10: o plano gratuito da FeriadosAPI cobre capitais; interior responde HTTP 403, logo o calendário municipal depende do plano pago. O INMET foi avaliado e descartado como fonte de chuva: a API não serve série histórica (204 para datas passadas) e corrigiria apenas o primeiro dos três fatores.
3. **O divisor da equivalência por conceito** (§6.1): confirmar se é 220 ou se a fonte de origem publica fator próprio.
4. **Efetivo estimado.** Informar só as profissões principais e estimar as demais, ou exigir por profissão quando ela for o gargalo. A segunda é mais correta e mais chata.
5. **Formato do canal externo** — CSV ou JSON — e o custo real da resolução de chave opaca.
6. **Períodos zerados** dentro do horizonte entram no Δ? Recomendação: **sim** — excluí-los maquia a homogeneidade.
7. **Herança de parâmetro** entre agrupador e linha, quando os dois têm `tmax`/impeditivo distintos. Regra proposta: a mais restritiva vence e o memorial registra o conflito.
8. **Limites de Δ padrão** — calibrar com orçamentos reais antes de fixar.
9. **Granularidade do arredondamento** dos percentuais gravados no cronograma.

---

## 16. Sequência de implementação

**V0 — o encaixe.** Provar o laço com o que já existe: receber `percents`, chamar `get_cronograma_grade` e `get_histograma`, calcular os dois Δ e as cargas mensais. Sem otimizador, sem IA, sem tela. Se este passo não fechar, nada do resto importa.

**V1 — a simulação determinística.** Amarras, modos, capacidade, distribuição, inviabilidades nomeadas, passagem pelo provisionador de medições e o memorial. Modo A e modo B.

**V2 — homogeneização e cenários.** Otimizar os dois Δ, modo C, comparação de cenários.

**V3 — o que só entra com demanda.** Caminho crítico e export, calendário real completo, liberação parcial, custos não proporcionais.

---

## 17. O que está implantado (2026-10-18)

Registro do que saiu do papel, para a próxima leitura não precisar adivinhar.

| Peça | Onde | Estado |
|---|---|---|
| Apuração de MO por linha | `preplanejamento_service.apurar` | pronta — pelas primitivas da curva ABC, nunca pelo histograma (ele já é a explosão amarrada ao cronograma: pedir-lhe as horas para propor os %s é circular) |
| Identidade de profissão | `familias_mo` | pronta — **a SINAPI é o eixo**, e nunca fecho transitivo: a curadoria é par a par, e fechá-la fundia SERVENTE com AJUDANTE ESPECIALIZADO por causa do `FDE 1.01.88`, que aponta para os dois |
| Associações de profissão | modal + PDF | prontas — o método à vista, porque acumular tudo na SINAPI muda quem é o gargalo |
| Δ e carga do mês | `avaliar` | prontos — §8 |
| Chuva | `chuva_referencia` | pronta — **B7 da SINAPI, já no banco**; não há parser de PDF a escrever (§17.1) |
| Horas úteis | `horas_uteis_obra` → `premissa_horas_uteis` | fonte única (§5.1): calendário do município (`catalogo.feriados`) com a chuva por cima; 180 h fixas sem as premissas |
| Distribuidor | `distribuir` | V1 pronto (§17.2) |
| Aplicar | `cronograma_service.aplicar_percents` | pronto — substituição em transação única |
| Amarras na tela | passo 2 do fluxo | prontas — posição mínima, execução, duração máxima e precedência por linha |
| Reconciliação pelo provisionador (§4) | `reconciliar` + `aplicar` | pronta — a proposta passa pelo provisionador ANTES de gravar |
| Memorial (§12) | `montar_memorial` + `gerar_memorial_pdf` | pronto — sete seções, reproduzível a partir das premissas |
| Persistência das premissas | `ativo.ativo_rascunhos` + `rascunho_service` | pronta (02/11) — §17.4 |
| Canal de IA (§10) | `preplanejamento_ia_service.sugerir` | interno pronto (02/11): a IA declara a sequência, o otimizador faz as janelas. Canal externo (§10.1) segue em aberto |
| Distribuir pela EAP | `otimizar_sequencia` | pronto (02/11) — §17.4 |

### 17.3 O fluxo da tela, em três passos

A tela não é um formulário só: é um caminho, e cada passo responde uma pergunta diferente.

1. **Premissas da obra** — município (destrava o calendário real), início sugerido em hoje+90d,
   prazo, tipo de obra e as horas úteis que saem disso. **As quatro são exigidas** para continuar;
   o tipo de obra não vem marcado, porque é escolha. O município do cadastro (do ativo ou, por
   herança, do empreendimento) vem travado. Sem ele, o usuário escolhe aqui e, ao continuar, um
   modal pergunta se grava também no cadastro — no ativo e/ou no empreendimento; nada vai em
   silêncio (`POST …/preplanejamento/municipio`, `service.gravar_municipio_obra`). No ativo de
   endereço vazio, o endereço do empreendimento é copiado junto: gravar só o município o tornaria
   "próprio" e esconderia, nos documentos, o resto do endereço herdado. A escada de efetivo médio por prazo (3 a 24 meses, de 3 em 3, e 36, 48 e 60 — o teto razoável de uma obra) é a ordem de
   grandeza com que ele dosa a escolha, e um clique nela escolhe o prazo.
2. **Sequência Executiva** — a timeline (§17.4): o nível do cronograma, a janela de cada frente e
   as relações entre elas. É aqui que a sequência executiva passa a existir, porque a EAP não a
   declara. A equipe por profissão foi para as premissas ("Alocação por função"), porque é lá que se
   decide o prazo.
3. **Proposta** — o que o método produziu, medido. Daqui se volta para ajustar, se baixa o memorial
   ou se aplica. Aplicar passa pelo provisionador antes de gravar.

**Linha do cronograma é GRUPO, e só grupo (revisto em 02/11).** Entre 19/10 e 02/11 o serviço que
estava no nível de corte também virava linha, para destravar a EAP mista (grupo com subgrupo E
serviços pendurados no mesmo nível). Isso enchia o cronograma de serviço solto — no nível 2, a
Fundação se abria nos seus serviços 3.1…3.7 —, e não é como se lê um cronograma: o serviço se
pendura no grupo acima e entra no valor dele. Voltou a regra original, e a EAP mista é tratada
onde sempre foi: `niveis_validos` não oferece o nível que deixaria serviço sem linha.

### 17.4 A Sequência Executiva: timeline, quatro formas de preencher, rascunho no banco (2026-11-02)

**A tela é uma timeline.** Uma linha por frente; a barra clara é a janela, a cheia é o que o motor
distribuiu nela. Arrasta-se a ponta para mudar início ou fim, o meio para deslocar, e clica-se na
linha vazia para criar a janela. A descrição abre a execução, o "ao longo da obra" e as relações;
as relações aparecem como setas. A cada mudança o motor redistribui e a linha de status remede.
Frente sem janela não recebe distribuição (`distribuir(..., so_declaradas=True)`), e a proposta
não se gera enquanto houver uma.

**Quatro formas de preencher:**

| Ação | O que faz |
|---|---|
| Limpar | grade vazia — o ponto de partida do desenho à mão, que não precisa de botão próprio |
| Distribuir pelo financeiro | cascata da EAP (`otimizar_sequencia`) dá a ordem; o nivelamento posiciona serviço a serviço com a duração da equipe, alvo = Δ financeiro (§17.10) |
| Distribuir pela mão de obra | o mesmo, alvo = **Δ por profissão** |
| AI \| Axys Intelligence | um modelo só: a IA dá a ordem, a app monta (§17.10) |

Ao entrar no passo sem rascunho válido para o prazo e as frentes, a grade chega VAZIA: preencher é
escolha do engenheiro — um dos botões, a IA ou o desenho à mão (decisão de 04/11; antes chegava
preenchida pelo financeiro). Trocar o nível refaz a grade do mesmo jeito que ela estava: a da IA
reagrupada, a de um botão pelo mesmo botão; a vazia ou desenhada à mão fica vazia.

**O otimizador.** Parte da cascata da EAP — cada frente com janela proporcional ao seu peso, na
ordem da planilha, com 25% do prazo de sobreposição — e faz busca local nas janelas (início, fim,
deslocamento), ficando com o que baixa o alvo. O mínimo trivial de qualquer Δ é "tudo em todos os
meses", então a busca é presa: a frente sem relação anda na ordem da EAP (não começa antes da
anterior) e não se afasta mais que a sobreposição do lugar que o peso lhe dá; as relações e o "ao
longo da obra" são respeitados; e o movimento se propaga pela cadeia de sucessores — quem ficou
para trás é empurrado só o necessário, quem estava colado é puxado junto. As relações, o modo e o
"ao longo da obra" já declarados se conservam: o otimizador só decide janelas.

**Δ por profissão.** "Distribuir pela mão de obra" quer cada profissão com efetivo constante, não o
total: dá para manter dez pessoas no canteiro trocando pedreiro por servente mês a mês. A régua
(`avaliar`) passou a medir também `delta_profissao_pct` — o Δ de cada profissão, ponderado pelas
horas dela —, e a linha de status mostra os três: Δ financeiro, Δ mão de obra (efetivo total) e Δ por
profissão.

Ativo 24, dez períodos, nível 1: pelo financeiro, Δ financeiro 2,99%; pela mão de obra, Δ por
profissão de 84% para 57%. A cascata fixa que precedeu o otimizador dava Δ financeiro de 13%.

**Rascunho no banco.** Premissas e sequência saíram do `localStorage` para
`ativo.ativo_rascunhos` — uma linha por (ativo, assunto), JSONB, gravar substitui. Ela é do ativo,
não do usuário: outra máquina ou outro usuário do tenant continua de onde parou, e vale a última
gravação. É cache de trabalho e some sozinho — quando fica parado mais de 30 dias (varrido na leitura,
sem job) e com o ativo (FK em cascata); aplicado, deixa de vencer e vira o registro do pré-plano
(abaixo). "Ao fechar a aba" não é gatilho: o
navegador não garante avisar. Rotas `GET`/`PUT /api/ativos/{id}/rascunho/{assunto}`; o assunto novo
entra no CHECK `ck_ras_assunto`. Migration `2026-11-02_ativo_rascunhos.sql`.

**Aplicar fecha o rascunho, não o apaga (2026-11-03).** Ele recebe a chave `aplicado` ({em, por}),
deixa de vencer e vira o registro do pré-plano. Com o cronograma preenchido e esse registro, a tela
reabre nos três passos só para leitura — premissas travadas, sem as ações da sequência nem o
aplicar; navega-se e baixa-se o memorial. Cronograma preenchido sem o registro (feito à mão) segue
no estado "já preenchido". Limpo o cronograma, o rascunho volta a ser de trabalho: a primeira
gravação da tela descarta `aplicado`.

### 17.5 AI | Axys Intelligence: a medição por serviço, com previsões (2026-11-03)

**O que a IA recebe.** Prazo em meses e em semanas (4 por mês); as frentes, com peso e as regras que
o engenheiro declarou (relações, ao longo da obra, execução); os subgrupos abaixo do corte, para
contexto; e cada serviço com frente, descrição, unidade, quantidade, valor e horas por função
(códigos F1, F2… com legenda, para não repetir o nome em cada serviço). Mais a prioridade financeiro ×
mão de obra do modal. Acima de 1.500 serviços vão os de maior valor.

**O que devolve.** Para cada serviço, `semanas: [primeira, última]`. Nada de percentual.

**O que a app faz.** O mês tem 4 semanas úteis, de 25% cada. O serviço se reparte igualmente pelas
suas semanas; o perfil da frente no mês é a soma dos seus serviços, pelo valor. O perfil vai na
amarra (`perfil` {período: peso}, mais `servicos` com o detalhe) e o distribuidor o usa como está,
sem redistribuir — a janela da frente é a que o perfil ocupa. Serviço sem resposta segue a janela da
própria frente; frente sem nenhum serviço respondido vai ao motor no prazo inteiro.

**A conversa: previsões, não rodadas.** Tudo o que é dado vai no pedido — planilha, regras, prazo e
o CALENDÁRIO da obra (mês de cada período, dias úteis e feriados em dia útil, do município e do
início das premissas). A conversa serve a uma coisa: a IA monta a medição e pede à app uma PREVISÃO
para balizar o ajuste — `prever_financeiro` (valor do mês, carga do mês em % da média, Δ) ou
`prever_profissoes` (efetivo de cada função mês a mês, carga, Δ por profissão, pico), ambas com a
janela de cada frente e as regras desobedecidas. Até 3 previsões por consulta; esgotadas, só resta
`entregar` (semanas por serviço, relações entre frentes, avisos). Na primeira chamada vão todos os
serviços; nas seguintes, só os que mudam — o não mencionado fica onde estava (a primeira versão,
em rodadas, tratava o não mencionado como "sem resposta", e a frente inteira caía no prazo todo,
8,33% por mês). Entrega que deixa mais da metade dos serviços sem semana falha, sem débito.

**O teto é duro.** O consumo mostrado no modal supõe o pior caso que a app permite (3 previsões e a
entrega, cada volta reenviando a conversa) e é LIMITE: antes de cada chamada a app confere se ela
cabe, reservando a entrega; não cabendo, força a entrega, e se nem ela couber encerra com a última
proposta medida. O débito é `min(consumo real, teto)`.

**API de respostas.** O modelo da casa (gpt-5.6-luna) só aceita ferramentas no chat com o raciocínio
desligado; a consulta usa `/v1/responses`, que aceita ferramentas com raciocínio. Os itens de
raciocínio e as chamadas voltam na entrada da volta seguinte.

**As relações da IA viram as setas.** Ela declara, por frente, a que libera o seu trabalho. Entra
como regra a relação que não repete uma do engenheiro, não fecha ciclo e é cumprida pela própria
medição. A que a medição não cumpre como declarada, mas cumpre num tipo mais brando, entra nesse tipo
(a IA pensa em semanas: "ligeiramente após" duas semanas depois cai no mesmo mês, que no cronograma é
concomitante); só cai a que nem concomitante cumpre, contada num aviso.

**Resposta por grupo.** O `item` pode ser o código de um grupo ou frente: vale para todos os serviços
dele não citados um a um, e o grupo mais fundo manda sobre o mais raso. Sem isso obra grande não cabe
numa resposta — no ativo 22 (778 serviços) a IA devolveu 179 e parou; com grupo, cobriu os 778.

**O custo, antes.** Ao abrir o modal a app monta a consulta sem chamá-la e mostra, num quadro, o
teto de AxysCoins e o saldo; sem saldo, o botão não libera. Depois, a linha de avisos diz o que se
consumiu ao lado do teto.
Durante a consulta o modal trava (sem fechar, sem duplo clique) e mostra a barra das gerações de PDF.

**A mesma pergunta não se paga duas vezes.** A consulta tem uma chave — o hash da planilha, das
regras, do prazo, do calendário, do peso, do prompt, das ferramentas e do modelo — e o resultado fica no rascunho, na
chave `ia` — só a mais recente. Repetir a pergunta reaplica o
guardado, sem chamar a IA nem debitar; o modal avisa antes. `ia` é do servidor: a tela grava o
rascunho e não a apaga. **Só vive enquanto o pré-plano é rascunho:** o Aplicar a apaga (o registro
já guarda a medição escolhida), e o Limpar com o pré-plano leva o rascunho inteiro (2026-11-04). Uma
consulta pesa ~7 KB; o motivo não é espaço, é não guardar lixo sem prazo.

**A regra declarada é dura.** A frente que ainda desobedece na entrega perde o perfil e
volta ao motor, que cumpre as relações por construção; repete-se até ninguém mais desobedecer, e
cada frente devolvida vira aviso.

**Mexer na frente devolve-a ao motor.** Arrastar a janela ou mudar execução/relações no painel apaga
o perfil daquela frente. "Distribuir pelo financeiro/mão de obra" apaga o de todas.

**O memorial** ganha a seção 4.1, "Medição por serviço": frente a frente, cada serviço com início e
fim em período e semana.

Ativo 24, doze períodos, Fernandópolis, peso 50/50: previsão do financeiro (Δ 29,1%), previsão das
profissões, entrega com Δ financeiro 19,95%; 16 relações aceitas; ~144 mil tokens de um teto de ~230
mil; 58 s. A lógica
construtiva veio certa (eletroduto enterrado de dados e voz no P2–P3, embutido no P5–P9, tomadas no
P11–P12; container do canteiro na obra inteira, placa em uma semana). A IA chega a uma curva em S,
longe dos 3% que o otimizador alcança por frente — e mais perto da obra real.

### 17.6 O trabalho da IA é do ativo, e o Aplicar é amarrado (2026-11-04)

**A medição da IA não depende do nível.** Ela é por serviço, e o serviço não muda com o nível do
cronograma — só a frente que o agrupa. A resposta da consulta traz a `medicao` (semanas por código de
serviço e relações por código de frente), que a tela guarda no rascunho (`medicao_ia`). Trocar o
nível com a grade vinda da IA chama `POST …/sequencia/ia/reagrupar`, que remonta a mesma medição nas
frentes do nível novo, sem consulta e sem custo. As relações seguem a frente: descendo de nível, cada
filha herda a relação da mãe (a predecessora vira a primeira filha dela para início-início, a última
para término-início); subindo, a relação vai para a mãe e some quando as duas pontas caem na mesma;
toda relação remontada passa de novo pelo crivo. O mês em R$ da provisão é idêntico em qualquer nível
(o vigia confere); a prévia difere em décimos de ponto percentual, do arredondamento do % da frente.
Limpar ou distribuir de outro jeito não apaga a `medicao_ia`.

**O Aplicar é amarrado: cronograma, provisão das medições e trava, numa transação.** Depois de
pré-planejado o fluxo se inverte — o cronograma e as medições derivam do pré-plano. `aplicar_proposta`
(medicao_cronograma.py), com as mesmas guardas do `aplicar_percents` (que segue servindo ao MCP):
  • a proposta vira o SNAPSHOT da provisão (o alvo que o simulador mira e para onde o Desfazer volta);
  • o simulador mede a proposta e o cronograma gravado é o que a provisão REALIZA — a reconciliação
    com o medível é a própria provisão;
  • a provisão fica em `ativo_orcamento_cronograma_medicoes` com `origem: "preplanejamento"` e, havendo
    medição da IA, `alvo_servico` {serviço: [R$ por mês]};
  • o cronograma trava;
  • o rascunho fecha (`aplicado` com `cro_id`, `cme_id`).
Reaplicar pela tela de medições conserva a origem e os alvos. Sem tabela nem coluna nova.

**O simulador ganha o modo por serviço.** Com `alvo_servico`, cada serviço segue a própria curva: a
fração acumulada do alvo vira quantidade acumulada, SEMPRE POR BAIXO — inteira na peça indivisível,
em centésimos no resto —, e no último mês da curva o serviço fecha inteiro. O acumulado medido nunca
passa do previsto, e todo serviço é medido dentro dos meses da IA (o vigia confere, serviço a
serviço). O serviço que a medição não trouxe anda no ritmo da frente. Medir contra o R$ (a primeira
versão) deixava lasca: o trunc de cada mês ficava um centavo abaixo de N peças.

**Pré-plano fechado.** Com o cronograma preenchido e o rascunho aplicado, a tela reabre nos três passos
só para leitura (§17.4).

**Caminho crítico.** `caminho_critico` (preplanejamento_service.py): a cadeia mais longa que termina
no último período em que cada elo é uma relação JUSTA — a frente começa exatamente quando a relação
com a predecessora deixa. Sem relação declarada, vazio. A tela do cronograma o destaca (`.cr-critico`,
só a barra lateral vermelha, com a legenda "Caminho crítico" acima da tabela — texto vermelho é da
linha que não fecha 100%) quando o cronograma veio de um pré-plano aplicado: relações do registro,
janelas do cronograma como está. O memorial o desenha no Gantt e no fluxograma.

**Ver Fluxograma / Ver Gráfico de Gantt** (passo 2, `POST …/preplanejamento/desenho/{gantt|fluxograma}`):
o mesmo desenho do memorial, sozinho, das mesmas premissas da tela — conferir a sequência antes do
resultado. Valem também no pré-plano fechado, que é só leitura.

### 17.7 Os dois documentos (2026-11-04)

**Memorial técnico** (`POST …/preplanejamento/memorial`, `preplanejamento_pdf.py` +
`preplanejamento_diagramas_pdf.py`), paisagem:
  1. Calendário e horas úteis — início, prazo, município, jornada; tabela mês a mês (dias úteis, horas
     úteis, feriados em dia útil) e o calendário da obra, um quadro por mês, feriado em destaque;
     a chuva em texto corrido.
  2. Mão de obra do orçamento — horas, efetivo médio no prazo, pico e mês do pico por profissão;
     equipe informada só quando há.
  3. Sequência executiva — de onde veio a sequência, quantas relações, o caminho crítico; Gantt das
     frentes (percentual do mês na barra, setas das relações, caminho crítico em vermelho, quebrado
     em blocos) e o fluxograma em rede (colunas = degraus de dependência).
  4. Distribuição resultante — tabela mensal, curva S e histograma; regularidade e incidência.
  5. Ajuste ao que é medível. 6. Ressalvas.
Texto de memorial: frase técnica e corrida, sem nota no meio do corpo.

**Provisão das medições** (`POST …/preplanejamento/provisao-pdf`): o PDF da tela de medições (Med 1
a Med N, um documento por medição — sem o cronograma ajustado: na provisão o previsto é o realizado),
alimentado pela proposta e pelo modo por
serviço, com cada medição listando só o que se mede no período (`provisao=True`). É o que o Aplicar
grava; antes dele, a prévia.

**Bateria de 2026-11-04** (IA com previsões × botões Distribuir; peso 50/50; Δ = desvio-padrão ÷ média):

| ativo | prazo | serviços | Distribuir financeiro Δfin | Distribuir MO Δprof | IA Δfin | IA Δprof | AXC cobrados |
|---|---|---|---|---|---|---|---|
| 36 | 3 m | 69 | 6,1% | 10,2% | 23,8% | 37,4% | 51 |
| 26 | 4 m | 174 | 1,1% | 63,4% | 21,6% | 64,4% | 80 |
| 24 | 12 m | 319 | 0,7% | 63,6% | 26,1% | 87,0% | 184 |
| 22 | 24 m | 778 | 0,8% | 28,7% | 52,9% | 79,2% | 291 |

A IA monta a medição com lógica de obra (curva em S, serviço no seu momento) e nivela pior que o
otimizador, que não tem lógica de obra. Na obra grande (22) o nivelamento dela é fraco (pico de 464
colaboradores contra 197–251 dos botões). Cada consulta: 37 a 62 s.

**Peça inteira (2026-11-04).** O serviço de unidade indivisível (`catalogo.unidades`, categoria
`unidade`) vai à IA com `inteira: true`, e é REGRA DURA do prompt: cada mês que ele ocupa recebe ao
menos uma peça. A previsão aponta os espalhados (`pecas_inteiras_espalhadas`); o que ainda vier
espalhado na entrega a app concentra no fim do período dado (`_concentra_pecas`), onde a medição o
poria de qualquer jeito. O percentual da frente reparte a peça inteira pelas PEÇAS de cada mês
(`_rateio`), não pelas semanas — o cronograma nasce igual ao que se mede. No ativo 24, o maior acerto
ao medível caiu de 44,32 para 3,35 pontos percentuais.

**Referências dos botões à IA — testado e DESCARTADO (2026-11-04).** Mandar à IA as duas
distribuições dos botões (financeiro e mão de obra, % por frente e mês, com Δ e pico) como ponto de
partida do equilíbrio PIOROU em todos os ativos, peso 50/50:

| ativo | sem referência Δfin / Δprof / pico | com referência Δfin / Δprof / pico | frentes em bloco (com) |
|---|---|---|---|
| 36 | 20,7% / 35,9% / 32 | 28,9% / 38,6% / 35 | 0/5 |
| 26 | 30,9% / 60,8% / 9 | 49,5% / 72,8% / 11 | 13/21 |
| 24 | 23,3% / 76,3% / 10 | 47,0% / 105,0% / 15 | 19/28 |
| 22 | 52,9% / 79,2% / 464 (bateria 04/11) | 54,1% / 104,4% / 666 | 83/85 |

Ela ancora na referência (no 22, 83 de 85 frentes em bloco) e não converge com as previsões. O
equilíbrio é conta, não julgamento: fica com a app (um "Nivelar" determinístico depois da IA).

**Gantt entre páginas.** A relação cuja predecessora está em outro bloco ganha o conector de página:
no bloco dela, a seta desce até a borda com "→ número"; no da frente, entra pela borda de cima com
"número →". Os rótulos de mesma posição se juntam numa faixa própria, fora das barras.

### 17.8 Dois fluxos, e como cada um se desfaz (2026-11-04)

O cronograma chega preenchido por um de dois caminhos, e a provisão das medições guarda qual
(`cme_medicoes.origem`):

1. **Simulador** (`origem` ausente ou `simulador`): bancada → cronograma preenchido → medições
   simuladas → afinadas → Aplicar ao cronograma. Na tela de medições, **Voltar ao anterior** devolve
   o cronograma ao estado de antes do Aplicar.
2. **Pré-planejamento** (`origem: preplanejamento`): o cronograma DERIVA da provisão. A tela de
   medições mostra a origem, com link para o pré-plano, e **não oferece Voltar ao anterior** — não há
   anterior; o servidor também recusa (`medicao_cronograma.voltar`).

**Limpar cronograma** (os dois fluxos): o cronograma volta ao estado de nunca montado — itens,
provisão, trava **e a configuração (prazo e nível)** saem juntos, e a tela pede prazo e nível de
novo. Sobrar o prazo antigo foi defeito: o pré-plano reabria com ele preenchido, quando o prazo é
premissa exigida dele (2026-11-04). O pré-plano é escolha do usuário, numa caixa do modal **marcada por padrão** ("Limpar
também o preenchimento do pré-planejamento", campo `preplano`): marcada, o rascunho sai inteiro,
consultas de IA junto; desmarcada, o rascunho só perde `aplicado` e o pré-plano reabre editável, com
o trabalho dele. O padrão é limpar:
um pré-plano preenchido, com os passos verdes, sobre um cronograma vazio dizia que havia trabalho
onde não havia (2026-11-04).

**Reiniciar pré-planejamento** (`POST …/preplanejamento/reiniciar`): o mesmo Limpar, sempre com o
pré-plano, oferecido na
tela do pré-plano. Só existe com o pré-plano aplicado, na linha dos três passos, à direita, atrás de
um modal.

**Consultas anteriores** (`GET …/preplanejamento/sequencia/ia/anteriores`): o modal da IA lista as
guardadas (a mais recente de cada modelo: data, prazo, nível, peso, AxysCoins pagos) e oferece **Reaplicar**
sem nova consulta — a medição é por serviço, então vale em qualquer nível; só o prazo tem de ser o
mesmo.

### 17.9 A IA dá as regras, a app nivela (2026-11-04)

Substitui a conversa de previsões de §17.5. As baterias mostraram que a IA tem lógica de obra e não
faz conta — nem com as distribuições dos botões na mão (§17.7). A divisão passou a ser:

- **A IA** (`consultar`, UMA chamada, ferramenta `entregar`): para cada serviço (ou grupo), a
  `janela` de obra possível — do mais cedo em que pode começar ao mais tarde em que pode terminar,
  NÃO o momento ideal — e o `diluir`; as relações entre frentes. A duração saiu em §17.10. O PRAZO é
  premissa do engenheiro, olhada antes de pedir (a escada de efetivo e o prazo mínimo do passo 1): a
  IA monta dentro dele, encurtando as repetições por igual, e não o questiona — cobrar para dizer
  "suba o prazo" não se faz (`prazo_sugerido_meses` saiu em 2026-11-04).
- **A app** (`nivelamento_service.nivelar`): posiciona cada serviço dentro da janela, com duração na
  faixa, pelo menor `peso·Δfin + (1−peso)·Δprof` — a mesma régua de `avaliar`. Relações (do
  engenheiro e da IA), ao longo da obra e peça inteira são duras; as regras endurecem por rodadas
  (`RODADAS`) para a busca não travar. Determinístico; menos de 3 s no ativo 22 (778 serviços).
- **O peso não vai à IA** e não entra na chave: mudar o peso renivela as regras guardadas, sem custo.
- **A medição guardada** tem `regras` (o que se pagou) e `semanas` niveladas com `peso_fin`. Trocar o
  nível reaproveita as semanas (provisão idêntica em todo nível); trocar o peso renivela.
- **Teto** = entrada + `max_output_tokens`; uma chamada, não passa.

**Bateria de 04/11, peso 50/50** (Δfin / Δprof / pico de efetivo):

| ativo | botões (melhor de cada) | IA com previsões (§17.7) | IA regras + nivelamento | tokens antes → agora |
|---|---|---|---|---|
| 36 | 6,1% / 10,2% / 28 | 20,7% / 35,9% / 32 | 17,9% / 23,7% / 31 | 51 mil → 12 mil |
| 26 | 1,1% / 63,4% / 8–10 | 30,9% / 60,8% / 9 | 0,7% / 32,9% / 7 | 115 mil → 27 mil |
| 24 | 1,35% / 65,5% / 9 | 23,3% / 76,3% / 10 | 0,74% / 53,6% / 9 | 138 mil → 44 mil |
| 22 | 0,8% / 28,7% / 197–251 | 52,9% / 79,2% / 464 | 9,7% / 30,3% / 190 | 291 mil → 96 mil |

**A variação entre consultas (F8, 04/11).** Medida com 5 consultas iguais por ativo (peso 50/50,
Δfin mín / mediana / máx):

| ativo | antes | só a regra do tempo (mesmas respostas, renivel.) | tudo (repetições + tempo + conferência) |
|---|---|---|---|
| 24 | 0,7 / 2,4 / 4,5% | igual (não tem serviço em MES) | 1,5 / 2,1 / 9,1% |
| 22 | 4,2 / 14,0 / 40,5% | 0,9 / 10,2 / 12,6% | 11,1 / 13,8 / 15,7% |

O que entrou, e por quê:
- ~~**Unidade de tempo manda na duração**~~ — **superado por §17.10**: quantidade em MES/DIA é
  informação, não duração (8 meses de engenheiro numa obra de 24 se diluem); a duração é da equipe.
- **Repetições lidas pela app** (`_repeticoes`): grupos irmãos com os mesmos serviços (≥ 70% em comum,
  3 ou mais) vão no pedido como `repeticoes` — no 22, 18 pavimentos (3.5–3.22, 46% da obra). A IA
  fica com o ciclo; a variância do 22 estreitou.
- **Conferência sem IA** (`_conferir`): esmagamento (faixa curta obrigada a carregar ≥ 1,6× a sua
  parte e > 10% da obra), mês sem serviço possível, resposta grossa, serviço sem regra. Só os GRAVES
  (esmagamento, mês sem serviço) pedem UMA correção, dentro do teto; a resposta grossa aparecia em
  toda consulta e corrigi-la dobrava o custo sem melhorar o resultado. O que sobra vira aviso.
- O teto mostrado passa a cobrir a correção (≈ 2× uma chamada); a consulta típica gasta uma.

A curadoria é do engenheiro (e do MCP).

### 17.10 A duração é da equipe; a ordem é da IA ou da EAP (2026-11-04)

Completa §17.9. A hipótese de origem (incidência, intensidade, recorrência e densidade sobre as horas
do orçamento) foi posta à prova nos seis ativos com cronograma em dev; o que dela ficou está aqui, e
o que não ficou, registrado no fim. O documento de origem não se guarda: este contrato é a verdade.

**Os indicadores** — sobre os serviços-folha fora da ALO, com as horas que a app já apura (`apurar`),
a profissão pela família (§6). `H(i,p)` horas da profissão p no serviço i; `H` o total da obra.

| Indicador | Conta | Pergunta | Papel no motor |
|---|---|---|---|
| Incidência | `H(p) ÷ H` | quanto do trabalho é dessa profissão | peso do Δ dela (já era: §17.9) |
| Recorrência | serviços com p ÷ serviços com horas | em quantos serviços ela aparece | reforça o peso: `H(p) × (0,5 + R(p))` — a disseminada é equipe permanente; o especialista entra e sai |
| Densidade | `V(i) ÷ Σp H(i,p)` (R$/h) | quanto vale o serviço por hora | consequência da regra da equipe: o elevador não se estica, porque não tem horas para isso |
| Intensidade | valor dos serviços em que p aparece | exposição financeira | fica no termômetro como leitura; não decide |

**A REGRA DA EQUIPE** (`nivelamento_service.duracao_pela_equipe`), em toda forma de preencher:

- **Tempo de trabalho** do serviço: `T = H(i,k) ÷ HU-mês`, em meses de UMA pessoa, onde `k` é a
  profissão-chave (a de mais horas no serviço) e HU-mês é a mesma hora útil da régua (`avaliar`) —
  mudou a jornada, muda junto.
- **Duração = T ÷ n**, com `n` pessoas, `1 ≤ n ≤ nmax`. Daí as duas regras duras:
  - *pouca hora não dura muito*: duração ≤ T (uma pessoa, tempo integral);
  - *muita hora não acaba curto*: duração ≥ T ÷ nmax.
- `nmax = ⌈efetivo necessário de k⌉`, com efetivo necessário = `H(k) ÷ HU-mês ÷ prazo` — o número
  que a tela mostra em **Alocação por função** para o prazo escolhido. É regra do back, não premissa:
  quem a governa é o PRAZO, que o usuário escolhe olhando a relação de efetivo por prazo e por função.
  Prazo curto sobe o teto sozinho (o efetivo necessário cresce), e com esse teto **todo serviço cabe
  no prazo**: as horas de um serviço não passam das da profissão na obra, então `T ÷ nmax ≤ prazo`.
- Serviço **sem horas** (equipamento, fornecimento) não tem regra de equipe: segue a janela que a
  ordem lhe dá.
- **Quantidade em MES ou DIA é informação, não duração** — o que manda é a complexidade da obra.
- A janela que a ordem dá e que não comporta a duração mínima cresce para comportá-la. Não há
  "prazo pela conta" por profissão: com `nmax` do efetivo necessário, a soma das horas de uma
  profissão sempre cabe no prazo; o prazo curto aparece na SEQUÊNCIA e no termômetro.

**AS TRÊS FORMAS** — todas posicionam SERVIÇO A SERVIÇO pelo nivelamento (§17.9), com a regra da
equipe; o que muda é de onde vem a ordem (a janela de cada serviço) e o peso:

| Forma | Ordem | Peso |
|---|---|---|
| Distribuir pelo financeiro | cascata da EAP (`otimizar_sequencia`) | 100% financeiro |
| Distribuir pela mão de obra | cascata da EAP | 100% mão de obra |
| AI \| Axys Intelligence | a IA dá SÓ a ordem (janela e relações); a app dosa a equipe pela permanência mínima e nivela pelo efetivo total (abaixo) | o do modal |

Antes, os botões esticavam a frente inteira pelo prazo dela: 23% a 100% do valor ficava mais longo
do que a equipe precisa — a curva lisa era física impossível.

**O MODELO COMBINADO, refeito (2026-11-04).** A medição mostrou que o teto ⌈efetivo necessário⌉ valia
por serviço e não por mês: com serviços da mesma profissão sobrepostos, a ativo 22 chegava a 21,9
ajudantes de carpinteiro com teto 6. Teto mensal duro não é a resposta — o pico não tem limite, tem
coerência. As regras:

- **Significância.** Profissão IMPORTANTE é a de mais de 1 mês útil na obra: dedicação exclusiva,
  premissa da empresa. As menores entram e saem quando a obra pede, sem limitar nada.
- **Permanência mínima** (`duracao_pela_permanencia`): quem entra numa profissão importante fica pelo
  menos o contrato de experiência. A equipe do serviço é n = ⌈horas ÷ (permanência × HU)⌉ — 800 h com
  180 h/mês e 45/45: 3 pessoas por 1,5 mês, a duração mínima; a máxima é a de uma pessoa ("entrou 3,
  fica 1,5 mês; depois pode reduzir"). As duas experiências — **45/45 (1,5 mês útil) e 30/90 (1,0)**
  — são montadas, e fica a melhor. Sem teto pelo prazo.
- **A régua é o EFETIVO TOTAL** (revisto em 04/11): a mão de obra deixa de ser medida pelo Δ de cada
  profissão e passa a ser a **oscilação do efetivo total** — variação total ÷ (2 × média) − 1: zero
  para o efetivo constante; na obra que sobe, fica e desce (o trapézio), o pico sobre a média; e
  cresce a cada vai-e-volta (sobe, cai, volta a subir). O Δ puniria a rampa natural de entrada e
  saída. A profissão sozinha oscilar não é defeito: a permanência mínima já segura a equipe.
- **O vai-e-volta da função** (`VAIVEM_PESO` = 0,25 da régua do total): de cada profissão importante
  cobra-se SÓ o vai-e-volta — variação total − 2 × pico, ÷ 2 × média —, zero para quem entra, fica e
  sai, mesmo em rampa. O pico não se cobra, que espalharia a função pela obra. Na UBS (consulta D):
  vai-e-volta somado das importantes 12,7 → 5,6 pessoas, oscilação do total 17,6% → 16,1%, Δfin
  5,6% → 6,4%; com 0,5 e 1,0 o total piora (22,7% e 24,1%). O que a obra não tem — servente no mês da
  fundação — nenhum nivelamento cria.
- **Financeiro com teto** (`TETO_FIN` = 50%): até ele, o Δ financeiro é da natureza da obra
  (acabamento vale mais e leva menos gente no mesmo tempo) e pesa só pelo peso escolhido; o que passa
  dele pesa dez vezes mais, e a montagem acima do teto perde para qualquer uma dentro dele.
- **Ordem de obra dentro da frente** (`_ordem_de_obra`, regra dura do nivelamento): o serviço cuja
  janela começa e termina mais tarde não começa antes do outro; com a MESMA janela, vale a ordem dos
  itens (fôrma, armação e concretagem do pilar, nessa ordem). A janela larga que contém a curta não
  ordena nada. Fora das frentes ao longo da obra.
- **O que vai à IA**: EAP, serviço, descrição e horas por função — sem valor, quantidade nem tempo de
  uma pessoa (a quantidade só na peça inteira). A IA dá a ordem.
- **Diluir** (`diluir`, por serviço ou grupo; o mais fundo manda): a IA marca `true` no que é mantido
  durante a obra — locação de contêiner, serviço ou equipamento pago por mês, entulho, consumo,
  vigilância, administração, equipamento de canteiro —, com a janela da obra inteira; a app dá a ele
  um perfil FIXO na janela (`_perfil_diluido`) e o tira do nivelamento — os outros se nivelam em volta
  (`nivelar(fixos=…)`). Pago por mês (UN·MÊS, M²·MÊS, MÊS): constante, o contêiner custa igual todo
  mês; o resto em sino (começa baixo, pico no meio, desce; σ = ¼ dos meses). `false` no que tem
  momento: mobilização no 1º mês, desmobilização no último, e o equipamento de uma TAREFA (a
  plataforma de um mês para uma pintura específica) na janela da tarefa — esse não se espalha.
- **Uma chamada só.** A IA dá a ordem; a conferência da app (sem IA, §17.9) pode devolvê-la uma vez
  para correção; a montagem é da app, com as duas experiências, e fica a de menor alvo (excesso
  sobre o teto financeiro; depois peso × Δ financeiro + (1 − peso) × oscilação do efetivo total).
  Nada vai ao usuário.

**Descartados no combinado (04/11, UBS Porte I, ativo 24, gpt-5.6-luna, duas consultas reais):**
- a **validação pela IA** — a montagem voltava à IA, que apontava janelas a corrigir. Piorou a obra
  todas as vezes: prendia serviço num mês só (laje 100% e alvenaria 79% no mês 5, pico de 16
  pessoas), espalhava a laje até o mês 8, e nunca aprovou; custava ~30 mil tokens e ~1 min por ciclo;
- a **ordem da EAP concorrendo** com a da IA: sem relações declaradas ela monta uma obra impossível
  (laje e alvenaria no mês 1, drywall nos meses 1–4, louças antes da pintura) e por isso parece mais
  regular — chegou a vencer. Fica só nos botões, que são a escolha explícita de quem não quer IA.

Efeito, na mesma ordem da IA (oscilação do efetivo total / Δ financeiro): consulta A 38,5% / 14,0% →
14,5% / 4,0%; consulta B (antes vencia a EAP, 52,5% / 6,1%) → 26,1% / 12,1%, com a sequência
construtiva da IA.

Medição na mesma ordem (EAP), peso 50%, antigo Δ × novo:

| Ativo | Oscilação | Vai-e-volta | Presença < 2 meses | Δ financeiro |
|---|---|---|---|---|
| 22 (24 meses) | 114% → 58–60% | 9 → 4–7 | 4 → 1–2 | 0,4% → 3,3–4,7% |
| 24 (10 meses) | 166% → 99–113% | 5 → 0 | 5 → 1 | 1,3% → 1,3–1,6% |
| 21 (4 meses) | 46% → 11–15% | 2 → 0 | 0 | 56% → 63–67% |

Fixar a duração em 1,5 mês (sem a faixa até uma pessoa) foi testado e descartado: na obra longa
espremia tudo em blocos curtos (ativo 22: Δ financeiro 0,4% → 46%, oscilação 114% → 152%).

**Um modelo só (2026-11-04).** O SIMPLIFICADO — a IA dando também a duração — saiu: perdeu em todos
os testes, nivelava pelo Δ por profissão (a régua que espalha a função) e não tinha `diluir`. As
consultas dele guardadas em rascunho não se reaplicam mais. O modal não oferece escolha: diz o que a
Axys Intelligence faz, o teto de AxysCoins e, em vermelho, que o valor é debitado sem volta.

**A IA lê no nível 5 (2026-11-05).** Qualquer que seja o nível da tela, a planilha vai à IA no nível
mais fundo que o cronograma aceita, até o 5 (`NIVEL_IA`, `nivel_da_ia` — o mesmo crivo que trava os
níveis na tela: nenhum serviço sem linha). Os níveis de cima derivam dele: a tela agrupa a resposta no
nível dela pelo `reagrupar`. As regras declaradas nas frentes da tela descem às frentes do nível da IA
(`_amarras_no_nivel`: a predecessora vira a primeira descendente dela, a última no "só depois"). Trocar
o nível da tela nunca pede consulta nova — a pergunta é a mesma.

**Exportar MS Project (2026-11-05).** Rodapé de Resultados: o XML do Project (MSPDI), para editar lá —
abre no Project, no ProjectLibre e no GanttProject, e é o único formato que leva as predecessoras sem
assistente de importação (planilha e CSV não levam). Vão a árvore da EAP (grupos como tarefas-resumo),
as datas pelo calendário da obra (feriados do município como exceções, 8,8 h/dia), as relações ("só
depois" → término-início; "concomitante" → início-início; "ligeiramente após" → início-início com 5
dias de defasagem), o valor da linha como custo fixo e a distribuição mensal na nota. As tarefas vão
MANUAIS: o Project abre com as datas do pré-plano, sem recalculá-las pelas ligações. XLSX não entra:
o cronograma já exporta a mesma planilha.

**A ordem é garantida: nenhuma inversão (2026-11-05).** O nivelamento é busca local — move um serviço por
vez — e a relação cobrada só pelo início da frente o deixava empacar com a sucessora antes da
predecessora (ativo 24: vigas no mês 2, pilares no 5; inversões também no 22 e no 26, que ninguém via).
Agora, em três camadas: (1) o nivelamento cobra, além do tipo declarado pela frente, o PISO por
serviço — nenhum serviço da sucessora começa antes do início da predecessora; (2) a inversão que
sobrar aperta a janela dos serviços sucessores e o nivelamento roda de novo (`RODADAS_ORDEM`),
reequilibrando já dentro da ordem; (3) por último, depois da peça inteira, a trava empurra a sucessora
para o mês em que a predecessora começa (`_impoe_relacoes`), e a frente sem serviço medido também começa
ali. O TIPO declarado ("ligeiramente após", "só depois") segue como regra forte do nivelamento, não como
trava: a IA pensa em semanas, e numa obra de 3 ou 4 meses a cadeia pilar → viga → laje → telhado não
cabe em "um mês depois" a cada elo — apertá-lo espremia a obra (ativo 36: Δfin 28% → 63%). Medido nos
ativos 22, 24, 26 e 36: zero inversões, com Δfin e oscilação iguais ou melhores (24: 15,7% → 7,6%).

**O caminho crítico é o dominante (2026-11-05).** Da frente que termina a obra volta-se sempre pela
predecessora que mais a prende (menor folga), até uma sem predecessora. Antes eram só as relações justas,
e num cronograma nivelado a cadeia quebrava no meio (ativo 24: "10.1 → 10.2 → 15.3"). Se a cadeia não
chega à origem, ela parte do primeiro item da EAP que não seja ALO. Entre as que chegam, vence a mais
longa; a frente que ocupa a obra inteira (canteiro, contêiner) não é fim de caminho — no ativo 22,
"2.1 → 2.3 contêineres" ganhava das vigas e lajes pavimento a pavimento. No Gantt o caminho fica só nas
setas (nome e barra em azul, as demais setas em cinza); quem destaca as frentes é o fluxograma, que
pagina por blocos de colunas em vez de encolher a caixa (36 meses, ~60 degraus: 5 páginas legíveis).

**A consulta é única por pré-plano (2026-11-05).** O modal tem duas fases. Antes da consulta: o
que a Axys Intelligence faz, o teto em AxysCoins e, num segundo quadro em vermelho, que o débito não
tem volta; Cancelar e Solicitar no meio do modal; sem régua. Ao voltar, o resultado preenche a grade
da Sequência e o modal fica, agora com o LOG da consulta (quando, quem, prazo, nível, AxysCoins,
tempo, serviços, relações e diluídos — sem os avisos da IA), a régua "Mais regular em" e um quadro
dizendo que ela se altera e se aplica livremente, sem custo. A régua renivela na hora; o nível
reagrupa sozinho. Outra pergunta é recusada (409): consultar de novo pede EXCLUIR a consulta — na
linha do log, com confirmação ali mesmo —, o que vai ao log (DELETE) e não devolve AxysCoins. O
PRAZO fica preso à consulta (a tela trava o campo e a escada; o servidor recusa outro prazo) até
ela ser excluída. Consultas de antes deste desenho (sem log) não prendem nada.

**A cobrança vai ao log.** Toda consulta que chama a IA grava em `audit.logs` (`ativo.ativo_rascunhos`,
INSERT, registro = o ativo): quem pediu, o IP, a chave, o prazo, os tokens (entrada, saída, total,
teto e cobrados), o teto em AxysCoins que o modal mostrou, o aviso exibido (o mesmo texto da tela,
`AVISO_DEBITO_IA`) e o debitado. O schema `ativo` não tem critério de retenção: o registro não sai na
limpeza.

**O termômetro** mostra também o **Δ na presença** (o Δ de cada profissão só nos meses em que ela
está em obra) e avisa quando o Δ alto vem do **porte** (profissão-chave com até 2 pessoas: uma a mais
ou a menos já é 50%). Esse Δ é da natureza da obra; não se persegue.

**A prova (04/11, peso 50/50, Δfin / Δprof; "esticado" = % do valor além do que a equipe permite).**
Nos ativos 24 e 26, mediana de 3 consultas por variante; nos demais, uma.

| ativo | IA de hoje (§17.9) | cascata EAP + equipe | IA + equipe | IA só ordem + equipe | melhor botão antigo |
|---|---|---|---|---|---|
| 22 | 45,9 / 87,5 (13%) | 1,1 / 40,1 | 40,7 / 88,7 | **2,6 / 30,5** | 25,6 / 28,7 (23%) |
| 36 | 17,9 / 23,7 (7%) | 1,5 / 15,2 | 17,6 / 23,8 | **3,2 / 13,4** | 7,1 / 10,2 (23%) |
| 25 | 47,2 / 49,6 (47%) | **0,9 / 12,6** | 48,4 / 53,6 | 8,4 / 24,8 | 0 / 0 (100%) |
| 24 | 0,7 / 65,6 (53–58%) | 2,0 / 80,3 | **1,5 / 66,8** | 5,5 / 70,3 | 1,4 / 97,2 (95%) |
| 26 | 14,8 / 49,3 (22–41%) | 9,9 / 66,5 | 19,4 / 52,6 | 27,2 / 49,2 | 1,1 / 74,3 (66%) |
| 21 | 34,2 / 62,1 (43%) | 55,6 / 29,6 | 33,8 / 63,8 | 34,2 / 64,5 | 20,5 / 14,9 (100%) |

Leitura: com a regra da equipe nada se estica e o Δ quase não paga por isso — os Δ baixos da IA de
hoje vinham de esticar serviço e de sorte de rodada (no 26, 0,3 / 14,8 / 26,3 de Δfin em três
consultas iguais). Só ordem e ordem com duração empatam onde se repetiu; a ordem pura ganha folgado
no 22 e no 36 e segue a doutrina (a IA julga a obra, a app faz a conta). A cascata da EAP com a
equipe, grátis e determinística, é a melhor ou perto dela em 4 de 6 — por isso o modelo combinado a
calcula sempre, e a variação da IA não derruba o resultado. No 21 (13 serviços, 2,8 pessoas em
média) nenhum método honesto alisa: é o porte.

**Testado e descartado:**
- a **matriz incidência × intensidade** por frente (continuidade / regularidade / concentrada /
  acomodar) ajustando a faixa de duração: não ajudou, e o limiar de "alta" não se sustentou (quase
  tudo caía em "acomodar");
- o **Δ na presença como alvo do nivelamento**: não mudou nada, e piorou o Δprof do 24 (85–97%);
  fica só como leitura;
- a **duração dada pela IA** no modelo combinado: empatou com a ordem pura, custa o mesmo e põe a
  conta na IA;
- faixas de equipe arbitradas (1 pessoa a meio período / 6 pessoas): trocadas pela relação T ÷ n;
- o **FATOR de equipe** sobre o efetivo médio (`nmax = ⌈FATOR × efetivo⌉`, premissa da tela, padrão
  2): a varredura de 04/11 nos 6 ativos de dev, no prazo de cada um, deu o mesmo resultado de 1 a 4
  (no 22, o maior, o 1 foi o melhor) — o arredondamento para cima e o prazo já fazem o trabalho. Saiu
  da tela e do código; o teto é o efetivo necessário (fator 1);
- **sugerir o prazo pela regularidade**: com a regra da equipe, o Δ melhora quanto MAIS CURTO o prazo
  (prazo longo deixa meses vazios, porque o serviço não se estica) — ele apontaria sempre o mínimo,
  com efetivo absurdo (no 22, 1.922 pessoas em 2 meses). O que limita a compressão é físico (gente no
  canteiro), e a tela já mostra o efetivo por prazo e por função: o prazo é decisão do usuário.

### 17.1 A chuva não precisa de parser

*Cálculos e Parâmetros* publica **um** número — 129 dias/ano, região de São Paulo. O que varia por UF é
o encargo **`B7 — Dias de Chuvas`**, que o import de Leis Sociais já carrega: 27 UFs por edição, em
`catalogo.edicoes_leis_sociais_itens`. SP dá 1,43%, idêntico ao livro.

E a conta sai da própria definição: `B7 = dias de parada ÷ dias efetivos`, logo **B7 é a fração do
tempo produtivo que a chuva leva**, e `horas × (1 − B7/100)` basta. Conferido: B7 é idêntico em SD e
CD nas 675 combinações UF × edição — é item de produtividade, não de tributo.

**Sempre da SINAPI**, qualquer que seja a fonte do orçamento. A CDHU não publica a rubrica e a FDE
publica zerada, e zero ali não é "não chove": é "esta tabela não trata disso". Chuva é fato do
**lugar**, não da tabela de preços — a obra em Belém perde os mesmos dias orçada pela CDHU.

### 17.2 A doutrina do distribuidor

Sete decisões, cada uma paga com um defeito observado:

1. **Duração vem da mão de obra**, `horas ÷ (gente × horas úteis)` — nunca do valor da linha. A
   fundação não dura doze meses porque vale 30%.
2. **Cada linha se espalha pela janela que as amarras deixam.** Correndo na capacidade máxima, a
   obra acabava no oitavo de dez meses e o Δ ia a 73%.
3. **Sem amarra declarada, a proposta sai nivelada** — e isso é a resposta certa, não recusa: é o
   §7 em código, porque a EAP organiza e não impede.
4. **Quem segura alguém não se alonga.** Linha com sucessor anda no mínimo; espalhada, ela comia a
   capacidade exatamente nos meses em que a sucessora era obrigada a acontecer.
5. **Janelas por duas passagens** sobre a cadeia de impedimentos (cedo na ida, tarde na volta),
   estilo CPM enxuto.
6. **Ordem de colocação: menor folga primeiro**, não a da EAP. A linha livre se acomoda no que
   sobra; a amarrada, não.
7. **A inviabilidade diz o que falta, e diz algo estável:** o que a linha exige sozinha na janela
   que lhe resta (`horas ÷ (h úteis × janela)`). A primeira versão media a folga residual, e esse
   número andava quando a equipe mudava — somar uma pessoa fazia o alerta pedir duas.

Medido no ativo 24, dez períodos: sem amarra, Δ 11,68% financeiro e 12,76% de mão de obra. Com a
cadeia `3.0 → 4.0 → 5.0`, sai sequência executiva de verdade (P1 / P2-5 / P6-8) e o Δ sobe para
~21% — impor sequência custa homogeneidade, como a §8 já previa.

---

## Limite deste contrato

A proporcionalidade quantidade → valor → horas é **hipótese de modelagem**: distribuir 40% da quantidade num período distribui 40% do material junto, e material não entra assim na obra. Custos de mobilização e compras antecipadas não são capturados. **A curva de valor orçado não é fluxo de caixa**, e a tela precisa dizer isso onde a curva aparece — não só aqui.
