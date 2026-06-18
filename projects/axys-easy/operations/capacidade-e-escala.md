# Capacidade e Escala — Easy

Doc **vivo**: mapeia clientes ativos → plano sugerido por serviço no Render. Calibrar com uso
real. Decisão de fundo em [ADR-006](../adrs/EASY-ADR-006-arquitetura-de-jobs-e-escala.md).

> Preços Render (USD/mês, por instância): 512MB=$7 · 2GB=$25 · 4GB=$85 · 8GB=$175 · 16GB=$225 · 32GB=$450.

## Dois eixos de escala

- **App web + `worker-clients`** → crescem com **demanda de cliente** (horizontal/autoscale).
- **`worker-imports`** → cresce com o **tamanho do dataset SINAPI**, não com clientes. Vertical,
  manual, raro (só em OOM de import).

## Faixa sugerida (ilustrativa — recalibrar com dados reais)

| Clientes ativos | App web              | worker-clients       | worker-imports         | ~Custo/mês  |
|-----------------|----------------------|----------------------|------------------------|-------------|
| 0–20 (hoje)     | 512MB → 2GB          | (1 worker faz tudo)  | inclui imports         | ~$25–40     |
| 20–100          | 2GB ×1–2 (autoscale) | 2GB ×1–3             | 2GB                    | ~$90–150    |
| 100–500         | 2GB ×2–4             | 2GB ×2–6             | 4GB                    | ~$250–400   |
| 500+            | 4GB ×N               | 4GB ×N               | 8GB (se SINAPI crescer)| dosar       |

## Banco (Postgres) — eixo próprio, e o gargalo que chega ANTES da RAM

O peso de dados NÃO está na app nem na `core.jobs` (minúscula/purgável) — está no **catálogo
versionado**: ~800k+ linhas por edição SINAPI (≈262k preços de insumo + ≈560k custos de
composição ×3 modalidades ×27 UFs), **mensal** → dezenas de milhões de linhas em poucos anos.
Cresce pelo eixo **dataset**, não por clientes.

| Tranco | Quando | Cura |
|--------|--------|------|
| Conexões esgotadas | **chega primeiro, no autoscale** | **PgBouncer (transaction mode)** — pré-requisito da Fase 3; sem ele, mais instâncias = mais conexões = banco quebra |
| Catálogo (10s de milhões de linhas) | médio prazo | particionar tabelas versionadas por `edi_id` (desenho já é imutável-por-edição) + `DETACH` edições frias → arquivar no R2 |
| Leitura dos clientes | longe | read replica (escrita no primary, consulta de catálogo/orçamento na réplica) |
| `core.jobs` | nunca | task de purge na `maint` (Fase 4): apaga/arquiva jobs terminados > N dias |

**Plano Postgres por faixa** (calibrar): 0–100 clientes → plano base; 100–500 → subir RAM/CPU
+ **ligar o pooler**; 500+ → pooler obrigatório + considerar read replica.

> ⚠️ **Pooler antes do autoscale.** Ligar o autoscale horizontal (Fase 3) SEM PgBouncer
> piora o banco. O pooler é pré-requisito, não otimização posterior.

## Estado atual (2026-06-18)

- **App web:** 512MB (a subir — Eixo demanda).
- **Worker:** Standard 1 CPU / 2GB ($25) — **um worker** servindo todas as filas (`imports,clients,maint`)
  enquanto há ~1 cliente. 512MB foi insuficiente para o import.
- O import SINAPI encosta em 2GB; mitigado por download streaming do R2 (sem ler arquivo
  inteiro em memória) e escrita em lote (`execute_values`).

## Capacity-advisor (Fase 4)

Task `maint` diária: conta tenants/registros ativos, compara com as faixas acima e, ao cruzar
um limiar, **notifica via ZAPI** sugerindo o ajuste. Provisionamento permanece manual.

## Gatilhos de ação

- **OOM no `worker-imports`** → subir um degrau de RAM **só** desse worker (eixo dataset).
- **Latência/fila alta em `clients`** → aumentar `maxInstances` do autoscale (eixo demanda).
- **App web lenta sob carga** → subir plano/instâncias da web.
- **Erros de "too many connections"** → ligar/ajustar o **pooler** ANTES de adicionar instâncias.
- **Query lenta no catálogo** → revisar índice; se for edição antiga, candidata a partição/arquivo.
