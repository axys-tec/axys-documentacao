# Conversão de mão de obra horista para mensalista em composições SINAPI

## Estudo técnico demonstrativo, Easy

**Base:** SINAPI/SP, agosto/2026. **Regime:** SD.
**CPU estudada:** 101157, alvenaria de vedação de blocos de gesso 7x50x66 cm, AF_05/2020, M².

## 1. Tese demonstrada

A conversão não pressupõe equivalência entre os custos completos H e MES. Os regimes possuem encargos sociais e complementares diferentes.

O teste de fidelidade é a remuneração-base associada à produtividade:

```math
MO mensalista base = 220 × MO horista base
```

Logo, para um coeficiente produtivo q:

```math
q × MO horista base = (q / 220) × MO mensalista base
```

A CAIXA publica a conversão:

```math
custo mensalista = (custo horista / (1 + ES horista)) × 220 × (1 + ES mensalista)
```

Isto é: retira-se o encargo horista, converte-se a remuneração-base por 220 e aplica-se o encargo mensalista.

Fonte: https://www.caixa.gov.br/Downloads/sinapi-metodologia/Livro_SINAPI_Metodologias_Conceitos.pdf

## 2. Prova pela mão de obra sem encargos

| Profissional | Código H | Base H | Código MES | Base MES | MES ÷ 220 |
|---|---|---|---|---|---|
| Pedreiro | 4750 | R$ 12,74/H | 41065 | R$ 2.802,80/MES | **R$ 12,74/H** |
| Servente | 6111 | R$ 10,47/H | 41084 | R$ 2.303,40/MES | **R$ 10,47/H** |

```math
12,74 × 220 = 2.802,80
10,47 × 220 = 2.303,40
```

A remuneração-base converge exatamente.

## 3. CPU 101157 original, SD

| Tipo | Código | Descrição | Unid. | Coef. | Unit. | Total |
|---|---|---|---|---|---|---|
| CPU | 88316 | Servente com encargos complementares | H | 0,242 | R$ 32,18 | R$ 7,78 |
| CPU | 88309 | Pedreiro com encargos complementares | H | 0,484 | R$ 37,26 | R$ 18,03 |
| INS | 44324 | Gesso cola | KG | 0,010 | R$ 2,81 | R$ 0,02 |
| INS | 34584 | Bloco de gesso vazado | M² | 1,027 | R$ 43,00 | R$ 44,16 |
| | | **Total** | | | | **R$ 69,99** |

Produtividade: **0,484 H de pedreiro + 0,242 H de servente por m²**.

## 4. CPU 101157 em SE

| Código | Descrição | Coef. | Unit. | Total |
|---|---|---|---|---|
| 88316 | Servente com encargos complementares | 0,242 H | R$ 19,89 | R$ 4,81 |
| 88309 | Pedreiro com encargos complementares | 0,484 H | R$ 22,30 | R$ 10,79 |
| 44324 | Gesso cola | 0,010 KG | R$ 2,81 | R$ 0,02 |
| 34584 | Bloco de gesso vazado | 1,027 M² | R$ 43,00 | R$ 44,16 |
| | **Total** | | | **R$ 59,78** |

SE ainda contém encargos complementares; por isso as CPUs de mão de obra precisam ser explodidas.

## 5. Explosão do pedreiro

### 88309, horista SD

| Componente | Valor/H |
|---|---|
| Pedreiro 4750 | R$ 27,39 |
| Alimentação | R$ 4,48 |
| EPI | R$ 1,47 |
| Exames | R$ 1,43 |
| Transporte | R$ 1,07 |
| Ferramentas | R$ 0,73 |
| Curso de capacitação 95371 | R$ 0,58 |
| Seguro | R$ 0,11 |
| **Total** | **R$ 37,26** |

### 88309, sem encargos sociais

| Componente | Valor/H |
|---|---|
| **Pedreiro, base** | **R$ 12,74** |
| Alimentação | R$ 4,48 |
| EPI | R$ 1,47 |
| Exames | R$ 1,43 |
| Transporte | R$ 1,07 |
| Ferramentas | R$ 0,73 |
| Curso | R$ 0,27 |
| Seguro | R$ 0,11 |
| **Total** | **R$ 22,30** |

