# JSON do Easy Mobile — três campos novos

**Para:** time do Axys Hub
**De:** time do Easy Mobile
**Data:** 19/09/2026
**Assunto:** campos acrescentados aos manifestos publicados no R2, que o site consome

---

## Resumo

Publicamos hoje a nova cartilha do TCU (*Engenharia de Custos em Obras Públicas — Guia de
perguntas e respostas*, 2026) na Base de Conhecimento. Para fazer isso direito, três campos
entraram nos JSON que vocês já leem.

**Nada quebra.** Os três são aditivos e opcionais: quem não os conhece ignora e continua
funcionando exatamente como antes. Este documento existe para vocês decidirem se querem
usá-los, não porque haja urgência de mudar algo.

---

## 1. `licenca` — no manifesto de downloads

**Onde:** `easy-mobile/downloads/_manifest.json`, em cada item.

```json
{
  "id": "tcu-engenharia-custos-perguntas-respostas",
  "titulo": "Engenharia de Custos em Obras Públicas · Guia de perguntas e respostas",
  "autoria": "Tribunal de Contas da União",
  "data_documento": "2026",
  "licenca": "Permite-se a reprodução desta publicação, em parte ou no todo, sem alteração do conteúdo, desde que citada a fonte e sem fins comerciais.",
  "arquivo": "easy-mobile/downloads/tcu-engenharia-custos-perguntas-respostas.pdf",
  "bytes": 4105553
}
```

**Por que importa para vocês:** esse texto é o aviso impresso na folha de rosto da
publicação. A permissão de redistribuir é **condicionada** a citar a fonte. Como o site
serve o PDF para o público, a citação precisa aparecer onde o documento é oferecido —
não é cortesia editorial, é a condição que nos autoriza a hospedá-lo.

O campo é opcional e só aparece em quem tem aviso de reprodução. Hoje: as duas publicações
do TCU. As do IBRAOP vêm sem, porque não localizamos aviso equivalente nelas.

---

## 2. `fonte` — no manifesto de downloads

```json
"fonte": {
  "pagina":  "https://portal.tcu.gov.br/publicacoes-institucionais/cartilha-manual-ou-tutorial/cartilha-engenharia-de-custos-de-obras-publicas-perguntas-e-respostas",
  "arquivo": "https://portal.tcu.gov.br/uploads/cartilha_engenharia_custos_obras_publicas_perguntas_respostas_eb964dd641.pdf"
}
```

- `pagina` — a página de chamada no portal do órgão
- `arquivo` — o PDF no servidor do órgão

**Serve a dois propósitos.** Para o leitor, é a prova de que não alteramos nada: quem
desconfiar vai à origem e compara. Para SEO, é um link de saída para domínio `gov.br` no
contexto certo, que sinaliza procedência do conteúdo.

Também opcional.

---

## 3. `pagina` — dentro de `referencias`

Este é o que provavelmente interessa mais a vocês.

**Onde:** em qualquer `referencias` da Base de Conhecimento (terminologia, dúvidas, casos,
acórdãos, artigos), quando a referência aponta para `grupo: "DOWNLOADS"`.

```json
"referencias": [
  { "tipo": "publicacao", "grupo": "ACORDAOS", "id": "tcu-2622-2013",
    "rotulo": "Acórdão TCU 2622/2013 — BDI, Simples Nacional e administração local" },

  { "tipo": "publicacao", "grupo": "DOWNLOADS",
    "id": "tcu-engenharia-custos-perguntas-respostas", "pagina": 40,
    "rotulo": "Cartilha TCU 2026 · BDI e preço de venda" }
]
```

Já está no ar, no verbete `bdi`:
`https://public.axys-tec.com.br/easy-mobile/terminologia/_manifest.json`

### Como montar o link

A URL **não** está guardada no JSON, de propósito. Vocês a montam em três passos:

1. procurar `id` no `downloads/_manifest.json` e pegar o campo `arquivo`
2. prefixar com a base pública
3. anexar `#page={pagina}`

Resultando em:

```
https://public.axys-tec.com.br/easy-mobile/downloads/tcu-engenharia-custos-perguntas-respostas.pdf#page=40
```

O visualizador de PDF nativo dos navegadores entende `#page=` e abre direto na página.
Não precisa de biblioteca.

**Por que não guardamos a URL pronta:** ela seria o mesmo caminho determinístico replicado
em dezenas de verbetes. Esta cartilha mudou de nome no dia em que entrou — de
`cartilha_..._eb964dd641.pdf` para `tcu-engenharia-custos-perguntas-respostas.pdf`. Com URL
fixa em cada referência, todas teriam quebrado de uma vez, em silêncio.

### Uma armadilha, medida

**`pagina` é a página do PDF, não a impressa no papel.** São números diferentes, e o
`#page=` conta a do PDF.

Nesta cartilha o sumário diz que o capítulo de BDI está na "p. 31". No arquivo, ele é a
**página 40**. O miolo inteiro está deslocado em 9 — mas a bibliografia está em 8, e o
sumário em 0. **Não existe fórmula de conversão.**

Se em algum momento vocês forem gerar `pagina` do lado de vocês, a página precisa ser
localizada no texto extraído do PDF, nunca calculada a partir do sumário. Convertido por
aritmética, o link aponta para o lugar errado sem dar erro nenhum.

