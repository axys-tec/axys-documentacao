# Easy Mobile — formato dos conteúdos no R2

**Base:** `https://public.axys-tec.com.br/easy-mobile/`
**Governado por:** `projeto.md` → *Infraestrutura de Conteúdo* · **Irmão:** `endpoints_json_api.md`

Este documento descreve **o que é publicado no bucket público** e como cada arquivo é
formado. A API não participa: o app lê direto da CDN.

---

## Regras que valem para tudo

**Nada disso passa pela API.** Conteúdo publicado é estático — a CDN entrega sem acordar
servidor, sem custo de banda e sem token.

**Path em slug ASCII, minúsculo, com hífen.** `duvidas/`, não `dúvidas/`; `estaca-helice`,
não `estaca hélice`. Acento em URL vira `%C3%BA`, quebra copiar-e-colar e cada cliente
codifica de um jeito. Rótulo de tela é outra coisa: lá continua "Dúvidas & Perguntas".

**O app usa sempre o path que vem no manifesto**, nunca monta o caminho por conta. Se a
convenção mudar, o manifesto absorve; um binário publicado na loja, não.

**Rascunho não mora aqui.** O bucket é público, e o que sai da CDN não volta. Material em
redação e revisão fica no bucket **privado**; publicar é **mover** e regerar os manifestos.

**Correção ganha path novo.** Nunca se sobrescreve objeto publicado — cache de borda
serviria a versão velha por dias.

**Cache:** manifesto `max-age=300` (é o ponto de descoberta, muda a cada publicação);
objeto de conteúdo é imutável e vive muito mais.

**Todo texto longo é Markdown**, e o campo diz isso no nome (`resposta_md`, `texto_md`) —
para ninguém renderizar como texto puro por engano.

**Datas em ISO.** `"2026-08-15"`, `"2026-08-21T14:30:00Z"`.

---

## A regra de partição

Como quebrar o conteúdo em arquivos não é gosto, é padrão de uso:

| Natureza | Corte | Por quê |
|---|---|---|
| **Longo, lido um por vez** — newsletter, artigo | **um arquivo por item** | o usuário abre um e lê; baixar os outros seria desperdício |
| **Curto e navegável** — dúvidas | **um arquivo por categoria** | ele abre várias seguidas, e busca no texto tem de funcionar sem rede |
| **Lista de arquivo** — downloads | **não parte** | o item já é só metadado; o binário é arquivo à parte por natureza |
| **Documento único** — institucional | **um arquivo por documento** | não tem edições |

Partir dúvida *por pergunta* seria o erro clássico: cada pergunta aberta viraria uma
requisição, e buscar no texto exigiria baixar tudo item a item.

---

## Estrutura

``` text
easy-mobile/
├── _ultimas.json                       agregado da HOME
├── newsletter/
│   ├── _manifest.json
│   └── 2026-08/
│       ├── conteudo.json
│       ├── completo.pdf
│       ├── capa.webp
│       └── assets/grafico-01.webp
├── artigos/
│   ├── _manifest.json
│   └── acordao-tcu-2622-2013/conteudo.json
├── terminologia/_manifest.json
├── downloads/
│   ├── _manifest.json
│   └── planilha-orcamentaria-inteligente/v2.xlsx
├── duvidas/
│   ├── _manifest.json                  só as categorias
│   ├── bdi.json                         o assunto inteiro
│   ├── sinapi.json
│   ├── orcamento.json
│   └── aditivos.json
└── institucional/
    ├── _manifest.json
    ├── solucoes.json
    ├── sobre.json
    └── roadmap.json
```

---

## `_ultimas.json` — a HOME

Alimenta "Últimas publicações" da HOME e da MAIN da Base de Conhecimento. Mistura grupos,
ordenado por data, **3 a 5 itens**. É o que dispensa rota de agregação na API.

```json
{
  "gerado_em": "2026-08-21T14:30:00Z",
  "itens": [
    { "grupo": "NEWSLETTER", "id": "2026-08",
      "titulo": "Easy Newsletter — Agosto/2026",
      "chamada": "SINAPI sobe 0,8% no mês; mão de obra puxa a alta.",
      "publicado_em": "2026-08-10",
      "capa": "easy-mobile/newsletter/2026-08/capa.webp",
      "destino": "easy-mobile/newsletter/2026-08/conteudo.json" }
  ]
}
```

---

## Manifesto de grupo — campos comuns

