# Achados: jurisprudência do TCU como fonte

Levantamento de 19/09/2026, feito para trazer a cartilha do TCU de 2026 para a Base de
Conhecimento e para conferir os acórdãos que já tínhamos.

Fica **fora de `v0_docs/`** de propósito. Toda pasta dentro de `v0_docs/acordaos/` precisa
ser um acórdão com `conteudo.json`, e uma pasta de pesquisa ali faz o validador reprovar —
que, por contrato, barra a publicação inteira.

---

## 1. As duas APIs do TCU, e por que a documentada não basta

### A documentada (dados abertos)

```
GET https://dados-abertos.apps.tcu.gov.br/api/acordao/recupera-acordaos?inicio=0&quantidade=5000
```

Único endpoint de acórdãos em `sites.tcu.gov.br/dados-abertos/webservices-tcu/`. Aceita
**apenas** `inicio` e `quantidade`: não há filtro por número, ano, colegiado nem texto.

Medido: o acervo para em torno de 100 mil registros, o que alcança **2020**. Baixamos
96.400 e cruzamos com os 99 acórdãos citados na cartilha: **resolve 31**. Os 68 restantes
são de 2001 a 2022, justamente a jurisprudência consolidada. O 2622/2013, citado 18 vezes
na cartilha, está fora.

### A que o site de pesquisa usa (não documentada)

Descoberta lendo `main.js` de `pesquisa.apps.tcu.gov.br`. Alcança o acervo inteiro.

```
GET https://pesquisa.apps.tcu.gov.br/rest/publico/base/{base}/{endpoint}
      ?termo=*&filtro={filtro}&ordenacao={ord}&quantidade={n}&inicio={i}
```

| Parte | Valor |
|---|---|
| `base` | `acordao-completo`, `jurisprudencia-selecionada`, `ata-sessao`, `norma`, … |
| `endpoint` | `documentosResumidos` para **listar**; `documento` devolve **UM**, na posição `inicio` |
| `filtro` | sintaxe de campo: `NUMACORDAO:2622 ANOACORDAO:2013 COLEGIADO:"Plenário"` |
| `ordenacao` | `DTRELEVANCIA desc, NUMACORDAOINT desc, COPIACOLEGIADO desc` |

**Armadilha 1 — `documento` ignora `quantidade`.** Devolve um documento só, seja qual for o
valor. Perdemos uma rodada inteira de coleta achando que `quantidade=1000` não funcionava.
Para listar é `documentosResumidos`.

**Armadilha 2 — o firewall responde com status 200.** Sem cabeçalho de navegador, o serviço
devolve uma página HTML de bloqueio **com HTTP 200**: erro disfarçado de sucesso. É preciso
conferir o corpo, não o status. Com `User-Agent` e `Referer` normais, responde JSON.

Campos de pesquisa de `acordao-completo`: `NUMACORDAO`, `ANOACORDAO`, `COLEGIADO`,
`RELATOR`, `SUMARIO`, `ACORDAO`, `RELATORIO`, `VOTO`, `PROC`, `ASSUNTO`, `ENTIDADE`,
`UNIDADETECNICA`, `TIPOPROCESSO`, `QUORUM`, entre outros.

Implementado em `z_scripts_apoio/importacao/tcu_busca_acordao.py`.

---

## 2. A armadilha do colegiado

**O mesmo número e ano existem em colegiados diferentes, e são acórdãos sem relação
nenhuma entre si.**

Exemplo: `46/2012` retorna três resultados, um do Plenário e dois "de relação", nas duas
Câmaras. Buscar só por número e ano devolve um deles em ordem que **não é estável** — a
mesma consulta nos deu Primeira Câmara numa rodada e Segunda na seguinte.

A cartilha do TCU sempre escreve o colegiado na citação (`1.182/2025-TCU-Plenário`), então
de lá se desambigua. Onde não houver, é preciso conferir o conteúdo.

### Como conferir qual é o certo

Comparamos os `assuntos` declarados na nossa ficha com o texto do acórdão. O resultado muda
conforme o que se compara:

| Comparado contra | Fichas sem nenhum eco |
|---|---|
| Só o `SUMARIO` | 16 de 31 |
| `SUMARIO` + `ACORDAO` (dispositivo) | 3 de 31 |
| `SUMARIO` + `ACORDAO` + **`VOTO`** | **0** |

**O sumário do TCU é um cabeçalho processual** (`AUDITORIA. FISCOBRAS. DETERMINAÇÕES`) e
quase nunca repete o tema: comparar contra ele produz falso positivo em massa. **A
substância está no VOTO.** Com os três campos juntos, cada número ambíguo teve exatamente
um candidato com eco total e os demais com zero.

| Acórdão | Colegiado certo | Eco | Candidatos descartados |
|---|---|---|---|
| `46/2012` | Plenário, 18/01/2012, José Mucio Monteiro | 5/5 | 2 de relação, ambos 0/5 |
| `3289/2014` | Plenário, 26/11/2014, Walton Alencar Rodrigues | 6/6 | 2 de relação, ambos 0/6 |
| `3576/2019` | **Primeira Câmara**, 07/05/2019, Benjamin Zymler | 5/5 | Segunda Câmara, 0/5 |

