# Fine-tuning das associações entre fontes

Escrito para quem for ajustar o prompt de associação, hoje ou daqui a um ano — inclusive para
treinar modelo próprio com este material.

Cada regra aqui **nasceu de um caso real** que quebrou em produção de curadoria. O caso está junto
da regra de propósito: sem ele, a regra vira superstição e alguém a afrouxa "porque parece
exagerada". Com ele, a discussão passa a ser sobre o dado.

O que está no banco é o resultado. O que está aqui é **por que** o resultado é esse.

---

## Onde cada coisa mora

| | |
|---|---|
| prompt de insumo | `z_scripts_apoio/analise_associacoes/revisao_ia_curadoria.py` → `_DOUTRINA` |
| prompt de composição | idem → `_DOUTRINA_CPU` (adendo sobre a doutrina de insumo) |
| runner | `z_scripts_apoio/analise_associacoes/roda_associacoes.py` |
| contrato da tabela | `contracts/catalogo/vinculacoes.md` §14 (1×1 duro) |
| auditorias congeladas | `z_scripts_apoio/_out_associacoes/auditoria_rodada*/` |

---

## Linha do tempo das rodadas

| rodada | data | prompt | itens | aceites | achados da curadoria humana |
|---|---|---|---|---|---|
| amostra 1 (INS) | 2026-09-23 | v0 | 50 | 21 | validada 100% |
| amostra 2 (INS) | 2026-09-24 | v0 | 50 | 17 | validada 100% |
| amostra CPU | 2026-09-24 | v0 + adendo CPU | 50 | 8 | validada 100%; 2 "prováveis" recusadas por abrangência |
| **rodada 1 (INS)** | 2026-09-24 | v1 | 100 | 31 | **6 achados — ver abaixo** |

A rodada 1 é a primeira em volume e a primeira a quebrar. As amostras anteriores passavam porque
eram pequenas e porque o curador lia cada linha; o volume expôs o que a leitura atenta escondia.

---

## Os seis achados da rodada 1, e o que cada um gerou

### 1. O 1×1 global foi violado

`SINAPI 131` foi escolhido por **dois** itens CDHU: o adesivo epóxi bicomponente genérico e o de
alta viscosidade. Sob 1×1 rígido só um pode ficar — e o correto é o de alta viscosidade, que
corresponde ao "pastoso (tixotrópico)" do destino.

**Causa:** o runner processava em paralelo (6 threads) contra um universo de destino **congelado
antes do lote**. Cada chamada garantia uma escolha; nenhuma sabia o que a vizinha tinha acabado de
escolher. O prompt garante unicidade DENTRO de uma chamada, nunca ENTRE chamadas independentes.

**Correção — no código, não no prompt:** o runner virou **sequencial com exclusão viva**. O
destino escolhido sai do universo antes do próximo item partir:

```
livres = elegiveis_destino − tomados
1º item → candidatos → prompt → retorno → destino sai do universo → próximo
```

**Por que sequencial e não um reconciliador pós-rodada** (decisão do Renan, 2026-09-24, contra a
proposta inicial): colisão não pode chegar na tela. Duas linhas com o mesmo destino, depois de
trinta, viram aceite por cansaço — falha de produto, não do curador, e contra a política de
descomplicação. A objeção de que "quem chega primeiro é o alfabeto, não o mérito" foi respondida
com um argumento melhor: **itens alfabeticamente próximos são tecnicamente próximos**, então uma
escolha ruim aparece na linha vizinha à do irmão que ficou sem par, onde o olho pega na hora.
Custo: a rodada fica mais lenta. Aceito explicitamente.

### 2. Resposta que contradiz o próprio contrato

`B.06.000.021525 — AÇO CA-50-A $MD BITOLAS` voltou com `escolhido: 62` e **seis** candidatos
marcados `aceito: true` (bitolas 6,3 / 8 / 10 / 32 / 12,5-16 / 20-25). A planilha escondia o
problema porque só mostra `escolhido`; o JSON bruto contradizia a regra que o próprio prompt
declara.

**Correção — guarda determinística antes de arquivar**, com até 3 tentativas. Resposta incoerente
volta ao modelo com a queixa no campo `corrija`:

- `escolhido` tem de estar entre os candidatos oferecidos
- `aceito: true` **só** no escolhido
- sem escolha → nenhum aceito e fator nulo
- com escolha → fator obrigatório
- todo candidato oferecido precisa de entrada em `candidatos`

**Princípio:** o que é verificável por regra não se pede ao modelo, se **confere**. Modelo é
probabilístico; contrato não.

### 3. Associação materialmente errada

