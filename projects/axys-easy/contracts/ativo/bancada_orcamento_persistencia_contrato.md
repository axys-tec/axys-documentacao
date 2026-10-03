# Bancada de Orçamento — Contrato de Persistência (o orçamento é autossuficiente)

**Versão:** 1.0 · **Data:** 2026-10-03 · **Aprovado por:** Renan Dias (Product + Architecture)
**Status:** contrato de domínio. Governa o schema `ativo` na parte do orçamento.
**Fonte da verdade do schema:** `docs/projects/axys-easy/schemas/schema.sql` (bloco "MÓDULO ATIVO").
**Correlatos:** `bancada_orcamento_contrato.md` (mecânica da tela), `EASY_ATIVO_CONTRATO.md`,
`catalogo/` (de onde o dado nasce).

**Revoga:** a tese "o preço é **resolvido**, não gravado" de `EASY_ATIVO_CONTRATO.md` §0, e o par
de tabelas `ativo.orcamento_insumos` + `ativo.orcamento_insumos_preco` na forma em que foram
desenhadas (ver §8).

---

## 0. Tese em uma frase

**O orçamento é uma planilha, não uma consulta.** O catálogo é onde o dado nasce; no instante em
que entra na bancada, o dado passa a ser do orçamento, e nada do que o orçamento mostra depende de
ir buscar coisa alguma fora dele.

## 1. O princípio, dito com precisão

> **A independência é do CATÁLOGO, não da bancada.**

Congela-se o que **nasce fora**: código, descrição, unidade, coeficiente, preço, SE, classe do
insumo, fonte e edição. Continua vivo o que é **da bancada**: `ativo_ls`, BDI, quantidade — porque
são parâmetros do próprio usuário, e ele manda neles.

Três razões, em ordem de peso:

1. **Confiança no dado.** Um recall não pode alterar orçamento alheio em silêncio; o detalhe não
   pode discordar da bancada; gerar o documento não pode mudar o que o usuário viu.
2. **A própria SINAPI declara que suas composições são genéricas.** O usuário pode e deve adaptá-las.
   Adaptou — o dado é dele.
3. **Desempenho**, que vem de brinde (§9). Não é a justificativa: as redundâncias de hoje se
   resolveriam com memoização, sem schema novo. A justificativa é a confiança.

## 2. O que acontece ao inserir — materialização

Ao adicionar um serviço na bancada, o sistema **consome** do catálogo (ou do `tenant_catalogo`) e
**grava** o resultado nas tabelas do orçamento. Uma vez. Daí em diante, o catálogo não é mais lido
para aquele serviço.

Por causa das composições filhas, **um serviço pode gravar duas ou mais composições**: a raiz e
cada sub-CPU alcançada, recursivamente.

**A rotação de regime materializa.** Quando a MO é convertida (horista → mensalista), a composição
já entra na bancada **com o insumo certo e as horas convertidas**. `mdo_estado` (REG/NC) é
**marcador do que aconteceu**, não instrução para recalcular depois. Não existe "variante a
reinterpretar": o que está gravado já é a composição final.

## 3. As quatro tabelas

### 3.1 `ativo.ativo_orcamento` (hoje `ativo.ativo_itens`)

A EAP e a linha do orçamento. Renomeada porque "itens" não remete a orçamento; a EAP vai junto.

| guarda | por quê |
|---|---|
| EAP: `parent_id`, `ordem`, `path`, `num`, `nivel`, `tipo` | a árvore é a verdade; o número `1.2.3` é render |
| `codigo`, `descricao`, `unidade` | **`codigo` não existe hoje** — é buscado no catálogo a cada render |
| `quantidade` | da bancada (memória de cálculo, digitação ou Excel) |
| `bdi_id` | da bancada |
| FK → `ativo_orcamento_composicao` | o vínculo com a composição materializada |
| flags de linha: `is_alo`, `obs`, `have_memory_calc` | estado da linha, não do custo |

### 3.2 `ativo.ativo_orcamento_composicao`

Uma linha por composição **efetiva** no ativo — inclusive as auxiliares (sub-CPUs usadas
indiretamente, que não são linha de serviço).

