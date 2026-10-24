# Horista para mensalista: o que a conversão preserva

Trocar a mão de obra horista pela mensalista dentro de uma composição do SINAPI muda o custo. Muda bastante. E a primeira pergunta de quem vê esse número cair é sempre a mesma: isso é desconto disfarçado?

A resposta é não, e dá para demonstrar. Este artigo estabelece as premissas, aplica a fórmula que a CAIXA publica, testa a identidade numa composição real e fecha com o comparativo item a item entre os dois regimes.

## Três grandezas que não se confundem

Quase todo erro nesta discussão nasce de tratar como uma coisa só o que são três:

O **coeficiente de produtividade** da composição, que diz quanto trabalho é necessário para produzir uma unidade do serviço.

O **custo da mão de obra**, que incorpora os encargos sociais do regime de contratação.

Os **encargos complementares**, que o SINAPI calcula com metodologia própria para cada regime: alimentação, transporte, EPI, exames, ferramentas, capacitação e seguro.

Converter regime mexe no segundo e no terceiro. Não mexe no primeiro.

## Os dois regimes são referências distintas, não variações de uma

O SINAPI vincula a unidade do insumo ao regime de encargos. Insumo em `H` carrega encargos de horista; insumo em `MES`, de mensalista. E os percentuais não são os mesmos.

A razão é estrutural. No horista, custos de períodos remunerados sem prestação correspondente de serviço são apropriados pelos encargos sociais. No mensalista, parte dessas parcelas já está compreendida na própria remuneração mensal.

Daí a primeira consequência prática, e ela contraria a intuição: **não se obtém o custo mensal multiplicando o custo horário carregado por 220.**

## A equação que a CAIXA publica

A conversão não é invenção de quem orça. O livro *SINAPI: Metodologias e Conceitos*, publicado pela CAIXA ao lado de *Cálculos e Parâmetros*, traz a fórmula:

```math
custo mensalista = (custo horista / (1 + ES horista)) × 220 × (1 + ES mensalista)
```

São três movimentos em ordem:

```math
custo horista / (1 + ES horista) = remuneração hora base
remuneração hora base × 220 = remuneração mensal base
remuneração mensal base × (1 + ES mensalista) = custo mensalista
```

Primeiro **retira** o encargo do regime de origem. Depois **converte** a remuneração-base por 220. Por fim **aplica** o encargo do regime de destino.

O ponto que sustenta tudo é o do meio. O que atravessa a conversão é a remuneração-base, e nada mais.

Isso muda o peso da discussão. Quando o orçamentista converte regime, não está criando um método: está aplicando o método que o mantenedor do sistema de referência escreveu e divulgou. A pergunta do controle deixa de ser *de onde você tirou essa conta* e passa a ser *a premissa mensalista se confirma nesta obra*. Só a segunda depende de fatos da obra.

## A convergência, verificada nos insumos

O SINAPI publica o mesmo profissional nas duas referências. Removidos os encargos de cada regime:

| Profissional | Código H | Base horária | Código MES | Base mensal | ÷ 220 |
|---|---|---:|---|---:|---:|
| Pedreiro | 4750 | R$ 12,74/h | 41065 | R$ 2.802,80/mês | **R$ 12,74/h** |
| Servente | 6111 | R$ 10,47/h | 41084 | R$ 2.303,40/mês | **R$ 10,47/h** |

```math
12,74 × 220 = 2.802,80
10,47 × 220 = 2.303,40
```

Exato. E é só isto que a metodologia oficial estabelece: a convergência da remuneração-base.

## O que 220 é, e o que não é

Duas grandezas do SINAPI são confundidas com frequência, e vale separá-las antes de seguir.

O fator **220** relaciona a remuneração-base horária à mensal. É constante de conversão entre tabelas.

As **horas efetivamente trabalhadas** são outra coisa. Desde a atualização de 2026, o SINAPI as considera no cálculo dos encargos complementares horários, e elas variam por Unidade Federativa.

Não se substitui uma pela outra. O 220 não afirma que existam 220 horas fisicamente produtivas no mês; ele traduz uma relação remuneratória. As horas efetivamente trabalhadas servem à apropriação de encargos, não à conversão de remuneração.

## A conversão do coeficiente, antes de qualquer número

Para um coeficiente horista `q`, a conversão é:

```math
q mensalista = q horista / 220
```

E a preservação da remuneração-base se demonstra por álgebra, sem depender de caso particular:

```math
q mensalista × MO mensalista base = (q horista / 220) × MO mensalista base
MO mensalista base = 220 × MO horista base
(q horista / 220) × 220 × MO horista base = q horista × MO horista base
```