`S.04.000.039006` (adesivo/selador à base de emulsão PVA/acrílica) → `SINAPI 4791` (adesivo
acrílico de base aquosa / cola de contato). O parecer se apoiou em "ambos acrílicos à base de
água".

**Regra gerada:** base química não substitui **função**. Selador/ponte de aderência e cola de
contato são produtos comercialmente distintos. Virou a seção de viscosidade/consistência/aplicação
e o CASO 9 do prompt.

### 4. Abrangência assimétrica — a contradição era nossa

Oito ou mais aceites foram justificados **exatamente** pelo que o prompt proibia: "a origem é
genérica quanto à bitola", "o candidato apenas detalha", "especificação adicional compatível".

**Causa:** instrução conflitante, e a culpa é da doutrina, não do modelo. O adendo de CPU dizia
"abrangência assimétrica é recusa". A doutrina de insumo, escrita antes e ainda vigente, dizia o
contrário com todas as letras:

> a fonte ser MAIS GENÉRICA que o SINAPI (SINAPI "CIMENTO CP II-32" × fonte "CIMENTO"): a fonte
> descreve a mesma coisa com menos detalhe

O adendo foi escopado só para CPU justamente para não matar o `AÇO CA-25 $MD BITOLAS` que havia
sido aceito na curadoria manual. A IA aplicou a regra de insumo, que era a que valia para ela.

**Correção:** a linha acima é **revogada**, e no lugar entra `GENERALIDADE SÓ CASA COM
GENERALIDADE` — que não proíbe o genérico, exige que ele case com genérico:

```
CA-50 $MD BITOLAS  →  CA-50 VERGALHÃO      aceita   (ambos sem bitola determinada)
CA-50 $MD BITOLAS  →  CA-50 6,3 MM         recusa   (a origem não determina a bitola)
```

**Lição que vale além deste caso:** quando o modelo desobedece de forma consistente e articulada,
suspeite da instrução antes de suspeitar dele. Aqui ele estava obedecendo — à outra regra.

### 5. Fatores de conversão: nenhum erro

Incluindo o único diferente de 1, que estava correto: origem de adesivo PVC em KG × destino em
frasco de 850 g por UN → `1 / 0,85 = 1,1765`.

**O que já estava certo e fica registrado:** a conversão se debruça sobre a **unidade oficial**,
nunca sobre a descrição. `CIMENTO BRANCO (SACO 20 KG)` com `ins_unidade = KG` contra destino em KG
é fator **1**, não 0,05 — o "saco de 20 kg" é texto, não grandeza.

### 6. Negativas: nenhuma claramente invertida

Em 2.070 recusas, nenhuma invertida. Casos difíceis tratados corretamente: oxiacetileno em [H] ×
equipamento em [UN] recusado por falta de fator seguro; anel DN 150 genérico × anel DEFOFO
recusado por norma não comprovada; equipamentos recuperados por coincidência de vocabulário
recusados por função.

**Leitura:** o endurecimento melhorou mais as **recusas** que os **aceites**. Faz sentido — recusar
exige achar um atributo divergente, que está escrito; aceitar exige provar identidade, que é o
trabalho difícil. O prompt v2 ataca o lado do aceite.

---

## Regras estruturais, e de onde vieram

### Silêncio não é compatibilidade

Atributo ausente é **desconhecido**, nunca "qualquer valor serve". Se o destino declara variante
por dimensão, bitola, seção, viscosidade, classe, capacidade, tensão, pressão, tratamento,
aplicação ou configuração, e a origem não determina essa variante — recusa.

*Origem: achado 4.*

### Marca e modelo são evidência técnica, mas não há navegação

A origem frequentemente cita "REF. COMPOUND DA OTTO BAUMGART OU EQUIVALENTE". Essa referência
**resolve** atributos que o texto não escreveu — se o Compound é comprovadamente fluido, a origem
não é genérica quanto à consistência.

**Mas o modelo não tem internet nesta execução.** A instrução tem de dizer isso, senão a licença
para "consultar a ficha técnica" vira licença para inventar ficha técnica. O texto exige: usar só
o que se pode afirmar com segurança, **declarar no parecer** quando a propriedade veio da
referência e não do texto, e rebaixar a confiança. Sem segurança, trata-se como ausência real.

*Origem: revisão do prompt v2, antes de rodar — não chegou a gerar erro em produção.*

### Ambiguidade entre candidatos devolve null

Se dois ou mais candidatos continuam aplicáveis e a origem não traz o atributo que os distingue,
não se escolhe nenhum. Posição e score **não desempatam** — servem para recuperação, não para
decisão.

*Origem: a família AÇO CA-*, onde a primeira bitola ranqueada era escolhida por ser a primeira.*

### Abrangência tem direção; a tabela não tem

