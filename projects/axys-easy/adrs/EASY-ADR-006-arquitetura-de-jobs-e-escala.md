# ADR-006 — Arquitetura de Jobs Assíncronos e Escala (filas, workers, RLS)

- **Status:** Aceito (alvo) — implementação por fases, ainda não aplicada
- **Data:** 2026-06-18
- **Autor:** Renan + Easy
- **Contexto:** Escala do worker Celery para uso misto admin + clientes (SaaS)
- **Decisão Relacionada a:** ADR-001 (core/módulos/microapps), ADR-004 (licenciamento)

---

## 1. Contexto

Hoje há **5 tasks**, todas no módulo `catalogo` (`import_service.py` + `jobs_async.py`),
numa **fila única** consumida por **um worker `--concurrency=1`** ([render.yaml](../../../../render.yaml)).
O status do job vive **só no Redis** (`AsyncResult`, `result_expires=24h`), sem tabela.

Com a chegada de trabalho de **cliente** (conversões/exports no módulo `ativo`) somado ao
trabalho **admin** (import de fonte-base, geração de caderno), três fraquezas aparecem:

1. tudo numa fila → import pesado pode travar tarefa de cliente (sem isolamento de QoS);
2. status efêmero (some em 24h, não consultável por tenant, sem histórico);
3. memória: o import SINAPI é RAM-bound (Excel grande) e divide o mesmo processo.

Dois sustos reais de prod já documentados: OOM do worker (512MB) e deadlock entre
`publicar` × `importar` na mesma fonte (resolvido com `pg_advisory_xact_lock(fte_id)`).

---

## 2. Forças e Restrições

- microapp (não ERP) — evitar over-engineering;
- single Postgres no Render, tenant vem do SSO (JWT do Hub);
- import de fonte-base ocorre **~1×/mês**, é pesado e às vezes **urgente** (admin resolve na hora);
- período inicial: **1 cliente por ~30 dias** → operar com **um único worker** agora;
- Render escala **horizontalmente** (mais instâncias por alvo de CPU/RAM); **não** engorda RAM
  de uma instância sozinho — vertical é troca manual de plano;
- prioridade de mensagem no broker **Redis** é fraca e **não preempta** task em execução.

---

## 3. Decisão

### 3.1 Isolamento por FILA + worker dedicado (não por prioridade)

Três filas declaradas **no código** (`task_routes`), permanentes:

| Fila | Tasks | Perfil |
|------|-------|--------|
| `imports` | `importar_sinapi`, `importar_cdhu`, `gerar_caderno` | pesado, RAM-bound, baixo volume, admin |
| `clients` | conversões/exports do módulo `ativo` | leve, latência importa, paralelizável |
| `maint` | `reindex_search`, `atualizar_indices`, capacity-advisor | leve, background/cron |

Prioridade **não** é o mecanismo de isolamento: no Redis ela só ordena o que está
esperando e **nunca interrompe** uma task rodando — com `concurrency=1` um import em
curso bloquearia o cliente de qualquer jeito. O isolamento real vem de **workers separados**
rodando em paralelo, com RAM própria. Prioridade fica como luxo opcional **dentro** de `clients`.

### 3.2 Topologia de deploy é configuração, não código

O roteamento (qual fila cada task usa) é fixo no código; **quantos workers e quais filas
cada um consome é só `render.yaml`**. Portanto a evolução é um *flip de ops*, sem refatorar:

- **Hoje (1 cliente):** um worker assina tudo — `celery worker -Q imports,clients,maint -B`.
  É a "porteira única". Mantém `concurrency=1` (import mensal bloqueia brevemente; aceitável).
- **Ao escalar:** quebra em dois serviços — `-Q imports` (gordo, serial, sem autoscale) e
  `-Q clients,maint` (pequeno, autoscale horizontal) — e **beat dedicado** (tira o `-B`).

### 3.3 Ingest desacoplado do processamento (sem cron de import)

Como o import é mensal e às vezes urgente, **não há agendador**: o ingest valida + sobe o
arquivo ao R2 + grava um job `pendente` (resposta imediata); o admin dispara **"processar
agora"** quando quiser. (Beat segue existindo só para `maint`.)

