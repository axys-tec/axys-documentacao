# Axys Easy — Pendências de Governança

**Status:** Vivo
**Data:** 2026-06-03
**Escopo:** decisões de governança/arquitetura ainda não fechadas.

> Lista do que está ABERTO. O que foi feito SAI daqui — o git guarda o histórico (Renan, 28/10/2026).
> A última seção é sempre a verificação em curso.

> Tudo que está aqui é uma **frente**: aberta, em espera ou em verificação. O que surgir fora delas
> é frente NOVA e entra com título próprio no índice abaixo (Renan, 29/10/2026).

---

## FRENTES PENDENTES

| | frente | estado |
|---|---|---|
| F1 | Ciclo de vida do orçamento | frente aberta |
| F2 | Submain do orçamento | frente aberta |
| F3 | Provisão de Medições | frente aberta |
| F4 | Remover o id das rotas | frente aberta |
| F5 | Associação entre fontes | frente aberta |
| F6 | Licenciamento, capacidade e arquivamento por produto | frente aberta |
| F7 | Cronograma (contrato §10) | frente aberta |
| F8 | Pré-planejamento — persistência e IA | frente aberta |
| F9 | Memória de cálculo — levantamentos CAD/RVT/BIM | frente aberta |
| F10 | Bancada colaborativa | frente aberta |
| F11 | MCP — fila de leitura e pré-planejamento | frente aberta |
| F12 | Ficha técnica → orçamento | frente aberta |
| F13 | Integração viva com Excel | em espera |
| F14 | Catálogo — identidade da fonte, import e resíduos | frente aberta |
| F15 | Catálogo Colaborativo | frente aberta |
| F16 | Tabelas de domínio com tela (ADM) | frente aberta |
| F17 | Certificação digital — assinar em lote | sem execução prevista |
| F18 | Segurança — RLS por schema | avaliar |
| F19 | Verificação de desempenho — com números | em curso |

---

**Contratos que governam o que está aqui** — citados no cabeçalho de propósito: contrato que
nenhuma pendência menciona desaparece em silêncio, e quem lê a pendência não vai caçá-lo.

| contrato | governa |
|---|---|
| [`contracts/ativo/bancada_orcamento_persistencia_contrato.md`](../contracts/ativo/bancada_orcamento_persistencia_contrato.md) | `ativo_orcamento`: congelar, concluir, reabrir, revisar — **F1** |
| [`contracts/axys_easy_modelo_licenciamento.md`](../contracts/axys_easy_modelo_licenciamento.md) | licenciamento, capacidade e consumo — **F6**. **Prevalece** sobre `EASY_HUB_LICENCIAMENTO.md` |
| [`contracts/catalogo/identidade_fonte.md`](../contracts/catalogo/identidade_fonte.md) | identidade da fonte (código imutável, nada decidido pelo nome), PRÓPRIA por origem, edição mínima do tenant, data-base por insumo. Nasceu do bug 2 (25-26/10/2026) — **F14** |
| [`contracts/ativo/apresentacao_orcamento_contrato.md`](../contracts/ativo/apresentacao_orcamento_contrato.md) | como o orçamento se apresenta ao sair: arranjo, repath, ordem canônica, timbrado, assinatura, data de emissão e as regras do Excel. Nasceu dos itens 12-13 do refino |

---

## F1 · Ciclo de vida do orçamento — frente aberta

Contrato que já existe e é ponto de partida:
[`bancada_orcamento_persistencia_contrato.md`](../contracts/ativo/bancada_orcamento_persistencia_contrato.md)
— mas lá "congelar" é congelar o dado do catálogo, não o estado do orçamento. O schema da família
`ativo_orcamento_*` está em produção desde o refactor de 11-13/10; o que falta é o **comportamento**.

- [ ] **Concluir e reabrir** — `aor_estado` / `aor_concluido_em`, com auditoria e snapshot (é a única
      auditoria da bancada: a transição, não cada operação). O badge e os três estados existem; nada
      escreve `aor_estado` hoje. A guarda "só em RASCUNHO" está repetida à mão em 8 serviços (MCP,
      editor de composição, descritivo, cotação); as rotas centrais da bancada — criar, editar, mover,
      colar, excluir, importar — **não têm guarda**. Fazer a guarda de rota central e o front
      desabilitando os gatilhos.
