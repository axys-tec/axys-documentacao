# AxySync — Especialização Loccitane

**Status:** 🟢 Produção (especializado)  
**Tipo:** Engine de Contabilidade (para Loccitane)  
**Repositório:** [axys-sync-loccitane](https://github.com/axys-tec/axys-sync-loccitane)

---

## O que é?

AxySync Loccitane é uma **especialização de AxySync** para a operação contábil específica do grupo Loccitane:

- ✅ Base: AxySync (engine contábil padrão)
- ➕ Customizações: Regras específicas de Loccitane
- ➕ Dados: Plano de contas + integração com sistema legado
- ➕ Integração: APIs de parceiros (Varejo Online, etc)

**Diferentemente de AxySync padrão**, Loccitane:
- Lida com múltiplos canais de venda (loja, e-commerce, distribuição)
- Integra com sistema de ponto de venda (VO mapping)
- Validações específicas de varejo
- Relatórios customizados (estoque, margem, etc)

---

## 📁 Documentação

### Local (Este Repositório)
- **Integrations** — Como Loccitane se conecta ao ecossistema

### Remota (Repositório Independente)
Documentação original + dados em: **[axys-sync-loccitane/docs/](https://github.com/axys-tec/axys-sync-loccitane/tree/main/docs)**

```
axys-sync-loccitane/docs/
├── Documentação AxySync (compartilhada com sync/)
├── axys_sync_loccitane_custo_mercadoria_doutrina.md
├── axys_sync_loccitane_expansao_futura_custo_vo.md
├── axys_sync_loccitane_validacao_empirica_saidas.md
├── contas_pagar_receber_vo.txt                   # ⚠️ Precisa estruturar
├── varejonline_api_endpoints.txt                 # ⚠️ Precisa estruturar
└── vo_*.{json,txt}                               # ⚠️ Dados brutos
```

---

## 🔄 Diferenças vs AxySync Padrão

| Aspecto | AxySync | Loccitane |
|---------|---------|-----------|
| **Contexto** | Engenharia/Construção | Varejo/Moda |
| **Canais** | Único | Múltiplos (loja, e-commerce, distribuição) |
| **Integração** | ERP externo | Sistema VO legado |
| **Plano de Contas** | Padrão por construtor | Customizado (Loccitane) |
| **Validações** | Custos de obra | Margens, estoque |
| **Relatórios** | Projeto vs realizado | Vendas, estoque, margem |

---

## 🏗️ Arquitetura

```
┌─────────────────────────────────────────┐
│ AxySync Core (engine contábil)          │
│ • autenticação (Hub)                    │
│ • plano de contas base                  │
│ • lançamentos & auditoria               │
└─────────────────────────────────────────┘
           ↓
┌─────────────────────────────────────────┐
│ Customizações Loccitane                 │
│ • plano de contas estendido             │
│ • validações varejistas                 │
│ • integração VO (point of sale)         │
│ • APIs de parceiros                     │
└─────────────────────────────────────────┘
           ↓
┌─────────────────────────────────────────┐
│ Dados de Loccitane                      │
│ • mapeamento VO → contas                │
│ • regras de provisão de custo           │
│ • validações empíricas                  │
└─────────────────────────────────────────┘
```

---

## 📊 Dados Específicos de Loccitane

### Plano de Contas Estendido

Arquivo: `docs/vo-mapping/plano_contas.json` (estruturado)

**Status:** 🔄 Precisa refatorar de `.txt` → `.json`

```json
{
  "1000": {
    "descricao": "Caixa",
    "tipo": "ativo",
    "categoria": "circulante"
  },
  "2000": {
    "descricao": "Fornecedores",
    "tipo": "passivo",
    "categoria": "circulante"
  },
  "...": {}
}
```

### Mapeamento VO (Varejo Online)

Arquivo: `docs/vo-mapping/vo_mapeamento.json` (estruturado)

**Status:** 🔄 Precisa refatorar de `.txt` → `.json`

```json
{
  "VO_001": {
    "descricao": "Varejo Loja física",
    "contas_integracao": [
      {"conta": "1100", "tipo": "vendas"},
      {"conta": "1200", "tipo": "devolucoes"}
    ]
  },
  "VO_002": {
    "descricao": "E-commerce Loccitane",
    "contas_integracao": [...]
  }
}
```

### Validações Empíricas

Arquivo: `docs/business-rules/validacao_saidas.md` (documentado)

Regras de negócio específicas de Loccitane:
- Margem mínima por categoria
- Limite de desconto por gerente
- Validação de estoque antes de venda
- Detecção de anomalias (venda fora de padrão)

---

## 🔗 Integração com Ecossistema

```
AxyHub (Control Plane)
   ├─ AxySync (Core contábil)
   │  └─ AxySync Loccitane (especialização)
   │
   ├─ AxyEasy (Orçamentos - para futuros projetos)
   │
   └─ Sistema VO Legado (Ponto de venda Loccitane)
      └─ API webhook → Sync Loccitane
```

---

## 🚀 Próximos Passos

### Curto Prazo (Refatoração)
1. **Estruturar dados:** `.txt` → `.json` + `.sql`
2. **Criar schema:** `docs/schemas/` com DDL do plano de contas
3. **Criar migrations:** `docs/schemas/migrations/` para deploy
4. **Documentar APIs:** `docs/integrations/` com endpoints VO

### Médio Prazo (Evolução)
1. Integrar com Varejo Online API
2. Automação de reconciliação (loja vs. contabilidade)
3. Relatórios de margem em tempo real
4. Alertas de anomalias

### Longo Prazo (Consolidação)
1. Unificar com AxyEasy (orçamentos para Loccitane)
2. Integrar com AxyPro (se necessário)
3. Consolidar plano de contas global Axys

---

## 📚 Referências

- **AxySync** — [Documentação base](../axys-sync/README.md)
- **AxyEasy** — [Orçamentos](../axys-easy/README.md)
- **AxysHub** — [Autenticação](../axys-hub/README.md)
- **Foundation** — [Decisões globais](../../foundation/)

---

## ⚠️ Nota Importante

Este diretório ([axys-easy/docs/projects/axys-sync-loccitane/](./)) serve como **bridge de integração** e **planejamento de refatoração**.

A documentação original e os dados brutos estão em: [axys-sync-loccitane](https://github.com/axys-tec/axys-sync-loccitane)

**Ações necessárias:**
1. ✅ Estruturar dados de VO (refatorar)
2. ✅ Criar schema.sql de referência
3. ✅ Documentar APIs de integração
4. ⏳ Implementar automações

