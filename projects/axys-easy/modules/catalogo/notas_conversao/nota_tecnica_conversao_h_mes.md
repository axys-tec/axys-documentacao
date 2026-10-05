# Conversão de mão de obra horista para mensalista no SINAPI

## Nota técnica consolidada: premissas, demonstração e regra adotada pelo Easy

**Contexto:** conversão de composições de custo unitário do SINAPI entre referências de mão de obra horista (`H`) e mensalista (`MES`).
**Base de exemplo:** SINAPI/SP, agosto de 2026, regime SD.
**Status:** consolida três documentos anteriores desta pasta. A hipótese que o primeiro deles registrou como pendente de teste foi verificada e está demonstrada na seção 9. A seção 12 delimita o que permanece interpretação.

---

## 1. Objetivo

Registrar a interpretação técnica utilizada pelo Easy na conversão de referências de mão de obra horista para mensalista, a demonstração que a sustenta e o limite do que se pode afirmar.

A premissa central é separar três grandezas que não se confundem:

1. o **coeficiente de produtividade** da composição de serviço;
2. o **custo da mão de obra**, que incorpora os encargos sociais do regime de contratação;
3. os **encargos complementares**, calculados pelo SINAPI com metodologia própria para cada regime.

A conversão não consiste em retirar encargos sociais do preço horário e reaplicá-los. Quando existe composição mensalista oficial correspondente, o Easy utiliza a referência publicada pelo próprio SINAPI.

---

## 2. Regimes horista e mensalista no SINAPI

O SINAPI vincula a unidade do insumo de mão de obra ao regime de encargos sociais:

- insumo em `H`: incidência de encargos sociais de **horista**;
- insumo em `MES`: incidência de encargos sociais de **mensalista**.

Os dois regimes não utilizam o mesmo percentual de encargos sociais. No horista, custos decorrentes de períodos remunerados sem prestação correspondente de serviço são apropriados por meio dos encargos sociais. No mensalista, parte dessas parcelas já está compreendida na remuneração mensal.

Disto decorre a primeira consequência operacional: **não é correto obter o custo mensal multiplicando o custo horário carregado por 220.**

---

## 3. Equação oficial de conversão

O livro **SINAPI: Metodologias e Conceitos**, publicado pela CAIXA, apresenta a conversão do custo horário com encargos sociais para o custo mensal com encargos sociais:

```math
C MES = (C H / (1 + ES H)) × 220 × (1 + ES MES)
```

onde `C H` é o custo horário com encargos sociais horistas, `ES H` e `ES MES` são os percentuais de encargos de cada regime, `220` é a jornada mensal utilizada na conversão remuneratória e `C MES` é o custo mensal com encargos mensalistas.

A operação tem três movimentos, nesta ordem:

```math
C H / (1 + ES H) = remuneração hora base
remuneração hora base × 220 = remuneração mensal base
remuneração mensal base × (1 + ES MES) = C MES
```

O fator **220 relaciona a remuneração-base horária à remuneração-base mensal**. Os encargos sociais são retirados do regime de origem e reaplicados conforme o regime de destino.

---

## 4. Verificação com os dados oficiais

São Paulo, agosto de 2026, SD:

| Referência | Código | Unidade | Custo |
|---|---:|:---:|---:|
| Pedreiro, horista | 4750 | H | R$ 27,39 |
| Pedreiro, mensalista | 41065 | MES | R$ 4.797,83 |
| Pedreiro com encargos complementares, horista | 88309 | H | R$ 37,26 |
| Pedreiro com encargos complementares, mensalista | 101445 | MES | R$ 6.340,41 |

Os códigos 4750 e 41065 são a mesma categoria profissional sob regimes distintos de apropriação. A relação entre eles **não** se obtém por `27,39 × 220`, porque R$ 27,39 já contém encargos sociais de horista.

Removidos os encargos de cada regime, a remuneração-base converge:

```math
12,74 × 220 = 2.802,80
10,47 × 220 = 2.303,40
```

É esta convergência, e somente ela, que a metodologia oficial estabelece.

---

## 5. Composições com encargos complementares

As composições 88309 e 101445 não contêm apenas custo salarial.

