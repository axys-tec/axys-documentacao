# AxySync ← → AxysEasy

**Status:** 🟢 Ativa (consulta de dados contábeis)  
**Padrão:** AXYS-ADR-020 (integrações)

---

## Casos de Uso

AxysEasy consome dados de AxySync para:

1. **Análise de Custos** — Comparar orçado vs. realizado
2. **Validação de Preços** — Confirmar precificação com custos reais
3. **Relatórios Financeiros** — Custo total de projeto/obra
4. **Integração de Notas Fiscais** — Validar lançamentos contábeis

---

## Arquitetura de Integração

```
AxyEasy
  ├─ Usuário seleciona "Projeto ACME"
  ├─ Easy carrega orçamentos
  └─ Easy consulta Sync:
       GET /api/v1/custos/projeto?
           tenant_uuid=550e8400...
           &projeto_id=123
           &data_inicio=2026-01-01
           &data_fim=2026-06-30
       ↓
       Sync retorna custos reais do período
       ↓
       Easy compara orçado (Easy) vs. realizado (Sync)
```

---

## Endpoints Consumidos por Easy

### 1. Custo Total de Projeto

```
GET /api/v1/custos/projeto
?tenant_uuid=550e8400-...
&projeto_id=123
&data_inicio=2026-01-01
&data_fim=2026-06-30

Response:
{
  "projeto_id": 123,
  "projeto_nome": "Torre Comercial - ACME",
  "tenant_uuid": "550e8400-...",
  "custo_total": 1250000.50,
  "custo_mao_obra": 450000.00,
  "custo_materiais": 650000.00,
  "custo_terceiros": 150000.50,
  "periodo": "2026-01-01 a 2026-06-30",
  "atualizado_em": "2026-06-01T14:30:00Z"
}
```

### 2. Custo por Fase

```
GET /api/v1/custos/projeto/123/fases
?tenant_uuid=550e8400-...

Response:
{
  "fases": [
    {
      "fase_id": 1,
      "fase_nome": "Fundação",
      "custo": 180000.00,
      "percentual": 14.4
    },
    {
      "fase_id": 2,
      "fase_nome": "Estrutura",
      "custo": 520000.00,
      "percentual": 41.6
    }
  ]
}
```

### 3. Custo por Categoria

```
GET /api/v1/custos/projeto/123/categorias
?tenant_uuid=550e8400-...

Response:
{
  "categorias": [
    {
      "categoria": "mao_obra",
      "custo": 450000.00,
      "quantidade_notas": 24
    },
    {
      "categoria": "materiais",
      "custo": 650000.00,
      "quantidade_notas": 156
    }
  ]
}
```

### 4. Validar Lançamento

```
POST /api/v1/validar-lancamento
{
  "tenant_uuid": "550e8400-...",
  "tipo": "nf_entrada",
  "projeto_id": 123,
  "valor": 5000.00,
  "categoria": "materiais",
  "descricao": "Cimento e areia"
}

Response:
{
  "valido": true,
  "avisos": [
    "Valor acima da média de 3500.00 para esta categoria",
    "Não há nota de empenho registrada"
  ],
  "sugestoes": [
    "Confirmar com fornecedor",
    "Verificar se foi pré-aprovado"
  ]
}
```

---

## Fluxo de Integração

### 1. Easy Carrega Projeto

```
AxyEasy
  ├─ Login do usuário
  ├─ Carrega lista de projetos
  └─ Para cada projeto, verifica "tem dados contábeis?"
```

### 2. Easy Consulta Custos em Sync

```
Easy:
  GET /api/v1/custos/projeto?
    tenant_uuid=[do JWT]
    &projeto_id=123

Sync:
  ├─ Valida JWT
  ├─ Valida tenant_uuid
  ├─ Verifica se usuário tem permissão
  ├─ Busca lançamentos contábeis associados ao projeto
  └─ Retorna agregações (total, por fase, por categoria)
```

