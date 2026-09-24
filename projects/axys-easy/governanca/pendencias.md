# Axys Easy — Pendências de Governança

**Status:** Vivo
**Data:** 2026-06-03
**Escopo:** decisões de governança/arquitetura ainda não fechadas.

> Lista de pendências. Itens marcados `[ ]` estão abertos; `[x]` concluídos.

---

## Catálogo Colaborativo

Referência: [../modules/catalogo/AXYS_CATALOGO_COLABORATIVO_v0.md](../modules/catalogo/AXYS_CATALOGO_COLABORATIVO_v0.md) · [roadmap.md](roadmap.md)

- [ ] Definir arquitetura definitiva do Catálogo Colaborativo
  - [ ] Definir modelo de curadoria
  - [ ] Definir workflow de aprovação
  - [ ] Definir mecanismo de reputação
  - [ ] Definir política de versionamento
  - [ ] Definir política de licenciamento de contribuições
  - [ ] Definir critérios de promoção para catálogo oficial
  - [ ] Avaliar indexação e busca pública
  - [ ] Avaliar impactos de armazenamento

---

## Bancada — pontos de revisão

> Contêiner dos pontos de revisão da bancada (Renan tem ~13 a acrescentar). Trabalhar
> quando a frente da bancada for aberta; por ora só registrados.

- [ ] **Caderno de Encargos reflete a composição ADAPTADA da bancada.** A CTA/CTC (descritivo)
  em si não muda, mas a **composição dela** muda quando o item, na bancada, sofreu **rotação de
  regime** (mensalista↔horista, badge REG) ou **conversão de MDO/insumo** (`converter_mdo`/
  `converter_ins`). Nesses casos o Caderno deve refletir **o que está na BANCADA** (composição
  adaptada), não a CTC crua do R2. **Escopo (rigor):** aplica-se SÓ ao caderno sobre o que está
  na bancada — **NÃO** afeta os cadernos técnicos das EDIÇÕES do catálogo (esses seguem a fonte).
- [ ] **Composição própria sem descritivo bloqueia o Caderno de Encargos.** Composições próprias,
  ao serem criadas, não carregam descritivo (CTC) → não entram no caderno. Resolver: ou o
  descritivo passa a fazer parte da composição própria na criação, ou abre-se um campo para o
  usuário digitar antes da geração. (Provável item da revisão geral da bancada.)

---

## Conversão entre fontes — fator NULL, exceção e derivação (2026-09-22)

> **Importa muito.** Nasce do refactor de associações (`REFACTOR_ASSOCIACOES_PLANO.md`), mas é
> decisão de PRODUTO sobre a bancada, não de schema.

### O caso da pia
O fator de conversão tem três estados (`vinculacoes.md` §3.4): `1` direta · `k` calculada ·
**`NULL` especial**. `NULL` = mesmo item, unidade diferente, e a conversão **depende de
quantitativo que só a obra sabe** — limpeza de pia cobrada por **m²** contra o item por **un**.
Quantas pias cabem num m²? Depende da obra.

Na planilha da fonte está **1,2 m²**. Ao converter para a favorita, a app **não pode** trocar por
1,2 un. O `NULL` não é uma limitação: é o que **devolve o poder de decisão ao usuário**.

### Os dois caminhos — e por que dependem do que o item É
- **Se é SERVIÇO** (linha de orçamento): o orçamento resolve — o usuário ajusta o quantitativo ali.
- **Se é INSUMO ou SUBCOMPOSIÇÃO (filha)**: **não dá para resolver na bancada**. A quantidade está
  dentro da receita de outra composição. Tem de ser gerada uma **composição própria**.

Daí nascem dois motores que a bancada ainda não tem:

- [ ] **Motor `exceção de conversão`** — caminho A: **não converte**. O item permanece o original,
  da fonte original, e **não respeita a regra geral** de convergir para a favorita. É explícito e
  auditável, não silencioso.
