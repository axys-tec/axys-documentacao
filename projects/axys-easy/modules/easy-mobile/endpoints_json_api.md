# Easy Mobile API — contrato de endpoints

**Serviço:** `backend/app_mobile_api.py` · **Host (prod):** `easy-mobile.axys-tec.com.br`
**Prefixo:** `/v0` · **Governado por:** `projeto.md` (este documento detalha; aquele decide)

> **A API não serve conteúdo editorial.** Newsletter, artigos, terminologia, casos,
> acórdãos e downloads vêm do **R2/CDN**, direto para o aplicativo, sem passar por aqui —
> formato e layout em **`conteudos_json_r2.md`**. Esta API entrega **dados de custo**:
> catálogo, busca, composições, insumos, índices, conversão e simulação.

---

## Regras que valem para TODAS as rotas

**Autenticação obrigatória.** `Authorization: Bearer <JWT do Hub>`, com `aud=easy-mobile`.
O token é emitido pelo **Hub** — o app faz login direto lá, e a senha nunca passa por esta
API. Token do Easy Web (`aud=easy`) é **recusado**, e vice-versa.

Claims usadas: `sub` (uuid), `subject_type` (`hub_user` | `mobile_client`) e
`client_hub_uuid`.

**Cota por usuário** (§5.6). `429` ao estourar, com `Retry-After`.

| | por minuto | por dia |
|---|---|---|
| requisições | 60 | 3600 |
| buscas | 30 | 400 |

**Limites de consulta** (§5.3): termo com **mínimo 3 caracteres**, **25 por página**, teto de
**10 páginas**. Estouro devolve `422` com mensagem que orienta a refinar.

**Valores são NÚMERO, datas são ISO** (§5.2). `276.19`, não `"R$ 276,19"`. `"2026-08"`, não
`"ago/26"`. A formatação é do Flutter, pelo locale do aparelho.

**Cache** é `private` (a resposta é autenticada). Edição explícita na URL → 30 dias, porque
edição publicada é imutável. Sem edição → 5 min, porque resolve "a vigente".

**Erros:** `401` sem token ou audience errada · `404` inexistente · `422` limite de consulta ·
`429` cota estourada.

---

## Catálogo

### `GET /v0/catalogo/filtros`
Bootstrap da tela de consulta. Uma chamada monta a barra de filtros inteira e responde
"qual é a edição vigente".

```json
{ "fontes": [{"id":1,"codigo":"SINAPI","nome":"…"}],
  "ufs": ["AC","AL","…"],
  "edicoes": [{"id":58,"fonte":"SINAPI","versao":"06-26","mes_ref":"2026-06","vigente":true}],
  "modalidades": [{"codigo":"SD","rotulo":"Sem desoneração"},{"codigo":"CD","rotulo":"Com desoneração"}],
  "defaults": {"uf":"SP","modalidade":"SD","tipo":"TODOS"} }
```

### `GET /v0/busca`
`q` (≥3) · `tipo` `TODOS|INSUMO|COMPOSICAO` · `fonte` · `edicao` · `uf` · `modalidade` · `pagina`

Candidatos ranqueados (código exato > full-text > trigram), reidratados no Postgres.

```json
{ "query":"interruptor bipolar", "pagina":1, "por_pagina":25, "total":312,
  "contexto":{"uf":"SP","modalidade":"SD","edicao":null,"tipo":"COMPOSICAO"},
  "itens":[{"tipo":"COMPOSICAO","id":15666,"fonte":"FDE","codigo":"09.08.038",
            "descricao":"…","unidade":"un","custo":276.19,"sem_custo":false,
            "mes_ref":"2026-04","match":"descricao"}] }
```

`match` é `codigo` · `descricao` · `similaridade` — permite ao app agrupar "achou pelo
código" acima de "achou por semelhança" sem trocar o motor de busca.

> **tipo=TODOS**: o índice filtra por tipo de entidade, então são duas consultas mescladas
> por score. `total` é a soma e a ordenação global é aproximada nas páginas seguintes.

### `GET /v0/composicoes/{id}`
`edicao` · `uf` · `modalidade`

Detalhamento **analítico precificado**. O `total` vem do motor único (perfil de
arredondamento por fonte), **não** da soma das linhas — a soma é só exibição.