| guarda | por quê |
|---|---|
| `atv_id`, `origem` (CATALOGO \| TENANT), `cmp_id` | **a chave** — ver §5 |
| `codigo`, `descricao`, `unidade` | identidade, congelada |
| `fonte`, `edicao_id`, `uf`, `modalidade` | a procedência daquele dado, no instante em que entrou |
| `custo_unit` | gravado (desempenho ao abrir) **e** conferível contra a soma dos filhos |
| `preco_fixado`, `desc_fixada` | override do usuário — **da composição**, não da linha (§5) |
| `mdo_estado` (REG/NC) | marcador do que foi materializado |

### 3.3 `ativo.ativo_orcamento_composicao_item`

O vínculo. **Espelho de `catalogo.composicoes_itens`** — não se inventa forma nova:

| guarda | espelha |
|---|---|
| FK → composição-pai | `ci_cmp_id` |
| `tipo_filho` (INSUMO \| COMPOSICAO) | `ci_tipo_filho` |
| FK → insumo **ou** FK → composição-filha | `ci_ins_id` / `ci_cmp_filho_id` |
| `coef` | `ci_coef` |
| `ordem` | `ci_ordem` |

Recursiva, como o original. É isto que sustenta sub-CPU sem tabela extra.

### 3.4 `ativo.ativo_orcamento_insumo`

A folha.

| guarda | por quê |
|---|---|
| `atv_id`, `origem_ref` | identidade no orçamento |
| `codigo`, `descricao`, `unidade` | congelados |
| **`classe`** (MO, MAT, EQUIP_AQ, EQUIP_LOC, ENC_COMP, ESP, SERV) | **obrigatória**: é ela que decide se a LS incide |
| `preco` **ou** `se` | duas colunas explícitas, nunca uma — ver §4 |

## 4. Mão de obra — o caso que muda o desenho

O preço da MO **não é um preço**. Medido no atv 22:

```
SE = 13.778,60   ·   LS = 71,18%   ·   valor exibido = 23.586,20
13.778,60 × 1,7118 = 23.586,21  ✓
```

O **SE nasce no catálogo**; o **LS é da bancada** (`ativo_ls`, que o usuário edita). Congelar o
valor final da MO quebraria a edição de LS — o orçamento passaria a ignorar um parâmetro do próprio
usuário.

**Regra:** para `classe = MO`, congela-se o **SE**; o LS incide na leitura, vindo de `ativo_ls`.
Para as demais classes, congela-se o **preço**.

`se` e `preco` são **colunas distintas**. Uma coluna só, interpretada pela classe, é o erro mais
caro possível aqui.

## 5. A chave e o invariante que a sustenta

**Chave da composição: `(atv_id, origem, cmp_id)`.** Simples, sem variante.

Ela só é válida sob este invariante, que é o núcleo do contrato:

> **Dentro de um ativo, uma composição tem UM unitário, UMA descrição e UM regime.**

Tudo que é por-item e alteraria o unitário **sobe para o nível da composição**: `preco_fixado`,
`custo_unit`, `descricao` fixada, `mdo_estado`. Fixar o preço de um serviço fixa em todos os
lugares onde aquela composição aparece — por desenho, não por efeito colateral.

A razão é a curva ABC, e é demonstrável (§7). Divergir de verdade tem outro caminho, que já existe:
**derive uma composição própria** (`tenant_catalogo`), que tem código próprio, auditoria e entra no
Caderno de Encargos como entidade distinta.

## 6. Ciclo de vida

### 6.1 Inserir
Consome do catálogo, materializa nas quatro tabelas, uma única vez por composição alcançada.
**Segunda inserção da mesma composição reusa a foto existente** — nunca refotografa. Duas linhas do
mesmo serviço com preços diferentes é defeito visível, não fidelidade ao Excel.

### 6.2 Excluir — por alcançabilidade, nunca por contador
Composição A usa B; B também é usada por C. Apagar o serviço que usava A deixa A órfã, **mas não B**.

**Regra:** a partir das linhas de serviço sobreviventes, caminha-se o grafo; o que não for alcançado
é removido. Uma CTE recursiva. Contador de referências desanda no primeiro bug e não enxerga o caso
acima.

### 6.3 Re-sincronizar — porta explícita, com diff
O recall acontece sob comando. A atualização do orçamento **também**: operação explícita, com tela
de diff mostrando o que muda, antes de mudar. Sem essa porta, o congelado vira prisão.

## 7. Defeito conhecido, a corrigir junto

`get_curva_abc` agrega por `(origem, cmp_id)` e toma o **unitário da primeira linha**, somando qtd e
total de **todas**. Com preço fixado em uma linha só, a linha da curva não multiplica:

```
composição 09.01.065, 2 linhas: 40 × 121.886,88 e 1 × 121.886,88
preço fixado na 2ª, ao dobro

curva ABC:  unitário 121.886,88 × qtd 41,00 = 4.997.362,08
            total exibido                   = 5.119.248,96
            divergência                        121.886,88
```

O total do orçamento continua certo (a reconciliação absorve o resíduo na maior linha) — **só a
linha mente**, o que é pior, porque passa despercebido até alguém auditar. O invariante de §5
elimina a causa.

## 8. O que isto revoga

- **`EASY_ATIVO_CONTRATO.md` §0**, na parte "o preço é resolvido, não gravado". Passa a ser:
  *o preço é resolvido no instante da inserção e gravado; a leitura não resolve nada.*
- **`ativo.orcamento_insumos` + `ativo.orcamento_insumos_preco`** (vazias, zero referência no
  código): a primeira é absorvida por `ativo_orcamento_insumo` — já tem `origem_ref`, `descricao`,
  `unidade`; faltam `codigo`, `classe` e `se`. A segunda some: preço por UF não se aplica, porque o
  insumo pertence a **uma** fonte, e a UF é fixa por fonte (`uq_opa_atv_fonte`) — logo o insumo
  tem uma UF só. (Um ativo **pode** ter UFs diferentes entre fontes: o atv 26 roda SINAPI/SC com
  CDHU, FDE e PRÓPRIA em SP. Isso não cria dois preços para o mesmo insumo.)
- **`ativo.ativo_itens.ati_regras_json` e `ati_ajuste_json`** (vazias, zero referência): não entram
  no desenho novo. Removê-las no mesmo passo.

`ativo.ativo_revisoes` e `ativo.ativo_eventos` **permanecem**, com papel redefinido: a revisão é
**prova na emissão** (snapshot hasheado write-once), não mecanismo de correção. A correção é este
contrato.

## 9. Desempenho — medido, não estimado

Estado de hoje (atv 22, 877 linhas / 739 serviços, cache do catálogo frio):

| | |
|---|---|
| queries por montagem do analítico | **9.379** (12,7 por serviço) |
| invariantes do ativo relidas por item | **7.896 (84%)** |
| pior caso isolado | a árvore inteira relida **739×** = 79% de todo o tempo de SQL |
| composições distintas | **121**, para 739 linhas → a mesma composição recalculada ~6× |

Em produção o banco é outro serviço: 9.379 idas × ~2 ms ≈ **19 s só de rede**. É por isso que dói
em prod e não em dev.

Com as quatro tabelas, abrir o orçamento é um punhado de queries, independente do cache e do
catálogo.

## 10. Storage — medido

| | atv 22 (739 serviços) |
|---|---|
| 4 tabelas relacionais | **~200 KB** (276 composições + 1.147 itens + 327 insumos = 1.750 linhas) |
| `rev_snapshot_json` comprimido | 465 KB |
| o mesmo JSON cru | 10.560 KB |

O relacional é **menor que o JSON**, porque o JSON repete chave em cada linha e não deduplica
composição. 1.000 orçamentos desse porte = 195 MB; 10.000 = 1,9 GB — contra os 4,7 GB que
`catalogo.composicoes_custo` já ocupa. Não é explosão.

**JSON em disco da Render está descartado por fato:** `render.yaml` só declara disco para o
OpenSearch; web e worker têm filesystem efêmero, apagado a cada deploy, e são serviços separados.

## 11. O que NÃO se grava

| não se grava | por quê |
|---|---|
| `pct_ls`, `ls_fonte` | da bancada (`ativo_ls`), o usuário edita |
| BDI | da bancada |
| `quantidade` na foto da composição | é vínculo explícito da linha, não da composição |
| `total` do item (`coef × valor`) | derivado; gravar derivado é convite a divergir |
| `ti`/classe em filho do tipo COMPOSICAO | classe é de insumo (medido: presente nas 1.542 linhas INSUMO, ausente nas 1.564 COMPOSICAO) |

## 12. Em aberto

1. **Renomear `ativo_itens` → `ativo_orcamento`** deve ser **commit separado**, só de rename. Junto
   com mudança estrutural, esconde erro.
2. **Limpeza das redundâncias (§9)** é independente do schema e barata. Vale fazer antes, para que
   o ganho do repense seja medido pelo que ele é — correção —, e não confundido com desempenho.
3. **Migração dos orçamentos existentes** — passo 3 do plano, ainda não projetada.