- [ ] **Motor `derivar composição`** — caminho B: cria uma **composição própria** sobre o item; o
  usuário tira os `1,2 m²` e põe `1 un`. É onde o quantitativo da obra entra.

### O que falta na tela (a dívida que já existia e ficou visível)
- [ ] **Distinguir "sem equivalente" de "equivalente que precisa de quantitativo".** Hoje os dois
  deixam o item nativo, sem aviso — o usuário não fica sabendo que existe um equivalente esperando
  por ele. Antes do refactor era pior (assumia fator **1**, calado, podendo errar por ordem de
  grandeza); agora está **certo e calado**. Falta o **avisado**: "opa, aqui não vai direto — ou
  você não converte, ou você deriva".
- [ ] **Guardar a QUANTIDADE ANTERIOR à conversão.** Toda conversão tem de registrar o quantitativo
  de origem, sempre. É auditoria: sem isso não se explica como `1,2 m²` virou `1 un`, nem se
  reconstrói o orçamento. Vale para os dois motores acima e para a conversão direta.

---

## Vinculação entre fontes — redesenho (pensar no próximo ajuste)

Hoje: MDO-fonte→SINAPI (estrela com hub SINAPI) + pares curados. **Problema:** ligar todas as
fontes par-a-par é O(n²) (`n(n-1)/2` pares; cada fonte nova nasce com n-1) — inviável de curar à
mão; e a estrela-SINAPI **perde caminho** quando o conceito não existe no SINAPI (ex.: quer CDHU
primária e só há CDHU↔FDE direto, não CDHU↔SINAPI↔FDE).

**Direção decidida (2026-09-14, execução adiada):** HUB CANÔNICO **neutro** (não precisa ser AXYS,
nem SINAPI). Tabelas tipo `agrupador_insumos`+itens e `agrupador_composicoes`+itens (cabeçalho
canônico; itens entram como **fonte/código**). Cada fonte mapeia **1×** ao canônico → **O(n)**, e o
canônico é a **união** (mata o "não tem no SINAPI").
- **Insumo = coisa** → dicionário de *coisas* (equivalência exata; substituição via canônico).
- **Composição = texto/serviço** → dicionário de *serviços*; a **receita fica por-fonte** (mesmo
  serviço, receitas diferentes é OK). **Favoritar fonte** vira "qual fonte realiza o serviço" +
  fallback pelo nó canônico — **não** converter receita. Encolhe `converter_mdo`/`converter_ins`.
- Eixo separado: substituição fina de insumo/MDO dentro da receita (H↔MÊS) segue via *coisa*.

**Ressalva (por que adiar):** mesmo O(n) é MUITA curadoria (múltiplas fontes/composições,
re-curadas **a cada edição**). Precisa de estratégia de curadoria viável (IA-assistida com confiança
alta, que hoje não há) antes de valer a pena. Adiado junto com a revisão geral da bancada.
Ver: `../modules/catalogo/CATALOGO_VINCULACOES_INTRA_FONTES.md`, favoritar-fonte na bancada.

---

## Desempenho — investigar infraestrutura de back (não é o servidor)

**Sintoma (Renan, 2026-09-16):** stacks/ambientes **antigos com MAIS dados** respondem **mais rápido**
que os atuais — o que descarta "faltou servidor/CPU". A suspeita é **infraestrutura de back** (não a
máquina): candidatos a investigar — plano/conexão do Postgres (pooler, latência web↔DB, região),
ausência/decaimento de índices, planos de query degradados (estatísticas/VACUUM/ANALYZE), N+1 nas
telas, cache frio (Redis TTL/eviction), cold start dos serviços Render. 
- [ ] Medir latência real por camada (web→DB, query pura, render de template) num endpoint lento
      conhecido, comparando o ambiente rápido (antigo) × o atual — isolar ONDE está o tempo.
