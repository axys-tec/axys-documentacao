# Conversão H→MÊS: o divisor do coeficiente — Contrato (consulta)

**Status:** Decidido, a implementar.
**Data:** 2026-10-16
**Escopo:** qual divisor a app aplica ao converter o coeficiente de mão de obra de uma composição, e por quê. Vale na **consulta de composições** — a tela do Easy e a API do Easy Mobile, que leem o mesmo motor.
**Implementa:** `backend/modules/catalogo/conversao_mdo.py`, `catalogo.edicoes_leis_sociais`.
**Parte 2:** [`ativo/conversao_mdo_bancada_contrato.md`](../ativo/conversao_mdo_bancada_contrato.md) — o que muda quando a conversão entra num orçamento real.

> **A decisão:** o coeficiente converte por `220 × (1 + ES_mensalista) / (1 + ES_horista)`, calculado **ao vivo** por edição, UF e regime. Em SINAPI/SP/desonerado isso dá **175,16 h**. O divisor fixo de 220 sai, e sai porque sub-apropria o custo em 22,7%.

---

## 1. O defeito

A app convertia o coeficiente dividindo por 220. Numa composição real — SERVENTE na 103669, concretagem de pilares, SINAPI/SP/SD:

```
HORISTA              7,377 h × R$ 32,18   = R$ 237,39
÷ 220                coef 0,033532 MES → R$ 183,43   (−22,70%)
```

Os 22,7% foram apresentados ao usuário como economia de encargo. Não são. São sub-apropriação: o divisor 220 assume que um mensalista entrega 220 horas de produção por mês, o que nenhuma fonte afirma.

A consequência prática é séria. Converter regime barateando cabe no caput do art. 8º do Decreto 7.983/2013; encarecer cai no parágrafo único, com aprovação do órgão gestor. A app entregava ao orçamentista uma economia de 8,4% no custo total da composição que não se sustenta diante de quem fizer a conta.

---

## 2. O que os livros dizem, e o que não dizem

**A fórmula do 220 é de custo do profissional, não de coeficiente.** *Metodologias e Conceitos*, item 6.3:

> *"A Constituição Federal estabelece jornada de trabalho de 220 horas mensais. Dessa forma, caso seja necessário realizar conversão do **custo horário** (com Encargos Sociais) para **custo mensal** (com Encargos Sociais) **do profissional**, deve ser empregada a expressão: `Custo Mensal = [Custo Horário / (1 + ES Horista)] × 220 × (1 + ES Mensalista)`"*

Converte o **preço de um insumo**. Não diz nada sobre coeficiente de composição, e o 220 que ela usa é a jornada constitucional — parâmetro remuneratório.

**Os insumos mensalistas existem para outra coisa.** O mesmo livro:

> *"No SINAPI as categorias de mão de obra que aparecem **nas composições de serviço** são apresentadas com seu **custo horário**, mão de obra operária. Porém também há no SINAPI insumos de mão de obra de **mensalistas**, profissionais que comumente são considerados na **equipe de administração local** de uma obra, tais como almoxarife, topógrafo, engenheiro."*

**E o banco confirma:** nenhuma composição de serviço do catálogo usa mão de obra em MES. Zero, em todas as fontes capturadas.

**Conclusão que reordena o problema:** a SINAPI não converte composição porque não pretende que se converta. A rotação de regime na mão de obra operária é **adaptação técnica da app**, legítima e útil, mas fora da metodologia publicada. Logo o divisor é escolha nossa, e cabe a nós justificá-la.

---

## 3. O divisor

Partindo da expressão publicada e perguntando *"a quantas horas de horista equivale um mês de mensalista?"*, isola-se `x`:

```
x × C_horista = C_horista / (1 + ES_h) × 220 × (1 + ES_m)

x = 220 × (1 + ES_m) / (1 + ES_h)
```

Não é número novo: é a própria equação do livro, lida como equivalência. Em SINAPI/SP/SD, com ES de 115,01% e 71,18%, `x = 175,16 h`.

**Ele zera a parcela de encargos sociais ao centavo.** Conferido no insumo:

```
SERVENTE SP/SD · x = 175,1528 h
  MO c/ ES        horista 22,51/h × 175,15 = R$ 3.942,96  ·  mensalista publicado R$ 3.942,96   −0,00%
  complementares   9,67/h × 175,15 = R$ 1.693,73  ·  mensalista publicado R$ 1.527,44   −9,82%
  TOTAL                              R$ 5.636,69  ·                      R$ 5.470,40   −2,95%
```

