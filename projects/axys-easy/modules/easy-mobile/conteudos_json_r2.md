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

## Fonte, validação e publicação

**A fonte é versionada; o R2 é o resultado.**

``` text
docs/projects/axys-easy/modules/easy-mobile/v0_docs/   ← FONTE (git, com histórico)
   ↓  valida_conteudo_mobile.py                        ← PORTÃO
public.axys-tec.com.br/easy-mobile/                    ← PUBLICADO (sem histórico)
```

O bucket não versiona, e já houve exclusão acidental de bucket neste projeto. Editar
direto no R2 é perder o trabalho na primeira distração.

### O portão

```
python3 z_scripts_apoio/valida_conteudo_mobile.py
```

Roda sobre a **fonte**, antes de publicar — validar o R2 depois seria tarde, o conteúdo
já estaria servindo. Sai com `1` se houver erro, então serve para travar a publicação.

**ERRO bloqueia:** campo ausente ou não previsto, `id` diferente do slug do termo, `id`
duplicado, item no manifesto sem pasta ou pasta sem item, vínculo apontando para id
inexistente, campo `_md` vazio, uso de `vinculados` no lugar de `referencias`, assuntos
divergindo entre manifesto e conteúdo, e **colisão inequívoca de vocabulário** — plural
(`insumos` × `insumo`) ou grafia quase idêntica.

**AVISO não bloqueia:** assunto sem verbete que não é colisão, assunto **vizinho** de um
verbete, travessão no texto, expressão burocrática e monotonia de molde nas distinções.

### Por que o portão existe

O vocabulário rachou **duas vezes seguidas**, em lotes diferentes e do mesmo jeito:
`aditivos` convivendo com o verbete `aditivo-contratual`, `canteiro` com
`canteiro-de-obras`, `limite` com `limites`. Não é descuido de quem escreve — é que nada
barrava antes de publicar. Etiqueta rachada quebra o agrupamento no aplicativo e esvazia
as `referencias`, que são o que transforma três listas soltas numa teia.

Na primeira execução ele pegou o que a revisão manual deixou passar (`equipamentos` ×
`equipamento`, `insumos` × `insumo`) e, depois, dois erros de quem o escreveu: um verbete
criado com `id` fora do slug e os vínculos que ficaram apontando para o id antigo.

### Duas regras de vocabulário que só apareceram no uso

**Assunto usado em dois ou mais documentos não é cauda longa — é conceito faltando no
glossário.** Foi essa régua que gerou os verbetes de `orcamento`, `preco-global`,
`edital`, `regime-de-execucao`, `contrato-verbal` e `atraso`: todos vieram do uso real,
nenhum de brainstorm. Assunto usado uma vez só (`insalubridade`, `frete`, `quimica`) fica
como está — forçar verbete para etiqueta ocasional incha o glossário sem servir ninguém.

**Gênero e espécie não são colisão.** `orcamento` e `orcamento-analitico` compartilham o
prefixo e **devem coexistir**; já `reequilibrio` e `reequilibrio-economico-financeiro` são
o mesmo conceito abreviado. Máquina não separa os dois casos, e por isso vizinhança por
prefixo é aviso, não erro: quem decide é quem escreve.

---

## A regra de partição

Como quebrar o conteúdo em arquivos não é gosto, é padrão de uso:

| Natureza | Corte | Por quê |
|---|---|---|
| **Longo, lido um por vez** — newsletter, artigo, **caso prático**, **acórdão** | **um arquivo por item** | o usuário procura *aquele* e lê; baixar os outros seria desperdício |
| **Curto e navegável** — **dúvidas rápidas** | **um arquivo por categoria** | ele abre várias seguidas, e busca no texto tem de funcionar sem rede |
| **Consulta pontual e curtíssima** — **terminologia** | **não parte** | é dicionário: ninguém lê um verbete só, e busca tem de varrer tudo |
| **Lista de arquivo** — downloads | **não parte** | o item já é só metadado; o binário é arquivo à parte por natureza |
| **Documento único** — institucional | **um arquivo por documento** | não tem edições |

Partir dúvida *por pergunta* seria o erro clássico: cada pergunta aberta viraria uma
requisição, e buscar no texto exigiria baixar tudo item a item.

