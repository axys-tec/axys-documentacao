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

### O problema dos níveis — e o que a medição diz

Descer um nível custa um nível. Orçamento de 5 níveis vira 6; de 6, vira 7.

**Medido no banco de dev em 06/10:**

| nível | itens | ativos |
|---|---|---|
| 1 | 134 | 11 |
| 2 | 473 | 11 |
| 3 | 683 | 9 |
| 4 | 690 | 5 |
| 5 | 10 | 2 |
| **6** | **8** | **2** |

**Já existem orçamentos com 6 níveis.** Então "limitar a 4 e deixar o 5 para o repath" não é
endurecer uma regra: é invalidar dado que está lá. E o repath da entrega já produz nível 7 hoje
(empreendimento 21), sem quebrar nada.

**O que de fato acontece acima do nível 5** — conferido, não suposto:

| lugar | comportamento |
|---|---|
| PDF analítico | `min(nivel, 5)` — indenta como nível 5; o número do item continua completo |
| Excel | `fill_nivel` faz o mesmo clamp |
| Bancada (tela) | o Tab só cria até o nível 5; níveis 6 vieram de outro caminho |
| Cronograma | nível de corte aceita 1–5, então etapa mais funda não entra na grade |

Ou seja: **nada estoura**. O que se perde acima de 5 é distinção visual (a cor de nível repete) e a
possibilidade de cortar o cronograma naquele nível.

**Recomendação para quando a unificação entrar:** não criar bancada excepcional — duplicar regra de
bancada é caro e vira duas verdades. Os caminhos reais são (a) aceitar 6+ níveis e resolver a
apresentação (mais uma cor de nível, corte de cronograma até 6), ou (b) travar a unificação quando
algum ativo de origem já tiver 5 níveis, avisando o usuário em vez de produzir algo torto.