- [ ] **Revisões R01+** — criar a revisão; cópia-na-escrita da composição (`aoc_aor_desde` existe e
      nada o grava: enquanto tudo é R00 o editor grava no lugar sem risco; com R01, editar composição
      compartilhada com revisão anterior tem de cloná-la); o `{versao}` da URL apontando de verdade
      para a revisão.
- [ ] **Contrato do ciclo de estados** — não existe; nasce com esta frente.
- [ ] **Composição própria sem descritivo no Caderno de Encargos.** Decidido em 11/10: não entra no
      caderno, e antes de gerar a tela **lista e pergunta** — *"Existem composições sem descritivo e
      estas serão ignoradas na montagem do Caderno de Encargos"*, com a lista (código + descrição, e a
      obra quando há mais de uma) e **Prosseguir sem** / **Cancelar**. Hoje o PDF imprime "Descritivo
      técnico não disponível". O modal e o pré-voo (uma query por origem, 5-331 ms contra 4,7 s da
      montagem) estão no patch congelado: `git cat-file -p refs/congelado/caderno-patch-blob` — dele
      só serve essa parte; a composição adaptada o caderno já lê do estado gravado.

**A semântica da revisão (decidida em 06/10, segue valendo):**

> **A planilha é atômica; a memória é isolada.** Não se separa uma linha do orçamento — ele revisa
> inteiro. Mas cada memória revisa sozinha, e **só revisa a que mudou**.

Daí o orçamento poder estar em **R11** com memórias em R11, outras em R0, outras em R1: cada memória
carrega a sua própria linha do tempo.

---

## F2 · Submain do orçamento — frente aberta

Eram as fases 6 e 8 do refactor do orçamento, redefinidas pelo Renan em 12/10:

> *"Basicamente será uma unificação das tabs, alocando-a para dentro de orçamento e gerando o
> histórico mas, como orçamento tem virado uma coisa de múltiplos botões, minha ideia será uma
> submain do orçamento, dando uma otimizada em tabs. Inclusive, é o que vai fazer mais sentido até
> para os outros produtos da app. Porque essa estrutura de tabs pode sobretensionar no carregamento."*

- [ ] Submain que absorve as tabs (Fontes, BDI e LS dentro do orçamento) e mostra o histórico de
      BDI/L.S. por revisão — desenho que serve os outros produtos também.
- [ ] Recaptura granular em prod (por orçamento/composição) — nunca virou script.

---

## F3 · Provisão de Medições — frente aberta

- [ ] O card de Medições é placeholder; o simulador que funciona não tem card. Frente própria.

---

## F4 · Remover o id das rotas — frente aberta

Documento da frente: [`next-steps/redesign_rotas_exposicao.md`](../next-steps/redesign_rotas_exposicao.md)
(a regra, o mapeamento de 10/10 e a Tarefa 2 — a trava do arquivamento, que é a mesma varredura).

- [ ] **Nenhuma rota exibe id** — `/empreendimentos/24`, `/ativos/26`. Desde 05/10 o empreendimento tem
      código opaco e a listagem não expõe mais o id; a URL ainda expõe. Desde 28/10 id alheio já dá
      404 (guarda de posse no roteador), então é higiene, não vazamento: o sequencial conta quantos
      objetos existem. Decidir sha estável × rotativo, link antigo, e as rotas de arquivo (PDF, XLSX,
      caderno) junto.

---

## F5 · Associação entre fontes — frente aberta

Documento de trabalho da frente: [`next-steps/associacoes_entre_fontes.md`](../next-steps/associacoes_entre_fontes.md)
(arestas do `publicar`, as duas últimas tarefas — telas de curadoria e plugue no import — e as dívidas
vivas). A doutrina está no contrato `contracts/catalogo/vinculacoes.md`. Abaixo, o que estava solto
aqui e é da mesma frente.

### Vinculação entre fontes — redesenho (pensar no próximo ajuste)

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

### PROD — drop/recreate de equivalencias_ins e equivalencias_cpu

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

### Matcher por busca — estado em 2026-09-24 e o que falta

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

#### Pendências

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

#### Doutrina endurecida (`_DOUTRINA_CPU` em `revisao_ia_curadoria.py`)

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