A economia que sobra **tem causa publicada**: os encargos complementares do mensalista são menores porque esta edição do livro excluiu o Curso de Capacitação dos mensalistas — *"uma vez que os empregados contratados nessa modalidade não recebem por produtividade do serviço"*. Uma economia de 2,95% com uma linha do livro por trás se defende numa impugnação; 22,7% sem origem, não.

### 3.1 É por UF e por regime, nunca fixo

`ES_h` e `ES_m` vivem em `catalogo.edicoes_leis_sociais`, por `(edi_id, uf, modalidade)`. O divisor herda essa granularidade:

| | SP | RJ | MG | BA | DF |
|---|---:|---:|---:|---:|---:|
| SD | 175,15 | 175,66 | 176,86 | 174,65 | 177,96 |
| CD | 175,16 | 175,66 | 176,87 | 174,66 | 177,97 |

Amplitude nacional nas 54 combinações: **173,16 a 179,82**, média 175,60. Qualquer constante no código é defeito.

### 3.2 Calcula-se ao vivo; guarda-se o que foi aplicado

O divisor é **função pura** de `(edi_id, uf, modalidade)`, e os três já estão no banco. Persisti-lo criaria uma segunda verdade sobre algo derivável, que passa a discordar da origem no dia em que a CAIXA revisar os encargos — o que ela faz anualmente. É a mesma doutrina do path determinístico: o que se calcula não se guarda.

**O registro é outra coisa e é obrigatório.** Tudo que congela um custo grava o divisor que usou, para o documento se reproduzir depois de uma revisão de encargos. Isso é a parte 2 deste contrato — aqui, na consulta, nada congela: cada abertura recalcula.

---

## 4. O que o 220 continua sendo

**O 220 identifica o par H↔MÊS e isso não muda.** `vinculacoes.md` §3.1 estabelece o par por `TRUNC(preço_mês / 220, 2) = preço_hora`, exato em 94 de 94 casos. Essa é a convergência da **remuneração-base**, que o artigo demonstra e os nossos dados confirmam (SERVENTE pelado: H R$ 9,95/h · MES R$ 2.189,00 ÷ 220 = R$ 9,95).

São dois usos distintos do mesmo número, e só um muda:

| Uso | Número | Muda? |
|---|---|---|
| Identificar que `88316` e `101452` são o mesmo profissional | 220 (remuneração-base) | **não** |
| Converter o coeficiente da composição | `220 × (1+ES_m)/(1+ES_h)` | **sim** |
| `JORNADA_H_MES` em `parametros_normativos` | 220, as-of | **não** — continua sendo a jornada legal |

---

## 5. As duas dimensões, que nunca se derivam uma da outra

Esta é a regra que o defeito anterior violava e que precisa ficar escrita.

**Física.** `horas = quantidade × coeficiente horista`. É o trabalho que o serviço exige, e não muda com regime de contratação nenhum. Alimenta histograma, cronograma e pré-planejamento. **O coeficiente horista fica preservado mesmo quando a composição rotaciona** — é dele que as horas saem, nunca da fração em MES.

**Financeira.** O coeficiente convertido pelo divisor, usado só para formar custo.

**É proibido recuperar horas físicas multiplicando a fração em MES por 220** — ou por qualquer número. Foi assim que o histograma passou a desenhar 0,04 colaborador num mês com dez pessoas.

---

## 6. Por que 175,16 e não as horas efetivas da CAIXA

As 165,98 h/mês de SP (271,60 dias efetivos ÷ 12 × 7,3333) são número publicado, e foram consideradas. Não servem aqui, por dois motivos.

**O primeiro é de propósito.** O livro usa as horas efetivas para ratear **encargo complementar** — custo mensal ÷ horas efetivas = custo horário. É critério de rateio de provisão, não medida de capacidade de produção.

**O segundo é que elas descontam férias, e férias se repõe.** Quando um trabalhador sai de férias, outro ocupa a vaga; a obra não para e o custo das férias está no encargo social. Descontar as férias da disponibilidade física conta uma ausência que o canteiro não sente. A reconciliação mostra que é disso que se trata:

```
SINAPI/SP   271,60 dias efetivos/ano                       165,98 h/mês
  + férias (23,59 d, reposta)            295,19 dias/ano   180,39 h/mês
  + enfermidade, chuva, faltas, demais   304,20 dias/ano   185,90 h/mês
  calendário real de 2026 (SP, 44 h/sem)                   184,07 h/mês
```

A distância inteira entre a base da CAIXA e o calendário real é **férias (14,4 h/mês)** mais uma cauda de 5,5 h de ausências não repostas. Com férias de volta, a disponibilidade física é 180,39 h/mês, e os 175,16 ficam 2,9% abaixo disso.

**Então o divisor tem dois pés:** deriva da equação publicada *e* fica perto da disponibilidade real. Levantamentos de calendário municipal confirmam a ordem de grandeza — Fernandópolis 182,60, São Paulo 183,33, Jales 182,60 h/mês antes das ausências.

**Ressalva de método, que vale manter no código.** A proximidade entre 175,16 (financeiro, por UF e regime) e ~180 (físico, por município e ano) é **corroboração, não identidade**. São grandezas diferentes, variam por eixos diferentes, e o dia em que divergirem não pode pegar o código tratando-as como a mesma.

---

## 7. O parecer técnico

Toda conversão exibida sai acompanhada de **parecer de uma página**, no próprio relatório — não em anexo, não sob demanda. Quem recebe um custo diferente do publicado precisa receber junto a razão, com os números.

O parecer declara, nesta ordem:

1. **o que foi convertido** — composição, fonte, edição, UF, regime, e quais itens de mão de obra rotacionaram;
2. **o fundamento** — a expressão do item 6.3 do *Metodologias e Conceitos*, citada, e a declaração de que a conversão de coeficiente é adaptação técnica, não metodologia publicada;
3. **o divisor** — `220 × (1+ES_m)/(1+ES_h)`, com os dois percentuais daquela edição e UF e o resultado;
4. **a verificação** — a parcela de encargos sociais fecha ao centavo contra o insumo mensalista publicado;
5. **o efeito** — custo antes, custo depois, variação em R$ e em %, com a parcela de complementares separada e a sua causa (exclusão do Curso de Capacitação dos mensalistas nesta edição);
6. **a ressalva legal** — barateamento cabe no caput do art. 8º do D 7.983/2013; se em alguma combinação de UF e regime a conversão encarecer, o parecer diz que o caso é do parágrafo único e exige aprovação do órgão gestor.

O parecer é gerado do mesmo dado que a conversão — não é texto fixo. Divisor, percentuais e valores vêm do cálculo.

---

## 8. Critérios de aceite

| Código | O que exige |
|---|---|
| `DIVISOR_FIXO` | Nenhum 220 cravado no caminho da conversão de coeficiente |
| `DIVISOR_POR_UF` | O divisor vem de `edicoes_leis_sociais` da edição, UF e regime em uso |
| `DIVISOR_AO_VIVO` | Não há tabela nem cache do divisor |
| `ES_FECHA_NO_INSUMO` | `preço_horista × divisor` = parcela de MO c/ ES do insumo mensalista, à tolerância de centavo |
| `COEFICIENTE_FISICO_PRESERVADO` | O coeficiente horista continua acessível depois da rotação |
| `HORA_NAO_SAI_DE_MES` | Nenhum caminho recupera horas físicas a partir da fração em MES |
| `PARECER_PRESENTE` | Relatório de conversão sempre acompanhado do parecer, com os números daquela conversão |
| `PAR_INTACTO` | A identificação do par H↔MÊS continua por 220 (`vinculacoes.md` §3.1) |
| `SEM_PAR_E_VALIDO` | Item sem par mensalista fica original e marcado, como hoje |

**Cenários:** SP/SD e SP/CD; uma UF de cada extremo (173,16 e 179,82); composição com mão de obra de mais de uma profissão; composição com sub-CPU que rotaciona e outra que não; fonte sem regime mensalista (CDHU/FDE) — `sem_mapeamento`, inalterado.

---

## 9. Alcance

Vale para a **consulta de composições**, que é o mesmo motor em duas portas: a tela do Easy e a API do Easy Mobile. As duas passam a mostrar o custo convertido pelo divisor novo e o parecer junto.

Nada aqui grava. O que acontece quando a conversão entra num orçamento real — registro do divisor, reprodutibilidade e recálculo — é a parte 2.