```json
{ "composicao":{"id":15666,"fonte":"FDE","codigo":"09.08.038","descricao":"…","unidade":"un"},
  "contexto":{"edicao":58,"uf":"SP","modalidade":"SD"},
  "edicoes_disponiveis":[…], "modalidades_disponiveis":["SD","SE"],
  "total":276.14, "incompleto":false,
  "itens":[{"tipo":"INSUMO","codigo":"1.01.15","descricao":"…","unidade":"H",
            "coef":3.1,"valor":29.01,"total":89.93}],
  "ctc":{"disponivel":true} }
```

`modalidades_disponiveis` traz só o que a fonte **publica** — não se oferece regime que ela
não tem, para não sugerir recálculo que não acontece.

### `GET /v0/insumos/{id}`
`edicao` · `uf`

```json
{ "insumo":{"id":9288,"fonte":"FDE","codigo":"1.01.39","descricao":"PEDREIRO","unidade":"H",
            "tipo":"MO","tipo_nome":"Mão de obra"},
  "contexto":{"edicao":58,"uf":"SP"},
  "precos":{"se":12.64,"sd":28.06,"cd":null}, "sem_preco":false,
  "precos_por_uf":[{"uf":"SP","se":12.64,"sd":28.06,"cd":null}],
  "edicoes_disponiveis":[…] }
```

`SE` é o pelado. `SD`/`CD` só diferem de `SE` em **mão de obra** — em material e equipamento
os três são iguais, e isso é fidelidade à fonte, não simplificação. `cd: null` significa que
a fonte não publica desonerado.

### `GET /v0/composicoes/{id}/ufs`
Custo do item em todas as UFs registradas. `modalidade`.

---

## Histórico e análise

### `GET /v0/composicoes/{id}/historico` · `GET /v0/insumos/{id}/historico`
`uf` · `inicio` · `fim` (AAAA-MM)

```json
{ "composicao":{…}, "uf":"SP",
  "periodo":{"inicio":"2024-01","fim":"2026-06","min":"2019-07","max":"2026-06"},
  "labels":["jan/24","fev/24"],
  "series":{"SD":[251.10,253.44],"CD":[null,null]},
  "indices":{"IPCA":[251.10,252.80],"INCC-M":[…]},
  "indices_meta":[{"codigo":"IPCA","nome":"…","fonte":"IBGE"}],
  "custos":[{"mes":"ago/26","SD":276.19,"CD":null}],
  "eventos":[{"edicao":"08/2026","tipo":"ALTERACAO_COEFICIENTE","ocorrencia":"…"}] }
```

> **Os índices vêm PROJETADOS EM R$**, ancorados no primeiro custo real (`p0 × i / i0`). O
> banco guarda número-índice base 100, que não sobrepõe a uma série de reais. A projeção
> fica no servidor porque, se o app ancorasse de um jeito e o Easy Web de outro, o mesmo
> item mostraria dois gráficos diferentes.

Índices do gráfico: **IGP-M, INCC-M, INPC, IPCA** e **IPOP-IGE** (só quando `uf=SP`).

### `GET /v0/composicoes/{id}/analise`
`uf` · `modalidade` · `inicio` · `fim`

**Texto padronizado**, sem requisição a IA. Comenta a variação do período e a aderência de
cada índice à trajetória real do custo.

Índices da análise: **IGP-M, INCC-M, INPC, IPCA, SELIC**. Os outros 24 do catálogo ficam
para o Easy Web.

Série com menos de dois meses apurados devolve `{"analise":{"erro":"…"}}` — e isso é
resposta, não falha.

---

## Conversão e simulação

### `GET /v0/composicoes/{id}/conversao`
`edicao` · `uf` · `modalidade` (`SD|CD`) · `bdi`

Conversão de regime **horista → mensalista** sobre a fonte-base, sem depender de ativo nem
de orçamento. É a mesma que a tela de conversão do Easy Web mostra.

