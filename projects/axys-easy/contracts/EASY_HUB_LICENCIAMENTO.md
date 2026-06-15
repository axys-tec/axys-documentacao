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
| **Contador (consumo)** | Price 12, CPU, Orça, Docs, PM, LicitPlan | **N usos / período** |
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
| **Price** (`easy-price-1`) | 1 orçamento (ativo) finalizado | `ativo_id + ciclo` |
| **Price 2** (`easy-price-2`) | 1 orçamento (ativo) finalizado | `ativo_id + ciclo` |
| **CPU** | 1 orçamento importado finalizado | `ativo_id + ciclo` |
| **Orça** | 1 orçamento finalizado/emitido | `ativo_id + ciclo` |
| **Docs** | 1 documento finalizado | `documento_id + ciclo` |
| **PM** | 1 estrutura de projeto finalizada | `estrutura_id + ciclo` |
| **LicitPlan** | 1 plano de licitação finalizado | `processo_id + ciclo` |
| **BuildDiary / FinControl** | 1 obra ativa no período (slot, não download) | `obra_id + período` |

---

## 4. Estados de licença (state machine) — inclui VIEW

O Hub assina um **status por app**; o Easy interpreta:

| Status | Entra? | Vê conteúdo? | Produz? | Dado |
|---|---|---|---|---|
| **ACTIVE** | sim | sim (edita) | sim (**download final** consome) | quente |
| **VIEW_ONLY** (graça pós-contrato) | sim | **sim** (leitura + RASCUNHO do que já existe) | não (sem editar/final/novo uso) | quente |
| **ARCHIVED** | **sim** | **não** (conteúdo arquivado, nada exibido) | não | backup |

> **Nenhum status é parede 403.** Em VIEW_ONLY e ARCHIVED o usuário **entra** — muda só o que vê e
> a parte comercial. VIEW_ONLY (licença vencida, dentro da graça): vê o que pagou. ARCHIVED: entra,
> **não vê nada** (já foi p/ backup), e recebe o CTA de desarquivar.

### 4.1 Camada comercial (CTA de renovação/desarquivamento)
Quando **sem licença ativa** (VIEW_ONLY **ou** ARCHIVED) o app exibe o gancho comercial. Em ARCHIVED:

> *"Poxa, você está sem licença ativa e seus projetos foram arquivados. Deseja desarquivá-los?
> Clique aqui para saber mais."*

"Desarquivar" dispara a **reconstrução** (`EASY_HUB_ARQUIVAMENTO.md`). A mesma frase (adaptada) vale na
**graça** (retenção informada 30, real 90) como nudge de renovação, mesmo antes de arquivar.

> **Regra comercial (inegociável):** desarquivamento é **SEMPRE** `cobrança de reconstrução +
> assinatura por 30 dias`. **Nunca reconstrução isolada** (não se paga só para ver e sumir). Ao
> término, o tenant volta a **ACTIVE** por ≥30 dias.

**Fluxo:** user clica o CTA → **Hub** processa a compra (reconstrução + 30d) → Hub chama
`reconstruir(tenant)` no Easy → Easy roda a reconstrução em **Celery** → ao concluir, **callback de
sucesso ao Hub** → Hub **notifica o user** ("reconstruído, acesso liberado") e abre o acesso (ACTIVE).
Detalhe operacional em `EASY_HUB_ARQUIVAMENTO.md` §3.2.

---

## 5. Persistência e graça pós-contrato

Linha do tempo após o fim do contrato:

| Janela | Status (user) | Dado | Pode |
|---|---|---|---|
| **0–30d** (retenção **informada**) | VIEW_ONLY | quente | ver o que pagou + RASCUNHO |
| **30d → avisado** | **ARCHIVED (aviso)** | **ainda quente** (até 90d) | nada (CTA desarquivar §4.1) |
| **90d** (retenção **real**) | ARCHIVED (real) | **vai p/ backup** (desconstrução) | nada (desarquivar = reconstrução) |

- **Aviso × real (otimização de estágio inicial):** no **30º dia** o user é **avisado** que foi
  arquivado (status ARCHIVED + CTA), **mas o dado fica no banco quente até o 90º dia** — ele não sabe
  que ainda não saiu. Isso **evita forçar workers** com poucos clients e torna o desarquivamento
  **instantâneo** nessa janela (o dado está lá). A **desconstrução real** (→ backup) só roda no **90º**.
- **Futuro:** quando a escala pedir, retenção real = informada (ex.: 30 = 30).
- Comercialmente **nada muda**: desarquivar é sempre reconstrução + 30d (§4.1) — mesmo na janela
  30–90 (só o custo operacional é ~zero, pois o dado ainda está quente).
- "Voltou para 30 e o cliente perdeu? Problema dele — não renovou." (Regra do Hub.)

---

## 6. Slot (BuildDiary / FinControl) + anti-gaming

- Cota = **obras ativas simultâneas no período**.
- **Anti-rotação:** **1 swap por mês** — terminou uma obra, pode abrir outra (a vaga libera para
  uma troca/mês). Precisa de mais que isso → **compra licença**. (Easy faz cumprir pelo ledger de
  ativação/desativação; os números são política do Hub.)

---

## 7. Interface de dados (contrato fechado)

### 7.1 Registro canônico de apps (`nome_apps`) — fonte da verdade
O Hub **DEVE** usar exatamente estes `code` (e enviar **somente** `easy-*`). `modelo` é
**derivado pelo Easy** a partir deste registro — o Hub **não** envia `modelo`.