- [ ] Conferir índices e `EXPLAIN ANALYZE` das queries quentes; rodar `ANALYZE` e comparar planos.
- [ ] Revisar pooler/região dos 3 serviços (web/worker/mobile) × banco — RTT por round-trip.
- [ ] Cache do catálogo: hit-rate e se o rewarm pós-restart está acontecendo.

---

## FDE — descrições com DOIS itens colados (parser da analítica)

**Sintoma (Renan, 2026-09-23, achado durante a curadoria de equivalências):**

```
FDE 6.30.77  TUBO DE COBRE CLASSE "E" DN=1 1/4" (35MM) P/AGUA QUENTE
             ‖ TUBO DE COBRE NBR13206 CLASSE "E" DN 15 MM (1/2") AGUA QUENTE INCL CONEXOES COM
```

**Medido em dev:** 105 insumos FDE com 110+ caracteres; em **90** deles a cauda é, literalmente, o
**início da descrição de outro item** do catálogo. Não é limite de coluna (`ins_descricao` é `text`)
— o corte em ~160 caracteres é o fim da linha física do PDF.

**Causa:** `fde_analitica_pdf_parser.py:252-258` cola na descrição as linhas anterior e seguinte
quando elas "parecem continuação", e `is_continuation_line()` (:172) devolve `True` para QUALQUER
linha que não seja cabeçalho/rodapé e da qual não se extraia um código. Quando o código de um item
novo não é reconhecido, o item inteiro vira continuação do anterior. A pista está nos códigos que
vazam — `16.06.047`, `16.07.045`, `06.03.066`: formato **2-2-3 dígitos**, que `extract_insumo_code`
não reconhece, diferente do `d.dd.dd` do resto do FDE.

**Impacto imediato:** os pares de equivalência que envolvem esses 90 itens **não são decidíveis** —
a descrição não descreve um item só. Ficaram como `INDECIDIVEL` na curadoria.

### Caminho de correção proposto (Renan) — e candidato a via OFICIAL

Prioridade declarada: **não deixar insumo/preço de fora**. Perder item é pior que descrição suja.

1. **MarkItDown** — converter o PDF para Markdown em vez de reconstruir linhas por coordenada de
   palavra. A estrutura de tabela sai pronta e o "parece continuação" deixa de ser heurística.
2. **Ao tomar o PREÇO do insumo, revisar a descrição.** O scraper do portal FDE já busca preço item
   a item (`fde_insumos_to_csv.get_price`) e a resposta traz a descrição **canônica da fonte**.
   Usar essa descrição para corrigir/validar a que veio do PDF fecha o ciclo sem custo novo: quem
   tem a verdade é o portal, não o PDF.

### Protocolo obrigatório para aplicar (a lição do carimbo)

Conserto de parser **só entra com diff antes/depois contra o PDF real** — foi assim que o carimbo
de emissão foi corrigido (3.380 linhas medidas, 78→0, zero dano colateral). Sem isso, troca-se um
defeito conhecido por um desconhecido.
- [ ] rodar o parser atual, guardar a saída como linha de base;
- [ ] aplicar a correção; rodar de novo; **diferenciar item a item**;
- [ ] critério de aceite duplo: as 90 descrições limpas **E** a contagem de insumos/preços
      **não pode cair**;
- [ ] `sanity_check()` do próprio arquivo não pega isto — ele só reprova acima de 20 descrições
      suspeitas, e o critério dele não olha comprimento nem colagem. Endurecer junto.


---

## PROD — drop/recreate de equivalencias_ins e equivalencias_cpu

**Feito em dev em 2026-09-23** (1.701 + 494 linhas descartadas, tabelas recriadas pelo `schema.sql`
com a regra 1×1 — ver `contracts/catalogo/vinculacoes.md` §14). **Falta fazer em prod.**

- [ ] **Só depois de validar o matcher em dev.** A ordem importa: o matcher precisa aprender a
      emitir UM candidato por item por fonte, senão a carga em prod bate no índice e para;