### 101445, mensalista SD

| Componente | Valor/MES |
|---|---|
| Pedreiro 41065 | R$ 4.797,83 |
| Alimentação | R$ 743,12 |
| EPI | R$ 244,86 |
| Exames | R$ 237,03 |
| Transporte | R$ 176,94 |
| Ferramentas | R$ 122,35 |
| Seguro | R$ 18,28 |
| **Total** | **R$ 6.340,41** |

### 101445, sem encargos sociais

| Componente | Valor/MES |
|---|---|
| **Pedreiro, base** | **R$ 2.802,80** |
| Alimentação | R$ 743,12 |
| EPI | R$ 244,86 |
| Exames | R$ 237,03 |
| Transporte | R$ 176,94 |
| Ferramentas | R$ 122,35 |
| Seguro | R$ 18,28 |
| **Total** | **R$ 4.345,38** |

A CPU mensalista não possui o curso existente na horista. EPI e demais complementares também possuem apropriações próprias. Eles não devem ser forçados a convergir por 220. O que converge é:

```math
2.802,80 = 12,74 × 220
```

## 6. Explosão do servente

### 88316, horista SD

| Componente | Valor/H |
|---|---|
| Servente 6111 | R$ 22,51 |
| Alimentação | R$ 4,48 |
| EPI | R$ 1,54 |
| Exames | R$ 1,43 |
| Transporte | R$ 1,07 |
| Ferramentas | R$ 0,57 |
| Curso | R$ 0,47 |
| Seguro | R$ 0,11 |
| **Total** | **R$ 32,18** |

### 88316, sem encargos sociais

| Componente | Valor/H |
|---|---|
| **Servente, base** | **R$ 10,47** |
| Alimentação | R$ 4,48 |
| EPI | R$ 1,54 |
| Exames | R$ 1,43 |
| Transporte | R$ 1,07 |
| Ferramentas | R$ 0,57 |
| Curso | R$ 0,22 |
| Seguro | R$ 0,11 |
| **Total** | **R$ 19,89** |

### 101452, mensalista SD

| Componente | Valor/MES |
|---|---|
| Servente 41084 | R$ 3.942,96 |
| Alimentação | R$ 743,12 |
| EPI | R$ 256,38 |
| Exames | R$ 237,03 |
| Transporte | R$ 176,94 |
| Ferramentas | R$ 95,69 |
| Seguro | R$ 18,28 |
| **Total** | **R$ 5.470,40** |

### 101452, sem encargos sociais

| Componente | Valor/MES |
|---|---|
| **Servente, base** | **R$ 2.303,40** |
| Alimentação | R$ 743,12 |
| EPI | R$ 256,38 |
| Exames | R$ 237,03 |
| Transporte | R$ 176,94 |
| Ferramentas | R$ 95,69 |
| Seguro | R$ 18,28 |
| **Total** | **R$ 3.830,84** |

```math
2.303,40 = 10,47 × 220
```

## 7. Conversão dos coeficientes

```math
0,484 H / 220 = 0,0022 MES
0,242 H / 220 = 0,0011 MES
```

O fator 220 não afirma que existam 220 horas fisicamente produtivas. Ele reproduz a relação remuneratória entre as referências-base H e MES publicadas pelo SINAPI.

## 8. Teste decisivo dentro da alvenaria

### Pedreiro

```math
0,484 × 12,74 = 6,16616
0,0022 × 2.802,80 = 6,16616
```

### Servente

```math
0,242 × 10,47 = 2,53374
0,0011 × 2.303,40 = 2,53374
```

Diferença nos dois casos: **R$ 0,00000**.

### Total da remuneração-base

```math
6,16616 + 2,53374 = 8,69990
```

O mesmo valor é obtido nos dois regimes.

## 9. Recomposição completa, SD

Horista:

```math
0,484 × 37,26 = 18,03384
0,242 × 32,18 = 7,78756
MO horista = 25,82140
```

Mensalista:

```math
0,0022 × 6.340,41 = 13,948902
0,0011 × 5.470,40 = 6,017440
MO mensalista = 19,966342
```

Diferença:

```math
25,82140 - 19,966342 = 5,855058
```

Arredondamento da composição: **R$ 5,86**.