### 3. Easy Exibe Comparativo

```
Tela em Easy:
┌─────────────────────────────────┐
│ Projeto: Torre ACME             │
├─────────────────────────────────┤
│ Orçado (Easy)      | Realizado (Sync) │
│ R$ 1.200.000       | R$ 1.250.000     │
│ Desvio: +4.2%      | ⚠️ Acima         │
├─────────────────────────────────┤
│ Por Fase:                        │
│ ✓ Fundação: -2.1% (bom)         │
│ ⚠️ Estrutura: +8.3% (alerta)    │
│ ❌ Acabamento: +15% (crítico)   │
└─────────────────────────────────┘
```

---

## Tratamento de Erros

### Token Inválido (401)

```
Easy tenta:
  GET /api/v1/custos/... com JWT

Sync retorna:
  401 Unauthorized
  {
    "erro": "Token inválido ou expirado",
    "acao": "Faça login novamente"
  }

Easy:
  └─ Redireciona para login
```

### Permissão Negada (403)

```
Easy tenta:
  GET /api/v1/custos/projeto/123?tenant_uuid=xyz

Sync valida:
  "Usuário pertence a tenant_xyz?"
  "usuario tem permissão de leitura em Sync?"

Se negado:
  403 Forbidden
  {
    "erro": "Você não tem acesso aos dados deste projeto",
    "tenant": "xyz"
  }

Easy:
  └─ Exibe "Sem acesso a dados contábeis"
```

### Sync Indisponível (503)

```
Easy tenta por 3 vezes com retry exponencial.
Se falhar:
  ├─ Log do erro
  └─ Exibe "Dados contábeis temporariamente indisponíveis"
     (usa cache de 1h se disponível)
```

---

## Cache em Easy

```python
# backend/core/sync_cache.py

class SyncCache:
    """Cache local de dados contábeis consumidos de Sync"""
    
    TTL = 3600  # 1 hora
    
    def get_custos_projeto(tenant_uuid, projeto_id):
        # Tenta cache primeiro
        cached = redis.get(f"sync:custos:{tenant_uuid}:{projeto_id}")
        if cached and not expirado(cached):
            return cached
        
        # Se expirou, consulta Sync
        dados = requests.get(
            f"{SYNC_API_URL}/custos/projeto?...",
            headers={"Authorization": f"Bearer {token}"}
        )
        
        # Armazena em cache
        redis.setex(
            f"sync:custos:{tenant_uuid}:{projeto_id}",
            TTL,
            dados.json()
        )
        
        return dados.json()
```

---

## Multitenancy

Um usuário pode ter acesso a múltiplos tenants:

```
Usuário: João Silva
  ├─ Tenant: ACME (role: contador)
  ├─ Tenant: XYZ (role: leitor)
  └─ Tenant: Moderna (role: gerente)
```

**Easy verifica:** Para cada tenant, qual token JWT usar?

```
# No header de cada requisição a Sync
Authorization: Bearer <JWT_para_tenant_xyz>

# Sync valida:
# "Este JWT é para tenant_xyz?"
# "Este usuário pode ler custos de tenant_xyz?"
```

---

## Segurança

### O que Easy NÃO faz

- ❌ Armazenar credenciais de Sync
- ❌ Fazer bypass de autenticação
- ❌ Modificar dados em Sync (somente leitura)
- ❌ Cache permanente de dados sensíveis

### O que Easy FAZ

- ✅ Usar token JWT do usuário
- ✅ Repassar headers de autorização
- ✅ Cache de curta duração (1h)
- ✅ Registrar acessos em audit

---

## TODO

- [ ] Webhook de Sync para "custo alterado" (invalidar cache)
- [ ] Sincronização automática de lista de projetos
- [ ] Historicidade de custos (gráfico de evolução)
- [ ] Alertas de desvio automático (ex: +10%)

