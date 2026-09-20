# O que existe na Base de Conhecimento, lugar por lugar

**Para:** time do Axys Hub
**De:** time do Easy Mobile
**Data:** 20/09/2026

Este documento descreve o conteúdo que o Easy Mobile publica no R2 e que o site consome.
Não é contrato de formato: a especificação dos campos está em `conteudos_json_r2.md`, e onde
os dois divergirem, vale ela.

---

## O caminho do conteúdo

```
docs/.../easy-mobile/v0_docs/   →   R2 (easy-mobile/…)   →   app e axys-tec.com.br
        FONTE, versionada            PUBLICADO                 CONSUMO
```

`v0_docs` é a **fonte versionada**, no repositório `axys-documentacao`. O que está lá é o que
existe; o R2 é cópia publicada dela. Tudo é gerado por script a partir do banco do catálogo
ou escrito à mão em Markdown, nunca editado direto no R2.

A publicação é atômica por rodada: `publica_conteudo_mobile.py` valida a fonte inteira,
recusa publicar se houver erro, e só então sobe. **Manifesto novo apontando para arquivo que
não subiu é pior que não publicar.**

---

## O único endereço fixo

```
https://public.axys-tec.com.br/easy-mobile/_manifest.json
```

É o ponto de descoberta. Ele lista os grupos, com `id`, rótulo, quantidade e **partição**, e
traz a vitrine de últimas publicações. Nada mais precisa ser conhecido de antemão: todos os
outros caminhos saem dele.

A partição diz **como navegar** o grupo, e existe para o cliente não precisar conhecer o nome
de cada um:

| `particao` | O manifesto do grupo… |
|---|---|
| `unico` | já contém todos os itens |
| `assunto` | lista arquivos por assunto, e cada um contém seus itens |
| `item` | lista itens, e cada um tem o seu próprio `conteudo.json` |

---

## Os oito grupos

### `terminologia` — 89 verbetes · partição `unico`

O glossário. Um arquivo só, `_terminologia.json`, na raiz.

Cada verbete traz conceito, função prática, distinções contra termos vizinhos, `ver_tambem`
e `referencias`. É o vocabulário controlado de toda a base: os `assuntos` dos outros grupos
usam o `id` do verbete, e não etiqueta livre. Sem essa disciplina o agrupamento racha.

### `duvidas` — 30 dúvidas em 5 assuntos · partição `assunto`

Pergunta curta com resposta direta. O manifesto lista os assuntos (`bdi`, `composicoes`,
`encargos`, `orcamento-e-contratos`, `referencias-de-precos`), e cada arquivo de assunto traz
6 dúvidas.

Atenção ao contar: o `_manifest.json` deste grupo **não tem** `itens`, tem `assuntos`. Quem
espera a mesma forma dos outros lê zero.

### `casos` — 16 casos · partição `item`

Situação concreta de obra e o que fazer com ela. Um `conteudo.json` por caso, com a situação,
a resposta curta e o desenvolvimento.

### `acordaos` — 187 fichas · partição `item`

Jurisprudência do TCU. Cada ficha tem duas camadas, e a distinção importa para a
renderização:

- **do Tribunal**, reproduzido: `numero`, `data` (data da sessão), `colegiado`, `relator`,
  `sumario_oficial` e `pdf_oficial`, que leva ao inteiro teor no servidor do próprio TCU
- **nosso**: `tese_md`, `aplicacao_pratica_md` e `limites_md`

Se o site exibir os dois juntos, vale marcar visualmente o que é citação. Misturar as vozes
faz parecer que o Tribunal disse o que nós explicamos.

`colegiado`, `relator`, `sumario_oficial` e `pdf_oficial` são **opcionais**: ausente quer
dizer "não obtivemos", nunca "não existe". Cinco fichas não têm sumário porque a base do TCU
não o traz.

### `newsletter` — 34 edições · partição `item` · 56 MB

A Axys Newsletter, uma edição por edição de fonte-base (SINAPI, CDHU, FDE). É o grupo mais
pesado da base.

Cada edição tem quatro artefatos:

```
newsletter/sinapi-2026-08/
    sinapi-2026-08.json     números apurados
    sinapi-2026-08.md       textos
    sinapi-2026-08.pdf      a revista, 7 páginas
    post/pagina-01.png …    7 imagens do carrossel
```

O `post/` é material de rede social, pronto para publicar. O nome dos arquivos é
`pagina-NN.png`, de 01 a 07.

### `artigos` — 10 artigos · partição `item` · 2,9 MB

Texto longo. O manifesto descreve (`titulo`, `chamada`, `assuntos`, `referencias`,
`palavras`) e o **corpo vive num `.md` próprio**, publicado como `text/markdown`, mais um
`.pdf` gerado dele.

O JSON nunca carrega o corpo. Revisar Markdown escapado dentro de string JSON é hostil para
quem escreve, e duas cópias do mesmo texto divergem na primeira edição.

### `downloads` — 5 documentos · partição `unico` · 28 MB

Publicações de terceiros que redistribuímos: duas cartilhas do TCU e três documentos do
IBRAOP.

**Dois campos aqui merecem atenção de vocês.** `licenca` traz o aviso de reprodução impresso
na obra, e nas do TCU ele condiciona a redistribuição a citar a fonte, sem fins comerciais.
`fonte` aponta a página de chamada e o arquivo no servidor do órgão. A citação não é
cortesia editorial: é a condição que nos autoriza a hospedar o arquivo, e precisa aparecer
onde o documento é oferecido.

### `institucional` — 7 itens · partição `item`

Quem é a Axys, contato, privacidade, termos. Conteúdo do próprio app.

---

## Onde a terminologia cruza com o resto

`referencias` é o que transforma listas soltas numa teia. Ela é **tipada**, para o cliente
abrir a tela certa por dentro em vez de jogar o leitor no navegador.

Duas novidades recentes, detalhadas em `hub_json_campos_novos.md`:

- **`DOWNLOADS` virou destino válido.** Antes, `referencias` só apontavam para conteúdo
  interno. Agora um verbete ou um artigo aponta para um PDF.
- **`pagina`** acompanha essas referências. O link se monta juntando o `arquivo` do
  manifesto de downloads com `#page={pagina}`. A URL não fica guardada no JSON de propósito:
  seria o mesmo caminho replicado em dezenas de lugares, e esta cartilha já mudou de nome uma
  vez.

---

## O que muda, e quando

| Grupo | Ritmo |
|---|---|
| `newsletter` | a cada edição de fonte: SINAPI mensal, CDHU e FDE quadrimestrais |
| `acordaos`, `artigos`, `terminologia` | quando há produção editorial |
| `downloads` | raro, quando um órgão publica documento novo |
| `institucional` | raro |

Cada publicação regenera o `_manifest.json` da raiz **contando o que existe de fato**.
Mantido à mão ele apodreceria na primeira semana.

O TTL do R2 reflete isso: manifesto com 5 minutos, porque é ponto de descoberta e muda a cada
publicação; conteúdo com 30 dias, porque item publicado é imutável e correção ganha caminho
novo.

---

## Dúvidas

A especificação dos campos está em
`docs/projects/axys-easy/modules/easy-mobile/conteudos_json_r2.md`.

Divergência entre o que este documento diz e o que o JSON traz, falem com o time do Easy
Mobile antes de contornar no código: campo interpretado de dois jeitos é como as duas pontas
divergem sem ninguém notar.