Caso prático e acórdão vão pelo caminho oposto — **um arquivo cada** — porque são longos,
estruturados, e o usuário chega neles procurando **um** assunto específico.

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
├── terminologia/_manifest.json         dicionário inteiro, não parte
├── downloads/
│   ├── _manifest.json
│   └── planilha-orcamentaria-inteligente/v2.xlsx
├── duvidas/
│   ├── _manifest.json                  só as categorias
│   ├── bdi.json                         o assunto inteiro
│   ├── sinapi.json
│   ├── orcamento.json
│   └── aditivos.json
├── casos/
│   ├── _manifest.json
│   └── andaime-aditivo-fora-da-planilha/conteudo.json
├── acordaos/
│   ├── _manifest.json
│   └── tcu-2622-2013/conteudo.json
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

## Base de Conhecimento — quatro seções, quatro perguntas

A Base de Conhecimento não é um balaio de textos. Cada seção responde a **uma pergunta
diferente**, e por isso tem estrutura editorial própria. Misturar as quatro num formato só
seria cômodo para quem publica e ruim para quem consulta.

| Seção | Responde | Corte | Exemplo |
|---|---|---|---|
| **Terminologia** | "O que significa?" | não parte | O que é BDI? |
| **Dúvidas rápidas** | "Como funciona / como faço?" | por assunto | Como converter encargos de horista para mensalista? |
| **Casos práticos** | "O que fazer nesta situação?" | por item | Posso incluir andaime por aditivo se não estava na planilha? |
| **Acórdãos** | "Qual é o entendimento e seu fundamento?" | por item | O que o Acórdão 2.622/2013 estabelece sobre BDI? |

---

## `terminologia/_manifest.json` — dicionário, não parte

Verbete objetivo. **Ninguém lê um verbete só**, e a busca precisa varrer tudo — por isso o
arquivo é único.

```json
{
  "grupo": "TERMINOLOGIA",
  "gerado_em": "2026-08-21T14:30:00Z",
  "itens": [
    {
      "id": "bdi",
      "termo": "BDI",
      "expansao": "Benefícios e Despesas Indiretas",
      "conceito_md": "Percentual aplicado sobre o custo direto para remunerar despesas indiretas, tributos, riscos e lucro.",
      "funcao_pratica_md": "É o que transforma **custo** em **preço**. Sem BDI, a planilha mostra quanto a obra custa, não por quanto ela pode ser contratada.",
      "distincoes": [
        { "termo": "Custo direto", "diferenca_md": "Custo direto é o que se aplica na obra; o BDI é o que existe **em volta** dela." },
        { "termo": "Encargos sociais", "diferenca_md": "Encargos incidem sobre a mão de obra dentro da composição; o BDI incide sobre o total." }
      ],
      "ver_tambem": ["custo-direto", "administracao-local", "data-base"],
      "referencias": [
        { "tipo": "acordao", "rotulo": "Acórdão TCU 2622/2013", "url": "https://…" }
      ]
    }
  ]
}
```

**`distincoes` é o campo que faz o verbete valer.** Dizer o que BDI *é* qualquer glossário
faz; dizer como ele **se diferencia de custo direto e de encargos** é o que tira a dúvida
que o usuário realmente tem.

Se um dia passar de algumas centenas de verbetes, parte por letra. Não antes.

---

## `duvidas/` — dúvida rápida, partido por assunto

Pergunta de resposta relativamente geral, que não depende do contrato concreto. Entre
**150 e 350 palavras**.

### `duvidas/_manifest.json`

```json
{
  "grupo": "DUVIDAS",
  "gerado_em": "2026-08-21T14:30:00Z",
  "assuntos": [
    { "id": "bdi",       "titulo": "BDI",       "qtd": 3, "arquivo": "easy-mobile/duvidas/bdi.json" },
    { "id": "encargos",  "titulo": "Encargos",  "qtd": 5, "arquivo": "easy-mobile/duvidas/encargos.json" },
    { "id": "orcamento", "titulo": "Orçamento", "qtd": 4, "arquivo": "easy-mobile/duvidas/orcamento.json" }
  ]
}
```

`qtd` deixa a MAIN escrever "BDI · 3 dúvidas" sem baixar nada.

### `duvidas/{assunto}.json`

```json
{
  "assunto": "encargos",
  "titulo": "Encargos",
  "gerado_em": "2026-08-21T14:30:00Z",
  "itens": [
    {
      "id": "converter-horista-mensalista",
      "pergunta": "Como converter encargos de horista para mensalista?",
      "resposta_direta": "Substituindo a composição de mão de obra horista pela equivalente mensalista e dividindo o coeficiente pela jornada mensal.",
      "explicacao_md": "A conversão não é aplicar outro percentual de LS…",
      "exemplo_md": "Coeficiente 1,16 H ÷ 220 h/mês = **0,00527 mês**.",
      "ressalva_md": "Só faz sentido em obra de médio ou longo prazo, com mão de obra própria…",
      "referencias": [
        { "tipo": "composicao", "rotulo": "Ver no simulador", "fonte": "SINAPI", "codigo": "103335" }
      ],
      "publicado_em": "2026-08-15",
      "atualizado_em": null
    }
  ]
}
```

