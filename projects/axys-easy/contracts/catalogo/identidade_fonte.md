# Contrato — Identidade da fonte

> **Status:** proposto 26/10/2026 (Renan) — governa toda decisão da app que dependa de "qual fonte é
> esta". Supera, no que conflitar: [fontes.md](fontes.md) §1-2 (troca de código) e
> [TENANT_CATALOGO_PROPOSTA.md](TENANT_CATALOGO_PROPOSTA.md) §0.6, §1 (fontes, edições), §2 (L.S.) e §8.4/8.8.
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
3. **Comportamento de cálculo específico de uma fonte é ATRIBUTO da fonte no banco**, nunca
   `if fonte == 'X'` no código. Fonte nova com o mesmo comportamento herda pelo atributo. Os dois
   que existem (Renan, 26/10/2026; migration `2026-10-26_fonte_perfil_bdi`):
   - `fte_perfil_arred` — `TRUNC` (SINAPI), `ROUND` (CDHU), `CHEIA` (FDE: unitário e linha cheios,
     total arredondado). Rege a **reprodução do import** (o oráculo da conferência). Nas telas de
     insumo e na MO com L.S. do catálogo, a regra é "ROUND arredonda, o resto trunca" — a FDE, CHEIA
     no oráculo, aparece truncada ali, como sempre foi. A **bancada não lê o perfil**: trunca tudo.
   - `fte_preco_com_bdi` — o preço publicado embute BDI (FDE): a conferência retira o BDI e a
     newsletter usa o custo limpo.
4. **Exceções** em que o código aparece no código-fonte, e o vigia `sanidade/nome_de_fonte.py` aceita:
   - o **parser** e o roteamento do import de cada fonte (presos ao formato do arquivo dela), os
     **seeds**, os **caminhos de storage** (o código é imutável) e o formato de documento de cada
     fonte (cabeçalho de grupo da CDHU, fichas da FDE, caderno da SINAPI);
   - a **SINAPI**: fica escrita no código (Renan, 26/10/2026) — é a fonte que publica o regime
     mensalista e a referência das equivalências; a ordem da newsletter também fica (vai mudar).

## 3. Tenant

1. O tenant cadastra fonte-base só como **perfumaria de nome**: `tenant_catalogo.fontes` é uma lista
   de rótulos (ORSE, SBC, D&C…) para dar granularidade. **Sem edição própria, sem L.S., sem
   comportamento.** O rótulo não decide nada. O **tipo** do rótulo (`fte_tipo` PRÓPRIA | EXTERNA) é
   atributo e continua: é ele que alimenta as flags dos entregáveis ("detalhar próprias / externas").
2. Insumo e composição próprios guardam o **id** do rótulo. Unicidade da composição: `(tenant,
   rótulo, código)`. A "PRÓPRIA" padrão é a fonte marcada `fte_bootstrap`, nunca procurada pelo texto.
3. **Edição própria mínima: só o mês.** `tenant_catalogo.edicoes` continua, com cadastro mínimo —
   o mês de referência (`mm/aaaa`); a descrição deriva dele, como no catálogo. A edição é **do
   tenant** (uma série de meses para todo o catálogo próprio), não de cada rótulo. O preço do insumo
   é por **(insumo, edição)**; a UF continua no insumo (`ins_uf`). É o mês que o usuário escolhe ao
   cotar e ao declarar a própria no orçamento.
4. **MÃO DE OBRA própria é cadastrada SEM ENCARGOS.** A tela diz isso sem ambiguidade ao escolher o
   tipo MÃO DE OBRA: cadastrar com encargos faz a bancada duplicá-los.
5. **Custo da composição própria**, por edição, como no catálogo: Σ coef × preço do filho naquela
   edição, **sem encargos** fora da bancada (rotulado assim). Filho sem preço na edição → a
   composição fica **sem custo** naquela edição — honesto, igual ao catálogo. O custo é guardado
   (cache) e **recalculado para todas as composições ATIVAS** quando uma edição é cadastrada ou um
   preço muda; composição inativa não é recalculada (a tela oferece **inativar**).
   Filho do catálogo global dentro da própria: edição mais recente da fonte dele, na UF da linha.
