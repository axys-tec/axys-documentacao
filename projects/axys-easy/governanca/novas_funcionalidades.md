# AxysEasy — Novas funcionalidades

Ideias aprovadas em conceito, **ainda não construídas**. Difere de `pendencias.md`, que guarda dívida
de coisa que já existe. Aqui é o que ainda não existe e um dia deve existir.

---

## Unificação de orçamentos *(registrada em 06/10/2026)*

Hoje o **Agrupamento** é função de ENTREGA: junta na impressão, sem tocar no cálculo. A unificação é
outra coisa — seria estado de PRODUÇÃO, um orçamento novo nascido de vários. Fica aqui como evolução,
não como dívida.

Duas formas, e a diferença está em por onde se junta.

### Forma 1 — Agrupamento em sequência

É a regra que o repath da entrega já aplica: **o ativo vira o nível 1** e tudo dele desce um degrau.
Os ativos entram inteiros, um depois do outro.

```
1.  ATIVO 1
1.1   ETAPA A
1.1.1   SUBETAPA A
1.2   ETAPA B
1.2.1   SUBETAPA B1
1.2.2   SUBETAPA B2
1.2.3   SUBETAPA B3
1.3   ETAPA 3
1.4   ETAPA 4
2.  ATIVO 2
2.1   ETAPA A
2.1.1   SUBETAPA A
...
```

### Forma 2 — Agrupamento por etapas

Junta pela **etapa**, não pelo ativo. O nível 1 passa a ser a etapa com o complemento
**"DO EMPREENDIMENTO"**, e cada ativo aparece sob ela.

```
1.  ETAPA A DO EMPREENDIMENTO
1.1   ETAPA A — ativo 1
1.1.1   SUBETAPA A — ativo 1
1.2   ETAPA A — ativo 2
1.2.1   SUBETAPA A — ativo 2
2.  ETAPA B DO EMPREENDIMENTO
2.1   ETAPA B — ativo 1
2.1.1   SUBETAPA B1 — ativo 1
2.1.2   SUBETAPA B2 — ativo 1
2.1.3   SUBETAPA B3 — ativo 1
2.2   ETAPA B — ativo 2
2.2.1   SUBETAPA B1 — ativo 2
2.2.2   SUBETAPA B2 — ativo 2
2.2.3   SUBETAPA B3 — ativo 2
3.  ETAPA 3 DO EMPREENDIMENTO
3.1   ETAPA 3 — ativo 1
3.2   ETAPA 3 — ativo 2
```

Nas duas formas **tudo desce um nível**. O que muda é o eixo da juntada: o ativo ou a etapa.

> **A definir antes de implementar:** por qual chave duas etapas de ativos diferentes são "a mesma"?
> Pelo nome exato? Pela posição (1ª etapa com 1ª etapa)? Ativos com números de etapas diferentes
> precisam de resposta — e ela muda o resultado.

### Os níveis — RESOLVIDO: trava em 5, para todo mundo

Descer um nível custa um nível. Mas a pergunta certa era de onde vinham os níveis 6 que a medição
acusou — e a resposta derrubou a premissa.

**Os 8 itens de nível 6 em dev são fixtures de teste**, todos nos ativos `ZZ SANIDADE NIVEIS 1-5`
(32 e 33), com nomes como `s5.1` e `novo-S-apos-1.4.5.5.5.3`. **Não existe orçamento real com 6
níveis.** Eu havia lido a medição como "já existe dado assim, endurecer seria retroativo" — era
leitura errada de número certo.

Como passaram: **não existe coluna de nível** — ele é derivado da cadeia de pais. O Tab da bancada
parava no 5, mas `criar_item` e `mover_item` não olhavam profundidade, então quem chamasse a API
direto (como o script de sanidade) furava.

**Decisão de 06/10 (Renan): trava em 5, igual para todo mundo, com ou sem repath.** A bancada é UM
estado; não existe bancada com outra regra. O repath desce um nível no DOCUMENTO — isso é
apresentação, não bancada, e por isso não muda o limite.

Implementado em `orcamento_service.NIVEL_MAX`:

| onde | regra |
|---|---|
| `criar_item` | recusa se o pai já está no nível 5 |
| `mover_item` | recusa se `profundidade(novo pai) + altura(subárvore) > 5` — mover arrasta os filhos |

Profundidade sai do `ati_path` materializado (`001000.000500` → 2), sem CTE recursiva.

Validado contra o banco: criar desce 2→5 e recusa o 6; mover uma subárvore de 2 níveis para dentro
de um nó do nível 4 é recusado ("ficaria com 6"), e mover a folha sozinha passa (4+1=5).

> Fica a dívida de limpar as fixtures `ZZ SANIDADE NIVEIS 1-5` (ativos 32 e 33), que hoje são o
> único dado acima de 5 níveis em dev.

### O que acontece acima do nível 5 (se algum dia passar)

| lugar | comportamento |
|---|---|
| PDF analítico | `min(nivel, 5)` — indenta como nível 5; o número do item continua completo |
| Excel | `fill_nivel` faz o mesmo clamp |
| Cronograma | nível de corte aceita 1–5, então etapa mais funda não entra na grade |

Nada estoura — o que se perde é distinção visual e o corte do cronograma.