## F6 · Licenciamento, capacidade e arquivamento por produto — frente aberta

Fonte: `docs/projects/axys-easy/contracts/axys_easy_modelo_licenciamento.md` — documento **oficial**
do licenciamento, que **prevalece** sobre o anterior (`EASY_HUB_LICENCIAMENTO.md`, 15/08).

O que é da frente do refino da bancada (arquivamento do ATIVO, estados, bloqueio de edição) está em
`refino_final_bancada.md`, encerrado em 10/10 — o que ele decidia está em
[`contracts/ativo/apresentacao_orcamento_contrato.md`](../contracts/ativo/apresentacao_orcamento_contrato.md).
Aqui fica o resto.

**Conferido contra o schema: nenhuma falha estrutural.** `atv_status` é texto livre sem CHECK,
`emp_arquivado` já existe, o JWT já carrega `licencas[]` e há onde pendurar o que falta. O que
falta é implementação, não redesenho. Dois pontos exigem coordenação com o Hub e estão marcados.

### 1 · Capacidade  ✓ O HUB ENTREGOU EM 06/10 — falta o Easy aplicar por produto

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

### 3 · Uso isolado: Price e CPU

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

### 4 · Axys Intelligence e o AxysCoin (AXC)

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

### 5 · IA fora do Axys Intelligence (prompt externo)

O uso do Axys Intelligence **não é obrigatório**. Onde for tecnicamente aplicável, o Easy oferece
**gerar e baixar/copiar o prompt**, para a pessoa usar a ferramenta que preferir sem gastar AXC.

O prompt externo é funcional e suficiente para resultado útil, mas **pode ser empobrecido** em
relação à inteligência proprietária — sem toda a engenharia de prompt, contexto, agentes e
validações da Axys. Empobrecido, não inútil.

O valor cobrado é a **conveniência integrada**: preparar contexto, executar, tratar a resposta e
conciliar com os dados do Easy. Não é restrição artificial ao acesso do usuário aos próprios dados.

### 6 · Retenção e sanitização

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

### 7 · Inadimplência — do Hub, o Easy respeita

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

### 9 · Arquivamento por produto — PRÓXIMO RINGUE (2026-10-06)

**Ordem combinada:** entra **depois** do ajuste da bancada. Não antes.

**Não depende das associações entre fontes** — isso era engano de redação aqui. Associação entre
fontes é **frente isolada**, que o Renan toca por fora da bancada e por fora do arquivamento;
status de produto não tem relação com equivalência entre fontes.

#### A tabela já existe; o comportamento não

`ativo.ativo_produto_status` entrou no schema e na migration `2026-10-06_ativo_produto_status.sql`
em 06/10. Nasceu **vazia e sem leitor**: nenhum ponto do app cria, arquiva ou conta vínculo.

Chave natural `(atvp_atv_id, atvp_produto)`. Guardas provadas em banco: um vínculo por produto,
tenant incoerente recusado pela FK composta, produto e status fora da lista recusados pelo CHECK, e
`ARQUIVADO` sem data (ou data sem `ARQUIVADO`) recusado. A contagem de ocupação sai em *Index Only
Scan* pelo índice parcial `ix_atvp_ocupacao`.

#### ✓ DECIDIDO (Renan, 06/10): os DOIS status ficam, em hierarquia

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

#### O que falta implementar

1. **Contagem de ocupação** em `ativo_produto_status` por `(tenant, licença)`, com o ativo não
   arquivado na cláusula. Substitui `ocupacao_ativos()`, que hoje conta por tenant sem produto.
2. **Criar ou reativar o vínculo** na primeira operação que põe o ativo em andamento no produto.
3. **`atv_status` com CHECK** e os estados fechados, mais a migração dos valores atuais (os 29
   ativos de dev estão todos em `RASCUNHO`).
4. **O aviso ao arquivar o ativo**, listando os produtos que vão cair junto.
5. **A expansão do status por produto na tab do ativo** — é onde a granularidade fica visível.
6. **Easy One:** a ocupação é de `atvp_atv_id` **distintos** sob `atvp_licenca = 'ONE'`.
7. Fazer isto na **mesma varredura** do mascaramento de rotas
   (F4, `next-steps/redesign_rotas_exposicao.md`, Tarefa 2): a trava precisa achar o objeto pela URL, e é a URL
   que a outra tarefa muda.

