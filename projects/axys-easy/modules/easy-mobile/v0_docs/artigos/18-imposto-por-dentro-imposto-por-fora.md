# Imposto por dentro, imposto por fora: como essa diferença muda o BDI

Imagine que sua empresa vai executar um serviço que custa R$ 100,00. Para simplificar, vamos deixar o lucro e as outras despesas de lado: você quer apenas cobrar o suficiente para pagar o serviço e os tributos. Suponha que esses tributos correspondam a 10% do valor da nota fiscal.

Quanto você precisa cobrar?

A primeira resposta costuma ser R$ 110,00. Afinal, 10% de R$ 100,00 são R$ 10,00. Parece suficiente acrescentar esse valor ao custo.

O problema aparece quando a nota é emitida. O tributo será calculado sobre os R$ 110,00 cobrados do cliente, e não sobre os R$ 100,00 que você gastou. Portanto, a empresa terá de recolher R$ 11,00. Dos R$ 110,00 recebidos, sobrarão R$ 99,00 para pagar um serviço que custou R$ 100,00.

Mesmo sem prever lucro, a empresa ficou no prejuízo.

Esse real que faltou ajuda a entender uma das contas mais importantes da formação de preços: quando o tributo incide sobre o preço de venda, simplesmente acrescentar sua alíquota ao custo não resolve.

## Quanto precisa entrar para que sobrem R$ 100,00?

Se o governo fica com 10% do valor da nota, a empresa fica com os outros 90%. É essa parte que precisa ser suficiente para pagar o custo.

A pergunta, então, pode ser feita de outra maneira: **R$ 100,00 correspondem a 90% de qual valor?**

Para descobrir, dividimos:

```math
Preço de venda = 100,00 / 0,90 = 111,11
```

Agora a conta fecha, com os valores arredondados para centavos:

| Destino do valor recebido | Valor |
|---|---:|
| Preço cobrado do cliente | R$ 111,11 |
| Tributo: 10% do preço | R$ 11,11 |
| Valor que sobra para pagar o serviço | R$ 100,00 |

## Uma alíquota de 10% pode representar uma carga de 11,11%?

Pode, quando mudamos a referência da comparação. No exemplo, a empresa recebe R$ 111,11, recolhe R$ 11,11 e fica com R$ 100,00. O mesmo tributo pode ser apresentado de duas maneiras:

- **Sobre o preço da nota:** R$ 11,11 de tributo para R$ 111,11 de faturamento correspondem a 10%.
- **Sobre o valor que sobra após o tributo:** R$ 11,11 de tributo para R$ 100,00 disponíveis correspondem a aproximadamente 11,11%.

É nesse segundo sentido que podemos falar em uma **alíquota efetiva sobre o valor líquido**, ou em uma taxa equivalente por fora. Uma alíquota de 10% calculada por dentro equivale a uma taxa de aproximadamente 11,11% aplicada sobre o valor sem esse tributo.

A alíquota legal permanece em 10% do preço. O que chega a 11,11% é o peso do tributo em relação ao valor líquido. Dizer sobre qual base estamos falando evita que dois percentuais corretos pareçam contraditórios.

A conversão pode ser feita assim, usando a alíquota em formato decimal:

```math
Taxa equivalente sobre o valor líquido = Alíquota por dentro / (1 - Alíquota por dentro)
```

Para os 10% do exemplo:

```math
0,10 / (1 - 0,10) = 0,1111 = 11,11%
```

Isso explica por que acrescentar apenas 10% aos R$ 100,00 não bastava. Para preservar esse valor depois do recolhimento, o acréscimo necessário era de 11,11%. Quanto maior a alíquota por dentro, maior fica a distância entre o percentual sobre o preço e sua taxa equivalente sobre o valor líquido.

## O que significa calcular por dentro ou por fora?

No cálculo **por fora**, o tributo é acrescentado a uma base que não contém o próprio tributo. Se essa base for R$ 100,00 e a alíquota for 10%, o tributo será R$ 10,00 e o total chegará a R$ 110,00. O IPI é um exemplo usual dessa forma de cálculo, observadas as regras da operação.