## 10. Explosão final em duas linhas

| Parcela | Horista | Mensalista convertido | Diferença |
|---|---|---|---|
| **Remuneração-base associada à produtividade** | **R$ 8,69990** | **R$ 8,69990** | **R$ 0,00000** |
| Estrutura adicional do regime | R$ 17,12150 | R$ 11,266442 | R$ 5,855058 |
| **Mão de obra completa** | **R$ 25,82140** | **R$ 19,966342** | **R$ 5,855058** |

A conversão não reduz salário-base e não altera a produtividade. A diferença está integralmente na estrutura adicional das referências oficiais: encargos sociais, encargos complementares e demais componentes aplicáveis a cada regime.

## 11. Composição convertida pelo Easy

| Tipo | Código | Descrição | Unid. | Coef. | Valor unit. | Total aproximado |
|---|---|---|---|---|---|---|
| CPU | 101452 | Servente mensalista com encargos complementares | MES | 0,0011 | R$ 5.470,40 | R$ 6,02 |
| CPU | 101445 | Pedreiro mensalista com encargos complementares | MES | 0,0022 | R$ 6.340,41 | R$ 13,95 |
| INS | 44324 | Gesso cola | KG | 0,010 | R$ 2,81 | R$ 0,02 |
| INS | 34584 | Bloco de gesso vazado | M² | 1,027 | R$ 43,00 | R$ 44,16 |

Mantidos os cálculos internos sem arredondamento intermediário, a diferença de mão de obra é aproximadamente **R$ 5,86/m²**, coerente com a passagem de cerca de R$ 69,99 para R$ 64,13 na apresentação do Easy.

## 12. Interpretação

O coeficiente da CPU responde: **quanto trabalho é necessário para produzir uma unidade do serviço?**

O regime responde: **como o custo desse trabalhador é apropriado?**

Ao converter `q H` para `q/220 MES`, o Easy não concede desconto sobre o SINAPI. Ele preserva a remuneração-base da produtividade e substitui a referência horista pela correspondente referência mensalista oficial.

Não há motivo para que os custos adicionais convirjam. O mensalista possui estrutura distinta: curso pode não existir; EPI, alimentação, transporte, exames, ferramentas e seguro possuem apropriações próprias; os encargos sociais também são menores e estruturalmente diferentes.

## 13. Adaptação da composição

O Acórdão TCU 619/2024-Plenário reconhece a possibilidade de adaptação de composições de sistemas oficiais quando devidamente justificada e compatível com as condições de execução do empreendimento. O acórdão não prescreve especificamente `H → MES/220`; ele dá suporte à possibilidade de adaptar a referência, desde que a adaptação seja tecnicamente demonstrada.

A memória de cálculo deve registrar: composição original, pares H/MES utilizados, edição/UF/regime, coeficientes originais, fator 220, identidade da remuneração-base e justificativa da condição mensalista.

Fonte TCU: https://pesquisa.apps.tcu.gov.br/documento/acordao-completo/%2A/NUMACORDAO%253A619%2520ANOACORDAO%253A2024%2520/DTRELEVANCIA%2520desc%252C%2520NUMACORDAOINT%2520desc/0

## 14. Conclusão

No estudo da composição 101157:

```math
0,484 × 12,74 = (0,484 / 220) × 2.802,80
0,242 × 10,47 = (0,242 / 220) × 2.303,40
```

A parcela de remuneração-base é **R$ 8,69990/m² em ambos os regimes**.

A diferença de aproximadamente **R$ 5,86/m²** surge somente após a aplicação das estruturas próprias das CPUs horista e mensalista.

Assim, quando a premissa técnica do orçamento é a utilização de mão de obra mensalista e existe referência mensalista oficial correspondente, a conversão aplicada pelo Easy preserva a remuneração-base da produtividade original e permite que o custo reflita a estrutura efetivamente aplicável ao regime mensalista.

---

## Referências

- CAIXA Econômica Federal, SINAPI: Metodologias e Conceitos.
- CAIXA Econômica Federal, SINAPI: Cálculos e Parâmetros.
- SINAPI/SP, agosto de 2026.
- TCU, Acórdão 619/2024-Plenário.
- Arquivo de estudo: `ESTUDO.xlsx`.
