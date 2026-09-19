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

- Os três campos são **opcionais**. Item sem eles continua válido.
- Campo vazio não é publicado — ou existe com valor, ou não aparece no JSON.
- Nenhum campo existente mudou de nome, tipo ou significado.
- O grupo `DOWNLOADS` passou a ser destino válido de `referencias`. Antes nenhum conteúdo
  referenciava downloads; agora referencia. Se o código de vocês tem uma lista fechada de
  grupos, `DOWNLOADS` precisa entrar nela — **este é o único ponto que pode gerar erro**
  do lado do site.

## Contrato

A especificação completa e canônica está em:
`docs/projects/axys-easy/modules/easy-mobile/conteudos_json_r2.md`

Seções relevantes: `referencias — link tipado, não URL solta` e
`downloads/_manifest.json — não parte`.

Dúvida ou divergência, falem com o time do Easy Mobile antes de contornar — campo do
contrato interpretado de dois jeitos é como as duas pontas divergem sem ninguém notar.
