# Axys Newsletter — como uma edição se produz

Guia de produção. Descreve onde cada coisa mora, a ordem dos passos e o que cada um decide.

Uma edição de newsletter segue **uma** edição de fonte-base. Não há newsletter sem edição
anterior da mesma fonte para comparar: o produto inteiro é o diferencial entre duas.

---

## Onde as coisas moram

```
z_scripts_apoio/newsletter/          os quatro passos
    gera_dados_newsletter.py           1. apura
    gera_pdf_newsletter.py             2. desenha
    valida_newsletter.py               3. confere
    gera_manifesto_newsletter.py       4. registra

backend/modules/catalogo/
    newsletter_dossie.py             OS NÚMEROS. Só lê e agrega.

backend/core/
    service_newsletter.py            A PELE. Decide o desenho, monta o HTML do PDF.

docs/.../v0_docs/newsletter/
    _modelo.md                       o texto genérico, com marcadores
    _manifest.json                   contado, nunca escrito à mão
    sinapi-2026-08/                  uma pasta por edição
```

A separação entre dossiê e pele importa: os números precisam poder ser conferidos **sem
abrir um PDF**.

---

## Uma edição em disco

```
newsletter/sinapi-2026-08/
    sinapi-2026-08.json     números apurados — nunca editado à mão
    sinapi-2026-08.md       os textos, JÁ com os números dentro
    sinapi-2026-08.pdf      a revista, 7 páginas
    post/pagina-01.png …    7 imagens do carrossel, uma por página
```

**O `.md` é o ponto de intervenção humana**, e o passo 2 lê ELE, não o modelo. Assim a
revisão editorial de um mês não se perde na geração seguinte, e ninguém precisa mexer no
modelo genérico para acertar uma frase de uma edição específica.

Número errado **não se conserta no `.md`**: o problema é de apuração e se resolve no dossiê.
Reescrever a frase deixa o texto divergente do JSON, e o JSON é o que se confere.

---

## Os quatro passos

### 1. Apurar

```
.venv/bin/python z_scripts_apoio/newsletter/gera_dados_newsletter.py --listar
.venv/bin/python z_scripts_apoio/newsletter/gera_dados_newsletter.py --fonte SINAPI --n 20
```

`--listar` mostra o que é publicável por fonte, numerado; `--n` escolhe pelo número.
Escreve o `.json` e o `.md`. Não sobrescreve `.md` existente sem `--forcar`, para não
apagar revisão.

**Rode contra PRODUÇÃO.** O banco local pode estar atrasado ou ter edição em rascunho que
em produção já saiu:

```
EASY_DB_URL="<url de produção>" .venv/bin/python …/gera_dados_newsletter.py --fonte CDHU --n 7
```

Já aconteceu de o local dizer que faltava CDHU 2026-07 quando produção tinha 2026-08, e de
dar o FDE como rascunho quando estava publicado.

### 2. Revisar o `.md`

Opcional, e é onde entra o julgamento editorial. As linhas `## chave` têm de ficar: são elas
que dizem onde cada texto entra.

Uma chave útil, que não vem no modelo: **`_insumos_max`**. Acrescente-a com um número para
cortar a lista de insumos quando a última página fechar com meia dúzia de linhas. É decisão
daquele mês, e por isso mora no `.md` e não no `.json`.

### 3. Desenhar

```
.venv/bin/python z_scripts_apoio/newsletter/gera_pdf_newsletter.py --edicao sinapi-2026-08
```

Gera o PDF e as 7 imagens do carrossel.

### 4. Conferir, e só então registrar

```
.venv/bin/python z_scripts_apoio/newsletter/valida_newsletter.py --edicao sinapi-2026-08
.venv/bin/python z_scripts_apoio/newsletter/gera_manifesto_newsletter.py
```

**O validador não é opcional.** Ele pega o que o olho cansa de conferir: título órfão
fechando página, tabela decapitada, transbordo de margem, página com menos de 40% de
ocupação (denuncia bloco que pulou inteiro) e marcador `{coisa}` que escapou da
substituição.

O manifesto só inclui edição **que tem PDF** — o app oferece o download, e prometer arquivo
inexistente é erro que só aparece na mão do usuário.

### 5. A vitrine, que é arquivo à parte

```
.venv/bin/python z_scripts_apoio/publicacao/gera_ultimas.py
```

`_ultimas.json` é a home, e **não** é regenerada pelo manifesto. Esquecer este passo publica
o acervo novo com a home velha. A receita são as 3 newsletters mais recentes, 1 artigo e
1 caso.

### 6. Publicar

```
.venv/bin/python z_scripts_apoio/publicacao/publica_conteudo_mobile.py            # ensaio
.venv/bin/python z_scripts_apoio/publicacao/publica_conteudo_mobile.py --publicar
```

Valida a base inteira antes de subir, e recusa publicar com erro.

---

## As decisões que valem para as três fontes

Fechadas em 22/08/2026, documentadas em `newsletter_dossie.py`:

**Modalidade sempre SD**, onerado. Olhar sempre o mesmo regime torna a série comparável: o
que muda de mês para mês é o preço do insumo, enquanto encargos quase não se mexem.
Alternar introduziria degrau que é da nossa escolha, não do mercado.

**Nível subgrupo, não grupo.** SINAPI não tem grupos, só 173 subgrupos; CDHU tem 61 e FDE
16. Subgrupo é o único nível que as três têm.

**SP em evidência.** Média de 27 UFs esconde que a variação não é nacional. O corpo é SP, e
a dispersão territorial entra como destaque próprio — só na SINAPI, a única com as 27.

**Índice acumulado no intervalo.** CDHU e FDE são quadrimestrais: comparar três meses de
variação contra o IPCA de um mês subestimaria a inflação em três vezes.

**Selic é contexto, não comparador.** Está guardada como taxa, não como variação.

---

## A regra do custo, e a exceção do FDE

A variação publicada sai do **custo declarado pela fonte** (`cc_custo_fonte`). O leitor
compara o nosso número com o que a fonte divulga, e divergir ali põe em dúvida o número
inteiro.

**O FDE é exceção.** Ele publica preço **com BDI embutido**, e nós o retiramos; ali o número
certo é o nosso (`cc_custo_calculado`). Medido: SINAPI bate em 0,00%, CDHU difere -0,07% por
arredondamento, e FDE difere **-18,72%**, que é o BDI.

Por isso o dossiê marca `custo_sem_bdi`, e o texto de cobertura diz ao leitor: no FDE, que
os valores excluem o BDI e representam custo, não preço de venda; nas demais, que são os
custos declarados pela fonte. **A frase é automática de propósito** — depender de alguém
lembrar de escrevê-la é como ela some justamente na edição em que faltar atenção.

**Cobertura é outra pergunta** e mede `cc_custo_calculado` sempre. Medida pela coluna da
fonte, CDHU acusaria 33,3% de buraco e FDE 50%: números falsos, que só dizem que a fonte não
declara a modalidade SE.

---

## Seções que somem sozinhas

Nem toda fonte tem todas as camadas. O dossiê devolve `None` e tanto o PDF quanto o `.md`
pulam a seção:

| Seção | Some quando |
|---|---|
| grupos | a fonte não tem a camada (SINAPI) |
| dispersão por UF | a fonte é de UF única (CDHU, FDE) |

Isso explica por que a mesma edição rende conjuntos de seções diferentes conforme a fonte, e
por que comparar `## chave` entre fontes distintas acusa diferença que não é defeito.
