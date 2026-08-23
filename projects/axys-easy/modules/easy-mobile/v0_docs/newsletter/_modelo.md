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

O que mudou na edição de {mes_extenso} da {fonte}: {media}% de variação média
{intervalo}, {veredito_frase}, com {incluidas} composições incluídas e {inativadas}
inativadas.

## abre_360

Visão 360°

## titulo_360

{fonte} {codigo}, em números

## indices_titulo

A fonte diante dos índices

## indices_nota

Variação da fonte em {uf}, regime sem desoneração, contra os índices acumulados no
intervalo entre as duas edições ({meses}). A Selic ({selic}% a.a.) aparece como contexto e
não entra na comparação: é taxa, não variação de preço.

## placar_titulo

A média não conta a história

## placar_texto

Das {comparaveis} composições comparáveis, {subiram} subiram e {cairam} caíram. A média de
{media}% é o saldo desse encontro, não o comportamento típico — a mediana ficou em
{mediana}%.

## movimento_titulo

O que entrou, saiu e voltou

## cobertura_texto

**Cobertura desta edição:** {ufs} UFs e {cpus} composições. {pct_sem_custo}% das linhas de
custo saíram sem valor e {pct_sem_preco}% dos preços de insumo estão vazios. Isso é
característica da publicação da fonte, e não do nosso processamento — informamos porque
quem orça precisa saber onde a base não alcança.

## abre_subgrupos

Impacto por subgrupo

## titulo_subgrupos

Onde o preço se moveu

## subgrupos_texto

Subgrupos com pelo menos 10 composições comparáveis, em {uf}. {total_subgrupos} subgrupos
tinham dado suficiente nesta edição. A variação é a razão entre os custos médios das duas
edições, e não a média das variações item a item: é ela que responde quanto o subgrupo
pesou, respeitando a grandeza de cada composição.

## altas_titulo

As dez maiores altas

## baixas_titulo

E as que recuaram

## baixas_vazio

Nenhum subgrupo fechou em queda nesta edição.

## abre_extremos

Insumos e território

## titulo_extremos

Os extremos da edição

## insumos_titulo

Insumos que mais se moveram

## insumos_nota

Variação de preço em {uf}, sem encargos. Extremos costumam refletir recomposição pontual
de um item, e não tendência de mercado — leia junto com a média de {ins_media}% dos
{ins_comparaveis} insumos comparáveis.

## uf_titulo

A variação não é nacional

## uf_texto

A média esconde o mapa. Entre a UF que mais subiu e a que menos subiu há {distancia_uf}
pontos percentuais de distância nesta edição — orçamento feito com a média do país erra
nos dois extremos.

## uf_nota

As cinco UFs de maior e de menor variação, na MESMA escala. Dois gráficos lado a lado,
cada um normalizado pelo próprio máximo, fariam uma queda de 0,2% parecer maior que uma
alta de 0,3%.

## kpi_variacao

Variação média ({uf})

## kpi_insumos

Insumos

## kpi_ipca

Diante do IPCA

## kpi_cobertura

Cobertura
