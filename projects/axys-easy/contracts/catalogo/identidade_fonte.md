# Contrato — Identidade da fonte

> **Status:** proposto 26/10/2026 (Renan) — governa toda decisão da app que dependa de "qual fonte é
> esta". Supera, no que conflitar: [fontes.md](fontes.md) §1-2 (troca de código) e
> [TENANT_CATALOGO_PROPOSTA.md](TENANT_CATALOGO_PROPOSTA.md) §0.4-0.6, §1 (edições), §2 e §8.4/8.7/8.8.
>
> Código e SQL que decidem por fonte referenciam este contrato no topo do arquivo.

---

## 1. A regra

**Nenhuma decisão do back é tomada pelo NOME de uma fonte.** Nome é exibição, e na entrada (o usuário
digitando, um arquivo importado) é buscador de identificador — traduzido **uma vez**, na entrada.

O que identifica uma fonte depende de quem é o dono dela:

| dono | identificador | o que pode mudar |
|---|---|---|
| catálogo global (`catalogo.fontes`) | `fte_codigo` (`SINAPI`, `CDHU`, `FDE`…) — **imutável** | `fte_nome` (exibição) |
| tenant (`tenant_catalogo.fontes`) | `fte_id` — o código é só rótulo | o rótulo, à vontade |

O mesmo inteiro existe nos dois catálogos (id-spaces separados). **Todo id de fonte, edição, insumo ou
composição anda com a sua ORIGEM** (catálogo × tenant). Id sem origem é defeito.

## 2. Catálogo global

1. `fte_codigo` é único e **imutável**. A guarda é do banco: um gatilho recusa `UPDATE` da coluna.
   A tela de fonte não oferece o campo na edição.
2. **Renomear não existe.** Se a fonte muda de nome (CPOS → CDHU já aconteceu), cadastra-se uma fonte
   nova. A **correlação antecessora → sucessora**, para a série de preços atravessar a troca, é
   desenhada aqui e construída no primeiro caso real: uma referência da fonte nova à antiga, com a
   data da troca; leituras de série (histórico, acumulado) seguem a cadeia.
3. **Comportamento específico de uma fonte é ATRIBUTO da fonte no banco**, nunca `if fonte == 'X'` no
   código: perfil de arredondamento, publicação de regime mensalista, preço publicado com BDI etc.
   Fonte nova com o mesmo comportamento herda pelo atributo, não por um `if` a mais.
4. **Exceções** em que o código aparece no código-fonte: o **parser** de import de cada fonte (é preso
   ao formato do arquivo dela), os **seeds** e os **caminhos de storage** (válido porque o código é
   imutável).

## 3. Tenant

1. O tenant cadastra fonte-base só como **perfumaria de nome**: `tenant_catalogo.fontes` é uma lista
   de rótulos (ORSE, SBC, D&C…) para dar granularidade. **Sem edição, sem L.S., sem comportamento.**
   O rótulo não decide nada.
2. Insumo e composição próprios guardam o **id** do rótulo. Unicidade da composição: `(tenant,
   rótulo, código)`. A "PRÓPRIA" padrão é a fonte marcada `fte_bootstrap`, nunca procurada pelo texto.
3. **O preço próprio é datado por mês** (`mm/aaaa`): o mês é a "edição" do preço = a data-base dele.
   Um preço por insumo por mês. A UF continua no insumo (`ins_uf`).
4. **MÃO DE OBRA própria é cadastrada SEM ENCARGOS.** A tela diz isso sem ambiguidade ao escolher o
   tipo MÃO DE OBRA: cadastrar com encargos faz a bancada duplicá-los.
5. O custo da composição própria é **calculado** (Σ coef × preço do filho). Fora da bancada (Dados
   Próprios) sai **sem encargos**, rotulado assim; na bancada, a MO leva a **L.S. declarada na
   bancada**. Não há custo armazenado por edição.
6. **O que o usuário criou é dele, para sempre.** Insumo ou composição própria criada em qualquer
   lugar (cadastro, import, bancada) vai para o catálogo do tenant. Não existe "entrou no orçamento
   mas não no catálogo".

## 4. Bancada

1. Na configuração de fontes do orçamento, a própria é a **ORIGEM** (rótulo PRÓPRIA), sem escolha de
   edição. O catálogo global é escolhido por código + edição.
2. O preço próprio que vale é o **mais recente até a data-base do orçamento**; ao capturar, a bancada
   o congela no estado, como faz com tudo.
3. **Cotação — vive no lugar do dono do insumo:**
   - insumo **próprio**: só no catálogo do tenant (`pri_cotacoes`). A cotação feita na bancada grava
     ali, no mês, e só traz o preço para a bancada;
   - insumo do **catálogo global**: a bancada é o armazenamento dela mesma — cotação e ajuste ficam
     **no orçamento**. Guardar no catálogo próprio é ação explícita, na página da cotação da bancada.
4. **Ver cotações anteriores:** botão direito no item → lista das cotações daquele insumo/serviço em
   orçamentos anteriores do tenant → clicar expande, com **Copiar para o orçamento** e **Acessar** (a
   página da cotação).
5. O rótulo gravado no estado do orçamento (`aoc_fonte`, `aoz_fonte`) é **retrato da época**: não
   acompanha mudança posterior de nome. É exibição, nunca chave.

## 5. Edição por item (fonte derivada)

1. Hoje o motor precifica todos os insumos de uma composição com **uma** edição, a da fonte da
   composição. Isso não serve para fonte **derivada** (SBC, ORSE, COMPESA): a COMPESA 7/26 usa insumos
   da SICRO 4/26.
2. **A edição que vale para um item é resolvida por UMA função**: "qual edição vale para este item,
   dado de qual composição ele é". Hoje ela responde a edição configurada para a fonte do item; com
   fonte derivada, consulta a **dependência declarada pela edição** (COMPESA 7/26 → SICRO 4/26,
   SINAPI x/26). No orçamento o usuário escolhe só a derivada; as dependências vêm junto.
3. A tabela de dependências entre edições existe desde já, vazia. O parser da primeira derivada e a
   regra de L.S. da MO de outra fonte dentro dela (de quem é a L.S.?) entram quando ela entrar.