**`resposta_direta` é campo separado, e vem primeiro**, porque a resposta tem de aparecer
antes da explicação. É também o que a lista mostra como prévia — quem está no canteiro
resolve a dúvida sem abrir.

**`ressalva_md` é obrigatória quando existe ressalva.** Resposta técnica sem limite vira
receita aplicada onde não cabe.

---

## `casos/` — caso prático, um arquivo por caso

Parte de uma **situação concreta** e depende de condicionantes. **Aqui não se responde só
"sim" ou "não"**: regime de execução, matriz de riscos, edital, contrato, natureza da
alteração e documentação podem mudar a conclusão.

### `casos/_manifest.json`

```json
{
  "grupo": "CASOS",
  "gerado_em": "2026-08-21T14:30:00Z",
  "itens": [
    {
      "id": "andaime-aditivo-fora-da-planilha",
      "titulo": "Andaime não previsto na planilha contratual",
      "chamada": "Depende do regime de execução e de a que título o andaime foi omitido.",
      "assuntos": ["aditivos", "epu"],
      "conteudo": "easy-mobile/casos/andaime-aditivo-fora-da-planilha/conteudo.json",
      "publicado_em": "2026-08-15"
    }
  ]
}
```

A `chamada` de um caso **já anuncia que a resposta é condicionada** — evita que a lista
sugira um "sim" que o texto não dá.

### `casos/{id}/conteudo.json`

```json
{
  "id": "andaime-aditivo-fora-da-planilha",
  "titulo": "Andaime não previsto na planilha contratual",
  "assuntos": ["aditivo-contratual", "empreitada-por-preco-unitario"],
  "publicado_em": "2026-08-15",
  "situacao_md": "A planilha contratual não previu andaime fachadeiro. A execução da fachada exige…",
  "resposta_curta": "Pode ser possível, mas depende do regime de execução e de a quem se atribui a omissão.",
  "condicionantes": ["Regime de execução", "Matriz de riscos", "Edital", "Contrato", "Natureza da alteração", "Documentação"],
  "verificar": [
    "Qual o regime de execução (EPU, empreitada global, integrada)?",
    "A matriz de riscos atribui a omissão a qual parte?",
    "O andaime é meio de execução de serviço já contratado ou serviço autônomo?",
    "Há projeto ou memorial que já previa a necessidade?"
  ],
  "fundamento_md": "Em Empreitada por Preços Unitários, o objeto é o serviço medido…",
  "procedimento": [
    "Levantar o que o edital e o contrato dizem sobre o item.",
    "Verificar a matriz de riscos e a quem cabe a omissão.",
    "Instruir o processo com justificativa técnica e memória de cálculo.",
    "Submeter à autoridade competente antes da execução."
  ],
  "riscos_md": "Executar antes de formalizar transfere o risco integralmente ao contratado…",
  "referencias": [
    { "tipo": "acordao", "rotulo": "Acórdão TCU …", "url": "https://…" },
    { "tipo": "publicacao", "rotulo": "Dúvida: quando cabe aditivo", "grupo": "DUVIDAS", "id": "quando-cabe-aditivo" }
  ]
}
```

**`condicionantes` é lista estruturada, não parágrafo.** O app mostra como etiquetas no
topo — o leitor vê **antes de ler** que a resposta depende de seis coisas. É a defesa
contra a leitura preguiçosa que transforma "depende" em "pode".

**`verificar` vem antes de `fundamento`**, de propósito: quem chega com a situação na mão
precisa primeiro saber o que olhar, não a teoria.

---

## `acordaos/` — ficha técnica, um arquivo por acórdão

**Não é pasta de PDF.** O valor da Axys está na **tradução prática do entendimento** — o
PDF oficial qualquer um acha.

### `acordaos/_manifest.json`

