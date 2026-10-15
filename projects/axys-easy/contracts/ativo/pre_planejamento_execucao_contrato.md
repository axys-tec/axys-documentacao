# Pré-planejamento de Execução — Contrato

**Status:** Especificação para implementação. Não implantado.
**Data:** 2026-10-15
**Escopo:** como o AxysEasy propõe o cronograma de uma obra a partir do orçamento, com método
declarado e memorial auditável. Indicador: **Termômetro de Execução Axys™**.
**Implementa (previsto):** `ativo.ativo_orcamento_cronograma`, `ativo.ativo_orcamento_cronograma_itens`,
`backend/modules/ativo/cronograma_service.py`, `orcamento_service.get_histograma`.

> **Tese.** Hoje o engenheiro orçamentista preenche o cronograma à mão, item a item, e o
> resultado reflete o bom senso dele — que pode ser excelente e, ainda assim, é indefensável
> quando questionado, porque não tem método escrito. Este módulo troca o bom senso silencioso
> por um **método declarado**: a app propõe a distribuição, mostra de onde ela saiu e entrega o
> memorial. Para discordar do resultado, passa a ser preciso discordar do **critério** — que é
> exatamente a conversa que se quer ter.
>
> **Não é um planejador de obra.** É pré-planejamento: o que o orçamentista precisa para
> entregar um cronograma coerente, não o que a empreiteira precisa para tocar o canteiro.

---

## 1. Como se chegou aqui

Esta seção é o registro das premissas e das correções de rota. Ela existe porque daqui a seis
meses ninguém lembra por que uma decisão foi tomada, e contrato sem motivo vira dogma.

**A hipótese inicial** foi: mão de obra é o gargalo da obra. Explodir as composições, apurar as
horas de cada profissão, dimensionar equipes (1 pedreiro + 1 servente; 2 + 2) e daí tirar o
prazo-base. Depois distribuir os serviços nesse prazo buscando homogeneidade de valor e de
gente. O AxysEasy **já faz a explosão** — este módulo começa nos resultados dela.

**O primeiro desenho foi grande demais e foi recortado.** A proposta que chegou de volta tinha
caminho crítico, rede de precedências completa (término-início, início-início, defasagem por
cura), pacotes de trabalho por frente, nivelamento de recursos, NetworkX e OR-Tools. O recorte
foi explícito: *"esse trabalho é mais de engenheiro orçamentista, e não de uma empreiteira de
obra"*. Saíram da V1 o CPM, as precedências completas, a logística de canteiro e a produtividade
de campo. Sobraram **duas amarras**: impeditivo e duração máxima.

**Três modos de entrada foram propostos e um deles quase se perdeu.** A primeira resposta
oferecia: (A) tenho equipe, qual o prazo; (B) tenho prazo, quantas equipes; (C) qual o melhor
equilíbrio. O recorte posterior guardou só o A. O modo C volta neste contrato porque é ele que
sustenta a tese: comparar cenários e justificar é o que transforma a saída em argumento.

**Os pesos 6/3/1 nasceram e morreram.** A ideia era agrupar profissões (G1 pedreiro/servente,
G2 eletricista/hidráulico, G3 demais) com pesos de predominância. Dois argumentos a derrubaram.
O primeiro, técnico: uma composição que exige 1.000 horas de pedreiro exige 1.000 horas;
multiplicar por 6 inventa 6.000. O segundo, de engenharia, e é o definitivo: **pedreiro e
servente são o que mais tem e o mais fácil de repor; o gargalo real costuma ser a profissão
rara**. Um peso fixo codifica volume fingindo que é escassez. A tripartição foi abandonada —
não há schema para ela e não deve haver. O gargalo sai do dado, não da declaração.

**O 220 foi o erro mais caro, e ele já estava em produção.** Durante a discussão fixou-se "180
h/mês úteis" como capacidade. Ao conferir contra o código, descobriu-se que o histograma dividia
a quantidade mensal de mão de obra por `JORNADA_H_MES` (220) para desenhar colaboradores/mês —
e estava errado nos dois regimes. A correção veio antes deste contrato e está na §5.

**A posição mínima continua ambígua** e este contrato a fecha na §7, contra a inclinação da
discussão original, pelo motivo que está lá.

---

