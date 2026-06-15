# Licenciamento e Medição de Uso — Interface Hub ↔ Easy

**Status:** POV do Easy para compatibilizar com o Hub (v0) · **Data:** 2026-06-14
**Escopo:** como o Easy **interpreta** o licenciamento e **mede o uso** dos produtos, e o que os
dois lados precisam trocar. Companheiro de `EASY_HUB_ARQUIVAMENTO.md` (offboarding) e
`products/EASY_PRODUTOS.md` (módulos).

> **Fronteira:** o **Hub é dono da regra** (plano, vencimento, renovação, cotas, política). O
> **Easy interpreta o consumo** (o que é "um uso"), faz cumprir o gate na UX e **reporta o uso de
> volta ao Hub com garantia de entrega**. Este documento é o ponto de vista do Easy para o Hub
> alinhar o que assina e o que recebe.

---

## 1. Dois modelos de medição

| Modelo | Produtos | Unidade |
|---|---|---|
| **Contador (consumo)** | Price 1/2, CPU, Orça, Docs, PM, LicitPlan | **N usos / período** |
| **Slot (vaga)** | BuildDiary, FinControl | **N obras ativas / período** |

Planos (iguais para ambos os modelos):
1. **Single-use** — 1 uso (ou 1 slot), janela de até **30 dias**.
2. **Starter** — 5 / mês, **não cumulativo** (renova +5, não soma).
3. **Advanced** — 10 / mês, não cumulativo.
4. **Unlimited** — ilimitado, renovação mensal.

---

## 2. A porteira do uso = DOWNLOAD FINAL  ★ definição central ★

Durante a produção o usuário pode **baixar qualquer arquivo, de qualquer frente**, em dois modos:

- **Download de avaliação (RASCUNHO):** sai com **tarja "RASCUNHO"**. **NÃO conta uso.** Quantos quiser.
- **Download final:** o app exibe a confirmação e, ao confirmar, **consome 1 uso e trava a edição**:

  > *"Ao confirmar, o download será considerado uso efetivo, reduzindo o número de usos disponíveis
  > e impedindo edição. Se necessário editar, ao reabrir, será contado como novo uso no momento do
  > download."*

**Consequências:**
- **Retrabalho NÃO é grátis** — sem isso, um single-use editaria/baixaria infinitamente. Avaliar é
  livre (RASCUNHO); **entregar** custa.
- **Travar = congelar.** Para produtos de orçamento, o download final **coincide com a emissão de
  revisão** (`ativo_revisoes` / snapshot) — alinhado à doutrina "orçamento é estado; emitido vira
  snapshot". Reabrir = novo **ciclo de edição** → o próximo download final = **novo uso**.
- **Idempotência:** o uso é ancorado em **artefato + ciclo de edição**. Re-tentativa do mesmo
  download final (mesmo `evento_id`) **não** cobra de novo; um novo ciclo, sim.

### Estados do artefato
```
EM EDIÇÃO ──(download final, confirma)──▶ FINALIZADO (travado, sem tarja)
   ▲                                            │
   └────────────── reabrir (novo ciclo) ◀───────┘   (próximo final = novo uso)
```

---

## 3. O que é "1 uso" por produto

Regra-mãe: **uso = entrega de valor, contada uma vez no download final, ancorada num artefato.**

| Produto | 1 uso = | Chave idempotente |
|---|---|---|
| **Price 1/2** | 1 orçamento (ativo) finalizado | `ativo_id + ciclo` |
| **CPU** | 1 orçamento importado finalizado | `ativo_id + ciclo` |
| **Orça** | 1 orçamento finalizado/emitido | `ativo_id + ciclo` |
| **Docs** | 1 documento finalizado | `documento_id + ciclo` |
| **PM** | 1 estrutura de projeto finalizada | `estrutura_id + ciclo` |
| **LicitPlan** | 1 plano de licitação finalizado | `processo_id + ciclo` |
| **BuildDiary / FinControl** | 1 obra ativa no período (slot, não download) | `obra_id + período` |

---

## 4. Estados de licença (state machine) — inclui VIEW

O Hub assina um **status por app**; o Easy interpreta:

| Status | Pode | Não pode | Dado |
|---|---|---|---|
| **ACTIVE** | abrir, editar, produzir, **download final** (consome) | — | no banco quente |
| **VIEW_ONLY** (graça pós-contrato) | abrir, **visualizar**, download **RASCUNHO** do que já existe | editar, produzir, download final, novo uso | no banco quente |
| **ARCHIVED** | — (precisa reconstruir) | tudo | foi p/ backup (ver arquivamento) |

> **VIEW_ONLY responde a pergunta do Renan:** licença vencida mas dentro do prazo → o Hub deixa
> entrar **só para ver** (nada ativado). Bom p/ o cliente (vê o que pagou) e gancho de renovação.