Estes três chegaram a ser removidos da base com base na medição incompleta (só sumário e
dispositivo) e foram **restaurados** depois da conferência com o voto. Fica o registro: a
régua errada condenou conteúdo correto.

---

## 3. O que a conferência revelou na nossa base

- **28 das 30 fichas tinham `data` NULA.** O campo existia e nunca fora preenchido.
- A única preenchida estava **errada**: `2622/2013` constava `2013-10-02`, e a sessão foi em
  `25/09/2013`. Provavelmente data de publicação no lugar da de sessão.
- **Três não eram do Plenário**, como o `orgao: "TCU"` genérico sugeria: `3576/2019` e
  `43/2015` são de Câmara.

Padronizamos `data` na **data de sessão**, que é a identidade que o TCU usa.

---

## 4. Mapa de expansão (levantado, NÃO aplicado)

A base `jurisprudencia-selecionada` é a curadoria do próprio TCU: **17.812 enunciados**, cada
um com a tese em uma frase, classificado por área, tema e subtema, e amarrado ao acórdão de
origem.

Campos: `AREA`, `TEMA`, `SUBTEMA`, `ENUNCIADO`, `EXCERTO`, `INDEXACAO`, `NUMACORDAO`,
`ANOACORDAO`, `COLEGIADO`, `AUTORTESE`, `DATASESSAOFORMATADA`, `NUMSUMULA`, `TIPOPROCESSO`.

Por área:

| Área | Enunciados |
|---|---|
| Responsabilidade | 3.461 |
| Licitação | 3.361 |
| Contrato Administrativo | 1.111 |
| Convênio | 857 |
| Finanças Públicas | 484 |

Dentro de Licitação + Contrato Administrativo há 4.472 enunciados em 105 temas. O recorte de
obras e orçamento dá **1.223 enunciados sobre 1.040 acórdãos distintos**:

| Tema | Enunciados |
|---|---|
| Obras e serviços de engenharia | 411 |
| Orçamento estimativo | 200 |
| Aditivo | 152 |
| Superfaturamento | 91 |
| Projeto básico | 86 |
| Parcelamento do objeto | 80 |
| RDC | 67 |
| Equilíbrio econômico-financeiro | 66 |
| Fiscalização | 42 |
| Reajuste | 16 |
| Sobrepreço | 11 |

Subtemas de "Obras e serviços de engenharia": Superfaturamento 72, Orçamento estimativo 69,
**BDI 67**, Fiscalização 39, Rodovia 33, Preço 24, Licença ambiental 24, Planejamento 14,
Cronograma físico-financeiro 7, Medição 6.

Exemplo de enunciado, com a redação do próprio TCU:

> **1513/2026-Plenário** · Obras e serviços de engenharia / Garantia contratual
> É irregular a exigência de seguro-garantia com cláusula de retomada (art. 102 da Lei
> 14.133/2021) em montante acima de 5% sobre o valor inicial do contrato sem a devida
> motivação técnica.

**Decisão de 19/09/2026: NÃO expandir.** A base fica com os acórdãos citados na cartilha,
porque essa é uma curadoria do próprio TCU sobre engenharia de custos. Os 1.040 entram
depois, se e quando houver motivo — este mapa existe para que o levantamento não precise
ser refeito.

Detalhe técnico para quando for a hora: o campo `ENUNCIADO` vem com `<a href>` embutido
apontando para o Planalto. Preservar o link ou guardar texto puro é decisão pendente.

---

## 5. A cartilha como fonte

`Engenharia de Custos em Obras Públicas — Guia de perguntas e respostas`, TCU, 2026, 152
páginas. Revisa a cartilha de 2014, agora sob a Lei 14.133/2021.

- **99 acórdãos** citados no miolo, em 136 citações. A contagem sobe de 80 para 99 quando se
  normalizam as quebras de linha antes de casar o padrão: sem isso, citação partida entre
  duas linhas passa despercebida.
- A bibliografia (páginas 139 a 149 do PDF) lista 80 entradas com colegiado e ano, mas **sem
  data exata**.
- **A página do PDF não é a impressa no papel.** O miolo está deslocado em 9 (o capítulo de
  BDI é "p. 31" no sumário e página 40 do arquivo) e a bibliografia em 8. Não há fórmula: a
  página se descobre no texto extraído por `z_scripts_apoio/genericos/pdf_para_markdown.py`,
  que marca cada uma com `<!-- p.N -->`.
- Acórdãos mais citados: `2622/2013` (18×), `2191/2025` (5×), `1182/2025` (5×),
  `1218/2026` (4×).
- **Três citados não foram localizados** em nenhum colegiado: `4370/2023`, `3569/2023` e
  `7290/2013`. Pendente.
