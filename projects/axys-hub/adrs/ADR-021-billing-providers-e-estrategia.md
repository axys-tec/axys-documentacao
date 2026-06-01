# ADR-021 — AxysHub Billing Core: Provedores, Roteamento e Normalização

**Status:** Aprovado  
**Data:** 2026-02-03  
**Stack:** FastAPI (AxysHub)  
**Escopo:** Billing do AxysHub (planos, cobrança, assinaturas, status, webhooks e normalização)

---

## 1. Contexto

O AxysHub é a **fonte da verdade** para governança, licenciamento e monetização do ecossistema Axys.
Para sustentar crescimento, troca de provedores e integração com apps (web e mobile), é necessário
centralizar a lógica de billing no Hub, evitando:

- Acoplamento direto entre app e gateway de pagamento
- Decisões ad-hoc por método ou provedor
- Exposição indevida a requisitos PCI
- Dificuldade de auditoria e rastreabilidade

Este ADR consolida decisões tomadas para o **Billing Core do AxysHub**, definindo provedores,
roteamento, fallback, normalização de eventos e regras de segurança.

> **Regra-mãe:** o AxysHub decide e normaliza; provedores apenas liquidam.

---

## 2. Decisão

Foi decidido implementar um **Billing Core interno ao AxysHub**, baseado em **drivers plugáveis**,
com contrato interno estável e independência de gateway.

### 2.1 Provedores definidos (v1)

- **Plataforma principal:** Pagar.me  
- **Pix principal (avulso por fatura):** Banco Inter  
- **Fallback (Pix, cartão e boleto):** Asaas  

### 2.2 Métodos e estratégia

- **Cartão (mensal/anual):** Pagar.me (checkout embedded)
- **Pix:** Banco Inter (somente cobrança avulsa, não recorrente)
- **Boleto:** Asaas (inicialmente)
- **Fallback automático:** apenas para falhas de infraestrutura

Dados sensíveis de cartão **nunca** transitam ou são armazenados no Hub.

---

## 3. Roteamento e Fallback

### 3.1 Regras de roteamento

- Cartão → Pagar.me (default)
- Pix avulso → Inter
- Boleto → Asaas
- Pix fallback → Asaas
- Cartão fallback → Asaas

### 3.2 Regras de segurança

- Fallback somente para erros de infraestrutura (timeout, 5xx, indisponibilidade)
- **Não** usar fallback automático para cartão recusado
- Evitar duplicidade de cobranças e antifraude

---

## 4. Organização de Código

O Billing Core reside em módulo dedicado:

```
backend/modules/billing/
  billing_routes.py
  billing_service.py
  providers/
    base.py
    pagarme.py
    inter_pix.py
    asaas.py
  models.py
  repository.py
  webhook_normalizer.py
```

Essa separação garante extensibilidade e substituição de provedores sem impacto no app.

---

## 5. Contrato Interno de Billing

### 5.1 Entidades mínimas

- customer (tenant)
- plan
- subscription
- charge
- payment_attempt
- provider_event
- billing_event

### 5.2 Status normalizados

- pending
- paid
- failed
- canceled
- refunded
- chargeback

O estado final **sempre** é confirmado por webhook normalizado.

---

## 6. Webhooks, Normalização e Idempotência

- Todo webhook gera um `BillingEvent` interno
- Eventos são persistidos com payload bruto para auditoria
- Chave idempotente obrigatória: `(provider, event_id)`
- Eventos duplicados são ignorados
- Mudança de estado só ocorre após validação do estado atual

---

## 7. Persistência (mínimo viável)

Tabelas conceituais obrigatórias:

- billing_customers
- billing_plans
- billing_subscriptions
- billing_charges
- billing_payment_attempts
- billing_provider_events
- billing_events

Índices únicos garantem idempotência e rastreabilidade.

---

## 8. Políticas por Método

### 8.1 Cartão
- Checkout embedded
- Confirmação final via webhook
- Recorrência inicial controlada pelo Hub

### 8.2 Pix (Inter)
- Cobrança avulsa com expiração
- Reemissão cria nova charge
- Expiração resulta em cancelamento interno

### 8.3 Boleto
- Emissão via Asaas
- Controle por webhook

---

## 9. Split de Pagamentos

Split **não faz parte do v1**, mas o Hub é a fonte da regra.
O driver apenas executa instruções de split definidas internamente.

---

## 10. Segurança e Segredos

- Chaves via variáveis de ambiente
- Validação de assinatura de webhook quando suportado
- Rate limit em rotas sensíveis
- Logs sem vazamento de PII

---

## 11. Evolução para Recorrência Nativa

A introdução de recorrência nativa de gateway (v2):

- Não invalida este ADR
- Acrescenta novos estados e eventos
- Mantém o Hub como normalizador e controlador de acesso

---

## 12. Consequências

### Positivas
- Desacoplamento total de gateways
- Facilidade de troca de provedor
- Auditoria completa
- Base sólida para monetização

### Negativas
- Implementação inicial mais extensa
- Maior rigor arquitetural

Essas consequências são consideradas **aceitáveis e desejáveis**.

---

## 13. Status Final

Este ADR é **obrigatório** para qualquer implementação de billing no AxysHub.
Alterações estratégicas exigem **novo ADR**, nunca modificação silenciosa.
