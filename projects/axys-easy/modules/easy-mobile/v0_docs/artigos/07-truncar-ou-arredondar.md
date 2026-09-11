# Truncar ou arredondar: por que centavos decidem um orçamento — e protegem o orçamentista

Todo preço de obra nasce de uma conta que não termina. Um coeficiente de 0,0347 multiplicado por um insumo de R$ 23,18 dá R$ 0,804346 — e dinheiro só tem duas casas. Em algum momento, alguém corta o número. **O critério desse corte não é detalhe de planilha: é decisão de orçamento.**

## O que cada critério faz

**Arredondar** aproxima a casa desejada olhando o algarismo seguinte: 12,346 vira 12,35 e 12,344 vira 12,34.

**Truncar** simplesmente corta — os dois viram 12,34.

## Por que a escala muda tudo

Arredondar é simétrico em teoria, mas a compensação só é perfeita se os valores se distribuírem de forma neutra, e preços de insumo não se comportam assim. Um item de R$ 0,23 repetido em dez mil unidades carrega o erro dez mil vezes; uma composição que contém outra arredonda duas vezes sobre o mesmo valor. **O desvio deixa de ser aleatório e passa a ter direção.**

## A orientação do controle

Preço acima do parâmetro caracteriza sobrepreço. Se pago, pode configurar superfaturamento.

Quem trunca pode ter que explicar centavos a menos. Quem arredonda pode ter que explicar centavos a mais — e é essa a explicação difícil.

## O que isso significa na prática

A pergunta correta diante de uma divergência não é "qual está certo", mas **"de onde vem a diferença"**. Se vem do critério de corte, é de centavos e previsível. Se vem de coeficiente ou preço de insumo, a ordem de grandeza é outra.

## O que não muda

As composições permanecem as da fonte-base, com os mesmos coeficientes e preços de insumo. Truncar reduz o preço total na casa dos centavos, mas não configura remuneração inapropriada: a própria composição e o BDI existem justamente para que a precificação seja segura.

## Um exemplo real

Composição **SINAPI 103320** — alvenaria de vedação de blocos vazados de concreto de 19×19×39 cm (espessura 19 cm) e argamassa de assentamento com preparo em betoneira (AF_12/2021). Data-base **julho/2026, SP**, unidade **m²**.

| Tipo | Código | Descrição | Unid. | Coef. | Valor unit. | Total |
|---|---|---|---|---:|---:|---:|
| CPU | 88316 | Servente com encargos complementares | H | 0,565000 | R$ 32,18 | R$ 18,18 |
| CPU | 88309 | Pedreiro com encargos complementares | H | 1,130000 | R$ 37,26 | R$ 42,10 |
| CPU | 87292 | Argamassa traço 1:2:8, preparo mecânico em betoneira até 600 L (AF_07/2026) | M3 | 0,012800 | R$ 616,40 | R$ 7,88 |
| INS | 37395 | Pino de aço com furo, haste 27 mm (ação direta) | CENTO | 0,010000 | R$ 46,74 | R$ 0,46 |
| INS | 34548 | Tela de aço soldada galvanizada para alvenaria, malha 15×15 mm | M | 0,420000 | R$ 5,28 | R$ 2,21 |
| INS | 654 | Bloco de vedação de concreto 19×19×39 cm (classe C — NBR 6136) | UN | 13,600000 | R$ 5,27 | R$ 71,67 |
| | | **Custo total da CPU** | | | | **R$ 142,50** |

O total acima resulta do **truncamento em duas casas, linha a linha**. Com arredondamento, a mesma composição valeria **R$ 142,53**:

| Conta | Resultado | Truncado | Arredondado |
|---|---:|---:|---:|
| 0,565 × 32,18 | 18,1817 | 18,18 | 18,18 |
| 1,13 × 37,26 | 42,1038 | 42,10 | 42,10 |
| 0,0128 × 616,40 | 7,88992 | 7,88 | **7,89** |
| 0,01 × 46,74 | 0,4674 | 0,46 | **0,47** |
| 0,42 × 5,28 | 2,2176 | 2,21 | **2,22** |
| 13,60 × 5,27 | 71,672 | 71,67 | 71,67 |
| **Total** | | **R$ 142,50** | **R$ 142,53** |

Vale destacar que o arredondamento foi aplicado **em cada linha**. Se fosse aplicado apenas ao final, o valor poderia ser ligeiramente diferente — usando-se o próprio critério.

## Três centavos, e o que eles viram

Comparando com o valor divulgado pela fonte-base, R$ 142,50, o orçamento arredondado precificaria cada metro quadrado com **três centavos a mais**.

Parece pouco. Mas uma obra com mil unidades desse serviço acumula R$ 30,00. Ainda é pouco frente ao serviço — só que uma planilha raramente tem um item: com mais duzentos itens carregando margem semelhante, chega-se a R$ 6.000,00. Estendido a várias obras, o valor cresce de forma significativa.

Existe a tese de que o desvio é percentualmente pouco expressivo e, portanto, defensável. É verdade. **Também é verdade que o auditor pode entender que o preço está acima do referencial e, portanto, que há sobrepreço.** O orçamentista pode acabar pagando a conta de um modelo matemático não conservador.

## E se a fonte arredondasse?

Nesse caso ela teria publicado R$ 142,53, e o orçamentista adotaria R$ 142,50. É menos — basta justificar. **Jamais será sobrepreço.**

Talvez por isso a SINAPI aplique truncamento na linha. E talvez, pelo mesmo motivo, ela possa ser a fonte oficial citada pela Lei Federal 14.133/2021 para edificações.

Fica a dica.
