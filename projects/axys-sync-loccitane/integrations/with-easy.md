# AxySync Loccitane ← → AxysEasy

**Status:** 📋 Planejado (não implementado ainda)  
**Caso de Uso:** Integração futura para orçamentos de produtos Loccitane

---

## Visão Futura

Quando Loccitane usar AxysEasy para orçamentos (ex: projetos comerciais, vitrines, eventos), Sync Loccitane fornecerá:

1. **Preços de Custo** — custo real dos produtos
2. **Margens Vigentes** — margem aplicada por categoria
3. **Validação de Preço** — confirmar se preço proposto é viável
4. **Histórico de Custos** — variação de preço ao longo do tempo

---

## Fluxo Esperado

```
Usuário em Easy (Orçamento de vitrine Loccitane)
  │
  ├─ 1️⃣ Seleciona produtos
  ├─ 2️⃣ Easy consulta preço base
  │      GET /api/v1/produtos/preco?
  │          sku_easy=PROD-001&
  │          canal=vitrine_loccitane
  │      ↓
  │      Sync Loccitane retorna:
  │      {
  │        "sku": "PROD-001",
  │        "descricao": "Creme L'Occitane 50ml",
  │        "custo": 15.50,
  │        "margem_padrao": 0.40,
  │        "preco_sugerido": 25.85,
  │        "historico_custo": [
  │          {"data": "2026-01-01", "custo": 15.00},
  │          {"data": "2026-03-01", "custo": 15.30},
  │          {"data": "2026-06-01", "custo": 15.50}
  │        ]
  │      }
  │
  ├─ 3️⃣ Easy propõe preço baseado em custo + margem
  ├─ 4️⃣ Usuário ajusta se necessário
  ├─ 5️⃣ Easy valida com Sync: "Este preço é viável?"
  │      POST /api/v1/validar-preco
  │      {
  │        "sku": "PROD-001",
  │        "preco": 26.00,
  │        "margem": 0.678
  │      }
  │      ↓
  │      Sync retorna:
  │      {
  │        "valido": true,
  │        "margem_alcancada": 0.678,
  │        "vs_padrao": "+16.8%",
  │        "avisos": []
  │      }
  │
  └─ 6️⃣ Easy finaliza orçamento com preço validado
```

---

## Endpoints Necessários

### 1. Obter Preço de Custo

```
GET /api/v1/produtos/preco
?sku=PROD-001
&canal=vitrine_loccitane  (opcional)

Response:
{
  "sku": "PROD-001",
  "descricao": "Creme L'Occitane 50ml",
  "custo_atual": 15.50,
  "margem_padrao": 0.40,  // 40%
  "preco_sugerido": 25.85,  // custo / (1 - margem)
  "ultimo_ajuste": "2026-06-01",
  "vigencia_ate": "2026-09-01"
}
```

### 2. Validar Preço

```
POST /api/v1/validar-preco
{
  "sku": "PROD-001",
  "preco_proposto": 26.00,
  "canal": "vitrine_loccitane"
}

Response:
{
  "valido": true,
  "custo": 15.50,
  "margem_alcancada": 0.678,  // (26-15.5)/26
  "vs_margem_padrao": "+16.8%",
  "avisos": [
    "Margem acima da padrão para esta categoria"
  ],
  "sugestoes": [
    "Confirmar com gerente antes de aplicar"
  ]
}
```

### 3. Histórico de Custos

```
GET /api/v1/produtos/preco/historico
?sku=PROD-001
&data_inicio=2026-01-01
&data_fim=2026-06-30

Response:
{
  "sku": "PROD-001",
  "historico": [
    {
      "data": "2026-01-01",
      "custo": 15.00,
      "motivo": "reajuste_fornecedor"
    },
    {
      "data": "2026-03-01",
      "custo": 15.30,
      "motivo": "cambio_variacao"
    },
    {
      "data": "2026-06-01",
      "custo": 15.50,
      "motivo": "promocao_fim"
    }
  ],
  "variacao_total": "+3.3%",
  "variacao_mes_atual": "+1.3%"
}
```

---

## Tratamento de Erros

### SKU Não Encontrado

```
GET /api/v1/produtos/preco?sku=INEXISTENTE

Response (404):
{
  "erro": "SKU não encontrado",
  "sku": "INEXISTENTE",
  "sugestao": "Verificar código com Loccitane"
}

Easy:
├─ Exibe: "Produto não encontrado em Sync"
└─ Sugestão: "Cadastrar produto em Sync antes"
```

### Canal Não Suportado

```
GET /api/v1/produtos/preco?sku=PROD-001&canal=INVALIDO

Response (400):
{
  "erro": "Canal inválido",
  "canais_validos": [
    "vitrine_loccitane",
    "varejo_online",
    "distribuicao"
  ]
}
```

### Sync Indisponível

```
Easy tenta por 3x com retry.
Se falhar:
├─ Log: erro de conexão
└─ Exibe: "Dados de custos indisponíveis (Sync offline)"
   "Use preço anterior: R$ 25.85"
```

---

## Cache em Easy

```python
# backend/core/loccitane_cache.py

class LoccitaneCache:
    """Cache de custos Sync Loccitane"""
    
    TTL = 3600  # 1 hora
    
    def get_preco(sku, canal=None):
        # Tenta cache
        cached = redis.get(f"loccitane:preco:{sku}:{canal}")
        if cached and not expirado(cached):
            return cached
        
        # Consulta Sync
        dados = requests.get(
            f"{SYNC_URL}/api/v1/produtos/preco",
            params={"sku": sku, "canal": canal},
            headers={"Authorization": f"Bearer {token}"}
        )
        
        # Armazena
        redis.setex(
            f"loccitane:preco:{sku}:{canal}",
            TTL,
            dados.json()
        )
        
        return dados.json()
```

---

## Multicanal (Futuro)

Sync Loccitane pode fornecer preços diferentes por canal:

```
{
  "sku": "PROD-001",
  "canais": {
    "vitrine_loccitane": {
      "custo": 15.50,
      "margem": 0.40,
      "preco": 25.85
    },
    "varejo_online": {
      "custo": 15.50,
      "margem": 0.35,  // margem menor online
      "preco": 23.85
    },
    "distribuicao": {
      "custo": 15.50,
      "margem": 0.15,  // margem mínima
      "preco": 18.24
    }
  }
}
```

---

## Segurança

### Autenticação

Easy usa JWT do Hub:
```
Authorization: Bearer <JWT_usuario>
```

Sync valida:
- Token assinado por Hub
- Usuário pertence a tenant Loccitane
- Usuário tem role `contador` ou superior

### Autorização

- ❌ Usuários sem acesso a Loccitane não veem preços
- ❌ Usuários operacionais não modificam preços
- ✅ Somente admin/gerente pode alterar margem

### Dados Sensíveis

- Preço de custo é **confidencial** (não enviar para cliente)
- Margem é **interna** (não expor em relatório PDF)
- Histórico é **auditável** (rastrear mudanças)

---

## TODO

- [ ] Implementar endpoints em Sync Loccitane
- [ ] Criar testes de integração Easy ↔ Sync
- [ ] Documentar matriz de permissões
- [ ] Webhook de "produto novo em Sync" (notificar Easy)
- [ ] Análise de margem em tempo real (alertas)