O 220 entra e sai. Sobra a identidade:

```math
q horista × MO horista base = (q horista / 220) × MO mensalista base
```

Isto vale para qualquer coeficiente e qualquer par de referências em que a convergência da seção anterior se verifique. Ainda assim, álgebra não convence sozinha: é vendo os números de uma composição real que se acredita nela. É o que vem a seguir.

## A composição, aberta camada por camada

Tomemos a **101157**, alvenaria de vedação em blocos de gesso, SINAPI/SP de agosto de 2026, regime desonerado. Vamos abri-la até chegar a insumos puros, converter nesse nível e comparar linha a linha.

### Etapa 1: como o SINAPI publica

| Item | Coef. | Unitário | Total |
|---|---:|---:|---:|
| Servente com encargos complementares (88316) | 0,242 h | R$ 32,18 | R$ 7,78 |
| Pedreiro com encargos complementares (88309) | 0,484 h | R$ 37,26 | R$ 18,03 |
| Gesso cola (44324) | 0,010 kg | R$ 2,81 | R$ 0,02 |
| Bloco de gesso vazado (34584) | 1,027 m² | R$ 43,00 | R$ 44,16 |
| | | **Total** | **R$ 69,99** |

Quatro linhas. Duas delas, as de mão de obra, não são insumos: são composições auxiliares, e é dentro delas que está tudo o que a conversão vai tocar.

### Etapa 2: a mão de obra se desdobra

Cada composição auxiliar abre em duas partes, o profissional e o bloco de encargos complementares. As quatro linhas viram seis, e o total não se move.

| Item | Coef. | Unitário | Total |
|---|---:|---:|---:|
| Servente (6111) | 0,242 h | R$ 22,51 | R$ 5,44 |
| Servente, encargos complementares | 0,242 h | R$ 9,67 | R$ 2,34 |
| Pedreiro (4750) | 0,484 h | R$ 27,39 | R$ 13,25 |
| Pedreiro, encargos complementares | 0,484 h | R$ 9,87 | R$ 4,78 |
| Gesso cola (44324) | 0,010 kg | R$ 2,81 | R$ 0,02 |
| Bloco de gesso vazado (34584) | 1,027 m² | R$ 43,00 | R$ 44,16 |
| | | **Total** | **R$ 69,99** |

Os encargos complementares são alimentação, transporte, EPI, exames, ferramentas, curso de capacitação e seguro. Sete itens que o SINAPI agrega e apropria por hora.

### Etapa 3: insumos puros

Falta separar o que ainda está embutido. Tanto o profissional quanto os encargos complementares carregam leis sociais dentro de si, e é exatamente isso que diferencia um regime do outro.

Separando as três naturezas, as seis linhas viram oito:

| Item | Coef. | Unitário | Total |
|---|---:|---:|---:|
| Servente, salário-base | 0,242 h | R$ 10,47 | R$ 2,53 |
| Servente, leis sociais `LS 115% × 10,47 = 12,04` + `0,25` nos complementares | 0,242 h | R$ 12,29 | R$ 2,97 |
| Servente, outros complementares | 0,242 h | R$ 9,42 | R$ 2,28 |
| Pedreiro, salário-base | 0,484 h | R$ 12,74 | R$ 6,16 |
| Pedreiro, leis sociais `LS 115% × 12,74 = 14,65` + `0,31` nos complementares | 0,484 h | R$ 14,96 | R$ 7,24 |
| Pedreiro, outros complementares | 0,484 h | R$ 9,56 | R$ 4,63 |
| Gesso cola (44324) | 0,010 kg | R$ 2,81 | R$ 0,02 |
| Bloco de gesso vazado (34584) | 1,027 m² | R$ 43,00 | R$ 44,16 |
| | | **Total** | **R$ 69,99** |

Agora sim, insumos puros: salário, encargo, benefício, material. E o total continua o da composição publicada.

A micro-memória da linha de leis sociais merece atenção. Ela tem **duas parcelas**. A primeira é a alíquota de 115% sobre o salário-base, que é o que quase todo mundo espera. A segunda, R$ 0,31 no pedreiro e R$ 0,25 no servente, está dentro dos próprios encargos complementares, porque o curso de capacitação é ele mesmo uma composição, com mão de obra dentro. Encargo social alcança complementar.

### Etapa 4: a mesma composição, em mensalista

Agora a troca. Coeficientes divididos por 220, referências horistas substituídas pelas mensalistas oficiais, materiais intocados:

```math
0,484 h / 220 = 0,0022 mês
0,242 h / 220 = 0,0011 mês
```

A composição, aberta nas mesmas oito linhas:

| Item | Coef. | Unitário | Total |
|---|---:|---:|---:|
| Servente, salário-base | 0,0011 mês | R$ 2.303,40 | R$ 2,53 |
| Servente, leis sociais `LS 71,18%` | 0,0011 mês | R$ 1.639,56 | R$ 1,80 |
| Servente, outros complementares | 0,0011 mês | R$ 1.527,44 | R$ 1,68 |
| Pedreiro, salário-base | 0,0022 mês | R$ 2.802,80 | R$ 6,16 |
| Pedreiro, leis sociais `LS 71,18%` | 0,0022 mês | R$ 1.995,03 | R$ 4,39 |
| Pedreiro, outros complementares | 0,0022 mês | R$ 1.542,58 | R$ 3,39 |
| Gesso cola (44324) | 0,010 kg | R$ 2,81 | R$ 0,02 |
| Bloco de gesso vazado (34584) | 1,027 m² | R$ 43,00 | R$ 44,16 |
| | | **Total** | **R$ 64,13** |

Duas diferenças estruturais aparecem aqui, e nenhuma delas é escolha nossa.

A alíquota de leis sociais é **71,18%**, contra 115% do horista. E a linha de leis sociais do mensalista tem **uma parcela só**: nos preços publicados, os encargos complementares mensalistas não trazem leis sociais embutidas, porque a composição mensalista não tem o curso de capacitação que, no horista, carregava mão de obra dentro.

### Etapa 5: lado a lado

| Linha | Horista | Mensalista | Δ |
|---|---:|---:|---:|
| **Servente, salário-base** | **R$ 2,53** | **R$ 2,53** | **0,00** |
| Servente, leis sociais | R$ 2,97 | R$ 1,80 | −1,17 |
| Servente, outros complementares | R$ 2,28 | R$ 1,68 | −0,60 |
| **Pedreiro, salário-base** | **R$ 6,16** | **R$ 6,16** | **0,00** |
| Pedreiro, leis sociais | R$ 7,24 | R$ 4,39 | −2,85 |
| Pedreiro, outros complementares | R$ 4,63 | R$ 3,39 | −1,24 |
| Gesso cola | R$ 0,02 | R$ 0,02 | 0,00 |
| Bloco de gesso vazado | R$ 44,16 | R$ 44,16 | 0,00 |
| **Total** | **R$ 69,99** | **R$ 64,13** | **−5,86** |

É esta tabela que responde à pergunta do título.

**As duas linhas de salário-base não se movem.** O pedreiro custa R$ 6,16 por metro quadrado antes e depois, o servente custa R$ 2,53 antes e depois. Mudou a unidade, mudou o coeficiente, mudou o preço unitário de referência, e o produto dos três permaneceu. O trabalho embutido no serviço continua o mesmo, remunerado pelo mesmo valor.

**Os materiais também não se movem**, o que é óbvio mas vale dizer: a conversão não passa perto do gesso nem do bloco.

**Os R$ 5,86 estão inteiros em quatro linhas laterais**, as de leis sociais e as de outros complementares. São elas que carregam a estrutura de cada regime, e são as únicas que mudam. Somadas: `1,17 + 0,60 + 2,85 + 1,24 = 5,86`.

### Sobre os centavos

As cinco tabelas fecham nos totais que o SINAPI publica, R$ 69,99 e R$ 64,13. Para isso, cada linha é truncada em dois decimais, como o sistema faz, e o centavo residual da composição auxiliar vai para a linha de maior resto descartado. É o que mantém a soma das partes igual ao todo em qualquer nível de abertura.

## Uma observação sobre casas decimais

Nas tabelas acima os valores aparecem em dois decimais, como na planilha. Por dentro, as duas linhas de salário-base fecham em zero absoluto: `0,484 × 12,74` e `0,0022 × 2.802,80` dão o mesmo R$ 6,16616, até a quinta casa. Isso acontece porque os coeficientes desta composição dividem exato por 220. Nem todo coeficiente se comporta assim: `0,399 ÷ 220` é dízima periódica, e aí a exatidão depende de o cálculo carregar todas as casas antes de arredondar.

É o que o Easy faz, e por isso a conversão fecha ao centavo. Vale saber que, em planilha montada à mão ou em outro modelo de cálculo, **arredondamentos intermediários podem produzir pequenas diferenças**. Elas são resíduo de arredondamento, não mudança de remuneração.

## Isto complementa, não contradiz

Já dissemos aqui que encargos sociais horista e mensalista **não se convertem por regra de três**. Continua valendo, e é o que a etapa 5 confirma: 115% e 71,18% não guardam proporção entre si, e as linhas de leis sociais dos dois regimes não guardam proporção entre si, nem com o fator 220. São modelos de cálculo distintos, cada um com sua base de incidência.