```json
{ "composicao":{…},
  "contexto":{"edicao":58,"uf":"SP","modalidade":"SD","bdi_pct":25},
  "converteu":true, "incompleto":false, "sem_mapeamento":false, "raiz_sem_par":false,
  "original":  {"total":180.86,"total_com_bdi":226.08},
  "convertido":{"total":151.32,"total_com_bdi":189.15},
  "diferenca":-29.54, "diferenca_pct":-16.33,
  "itens":[{"tipo":"COMPOSICAO","codigo":"101452","descricao":"SERVENTE DE OBRAS…",
            "unidade":"MES","coef":0.00527,"estado":"convertido","fator":220.0,
            "origem":{"codigo":"88316","descricao":"SERVENTE…","unidade":"H",
                      "coef":1.16,"valor":32.18},
            "filhos":null}],
  "auxiliares":[…] }
```

Cada linha convertida traz **`origem`** (o insumo horista que saiu), **`fator`** (a jornada
mensal aplicada) e **`filhos`** (auxiliares) — é o que permite ao app montar o PDF
localmente.

`SE` não entra: é justamente a LS que diferencia horista de mensalista, então comparar sem
encargo não teria sentido.

Item sem par mensalista fica **sinalizado** (`sem_mapeamento`, `raiz_sem_par`) em vez de
sumir. Obra pública não admite número que esconde o que não foi convertido.

### `GET /v0/composicoes/{id}/simular`
`edicao` · `uf` · `modalidade` · `ls` (%) · `bdi` (%)

"Quanto ficaria este serviço com os meus dados?" Devolve original e simulado lado a lado —
sem o original ao lado, o simulado não diz nada.

```json
{ "composicao":{…}, "contexto":{"edicao":58,"uf":"SP","modalidade":"SD"},
  "original":{"total":180.86,"ls_pct":{"horista":115.01,"mensalista":71.18}},
  "simulacao":{"ls_pct":71.18,"bdi_pct":25,"total_sem_bdi":161.22,"total":201.53},
  "diferenca":20.67, "diferenca_pct":11.43, "incompleto":false }
```

`ls` sobrescreve a LS da fonte e vale para **toda** a mão de obra da composição.

> **Alavancas que NÃO existem, e por quê — nenhuma é pendência:**
>
> **preço de insumo** — fora de escopo por decisão de 21/08/2026: não teria uso em escala.
> Seria viável tecnicamente, mas mexeria no motor que a bancada usa em produção para
> atender caso raro.
>
> **fonte-destino** — depende das tabelas de equivalência, que continuam fora do GRANT
> (§5.1). Habilitar é decisão comercial, não técnica.
>
> **regime dentro do `/simular`** — use `/conversao`, que converte de verdade. Trocar o
> percentual de LS **não** converte regime: o motor aplica `ls_h` aos horistas e `ls_m` aos
> mensalistas, então mexer só num deles devolveria o mesmo total — número plausível e
> errado, que é pior que ausência.

---

## Documentos

### `GET /v0/composicoes/{id}/ctc`
`edicao` — resolve a versão vigente **à época**, não a mais recente.

```json
{ "disponivel": true,
  "conteudo": "1) Forma de medição\\n...",
  "formato": "markdown" }
```

Sem CTC: `{"disponivel": false, "motivo": "Não existe caderno técnico para este serviço."}`

**Rota separada do detalhe e nunca cacheada** (`no-store`). O Markdown privado é entregue na
resposta autenticada para que o mesmo fluxo funcione no Flutter Web, iOS e Android, sem depender
de CORS do bucket. O app deve pedi-lo na hora de abrir e não o guardar.

O documento é o **CTC** — Caderno Técnico de Composição, produção da Axys, em Markdown:

```
1) Forma de medição      ← o app monta
2) Descritivo do que remunera  ← o app monta
3) Composição            ← IGNORAR: já vem estruturado e com preço em /v0/composicoes/{id}
```

O caderno e as fichas **da fonte** (HTML de CDHU/SINAPI/FDE) **não são expostos ao mobile**.

---

## Índices

### `GET /v0/indices` · `GET /v0/indices/{codigo}`
Lista (29 índices, código · nome · fonte) e série completa de um índice — tabela e arrays
cronológicos para o gráfico. Alimenta o grupo "Índices Inflacionários" da Base de
Conhecimento.

Índice é **dado**, não conteúdo editorial: vem do banco, não de manifesto no R2.

---

## Saúde

`GET /health` — liveness; **não toca o banco** (health dependente de banco vira alarme falso).
`GET /health/db` — readiness; confirma a credencial: serviço de leitura conectado como
`axys_tec` é falha de configuração, não detalhe.
