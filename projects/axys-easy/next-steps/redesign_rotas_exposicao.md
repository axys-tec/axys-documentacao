# Redesign das rotas — nada de id exposto

**Aberto em 06/10/2026.** Guarda-chuva para o conjunto de tarefas que muda como a app expõe os seus
objetos nas URLs. Nasce com uma tarefa; outras entram aqui conforme forem mapeadas.

---

## A regra

**Nenhuma rota da app deve exibir id.** Nem para usuário interno. Sempre por um identificador
mascarado (sha), com a rota resolvendo para o id só do lado de dentro.

Isso vale para todas as rotas, não só as de cliente: id sequencial em URL conta quantos objetos
existem, permite varredura e convida a adivinhar o vizinho.

---

## Tarefa 1 — tirar o id das URLs *(era a pendência P8 do refino)*

Hoje a URL mostra o id do banco:

```
/empreendimentos/24
/empreendimentos/ativos/26
```

O **código curto** criado em 05/10 já tirou o id da LISTAGEM (o usuário vê um código opaco de 8
caracteres em vez do id). Falta tirar da **rota**.

**A avaliar quando a tarefa for pega:**

- quem resolve o sha → id, e onde fica o índice (coluna no próprio registro, ou tabela de rotas)
- o sha é estável por objeto (sempre o mesmo) ou rotativo
- o que acontece com links antigos já compartilhados
- rotas internas de API e de arquivo (PDF, XLSX, caderno) entram junto — hoje também carregam id
- o impacto no front, que monta URL em vários lugares

> Não é trabalho de refino. Fica aqui para ser avaliado em bloco, com as outras tarefas de rota.

### Mapeamento — medido em 2026-10-10

**⚠️ O código curto de 05/10 NÃO pode ser o endereço.** Ele é
`sha256(os.urandom(16))[:8]` (`ativo/service.py:codigo_curto`) e é gravado em
**`emp_codigo_interno`** — que no schema é `TEXT` **nullable, sem UNIQUE**, comentado como "código
próprio do tenant". A própria docstring diz: *"colisão não importa: é identificador DO TENANT, não
chave"*. E `service.py:400` deixa o usuário **sobrescrevê-lo** no formulário de edição.

Três consequências, e elas decidem a tarefa:

1. endereço tem de ser **único e imutável**; esse campo é nem um nem outro — o dia em que o usuário
   editar ou apagar o código, a URL morre ou aponta para outro objeto;
2. dois tenants podem ter o mesmo código, então a rota precisaria do tenant junto para desempatar —
   e aí o identificador deixou de ser opaco sozinho;
3. o **ativo não tem nem isso**: `codigo_curto()` só é chamado em `criar_empreendimento`.
   `atv_codigo_interno` existe com a mesma forma frouxa e nunca é preenchido pelo sistema.

**Logo:** a Tarefa 1 precisa de **coluna nova** (`*_rota`, `NOT NULL UNIQUE`, gerada no insert e
nunca editável) ou de tabela de rotas. Reusar o campo do tenant seria pegar um rótulo e usá-lo como
endereço — é a troca que parece economia e cobra depois.

**Superfície real, contada hoje:**

| o que | quanto |
|---|---|
| rotas com id no path, só no módulo de ativo | **79** |
| ocorrências de URL com id montadas no front | **148**, em **26** arquivos |
| rotas que mutam no módulo de ativo (Tarefa 2) | 83 |

O front é a parte caríssima: 148 pontos de montagem. Um helper único de URL **antes** da troca
reduz a 148 a um lugar — e esse helper vale por si, mesmo que o sha demore.

**Links antigos:** com 79 rotas e links já compartilhados por usuários, a transição não pode ser
seca. O caminho é a rota aceitar os DOIS por uma janela (sha novo, id antigo com `301` para a forma
nova), e só depois recusar o id. Isso é decisão de produto, não de código: quem define a janela é
você.

**Ordem que o mapeamento revela:** coluna/endereço → helper de URL no front → rotas → trava
(Tarefa 2). A trava é a ÚLTIMA porque ela lê o objeto *pelo que está na URL*, e é isso que muda.

---

## Tarefa 2 — a trava do arquivamento *(era o item 22 do refino)*

**Arquivamento** é o que libera capacidade de licença:

| estado | ocupa capacidade | edita | histórico |
|---|---|---|---|
| Disponível para trabalho | sim | sim | sim |
| **Arquivado** | **não** | **não** | preservado |

Arquivar e restaurar **não são consumo** e não têm contador. Restaurar só quando houver capacidade.

**O Hub fechou em 06/10** (`a12a4cd` no subrepo de documentação): `capacity` vem no mesmo JWT, os
três endpoints internos existem e `ativo.ativo_produto_status` já está no schema. **O arquivamento
deixou de depender do Hub** e virou o próximo ringue, depois das associações e do ajuste da bancada.

> ⚠ O desenho mudou de forma com o contrato: o slot é por **(ativo, produto)**, não um status único
> do ativo. Duas consequências — `atv_status` não carrega `ARQUIVADO`, e a cascata para cima
> (último ativo arquivado arquiva o empreendimento) perde sentido. **Decisão pendente**, com
> recomendação registrada em `governanca/pendencias.md`, F6, que é
> onde este item passa a morar por inteiro.

### Por que mora aqui, e não solta

A trava precisa impedir QUALQUER escrita num ativo arquivado. Medido na app hoje:

- **83 rotas que mutam** (POST/PUT/PATCH/DELETE) no módulo de ativo
- todas passam por `require_auth` (114) ou `require_licenca_ativa` (87)
- já existe infra de middleware em `app.py` (`DocRateLimitMiddleware` é o precedente)

*Conferido em 2026-10-10:* o precedente existe e está montado (`app.py:130`), então a trava central
é viável como middleware. O que a confirmou como ÚLTIMA da fila foi outra medida: das rotas do
módulo, **79 carregam id no path** — é delas que o middleware tiraria o objeto, e é exatamente essa
forma que a Tarefa 1 troca.

Então **dá para ser central**, sem tocar as 83: um middleware que, no método mutante, descobre de
qual ativo/empreendimento a requisição trata e recusa se estiver arquivado.

**E é por isso que as duas tarefas são a mesma varredura:** o middleware descobre o objeto **pelo
que está na URL** — e a Tarefa 1 muda exatamente isso. Escrever a trava lendo id e depois reescrever
para ler sha é fazer duas vezes.

> Se, ao mapear, ficar claro que a trava resolve inteira dentro de `app.py` sem depender da forma da
> URL, ela se separa e vai sozinha. A decisão sai do mapeamento, não antes dele.