#### Pendências do lado do Hub (declaradas em 06/10)

| | |
|---|---|
| retry persistente para notificação Hub → Easy | do Hub; hoje falha de notificação só fica registrada |
| alteração de plano no dashboard comercial | do Hub |

### O que está fechado e não é pendência

Para não reabrir por engano:

- **não existe** contador canônico em app recorrente;
- **não se cobra** conclusão, reabertura, revisão nem emissão;
- **não há** reset mensal de "usos" em app de capacidade;
- **não se duplica** saldo comercial autoritativo no Easy — o saldo é do Hub, a evidência
  operacional é do Easy, e os dois compartilham o id de idempotência;
- **não se escreve** regra financeira no microapp;
- cadastrar empreendimento, por si só, **não** consome capacidade — quem ocupa é o ativo.

> A trava do arquivamento (item 7 acima) é a mesma varredura de F4.

---

## F7 · Cronograma (contrato §10) — frente aberta

- [ ] Período fixo de 30 dias.
- [ ] "Distribuir linear" e "puxar curva".
- [ ] Físico × financeiro.
- [ ] Calibração do nível 4.

---

## F8 · Pré-planejamento — persistência e IA — frente aberta

- [ ] Persistência das premissas.
- [ ] O canal de IA.

---

## F9 · Memória de cálculo — levantamentos CAD/RVT/BIM — frente aberta

- [ ] A seção Levantamentos é reservada: import de JSON estruturado CAD/RVT/BIM →
      `mc_levantamentos` / `mci_levantamento_key` (as colunas já existem).
- [ ] Decidir se uma memória pode misturar bloco de grid e de CAD (entendimento atual: sim, procedência
      por bloco).

---

## F10 · Bancada colaborativa — frente aberta

- [ ] Edição simultânea: lock por âncora e refresh do JWT.
- [ ] Fluxo de tela da conciliação de código desconhecido.

---

## F11 · MCP — fila de leitura e pré-planejamento — frente aberta

O `/mcp` está no ar em prod (OAuth só para ChatGPT, Claude e Gemini desde 28/10).
- [ ] Fila de leitura.
- [ ] Pré-planejamento no MCP — suspenso pelo Renan (20/10). Ao retomar: leitura e prévia, nunca a
      escolha (doutrina de produtividade); textos em `instrucoes_ia.md`.

---

## F12 · Ficha técnica → orçamento — frente aberta

- [ ] A "tabela 3" (ficha técnica → orçamento, base do Easy Price/CPU).
- [ ] Uma rota do ativo ainda lê ficha/caderno de `catalogo.documentos`; migrar para
      `external_path.versoes` as-of.

---

## F13 · Integração viva com Excel — em espera

- [ ] Híbrido Power Query (leitura) + Office Add-in (escrita, SSO). Em espera por decisão do Renan.

---

## F14 · Catálogo — identidade da fonte, import e resíduos — frente aberta

### Identidade da fonte — o que ficou de futuro (bug 2, 26/10/2026)

A subida para prod está feita (conferida em 28/10). Abertos:
- [ ] **Fonte derivada de verdade** (SBC, ORSE, COMPESA): parser + L.S. da MO de outra fonte. A função
  única de edição por item e a tabela `catalogo.edicoes_dependencias` já existem (vazia). Quando
  entrar, as telas de composição do catálogo (cliente `/consulta-composicoes/detalhar` e interna
  `/composicoes/{id}/editar`) passam a mostrar a **data-base de cada insumo** — hoje é a mesma em
  todas as linhas (nenhuma composição do catálogo mistura fontes).
- [ ] **Correlação de fonte sucessora** (antecessora → sucessora, para a série atravessar o renome):
  desenhada no contrato §2.2, construída no primeiro renome real.
- [ ] **Divergência de arredondamento da FDE**: o oráculo conta CHEIA; as telas de insumo e a MO com
  L.S. do catálogo truncam ("ROUND arredonda, o resto trunca"). Ficou como era, agora escrito
  (contrato §2.3). Decidir se a tela deve seguir o perfil.
- [ ] **9 linhas sem data-base em dev**: insumos CDHU numa revisão antiga que só declara a PRÓPRIA —
  não há de onde tirar o mês; mostram "—".