No cálculo **por dentro**, o tributo já faz parte do valor sobre o qual é calculado. No nosso exemplo, os 10% são uma parte do preço final da nota. Por isso, precisamos encontrar um preço do qual seja possível retirar o tributo e ainda conservar os R$ 100,00 necessários à execução.

Para o orçamento de obras, a consequência prática é esta: **um percentual sobre o faturamento não pode ser tratado como se fosse um percentual sobre o custo.**

Essa é a razão de os tributos sobre a receita aparecerem no denominador da fórmula usual do BDI. Mas há um cuidado adicional: antes de somar alíquotas, é preciso verificar se elas realmente incidem sobre a mesma base. Voltaremos a isso ao tratar da decisão recente do STF.

## Como essa conta entra no BDI

O BDI é a taxa utilizada para transformar o custo direto da obra em preço de venda, incorporando parcelas como administração central, seguros, riscos, despesas financeiras, lucro e tributos sobre a receita.

Na expressão usual discutida no Acórdão 2.622/2013 do TCU, essas parcelas são organizadas assim:

```math
BDI = (1 + AC + S + R + G) × (1 + DF) × (1 + L) / (1 - I) - 1
```

Nessa expressão, `AC` é a administração central; `S`, os seguros; `R`, os riscos; `G`, as garantias; `DF`, as despesas financeiras; `L`, o lucro; e `I`, a carga de tributos sobre o preço considerada no orçamento. As taxas entram em formato decimal: 10% corresponde a `0,10`.

Para acompanhar o raciocínio, pense primeiro na parte de cima da fração. Ela reúne os fatores que serão aplicados ao custo antes do ajuste dos tributos. Depois, a divisão por `1 - I` encontra o preço necessário para que, após o recolhimento, reste o valor previsto para essas parcelas.

No exemplo inicial, como deixamos todas as demais parcelas de lado, a expressão se resume a:

```math
Preço de venda = Custo / (1 - I)
```

O lucro também merece atenção. Nessa fórmula, `L` é aplicado como acréscimo à base formada pelas parcelas anteriores. Portanto, preencher `L` com 7% não significa que o lucro líquido será igual a 7% do faturamento. Para falar em margem, é necessário dizer sobre qual valor ela foi calculada.

## O tamanho da diferença em um orçamento

Vamos considerar um exemplo didático com PIS de 0,65%, Cofins de 3% e ISS de 5%, todos inicialmente calculados sobre o valor integral do serviço. Essas alíquotas não representam todas as empresas nem todas as obras; servem para acompanhar a conta.

A soma é 8,65%. Para um serviço de custo igual a R$ 100,00, sem as demais parcelas do BDI, temos:

| Forma de calcular | Preço de venda |
|---|---:|
| Acrescentar 8,65% ao custo | R$ 108,65 |
| Dividir o custo por `1 - 0,0865` | R$ 109,47 |

No primeiro caso, os tributos sobre a nota somariam aproximadamente R$ 9,40. Restariam R$ 99,25, insuficientes para pagar o custo. No segundo, o recolhimento seria de aproximadamente R$ 9,47 e restariam R$ 100,00.

Sobre um custo de R$ 10 milhões, a diferença entre os preços calculados pelos dois métodos seria de aproximadamente **R$ 81,9 mil**. Esse é o valor que faltaria no preço para preservar o custo depois dos tributos, mantidas as hipóteses do exemplo.

## O que muda com a exclusão do ISS da base do PIS e da Cofins