| Componente | 88309 horista (H) | 101445 mensalista (MES) |
|---|---:|---:|
| Profissional | R$ 27,39 | R$ 4.797,83 |
| Alimentação | R$ 4,48 | R$ 743,12 |
| EPI, família pedreiro | R$ 1,47 | R$ 244,86 |
| Exames | R$ 1,43 | R$ 237,03 |
| Transporte | R$ 1,07 | R$ 176,94 |
| Ferramentas, família pedreiro | R$ 0,73 | R$ 122,35 |
| Curso de capacitação 95371 | R$ 0,58 | não existe |
| Seguro | R$ 0,11 | R$ 18,28 |
| **Total** | **R$ 37,26** | **R$ 6.340,41** |

Portanto `88309 × 220 ≠ 101445`, e essa desigualdade **não demonstra erro de nenhuma das referências**. As duas foram construídas segundo regimes distintos, com encargos sociais e complementares apropriados pela metodologia aplicável a cada um.

---

## 6. O fator 220 e as horas efetivamente trabalhadas

A partir da atualização de 2026, o SINAPI passou a considerar, no cálculo dos encargos complementares horários, o número de horas efetivamente trabalhadas ao longo do mês, variável por Unidade Federativa.

Esse parâmetro **não se confunde** com o fator 220 da conversão remuneratória. São grandezas de função diferente:

| Grandeza | Função |
|---|---|
| 220 | relaciona remuneração-base horária e mensal |
| horas efetivamente trabalhadas | apropriação horária de encargos complementares e metodologia de encargos sociais |

Não é correto substituir o fator 220 da conversão remuneratória pelo número de horas efetivamente trabalhadas.

---

## 7. Conversão do coeficiente produtivo

Uma composição de serviço expressa produtividade. Se ela estabelece `0,484 H` de pedreiro por unidade, o coeficiente representa o tempo de mão de obra associado àquela atividade.

Para um coeficiente horista `q H`, a conversão adotada é:

```math
q MES = q H / 220
```

A preservação da remuneração-base é demonstrável por álgebra, antes de qualquer número:

```math
q MES × MO MES base = (q H / 220) × MO MES base
MO MES base = 220 × MO H base
(q H / 220) × 220 × MO H base = q H × MO H base
```

Logo:

```math
q H × MO H base = (q H / 220) × MO MES base
```

A conversão preserva exatamente a parcela de remuneração-base associada ao coeficiente produtivo. O que muda são os encargos próprios do regime escolhido.

---

## 8. Hipótese econômica

O coeficiente responde: **quanto trabalho é necessário para produzir uma unidade do serviço?**
O regime responde: **como o custo desse trabalhador é apropriado?**

A hipótese de trabalho é que a **produtividade física da CPU é preservada e altera-se apenas a forma de apropriação econômica da mão de obra**. O fator 220 não afirma que existam 220 horas fisicamente produtivas no mês: ele é a relação remuneratória entre a referência horária e a mensal, enquanto repousos, feriados, ausências, obrigações sociais e encargos complementares permanecem incorporados aos preços oficiais de cada regime.

---

## 9. Demonstração numérica

**CPU 101157**, alvenaria de vedação de blocos de gesso 7x50x66 cm, AF_05/2020, M². SINAPI/SP 08/2026, SD.

Composição original:

| Tipo | Código | Descrição | Un. | Coef. | Unit. | Total |
|---|---|---|---|---:|---:|---:|
| CPU | 88316 | Servente com encargos complementares | H | 0,242 | R$ 32,18 | R$ 7,78 |
| CPU | 88309 | Pedreiro com encargos complementares | H | 0,484 | R$ 37,26 | R$ 18,03 |
| INS | 44324 | Gesso cola | KG | 0,010 | R$ 2,81 | R$ 0,02 |
| INS | 34584 | Bloco de gesso vazado | M² | 1,027 | R$ 43,00 | R$ 44,16 |
| | | **Total** | | | | **R$ 69,99** |

Coeficientes convertidos:

```math
0,484 H / 220 = 0,0022 MES
0,242 H / 220 = 0,0011 MES
```

Teste da identidade da seção 7, sobre a remuneração-base:

| Categoria | Horista | Mensalista | Diferença |
|---|---:|---:|---:|
| Pedreiro | `0,484 × 12,74 = 6,16616` | `0,0022 × 2.802,80 = 6,16616` | 0,00000 |
| Servente | `0,242 × 10,47 = 2,53374` | `0,0011 × 2.303,40 = 2,53374` | 0,00000 |
| **Soma** | **R$ 8,69990** | **R$ 8,69990** | **R$ 0,00000** |

A identidade fecha em zero, não em zero arredondado.

Mão de obra completa, com encargos:

```math
MO horista = 0,484 × 37,26 + 0,242 × 32,18 = 25,82140
MO mensalista = 0,0022 × 6.340,41 + 0,0011 × 5.470,40 = 19,966342
diferença = 5,855058
```

A composição passa de **R$ 69,99** para **R$ 64,13** por m², redução de 8,4%, integralmente originada na estrutura adicional de cada regime.

### 9.1. Precisão do coeficiente convertido

A identidade é exata em aritmética exata. Para que ela feche ao centavo no sistema, **o coeficiente convertido é mantido com todas as casas**, e o arredondamento ocorre apenas na exibição.

Isto é requisito, não preferência. Nem todo coeficiente divide por 220 em decimais finitos:

| CPU | Coeficiente | `q / 220` | Se truncado a 6 casas |
|---|---:|---|---:|
| 101157 | 0,484 | 0,0022, exato | identidade fecha em zero |
| 101157 | 0,242 | 0,0011, exato | identidade fecha em zero |
| 103671 | 0,399 | 0,00181363…, periódico | resíduo de R$ +0,001019 |
| 103671 | 1,196 | 0,00543636…, periódico | resíduo de R$ −0,000838 |

Os dois primeiros são dízimas finitas e fechariam mesmo com arredondamento. Os dois últimos não, e é por eles que a regra existe.

**Implementação:** converter uma vez, guardar em precisão plena, nunca recalcular a partir do valor arredondado apresentado na tela. Observada essa regra, a identidade da seção 7 fecha ao centavo em qualquer coeficiente.

---

## 10. Diff completo do par 88309 → 101445

Mesma unidade nos dois lados: o mensalista dividido por 220, comparado hora a hora equivalente.

| Componente | Horista (por h) | Part. | Mensalista (÷ 220) | Part. | Δ |
|---|---:|---:|---:|---:|---:|
| **Remuneração-base** | **12,74** | 34,2% | **12,74** | 44,2% | **0,00** |
| Alimentação | 4,48 | 12,0% | 3,38 | 11,7% | −1,10 |
| EPI | 1,47 | 3,9% | 1,11 | 3,9% | −0,36 |
| Exames | 1,43 | 3,8% | 1,08 | 3,7% | −0,35 |
| Transporte | 1,07 | 2,9% | 0,80 | 2,8% | −0,27 |
| Ferramentas | 0,73 | 2,0% | 0,56 | 1,9% | −0,17 |
| Curso de capacitação 95371 | 0,27 | 0,7% | não existe | | −0,27 |
| Seguro | 0,11 | 0,3% | 0,08 | 0,3% | −0,03 |
| Encargos sociais embutidos | 14,96 | 40,1% | 9,07 | 31,5% | −5,89 |
| **Custo da hora** | **37,26** | 100% | **28,82** | 100% | **−8,44** |

Leitura das três classes de linha:

- **Idêntica:** a remuneração-base. É a única que tem de fechar em zero, e fecha.
- **Só existe de um lado:** o curso de capacitação, ausente na composição mensalista.
- **Muda de valor:** todas as demais, por apropriação própria de cada regime.

Dois registros que o diff evidencia. O primeiro: a participação da remuneração-base sobe de 34,2% para 44,2%, enquanto a dos encargos sociais cai de 40,1% para 31,5%. A composição interna do custo muda mais do que o total. O segundo: o curso de capacitação aparece por R$ 0,58 no custo cheio e por R$ 0,27 na versão sem encargos sociais, porque o curso é ele mesmo uma composição com mão de obra dentro. Os encargos alcançam também os complementares.

---

## 11. O que está demonstrado

Pelas publicações do SINAPI:

1. existem regimes de encargos sociais horista e mensalista;
2. a unidade `H` está vinculada aos encargos horistas e a unidade `MES` aos mensalistas;
3. a CAIXA utiliza 220 horas na fórmula oficial de conversão do custo horário para o custo mensal;
4. a conversão exige retirar os encargos horistas antes de aplicar os mensalistas;
5. existem referências oficiais de mão de obra e de composições com encargos complementares em `H` e em `MES`;
6. os encargos complementares possuem metodologia própria e, desde 2026, sua apropriação horária considera horas efetivamente trabalhadas.

Pela verificação da seção 9, e este é o ponto que estava pendente de teste nas versões anteriores desta nota:

