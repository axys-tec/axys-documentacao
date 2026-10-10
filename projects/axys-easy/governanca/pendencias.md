# Axys Easy — Pendências de Governança

**Status:** Vivo
**Data:** 2026-06-03
**Escopo:** decisões de governança/arquitetura ainda não fechadas.

> Lista de pendências. Itens marcados `[ ]` estão abertos; `[x]` concluídos.

**Contratos que governam o que está aqui** — citados no cabeçalho de propósito: contrato que
nenhuma pendência menciona desaparece em silêncio, e quem lê a pendência não vai caçá-lo.

| contrato | governa |
|---|---|
| [`contracts/ativo/bancada_orcamento_persistencia_contrato.md`](../contracts/ativo/bancada_orcamento_persistencia_contrato.md) | `ativo_orcamento`: congelar, concluir, reabrir, revisar. Frente pós-refino; leva o P3 (revisão) e o P4 (id dentro de JSON) |
| [`contracts/axys_easy_modelo_licenciamento.md`](../contracts/axys_easy_modelo_licenciamento.md) | licenciamento, capacidade e consumo (seções 1 a 9 abaixo). **Prevalece** sobre `EASY_HUB_LICENCIAMENTO.md` |
| [`contracts/ativo/apresentacao_orcamento_contrato.md`](../contracts/ativo/apresentacao_orcamento_contrato.md) | como o orçamento se apresenta ao sair: arranjo, repath, ordem canônica, timbrado, assinatura, data de emissão e as regras do Excel. Nasceu dos itens 12-13 do refino |

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

---

## Agrupamento no Excel — a chave do VLOOKUP precisa da edição (2026-10-05)

O parâmetro **Agrupamento** (ISOLADO/AGRUPADO) vale só para o PDF. O workbook da Finalização
continua com abas por ativo, sempre, e isso é deliberado.

O PDF pode juntar porque cada linha dele já carrega o preço resolvido — e o analítico passou a
detalhar cada item pelo `atv_id` do próprio item (`get_orcamento_analitico`). A planilha, não: a aba
**Insumos deduplica por `fonte|código`** e é dela que o Analítico puxa preço por VLOOKUP
(`orcamento_analitico_excel.py`, `_SDCOL`).

Ativos do mesmo empreendimento podem divergir, e divergem:

| caso | medido em dev |
|---|---|
| edições diferentes | empreendimento 21: ativo 22 em SINAPI **07-26**, ativos 32/33 em **08-26** |
| BDI diferente (mesmo preço de catálogo) | empreendimento 20: 9 de 46 composições com unitário c/BDI distinto entre os dois ativos (253,64 × 253,72) |

Num workbook agrupado, a mesma chave teria dois preços: o dedup guardaria um e o outro ativo
herdaria preço errado, **calado** — o pior tipo de erro, porque a planilha continua somando.

**Para fechar:** a edição (e o BDI) entram na chave do VLOOKUP, ou cada ativo ganha a sua aba de
Insumos. É a frente do consolidado amarrado por fórmulas, não o estado de impressão que o
Agrupamento define.

**Prioridade baixa, e por doutrina** (05/10/2026): o Excel é arquivo de TRABALHO, não peça de
entrega — ninguém manda planilha aberta e editável para o cliente. O que se entrega é o PDF, e lá o
agrupamento já funciona. Pela mesma razão, Ocultar Fontes-Base / Código da Fonte também não se
aplica ao workbook: quem precisar oculta a coluna no próprio Excel.

> Na curva ABC global do PDF o mesmo conflito aparece e foi resolvido por agregação: o unitário da
> linha agregada é a **média ponderada** (total ÷ qtd), como a curva de insumos já fazia. Colapsar é
> o que a curva global quer — é dela que sai o ranking A/B/C do empreendimento.

---

## Revisão de orçamento — o desenho (decidido em 06/10/2026)

Era a pendência **P3** do refino ("o que se duplica numa revisão"). O desenho que o Renan fixou:

**A revisão congela o estado atual, e o estado congelado vive em JSON** — não numa segunda árvore
de tabelas. Tecnicamente basta um campo de versão:

```
ativo_orcamento.versao   R00 (inicial) → R01 → R02 …
```

Vale para o **orçamento** e para a **memória de cálculo**, com uma diferença que é o coração do
desenho:

> **A planilha é atômica; a memória é isolada.** Não se separa uma linha do orçamento — ele revisa
> inteiro. Mas cada memória revisa sozinha, e **só revisa a que mudou**: a anterior fica como JSON.

Daí sai o que parece estranho e é correto: o orçamento pode estar em **R11** com **algumas memórias
em R11, outras ainda em R0, outras em R1**. Cada memória carrega a sua própria linha do tempo.

**Em aberto, e é decisão de implementação:** se o estado congelado vive em JSON ou em tabela. O
Renan aceita tabela se o desempenho pedir — o que não muda é a semântica acima.

**Depende de** `ativo_orcamento`, que é a frente pós-refino nascida do item 17 do refino.

> **O desenho dessa frente mora em
> [`contracts/ativo/bancada_orcamento_persistencia_contrato.md`](../contracts/ativo/bancada_orcamento_persistencia_contrato.md).**
> Está citado aqui de propósito: é o contrato que **governa** o congelar/concluir/reabrir/revisar, e
> sem ponteiro de dentro das pendências ele desaparece em silêncio — ninguém vai caçar contrato que
> nenhuma pendência menciona. **A pendência P4 (id dentro de JSON) também foi para lá**, por decisão
> de 06/10: as colunas JSON são do orçamento, e se decidem com o desenho na mão.

---

## Resíduo no catálogo GLOBAL — `AX-000.001-CPU` (2026-10-06)

Achado ao varrer o banco para a migration dos códigos próprios: existe **1 composição no catálogo
GLOBAL** (`catalogo.composicoes`, `cmp_fte_id = 1`) com código no formato PRÓPRIO antigo —
`AX-000.001-CPU`, "ENGENHEIRO JUNIOR DE CIVIL COM ENCARGOS". Existe em **dev e em produção**, e
arrasta uma linha em `catalogo.search_document`.

Cheira a resíduo do incidente do item 16 (o bucket paralelo criado porque o código da fonte era
usado como chave de identidade). **Não foi tocado** pela migration de 06/10, que só mexe em
`tenant_catalogo` — mexer no catálogo global sem entender a origem seria pior que o sintoma.

**A resolver:** entender se é lixo (apagar) ou se é uma composição legítima que foi parar no bucket
errado (mover para o tenant certo, com código novo).

---

## Refino final da bancada — ENCERRADO (2026-10-10)

Os itens 1 a 21 foram entregues e validados no front. O documento de trabalho
(`refino_final_bancada.md` e `refino_final_bancada_itens12-13.md`) sai do repo: o que ele
decidia virou código com o porquê no comentário, os contratos em
[`contracts/ativo/`](../contracts/ativo/) governam o resto, e o que sobrou de aberto está abaixo.

Guardam o que foi entregue, e acusam se quebrar:
`z_scripts_apoio/sanidade/documento_pdf.py` (51 checks, medidos no PDF gerado) e
`z_scripts_apoio/sanidade/excel_valores.py` (confronta o que o Excel calcularia com o que o app
calcula — openpyxl guarda a fórmula, não o resultado).

**O que ficou aberto do refino:**

- [ ] **P1b · Arquivamento por produto** — é ele que libera capacidade. Tem seção própria abaixo
  ("Arquivamento por produto — PRÓXIMO RINGUE"); depende do Hub mandar `capacity`.
- [ ] **P3 · O que se duplica numa revisão** — leitura do schema tabela por tabela. A pergunta que
  organiza: *o que, nesta tabela, é do ORÇAMENTO e o que é do ATIVO?* O do ativo é compartilhado
  entre revisões, o do orçamento se duplica. Memória de cálculo e ficha técnica são do ativo;
  itens, BDI, LS e cronograma são do orçamento. **Não há decisão em aberto — é trabalho.** Vai
  junto com o refactor de `ativo_orcamento`.