- [ ] `DROP TABLE catalogo.equivalencias_ins, catalogo.equivalencias_cpu CASCADE` em prod e
      recriar pelos blocos do `schema.sql` (tabela + 2 uniques + 2 índices + trigger de guarda);
- [ ] **`equivalencias_mo` NÃO entra** — rito próprio, já resolvida, e tem curadoria humana viva lá
      (34 pares confirmados pelo Renan);
- [ ] migrar os dados só DEPOIS: a carga tem de nascer já 1×1;
- [ ] conferir que o CHECK e os dois uniques existem em prod antes de qualquer INSERT.

**O que se perde no drop:** em prod, 357 ins + 589 cpu `pendente` não curados — descartáveis por
definição (proposta de máquina). Em dev, a curadoria do Maicon e a do Renan de 22-23/09 já estavam
exportadas em `z_scripts_apoio/analise_associacoes/curadoria_maicon.json` e
`curadoria_propostas_matcher.json`, que casam por CÓDIGO e sobrevivem a rebuild de id.

---

## Matcher por busca — estado em 2026-09-24 e o que falta

O matcher deixou de raciocinar. Não infere família, não compara raiz, não arbitra número: chama
`provider_search` nos dois modos (postgres e elastic), intercala as posições com dedup e corta em
30. Scripts: `monta_candidatos.py` (INS) e `monta_candidatos_cpu.py` (CPU). Nenhum dos dois decide
nem grava no banco — produzem o material da curadoria.

**Por que os dois motores, e por que intercalar.** Eles erram em lugares diferentes: em CPU, 61%
das candidatas vieram de um motor só (33.056 só elastic, 31.502 só postgres, 41.909 ambos). O RRF
foi testado e REPROVADO: premia concordância, e quando o certo é o que só um motor enxerga o
prêmio vira punição — o `CABO TORCIDO FLEXÍVEL 2x2,5MM²`, 1º do elastic e fora dos 100 do
postgres, caía para 46º. Intercalado, o pior caso de 38 associações curadas foi 15º.

**Por que não cortar por score.** Testado duas vezes e reprovado nas duas. Como régua de corte,
custava o dobro de payload na mesma cobertura e estourava em 154 candidatos. Como PISO ("não tem
par, nem chama a IA"), pior: itens SEM par pontuam IGUAL ou MAIS ALTO que itens com par (mediana
ES 282 x 226) — score mede semelhança textual com o índice, não existência de equivalente.

**Medido em curadoria (98 itens, IA propondo e Renan validando 100%):**

| | INS | CPU |
|---|---|---|
| itens curados | 100 (2 amostras) | 50 |
| associações aceitas | 38 (38%) | 8 (16%) |
| pior posição do aceito | 15º | 10º |
| perderia com 1 motor só | pg 2, es 4 | pg 2, es 0 |

### Pendências

- [ ] **Fator de conversão devolvido pela IA**, com justificativa. Duas armadilhas: (a) `ori`/`dest`
      é POSIÇÃO DE ARMAZENAMENTO, não direção — o trigger canoniza pela `fte_id` e pode inverter o
      par depois da IA; o fator tem de vir amarrado a QUAL LADO MULTIPLICA; (b) a conversão se
      debruça sobre a **unidade do item**, não sobre a descrição — `CIMENTO BRANCO (SACO 20 KG)`
      com `ins_unidade = KG` contra destino em KG é 1×1, não 0,05.
- [ ] **Analítico sem mão de obra na saída de CPU**, e o prompt dizendo por quê. MDO e equipamento
      são produtividade, não identidade, e não apareceram em nenhum parecer. Corrigir o cabeçalho
      do `monta_candidatos_cpu.py`, que hoje afirma o contrário.
