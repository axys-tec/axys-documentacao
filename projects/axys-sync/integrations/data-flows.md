# AxySync — Fluxos de Dados

**Status:** 📊 Mapeado  
**Propósito:** Documentar como dados fluem entre Sync e demais sistemas

---

## Visão Geral

```
┌─────────────┐
│ AxysHub     │ (Control Plane)
│ • tenants   │
│ • usuarios  │
│ • licensas  │
└────┬────────┘
     │
     ├─→ AxySync
     │   • valida tenant
     │   • obtém plano
     │
     ├─→ AxyEasy
     │   • obtém tenant
     │   • valida acesso
     │
     └─→ AxyPro
         • obtém usuario
         • valida role
```

---

## Fluxo 1: Sessão de Usuário

```
┌──────────────────────────────────────────────┐
│ Usuário faz login em qualquer app            │
└──────────────────────────────────────────────┘
            │
            ↓
┌──────────────────────────────────────────────┐
│ AxysHub (autenticação)                       │
│ • valida email + password                    │
│ • emite JWT assinado (RS256)                 │
│ • inclui: sub, email, tenants, roles        │
└──────────────────────────────────────────────┘
            │
            ├─→ Token → Easy (armazena em cookie)
            ├─→ Token → Sync (armazena em localStorage)
            └─→ Token → Pro (armazena em sessionStorage)
```

---

## Fluxo 2: Operação Contábil (Easy → Sync)

```
User em Easy:
┌─────────────────────────────────────────────┐
│ Clica "Ver custos reais de Projeto ACME"    │
└─────────────────────────────────────────────┘
                    │
                    ↓
        Easy (backend/catalogo/routes.py)
        ├─ Extrai tenant_uuid do JWT
        ├─ Extrai projeto_id da requisição
        └─ Monta requisição para Sync
                    │
                    ↓
        Sync (GET /api/v1/custos/projeto)
        ├─ Valida JWT (signature, expiry)
        ├─ Verifica: tenant_uuid correto?
        ├─ Verifica: usuario tem permissao_leitura?
        ├─ Busca lançamentos contábeis:
        │  SELECT SUM(valor) FROM lancamento
        │  WHERE projeto_id = 123
        │  AND tenant_uuid = 550e8400...
        │  AND data BETWEEN ? AND ?
        ├─ Agrupa por fase/categoria
        └─ Retorna JSON
                    │
                    ↓
        Easy (recebe resposta)
        ├─ Armazena em cache (TTL: 1h)
        ├─ Valida estrutura
        └─ Calcula desvio (realizado - orçado)
                    │
                    ↓
        Browser:
        ┌─────────────────────┐
        │ Tabela de Custos    │
        │ • Orçado (Easy)     │
        │ • Realizado (Sync)  │
        │ • Desvio (%)        │
        └─────────────────────┘
```

---

## Fluxo 3: Validação de Nota Fiscal (Easy → Sync)

```
User em Easy:
┌──────────────────────────────┐
│ Upload de NF-e para projeto  │
└──────────────────────────────┘
            │
            ↓
    Easy (módulo: doc/routes.py)
    ├─ Valida arquivo XML
    ├─ Extrai: valor, fornecedor, data
    └─ Chama Sync para validar
            │
            ↓
    Sync (POST /api/v1/validar-lancamento)
    ├─ Valida JWT
    ├─ Verifica limite de valor por categoria
    ├─ Busca orçamento associado
    ├─ Valida: valor está coerente?
    ├─ Busca notas anteriores do mesmo fornecedor
    │  SELECT AVG(valor) FROM lancamento
    │  WHERE fornecedor_id = X AND categoria = Y
    └─ Retorna: OK ou AVISO
            │
            ↓
    Easy (recebe validação)
    ├─ Se OK → aceita nota
    ├─ Se AVISO → pede confirmação do user
    └─ Se ERRO → rejeita
```

---

## Fluxo 4: Sincronização de Plano de Contas (Hub → Sync)

```
Evento: Novo tenant criado no Hub

┌────────────────────────────────┐
│ AxysHub (API)                  │
│ POST /webhooks/sync/novo-tenant│
└────────────────────────────────┘
            │
            ↓
    Sync (webhook receiver)
    ├─ Recebe: tenant_uuid, tenant_code, plano
    ├─ Cria schema para novo tenant
    │  CREATE SCHEMA tenant_550e8400...
    ├─ Executa migrations
    │  01-initial-schema.sql
    │  02-plano-contas-padrao.sql
    ├─ Carrega catálogos padrão
    │  INSERT INTO plano_contas (...)
    │  VALUES ('1000', 'Caixa', ...)
    └─ Registra em audit: "tenant criado"
            │
            ↓
    Sync (status 200 OK para Hub)
    └─ Pronto para receber operações
```

---

## Fluxo 5: Exportação de Dados (Sync → Pro)

```
Evento: Usuário gera relatório financeiro em Pro

┌─────────────────────────────────┐
│ AxysPro (módulo financeiro)      │
│ "Gerar relatório de custos"     │
└─────────────────────────────────┘
            │
            ├─ 1️⃣ Carrega orçamentos de Easy
            │  GET /api/easy/orcamentos?projeto=123
            │
            ├─ 2️⃣ Carrega custos de Sync
            │  GET /api/sync/custos/projeto?projeto=123
            │
            └─ 3️⃣ Consolida em Pro
                SELECT SUM(valor)
                FROM pro.custo_projeto
                WHERE projeto_id = 123
                   │
                   ↓
            Pro (consolidação)
            ├─ Orçado (Easy)     | R$ 1.200.000
            ├─ Realizado (Sync)  | R$ 1.250.000
            ├─ Desvio            | +R$ 50.000 (4.2%)
            └─ Salva em audit_consolidacao
```