```json
{
  "grupo": "NEWSLETTER",
  "gerado_em": "2026-08-21T14:30:00Z",
  "itens": [
    { "id": "2026-08",
      "titulo": "Easy Newsletter — Agosto/2026",
      "chamada": "SINAPI sobe 0,8% no mês; mão de obra puxa a alta.",
      "publicado_em": "2026-08-10",
      "assuntos": ["SINAPI", "MAO_DE_OBRA"],
      "capa": "easy-mobile/newsletter/2026-08/capa.webp",
      "conteudo": "easy-mobile/newsletter/2026-08/conteudo.json",
      "pdf": "easy-mobile/newsletter/2026-08/completo.pdf" }
  ]
}
```

**`chamada` é obrigatória.** Sem ela, montar uma lista de três itens obrigaria o app a
baixar três `conteudo.json` inteiros só para ter o que escrever embaixo do título.

---

## `conteudo.json` — newsletter, artigo, institucional

**Blocos tipados, não HTML.** Cada bloco é uma coisa que o Flutter sabe desenhar
nativamente. É isto que permite publicar conteúdo novo **sem versão nova do aplicativo** —
e o que evita WebView.

```json
{
  "id": "2026-08",
  "titulo": "Easy Newsletter — Agosto/2026",
  "subtitulo": "O que mudou nas fontes em agosto",
  "publicado_em": "2026-08-10",
  "capa": "easy-mobile/newsletter/2026-08/capa.webp",
  "blocos": [
    { "tipo": "resumo",  "texto_md": "A SINAPI subiu **0,8%** no mês…" },

    { "tipo": "numeros", "itens": [
        { "rotulo": "Variação SINAPI", "valor": "+0,8%", "tendencia": "alta" },
        { "rotulo": "Acima do INCC-M", "valor": "+0,3 p.p.", "tendencia": "alta" } ] },

    { "tipo": "titulo",  "nivel": 2, "texto": "Mão de obra puxou a alta" },
    { "tipo": "texto",   "texto_md": "O grupo de **mão de obra** respondeu por…" },

    { "tipo": "imagem",  "arquivo": "easy-mobile/newsletter/2026-08/assets/grafico-01.webp",
                         "legenda": "Distribuição da variação por grupo",
                         "largura": 1200, "altura": 675 },

    { "tipo": "tabela",  "titulo": "Maiores altas",
                         "colunas": ["Código", "Descrição", "Variação"],
                         "alinhamento": ["esquerda", "esquerda", "direita"],
                         "linhas": [["88309", "ELETRICISTA", "+2,4%"]] },

    { "tipo": "ranking", "titulo": "Top 5 altas",
                         "itens": [{ "posicao": 1, "rotulo": "ELETRICISTA", "valor": "+2,4%" }] },

    { "tipo": "grafico", "formato": "linha", "titulo": "SINAPI × INCC-M",
                         "labels": ["mai/26", "jun/26", "jul/26"],
                         "series": [{ "nome": "SINAPI", "valores": [100.0, 100.5, 101.3] }] },

    { "tipo": "referencias", "itens": [
        { "tipo": "composicao", "rotulo": "Ver a composição", "fonte": "SINAPI", "codigo": "103335" } ] },

    { "tipo": "cta", "texto": "Quer orçar com esses dados?",
                     "rotulo": "Conhecer o Easy", "destino": "solucoes" }
  ]
}
```

**Tipos de bloco:** `resumo` · `titulo` · `texto` · `numeros` · `imagem` · `tabela` ·
`ranking` · `grafico` · `referencias` · `cta`.

**Regra de ouro — nunca transformar texto em imagem.** Texto, número, ranking, tabela e
gráfico vão como **dados**; imagem é só fotografia e ilustração. Texto em imagem não é
buscável, não é acessível, não se adapta à tela e pesa dez vezes mais.

**`imagem` traz largura e altura** para o app reservar o espaço antes de baixar — sem
isso, o texto pula na tela quando a foto carrega.

---

## `duvidas/` — partido por assunto

### `duvidas/_manifest.json` — só as categorias

```json
{
  "grupo": "DUVIDAS",
  "gerado_em": "2026-08-21T14:30:00Z",
  "assuntos": [
    { "id": "bdi",       "titulo": "BDI",       "qtd": 3, "arquivo": "easy-mobile/duvidas/bdi.json" },
    { "id": "sinapi",    "titulo": "SINAPI",    "qtd": 5, "arquivo": "easy-mobile/duvidas/sinapi.json" },
    { "id": "orcamento", "titulo": "Orçamento", "qtd": 4, "arquivo": "easy-mobile/duvidas/orcamento.json" },
    { "id": "aditivos",  "titulo": "Aditivos",  "qtd": 2, "arquivo": "easy-mobile/duvidas/aditivos.json" }
  ]
}
```

`qtd` deixa a MAIN escrever "BDI · 3 dúvidas" sem baixar nada.