- [ ] **JSON isolado por id**: `associacoes/{ins,mo,cpu}/{fonte_ori}_{fonte_dest}/{id}.json`. No
      acumulado, qualquer alteração invalida o arquivo inteiro; por id, a comparação de hash fica
      granular e o import por edição reprocessa 12 itens em vez de 3.549.
- [ ] **Persistência banco/R2 com reuso.** Banco: associados com parecer. R2: recusados e
      não-associados. Três usos: (1) associado sem alteração de hash não volta para a IA; (2)
      negado idêntico ao request anterior é excluído no import; (3) par já curado sai do matcher.
      A cada edição o request roda só sobre a novidade — daí a importância de guardar os negados.
- [ ] **IA pedir o analítico sob demanda** em vez de carregá-lo sempre (o arquivo completo de CPU
      tem 227 MB; a amostra de 50 tem 3,2 MB, grande demais para um worker). Amarra obrigatória: o
      que ela buscar é insumo para o parecer, nunca decisão dela.
- [ ] **Guarda numérico não conhece kgf × daN** (1 kgf = 0,98 daN). Caso real: `POSTE CIRCULAR H=11M
      P/600KGF` — a SINAPI só tem 200-400 daN em circular de 11 m; o 600 daN de 11 m é DUPLO T.
      Recusa correta, mas pela seção, não pelo número.
- [ ] **Medir o corte de CPU.** 30 candidatas está sobrando (pior aceito em 10º), mas com 8
      decisões não dá para fixar número. Repetir com a próxima amostra.
- [ ] **Elastic rende menos em CPU** — nenhuma aceita veio só dele, contra 2 só do postgres.
      Hipótese: descrição de composição é longa e narrativa. Observar na próxima leva.

### Doutrina endurecida (`_DOUTRINA_CPU` em `revisao_ia_curadoria.py`)

Quatro regras nasceram da curadoria de 2026-09-24 e estão no prompt:

1. **Abrangência tem direção; a tabela não tem.** O par 1×1 converte nos dois sentidos, logo
   precisa ser verdadeiro nos dois — teste o sentido que falha, do mais abrangente para o mais
   estrito. Específico→genérico é verdade; genérico→específico não. `DEMOLIÇÃO DE CONCRETO SIMPLES`
   admite moldura decorativa, e pagar isso como demolição de piso desarruma a medição. Trava contra
   excesso de zelo: qualificador diferente sobre o MESMO universo vale (`ESTACA RAIZ EM SOLO` x
   `ESTACA RAIZ SEM PRESENÇA DE ROCHA`).
2. **Escopo de fornecimento embutido.** Recusa quando só um lado embute conexão — a SINAPI paga em
   composição própria, CDHU (123) e FDE (119) embutem no metro. Muitas grafias: `INCLUSIVE
   CONEXÕES`, `INCL CONEXÕES`, `INCL.CONEX`, `COM CONEXÕES`. Confirma no analítico: 1,40 m de tubo
   por metro é 1,00 + 0,40 de metro-equivalente; 1,03 é só perda. Se os DOIS embutem, o par vale
   (a SINAPI tem 8).
3. **Julgar serviço, unidade e insumo representativo; não julgar coeficiente.** Duas composições
   corretas do mesmo serviço têm produtividades diferentes — 8 fios de arame contra 11 não recusa.
4. **O analítico desambigua o título.** `LIMPEZA COM PRODUTOS QUÍMICOS` só vira par porque o
   analítico diz ÁCIDO MURIÁTICO; `BOTÃO SEM SINALIZADOR` x `VERDE E VERMELHO` só deixa de ser
   contradição porque o analítico mostra PULSADOR com capas coloridas. Quando não houver
   representativo dos dois lados, decidir por serviço e unidade e DECLARAR que foi sem
   representativo.

**Escopo:** o adendo vale para CPU. Em insumo, a linha que autoriza o mais genérico continua
valendo — insumo é coisa que se compra e se entrega igual; composição é serviço que se mede e se
paga.