O par 1×1 converte nos dois sentidos, logo precisa ser verdadeiro nos dois. Teste sempre o sentido
que falha: do mais abrangente para o mais estrito.

`DEMOLIÇÃO DE CONCRETO SIMPLES` admite moldura decorativa; pagar isso como demolição de piso
desarruma a medição na obra. Específico→genérico é verdade; genérico→específico não.

**Trava contra excesso de zelo:** qualificador diferente sobre o **mesmo universo** vale.
`ESTACA RAIZ Ø45 EM SOLO` × `ESTACA RAIZ Ø45 SEM PRESENÇA DE ROCHA` são o mesmo conjunto de
serviços com palavras distintas. A pergunta não é "o texto é mais detalhado?" — é **"existe caso
que cabe num código e não cabe no outro?"**.

*Origem: amostra CPU de 2026-09-24, as duas "prováveis" (demolição e porta veneziana).*

### Escopo de fornecimento embutido (só composição)

A SINAPI paga conexão em composição própria; CDHU (123 composições) e FDE (119) embutem no metro
da tubulação. Se só um lado embute, os códigos não medem a mesma coisa — recusa, ainda que tubo,
DN, classe e unidade coincidam.

Confirma-se no analítico: 1,40 m de tubo por metro de serviço é 1,00 de tubo + 0,40 de
metro-equivalente de conexão; 1,03 é só perda de corte. A mão de obra acompanha (2 h × 0,53 h).
Este é o **único** uso legítimo do coeficiente na doutrina — confirmar o que o título disse, nunca
recusar por produtividade.

Não é proibição do termo: se os dois lados embutem, o par vale (a SINAPI tem 8).

*Origem: `46.07.070 TUBO GALVANIZADO DN 2 1/2", INCLUSIVE CONEXÕES` → `92342`, aceito por engano na
amostra CPU e reprovado na auditoria.*

### O analítico desambigua o título (só composição)

`LIMPEZA DE PISO COM PRODUTOS QUÍMICOS` não diz qual produto; o analítico diz `0,2 L ÁCIDO
MURIÁTICO`, e aí o par aparece. `BOTÃO DUPLO SEM SINALIZADOR` × `VERDE E VERMELHO` parece
contradição; o analítico mostra PULSADOR com capas coloridas, e a contradição some.

Quando não houver insumo representativo dos dois lados, decidir por serviço e unidade e
**declarar** que foi sem representativo.

*Origem: amostra CPU, os dois casos acima.*

### Entrega igual × entrega diferente

O critério que resolve faixa, adição e variante é **o que o item entrega**, não como o texto o
escreve nem quanto ele custa.

- `CP II-E`, `CP II-Z`, `CP II-F` na mesma classe: as letras são **adição mineral escolhida pela
  indústria conforme disponibilidade**. A entrega é a mesma — associam entre si.
- `RS` (resistente a sulfatos), `ARI`, `BC`: **ganho de propriedade declarado**. Entrega diferente
  — têm de coincidir, nunca se flexibilizam.
- Classe 32 × 40, família CP II × CP III: entrega diferente — recusa nos dois sentidos.
- Faixa `8 a 12 mm²` contra origem de `10 mm²`: ampacidade diferente dentro da faixa, ou seja,
  variantes que entregam coisas diferentes agrupadas num cadastro só — recusa.

Não confunda com **preço**: dois itens podem custar diferente e entregar o mesmo (marca, embalagem,
fornecedor), e é por isso que o preço nunca entra na decisão.

*Origem: revisão do prompt v2 com o Renan, 2026-09-24. A distinção E/Z/F × RS veio dele e eliminou
a necessidade de uma exceção especial para cimento — o critério geral já resolve.*

### Coeficiente não julga identidade (só composição)

Duas composições corretas do mesmo serviço têm produtividades diferentes. Cerca com 8 fios de
arame × 11 fios **não** recusa — o representativo (mourão + arame farpado) é que decide. Mão de
obra e equipamento não entram na decisão: são produtividade, não identidade.

*Origem: `34.05.030 CERCA EM ARAME FARPADO` → `106460`, aceito corretamente apesar do coeficiente
divergente.*

---

### Por que 1×1 é a única forma admissível — e por que a pré-curadoria é script, não prompt

**A tabela existe para migrar dado de uma fonte para outra sem regressão nem prejuízo.** Tudo se
deduz disso. Migrar sem regressão é a volta ser a ida; só a bijeção garante. A forma admissível é
uma: *isto equivale àquilo* — nunca *isto equivale a isto, àquilo e àquele outro*.

*Origem: Renan, 2026-09-26, depois de ver quatro soalhos de tábua da FDE, com larguras e vigamentos
diferentes, todos apontando para o mesmo `ASSOALHO DE MADEIRA` da SINAPI.*

