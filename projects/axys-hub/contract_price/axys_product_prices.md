# Axys — Tabela de Precos (rascunho de decisao)

Valores direcionais em R$/mes. [prov] = provisorio, falta ancora externa.

PRINCIPIO DA CADEIRA: precificada por CARGA (suporte + dado), nao por assento.
- Lancador de campo (leve, necessario) ......... barato   -> BuildDiary +9,90
- Operador de escritorio (gera suporte) ........ medio    -> Eixo 1 + FinControl +49,90
- Usuario institucional (dado pesadissimo) ..... caro     -> Easy-One +199,90

---

## EIXO 1 — Escada single -> unlimited (unidade = uso/mês)

Todos os produtos deste eixo sao cobrados por uso/mês.

| Categoria        | Price   | CPU   | Docs  | PM     | LicitPlan | Orca     |
|------------------|---------|-------|-------|--------|-----------|----------|
| Single (1 uso/mês)   | 14,90   | 19,90 | 19,90 | 14,90  | 129,90    | 99,90    |
| Starter (2 usos/mês) | 19,90   | 34,90 | 34,90 | 19,90  | 199,90    | 149,90   |
| Advanced (3 usos/mês)| 29,90   | 49,90 | 49,90 | 29,90  | 299,90    | 199,90   |
| Pro (6 usos/mês)     | 59,90   | 69,90 | 69,90 | 59,90  | 399,90    | 299,90   |
| Unlimited (inf)      | 99,90   | 99,90 | 99,90 | 99,90  | 499,90    | 399,90   |
| Cadeira extra*1* | +49,90  | +49,90| +49,90| +49,90 | +49,90    | +49,90   |
| add-ON Price2*2* | +9,90   | -     | -     | -      | -         | —        |

*1* Cadeira so vendavel a partir do plano Pro.
*2* Plug-in do Price. Liga/desliga, evolui v2->v3->v4 como capacidade.
    Excecao de recorrencia: cobrado cheio sempre, sem desconto semestral/anual.
*3* Regra geral de recorrencia: semestral = -R$ 5 por mes e anual = -R$ 10 por mes, aplicados sobre BASE + CADEIRA em todos os produtos desta tabela. A compra e feita sobre o valor total do periodo, com parcelamento em ate 12x no cartao, comprometendo o maior limite no cartao.

---

## EIXO 2 — Obra/contrato ativo (unidade = obras ativas)

| Categoria          | BuildDiary | FinControl | Easy-One |
|--------------------|------------|------------|-------------|
| Single (1 obra/mês)  | 39,90      | 39,90      |             |
| Starter (2 obras/mês)| 59,90      | 59,90      |             |
| Advanced (3 obras/mês)| 99,90     | 99,90      |             |
| Pro (6 obras/mês)    | 199,90     | 199,90     |             |
| Unlimited (inf)    | 299,90     | 299,90     | 1.999,90    |
| Cadeira extra*1*   | +9,90      | +49,90     | +199,90     |

Easy-One = Unlimited de governanca: BuildDiary + FinControl + PM + LicitPlan + Orca,
obras ilimitadas, 5 cadeiras inclusas, conexao do ativo.
Escala: 5 users = 2k | 15 users = ~4k (barato p/ numero alto, dado pesadissimo).
*1* Regra geral de recorrencia: semestral = -R$ 5 por mes e anual = -R$ 10 por mes, aplicados sobre BASE + CADEIRA em todos os produtos desta tabela. A compra e feita sobre o valor total do periodo, com parcelamento em ate 12x no cartao, comprometendo o maior limite no cartao.

---

## REGRA DE RECORRENCIA (licenciamento)

Aplica sobre BASE + CADEIRA em todos os produtos/licenciamentos desta tabela. NAO aplica ao plug-in Price2.
Formula: valor base - R$ X por cadeira-mes.
- Mensal ...... valor cheio
- Semestral ... base - R$ 5  (compra 6 meses, garante faturamento do semestre)
- Anual ....... base - R$ 10 (compra 12 meses, garante faturamento do ano)
- Compra ..... valor total do periodo, com parcelamento em ate 12x no cartao; o limite comprometido e o maior do total da compra

CONTRATO PRICE (exemplo, plano Pro base 59,90):
- Mensal:     59,90/mes
- Semestral:  54,90/mes  -> 54,90 x 6  = 329,40 (vs 359,40 avulso)
- Anual:      49,90/mes  -> 49,90 x 12 = 598,80 (vs 718,80 avulso)
Cadeira extra Pro (49,90) no anual: 39,90 -> mesma regra (-10).
Add-on Price2 (+9,90): cheio em qualquer plano, sem desconto.

---

## Pendencias

1. Definir as faixas de cadastro ativo do Easy-One e os limites objetivos de cada faixa.
