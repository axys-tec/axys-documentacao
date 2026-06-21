# Bancada de Cronograma — Contrato de Montagem (Tela de Produção + easy-to-excel)

> **Escopo:** especifica a **tela de produção** do cronograma físico-financeiro — seleção do nível de descida, prazo em meses, montagem do grid de preenchimento — e o **round-trip com o Excel**. Herda a espinha da Bancada de Orçamento: mesma `ativo`, mesma chave estável, mesmo WebSocket, mesma regra TRUNC. Documento irmão de `bancada_orcamento_contrato.md`.
>
> **Princípio que costura tudo:** o cronograma **não é uma segunda árvore** — é uma **projeção temporal da árvore do orçamento**. Ele não inventa itens; ele faseia no tempo o valor de itens que já existem na `ativo_itens`. Tela, Excel e API são três portas para a mesma `cronograma` + `cronograma_itens`.

---

## 1. O que o cronograma é (e o que não é)

```
ativo_itens (a árvore do orçamento — já existe, já resolvida)
       │  o cronograma NÃO duplica isto
       ▼
NÍVEL DE CORTE (o "guarda-chuva": ex. nível 3)
       │  faseia no tempo o valor de cada item NESTE nível
       ▼
cronograma_itens  (item-do-nível × período → % do valor)
       grid:  linhas = itens do nível de corte · colunas = períodos (meses)
```

- O cronograma **depende** do orçamento existir e ter valor resolvido. Sem orçamento, não há o que fasear.
- Ele opera **num nível de corte** (n-1 do detalhamento): se o orçamento desce até o nível 5, o cronograma normalmente faseia no nível 3. Tudo **abaixo** do item de corte segue o padrão dele (não se faseia folha a folha).
- O valor de cada célula é uma **fração (%)** do valor do item naquele período. A soma dos períodos de um item = 100% do valor dele.

---

## 2. A chave estável — o mesmo princípio do orçamento

Cada linha do grid é **um item da árvore** no nível de corte → carrega o **`ati_id`** (a mesma chave do orçamento). Exposta, protegida, fora da área imprimível.

- A linha do cronograma **não é um registro novo de estrutura** — é o `ati_id` de um item que já existe no orçamento, agora com sua distribuição temporal.
- `cronograma_itens` guarda o cruzamento: `cri_ati_id` (qual item) × `cri_periodo` (qual mês) × `cri_percent` (quanto). A chave `(cro_id, ati_id, periodo)` é única.
- Round-trip: a chave garante que "fasear o item 1.2 em 30%/40%/30%" volte do Excel para o item certo — nunca recria, nunca desalinha.

> O cronograma reusa o `ati_id` do orçamento de propósito: é o que faz orçamento e cronograma **conversarem**. Mudou o valor de um item no orçamento? O cronograma daquele item re-resolve (os % continuam, o valor-base muda). Deletou o item? Some do cronograma também (a chave casa).

---

## 3. Montagem — a sequência de produção

A tela monta em quatro passos, nesta ordem:

1. **Seleciona o nível de descida (corte).** O usuário escolhe até que nível o cronograma desce (ex.: nível 3). Isso define **quais itens viram linha** do grid — os itens daquele nível. É o mesmo gesto da bancada de orçamento ("selecionar nível para descer"), aplicado ao cronograma. Grava em `cronograma.cro_nivel_corte`.
2. **Define o prazo.** Prazo total + tamanho do período → nº de períodos. Ex.: prazo 360 dias, período 30 → 12 meses. Grava `cro_prazo_dias`, `cro_periodo_dias`, `cro_num_periodos`.
3. **Monta o grid.** A API gera a matriz: **linhas = itens do nível de corte** (cada um com seu valor resolvido do orçamento), **colunas = períodos** (1..N meses). Células vazias, prontas para preencher.
4. **Preenche os valores.** O usuário distribui, por item, o **% do valor em cada período** (ou o valor absoluto, que o sistema converte em %). Linha a linha, até cada item somar 100%.

> O grid é o produto: itens no eixo vertical, meses no horizontal, % nas células. É a "curva física" da obra — quanto de cada item acontece em cada mês.

---

## 4. O grid — estrutura de colunas

| Col | Campo | Origem | Editável? |
|-----|-------|--------|-----------|
| (chave) | `ati_id` | árvore (orçamento) | não (visível, protegida) |
| Item | numeração `1.2.3` | derivada (render) | não |
| Descrição | resolvida (do orçamento) | não | não |
| Valor | valor resolvido do item | **resolvido** (do orçamento) | não |
| Mês 1..N | `cri_percent` por período | usuário | **sim** |
| Σ % | soma dos períodos do item | derivada | não (deve fechar 100%) |
| Σ R$ | valor × % acumulado | derivada (TRUNC) | não |

Linhas extras (derivadas, não editáveis):
- **Total por período** (coluna): Σ dos valores de todos os itens naquele mês → a parcela mensal da obra.
- **Acumulado** (coluna): soma corrente período a período → a curva-S financeira.

---

## 5. Regras de preenchimento e validação