---

## 5. Persistência e graça pós-contrato

- **Garantia:** dados ficam no **banco quente por 30 dias após o fim do contrato** (prática: **90
  dias**). Nesse período: status **VIEW_ONLY**, **não** vai para backup.
- Passado o prazo (Hub decide N; ≥30, prática 90) → **desconstrução** para backup
  (`EASY_HUB_ARQUIVAMENTO.md`); status **ARCHIVED**; volta exige **reconstrução**.
- "Voltou para 30 e o cliente perdeu? Problema dele — não renovou." (Regra do Hub.)

---

## 6. Slot (BuildDiary / FinControl) + anti-gaming

- Cota = **obras ativas simultâneas no período**.
- **Anti-rotação:** **1 swap por mês** — terminou uma obra, pode abrir outra (a vaga libera para
  uma troca/mês). Precisa de mais que isso → **compra licença**. (Easy faz cumprir pelo ledger de
  ativação/desativação; os números são política do Hub.)

---

## 7. Interface de dados

**Hub → Easy** (no login e sob consulta; **somente apps `easy-*`**):
```
licencas: [
  { app: "easy-orca", modelo: "contador", plano: "advanced",
    restantes: 7, periodo_fim: "2026-07-01", status: "ACTIVE" },
  { app: "easy-build-diary", modelo: "slot", plano: "starter",
    slots: 5, slots_em_uso: 3, swaps_restantes: 1, periodo_fim: "...", status: "ACTIVE" },
  { app: "easy-docs", plano: "single-use", restantes: 0,
    expira_em: "2026-06-20", status: "VIEW_ONLY" }
]
```
*Prazos:* o Easy **precisa** de `periodo_fim`/`expira_em` — mas **só como snapshot** para UX
("renova/expira em") e gate local. **A verdade da cota é do Hub.**

**Easy → Hub** (ao consumir — **com garantia, padrão outbox**):
1. Easy grava o uso **localmente** (ledger, chave = artefato+ciclo) e libera a entrega.
2. Worker **entrega ao Hub e re-tenta com backoff até ACK** (PENDENTE→ENVIADO→CONFIRMADO; ERRO
   re-tenta). Nunca desiste sem confirmação.
3. Hub **deduplica pela chave** e decrementa; devolve o restante atualizado.
4. No login/periodicamente o Easy **re-sincroniza** o restante (reconciliação).

Tolera queda de rede **sem perder cobrança nem cobrar em dobro**.

---

## 8. Fronteira Pro / Gestor

**Pro e Gestor ficam FORA do snapshot do Easy.** Quando o Easy pergunta "o que há de Easy
liberado?", o Hub responde **só `easy-*`** (Pro/Gestor invisíveis). Não doutrinamos esses produtos
agora — evoluem livres. (Já refletido no código: `apps = [s for s in ... if s.startswith("easy")]`.)

---

## 9. Lado do Easy — esquema proposto (schema `licenca`)

> Espelha o padrão do arquivamento (proposta; DDL fina na implementação).

- **`licenca.uso`** — ledger do consumo: `app`, `tenant_uuid`, `artefato_tipo`, `artefato_id`,
  `ciclo`, `consumido_em`, `consumido_por`, `contexto_json`. **UNIQUE(app, artefato_tipo,
  artefato_id, ciclo)** = idempotência (1 finalização por ciclo).
- **`licenca.uso_outbox`** — entrega confiável: `uso_id`, `status`
  (PENDENTE/ENVIADO/CONFIRMADO/ERRO), `tentativas`, `proxima_tentativa`, `ultimo_erro`,
  `confirmado_em`. Worker drena até CONFIRMADO.
- **`licenca.app_cache`** — snapshot do Hub por app (`plano`, `modelo`, `restantes`/`slots`,
  `swaps_restantes`, `periodo_fim`, `status`, `atualizado_em`) — gate/UX, inclusive offline.
- **Trava do artefato:** derivada do ledger (existe `uso` no ciclo corrente do artefato →
  FINALIZADO). Reabrir = incrementa `ciclo`. (Opcional: flag denormalizada no artefato p/ UI.)

---

## 10. A confirmar com o time do Hub

1. Campos exatos do snapshot por app (§7) e o **endpoint de consulta** (re-sync) + **endpoint de
   report** (idempotente por chave).
2. **N de graça pós-contrato** (≥30, prática 90) — gatilho da desconstrução (cruza com arquivamento).
3. Política de **renovação não-cumulativa** (reset do contador no `periodo_fim`).
4. Semântica de **swap** do slot (1/mês) — Hub guarda a contagem ou confia no Easy?
5. Formato do `status` (ACTIVE/VIEW_ONLY/ARCHIVED) e quem o calcula (Hub, a partir de vencimento).