## 2. O que já existe, e que este contrato não reinventa

| Peça | Onde | O que entrega |
|---|---|---|
| Árvore do orçamento | `ativo.ativo_orcamento_itens` (`ati_path`) | EAP com N níveis, valor e quantidade por item |
| Explosão de composições | `orcamento_service` | horas por função/insumo de cada serviço |
| Cronograma | `ativo.ativo_orcamento_cronograma` + `…_cronograma_itens` | item-do-nível-de-corte × período → % do valor |
| Grade derivada | `cronograma_service.get_cronograma_grade` | valor por item e por período, já conciliado com o total |
| Histograma | `orcamento_service.get_histograma` | horas e colaboradores por mês, por função |
| Medições | `cronograma_service` + `…_cronograma_medicoes` | valida os % do cronograma contra os itens |
| Identidade de MDO entre fontes | `catalogo.equivalencias_mo` | CDHU/FDE `PEDREIRO` → SINAPI `PEDREIRO` |
| Identidade de MDO entre regimes | `catalogo.composicoes_mapeamento_mdo` | `88309 (H)` ↔ `101445 (MES)` |

**A consequência é a mais importante deste contrato:** o motor de simulação **não desenha nada
novo**. Ele propõe percentuais e pergunta às funções que já existem o que elas devolvem.

```
    propõe percents  ──►  get_cronograma_grade(percents=…)  ──►  valor por mês
            ▲                          │
            │                          ▼
            └──────────  get_histograma(grade=…)  ──►  horas e colaboradores por mês
                                       │
                                       ▼
                         CV financeiro, CV de mão de obra, Termômetro
```

`get_cronograma_grade` **já aceita** `percents` injetados — a costura foi aberta para o simulador
de medições e serve igual aqui. `get_histograma` **já aceita** a `grade` pronta. O laço de
otimização é essas duas chamadas dentro de um avaliador.

---

## 3. A unidade de planejamento é o nível de corte

O cronograma não é uma segunda árvore: é a projeção temporal da árvore do orçamento, **num nível
de corte** (`cro_nivel_corte`). O grid é *item-do-nível × período*, e tudo abaixo do item de
corte segue o padrão dele.

