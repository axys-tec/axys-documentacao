# Artigos — como um artigo se produz

Guia de produção dos textos longos. 10 artigos em 20/09/2026.

Artigo é o único conteúdo da base **escrito à mão do começo ao fim**. Não há script que o
gere: há script que gera o PDF dele e que o registra.

---

## Onde as coisas moram

```
z_scripts_apoio/artigos/
    gera_pdf_artigos.py              gera os PDFs e registra no manifesto

backend/core/
    service_articles.py              a pele: HTML → PDF, capa, tipografia

docs/.../v0_docs/artigos/
    _manifest.json                   descreve; NUNCA carrega o corpo
    08-fases-de-projeto-….md         o texto
    fases-de-projeto-….pdf           gerado do .md
```

**O número no nome do arquivo é ordem de edição, não identidade.** O nome publicado sai do
`id` do manifesto, então reordenar arquivos não muda URL.

---

## A separação que sustenta tudo

O manifesto **descreve**: `titulo`, `chamada`, `assuntos`, `referencias`, `palavras`. O corpo
vive num `.md` próprio, publicado como `text/markdown`.

O JSON nunca carrega o texto. Revisar Markdown escapado dentro de string JSON é hostil para
quem escreve, e duas cópias do mesmo texto divergem na primeira edição. O `.md` é a fonte
**e** o arquivo publicado: não existe segunda cópia para divergir.

---

## Produzir

### 1. Escrever o `.md`

Nome: `NN-{slug}.md`, com NN sequencial. A primeira linha é `# Título`, e **é por ela que o
publicador casa o arquivo com o manifesto** — título no `.md` diferente do `titulo` no JSON
significa artigo que não sobe.

### 2. Registrar no manifesto

À mão, em `artigos/_manifest.json`:

```json
{ "id": "fases-de-projeto-e-a-precisao-orcamentaria",
  "titulo": "Fases de projeto e a precisão orçamentária correspondente",
  "chamada": "Uma frase que faz o leitor abrir.",
  "assuntos": ["projeto", "projeto-basico", "anteprojeto"],
  "referencias": [ … ],
  "conteudo": "easy-mobile/artigos/fases-de-projeto-e-a-precisao-orcamentaria.md",
  "formato": "markdown", "palavras": 937, "publicado_em": "2026-09-20" }
```

`palavras` é conferido pelo validador contra o arquivo. Divergiu, reprova.

### 3. Gerar o PDF

```
.venv/bin/python z_scripts_apoio/artigos/gera_pdf_artigos.py
```

Gera todos e acrescenta `pdf` e `pdf_bytes` ao manifesto. Pré-gerar em vez de renderizar sob
demanda: o app oferece "baixar", e quem baixa quer o arquivo, não um render. São dezenas de
KB por artigo, sempre os mesmos bytes.

### 4. Validar e publicar

```
.venv/bin/python z_scripts_apoio/validacao/valida_conteudo_mobile.py
.venv/bin/python z_scripts_apoio/publicacao/publica_conteudo_mobile.py --publicar
```

---

## Estilo

**Tamanho**: os sete primeiros ficaram entre 547 e 839 palavras. Os três de setembro de 2026
passaram de 900 por acréscimos do autor, e isso é escolha editorial, não regra quebrada.

**Sem travessão.** O validador avisa. Vale para todo texto publicado.

**Seções curtas com `##`.** Parágrafos de duas a quatro linhas. Negrito só no que decide a
leitura.

**Tabela funciona**, tanto no app quanto no PDF.

---

## Links

O gerador trata **as duas formas**, porque quem escreve alterna entre elas sem pensar:

```markdown
[Easy Orça™](https://www.axys-tec.com.br/easy-orca)     markdown
https://www.axys-tec.com.br/easy-orca                    URL solta
```

Nos dois casos sai link clicável no PDF.

**Não repita a URL como texto do link.** `[https://…](https://…)` imprime o endereço inteiro
no corpo, atravessa a linha e polui. O nome do produto basta.

As URLs oficiais dos produtos estão em `reference_produtos_axys_urls` (memória do projeto).
Atenção a `easy-orca`, sem cedilha, e `easy-proj-manager`, abreviado.

---

## Referências

`referencias` é tipada, para o app abrir a tela certa por dentro. Um artigo costuma apontar
para verbetes do glossário e acórdãos que o fundamentam.

Desde 19/09/2026 também aponta para **PDF numa página específica**:

```json
{ "tipo": "publicacao", "grupo": "DOWNLOADS",
  "id": "tcu-engenharia-custos-perguntas-respostas", "pagina": 40,
  "rotulo": "Cartilha TCU 2026 · BDI e preço de venda" }
```

**A página é a do PDF, não a impressa no papel.** São números diferentes: na cartilha do TCU
o miolo está deslocado em 9 e a bibliografia em 8. Não há fórmula. A página se descobre no
texto extraído por `z_scripts_apoio/genericos/pdf_para_markdown.py`, que marca cada uma com
`<!-- p.N -->`.

---

## Citar fonte de terceiro

Documento alheio citado no corpo vai para `downloads/` e se referencia por `grupo` e `id`,
nunca por URL colada no texto. Ver `gera_manifesto_downloads.py`.

Publicação do TCU condiciona a reprodução a citar a fonte, sem fins comerciais — o campo
`licenca` do manifesto de downloads carrega esse aviso, e ele precisa aparecer onde o
documento é oferecido.