---

## Fluxo 6: Auditoria Cruzada (Todos → Central)

```
Evento: Usuário modifica custo no Sync

┌──────────────────────────────────┐
│ Sync (operação)                  │
│ UPDATE lancamento SET valor = X  │
└──────────────────────────────────┘
            │
            ├─ Registra em Sync.audit.log_operacao
            │  {
            │    usuario_id: "user-uuid",
            │    tenant_uuid: "550e8400...",
            │    operacao: "UPDATE",
            │    tabela: "lancamento",
            │    id: 456,
            │    antes: {valor: 1000},
            │    depois: {valor: 1100},
            │    criado_em: "2026-06-01T14:30:00Z"
            │  }
            │
            └─ (Opcional) Envia webhook para Hub
               POST /webhooks/audit/operacao
               {audit_record}
                    │
                    ↓
               Hub (armazena em audit centralizado)
               SELECT COUNT(*) FROM hub.audit_operacao
               WHERE tenant_uuid = "550e8400..."
               ORDER BY criado_em DESC
                    │
                    ↓
               Relatório de auditoria:
               ┌─────────────────────────────────┐
               │ Auditoria de: ACME Corp         │
               │ Período: 01/01 - 30/06/2026    │
               │ • 1.240 operações (Easy)        │
               │ • 856 operações (Sync)          │
               │ • 234 operações (Pro)           │
               │ • 2.330 total                   │
               └─────────────────────────────────┘
```

---

## Fluxo 7: Graceful Degradation (Offline Mode)

```
Cenário: Internet cai

┌────────────────────────────────┐
│ Sync tenta contato com Hub     │
│ POST /health                   │
└────────────────────────────────┘
            │
       FALHA (timeout 5s)
            │
            ↓
    Sync ativa "grace period"
    ├─ Valida JWT offline
    │  (decode com public key localmente)
    ├─ Se token válido → permite operação
    ├─ Se token expirado → bloqueia
    └─ Registra: "modo offline desde 14:30"
            │
            ↓
    Usuário em Sync continua operando
    ├─ Operações não sincronizam com Hub
    ├─ Dados locais são autoridade temporária
    └─ Quando volta internet → sincroniza
            │
            ↓
    Internet volta
    Sync:
    ├─ Detecta contato com Hub restabelecido
    ├─ Sincroniza audit_logs pendentes
    ├─ Valida integridade
    └─ Volta modo normal

    Duration: até 24h (default)
    Após 24h: bloqueia por segurança
```

---

## Fluxo 8: Reparação de Inconsistência

```
Evento: Usuário reporta "custos não batem"

┌─────────────────────────────────────┐
│ Sync (rotina de verificação)        │
│ • Compara: agregações Easy vs Sync  │
│ • Busca lançamentos órfãos          │
│ • Valida integridade referencial    │
└─────────────────────────────────────┘
            │
    Inconsistência detectada:
    • 3 lançamentos sem projeto_id
    • 1 NF com valor negativo
    • 5 entradas sem fornecedor
            │
            ↓
    Sync gera relatório
    ├─ Identifica problema
    ├─ Sugere ação corretiva
    └─ Notifica via webhook Hub
            │
            ↓
    Hub (notifica usuario/admin)
    ├─ Email: "Inconsistências detectadas em ACME"
    ├─ Link: "Clique para revisar"
    └─ Timeout: 7 dias para resolver
            │
            ↓
    Usuario clica em Sync
    └─ Tela: "Revisar lançamentos órfãos"
       ├─ NF-001: valor: -500 (inverter?)
       ├─ NF-045: sem fornecedor (vincular?)
       └─ Botão: [Corrigir Automaticamente]
```

---

## Data Model: Tenant Isolamento

```
Hub Database:
├── tenant (tb_tenant)
│   ├── tenant_uuid (PK)
│   ├── tenant_code
│   ├── plano
│   └── status
│
└── usuario_tenant (junction)
    ├── usuario_id
    ├── tenant_uuid
    └── role (contador, gerente, diretor)

Sync Database (por tenant):
├── plano_contas
│   ├── conta_id (local)
│   ├── categoria
│   └── descricao
│
├── lancamento
│   ├── lancamento_id (local)
│   ├── conta_id (FK)
│   ├── valor
│   ├── projeto_id  ← referência a projeto em Pro/Easy
│   └── criado_em
│
└── audit.log_operacao
    ├── user_id
    ├── operacao
    ├── tabela
    └── criado_em
```

---

## Considerações de Performance

### Caching Strategy

```
Sync
├─ Cache em memória: dados de plano_contas (1h)
├─ Cache em Redis: agregações de custo (1h)
└─ Cache em navegador (Easy): JSON de custos (1h)
```

### Query Optimization

```sql
-- ❌ Sem índice (lento)
SELECT SUM(valor) FROM lancamento
WHERE projeto_id = 123 AND data >= '2026-01-01';

-- ✅ Com índice
CREATE INDEX idx_lancamento_projeto_data
ON lancamento(projeto_id, data);
```

### Connection Pooling

```python
# Sync usa pool de conexões
# Min: 5 conexões
# Max: 20 conexões
# Idle timeout: 5 min

pool = psycopg2.pool.SimpleConnectionPool(5, 20, dsn)
```

---

## TODO

- [ ] Implementar webhook de reparação automática
- [ ] Sincronização de master data (fornecedores, categorias)
- [ ] Replicação leitura (Read Replica) para relatórios
- [ ] Compressão de histórico (archive após 2 anos)