- [ ] **P5 · Schema do RT** — o responsável técnico mora em `tenant_catalogo`, que é catálogo
  TÉCNICO. RT não é catálogo técnico. Observação de modelagem, sem urgência.
- [ ] **P6 · Certificação digital** — assinar em lote. Tem seção própria abaixo; a dor se mede
  depois de a assinatura por documento rodar.
- [ ] **P8 · O id do banco ainda está na URL** — `/empreendimentos/24`, `/ativos/26`. Desde 05/10 o
  empreendimento tem código opaco e a LISTAGEM não expõe mais o id; a URL ainda expõe. Risco
  pequeno (toda consulta filtra por `tenant_uuid`, então id de outro tenant dá rota inexistente),
  mas o sequencial conta quantos empreendimentos existem na base. Trocar exige decidir o que fazer
  com link antigo, e vale para ativo também. É higiene, não trava nada.
- [ ] **P4 · guarda para id dentro de JSON** — a regra ("id de outra tabela dentro de JSON ou tem
  FK, ou é foto histórica declarada, ou está errado") foi verificada em 06/10 e **não está
  violada**: das 14 colunas JSONB, 10 estão vazias e as 4 em uso não guardam id nenhum. Falta a
  guarda: um teste que varra as colunas JSON e falhe apontando a coluna. **Casar por VALOR** (o
  número existe como PK naquela tabela?), não por nome — a primeira varredura manual não achou
  `ati_origem` porque a regex exigia sufixo `_id`, e detector baseado em nome erra por nome.

**Duas frentes do documento seguem vivas em seção própria, abaixo:** a revisão de orçamento
(decidida em 06/10) e o arquivamento por produto.

---

## Sanidade do catálogo tem de rodar NO IMPORT, pela tela (2026-10-10)

Existe o script [`z_scripts_apoio/sanidade/catalogo_custos.py`](../../../../z_scripts_apoio/sanidade/catalogo_custos.py),
que confronta o que a fonte publicou (`cc_custo_fonte`) com o que o motor calcula
(`cc_custo_calculado`) em cada edição. Ele roda à parte, por linha de comando — e **o import é
feito em produção, pela tela, não em dev com curadoria**. Script solto que ninguém lembra de rodar
não protege nada.

**A fazer:** a conferência vira etapa do próprio import/publicar e o resultado aparece na tela,
junto do manifesto. O padrão de cada fonte já está medido e é o que o script usa:

| fonte | esperado | medido em 2026-10-10 |
|---|---|---|
| SINAPI | bate exato | 0 de 248.895, em 25 edições |
| CDHU | diverge por arredondamento (a fonte publica com ROUND) | ~9% fora do limite de 1 centavo por item — **a explicar** |
| FDE | diverge sempre: a fonte publica COM BDI, o nosso é limpo | 0 com calculado acima do publicado |

O limite certo para "é só arredondamento" é **1 centavo por item da composição** — nem valor
absoluto nem percentual servem sozinhos: R$ 13 num chiller de R$ 523 mil é 0,00%, e 6 centavos
numa composição de R$ 0,24 com 7 itens são 25%.

**Dois achados abertos do script**, nenhum deles regressão (estão assim desde 2021):
- CDHU: ~9% das composições divergem acima do limite de arredondamento, em todas as edições.
- 12.664 custos SINAPI (e 5 CDHU) publicados em composição vigente que o motor **não consegue
  calcular** (`cc_custo_calculado IS NULL`).

---

## ⚠ SEQUÊNCIA DE DEPLOY — duas migrations com ordens OPOSTAS (2026-10-05)

Há duas migrations pendentes de prod em estados diferentes, e **a ordem entre código e banco é
inversa entre elas**. Errar a ordem derruba a app.

| migration | prod | ordem obrigatória | se inverter |
|---|---|---|---|
| `2026-10-04_responsavel_tecnico.sql` | ✅ **já aplicada** | migration → código | código sem migration: `/dados-proprios` dá 500 (a contagem de responsáveis entra na mesma query das outras) |
| `2026-10-05_empreendimento_parametros_documento.sql` | ⬜ **não aplicada** | **código → migration** | migration sem código: `get_contexto` quebra, porque a versão no ar ainda lê `epa_fonte` |

### A sequência correta, de ponta a ponta

1. **A do RT já rodou** em 05/10. Enquanto o código não sobe, prod tem tabelas vazias que ninguém
   lê — inofensivo.
2. **Pushar o código.** Aí a tela de RT passa a funcionar (a migration dela já está lá) e o
   `get_contexto` já não lê `epa_fonte` (o degrau por empreendimento morreu no código).
3. **Só então** rodar `2026-10-05_empreendimento_parametros_documento.sql`.

Entre os passos 2 e 3 existe uma janela em que a tabela antiga ainda está em prod e ninguém a lê.
É inofensiva: a tabela está vazia, e o código novo não a toca.

### Por que a ordem é inversa

A do RT **só acrescenta** — tabelas novas e uma coluna com default. Banco à frente do código é
sempre seguro quando só se acrescenta.

A de `empreendimento_parametros` **derruba e recria com outra forma**. Banco à frente do código
significa o código antigo procurando `epa_fonte` numa tabela que já não a tem.

### A trava que protege contra engano

A migration de 05/10 tem um bloco `DO` que **aborta** se a tabela antiga tiver qualquer linha —
testado. Ela protege contra dado inesperado, **não** contra a ordem errada: se rodar antes do
deploy, ela passa (a tabela está vazia) e quebra a app.

---

## Licenciamento, capacidade e consumo (2026-10-01)

Fonte: `docs/projects/axys-easy/contracts/axys_easy_modelo_licenciamento.md` — documento **oficial**
do licenciamento, que **prevalece** sobre o anterior (`EASY_HUB_LICENCIAMENTO.md`, 15/08).

O que é da frente do refino da bancada (arquivamento do ATIVO, estados, bloqueio de edição) está em
`refino_final_bancada.md`, encerrado em 10/10 — o que ele decidia está em
[`contracts/ativo/apresentacao_orcamento_contrato.md`](../contracts/ativo/apresentacao_orcamento_contrato.md).
Aqui fica o resto.

**Conferido contra o schema: nenhuma falha estrutural.** `atv_status` é texto livre sem CHECK,
`emp_arquivado` já existe, o JWT já carrega `licencas[]` e há onde pendurar o que falta. O que
falta é implementação, não redesenho. Dois pontos exigem coordenação com o Hub e estão marcados.

## 1 · Capacidade  ✓ O HUB ENTREGOU EM 06/10 — falta o Easy aplicar por produto

**Deixou de depender do Hub.** O contrato fechou em 06/10 (`a12a4cd` no subrepo de documentação) e
ficou explícito que **não existe JWT separada para licenciamento**: os entitlements vêm no MESMO
JWT RS256 do login/SSO, com identidade, issuer, audience, validade e transporte inalterados. Só o
formato de `licencas` mudou:

```json
{"app": "easy-orca", "model": "capacity", "capacity": 5}
```

`capacity: null` (e `remaining: null`) é Unlimited. Os aliases antigos `modelo`, `label` e
`app_labels` **não vêm mais**. `EASY_HUB_LICENCIAMENTO.md` (15/08) agora aponta para
`axys_easy_modelo_licenciamento.md` como fonte prevalente.

**O que o Easy já tem no ar:** o gate de capacidade existe em `ativo/service.py` — advisory lock
por tenant, contagem de ocupação e recusa com `capacity_exceeded`, nos dois pontos certos (criar
ativo e desarquivar empreendimento). E os três endpoints internos de §10.2/10.4 estão em
`ativo/routes.py`, autenticados por `EASY_HUB_CLIENT_ID`/`SECRET`:

| endpoint | para quê |
|---|---|
| `GET /api/internal/licensing/occupancy` | o Hub pergunta a ocupação antes de efetivar downgrade |
| `POST /api/internal/licensing/capacity` | invalidação imediata da capacidade em sessão aberta |
| `POST /api/internal/licensing/access-mode` | idem para `ACTIVE`/`VIEW_ONLY`/`BLOCKED` |

**O que FALTA, e é a pendência real:** a ocupação no ar conta **por tenant, sem produto** —
`ocupacao_ativos()` soma os ativos de empreendimentos não arquivados cujo `atv_status` não é
`ARQUIVADO`. O contrato §10.1 exige ocupação **por licença/produto**, porque Orça 5 e Docs 5 são
dois tetos e não um saldo de 10. `ativo.ativo_produto_status` já está no schema e na migration
`2026-10-06_ativo_produto_status.sql` para isso — **vazia, sem leitor nenhum ainda**.

Ver a seção "Arquivamento por produto" abaixo: a tabela existe, o comportamento não.

## 2 · API de ocupação para o downgrade  ✓ IMPLEMENTADA EM 06/10

O endpoint existe e responde `{tenant_uuid, product, em_andamento}`. `product` é obrigatório e tem
de ser uma licença de capacidade; produto inválido dá `400`, credencial errada `401`. Se o Easy não
responder, o Hub **não efetiva** o downgrade — e nenhum dos dois arquiva nada sozinho.

**A ressalva que sobra é a mesma da seção 1:** a resposta hoje ignora o `product` para contar. Ele
é validado contra a lista de apps e devolvido no corpo, mas a contagem é a mesma para qualquer
produto. Fica correta quando a ocupação passar a ler `ativo_produto_status`.

Credenciais: as de sempre. No Easy `EASY_HUB_CLIENT_ID`/`EASY_HUB_CLIENT_SECRET`, no Hub
`EASY_SSO_CLIENT_ID`/`EASY_SSO_CLIENT_SECRET`. **Não existe segredo novo para licenciamento.**

O Hub também corrigiu a alçada do lado dele: capacidade e modo de acesso passam a exigir sessão
administrativa interna, e **a credencial do Easy não concede licença nem altera capacidade**.

## 3 · Uso isolado: Price e CPU

São produtos de **uso isolado** — saldo canônico no Hub, evento de consumo explícito, deliberado,
transacional, auditável e **idempotente**.

O contrato já fixou o momento de consumo de cada um:

- **Price:** depois de preencher os dados do motor paramétrico, abre simulação resumida e aviso
  duro — *"Deseja avançar no orçamento paramétrico? Ao avançar, será computado o uso e não será
  possível alterar mais os dados básicos de área e infraestrutura do ativo, podendo apenas ser
  manipulado itens e/ou etapas."*
- **CPU:** nasce de importação de xls/xlsx, com **diff em tela** do que vem do sintético, e o
  usuário podendo subir e baixar a planilha no mesmo lugar para conferência. Aviso igualmente
  duro — *"Deseja avançar para o detalhamento das composições? Ao avançar será computado o uso e
  não será possível excluir ou adicionar itens, limitando-se a manipular preços de insumos e/ou
  composições de serviços."*

**Nota de arquitetura que vale registrar:** o Price é *apartado* do Orça — acesso e comportamento
isolados, **mesmas tabelas e premissas**, e é a permissão de uso que determina o front. Então não
é um schema novo; é um modo.

E aqui entra o que eu havia proposto para o Orça e foi descartado lá: a regra de **não deixar
transformar a unidade em outra** é exatamente o `dados_congelados` destes produtos. No Orça não
vale (concluir não é consumo); aqui é o coração do modelo.

A auditoria do evento tem **13 campos mínimos** definidos no contrato (tenant, usuário, produto,
unidade de trabalho, data/hora, evento, quantidade, saldo antes, saldo depois, id idempotente,
status da sincronização, quem confirmou, erro). `ativo.ativo_eventos` existe e está vazia — serve
de base, mas o contrato pede mais campos do que ela tem.

## 4 · Axys Intelligence e o AxysCoin (AXC)

Terceira categoria comercial, nem licença nem capacidade: **créditos**.

Referência econômica fixa: **1.000 AXC = US$ 1,00** de custo computacional. O consumo de cada
operação é o custo efetivo da requisição ao provedor (entrada, saída, demais recursos).

Formação de preço, já fechada no contrato:

```
CUSTDIR = custo efetivo do dólar × (1 + AX1)        AX1  = 10%  (risco cambial)
preço de 1.000 AXC = [CUSTDIR × (1 + LUCR)] / (1 - TRIB)
                                                    LUCR = 10%  (margem)
                                                    TRIB = 10%  (tributos)
```

Arredonda **para cima**, em três casas. Cotação semanal, vendida só em reais, recarga mínima
R$ 10. A cotação da compra define definitivamente o saldo creditado.

O que precisa existir:

- confirmação **em tela antes de cada operação**, mostrando consumo estimado, saldo atual e saldo
  previsto, avisando que o efetivo pode variar;
- débito do **consumo efetivo** ao final, admitindo pequeno saldo negativo só pela diferença entre
  estimativa e real, dentro de tolerância a definir; negativo impede nova operação;
- **saldo lido do Hub antes de CADA operação** — e esta é a ressalva operacional do contrato: como
  é multi-tenant e multi-app, o saldo do login pode estar velho. Bater no Hub, atualizar, rodar;
- depois de rodar, **enfileirar a comunicação ao Hub** com idempotência e fallback de falha. O Hub
  registra o uso de qualquer jeito.

## 5 · IA fora do Axys Intelligence (prompt externo)

O uso do Axys Intelligence **não é obrigatório**. Onde for tecnicamente aplicável, o Easy oferece
**gerar e baixar/copiar o prompt**, para a pessoa usar a ferramenta que preferir sem gastar AXC.

O prompt externo é funcional e suficiente para resultado útil, mas **pode ser empobrecido** em
relação à inteligência proprietária — sem toda a engenharia de prompt, contexto, agentes e
validações da Axys. Empobrecido, não inútil.

O valor cobrado é a **conveniência integrada**: preparar contexto, executar, tratar a resposta e
conciliar com os dados do Easy. Não é restrição artificial ao acesso do usuário aos próprios dados.

## 6 · Retenção e sanitização

O próprio contrato registra os workers como pendência, para depois das primeiras vendas.

| plano | retenção contratada | margem interna (não divulgada) |
|---|---|---|
| uso único | 30 dias | +30 |
| até 10 ativos | 60 dias | +60 |
| Unlimited | 120 dias | +60 |

Regras que precisam ser respeitadas quando isso for construído:

- prazos **parametrizados**, não fixos no código — por decisão do contrato, em tabelas **seedadas**
  sem tela por enquanto;
- encerrada a margem, os dados podem sair do banco operacional e virar **arquivo histórico
  estruturado e versionado**, preservando o suficiente para restauração controlada no schema
  vigente;
- **a sanitização só ocorre depois de confirmada a geração, integridade e persistência segura do
  arquivo** — esta é a ordem que não pode inverter;
- classes progressivas `archive_y1`, `archive_y2`, `archive_y3`; vencer uma classe **não** implica
  exclusão automática;
- **não** haverá banco operacional paralelo para tenant inativo;
- restauração é serviço técnico interno, cobrado, nunca self-service.

## 7 · Inadimplência — do Hub, o Easy respeita

Inadimplência **não apaga dado, não arquiva ativo e não altera histórico**. Ela muda
progressivamente o **modo de acesso** concedido pelo Hub:

```
renovação não processada
  → D+1..D+7   período de regularização (tenant operacional, Hub avisa 1×/dia)
  → D+7        suspensão das funcionalidades
  → até 30d    acesso congelado / somente visualização
  → fim do 30º bloqueio de acesso à plataforma
  → 180+d      sujeito à política de retenção e sanitização
```

O Easy precisa honrar o modo que vem do Hub. O `VIEW_ONLY` já existe no gate atual — falta
conferir se cobre o estado "funcionalidades suspensas" do D+7, que é diferente de só-visualização.

---

## 8 · Certificação digital — assinar em lote (2026-10-06, era o item 20 do refino)

Veio do refino final da bancada, onde era o último item. **Sai do refino por decisão de 06/10**:
não é ajuste de bancada, é produto novo, e só se mede depois da assinatura por documento rodar.

A dor real: o Adobe assina um PDF por vez, e são oito documentos por entrega. **A decisão de
assinatura por documento já resolve boa parte** — um consolidado é uma assinatura, não oito. Isso
vale dizer antes de qualquer engenharia, porque muda o tamanho do problema.

Para o que sobrar, três caminhos, do mais barato ao mais caro:

1. **Consolidar mais.** Cada documento a menos é uma assinatura a menos. É desenho, não código.
2. **Assinador local.** O certificado fica na máquina da pessoa, um agente nativo assina o lote e
   devolve. É o único jeito honesto de assinar muitos sem a chave privada sair de lá — mas é um
   produto próprio, com instalador por sistema operacional.
3. **Assinatura no servidor** com certificado enviado pelo usuário (pyHanko e afins). Tecnicamente
   o mais simples, e o que **não faria sem pensar muito**: guardar chave privada de terceiro é
   responsabilidade jurídica séria, não detalhe de implementação.

Navegador puro **não alcança**: a Web Crypto não lê o repositório de certificados do sistema. Sem
agente nativo ou ponte PKCS#11, não há caminho.

**Método, e é o que trava:** medir a dor depois da assinatura por documento estar no ar. Construir
antes de medir é escolher o caminho 2 ou 3 sem saber se o caminho 1 já bastava.

## 9 · Arquivamento por produto — PRÓXIMO RINGUE (2026-10-06)

**Ordem combinada:** entra **depois** de fechar as associações entre fontes e o ajuste da bancada.
Não antes.

### A tabela já existe; o comportamento não

`ativo.ativo_produto_status` entrou no schema e na migration `2026-10-06_ativo_produto_status.sql`
em 06/10. Nasceu **vazia e sem leitor**: nenhum ponto do app cria, arquiva ou conta vínculo.

Chave natural `(atvp_atv_id, atvp_produto)`. Guardas provadas em banco: um vínculo por produto,
tenant incoerente recusado pela FK composta, produto e status fora da lista recusados pelo CHECK, e
`ARQUIVADO` sem data (ou data sem `ARQUIVADO`) recusado. A contagem de ocupação sai em *Index Only
Scan* pelo índice parcial `ix_atvp_ocupacao`.

### ✓ DECIDIDO (Renan, 06/10): os DOIS status ficam, em hierarquia

A tabela parecia contradizer a decisão de 01/10 (slot num status único do ativo). **Não contradiz:
são dois níveis, e a divergência acaba quando se diz qual manda.**

| | o que é | granularidade |
|---|---|---|
| `ativo.ativos.atv_status` | **chave geral.** `ARQUIVADO` aqui **bloqueia TODOS os produtos** | um por ativo |
| `ativo.ativo_produto_status` | o detalhe por produto, dentro do que a chave geral permite | um por produto |

`atv_status = 'ARQUIVADO'` é o interruptor de parede: desce tudo de uma vez, em qualquer produto, e
libera todos os slots daquele ativo. Os vínculos por produto são os interruptores de cada ponto —
só valem com a parede ligada.

**Duas obrigações que essa hierarquia cria, e são a razão de ela funcionar:**

1. **Avisar o usuário, na hora de arquivar, que arquivar o ATIVO bloqueia todos os produtos.** Sem
   esse aviso a chave geral é uma armadilha: a pessoa arquiva pensando em soltar o Orça e perde o
   Docs, o PM e o resto junto. É aviso de consequência, não explicação de tela — cabe no modal de
   confirmação, com a lista dos produtos que vão cair.
2. **Dar onde ver e mexer no detalhe:** na **tab do ativo**, uma **expansão de formulário com o
   status por produto**. É ali que a granularidade existe para o usuário; sem a expansão, a tabela
   seria estado invisível, que é o pior tipo.

**O que isso resolve de graça:** a cascata para cima sobrevive. "Arquivar o último ativo em
andamento arquiva o empreendimento" volta a ter resposta única, porque *em andamento* passa a ser
lido no `atv_status`, que é um só. E a assimetria de 01/10 (desarquivar o empreendimento **não**
levanta os ativos) continua valendo pelo mesmo motivo de antes: levantar cinco de uma vez
estouraria o teto e obrigaria a app a escolher quais derrubar.

**Consequência para a contagem de ocupação:** vínculo `EM_ANDAMENTO` **cujo ativo não esteja
`ARQUIVADO`**. A chave geral entra na cláusula, senão um ativo arquivado continuaria ocupando slot
pelos vínculos que ficaram para trás.

### O que falta implementar

1. **Contagem de ocupação** em `ativo_produto_status` por `(tenant, licença)`, com o ativo não
   arquivado na cláusula. Substitui `ocupacao_ativos()`, que hoje conta por tenant sem produto.
2. **Criar ou reativar o vínculo** na primeira operação que põe o ativo em andamento no produto.
3. **`atv_status` com CHECK** e os estados fechados, mais a migração dos valores atuais (os 29
   ativos de dev estão todos em `RASCUNHO`).
4. **O aviso ao arquivar o ativo**, listando os produtos que vão cair junto.
5. **A expansão do status por produto na tab do ativo** — é onde a granularidade fica visível.
6. **Easy One:** a ocupação é de `atvp_atv_id` **distintos** sob `atvp_licenca = 'ONE'`.
7. Fazer isto na **mesma varredura** do mascaramento de rotas
   (`redesign_rotas_exposicao.md`, Tarefa 2): a trava precisa achar o objeto pela URL, e é a URL
   que a outra tarefa muda.

### Pendências do lado do Hub (declaradas em 06/10)

| | |
|---|---|
| retry persistente para notificação Hub → Easy | do Hub; hoje falha de notificação só fica registrada |
| alteração de plano no dashboard comercial | do Hub |
| código principal do Hub ainda **local, sem push** | só o subrepo de documentação foi publicado |

### ✓ `audit.uso_isolado` — declarada e renomeada em 06/10

Nasceu como `audit.license_usage_event`, criada direto nos bancos de dev e produção pelo time do
Hub, fora do `schema.sql` e com nomes em inglês sem prefixo. Vazia nos dois.

**Não era órfã:** `backend/core/licensing.py` a usa como **outbox** do consumo isolado — grava o
evento local antes de chamar o Hub, e o retry repete a mesma chave de idempotência sem duplicar o
débito. Mas nada chama `consume_isolated_usage`, porque Price e CPU ainda não existem (seção 3).

**Feito em 06/10, nesta ordem:**

1. **Declarada no `schema.sql`** — o defeito não era a tabela, era a foto não mostrar tabela que o
   banco tem. Schema divergindo de código é o que não se pode deixar.
2. **Renomeada para `audit.uso_isolado`**, português e prefixo `uso_`, como `audit.logs` e
   `audit.login_logs`. Por `RENAME`, que preserva PK, UNIQUE, CHECKs, índice e defaults sem recriar
   nada nem tocar linha. `uso_sync` passou a falar a língua da casa: `PENDENTE` · `CONFIRMADO` ·
   `FALHOU`.
3. **Ganhou uma guarda que não existia:** `ck_uso_confirmado` — data de confirmação e estado não
   podem discordar, do mesmo jeito que em `ativo_produto_status`.

Feito **agora de propósito**: com a tabela vazia e sem chamador, custou um arquivo. Depois do
primeiro evento gravado custaria migração de dado, janela e risco.

Provado no caminho real (Hub apontado para endereço morto, para não debitar nada): insert e falha
marcam `FALHOU` sem data, retry com a mesma chave não duplica linha, `CONFIRMADO` grava a data e o
saldo, a guarda recusa `FALHOU` com data velha, e a chamada idempotente devolve o saldo sem tocar o
Hub.

## O que está fechado e não é pendência

Para não reabrir por engano:

- **não existe** contador canônico em app recorrente;
- **não se cobra** conclusão, reabertura, revisão nem emissão;
- **não há** reset mensal de "usos" em app de capacidade;
- **não se duplica** saldo comercial autoritativo no Easy — o saldo é do Hub, a evidência
  operacional é do Easy, e os dois compartilham o id de idempotência;
- **não se escreve** regra financeira no microapp;
- cadastrar empreendimento, por si só, **não** consome capacidade — quem ocupa é o ativo.