### FDE — descrições com DOIS itens colados (parser da analítica)

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

#### Caminho de correção proposto (Renan) — e candidato a via OFICIAL

Prioridade declarada: **não deixar insumo/preço de fora**. Perder item é pior que descrição suja.

1. **MarkItDown** — converter o PDF para Markdown em vez de reconstruir linhas por coordenada de
   palavra. A estrutura de tabela sai pronta e o "parece continuação" deixa de ser heurística.
2. **Ao tomar o PREÇO do insumo, revisar a descrição.** O scraper do portal FDE já busca preço item
   a item (`fde_insumos_to_csv.get_price`) e a resposta traz a descrição **canônica da fonte**.
   Usar essa descrição para corrigir/validar a que veio do PDF fecha o ciclo sem custo novo: quem
   tem a verdade é o portal, não o PDF.

#### Protocolo obrigatório para aplicar (a lição do carimbo)

Conserto de parser **só entra com diff antes/depois contra o PDF real** — foi assim que o carimbo
de emissão foi corrigido (3.380 linhas medidas, 78→0, zero dano colateral). Sem isso, troca-se um
defeito conhecido por um desconhecido.
- [ ] rodar o parser atual, guardar a saída como linha de base;
- [ ] aplicar a correção; rodar de novo; **diferenciar item a item**;
- [ ] critério de aceite duplo: as 90 descrições limpas **E** a contagem de insumos/preços
      **não pode cair**;
- [ ] `sanity_check()` do próprio arquivo não pega isto — ele só reprova acima de 20 descrições
      suspeitas, e o critério dele não olha comprimento nem colagem. Endurecer junto.

### Sanidade do catálogo tem de rodar NO IMPORT, pela tela (2026-10-10)

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

### Resíduo no catálogo GLOBAL — `AX-000.001-CPU` (2026-10-06)

Achado ao varrer o banco para a migration dos códigos próprios: existe **1 composição no catálogo
GLOBAL** (`catalogo.composicoes`, `cmp_fte_id = 1`) com código no formato PRÓPRIO antigo —
`AX-000.001-CPU`, "ENGENHEIRO JUNIOR DE CIVIL COM ENCARGOS". Existe em **dev e em produção**, e
arrasta uma linha em `catalogo.search_document`.

Cheira a resíduo do incidente do item 16 (o bucket paralelo criado porque o código da fonte era
usado como chave de identidade). **Não foi tocado** pela migration de 06/10, que só mexe em
`tenant_catalogo` — mexer no catálogo global sem entender a origem seria pior que o sintoma.

**A resolver:** entender se é lixo (apagar) ou se é uma composição legítima que foi parar no bucket
errado (mover para o tenant certo, com código novo).

### Herdados dos planos de import de jun–jul (removidos em 29/10/2026)

- [ ] **Manutenções da SINAPI não chegam ao banco.** O import recebe o arquivo `SINAPI_Manutenções`
      (guardado como original), mas nada popula `catalogo.sinapi_manutencoes` (tabela existe, vazia), e a
      reconciliação **SINAPI-Diff × Axys-DIFF** (as manutenções publicadas cobrem o que o diff da Axys
      achou?) não existe. Era a Fase 3.4 do `PLANO_IMPORT_CATALOGO.md`.
- [ ] **Template genérico de import para fonte não nativa** (CSV/Excel no formato normalizado dos
      parsers + `parser_template.py` + testes). Era a Fase 6 do mesmo plano. Avaliar junto da *fonte
      derivada de verdade* (acima), que é onde ele faria falta.
- [ ] **4 blobs órfãos no R2 da FDE 04-26** (originais de runs antigos removidos do registro em 06/07:
      `relatorio_…`, `honorarios_TABELA DE HONORÁRIOS`, `html_catalogos_…`, `html_componentes_…`).
      Inofensivos, não linkados. Conferir se sobreviveram ao rebuild do catálogo antes de apagar —
      por chave exata, nunca por padrão.

---

## F15 · Catálogo Colaborativo — frente aberta

Referência: [../modules/catalogo/AXYS_CATALOGO_COLABORATIVO_v0.md](../modules/catalogo/AXYS_CATALOGO_COLABORATIVO_v0.md)

