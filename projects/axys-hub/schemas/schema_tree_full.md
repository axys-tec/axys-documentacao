# AxysHub — Tree do Banco

Fonte: `schema.sql`
Atualizado em: 2026-08-19

```text
axys-hub
├── identity
│   ├── hub_user (identidade global de usuários vinculáveis a produtos e tenants)
│   ├── hub_tenant (unidade canônica de isolamento)
│   ├── hub_tenant_profile (papel macro do tenant por aplicação)
│   ├── hub_user_tenant (vínculo global usuário ↔ tenant)
│   ├── hub_store (unidade operacional do tenant)
│   ├── hub_user_store (escopo opcional usuário ↔ store)
│   └── client_easy_mobile (identidade gratuita e isolada do Easy Mobile)
├── auth
│   ├── hub_auth_token (códigos/tokens contextuais do Hub)
│   ├── hub_api_registry (catálogo de APIs integráveis)
│   ├── hub_api_key (chave estática por tenant)
│   ├── hub_api_client (credencial OAuth/app por tenant)
│   ├── hub_api_token (token emitido para API client)
│   ├── easy_mobile_mfa_challenge (desafios MFA de cadastro e alteração de contato)
│   ├── easy_mobile_auth_code (códigos SSO de uso único da identidade mobile)
│   └── easy_mobile_rate_limit (limites persistentes de cadastro, login e MFA)
├── product
│   ├── ecosystem (agrupador estratégico dos ecossistemas Axys)
│   ├── product (produto ou solução comercializável)
│   ├── module (módulo funcional licenciável)
│   ├── offer (forma comercial de vender produto ou módulo)
│   ├── offer_entitlement (capacidades liberadas pela oferta)
│   ├── offer_policy (política operacional/comercial da oferta)
│   ├── offer_price (histórico de preço e vigência)
│   ├── addon (capacidade adicional comercializável)
│   ├── addon_entitlement (capacidades liberadas pelo adicional)
│   ├── addon_price (histórico de preço do adicional)
│   ├── combo (agrupamento comercial de ofertas)
│   └── combo_item (oferta integrante do combo)
├── analytics
│   ├── provider_config (configuração de provedores de analytics)
│   ├── visitor (identidade anônima de visitante)
│   ├── session (sessão analítica)
│   ├── page_view (visualização de página)
│   ├── event_type (vocabulário de eventos)
│   ├── event (evento analítico público)
│   ├── visitor_identity_link (vínculo visitante ↔ identidade conhecida)
│   └── easy_mobile_event (telemetria append-only do Easy Mobile)
├── commercial
│   ├── partner (parceiro ou canal comercial)
│   ├── lead (lead antes da conversão)
│   ├── referral_visit (visita atribuída a referência)
│   ├── tenant_attribution (responsável comercial pelo tenant)
│   ├── commission_rule (regra de comissão)
│   ├── commission_event (evento gerador de comissão)
│   └── commission_payout (pagamento ou lote de comissão)
├── orders
│   ├── hub_order (pedido ou compra do tenant)
│   ├── hub_order_item (snapshot itemizado da venda)
│   └── hub_order_event (evento do ciclo de vida do pedido)
├── billing
│   ├── hub_subscription (assinatura recorrente)
│   ├── hub_subscription_item (oferta integrante da assinatura)
│   ├── hub_subscription_period (competência de cobrança)
│   ├── hub_license (licença técnica tenant ↔ produto)
│   ├── hub_license_key (chave criptográfica da licença)
│   ├── hub_license_activation (validação da licença por ambiente)
│   ├── hub_user_app (vínculo efetivo usuário ↔ produto)
│   ├── hub_ai_credit_account (saldo de créditos de IA por tenant)
│   ├── hub_ai_credit_ledger (livro-caixa imutável dos créditos de IA)
│   ├── hub_microapp_instance (instância de produto por tenant)
│   └── hub_microapp_config (configuração da instância)
├── gateway
│   ├── provider (provedor de pagamento)
│   ├── payment (transação de pagamento)
│   ├── payment_event (evento associado ao pagamento)
│   └── webhook_event (webhook bruto recebido)
├── fiscal
│   ├── company_profile (perfil fiscal da emissora)
│   ├── service_profile (parametrização fiscal do serviço)
│   ├── invoice (NFS-e consolidada por pedido)
│   ├── invoice_item (item fiscal da NFS-e)
│   └── invoice_event (evento de emissão ou retorno)
└── audit
    ├── audit_log (trilha geral de auditoria)
    ├── login_log (login, logout e troca de conta)
    ├── billing_audit_log (auditoria sensível de billing)
    └── security_event (evento de segurança)
```

## Isolamento da identidade Easy Mobile

`identity.client_easy_mobile` é deliberadamente separada de `identity.hub_user`.
O usuário gratuito não cria tenant, store, licença ou vínculo em `hub_user_tenant`.

Quando houver conversão para cliente de um produto, `client_hub_uuid` registra o vínculo
com `identity.hub_user.user_id`. O cadastro mobile original permanece como origem histórica
da conversão; a identidade canônica contratante passa a ser `hub_user`.

Tabelas auxiliares desse fluxo:

- `auth.easy_mobile_mfa_challenge`: verificação de cadastro e alteração de contato;
- `auth.easy_mobile_auth_code`: código SSO de uso único, sem tenant fictício;
- `auth.easy_mobile_rate_limit`: proteção persistente contra abuso e força bruta;
- `analytics.easy_mobile_event`: eventos append-only, gravados pela role restrita
  `easy_mobile_analytics_writer`.
