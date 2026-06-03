# AxySync ← → AxysHub

**Status:** 🟢 Ativa (multi-tenant management)  
**Padrão:** AXYS-ADR-002, AXYS-ADR-003 (licenciamento)

---

## Fluxo de Autenticação

```
1. Usuário inicia AxySync
   ↓
2. AxySync consulta AxysHub
   → "Quais tenants este usuário tem?"
   ↓
3. Hub retorna lista de tenants
   ├─ ACME Corporation
   ├─ XYZ Construções
   └─ Construção Moderna LTDA
   ↓
4. AxySync valida licenciamento
   → "Qual plano Sync tem cada tenant?"
   ↓
5. Se válido → Acesso liberado
```

---

## Identificação de Tenant

Em AxySync, cada operação contábil é feita **por tenant**:

```
GET /api/v1/contasapagar?tenant_uuid=550e8400-...
GET /api/v1/planocontas?tenant_uuid=550e8400-...
POST /api/v1/lancamento {..., tenant_uuid: ...}
```

**Não existe operação sem tenant_uuid.**

---

## Validação de Licensa

AxysHub informa ao Sync:

```json
{
  "tenant_uuid": "550e8400-e29b-41d4-a716-446655440000",
  "tenant_code": "ACME",
  "sync_plan": "pro",
  "sync_features": [
    "contas_pagar",
    "contas_receber",
    "plano_contas",
    "analise_custos",
    "integracao_easy"
  ],
  "valid_until": "2026-12-31"
}
```

**Sync bloqueia operações** se:
- ❌ Licença expirada
- ❌ Tenant inativo em Hub
- ❌ Feature não licenciada

---

## Isolamento de Dados

AxySync opera com **um banco de dados por tenant** ou **schema por tenant**:

### Opção A: Banco Dedicado (Escalável)

```
PostgreSQL Instance
├── axyspro_sync_acme
├── axyspro_sync_xyz
└── axyspro_sync_construcao_moderna
```

### Opção B: Schema Compartilhado (Simples)

```
PostgreSQL Database: axyspro_sync_multi
├── tenant_550e8400.planocontas
├── tenant_550e8400.lancamentos
├── tenant_xyz.planocontas
└── tenant_xyz.lancamentos
```

**Decisão:** Implementar com Schema (Opção B) inicialmente, evoluir para Banco (Opção A) conforme escala.

---

## Graceful Degradation

Se AxysHub fica indisponível:

```
AxySync
  ↓
  Tenta conectar AxysHub
    ↓
    Falha após timeout (5s)
    ↓
    Valida token JWT offline
      ↓
      Se token válido → Permite operação por grace period (24h)
      Se token expirado → Bloqueia com mensagem clara
```

**Regra:** Sem contato com Hub por mais de 24h → bloqueio preventivo (evita uso indevido).

---

## Claims do JWT

Quando AxysHub emite token para Sync:

```json
{
  "sub": "user-uuid",
  "email": "usuario@acme.com",
  "tenant_uuid": "550e8400-e29b-41d4-a716-446655440000",
  "tenant_code": "ACME",
  "sync_role": "contador",  // contador, gerente, diretor
  "sync_features": ["contas_pagar", "contas_receber"],
  "iat": 1622505600,
  "exp": 1622534400  // 8 horas
}
```

**Roles em Sync:**
- `contador` — operações rotineiras, sem aprovações
- `gerente` — aprova lançamentos acima de limite
- `diretor` — acesso total, auditorias
- `leitor` — somente leitura

---

## Auditoria de Acesso

Toda operação em Sync registra:

```sql
INSERT INTO audit.log_operacao (
  usuario_id,
  tenant_uuid,
  tabela_afetada,
  operacao,
  registro_id,
  dados_antes,
  dados_depois,
  criado_em
) VALUES (...)
```

**AxysHub consulta para auditorias legais:**
```
GET /api/v1/audit?tenant_uuid=...&data_inicio=...&data_fim=...
```

---

## Integração com Licenciamento

```
AxysHub (Licensing Server)
   ├─ Define plano Sync por tenant
   ├─ Emite token JWT
   └─ Revoga se não pagou
         ↓
      AxySync
      (valida, bloqueia se necessário)
```

**Fluxo:**
1. Cliente paga fatura → Hub atualiza status
2. Hub emite nova licença assinada
3. Sync recebe nova licença on-demand
4. Sync atualiza features liberadas

---

## Configuração de Ambiente

**Variáveis necessárias em Sync:**

```bash
HUB_URL=https://axys-hub.onrender.com
HUB_PUBLIC_KEY=-----BEGIN PUBLIC KEY-----...
JWT_ALGORITHM=RS256

# Grace period (horas sem contato com Hub)
GRACE_PERIOD_HOURS=24

# Cache de tenants
TENANT_CACHE_TTL_MINUTES=60
```

---

## TODO

- [ ] Implementar refresh automático de token
- [ ] Webhook do Hub para "tenant deactivated"
- [ ] Syncronização de plano de contas (master data)
- [ ] Suportar operação offline com SQLite local