Do nosso lado usamos `z_scripts_apoio/genericos/pdf_para_markdown.py`, que extrai o PDF
marcando cada página com `<!-- p.N -->`.

---

## 4. `colegiado`, `relator` e `sumario_oficial` — nas fichas de acórdão

**Onde:** `easy-mobile/acordaos/{id}/conteudo.json`.

```json
{
  "id": "tcu-1182-2025",
  "orgao": "TCU",
  "numero": "1182/2025",
  "data": "2025-05-28",
  "colegiado": "Plenário",
  "relator": "Benjamin Zymler",
  "sumario_oficial": "RELATÓRIO DE AUDITORIA. FISCOBRAS/2025. CONSTRUÇÃO DO ARCO METROPOLITANO DE MACEIÓ/AL - BR-424/AL. […]",
  "tese_md": "…",
  "aplicacao_pratica_md": "…"
}
```

Os três vêm da base pública de jurisprudência do TCU, **sem uma palavra nossa**.
`sumario_oficial` é o sumário do Tribunal reproduzido como ele é.

**Por que separamos:** quem lê uma ficha precisa distinguir o que o TCU decidiu do que nós
explicamos. `sumario_oficial` é citação; `tese_md`, `aplicacao_pratica_md` e `limites_md`
são redação nossa. Misturar as duas vozes num campo só é como paráfrase vira citação.

Se vocês exibem acórdãos no site, vale renderizar `sumario_oficial` com marcação de
citação, visualmente distinta do texto autoral. Para SEO é conteúdo verificável contra a
fonte primária.

**Os três são opcionais.** Ausente quer dizer "não obtivemos", nunca "não existe".

### Atenção: valores de `data` vão MUDAR em fichas já publicadas

Estamos padronizando `data` na **data da sessão**, que é a identidade que o TCU usa. Parte
das fichas antigas trazia outra data, provavelmente a de publicação. Exemplo confirmado: o
Acórdão 2622/2013 estava como `2013-10-02` e a sessão foi em `2013-09-25`.

Se algo do lado de vocês usa `data` como chave de cache, âncora de URL, ordenação estável
ou `datePublished` no schema.org, esses valores mudam na próxima publicação. É o único
ponto desta leva que altera dado existente em vez de acrescentar campo.

---

## 5. Terminologia passou a citar PDF, o que antes não acontecia

Vale destacar porque é **comportamento novo**, não apenas campo novo.

Até agora, `referencias` da terminologia apontavam só para conteúdo interno da Base de
Conhecimento (outro verbete, um acórdão, uma dúvida). Agora um verbete pode referenciar um
**documento em PDF** do grupo `DOWNLOADS`, numa **página específica**.

Na prática, o site passa a precisar de um caminho que provavelmente não existe hoje: do
verbete para o PDF, ancorado. Se a renderização atual de `referencias` assume que todo
alvo é uma página de conteúdo, ela vai gerar link quebrado ou simplesmente ignorar a
referência.

---

## O que sugerimos avaliar

Nenhum destes é pedido — é o que nós faríamos, e vocês conhecem o site melhor.

1. **Exibir `licenca`** junto ao botão de download da cartilha. É o item com maior peso: é
   condição de uso, não enfeite.
2. **Exibir `fonte.pagina`** como "Publicação original no portal do TCU".
3. **Transformar referência com `pagina` em link direto.** Hoje, se o site renderiza
   `referencias`, uma referência a DOWNLOADS provavelmente vira link para o PDF inteiro.
   Acrescentar `#page=` é mudança de uma linha e melhora muito a citação.
4. **SEO:** um verbete que cita "cartilha do TCU 2026, p. 40" com link ancorado é conteúdo
   com procedência verificável. Vale considerar `citation`/`isBasedOn` no schema.org dos
   verbetes, se vocês já marcam essas páginas.

---

## Compatibilidade

**Aditivo, e portanto seguro:**

- Todos os campos novos (`licenca`, `fonte`, `pagina`, `colegiado`, `relator`,
  `sumario_oficial`) são **opcionais**. Item sem eles continua válido.
- Campo vazio não é publicado. Ou existe com valor, ou não aparece no JSON.
- Nenhum campo existente mudou de nome ou de tipo.

**Os dois pontos que exigem ação de vocês:**

1. **`DOWNLOADS` virou destino válido de `referencias`.** Antes nenhum conteúdo
   referenciava downloads; agora terminologia e acórdãos referenciam. Se o código tem lista
   fechada de grupos, ela precisa aceitar `DOWNLOADS`, e a renderização precisa saber que o
   alvo é um PDF e não uma página de conteúdo.
2. **Valores de `data` em fichas de acórdão vão mudar**, com a padronização na data de
   sessão (ver seção 4). É a única alteração de dado existente nesta leva.

## Contrato

A especificação completa e canônica está em:
`docs/projects/axys-easy/modules/easy-mobile/conteudos_json_r2.md`

Seções relevantes: `referencias — link tipado, não URL solta` e
`downloads/_manifest.json — não parte`.

Dúvida ou divergência, falem com o time do Easy Mobile antes de contornar — campo do
contrato interpretado de dois jeitos é como as duas pontas divergem sem ninguém notar.
