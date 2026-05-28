# AxysDash — Dashboard API Contract (v0)
**Status:** rascunho consolidado (pré-produção)  
**Data:** 2026-02-08  
**Público:** interno Axys (ainda não público)

---

## 0) Princípio fundamental
O **AxysDash** é um **dashboard de bolso**, voltado ao acompanhamento **do dia e do mês corrente**.

Ele **não é** um data warehouse, **não é** ferramenta histórica e **não substitui o ERP**.

> Consequência direta: **dados antigos podem e devem ser descartados**.

Dash ≠ ERP: o Dash não executa operações do ERP e não o substitui.

---

## 1) Arquitetura (visão oficial)

iOS App  
→ HTTPS  
→ AxysHub (Render)  
→ AxysDashDB (Postgres — cache descartável)

O AxysHub:
- recebe dados **push** do ERP/microapp do cliente;
- valida, normaliza e armazena **somente o necessário**;
- expõe **apenas leitura** para o iOS.

Não existe fluxo padrão de *pull* do Hub para o ERP.

---

### 1.1 DashDB (cache m?nimo por feature_code)
- DashDB ? cache descart?vel.
- N?o existem tabelas por dom?nio (vendas/financeiro).
- Persist?ncia ? feita por feature_code em tabela ?nica:
- dash_store_scope (escopo de store)
- dash_summary_day (snapshot di?rio completo)
- dash_ingest_guard (travas/quotas)

---

## 2) Escopo temporal dos dados

### 2.1 Janela ativa
- Apenas **?ltimos N dias** (padr?o 30) s?o mantidos.
- Dias anteriores ? janela **n?o s?o garantidos**.
- N?o existe obriga??o de manter dados hist?ricos.

### 2.2 Pol?tica de descarte
- **Limpeza di?ria por reten??o**:
  - dados com `day_ref` mais antigos que N dias s?o **apagados**;
  - m?dias antigas podem ser descartadas na mesma janela;
  - DashDB mant?m apenas a janela recente.

Isso ? **comportamento esperado**, n?o exce??o.

---

## 3) Base path e versionamento

### 3.1 Base path fixo do app
```
/api/v1/dash
```

### 3.2 Versionamento
- `v0` indica contrato **não público**, sujeito a ajustes.
- Versionamento oficial (`v1`) só ocorrerá quando a API for pública.

---

## 4) Seguranca e autenticacao

### 4.1 Modelo oficial (dual)
O AxysDash suporta dois fluxos:

- Login humano (iOS)
  POST /api/v1/dash/auth/login-user com email e password.
  Retorna access_token Bearer para leitura.

- Client Credentials (ERP/ingest)
  POST /api/v1/dash/auth/login com client_key e client_secret.
  Usado para automacao e ingest.

### 4.2 Headers obrigatorios
Login humano:
```
Authorization: (nao aplicavel)
X-API-Key: (nao exigido)
```

Leitura com token:
```
Authorization: Bearer <access_token>
```

Ingest e login client-credentials:
```
X-API-Key: <api_key>
Authorization: Bearer <access_token>
```

### 4.3 Token
- Token opaco.
- Escopo limitado (dash:read, dash:media).
- Expiracao curta ou media (decisao operacional).

---

## 5) Fluxo operacional (push-only)

Tipos de ingest (controlados por trava):
- `summary_day`: frequente, m?nimo de 5 min entre chamadas por store+feature.

### 5.1 Dia N ? opera??o di?ria
A cada intervalo definido pelo ERP (ex.: 5 minutos):

1) ERP identifica a ?ltima venda conhecida (`last_sale_id` ou equivalente).
2) Se houver mudan?a:
   - envia vendas novas/alteradas;
   - envia produtos/m?dias necess?rias;
3) API valida, reduz e armazena no DashDB.

N?o havendo mudan?a, **nenhuma chamada ? necess?ria**.

---

## 6) Media de produtos

- Não existe URL pública.
- Toda imagem:
  - é reduzida para **≤ 200 KB**;
  - é armazenada apenas para o **mês corrente**;
  - é descartada na virada do mês.

Endpoint:
```
GET /api/v1/dash/media/products/{photo_key}
```
Requer Bearer token. X-API-Key nao e exigido para leitura.

---

## 7) Endpoints oficiais

- `GET  /api/v1/dash/health`
- `POST /api/v1/dash/auth/login` (client credentials)
- `POST /api/v1/dash/auth/login-user` (login humano)
- `GET  /api/v1/dash/auth/me`
- `GET  /api/v1/dash/summary`
- `POST /api/v1/dash/ingest/{feature_code}/summary_day`
- `POST /api/v1/dash/media/ingest/product` (ingest)
- `POST /api/v1/dash/ingest/media/products` (compat)
- `GET  /api/v1/dash/media/products/{photo_key}`

### 7.1 Payload de ingest (resumo)
Os endpoints de ingest recebem um envelope JSON simples:

```json
{
  "tenant_id": "<uuid>",
  "store_id": "<uuid>",
  "feature_code": "sales",
  "ref": "2026-02-06",
  "payload": { "...": "..." },
  "meta": { "anchor": "...", "merge": true }
}
```

- `summary_day` usa `day_ref` (query string) ou `ref` no body.
- `meta.anchor` eh opcional e serve para controle de ingests.
- `meta.merge` (default true) indica se a API deve mesclar com o payload atual.

O iOS **nunca escreve dados**. Ingest é automatizado (ERP/HUB).

Não existem endpoints `/sync/*` neste contrato.

### 7.2 Payload de vendas (summary)
Campos relevantes em `sales` (retorno do GET /api/v1/dash/summary):

- `sale_id`: string
- `date_time`: string no formato `DD/MM/YYYY HH:MM:SS`
- `client_name`: string (opcional)
- `seller_name`: string (opcional)
- `payment_method`: string (opcional)
- `gross_total`, `discount_total`, `net_total`: string formatada em pt-BR
- `items_count`: int
- `items`: lista com `sku`, `mix_code`, `description`, `size`, `quantity`, `unit_price`, `total_price`, `image_url`


---

## 8) Não-objetivos explícitos
O AxysDash **não se propõe** a:
- consultas históricas;
- reconstrução de meses passados;
- auditoria fiscal;
- sincronização reversa com ERP.

Essas funções pertencem ao ERP do cliente.

---

## 9) Regra final
Se houver conflito entre:
- simplicidade operacional  
- retenção excessiva de dados  

👉 **a simplicidade vence**.