**Objetivo:** composições produzidas por tenants disponibilizadas para toda a comunidade mediante
validação da Axys. Depende de governança do catálogo, auditoria, versionamento e workflow de aprovação.

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

## F16 · Tabelas de domínio com tela (ADM) — frente aberta

- [ ] **As tabelas de domínio precisam de tela** — `catalogo.profissoes` (39),
  `catalogo.conselhos_classe` (3) e `doc_resp_tecnica` (3) nasceram semeadas no `schema.sql`, que é
  o certo para lista fechada e pequena. Mas elas **não são imutáveis**: profissão entra e sai, o CFT
  reconhece título novo, e o recorte de "construção e infraestrutura" é opinião — vai ser corrigido
  no uso. Hoje, acrescentar uma profissão exige editar o schema, escrever migration e fazer deploy:
  caro demais para uma linha de vocabulário. Pedem CRUD no módulo interno (ADM), ao lado do que já
  existe para o catálogo. Não trava nada agora; vira dor no primeiro *"falta o meu título aí"*.
  (Era o P7, e **tinha caído fora** desta lista na migração do documento do refino — recuperado do
  histórico em 11/10.)

---

## F17 · Certificação digital — assinar em lote — sem execução prevista

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

---

## F18 · Segurança — RLS por schema — avaliar

O isolamento entre tenants, o bucket privado, a fórmula no Excel, XSS, CSRF, OAuth do MCP, limite de login
e de IA, sandbox do HTML importado e o LIKE foram fechados em 28/10 (vigia `sanidade/isolamento_tenants.py`).
Ficou:

- [ ] **RLS no banco, por schema — `ativo` e `tenant_catalogo`** (avaliar depois; Renan, 28/10). Hoje o
      isolamento depende só da APLICAÇÃO (guarda de posse no roteador + `WHERE tenant_uuid` nos serviços);
      RLS faz o Postgres recusar linha de outro tenant mesmo que a query esqueça o filtro. É ligado e
      escrito tabela a tabela, mas um script aplica o mesmo padrão ao schema inteiro.
      - `tenant_catalogo`: toda tabela tem `*_tenant_uuid` → política direta (`= current_setting(...)`).
      - `ativo`: só `ativos`/`empreendimentos` têm o tenant; as filhas (`ativo_orcamento_*`) chegam a ele
        por cadeia (item → revisão → orçamento → ativo). Decidir: política que segue a cadeia (custo em
        toda query) ou coluna de tenant desnormalizada nas filhas (migration + manter na escrita).
      - Toda conexão do pool recebe `SET app.current_tenant` no começo da requisição e o esquece ao voltar
        ao pool; jobs/scripts que leem vários tenants usam um papel próprio. Sem o SET, o resultado é
        VAZIO em silêncio — testar cada consulta. Hoje só `core.jobs` tem RLS.

---

## F19 · Verificação de desempenho — com números — em curso

**Sintoma (Renan, 16/09):** ambientes antigos, com MAIS dados, respondiam mais rápido que os atuais —
o que descarta "faltou servidor" e aponta infraestrutura de back.

**Feito em 28/10:** ataque pontual (cast que matava índice 2.134 → 8 ms; analítico 4,37 → 0,31 s; uma ida
por gesto na bancada) e a MEDIÇÃO que faltava: toda resposta da app web sai com `Server-Timing`
(`db` = tempo e nº de queries, `app` = Python/template, `total`), visível no DevTools em prod. As
estatísticas de query de prod (`pg_stat_statements`) foram ZERADAS em 29/10 01:32 UTC — antes acumulavam
desde 21/09, misturando cargas, migrations e o antes dos consertos.

- [ ] Depois de alguns dias de uso real: ler `pg_stat_statements` de prod (as 20 de maior tempo total,
      fora o agente de métricas da Render) e medir pelo `Server-Timing` os endpoints quentes — bancada,
      analítico, cronograma, curva ABC, busca, caderno — separando rede, banco e app.
- [ ] Com os números: fechar esta pendência, ou abrir ataque com alvo. Não se mexe no que não foi medido.
- [ ] Ainda sem medida: pooler/região dos 3 serviços × banco (RTT por ida) e hit-rate do cache do catálogo.