### `duvidas/{assunto}.json` — o assunto inteiro

```json
{
  "assunto": "bdi",
  "titulo": "BDI",
  "gerado_em": "2026-08-21T14:30:00Z",
  "itens": [
    {
      "id": "bdi-diferenciado-equipamentos",
      "pergunta": "Posso aplicar BDI diferenciado sobre fornecimento de equipamentos?",
      "resposta_md": "**Sim, e é a melhor prática.** Na composição do BDI entram parâmetros que se relacionam com a dificuldade de execução e o valor agregado da solução…",
      "referencias": [
        { "tipo": "acordao", "rotulo": "Acórdão TCU 2622/2013", "url": "https://…" }
      ],
      "publicado_em": "2026-08-15",
      "atualizado_em": null
    }
  ]
}
```

**Regra editorial:** quando existir fonte normativa, **cite-a**. É o que separa "opinião de
um engenheiro experiente" de conhecimento Axys verificável — e é a *confiança irrefutável*
do objetivo secundário do projeto.

---

## `referencias` — link tipado, não URL solta

Aparece em dúvidas, artigos e newsletter. **Tipado para o app abrir a tela certa por
dentro**, em vez de jogar o usuário no navegador:

| `tipo` | Campos | O app faz |
|---|---|---|
| `composicao` | `fonte`, `codigo` | abre o detalhamento na Central de Custos |
| `ctc` | `fonte`, `codigo` | abre o caderno técnico |
| `insumo` | `fonte`, `codigo` | abre o detalhe do insumo |
| `indice` | `codigo` | abre a série do índice |
| `publicacao` | `grupo`, `id` | abre outro conteúdo |
| `acordao` · `url` | `url` | abre fora do app |

Referência interna usa **fonte + código**, nunca `id` numérico: o id é interno e pode
mudar num rebuild; o par fonte+código é a identidade estável.

---

## `downloads/_manifest.json` — não parte

```json
{
  "grupo": "DOWNLOADS",
  "gerado_em": "2026-08-21T14:30:00Z",
  "itens": [
    {
      "id": "planilha-orcamentaria-inteligente",
      "titulo": "Planilha Orçamentária Inteligente",
      "chamada": "Modelo com fórmulas de BDI, encargos e curva ABC prontos.",
      "arquivo": "easy-mobile/downloads/planilha-orcamentaria-inteligente/v2.xlsx",
      "formato": "xlsx",
      "tamanho_bytes": 284160,
      "versao": "2.0",
      "requer": "Excel 2016 ou superior",
      "publicado_em": "2026-08-15",
      "capa": null
    }
  ]
}
```

**`tamanho_bytes` e `formato` não são enfeite.** O usuário está no canteiro, em rede
móvel: precisa saber se vai baixar 280 KB ou 40 MB **antes** de tocar. O formato decide o
ícone e se o aparelho abre.

**`versao` e `requer`** existem porque utilitário envelhece — planilha e coletor CAD ganham
versão nova, e o usuário precisa saber qual está levando.

---

## `terminologia/_manifest.json` — inline

Glossário: definição curta, lista plana, busca precisa funcionar sobre tudo.

```json
{
  "grupo": "TERMINOLOGIA",
  "gerado_em": "2026-08-21T14:30:00Z",
  "itens": [
    { "id": "bdi", "termo": "BDI",
      "expansao": "Benefícios e Despesas Indiretas",
      "definicao_md": "Percentual aplicado sobre o custo direto para cobrir…",
      "ver_tambem": ["encargos-sociais", "curva-abc"],
      "referencias": [{ "tipo": "acordao", "rotulo": "Acórdão TCU 2622/2013", "url": "https://…" }] }
  ]
}
```

Se um dia passar de algumas centenas de termos, parte por letra — mesma lógica das
dúvidas. Não antes.

---

## `institucional/` — documento único

`solucoes.json`, `sobre.json` e `roadmap.json`, cada um no formato `conteudo.json`
(blocos tipados). São os textos que hoje moram no binário.

Migrar para cá permite corrigir uma data do Roadmap **sem passar pela revisão da App
Store**, que leva dias — e o Roadmap é justamente a tela onde data errada mais custa
credibilidade.

---

## O que nunca fazer

- Editar arquivo direto no bucket público (rascunho é no privado; publicar é mover).
- Sobrescrever objeto publicado (correção ganha path novo).
- Montar path no app em vez de usar o do manifesto.
- Texto dentro de imagem.
- HTML no lugar de blocos tipados — WebView não é renderização nativa.
- Acento ou espaço em nome de arquivo ou pasta.
- Embutir conteúdo editorial no binário do aplicativo.