O que se converte é outra coisa. É a remuneração-base, pelo fator que o SINAPI publica, e só ela.

## A leitura jurídica

Converter regime é adaptar composição de sistema oficial de referência. Cai no art. 8º do Decreto 7.983/2013, que exige relatório técnico de profissional habilitado demonstrando a pertinência do ajuste.

O Acórdão 619/2024-Plenário reconhece a possibilidade de adaptar composições dos sistemas oficiais quando devidamente justificada e compatível com as condições de execução. Ele não prescreve a conversão por 220: dá suporte à adaptação tecnicamente demonstrada, que é o que um estudo como este produz.

E repare no sinal do resultado. Aqui o custo **caiu**, e ficar abaixo do teto do art. 3º é exatamente o que ele pede. Fosse ao contrário, o ajuste sairia do caput do art. 8º e cairia no parágrafo único, que exige condições especiais e aprovação do órgão gestor dos recursos. A direção da conversão decide qual regime jurídico se aplica, e por isso ela precisa aparecer na peça, não só o valor final.

## O que a memória de cálculo tem de registrar

A composição original, com código e descrição. O par horista e mensalista utilizado, por código. Edição, UF e regime de encargos. Os coeficientes originais e os convertidos. O fator 220, com remissão à metodologia da CAIXA. A verificação da identidade, com o resíduo quando houver. O sinal e o valor da diferença, por item e no total. E a justificativa da premissa mensalista.

Os sete primeiros qualquer auditor reconstrói da tabela. O último não está em tabela nenhuma: encargos de mensalista pressupõem trabalhador mensalista. Se a obra vai ser executada com mão de obra contratada por hora, o orçamento adotou um regime que não vai acontecer, e é a folha de pagamento que vai responder por isso depois.

## Um zoom dentro da hora

As etapas 3 e 4 agruparam os sete encargos complementares numa linha só. Vale abri-los, porque é aí que se vê **por que** essas linhas laterais mudam. As duas referências do pedreiro na mesma unidade, com o mensalista dividido por 220:

| Componente | Horista 88309 (por h) | Part. | Mensalista 101445 (÷ 220) | Part. | Δ |
|---|---:|---:|---:|---:|---:|
| **Remuneração-base** | **R$ 12,74** | 34,2% | **R$ 12,74** | 44,2% | **0,00** |
| Alimentação | R$ 4,48 | 12,0% | R$ 3,38 | 11,7% | −1,10 |
| EPI | R$ 1,47 | 3,9% | R$ 1,11 | 3,9% | −0,36 |
| Exames | R$ 1,43 | 3,8% | R$ 1,08 | 3,7% | −0,35 |
| Transporte | R$ 1,07 | 2,9% | R$ 0,80 | 2,8% | −0,27 |
| Ferramentas | R$ 0,73 | 2,0% | R$ 0,56 | 1,9% | −0,17 |
| Curso de capacitação 95371 | R$ 0,27 | 0,7% | não existe | | −0,27 |
| Seguro | R$ 0,11 | 0,3% | R$ 0,08 | 0,3% | −0,03 |
| Encargos sociais embutidos | R$ 14,96 | 40,1% | R$ 9,07 | 31,5% | −5,89 |
| **Custo da hora** | **R$ 37,26** | 100% | **R$ 28,82** | 100% | **−8,44** |

São três classes de linha, e convém lê-las separadamente.

**A linha idêntica** é a remuneração-base, pelo mesmo motivo da etapa 5.

**A linha que existe de um lado só** é o curso de capacitação, ausente da composição mensalista. Não é erro nem esquecimento: é apropriação própria de cada regime.

**As linhas que mudam de valor** são todas as demais. Nenhuma tem obrigação de convergir por 220, e forçar essa convergência seria o erro.

O zoom mostra ainda uma coisa que a conta global esconde: a participação da remuneração-base sobe de 34,2% para 44,2%, enquanto a dos encargos sociais cai de 40,1% para 31,5%. A composição interna do custo muda mais do que o total.

## O que levar

A conversão de regime não concede desconto sobre o SINAPI. Ela preserva, ao centavo, a remuneração-base associada à produtividade, e substitui a estrutura de uma referência oficial pela estrutura da outra.

Quem afirmar que o número menor é abatimento indevido precisa explicar por que `0,484 × 12,74` e `0,0022 × 2.802,80` dão o mesmo resultado.

No [Easy Orça™](https://www.axys-tec.com.br/easy-orca) a conversão é feita pelos pares oficiais e cada item convertido fica marcado na planilha, para que o que precisa ser justificado continue visível depois que a peça é salva.