- **Cada item fecha 100%** entre seus períodos. O sistema sinaliza (não bloqueia de imediato) itens que somam ≠ 100% — é conciliação, não trava (mesma filosofia do resto: mostra a divergência, o usuário decide). Emissão final pode exigir 100%.
- **% ou valor:** o usuário pode digitar o **percentual** ou o **valor absoluto** na célula; o sistema converte para `cri_percent` (a verdade armazenada é sempre o %, para sobreviver à rotação de preço do orçamento).
- **Por que % e não valor fixo:** se o cronograma guardasse valor absoluto, rotacionar a edição/LS/BDI no orçamento (que muda o valor do item) deixaria o cronograma **defasado**. Guardando %, o valor de cada célula **re-resolve** junto com o orçamento. O cronograma acompanha o preço vivo — não congela.
- **TRUNC(2) em cascata** (igual ao orçamento): o valor de cada célula = TRUNC(valor_item × %, 2); os totais somam os já-truncados. Vale nas três portas.

---

## 6. easy-to-excel — ida e volta

### 6.1 Ida (cronograma → Excel)
Exporta o grid no template: **`ati_id`** (chave visível/protegida) + Item + Descrição + Valor (read-only, resolvido) + colunas **Mês 1..N** (editáveis, com o % atual) + totais derivados. A estrutura de linhas vem do nível de corte; o usuário não cria itens no Excel (eles são do orçamento).

### 6.2 Volta (Excel → cronograma)
O parser lê **só o núcleo editável**: `ati_id` + os **% por período**. Valor e descrição são ignorados na volta (re-resolvidos do orçamento). Reconciliação pela chave:

```
para cada linha do Excel:
   ati_id existe no nível de corte?  → atualiza os cri_percent dos períodos
   ati_id não pertence ao corte?     → ignora/sinaliza (não cria item — cronograma não inventa estrutura)
```

> Diferença-chave para o orçamento: no cronograma o Excel **não cria nem deleta itens** — a estrutura é dada pelo orçamento. O Excel do cronograma só **distribui %**. Linha sem `ati_id` válido não vira item novo; vira sinalização.

### 6.3 Idempotência e colisão
Reimportar o mesmo arquivo é idempotente (a chave + período atualizam no lugar). Conflito (tela × Excel no mesmo item/período) resolve por last-write no nível da célula `(ati_id, periodo)`, com evento em `ativo_eventos`.

---

## 7. Tempo real (WebSocket) — herda do orçamento

Mesmo transporte e mesma ambição da bancada de orçamento:
- **MVP:** presença + sync ao vivo + **trava por item** (a linha do item no grid). Vários faseando a mesma obra; cada um vê o do outro; o item em edição trava.
- O WebSocket empurra deltas por **`(ati_id, periodo)`** — atualiza só a célula afetada, não o grid inteiro. A chave estável habilita o sync incremental.
- Tempo real vale para **tela e excel-web**; arquivo `.xlsx` desktop é round-trip discreto.
- Evolução célula-a-célula simultânea (CRDT/OT) adiada conscientemente.

---

## 8. Conversa com o orçamento (a dependência viva)

O cronograma é **escravo do valor** do orçamento, **dono da distribuição** temporal:

| Evento no orçamento | Efeito no cronograma |
|---------------------|----------------------|
| muda qtd/preço de um item | o valor da linha re-resolve; os % permanecem; Σ R$ muda |
| rotaciona edição/LS/BDI | todos os valores re-resolvem; cronograma acompanha (guarda %) |
| deleta um item do nível de corte | a linha some do cronograma (chave casa) |
| adiciona item no nível de corte | nova linha aparece no grid, vazia (a preencher) |
| muda o nível de corte | o grid se remonta no novo nível (re-projeta) |

> É por isso que o cronograma guarda **%** e reusa o **`ati_id`**: as duas decisões juntas fazem o cronograma seguir o orçamento vivo sem defasar e sem duplicar estrutura.

---

## 9. Invariantes (cravados — valem nas três portas)

1. **Cronograma é projeção temporal da árvore**, não uma segunda árvore. Não cria/deleta itens.
2. **Reusa o `ati_id`** do orçamento — exposto, protegido, fora da área imprimível. É o que faz orçamento e cronograma conversarem.
3. **Guarda % (`cri_percent`), não valor absoluto** — para acompanhar o preço vivo do orçamento sob rotação.
4. **Nível de corte (n-1)** define as linhas; abaixo dele segue o guarda-chuva.
5. **Cada item fecha 100%** entre períodos (sinaliza divergência, não trava cedo).
6. **TRUNC(2) em cascata**, nunca ROUND — igual ao orçamento.
7. **Excel do cronograma só distribui %** — não inventa estrutura; linha sem chave válida é sinalização.
8. **WebSocket** com MVP presença + sync + trava por item; delta por `(ati_id, periodo)`.
9. **Reimportar é idempotente**; conflito resolve por célula `(ati_id, periodo)`, nunca arquivo-inteiro.

---

## 10. Decisões em aberto (próxima rodada)

- **Editor visual:** grid puro de % ou Gantt (barras) com o grid por trás? O Gantt é exibição; a verdade é o %.
- **Distribuição assistida:** botão "distribuir linear" (item dividido igualmente nos períodos que ele ocupa) e "puxar curva" (S, frontal, traseira) como atalhos de preenchimento.
- **Período:** sempre mensal (30 dias) ou aceita período livre (quinzenal, semanal)? O schema já tem `cro_periodo_dias`.
- **Validação de emissão:** exigir 100% por item para emitir, ou permitir emitir parcial com aviso?
- **Físico vs financeiro:** o % é o mesmo para físico e financeiro, ou o usuário pode descolar (avanço físico ≠ desembolso)? Decide se `cronograma_itens` ganha um segundo % ou se há dois cronogramas.
- **Template Excel:** uma aba só, ou orçamento + cronograma no mesmo arquivo (abas linkadas pela chave)?