### 3.4 Estado durável em DB (tabela de jobs)

Tabela (ex. `core.jobs`) com `job_id, tenant_id, tipo, fila, estado, payload, progresso,
resultado, erro, agendado_para, criado_em, iniciado_em, terminado_em`. Vira a verdade do
status (sobrevive ao `result_expires`), a fila lógica do ingest→process e o histórico por
tenant. O `AsyncResult` do Redis vira só detalhe de execução em tempo real.

### 3.5 Multi-tenant: `tenant_id` + RLS (FORCE)

Isolamento **lógico reforçado por Row-Level Security**: mesma coluna `tenant_id`, mas o
Postgres impõe o filtro via policy. Numa app que muda rápido, um `WHERE` esquecido não vaza
dados de outro cliente. Requisitos: setar `app.current_tenant` por request **e** por task;
`FORCE ROW LEVEL SECURITY` (o role dono ignora RLS por padrão). Schema/DB-per-tenant ficam
reservados para exigência contratual de isolamento físico.

### 3.6 Escala em dois eixos independentes

- **Eixo dataset** — `worker-imports`. RAM função do **tamanho do Excel SINAPI**, não do nº de
  clientes → vertical, manual, raro (só em OOM).
- **Eixo demanda** — **app web** + `worker-clients`. RAM/instâncias função de clientes ativos
  → horizontal/autoscale + faixa documentada (ver [operations/capacidade-e-escala.md](../operations/capacidade-e-escala.md)).
- **Capacity-advisor:** task `maint` diária conta tenants/registros ativos e, ao cruzar uma
  faixa, **notifica via ZAPI** (já no banco) sugerindo o ajuste de plano. Provisionar segue manual.

### 3.7 Banco (Postgres) — o tranco do dado, separado do compute

O volume de dados está no **catálogo versionado** (~800k+ linhas por edição SINAPI, mensal),
não nos jobs nem nos tenants. Decorrências:

- **Pooler é pré-requisito do autoscale (Fase 3).** Cada instância web/worker abre conexões e o
  Postgres tem limite RÍGIDO por plano. Ligar autoscale horizontal **sem PgBouncer (transaction
  mode)** esgota conexões — mais instâncias pioram o banco. Pooler vem ANTES da Fase 3.
- **Escala do dataset = partição por `edi_id`.** As tabelas versionadas (`insumos_preco`,
  `composicoes_custo`, etc.) são imutáveis-por-edição → particionáveis por edição; edições frias
  viram partições `DETACH`-áveis e arquiváveis no R2 sem tocar nas quentes.
- **`core.jobs` é purgável:** PK `INTEGER` (volume de vida não chega a 2,1 bi) + task de purge na
  `maint` mantém a tabela pequena. Nota: purgar não recicla o `IDENTITY` (a sequence só sobe) —
  `INT` basta pela TAXA de inserts, não pela limpeza.
- Leitura pesada de cliente, bem depois: **read replica**.

---

## 4. Fases de implementação (cada uma deployável e reversível)

| Fase | Entrega |
|------|---------|
| **0** | Tabela `jobs` (`tenant_id`) + estado durável; policies RLS (FORCE) no `schema.sql` |
| **1** | `task_routes`/`task_queues` no `celery_app.py` + worker `-Q imports,clients,maint` (porteira única) — **mudança coordenada código+render.yaml+run_worker.sh; deployar sem import em curso** |
| **2** | `worker-imports` dedicado + botão "processar agora" + ingest→pendente |
| **3** | Autoscale horizontal em app web + `worker-clients` — **pré-requisito: PgBouncer (transaction mode); ligar o pooler ANTES do autoscale** |
| **4** | `capacidade-e-escala.md` + task capacity-advisor via ZAPI |

---

## 5. Consequências

- **Positivas:** QoS isolado (import nunca trava cliente), memória isolada, status durável e
  por-tenant, escala como flip de ops, segurança de tenant garantida pelo banco.
- **Custos:** plumbing de RLS (setar tenant por conexão/task); coordenação no deploy da Fase 1;
  uma tabela e migrations a mais.
- **Não-objetivos:** schema/DB-per-tenant; autoscale do worker de import; provisionamento
  automático de planos (advisor só avisa).
