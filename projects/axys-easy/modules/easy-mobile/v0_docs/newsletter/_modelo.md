# Modelo editorial — Axys Newsletter

Toda a **copy** da revista mora aqui. O código só desenha e injeta números; quem escreve
mexe neste arquivo e não em Python.

Cada bloco começa com `## chave`. O texto abaixo dele é o que sai no PDF. Os marcadores
entre chaves são substituídos pelos números do dossiê da edição — se você escrever um
marcador que não existe, a geração falha na hora, em vez de publicar `{coisa}` na cara do
leitor.

**Marcadores disponíveis:** `{fonte}` `{codigo}` `{mes_extenso}` `{uf}` `{intervalo}`
`{meses}` `{media}` `{mediana}` `{comparaveis}` `{subiram}` `{cairam}` `{estaveis}`
`{incluidas}` `{inativadas}` `{reativadas}` `{alteradas}` `{ufs}` `{cpus}`
`{pct_sem_custo}` `{pct_sem_preco}` `{ipca}` `{selic}` `{veredito}` `{veredito_frase}`
`{total_subgrupos}` `{ins_media}` `{ins_comparaveis}` `{ref_curto}` `{ref_anterior_curto}`
`{distancia_uf}`

---

## lead

A edição de {mes_extenso} apresentou variação média de {media}% nos custos das
composições em {uf}, {veredito_frase}. Entre as atualizações da fonte, foram incluídas
{incluidas} novas composições, {inativadas} foram inativadas e outras {alteradas}
passaram por revisão.

## abre_360

Visão 360°

## titulo_360

{fonte} {codigo}, em números

## indices_titulo

A fonte diante dos índices

## indices_nota

Variação da fonte em {uf}, regime sem desoneração, contra os índices acumulados no
intervalo entre a edição atual e a edição anterior. {selic_frase}

## placar_titulo

A média não conta a história

## placar_texto

Das {comparaveis} composições comparáveis, {subiram} tiveram aumento de custo e {cairam}
tiveram redução. A média de {media}% é o resultado desse balanço, não o comportamento
típico. A mediana das variações ficou em {mediana}%.

## movimento_titulo

O que entrou, saiu e voltou

## cobertura_texto

**Cobertura desta edição:** {ufs} UFs e {cpus} composições. Do total publicado, {pct_sem_custo}%
das linhas de custo das composições e {pct_sem_preco}% dos preços de insumos foram
disponibilizados pela fonte sem preço. Esses percentuais ajudam a dimensionar a cobertura
efetiva da edição e a disponibilidade de preços para uso em orçamentos.

## abre_subgrupos

Impacto por subgrupo

## titulo_subgrupos

Onde os custos variaram

## subgrupos_texto

A análise considera os subgrupos com pelo menos 10 composições comparáveis em {uf}. Nesta
edição, {total_subgrupos} subgrupos atenderam a esse critério. Para cada um deles, a
variação foi calculada a partir dos custos médios das duas edições, permitindo identificar
onde ocorreram os maiores aumentos e reduções no período.

## altas_titulo

Os dez maiores aumentos

## baixas_titulo

Os subgrupos com redução

## baixas_vazio

Nenhum subgrupo apresentou redução nesta edição.

## abre_extremos

Insumos e território

## titulo_extremos

Os extremos da edição

## insumos_titulo

Insumos com maior variação

## insumos_nota

Variação de preço em {uf}, sem encargos. São preços de mercado coletados pela
fonte-base, e os extremos refletem o comportamento do item no período. Para entender
melhor essas variações, recomendamos a avaliação dos respectivos insumos, das composições
que os utilizam, bem como uma análise de mercado no período indicado.

## uf_titulo

A variação não é nacional

## uf_texto

A variação de preços apresenta diferenças entre as UFs. Nesta edição, {uf_maior_nome}
registrou a maior variação, com {uf_maior_pct}%, enquanto {uf_menor_nome} apresentou a
menor, com {uf_menor_pct}%. A diferença entre os dois extremos foi de {distancia_uf}
pontos percentuais.

## uf_texto2

Esse intervalo demonstra a importância de considerar o comportamento dos preços em cada
estado. Abaixo, apresentamos a variação observada em cada UF contemplada pela
fonte-base.

## uf_nota

Todas as {ufs} UFs contempladas pela fonte-base, na mesma escala.

## kpi_variacao

Variação média ({uf})

## kpi_revisadas

Revisadas

## kpi_cobertura_capa

Cobertura

## kpi_cobertura

Cobertura

## revisoes_titulo

Revisões da edição

## revisoes_texto

Das {alteradas} composições revisadas, {rev_coeficiente} tiveram alteração de coeficiente,
{rev_incluido} passaram a contar com novo insumo e {rev_excluido} tiveram insumo removido.
Uma mesma composição pode figurar em mais de uma categoria.

## acumulado_titulo

No acumulado do ano

## acumulado_texto

Variação desde o fechamento de dezembro até esta edição, em {uf}, ao lado dos índices
acumulados no mesmo período.

## revisoes_subgrupos_titulo

Onde as revisões se concentraram

## acumulado_rotulo_fonte

{fonte} ({uf})

## encerramento_titulo

Como usar esta edição

## encerramento_texto

Os números desta edição saem da leitura completa da publicação da fonte-base, comparada com a edição imediatamente anterior. As composições e os insumos citados podem ser consultados em detalhe na **Base de Conhecimento Axys**, disponível no aplicativo. Se você orça com {fonte}, vale conferir se os subgrupos listados nesta edição estão presentes no seu orçamento em andamento.
## abre_grupos

Impacto por frente

## titulo_grupos

Como cada frente de obra se comportou

## grupos_texto

A {fonte} organiza as composições em grupos, que reúnem serviços de uma mesma frente de
obra. Nesta edição, {total_grupos} grupos tinham composições comparáveis em {uf}. A
leitura por frente mostra onde o movimento se concentrou, antes de descer ao detalhe do
subgrupo.

## grupos_altas_titulo

As frentes com maior aumento

## grupos_baixas_titulo

As frentes com redução

## grupos_nota

Grupos com pelo menos 5 composições comparáveis. A variação é a razão entre os custos
médios das duas edições, o que respeita a grandeza de cada composição dentro da frente.
