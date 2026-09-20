# Downloads — como se acrescenta um documento

Guia de produção da estante de publicações de terceiros. 5 documentos em 20/09/2026: duas
cartilhas do TCU e três do IBRAOP.

Aqui não se produz conteúdo, se **redistribui** — e redistribuir obra alheia tem condição.

---

## Onde as coisas moram

```
z_scripts_apoio/publicacao/
    gera_manifesto_downloads.py      a lista de itens vive DENTRO dele

docs/.../v0_docs/downloads/
    _manifest.json                   gerado, nunca escrito à mão
    tcu-engenharia-custos-….pdf      o arquivo, já renomeado
```

O manifesto é gerado do script, e a lista de documentos é uma constante no próprio script.
Acrescentar documento é **editar o script**, não o JSON.

---

## Acrescentar um documento

### 1. Pôr o arquivo em `downloads/`

Com o nome que vier da origem. O script renomeia.

### 2. Declarar no script

Em `gera_manifesto_downloads.py`, acrescente ao `ITENS`:

```python
dict(origem="cartilha_….pdf",                    nome como chegou
     id="tcu-engenharia-custos-perguntas-respostas",   vira o nome publicado e a URL
     tipo="pdf",
     titulo="Engenharia de Custos em Obras Públicas · Guia de perguntas e respostas",
     resumo="O que é, em duas ou três frases. O usuário decide por ele se baixa 4 MB.",
     autoria="Tribunal de Contas da União", data_documento="2026",
     licenca=LICENCA_TCU,
     fonte={"pagina": "https://portal.tcu.gov.br/…",
            "arquivo": "https://portal.tcu.gov.br/uploads/….pdf"}),
```

O `id` vira o nome do arquivo publicado e a URL. **Corrigir um título depois não muda a
URL**; mudar o `id`, sim, e quebra toda referência que aponte para ele.

Os arquivos são renomeados para nome falante porque `OT_DIRETRIZES_OT-009-2024b.pdf` não diz
nada na tela de um celular.

### 3. Gerar e publicar

```
.venv/bin/python z_scripts_apoio/publicacao/gera_manifesto_downloads.py
.venv/bin/python z_scripts_apoio/validacao/valida_conteudo_mobile.py
.venv/bin/python z_scripts_apoio/publicacao/publica_conteudo_mobile.py --publicar
```

---

## Licença e origem

**`licenca`** guarda o aviso de reprodução impresso na obra, copiado **palavra por palavra**:
resumir uma licença é alterá-la.

As publicações do TCU dizem, na folha de rosto:

> Permite-se a reprodução desta publicação, em parte ou no todo, sem alteração do conteúdo,
> desde que citada a fonte e sem fins comerciais.

A citação é **condição da redistribuição**, não cortesia editorial. Por isso ela viaja junto
do arquivo até a tela, e não fica só no nosso registro.

**`fonte`** aponta a página de chamada e o arquivo no servidor do órgão. Serve a dois
propósitos: o leitor que desconfiar vai à origem e compara, e o link de saída para domínio
`gov.br` sinaliza procedência.

Os dois campos são opcionais, e só aparecem em quem os tem. As do IBRAOP estão sem `licenca`
porque não localizamos aviso equivalente nelas — e **não se inventa termo de licença**.

---

## Edição nova não apaga a anterior

Quando o órgão publica revisão, ela **entra ao lado**, não no lugar.

Em 19/09/2026 o TCU publicou a revisão da cartilha de 2014. As duas estão na estante: quem
audita contrato antigo precisa da regra vigente à época, e sumir com o documento superado é
reescrever o passado.

Quem separa as duas é o campo `data_documento`, e o `resumo` da antiga passa a dizer que foi
superada, com o motivo.

---

## Citar um download de dentro do conteúdo

Desde 19/09/2026, verbetes e artigos apontam para documento em **página específica**:

```json
{ "tipo": "publicacao", "grupo": "DOWNLOADS",
  "id": "tcu-engenharia-custos-perguntas-respostas", "pagina": 40 }
```

**A URL não se guarda.** Quem exibe monta `{arquivo do manifesto}#page={pagina}`. Guardar a
URL pronta replicaria um caminho determinístico em dezenas de lugares — e esta cartilha
mudou de nome no dia em que entrou, de `cartilha_…_eb964dd641.pdf` para
`tcu-engenharia-custos-perguntas-respostas.pdf`.

**A página é a do PDF, não a impressa.** Nesta cartilha o miolo está deslocado em 9: o
capítulo de BDI é "p. 31" no sumário e página 40 do arquivo. A bibliografia está em 8. Não há
fórmula, e converter o número do sumário por aritmética é como o link passa a apontar para o
lugar errado sem ninguém perceber.

Para achar a página certa:

```
.venv/bin/python z_scripts_apoio/genericos/pdf_para_markdown.py caminho/do.pdf saida.md
```

Ele marca cada página com `<!-- p.N -->`. Depois é procurar o trecho no texto e ler a âncora.