Em 21 de outubro de 2026, o STF julgou o Tema 118, no RE 592.616, e decidiu pela exclusão do ISS da base de cálculo do PIS e da Cofins. A notícia oficial informa que a modulação dos efeitos não foi examinada naquele julgamento e poderia ser discutida em recurso. [Fonte: STF](https://noticias.stf.jus.br/postsnoticias/stf-decide-que-iss-nao-integra-base-de-calculo-do-pis-e-da-cofins/).

Para entender a consequência no orçamento, vamos manter as alíquotas do exemplo e considerar um cenário em que essa exclusão seja aplicável. O desenvolvimento a seguir é uma demonstração matemática do efeito nas bases de cálculo, não uma fórmula de BDI fixada pelo STF.

Em uma nota de R$ 100,00, o ISS de 5% corresponde a R$ 5,00. Excluído esse valor, a base do PIS e da Cofins passa a ser R$ 95,00.

As alíquotas dessas contribuições permanecem iguais. O que diminui é o valor sobre o qual elas são aplicadas:

| Tributo | Sobre os R$ 100,00 integrais | Com o ISS excluído da base das contribuições |
|---|---:|---:|
| ISS: 5% | R$ 5,00 | R$ 5,00 |
| PIS: 0,65% | R$ 0,65 | R$ 0,6175 |
| Cofins: 3% | R$ 3,00 | R$ 2,85 |
| **Total de tributos** | **R$ 8,65** | **R$ 8,4675** |

A redução é proporcional ao ISSQN efetivamente recolhido: quanto maior a parcela do ISS no preço, maior o alívio na base das contribuições. **Sobre o que já foi recolhido a mais, a empresa pode pleitear ressarcimento tributário**, observados o prazo prescricional e eventual modulação de efeitos.

A carga conjunta cai de 8,65% para **8,4675% do preço**. O ISS continua devido: o que diminui é apenas a base do PIS e da Cofins.

## Como representar essa possibilidade no cálculo do BDI

Quando os três tributos incidem sobre o mesmo preço, suas alíquotas podem ser somadas em um único `I`. Quando o ISS sai da base das contribuições, o denominador passa a ter um fator para cada base:

```math
BDI = (1 + AC + S + R + G) × (1 + DF) × (1 + L) / ((1 - PIS - COFINS) × (1 - ISSQN)) - 1
```

Cada fator retira do preço a parcela de um tributo calculada sobre a sua própria base. Com os números do exemplo:

```math
(1 - 0,0065 - 0,03) × (1 - 0,05) = 0,915325
```

É o mesmo denominador de antes, agora escrito de modo que mostra de onde ele vem. Como a divisão passa a ser feita por um número maior que `0,9135`, o preço necessário diminui.

Voltando ao serviço que custa R$ 100,00, ainda sem lucro ou outras despesas:

| Cenário | Preço necessário |
|---|---:|
| PIS e Cofins sobre o preço integral | R$ 109,47 |
| PIS e Cofins com o ISS excluído da base | R$ 109,25 |

Para um custo de R$ 10 milhões, os preços seriam aproximadamente R$ 10.946.907,50 e R$ 10.925.081,26: uma diferença de **R$ 21.826,24**. A redução da carga tributária é de 0,1825 ponto percentual; a variação do BDI e do preço resulta da aplicação dessa carga na fórmula.

Em uma obra real, a conta precisa considerar o regime tributário, eventuais créditos, a base efetiva do ISS, outros tributos e as condições de aplicação da decisão. Se o ISS corresponder a uma parcela diferente de 5% do preço total, por exemplo, será essa parcela efetiva que deverá entrar no fator do ISSQN. O mesmo raciocínio não autoriza alterar automaticamente outros tributos ou revisar preços de contratos existentes.

A contribuição do julgamento para o orçamento é tornar ainda mais evidente uma exigência que já existia: o campo de tributos do BDI precisa refletir as bases de cálculo efetivamente aplicáveis. Uma soma de alíquotas só representa bem a carga quando as bases permitem essa soma.

Antes de fechar o preço, vale fazer a conferência mais simples: calcular os tributos sobre as respectivas bases e subtraí-los do faturamento previsto. O valor restante precisa sustentar o custo e as demais parcelas consideradas na proposta. Foi essa conferência que revelou o real que faltava no primeiro exemplo, e é ela que permite avaliar, com clareza, o efeito de uma mudança tributária sobre o BDI.