Isso decide, sem discussão, a pergunta que a especificação original deixou aberta ("qual é a
unidade mínima do planejamento?"): **é o item do nível de corte**. O planejador não sequencia
milhares de folhas; ele distribui as linhas que o cronograma já tem.

As horas de cada linha são a soma dos serviços descendentes — conta que o histograma já faz
(`_etapa_id`: *"a linha do cronograma que governa o serviço é o GRUPO ancestral mais fundo com
nível ≤ corte"*). Nada a reimplementar.

**Consequência para os parâmetros:** impeditivo, duração máxima, posição mínima e modo são
atributos de **linha do cronograma**. Parâmetro sugerido para um item abaixo do corte é herdado
pela linha que o governa; conflito entre descendentes da mesma linha resolve-se pela regra mais
restritiva, e o memorial registra que houve conflito.

---

## 4. Fluxo e fronteiras

```
   orçamento ──► PRÉ-PLANEJADOR ──► curadoria do engenheiro ──► CRONOGRAMA
                                                                   │
                                                   ┌───────────────┼───────────────┐
                                                   ▼               ▼               ▼
                                              histograma       medições       documentos
```

O pré-planejador **propõe**; quem grava é a curadoria. O cronograma continua sendo a verdade da
obra, e dele derivam histograma e medições como hoje.

**O simulador de medições é outra função e continua sendo.** Ele valida os % do cronograma
contra os itens e pode não dar match mesmo com o cronograma vindo daqui. A ordem é
`pré-planejador → cronograma → medições`, e o alerta que o código já carrega vale em dobro:

> *"o alvo continua sendo o cronograma COMO O USUÁRIO o definiu (o snapshot), não o que o próprio
> simulador escreveu — senão cada rodada miraria a anterior e a conta andaria sozinha, sem fim."*

**Regra:** o pré-planejador escreve o cronograma **uma vez, na curadoria**, e nunca lê de volta o
que ele mesmo escreveu para recalcular. Cada simulação parte do orçamento, não da simulação
anterior.

---

## 5. O tempo: duas constantes que não se confundem

| Constante | Valor | O que é | Onde vive |
|---|---:|---|---|
| `JORNADA_H_MES` | 220 | Fator de **remuneração**: relaciona o salário-base horário ao mensal. É a constante que a CAIXA publica para converter regime | `catalogo.parametros_normativos`, as-of |
| `HORAS_UTEIS_MES` | 180 | Premissa de **produção**: 8,8 h/dia × 20,5 dias úteis ≈ 180,4. Converte horas de trabalho em gente no canteiro | `orcamento_service`, declarada na tela |

A fórmula oficial de conversão de regime é
`custo mensalista = custo horista / (1 + ES_horista) × 220 × (1 + ES_mensalista)`, e o que
atravessa a conversão é a remuneração-base. **O 220 não afirma que existam 220 horas produtivas
no mês.** Usá-lo como fator de tempo produziu, no histograma, um mês com 9,89 MES de mão de obra
— cerca de dez pessoas — desenhado como `0,04 colaborador`.

**A regra do efetivo sai da unidade**, porque o cronograma dilui por período e período é mês:

```
MES → a quantidade JÁ É gente-mês. 2 MES no mês são 2 colaboradores. Nada a dividir.
H   → horas de trabalho no mês ÷ HORAS_UTEIS_MES.
```

Horista e mensalista convivem no mesmo ativo (a bancada roda o regime item a item): cada balde
vira gente pela sua regra e os dois se somam. **A premissa é declarada onde o número aparece** —
"Colaboradores por mês (horas ÷ 180 h úteis)" —, porque sem ela ninguém confere.

### 5.1 A data-alvo, e por que não há calendário

O cronograma é **abstrato**: períodos, não meses de calendário (`cro_periodo_dias`, default 30).
Isso fica. O que entra é uma **data-alvo de início** (`cro_data_alvo`, opcional), da qual se
deriva o mês de cada período quando for preciso nomeá-lo.

Não se guarda calendário, não se consulta feriado, não se varia a capacidade mês a mês. Dia útil
real é precisão que este módulo não promete, e prometê-la obrigaria a sustentá-la. Se um dia
fizer falta, as fontes estão mapeadas: API de feriados (o ativo já tem município e UF) com
fallback no próprio SINAPI, que desde 2026 publica horas efetivamente trabalhadas por UF.

---

## 6. Mão de obra: identidade, não família

O planejador trabalha com **profissões**, não com grupos. Antes de contar, ele unifica o que é a
mesma profissão sob códigos diferentes, por dois eixos que já existem e são curados:

- **entre fontes** — `catalogo.equivalencias_mo` (109 pares confirmados): o `PEDREIRO` da CDHU e
  o da FDE são o `PEDREIRO` da SINAPI;
- **entre regimes** — `catalogo.composicoes_mapeamento_mdo` (94 pares): `88309 (H)` e
  `101445 (MES)` são o mesmo pedreiro.

Sem isso, um orçamento com duas fontes conta dois pedreiros diferentes e nenhum gargalo aparece.

**O que NÃO se modela:** família ou substituibilidade (azulejista como "parente" do pedreiro).
Isso é juízo de engenharia, varia por obra e por região, e declará-lo numa tabela seria fingir
que é fato. O gargalo é **calculado**: a profissão com maior `horas ÷ capacidade` naquele
cenário, seja ela pedreiro ou marmorista.

---

## 7. As amarras

| Parâmetro | Domínio | Semântica |
|---|---|---|
| `posicao_minima` | inteiro ≥ 1 | **Período absoluto** do cronograma. Primeiro período elegível para iniciar |
| `modo` | `sequencial` \| `intercalada` \| `aleatoria` | Padrão de ocupação dos períodos |
| `impeditivos` | lista de `ati_id` | Linhas cuja conclusão **integral** libera o início |
| `tmax_periodos` | inteiro ≥ 1 \| nulo | Máximo de períodos entre início e fim, **pausas incluídas** |
| `origem` | `manual` \| `eap` \| `ia` | Proveniência efetiva do parâmetro |

**Posição mínima é período absoluto, e isto fecha a pendência.** A discussão original inclinava
para "etapa relativa", com o argumento de que permitiria recalcular o prazo sem invalidar a
parametrização. O argumento é bom e perde para um fato: a app **não tem** o conceito de etapa
executiva. O que ela tem é path e ordem, que organizam o orçamento e não declaram sequência de
obra. Criar "etapa" seria inventar uma terceira estrutura para conviver com a EAP e com o
cronograma. Período absoluto encaixa no que existe, e o custo — reparametrizar ao mudar o prazo
— é real e pequeno: o memorial registra a posição e o recálculo é um clique.

**O par `posicao_minima` + `impeditivos` É a sequência executiva.** Ele não a substitui nem a
aproxima: ele é o único lugar onde ela passa a existir. A EAP *deveria* declará-la, e às vezes
declara — mas com frequência não, seja porque quem montou não se deu ao trabalho, seja porque
misturou serviço com etapa na mesma hierarquia. Uma EAP assim organiza o orçamento e não diz
nada sobre a obra.

É por isso que a sequência **não se deriva** da EAP automaticamente. Derivar seria ler ordem
visual como dependência, e uma EAP mal estruturada produziria um cronograma mal estruturado com
cara de calculado. Quem preenche essa lacuna é a §10 — e é esse, não o preenchimento de campos,
o trabalho principal da IA neste módulo.

**Os três modos**, com o padrão de ocupação:

| Modo | Padrão | Definição |
|---|---|---|
| Sequencial | `1,1,1,1` | Começou, só para quando terminar |
| Intercalada | `1,0,1,0,1` | Depois de iniciar, pula **exatamente um** período e retoma |
| Aleatória | `1,1,0,0,1` | Pausas e retomadas livres entre os períodos elegíveis |

"Aleatória" é nome de interface, não método: o motor escolhe deterministicamente. Havendo
desempate por sorteio, a `seed` é persistida.

**A EAP organiza, não impede.** Itens na mesma posição podem andar juntos — estrutura, alvenaria,
elétrica e hidráulica são o caso clássico. Impedimento só existe quando declarado.

**`tmax` conta períodos corridos, pausas incluídas.** Uma intercalada com três períodos ativos
ocupa janela de cinco. Com `tmax=4`, isso é inviável e se declara: `TMAX_INCOMPATIVEL_COM_MODO`.
O motor **não** troca o modo para caber.

---

## 8. Homogeneidade e o Termômetro de Execução Axys™

Para a série mensal `Z`: `μ = ΣZ/T`, `σ = √(Σ(Z−μ)²/T)` (populacional), `CV = 100σ/μ`.

Duas séries, dois CVs: **financeiro** (valor por mês, da grade) e **de mão de obra** (horas por
mês, do histograma). CV e não desvio absoluto porque R$ 100 mil de desvio pesam diferente numa
obra de R$ 500 mil e numa de R$ 50 milhões.

O **Termômetro** é a leitura mensal das mesmas séries, em percentual da própria média:
`temperatura_m = 100 × Z_m / média(Z)`. 100 é a média, 130 é 30% acima, 75 é 25% abaixo. Duas
temperaturas independentes, financeira e operacional.

**CV é global, temperatura é mensal** — e um CV baixo esconde pico localizado, então registra-se
também `max |Z_m/média − 1|`. A homogeneidade do total de horas não substitui a checagem por
profissão: um mês pode ter total regular e sobrecarregar eletricistas.

**Os limites de CV são metas, não restrições.** Se a fundação é 30% do orçamento e ocupa o
primeiro período, talvez não exista cronograma com CV financeiro baixo. Nesse caso o sistema
entrega o melhor viável, informa o CV alcançado e **nomeia a restrição responsável**. Nunca
distorce a sequência para produzir um gráfico bonito. O limite de partida é 20% para ambos,
configurável e separado — valor de ensaio, não referência técnica.

### 8.1 Prioridade das regras

```
conservação do valor da linha > impeditivos > posição mínima > modo e tmax >
capacidade informada > prazo global fixado > homogeneidade
```

Conflito entre restrições obrigatórias devolve **inviável** com a causa, não um cronograma
aparentemente válido.

---

## 9. Os três modos de uso

| Modo | O engenheiro informa | O sistema responde |
|---|---|---|
| **A — tenho equipe** | efetivo por profissão | o prazo viável e o cronograma |
| **B — tenho prazo** | o prazo contratual | o efetivo necessário mês a mês, e onde ele é inviável |
| **C — qual o equilíbrio** | nada, ou uma faixa | cenários comparados, com prazo, efetivo de pico e CVs |

O modo C é o que sustenta a tese do módulo. Exemplo do que ele entrega:

> *A execução em 10 períodos exige pico de 14 colaboradores no período 5. Em 11 períodos o pico
> cai para 11 e o CV de mão de obra vai de 24% para 16%. A decisão depende do custo de
> permanência no canteiro e da disponibilidade de contratação.*

Isso é comparação, não promessa. O sistema não afirma economia nem prazo sem nova simulação.

---

## 10. A IA parametriza; ela não planeja

**O trabalho dela é declarar a sequência executiva que a EAP não declarou.** Essa é a tarefa,
e o resto é consequência dela. Uma EAP bem feita já carrega a ordem da obra; muitas não carregam,
porque misturam serviço com etapa ou foram montadas só para somar. Sem a sequência, o motor não
tem o que respeitar e volta a distribuir por conta própria — que é exatamente o que este módulo
existe para acabar. Preencher modo e duração máxima é a parte fácil; amarrar o que precede o quê
é a parte que não dá para automatizar por regra.

A IA recebe a **planilha sintética** — ids estáveis, código EAP, nível, descrição,
agrupador/serviço, unidade, quantidade, valor e **horas por profissão** da linha. Não recebe
composição, insumo nem coeficiente: a app já apurou isso.

Ela devolve **só o quadro de parametrização** (§7), por linha ou por agrupador, com `origem=ia`.
O engenheiro revisa; ao editar, a origem passa a `manual` e a sugestão original fica guardada
para comparação.

A IA pode avisar que a EAP recebida não separa etapas de serviços, ou que o nível de corte do
cronograma agrupa coisas que a obra executa em momentos diferentes. É um aviso ao engenheiro, não
uma recusa: o módulo roda do mesmo jeito, e o memorial registra a ressalva.

**Sugestão de `tmax` é estimativa, nunca fato.** 9.000 horas de uma profissão são 50
colaboradores-mês: com dez, cinco meses; com cinco, dez meses. Sem efetivo de referência, horas
não determinam prazo, e a IA deve poder responder `null` com um aviso em vez de inventar.

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
    "horas_uteis_mes": 180,
    "cv_financeiro_max_pct": 20,
    "cv_mo_max_pct": 20,
    "efetivo_por_profissao": {"88309": 4, "88316": 4}
  },
  "linhas": [
    {"ati_id": 1402, "posicao_minima": 1, "modo": "sequencial",
     "impeditivos": [], "tmax_periodos": 2, "origem": "ia"}
  ]
}
```

O efetivo é chaveado pelo **código do insumo de MDO**, já unificado pelas equivalências — não por
nome de profissão, que não é chave.

### 11.2 Simulação (saída)

```json
{
  "schema_version": "1.0",
  "simulacao_id": "sim-001",
  "status": "viavel",
  "percents": {"1402": {"1": 40.0, "2": 60.0}},
  "mensal": [
    {"periodo": 1, "valor": 20000.0, "horas": 400.0, "colaboradores": 2.22,
     "temp_financeira": 80, "temp_mo": 80}
  ],
  "metricas": {"cv_financeiro_pct": 20.0, "cv_mo_pct": 20.0,
               "desvio_max_financeiro_pct": 20.0, "desvio_max_mo_pct": 20.0},
  "gargalo": {"codigo": "88309", "descricao": "PEDREIRO…", "periodos": 11.4},
  "avisos": [],
  "memorial": {"premissas": [], "etapas": [], "restricoes_ativas": []},
  "solver": {"metodo": "…", "seed": null, "otimalidade_provada": false}
}
```

`percents` sai no formato que `get_cronograma_grade` já consome. **É esse campo que a curadoria
grava** — e é o único que o módulo escreve no cronograma.

Inviável: `status="inviavel"`, `percents={}`, `violacoes=[{codigo, ati_id, detalhe}]`. Não se
produz cronograma de aparência válida.

---

## 12. O memorial de premissas e cálculos

É entregável de **primeira classe**, não anexo. É ele que troca "o engenheiro achou" por "o
método diz", e é por ele que a proposta se defende num questionamento de edital.

O memorial declara, em ordem:

1. **as premissas** — horas úteis adotadas e por quê; efetivo informado ou estimado; prazo
   imposto ou calculado; limites de CV;
2. **a apuração** — horas por profissão, já unificadas pelas equivalências, com o que foi
   unificado explicitado (`CDHU B.01.000.010139 → SINAPI 88309`);
3. **a capacidade** — `T_p = horas ÷ (efetivo × horas úteis)` por profissão, e qual delas é o
   gargalo;
4. **as amarras aplicadas** — impeditivos, posições mínimas, modos e tmax, com a origem de cada
   um (`manual`, `eap`, `ia`);
5. **o resultado** — distribuição por período, os dois CVs, as duas temperaturas e o maior
   desvio mensal;
6. **o que não foi atingido** — meta de CV não alcançada, com a restrição responsável nomeada.

O memorial sai no papel da casa, pelo motor de documentos (`Relatorio` com escopo), como qualquer
outra peça.

---

## 13. Caminho crítico: entregue, não prometido

O módulo pode derivar, dos impeditivos declarados, a cadeia mais longa e as folgas — e **exporta**
em formato de planejamento (MS Project / XML), para quem quiser levar adiante em ferramenta
própria.

O que ele **não faz** é se apresentar como planejamento executivo. Não há precedências parciais,
nem início-início, nem defasagem, nem calendário de recursos. O export é um ponto de partida
honesto; a tela não promete mais do que isso e não usa a palavra "planejamento" na interface.

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
| `META_CV_INALCANCAVEL` | Diagnóstico com a restrição nomeada, nunca adulteração |
| `UNIDADE_IGNORADA` | Efetivo calculado pela unidade da linha (H ÷ úteis; MES direto) |
| `IA_ID_INEXISTENTE` | JSON da IA não cria linha que não existe |
| `ORCAMENTO_ALTERADO` | Parâmetros de orçamento revisado não se aplicam sem reconciliação |

**Cenários obrigatórios:** sequencial de 4 períodos; intercalada com 3 ativos em janela de 5;
impedimento simples; duas linhas na mesma posição; ciclo; linha com valor e sem horas; linha com
horas e sem valor; ativo só horista; ativo só mensalista; **ativo misto**; efetivo insuficiente;
prazo imposto curto; CV impossível; orçamento com muitas linhas.

---

## 15. O que permanece aberto

1. **Solver.** Heurística, CP-SAT ou MILP — decidir por benchmark no tamanho real de orçamento,
   não por preferência. Não alegar otimalidade sem prova.
2. **Efetivo estimado.** Informar só as profissões principais e estimar as demais, ou exigir por
   profissão quando ela for o gargalo. A segunda é mais correta e mais chata.
3. **Períodos zerados** dentro do horizonte entram no CV? Recomendação: **sim** — excluí-los
   maquia a homogeneidade.
4. **Herança de parâmetro** entre agrupador e linha, quando os dois têm `tmax`/impeditivo
   distintos. Regra proposta: a mais restritiva vence e o memorial registra o conflito.
5. **Limites de CV padrão** — calibrar com orçamentos reais antes de fixar.
6. **Granularidade do arredondamento** dos percentuais gravados no cronograma.

---

## 16. Sequência de implementação

**V0 — o encaixe.** Provar o laço com o que já existe: receber `percents`, chamar
`get_cronograma_grade` e `get_histograma`, calcular CVs e temperaturas, devolver o Termômetro.
Sem otimizador, sem IA, sem tela. Se este passo não fechar, nada do resto importa.

**V1 — a simulação determinística.** Amarras, modos, capacidade, distribuição, inviabilidades
nomeadas e o memorial. Modo A e modo B.

**V2 — homogeneização e cenários.** Otimizar os dois CVs, modo C, comparação de cenários.

**V3 — o que só entra com demanda.** Caminho crítico e export, liberação parcial, calendário
real, custos não proporcionais.

---

## Limite deste contrato

A proporcionalidade quantidade → valor → horas é **hipótese de modelagem**: distribuir 40% da
quantidade num período distribui 40% do material junto, e material não entra assim na obra.
Custos de mobilização e compras antecipadas não são capturados. **A curva de valor orçado não é
fluxo de caixa**, e a tela precisa dizer isso onde a curva aparece — não só aqui.
