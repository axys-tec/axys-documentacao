# AxysHub — Tree do Banco (Pre-Foto)

Fonte: `schema_redesign_pre-foto.sql`

```text
axys-hub
├── identity
│   ├── hub_user (cadastro de usuário)
│   ├── hub_tenant (cadastro de tenant)
│   ├── hub_user_tenant  (vinculacao usuario a tenant)
│   ├── hub_store (cadastro de store vinculada a tenant)
│   └── hub_user_store (vinculacao usuario-store-tenant)
├── auth
│   ├── hub_auth_token (token de sessao contextual do hub)
│   ├── hub_api_registry (catalogo de apis integraveis)
│   ├── hub_api_key (chave estatica por tenant)
│   ├── hub_api_client (credencial oauth/app por tenant)
│   └── hub_api_token (token emitido para api client)
├── product
│   ├── ecossistema (agrupador estrategico dos ecossistemas Axys)
│   ├── produto (produto/solucao comercial vendavel)
│   ├── modulo (modulo funcional licenciavel dentro do produto)
│   ├── oferta (forma comercial de vender o produto ou modulo)
│   ├── oferta_concessao (o que a oferta libera em uso, usuario, modulo ou capacidade)
│   ├── oferta_politica (politica operacional/comercial vinculada a oferta)
│   ├── oferta_preco (historico de preco e vigencia da oferta)
│   ├── adicional (capacidade adicional/complemento vendavel do produto)
│   ├── adicional_concessao (o que o adicional libera sobre a oferta/produto base)
│   ├── adicional_preco (historico de preco e vigencia do adicional)
│   ├── combo (agrupamento comercial de ofertas com condicao propria)
│   └── combo_item (item/oferta integrante do combo)
├── commercial
│   ├── partner (cadastro de parceiro/canal comercial)
│   ├── lead (lead comercial antes da conversao)
│   ├── referral_visit (captura de visita por referencia)
│   ├── tenant_attribution (dono comercial do tenant)
│   ├── commission_rule (regra de comissao)
│   ├── commission_event (evento de comissao gerado)
│   └── commission_payout (pagamento/lote de comissao)
├── orders
│   ├── hub_order (pedido/compra do tenant)
│   ├── hub_order_item (snapshot itemizado da venda)
│   └── hub_order_event (evento do ciclo de vida do pedido)
├── billing
│   ├── hub_subscription (assinatura recorrente)
│   ├── hub_subscription_item (item/oferta da assinatura)
│   ├── hub_subscription_period (competencia de cobranca)
│   ├── hub_license (licenca tecnica do produto)
│   ├── hub_license_key (chave criptografica da licenca)
│   ├── hub_license_activation (validacao/ativacao de licenca)
│   ├── hub_user_app (vinculo efetivo usuario-produto)
│   ├── hub_microapp_instance (instancia de produto por tenant)
│   └── hub_microapp_config (configuracao da instancia)
├── gateway
│   ├── provider (provedor de pagamento)
│   ├── payment (transacao de pagamento)
│   ├── payment_event (evento associado ao pagamento)
│   └── webhook_event (webhook bruto recebido)
├── fiscal
│   ├── company_profile (perfil fiscal da emissora)
│   ├── service_profile (parametrizacao fiscal do servico)
│   ├── invoice (nfse consolidada por pedido)
│   ├── invoice_item (item fiscal da nfse)
│   └── invoice_event (evento de emissao/retorno)
└── audit
    ├── audit_log (trilha geral de auditoria)
    ├── login_log (login, logout e troca de conta)
    ├── billing_audit_log (auditoria sensivel de billing)
    └── security_event (evento de seguranca)
```