```json
{
  "grupo": "ACORDAOS",
  "gerado_em": "2026-08-21T14:30:00Z",
  "itens": [
    {
      "id": "tcu-2622-2013",
      "orgao": "TCU",
      "numero": "2622/2013",
      "data": "2013-10-02",
      "titulo": "Acórdão TCU 2622/2013 — BDI e encargos sociais",
      "assuntos": ["bdi", "encargos"],
      "tese_curta": "Fixa faixas referenciais de BDI por tipo de obra e veda a inclusão de determinados itens.",
      "conteudo": "easy-mobile/acordaos/tcu-2622-2013/conteudo.json"
    }
  ]
}
```

### `acordaos/{id}/conteudo.json`

```json
{
  "id": "tcu-2622-2013",
  "orgao": "TCU",
  "numero": "2622/2013",
  "data": "2013-10-02",
  "assuntos": ["bdi", "encargos"],
  "tese_md": "Em linguagem simples: o Tribunal fixou faixas referenciais de BDI por tipo de obra…",
  "aplicacao_pratica_md": "Na prática, ao montar o BDI de uma obra de edificação você compara…",
  "limites_md": "O entendimento vale para obras públicas federais e é **referencial, não camisa de força**: BDI fora da faixa é admissível quando justificado…",
  "dispositivos": ["Lei 8.666/1993, art. 7º", "IN nº …"],
  "referencias": [
    { "tipo": "publicacao", "rotulo": "BDI", "grupo": "TERMINOLOGIA", "id": "bdi" },
    { "tipo": "publicacao", "rotulo": "BDI diferenciado para equipamentos", "grupo": "DUVIDAS", "id": "bdi-diferenciado-equipamentos" }
  ],
  "pdf": null,
  "publicado_em": "2026-08-15"
}
```

**`assuntos` é VOCABULÁRIO CONTROLADO, não etiqueta livre.** Todo assunto que também for
conceito deve usar o **id do verbete** da terminologia. Sem essa disciplina o vocabulário
racha: na primeira leva de 30 acórdãos apareceram `limite` e `limites` como etiquetas
distintas, e `aditivo` convivendo com o verbete `aditivo-contratual`. Etiqueta rachada
quebra o agrupamento no app e esvazia o `vinculados`.

**`referencias` é o que transforma três listas em uma teia.** Um acórdão sobre BDI aponta
para o verbete BDI; o verbete pode listar os acórdãos que o citam. Preencher é mecânico
quando o vocabulário é controlado — e impossível quando não é.

**`limites_md` é o campo que separa a ficha de um resumo qualquer.** Dizer o que o acórdão
estabelece é metade; dizer **até onde ele vale** é o que evita que o leitor aplique um
entendimento fora do escopo — que é como a maioria dos erros acontece.

**Não se guarda link para a fonte oficial** (decisão de 22/08/2026). O TCU não expõe
permalink construível, e o que sobra são URLs de dentro do app de busca deles, com
codificação tripla, que apodrecem em meses — na primeira leva, 8 de 30 apontavam para
*ata de sessão* ou *informativo*, não para o acórdão. Link errado é pior que link ausente.

**`orgao` + `numero` já identificam o documento**, e é isso que basta: o aplicativo monta
a busca no momento do toque, a partir de campos que já tem. Nada armazenado, nada a
apodrecer. `pdf` continua opcional, para quando houver arquivo sob controle da Axys.

**Regra editorial das quatro seções:** quando existir fonte normativa, **cite-a**. É o que
separa "opinião de um engenheiro experiente" de conhecimento Axys verificável — e é a
*confiança irrefutável* do objetivo secundário do projeto.

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
| `publicacao` | `grupo`, `id` | abre outro conteúdo (`TERMINOLOGIA`, `DUVIDAS`, `CASOS`, `ACORDAOS`, `NEWSLETTER`, `ARTIGOS`) |
| `acordao` · `url` | `url` | abre fora do app |

**O campo se chama `referencias` em TODA a Base de Conhecimento** — terminologia, dúvidas,
casos e acórdãos. Houve uma versão em que os acórdãos usavam `vinculados`; foi unificado em
22/08/2026. Dois nomes para a mesma coisa obrigariam o app a tratar dois campos idênticos.

**Rótulo de acórdão é sempre `Acórdão {orgao} {numero}`**, sem cauda descritiva. O título e a
tese o app busca na própria ficha — repetir no rótulo cria duas versões da mesma descrição,
que divergem na primeira edição.

**Vínculo automático não se soma a curadoria humana.** Quando o conteúdo já traz acórdãos
escolhidos a dedo, o preenchimento automático não acrescenta: escolha de quem escreveu vale
mais que sobreposição de etiqueta. Onde não há curadoria, o automático entra com **no máximo
dois** e só com sobreposição real de assunto.

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
