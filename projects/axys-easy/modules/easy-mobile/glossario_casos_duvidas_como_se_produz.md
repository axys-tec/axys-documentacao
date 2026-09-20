# Glossário, casos e dúvidas — como se produzem

Os três conteúdos **escritos inteiramente à mão**. Não há script que os gere: há validador
que os recusa quando saem errados.

| | Quantos | Onde |
|---|---|---|
| Glossário | 89 verbetes | `_terminologia.json`, arquivo único |
| Casos práticos | 16 | `casos/{slug}/conteudo.json` |
| Dúvidas rápidas | 30 em 5 assuntos | `duvidas/{assunto}.json` |

---

## O glossário governa o resto

`_terminologia.json` não é só um dicionário: é o **vocabulário controlado** da base inteira.
Os `assuntos` de acórdãos, casos, dúvidas e artigos usam o `id` do verbete, nunca etiqueta
livre.

Sem essa disciplina o vocabulário racha, e ele já rachou duas vezes: `aditivos` convivendo
com `aditivo-contratual`, `canteiro` com `canteiro-de-obras`, `limite` com `limites`.
Etiqueta rachada quebra o agrupamento no app e esvazia as `referencias`, que são o que
transforma três listas soltas numa teia.

### Um verbete

```json
{ "id": "contingencia", "termo": "Contingência", "expansao": null,
  "conceito_md": "O que é, em uma ou duas frases.",
  "funcao_pratica_md": "Para que serve na planilha.",
  "distincoes": [ { "termo": "Álea extraordinária",
                    "diferenca_md": "Onde um acaba e o outro começa." } ],
  "ver_tambem": ["matriz-de-riscos", "bdi"],
  "referencias": [ … ] }
```

`id` tem de ser o slug de `termo` — o validador confere. `ver_tambem` só aponta para verbete
existente.

### Quando criar um verbete, e quando não

**Assunto usado em dois ou mais documentos não é cauda longa: é conceito faltando.** Foi essa
régua que gerou `orcamento`, `preco-global`, `edital`, `regime-de-execucao`, `contrato-verbal`
e `atraso` — todos vieram do uso real, nenhum de brainstorm.

**Assunto usado uma vez só fica como está.** Forçar verbete para etiqueta ocasional incha o
glossário sem servir ninguém.

O validador ajuda: assunto sem verbete vira aviso, e aviso que se repete é o sinal. Em
20/09/2026 foi assim que entraram `orcamento-de-referencia`, `regionalizacao` e
`metodologia-executiva`; e foi assim que `planejamento`, `documentacao` e `custo` **não**
entraram, por genéricos demais.

### Gênero e espécie não são colisão

`orcamento` e `orcamento-analitico` compartilham prefixo e **devem coexistir**. Já
`reequilibrio` e `reequilibrio-economico-financeiro` são o mesmo conceito abreviado. Máquina
não separa os dois casos: vizinhança por prefixo é aviso, não erro, e quem decide é quem
escreve.

---

## Casos práticos

Situação concreta de obra e o que fazer com ela. Um `conteudo.json` por caso, mais a entrada
no `_manifest.json` do grupo.

Campos: a situação, a resposta curta, o desenvolvimento, `assuntos` e `referencias`.

O caso serve quando a pergunta é **"o que faço nesta situação?"**. Se for "o que significa",
é verbete; se for "como funciona por inteiro", é artigo.

---

## Dúvidas rápidas

Pergunta curta com resposta direta, agrupadas por assunto: `bdi`, `composicoes`, `encargos`,
`orcamento-e-contratos`, `referencias-de-precos`. Seis por arquivo.

**O manifesto deste grupo é diferente dos outros**: ele lista `assuntos`, não `itens`. Quem
procura `itens` ali encontra zero, e há 30 dúvidas.

Para acrescentar uma dúvida, edite o arquivo do assunto. Para criar um assunto novo,
acrescente o arquivo e registre-o no `_manifest.json`.

---

## O portão

```
.venv/bin/python z_scripts_apoio/validacao/valida_conteudo_mobile.py
```

**Erro barra a publicação. Aviso não.**

| Erro (barra) | Aviso (não barra) |
|---|---|
| referência para id inexistente | assunto sem verbete |
| campo `_md` vazio | assunto vizinho de um verbete |
| `vinculados` no lugar de `referencias` | travessão no texto |
| assuntos divergindo entre manifesto e conteúdo | expressão burocrática |
| colisão inequívoca de vocabulário | monotonia de molde nas distinções |

O portão existe porque o vocabulário rachou duas vezes seguidas, do mesmo jeito, e nada
barrava antes de publicar. Na primeira execução ele pegou o que a revisão manual deixara
passar (`equipamentos` × `equipamento`, `insumos` × `insumo`).

---

## Regras de escrita

**Caixa alta** na identidade do catálogo (descrição, subgrupo, unidade). Minúsculas nas
fichas.

**Sem travessão** em texto publicado.

**Rótulo de acórdão é sempre `Acórdão {órgão} {número}`**, sem cauda descritiva. O título e a
tese o app busca na própria ficha; repetir no rótulo cria duas versões da mesma descrição,
que divergem na primeira edição.

**Vínculo automático não se soma a curadoria humana.** Onde o conteúdo já traz acórdãos
escolhidos a dedo, o preenchimento automático não acrescenta.

---

## Publicar

```
.venv/bin/python z_scripts_apoio/publicacao/gera_ultimas.py          # se entrou caso novo
.venv/bin/python z_scripts_apoio/publicacao/publica_conteudo_mobile.py --publicar
```
