# Acórdãos — como uma ficha se produz

Guia de produção da base de jurisprudência. 187 fichas em 20/09/2026.

Uma ficha tem **duas camadas que nunca se misturam**: o que o Tribunal decidiu, reproduzido
da fonte, e o que nós explicamos. Quem lê precisa saber qual é qual.

---

## Onde as coisas moram

```
z_scripts_apoio/importacao/
    tcu_busca_acordao.py             busca o acórdão na base pública do TCU
    acordao_verbete.py               escreve a ficha a partir do texto dele
    acordao_verbete_estilo.md        A DOUTRINA. Leia antes de mexer no prompt.

docs/.../v0_docs/acordaos/
    _manifest.json                   contado, nunca escrito à mão
    tcu-2622-2013/conteudo.json      uma pasta por acórdão
```

---

## Os campos, e de onde vem cada um

**Da fonte, reproduzido:**

| Campo | O que é |
|---|---|
| `numero`, `data` | número e **data da sessão** (não a de publicação) |
| `colegiado`, `relator` | quem julgou |
| `sumario_oficial` | o sumário do próprio acórdão |
| `pdf_oficial` | link para o inteiro teor no servidor do TCU |

**Nosso, autoral:**

| Campo | O que é |
|---|---|
| `tese_md` | o verbete: a regra, no imperativo |
| `aplicacao_pratica_md` | o que fazer com ela na planilha ou na fiscalização |
| `limites_md` | onde a tese NÃO alcança |
| `assuntos` | 2 a 5 ids do glossário, vocabulário controlado |
| `dispositivos` | normas citadas no texto do acórdão |

Os quatro campos da fonte são **opcionais**: ausente quer dizer "não obtivemos", nunca "não
existe". Cinco fichas não têm sumário porque a base do TCU não o traz.

---

## Produzir

### 1. Buscar o acórdão

```
.venv/bin/python z_scripts_apoio/importacao/tcu_busca_acordao.py 2622 2013 Plenário
```

**O colegiado é obrigatório, e não é zelo.** O mesmo número e ano existem em colegiados
diferentes, em acórdãos sem relação nenhuma: `1182/2025` aparece três vezes, um do Plenário e
dois de relação nas Câmaras. Buscar só por número devolve o errado sem avisar.

Sem colegiado (`--lote` com `colegiado: null`), a busca escolhe por sobreposição de
vocabulário e marca `ambiguo` quando há mais de um candidato de mérito.

### 2. Escrever a ficha

```
.venv/bin/python z_scripts_apoio/importacao/acordao_verbete.py 2622 2013 Plenário
.venv/bin/python z_scripts_apoio/importacao/acordao_verbete.py --lote alvos.json --gravar
```

**Sem `--gravar` não escreve nada**, só mostra o que faria. O padrão é o ensaio porque ficha
ruim publicada empresta autoridade do TCU a texto que ninguém conferiu.

O modelo escreve os três campos autorais. Número, data, colegiado, relator, sumário e link
vêm da API e **não passam por ele**: fato não se pede a modelo de linguagem.

### 3. Registrar e publicar

```
.venv/bin/python z_scripts_apoio/validacao/valida_conteudo_mobile.py
.venv/bin/python z_scripts_apoio/publicacao/publica_conteudo_mobile.py --publicar
```

---

## A doutrina do verbete

Detalhada em `acordao_verbete_estilo.md`. O essencial:

**Verbete não é citação nem resumo livre.** É a parte do voto que o colegiado acompanhou,
recolocada no imperativo para valer como regra geral.

**Máxima fidelidade ao texto do relator.** Muda-se tempo verbal e recorte, nunca o
vocabulário técnico. "Natureza superveniente" não vira "caráter imprevisto": quem lê a ficha
e vai ao acórdão tem de reconhecer o texto.

**Acórdão sem material não vira ficha.** Melhor 40 que se sustentam do que 186 com um terço
de enchimento. O modelo pode recusar, e recusou 30 de 186 — "trata de concessão de
aposentadoria", "prestação de contas e segregação contábil".

---

## As guardas, e por que cada uma existe

Todas nasceram de erro observado, nenhuma de hipótese:

| Guarda | Erro que a originou |
|---|---|
| `tese_md` em voz normativa | o modelo escrevia "Utilize os parâmetros", que é instrução, não enunciado |
| `dispositivos` recusa rito | vinham arts. do Regimento Interno, que são o rito do recurso |
| dispositivo tem de estar no texto | dedução aqui é invenção |
| `assuntos` só do glossário | etiqueta livre racha o vocabulário |
| sem travessão, sem ponto e vírgula | estilo da casa |

---

## Armadilhas do acervo do TCU

**O firewall corta por ritmo e responde HTTP 200 com HTML.** Erro que se disfarça de
sucesso: nenhuma checagem de código HTTP o pega. Cortou três vezes numa varredura de 187.
Regra: 1 a 2 requisições por acórdão, pausa de 8 segundos.

**`/documento` devolve UM resultado e ignora `quantidade`.** Quem lista é
`documentosResumidos`. Confundir os dois fazia a busca devolver sempre o primeiro por
relevância, muitas vezes acórdão de relação.

**Acórdão de relação PODE ter determinação substantiva.** Não é despacho vazio por
definição. O `2423/2024` do Plenário é de relação e fixa entendimento sobre acompanhamento
de riscos, exatamente o que a cartilha cita. Preferir o de mérito ali traria um acórdão sobre
Fundo Nacional de Assistência Social.

**Quem desambigua é o ASSUNTO, não o tipo do documento.**

**O acervo anterior a 2001 vem pela metade.** A Decisão 215/1999-Plenário tem dispositivo
VAZIO na base. Comparar relevância entre candidatos pressupõe que todos tenham texto: ali,
o número maior é o do documento mais bem indexado, não o mais pertinente.

**A substância está no VOTO.** O sumário é cabeçalho processual (`AUDITORIA. FISCOBRAS.
DETERMINAÇÕES`) e quase nunca repete o tema. Conferir uma ficha contra o sumário produz
falso positivo em massa: 16 de 31 pareciam erradas; contra o voto, nenhuma.

---

## Conferir uma ficha

O teste que funciona é o **eco de vocabulário**: quantos termos da nossa tese aparecem no
sumário + dispositivo + voto do acórdão. Eco alto significa que a ficha fala do mesmo
assunto que o documento.

Na auditoria de 20/09/2026: 186 conferidas, 150 com eco acima de 80%, **nenhuma com eco
zero**, uma trocada de documento.
