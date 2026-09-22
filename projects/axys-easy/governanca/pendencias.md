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