7. a relação `q MES = q H / 220`, combinada com a substituição pela referência mensalista oficial, **preserva exatamente a remuneração-base associada ao coeficiente produtivo**, dentro do limite de precisão da seção 9.1;
8. a diferença de custo resultante origina-se **integralmente** das estruturas de encargos sociais e complementares de cada regime, e **não** de alteração da remuneração;
9. portanto, a conversão **não constitui desconto sobre o SINAPI**. A afirmação contrária é verificável e falsa: exige explicar por que `0,484 × 12,74` e `0,0022 × 2.802,80` produzem o mesmo valor.

---

## 12. O que permanece interpretação

A demonstração acima resolve a objeção técnica. Não transforma a operação em regra publicada.

O SINAPI documenta a conversão **de custo de mão de obra** entre regimes. Não há, na documentação consultada, orientação que trate especificamente da **transformação do coeficiente produtivo de uma composição de serviço** por `H / 220` com troca da composição auxiliar.

A cobertura dessa operação é normativa, não metodológica: o art. 8º do Decreto 7.983/2013 admite adotar especificidades de projeto nas composições, desde que demonstrada a pertinência em relatório técnico de profissional habilitado; e o Acórdão TCU 619/2024-Plenário reconhece a possibilidade de adaptação de composições dos sistemas oficiais quando devidamente justificada e compatível com as condições de execução. Nenhum dos dois prescreve `H → MES/220`.

Decorre daí a distinção que a funcionalidade deve manter visível:

| Camada | O que é |
|---|---|
| Dado oficial | preços e composições do SINAPI, na edição, UF e regime declarados |
| Fórmula oficial | conversão de custo entre regimes, publicada pela CAIXA |
| Transformação do Easy | `q MES = q H / 220` com troca do par de referência |
| Premissa do orçamento | a condição de execução em regime mensalista, que é fato da obra |

A última camada é a única que nenhuma tabela demonstra. Encargos de mensalista pressupõem trabalhador mensalista.

**Direção do resultado.** Quando a conversão reduz o custo unitário, o ajuste permanece no caput do art. 8º. Quando o eleva acima da referência adotada, passa a depender do parágrafo único do mesmo artigo, que exige condições especiais justificadas e aprovação do órgão gestor dos recursos. O sinal da diferença altera o regime jurídico aplicável e precisa ser registrado, não apenas o valor final.

---

## 13. Regra adotada pelo Easy

Para mão de obra horista de coeficiente `q H`:

```math
q MES = q H / 220
```

A referência horista com encargos é substituída pela correspondente referência mensalista oficial do SINAPI, na mesma edição, localidade e regime de desoneração.

Identidade de controle, a ser verificada pelo sistema sempre que o par permitir:

```math
q H × MO H base = q MES × MO MES base
```

Condições de aplicação:

- existência de referência mensalista compatível e da mesma categoria profissional;
- mesma edição, localidade e regime de desoneração;
- preservação dos coeficientes físicos de produtividade;
- coeficiente convertido mantido com todas as casas no cálculo interno, arredondado só na exibição;
- rastreabilidade da conversão item a item;
- documentação da premissa de contratação considerada no orçamento.

Sem par mensalista correspondente, **não se converte**: o item permanece horista e recebe marcação própria.

---

## 14. Memória de cálculo

A conversão tem de deixar registrados:

1. a composição original, com código e descrição;
2. a categoria profissional substituída e o par `H`/`MES` utilizado, por código;
3. edição, UF e regime de encargos;
4. os coeficientes originais e os convertidos;
5. o fator 220, com remissão à metodologia publicada pela CAIXA;
6. a verificação da identidade da seção 13, que deve fechar ao centavo;
7. a justificativa da premissa mensalista no caso concreto;
8. o sinal e o valor da diferença resultante, por item e no total.

Os sete primeiros são reconstituíveis a partir das tabelas. O sétimo não: depende de como a obra será executada.

---

## Referências

- CAIXA Econômica Federal. **SINAPI: Metodologias e Conceitos**.
- CAIXA Econômica Federal. **SINAPI: Cálculos e Parâmetros**.
- CAIXA Econômica Federal. Consulta de preços e custos SINAPI, SP, agosto/2026.
- Insumos 4750 e 41065; composições 88309, 101445, 88316, 101452, 101157 e 103671.
- Decreto 7.983/2013, arts. 3º e 8º.
- TCU, Acórdão 619/2024-Plenário.

---

*Consolida as notas técnicas anteriores desta pasta, que foram substituídas por este documento. A demonstração numérica permanece em `estudo_tecnico_conversao_horista_mensalista_sinapi_easy_v2.md`, ao lado.*
