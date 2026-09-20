# Onde fica cada coisa

Conteúdo da Base de Conhecimento do Easy Mobile. Esta pasta é a fonte; o R2 é cópia dela.

```
v0_docs/
├── _terminologia.json      89 verbetes do glossário, TODOS num arquivo só
├── _ultimas.json           a vitrine da home (gerada, não editada)
│
├── acordaos/               187 fichas de jurisprudência do TCU
│   ├── _manifest.json
│   └── tcu-2622-2013/conteudo.json
│
├── artigos/                10 artigos longos
│   ├── _manifest.json
│   ├── 02-bdi-sem-atalhos.md        o texto (o número é ordem, não identidade)
│   └── bdi-sem-atalhos.pdf          gerado do .md
│
├── casos/                  16 casos práticos
│   ├── _manifest.json
│   └── aditivo-em-planilha-separada/conteudo.json
│
├── downloads/              5 documentos de terceiros (TCU, IBRAOP)
│   ├── _manifest.json
│   └── tcu-engenharia-custos-perguntas-respostas.pdf
│
├── duvidas/                30 dúvidas rápidas, agrupadas por assunto
│   ├── _manifest.json               lista os ASSUNTOS, não as dúvidas
│   └── bdi.json                     6 dúvidas de BDI
│
├── institucional/          7 páginas do app (contato, missão, privacidade…)
│   ├── _manifest.json
│   └── contato.json
│
└── newsletter/             34 edições da revista
    ├── _manifest.json
    ├── _modelo.md                   texto genérico com marcadores
    └── sinapi-2026-08/
        ├── sinapi-2026-08.json      números apurados
        ├── sinapi-2026-08.md        os textos
        ├── sinapi-2026-08.pdf       a revista
        └── post/pagina-01.png …     7 imagens do carrossel
```

## Procurando algo

| Quero… | Está em |
|---|---|
| o que significa um termo | `_terminologia.json` |
| o que o TCU decidiu | `acordaos/tcu-{numero}-{ano}/conteudo.json` |
| um texto longo | `artigos/NN-{slug}.md` |
| uma situação de obra | `casos/{slug}/conteudo.json` |
| uma cartilha para baixar | `downloads/` |
| pergunta e resposta curta | `duvidas/{assunto}.json` |
| a revista de um mês | `newsletter/{fonte}-{ano}-{mes}/` |

## Três coisas que confundem

**`_manifest.json` é sempre contado, nunca escrito à mão.** Mantido a dedo, apodrece na
primeira semana. Quem gera: `z_scripts_apoio/publicacao/` e `z_scripts_apoio/newsletter/`.

**O de `duvidas` é diferente dos outros**: ele lista `assuntos`, não `itens`. Quem procura
`itens` ali encontra zero, e há 30 dúvidas.

**`_ultimas.json` não sai do manifesto.** É a vitrine da home, tem script próprio
(`gera_ultimas.py`), e esquecer de rodá-lo publica acervo novo com home velha.

## Para produzir

- Revista: `newsletter_como_se_produz.md` (na pasta acima)
- Formato dos campos: `conteudos_json_r2.md` (na pasta acima)
- Publicar tudo: `z_scripts_apoio/publicacao/publica_conteudo_mobile.py --publicar`