| `code` | abbr | label | modelo |
|---|---|---|---|
| `easy-price-1`     | PR1  | Easy Price          | contador |
| `easy-price-2`     | PR2  | Easy Price 2        | contador |
| `easy-cpu`         | CPU  | Easy CPU            | contador |
| `easy-orca`        | ORÇ  | Easy Orça           | contador |
| `easy-docs`        | DOCS | Easy Docs           | contador |
| `easy-pm`          | PM   | Easy ProjectManager | contador |
| `easy-licit-plan`  | LIC  | Easy LicitPlan      | contador |
| `easy-build-diary` | DIÁ  | Easy BuildDiary     | slot |
| `easy-fin-control` | FIN  | Easy FinControl     | slot |

> ⚠️ Alinhar o stub de dev `_DEV_CLAIMS` (`easy-diary`/`easy-fin`/`easy-licit` estão **errados**) a
> estes códigos canônicos. O Hub real **deve** assinar exatamente os `code` acima.

**Cada variante é um app independente.** `easy-price-1` e `easy-price-2` são **apps separados**
(código/licença próprios) — a diferença é interna (drivers/parâmetros), não estrutural.

**Doutrina de evolução (forward-compat):** todo **produto novo** ou **nova variante** (ex.: um
futuro `easy-price-3` / "Price 2+") **entra AQUI** neste registro, com **a mesma estrutura de
dados** (code/abbr/label/modelo + os campos §7.3/§7.4). **Não se pré-lista produto não lançado** —
o doc só carrega o que existe; ao lançar, registra-se aqui e o padrão se mantém (zero refactor de
interface).

### 7.2 Envelope (Hub → Easy) — no login e sob consulta
```json
{
  "tenant_uuid": "…",
  "emitido_em": "2026-06-14T12:00:00Z",
  "licencas": [ /* itens §7.3/§7.4 — só easy-* */ ]
}
```
- App **ausente** da lista = **não-licenciado** (card em stand-by "assinar").
- App **presente** = licenciado; `status` (§7.5) diz se ACTIVE / VIEW_ONLY / ARCHIVED.

**Campos comuns a todo item:**
| campo | tipo | obs |
|---|---|---|
| `app` | string | `code` canônico (§7.1) |
| `plano` | enum | `single-use` \| `starter` \| `advanced` \| `unlimited` |
| `status` | enum | `ACTIVE` \| `VIEW_ONLY` \| `ARCHIVED` (§7.5) |
| `periodo_inicio` | date | início do período corrente |
| `periodo_fim` | date | renovação (reset **não-cumulativo**); p/ `single-use` = expiração da janela 30d |

### 7.3 Item CONTADOR (Price1/2, CPU, Orça, Docs, PM, LicitPlan)
| campo | tipo | obs |
|---|---|---|
| `cota` | int \| null | usos do período (`single-use`=1; `null` se `unlimited`) |
| `restante` | int \| null | **autoritativo do Hub** na emissão (`null` se `unlimited`) |
```json
{ "app": "easy-orca", "plano": "advanced", "status": "ACTIVE",
  "periodo_inicio": "2026-06-01", "periodo_fim": "2026-07-01",
  "cota": 10, "restante": 7 }
```
Easy mantém contador **local** (`cota − usos confirmados no período`, do ledger) p/ gate ao vivo e
**reconcilia** com `restante` a cada sync.

### 7.4 Item SLOT (BuildDiary, FinControl)
| campo | tipo | obs |
|---|---|---|
| `slots` | int \| null | obras ativas permitidas (`null` se `unlimited`) |
| `swaps_cota` | int | trocas por período (padrão **1**) |
```json
{ "app": "easy-build-diary", "plano": "starter", "status": "ACTIVE",
  "periodo_inicio": "2026-06-01", "periodo_fim": "2026-07-01",
  "slots": 5, "swaps_cota": 1 }
```
`slots_em_uso` e `swaps_restante` são **derivados pelo Easy** (as obras vivem no Easy); o Easy
reporta ativação/desativação ao Hub (mesmo outbox) p/ billing/auditoria.

### 7.5 Status (enum) — quem calcula
O **Hub calcula** a partir de vencimento/graça e assina por app:
`ACTIVE` (full) · `VIEW_ONLY` (graça pós-contrato, §4/§5) · `ARCHIVED` (foi p/ backup, §5).

### 7.6 Easy → Hub — report de uso (com garantia, padrão outbox)
```json
{
  "evento_id": "uuid",                 // idempotência (dedup no Hub)
  "tenant_uuid": "…",
  "app": "easy-orca",
  "tipo": "USO",                       // USO | SLOT_ATIVAR | SLOT_DESATIVAR
  "artefato": { "tipo": "ativo", "id": 123, "ciclo": 2 },
  "ocorrido_em": "2026-06-14T12:34:56Z"
}
```
Fluxo: (1) Easy grava o uso local (ledger, UNIQUE por `app+artefato+ciclo`) e libera a entrega →
(2) worker **entrega e re-tenta com backoff até ACK** (PENDENTE→ENVIADO→CONFIRMADO; ERRO re-tenta,
nunca desiste) → (3) Hub **deduplica por `evento_id`** e decrementa; responde ACK + `restante`
atualizado → (4) Easy **re-sincroniza** no login/periodicamente. **Sem perder cobrança nem cobrar
em dobro.**

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