**A unicidade não é julgamento — é aritmética sobre o conjunto.** E por isso não pode morar no
prompt. O worker que julgou `TACHA TIPO I BIDIRECIONAL REFLETIVA` não tinha como saber que outras
cinco tachas iam para o mesmo destino: cada item é uma chamada isolada, e a colisão só existe
depois que todas voltaram. Pedir à IA que garanta unicidade é pedir que ela saiba o que ela não
viu. **A verificação é passo posterior, determinístico e reexecutável.**

Medido na CDHU→SINAPI de 2026-09-25 (379 pares propostos): **47 destinos disputados por 2+ origens,
111 propostas envolvidas — 29% dos pares.** Os campeões:

| origens | destino | o que a SINAPI reparte e a origem não |
|---|---|---|
| 6 tachas | `TACHA SOBRE ASFALTO` | tipo I/II, mono/bidirecional, resina |
| 5 formas em tubo de papelão | `FÔRMA DE PILARES CIRCULARES` | Ø 25, 35, 40, 45, 50 cm |
| 4 porcelanatos | `REVESTIMENTO CERÂMICO PARA PISO` | natural/esmaltado, polido/acetinado |

**Duplicata dentro da fonte nega os dois lados.** FDE tem `03.03.014` e `16.14.034`, ambos
`CONCRETO DOSADO E LANCADO FCK= 20 MPA`, **analítico idêntico até o coeficiente** — os mesmos 1,62
pedreiro, 1,62 servente, 1,02 concreto, 0,10 vibrador. Diferem só no subgrupo: `CONCRETO` contra
`MUROS DE ARRIMO - CONCRETO ARMADO`. É duplicata de navegação: a FDE repete o serviço em cada
capítulo onde ele é usado.

A saída tentadora era eleger um canônico e ligar o gêmeo a ele. **Foi recusada, e pelo argumento
que a sustentava:** escolher é assimétrico e some — o orçamento que usou o outro código perde a
conversão sem aviso, e qual é "o outro" depende do capítulo que o orçamentista estava folheando.
Negar os dois é simétrico e **visível**. A fonte se declara polêmica ao criar duas composições
distintas com a mesma descrição; o parecer da negativa devolve o defeito a quem o criou.

Medido em 2026-09-26: **FDE 165 grupos / 379 composições (11,2%)**; CDHU 1 grupo / 2 insumos;
SINAPI nenhum, em nada.

**Negar não deixa o usuário sem saída — deixa com a melhor.** Itens de descrição parecida têm
insumo parecido, e a conversão na bancada migra os **insumos** de A para B mantendo os
coeficientes da origem. É mais fiel que um vínculo de composição escolhido no chute, e tem a mesma
virtude de poder escolher qual composição usar entre as que remuneram a mesma coisa: constrói-se
composição diversa com os insumos da fonte preferida. **A equivalência de composição é atalho
quando é indiscutível; quando não é, o caminho pleno já existe e é melhor.**

**O prompt não foi mexido, e as rodadas não foram refeitas.** Ele nasceu para determinar ou negar
o máximo possível com a máxima confiança, sem chute, e cumpriu isso. A regra de unicidade entra
depois, por script, sobre o que ele produziu.

**MDO fica fora.** Lá o destino não é exclusivo por natureza — esgoteiro e poceiro caem os dois em
encanador — e a unicidade é só `(origem, fonte destino)`.


## Decisões de arquitetura que sustentam o prompt

**A IA nunca decide status.** Ela propõe e justifica — a escolha E cada recusa. Quem confirma ou
rejeita é gente, em tela, por `decidir()`, com usuário e auditoria.

**Texto de IA não entra em tabela.** A justificativa vive no JSON, que é o material da tela e deste
fine-tuning. No banco vão método e score, nada de prosa.

**Um arquivo por item**, não um acumulado: `associacoes/{ori}_{dest}/{tipo}_{id}.json`. No
acumulado qualquer alteração invalida o arquivo inteiro; por item, o import de uma edição
reprocessa os 12 que mudaram, não os 3.549.

**`candidatos_vistos` é o que permite o reuso.** São os ids que a IA já examinou. Na edição
seguinte, mesma lista → não volta para a IA; um candidato novo → volta, porque o universo mudou.
Sem isso, item recusado hoje ficaria recusado para sempre, ainda que a fonte destino publicasse o
par certo amanhã.

---

## Em aberto

- **Convergência da rodada 1** — rerodar os mesmos 100 com o prompt v2 e medir: quantos dos 31
  sobrevivem, quantos dos 69 mudam, se os 8 casos de abrangência viram null, se a colisão some.