6. **O que o usuário criou é dele, para sempre.** Insumo ou composição própria criada em qualquer
   lugar (cadastro, import, bancada) vai para o catálogo do tenant. Não existe "entrou no orçamento
   mas não no catálogo".

## 4. Bancada

1. Na configuração de fontes do orçamento, a própria é **UMA linha**, identificada pela **ORIGEM**
   (rótulo PRÓPRIA) — libera todas as composições próprias, de qualquer rótulo — com a escolha da
   **edição própria** (o mês). O catálogo global é escolhido por código + edição.
   A linha PRÓPRIA não tem UF (está no insumo), não converte L.S. (a MO própria leva sempre a L.S. do
   ativo, na modalidade da favorita) e não pode ser favorita.
2. **A favorita é obrigatória** e é uma fonte do catálogo global. A **data-base do orçamento** é o
   mês da edição da favorita — derivada, não gravada.
3. Item próprio sem preço na edição própria declarada entra **sem preço**, como no catálogo. Ao
   capturar, a bancada congela o preço no estado, como faz com tudo.
4. **O preço exibido dentro do ativo** (Consulta, busca da bancada) é o que o item vai ter **com a
   configuração daquele ativo**: fonte com conversão de L.S. ligada → L.S. do ativo; desligada → a
   L.S. da própria fonte. Não converter é escolha do usuário — um erro, talvez, mas dele: a Axys não
   proíbe usar o preço referencial sem adequar.
5. **Cotação — vive no lugar do dono do insumo:**
   - insumo **próprio**: só no catálogo do tenant (`pri_cotacoes`). A cotação feita na bancada grava
     na **edição própria declarada no orçamento** e só traz o preço para a bancada; se a edição já
     tem preço, a tela pergunta se substitui. As cotações de insumo próprio já gravadas nos
     orçamentos migram para o catálogo do tenant;
   - insumo do **catálogo global**: a bancada é o armazenamento dela mesma — cotação e ajuste ficam
     **no orçamento**. Guardar no catálogo próprio é ação explícita, na página da cotação da bancada.
6. **Data-base de cada insumo** (Renan, 26/10/2026). O preço de cada insumo no estado guarda o mês
   de quando é (`azp_data_base`, dia 1; NULL = sem preço), e a tela Ver composição e o PDF dela
   mostram a coluna em **mm/aaaa**:
   - catálogo: o mês da edição de onde o preço veio;
   - próprio: o mês da edição própria de onde veio (com "último preço registrado", pode ser
     anterior ao declarado);
   - cotação feita na bancada (catálogo ou próprio): o **mês em que foi feita** — o dado concreto. A
     app não confere as datas das propostas: o que o usuário cotou é escolha dele.
   A linha de **CPU e sub-CPU** mostra o mês da edição declarada da fonte dela: a composição é
   derivação dos insumos e foi resolvida agora — não se grava.
   **Insumo sem preço → "ver histórico"** no lugar do preço: modal `edição | preço | aplicar ao
   orçamento` com as edições da fonte do insumo **até** o mês da edição declarada (nunca posterior),
   só as que têm preço, na UF e modalidade da linha; as de mais de 6 meses levam marca (janela do
   TCU). No fim, **[ criar cotação ]** → a página da cotação da bancada. **Aplicar** grava só no
   orçamento — catálogo e próprio, o catálogo do tenant fica intacto — com o valor e a data-base da
   edição escolhida; MO leva a L.S. do ativo, como na captura. A origem fica na evidência da cotação
   e na auditoria.
   **No editor da composição da bancada** a data-base é escolha do usuário: cada insumo do estado
   tem o seletor com as mesmas edições do histórico; trocar o mês troca o unitário da linha e vai
   no Salvar (Cancelar descarta), pelo mesmo miolo do aplicar — vale para o insumo no orçamento
   inteiro, como a cotação. A linha de CPU mostra a data vigente e não se escolhe.
   (Substitui o "botão direito → cotações de orçamentos anteriores", que não chegou a ser feito.)
7. O rótulo gravado no estado do orçamento (`aoc_fonte`, `aoz_fonte`) é **retrato da época**: não
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
