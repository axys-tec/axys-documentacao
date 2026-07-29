# Main Arquitecture

organization
├── brand
├── brand_revenue
├── group_enterprise
├── partner
├── supplier
├── tenant_store
└── store_secrets

catalog
├── collection
├── product_group
├── product_type
├── product_grade
├── product
└── attachment_type

planning
├── collection_plan
└── collection_plan_item

orders
├── order
├── order_product
└── order_product_grade

purchases
├── purchase
├── purchase_product
└── purchase_product_grade

tickets
├── ticket
├── ticket_debtor_split
├── ticket_attachment
└── ticket_history

royalties
├── royalty_statement
├── royalty_statement_detail
└── royalty_statement_attachment

audit
├── logs
├── login_logs
├── api_logs
├── retention_policy
└── retention_rule


# Schemas Arquitecture

organization
├── brand
│   ├── brand_id (INT)
│   ├── description (TEXT) -- ex: Santa Lolla, Degalls
│   ├── created_at
│   ├── updated_at
│   ├── created_by
│   └── updated_by
│
├── brand_revenue
│   ├── brand_revenue_id (INT)
│   ├── brand_id (INT) -- FK brand
│   ├── description (TEXT) -- ex: {Royalties/Imagem}, {Tx Marketing}
│   ├── created_at
│   ├── updated_at
│   ├── created_by
│   └── updated_by
│
├── group_enterprise
│   ├── group_enterprise_uuid (UUID)
│   ├── enterprise_name (TEXT) -- Nome do grupo/empresa/faturamento
│   ├── brand_id (INT) -- FK brand
│   ├── brand_revenue_id (INT) -- FK brand_revenue (vínculo de destino financeiro)
│   ├── documents_json (JSONB)
│   ├── addresses_json (JSONB)
│   ├── contacts_json (JSONB)
│   ├── created_at
│   ├── updated_at
│   ├── created_by
│   └── updated_by
│   │
│   ├── documents_json example (replicado de supplier/partner)
│   │   {
│   │     "cnpj": "",
│   │     "state_registration": "",
│   │     "municipal_registration": null
│   │   }
│   │
│   ├── addresses_json example
│   │   [
│   │     {
│   │       "type": "comercial",
│   │       "street": "",
│   │       "number": "",
│   │       "complement": null,
│   │       "district": "",
│   │       "city": "",
│   │       "state": "",
│   │       "postal_code": "",
│   │       "country": "BR"
│   │     }
│   │   ]
│   │
│   └── contacts_json example (unificado)
│       {
│         "main_contact": {
│           "name": "Nome do Gestor de Contas",
│           "type": "comercial",
│           "email": "contato@grupo.com",
│           "phone": "+5511999998888"
│         },
│         "other_contacts": []
│       }
│
├── partner
│   ├── partner_uuid
│   ├── partner_name
│   ├── documents_json
│   ├── addresses_json
│   ├── contacts_json
│   ├── created_at
│   ├── updated_at
│   │
│   ├── documents_json example
│   │   {
│   │     "cnpj_or_cpf": "",
│   │     "state_registration": null,
│   │     "municipal_registration": null
│   │   }
│   │
│   ├── addresses_json example
│   │   [
│   │     {
│   │       "type": "comercial",
│   │       "street": "",
│   │       "number": "",
│   │       "complement": null,
│   │       "district": "",
│   │       "city": "",
│   │       "state": "",
│   │       "postal_code": "",
│   │       "country": "BR"
│   │     }
│   │   ]
│   │
│   └── contacts_json example
│       {
│         "main_contact": {
│           "name": "Nome Completo do Representante",
│           "type": "comercial",
│           "email": "contato@representante.com",
│           "phone": "+5511999998888"
│         },
│         "other_contacts": []
│       }
│
├── tenant_store
│   ├── tenant_uuid
│   ├── store_uuid
│   ├── partner_uuid
│   ├── license_active
│   ├── synced_at
│   └── UNIQUE (tenant_uuid, store_uuid, partner_uuid)
│
├── supplier
│   ├── supplier_id
│   ├── legal_name
│   ├── documents_json
│   ├── addresses_json
│   ├── contacts_json
│   ├── metadata_json
│   ├── created_at
│   ├── updated_at
│   │
│   ├── documents_json example
│   │   {
│   │     "cnpj": "",
│   │     "state_registration": "",
│   │     "municipal_registration": null
│   │   }
│   │
│   ├── addresses_json example
│   │   [
│   │     {
│   │       "type": "comercial",
│   │       "street": "",
│   │       "number": "",
│   │       "complement": null,
│   │       "district": "",
│   │       "city": "",
│   │       "state": "",
│   │       "postal_code": "",
│   │       "country": "BR"
│   │     }
│   │   ]
│   │
│   ├── contacts_json example
│   │   {
│   │     "main_contact": {
│   │       "name": "Nome Completo do Contato Principal",
│   │       "type": "comercial",
│   │       "email": "comercial@fornecedor.com",
│   │       "phone": "+5511999998888"
│   │     },
│   │     "other_contacts": [
│   │       {
│   │         "name": "Financeiro",
│   │         "type": "financeiro",
│   │         "email": "financeiro@fornecedor.com",
│   │         "phone": "+551133334444"
│   │       },
│   │       {
│   │         "name": "Setor de Expedição",
│   │         "type": "operacional",
│   │         "email": null,
│   │         "phone": "+551133334445"
│   │       },
│   │       {
│   │         "name": "Carlos Souza (Representante)",
│   │         "type": "representante",
│   │         "email": "carlos@fornecedor.com",
│   │         "phone": "+5511988887777"
│   │       }
│   │     ]
│   │   }
│   │
│   └── metadata_json example
│       {
│         "notes": ""
│       }
│
└── store_secrets
    ├── store_uuid
    ├── secrets_json_encrypted
    ├── updated_at
    └── UNIQUE (store_uuid)

    secrets_json_encrypted example
    {
    "teceo": {
        "api_url": "https://api.exemplo.com",
        "client_id": "store-123",
        "client_secret": "secret-value",
        "access_token": "token-value",
        "refresh_token": "refresh-value"
    },
    "erp": {
        "provider": "bling",
        "api_url": "https://api.bling.com.br",
        "client_id": "client-id",
        "client_secret": "client-secret",
        "access_token": "access-token"
    },
    "sl_connect": {
        "api_key": "api-key",
        "webhook_secret": "webhook-secret"
    }
    }


# Catalog Schemas

catalog
├── collection
│   ├── collection_id
│   ├── brand_id
│   ├── description
│   ├── season
│   ├── created_at
│   ├── updated_at
│   └── Season
│       ├── VERAO
│       ├── OUTONO
│       ├── INVERNO
│       └── PRIMAVERA
│
├── product_group
│   ├── product_group_id
│   ├── description
│   ├── created_at
│   ├── updated_at
│   └── Seed
│       ├── Calçados
│       ├── Bolsas
│       └── Carteiras
│
├── product_type
│   ├── product_type_id
│   ├── product_group_id
│   ├── description
│   ├── created_at
│   ├── updated_at
│   └── Seed
│       ├── Anabela
│       ├── Bolsa
│       ├── Boneca
│       ├── Bota
│       ├── Carteira
│       ├── Clutch
│       ├── Espadrilhe
│       ├── Flip Flop
│       ├── Mala
│       ├── Mocassim
│       ├── Mochila
│       ├── Mule
│       ├── Necessaire
│       ├── Overknee
│       ├── Papete
│       ├── Peep Toe
│       ├── Plataforma
│       ├── Porta Cartão
│       ├── Porta Passaporte
│       ├── Rasteira
│       ├── Sandália
│       ├── Sapatilha
│       ├── Scarpin
│       ├── Shopper
│       ├── Slide
│       ├── Slip On
│       ├── Tênis
│       └── Tote
│
├── product_grade
│   ├── product_grade_id
│   ├── description
│   ├── created_at
│   ├── updated_at
│   └── Seed
│       ├── 34
│       ├── 35
│       ├── 36
│       ├── 37
│       ├── 38
│       ├── 39
│       ├── 40
│       ├── 33/4
│       ├── 34/5
│       ├── 35/6
│       ├── 36/7
│       ├── 37/8
│       ├── 38/9
│       ├── 39/0
│       ├── 40/1
│       └── PC
│
└── product
    ├── product_id
    ├── brand_id
    ├── product_group_id
    ├── product_type_id
    ├── product_grade_id
    ├── sku
    ├── description
    ├── product_main_photo_path
    ├── product_photos_path
    ├── created_at
    ├── updated_at
    ├── UNIQUE (brand_id, sku)
    │
    ├── product_main_photo_path example
    │   products/santa-lolla/0008.01D3.0010.0001/main.webp
    │
    ├── product_photos_path example
    │   [
    │     {
    │       "path": "products/santa-lolla/0008.01D3.0010.0001/photo-01.webp",
    │       "position": 1
    │     },
    │     {
    │       "path": "products/santa-lolla/0008.01D3.0010.0001/photo-02.webp",
    │       "position": 2
    │     }
    │   ]
    │
    └── Observações
        ├── product_variant permanece fora do MVP
        ├── SKU identifica o produto comercial dentro da marca
        └── A relação Product × Collection será definida posteriormente

├── attachment_type
│   ├── attachment_type_id (INT)
│   ├── name (TEXT) -- ex: NFe, NFSe, CTE, Ficha de Royalties, Ficha de Tickets, Comprovante, E-mail, Boleto, Documento de Cobrança, Comprovante de Recusa, Outro
│   ├── code (TEXT) -- ex: NFE, NFSE, CTE, FICHA_ROYALTIES, FICHA_TICKETS, COMPROVANTE, EMAIL, BOLETO, COBRANCA, RECUSA, OUTRO
│   ├── created_at
│   ├── updated_at
│   └── Seed
│       ├── NFe (NFE)
│       ├── NFSe (NFSE)
│       ├── CTe (CTE) -- Comprovante de Transporte Eletrônico
│       ├── Ficha de Royalties (FICHA_ROYALTIES)
│       ├── Ficha de Tickets (FICHA_TICKETS)
│       ├── Comprovante (COMPROVANTE)
│       ├── E-mail (EMAIL)
│       ├── Boleto (BOLETO)
│       ├── Documento de Cobrança (COBRANCA)
│       ├── Comprovante de Recusa (RECUSA)
│       └── Outro (OUTRO)


# Orders, Purchases, Tickets and Royalties Schemas

orders
├── order
│   ├── order_id (BIGINT)
│   ├── store_uuid
│   ├── supplier_id
│   ├── collection_id
│   ├── order_number (TEXT)
│   ├── total_qty (INTEGER)
│   ├── total_amount (NUMERIC)
│   ├── status (TEXT)  -- ex: RASCUNHO, APROVADO, FATURADO, CANCELADO
│   ├── created_at
│   ├── updated_at
│   ├── created_by
│   └── updated_by
│
├── order_product
│   ├── order_product_id (BIGINT)
│   ├── order_id (BIGINT)
│   ├── product_id
│   ├── sell_in_unit_price (NUMERIC)
│   ├── sell_in_total_amount (NUMERIC)
│   ├── sell_out_unit_price (NUMERIC, NULL)
│   ├── sell_out_total_amount (NUMERIC, NULL)
│   ├── total_qty (INTEGER)
│   ├── created_at
│   ├── updated_at
│   ├── created_by
│   └── updated_by
│
└── order_product_grade
    ├── order_product_grade_id (BIGINT)
    ├── order_product_id (BIGINT)
    ├── grade_size (TEXT)  -- ex: 35, 36
    ├── quantity (INTEGER)
    ├── created_at
    ├── updated_at
    ├── created_by
    └── updated_by

purchases
├── purchase
│   ├── purchase_id (BIGINT)
│   ├── store_uuid
│   ├── supplier_id
│   ├── collection_id
│   ├── purchase_number (TEXT) -- número da Nota Fiscal
│   ├── purchase_nfe_key (TEXT) -- chave técnica da NFe
│   ├── total_amount_supplier (NUMERIC)
│   ├── total_amount_royalties (NUMERIC)
│   ├── total_amount_marketing (NUMERIC)
│   ├── total_amount (NUMERIC) -- valor total final da compra
│   ├── purchase_status (TEXT)
│   │   -- Status do Recebimento/Revisão da Nota:
│   │   -- LANCADO: XML da NF importado e revisado para audit
│   │   -- RECEBIDO: NF conferida física/comercialmente; royalties associados viram DEVIDOS
│   │   -- RECUSADO: NF devolvida ou recusada; royalties associados viram INDEVIDOS
│   │   -- NAO_RECEBIDO: Problema de logística/extravio; royalties associados viram INDEVIDOS
│   ├── created_at
│   ├── updated_at
│   ├── created_by
│   └── updated_by
│
├── purchase_product
│   ├── purchase_product_id (BIGINT)
│   ├── purchase_id (BIGINT)
│   ├── product_id
│   ├── unit_price (NUMERIC)
│   ├── total_qty (INTEGER)
│   ├── total_amount (NUMERIC)
│   ├── created_at
│   ├── updated_at
│   ├── created_by
│   └── updated_by
│
└── purchase_product_grade
    ├── purchase_product_grade_id (BIGINT)
    ├── purchase_product_id (BIGINT)
    ├── grade_size (TEXT)
    ├── quantity (INTEGER)
    ├── created_at
    ├── updated_at
    ├── created_by
    └── updated_by


tickets
├── ticket
│   ├── ticket_id (BIGINT)
│   ├── store_uuid
│   ├── ticket_number (TEXT) -- número usado pela app externa
│   ├── ticket_type (TEXT) -- tipos vindos do LunalôSys (ex: Price - Erro NF, Supply - Divergência NF, etc)
│   ├── purchase_id (BIGINT, NULL) -- opcional, FK direta p/ NF de compra
│   ├── order_id (BIGINT, NULL) -- opcional, FK direta p/ Pedido de origem (evitando perdas de desempenho e facilitando joins diretos)
│   ├── ticket_status (TEXT) -- LANCADO, DEVIDO, CONVERTIDO, RECUSADO, PAGO
│   ├── total_amount_claimed (NUMERIC) -- soma total reclamada/reivindicada no ticket
│   ├── total_amount_approved (NUMERIC) -- soma total aprovada para abatimento
│   ├── created_at
│   ├── updated_at
│   ├── created_by
│   └── updated_by
│
├── ticket_debtor_split
│   ├── ticket_debtor_split_id (BIGINT)
│   ├── ticket_id (BIGINT)
│   ├── brand_revenue_id (INT, NULL) -- se preenchido, mapeia se o split é da receita de Royalties ou Imagem/Marketing
│   ├── group_enterprise_uuid (UUID, NULL) -- opcional, FK direta p/ o faturamento corporativo de destino da marca devedora
│   ├── debtor_type (TEXT) -- ex: "FORNECEDOR", "FRANQUIA_ROYALTIES", "FRANQUIA_MARKETING"
│   ├── amount_claimed (NUMERIC)
│   ├── amount_approved (NUMERIC)
│   ├── split_status (TEXT) -- LANCADO, DEVIDO, RECUSADO, PAGO/ABATIDO
│   ├── created_at
│   ├── updated_at
│   ├── created_by
│   └── updated_by
│
├── ticket_attachment
│   ├── ticket_attachment_id (BIGINT)
│   ├── ticket_id (BIGINT)
│   ├── attachment_path (TEXT) -- arquivo no bucket (ex: comprovante de avaria, e-mail de aprovação)
│   ├── filename (TEXT)
│   ├── created_at
│   └── created_by
│
└── ticket_history
    ├── ticket_history_id (BIGINT)
    ├── ticket_id (BIGINT)
    ├── action (TEXT)
    ├── description (TEXT)
    ├── created_at
    └── created_by

royalties
├── royalty_statement
│   ├── royalty_statement_id (BIGINT)
│   ├── store_uuid
│   ├── collection_id
│   ├── group_enterprise_uuid (UUID) -- vincula qual empresa/faturamento corporativo de destino dessa folha de royalty
│   ├── brand_revenue_id (INT) -- vincula se essa folha é da receita de Royalties/Imagem ou se é da Taxa de Marketing
│   ├── statement_number (TEXT) -- ficha mensal de cobrança de royalties/mkt
│   ├── base_calculation_amount (NUMERIC) -- base de cálculo calculada pelas NFs de compra
│   ├── total_royalties_amount (NUMERIC) -- valor bruto total devido para royalties (ex: 6.5% ou de acordo com taxa)
│   ├── total_marketing_amount (NUMERIC) -- valor bruto total devido para marketing (ex: 3.5% ou de acordo com taxa)
│   ├── total_deduction_amount (NUMERIC) -- base de abatimentos acumulados via tickets (ticket_debtor_split aprovados)
│   ├── net_amount_due (NUMERIC) -- valor líquido final esperado para pagamento
│   ├── statement_status (TEXT) -- PREVISTO, DEVIDO, FATURADO, PAGO, CANCELADO
│   ├── due_date (DATE)
│   ├── payment_date (DATE, NULL)
│   ├── created_at
│   ├── updated_at
│   ├── created_by
│   └── updated_by
│
├── royalty_statement_detail
│   ├── royalty_statement_detail_id (BIGINT)
│   ├── royalty_statement_id (BIGINT)
│   ├── purchase_id (BIGINT) -- amarra a NF de compra de origem ao faturamento mensal de royalties
│   ├── calculated_royalties_amount (NUMERIC)
│   ├── calculated_marketing_amount (NUMERIC)
│   ├── created_at
│   ├── updated_at
│   ├── created_by
│   └── updated_by
│
└── royalty_statement_attachment
    ├── royalty_statement_attachment_id (BIGINT)
    ├── royalty_statement_id (BIGINT)
    ├── attachment_path (TEXT) -- arquivo da ficha e comprovante de pgto
    ├── filename (TEXT)
    ├── created_at
    └── created_by


audit
├── retention_policy
│   ├── retention_policy_id (INTEGER)
│   ├── description (TEXT) -- ex: Permanente, 90 dias, 365 dias, etc
│   ├── is_permanent (BOOLEAN)
│   └── retention_days (INTEGER)
│
├── retention_rule
│   ├── retention_rule_id (INTEGER)
│   ├── schema_name (TEXT)
│   ├── table_name (TEXT)
│   └── retention_policy_id (INTEGER) -- FK retention_policy
│
├── logs
│   ├── log_id (BIGINT)
│   ├── log_schema (TEXT)
│   ├── log_table (TEXT)
│   ├── log_record_id (TEXT)
│   ├── log_action (TEXT) -- INSERCAO, ATUALIZACAO, EXCLUSAO
│   ├── log_user (TEXT)
│   ├── log_ip (TEXT)
│   ├── log_before_data (JSONB)
│   ├── log_after_data (JSONB)
│   └── log_created_at (TIMESTAMPTZ)
│
├── login_logs
│   ├── log_id (BIGINT)
│   ├── log_user_id (TEXT)
│   ├── log_email (TEXT)
│   ├── log_name (TEXT)
│   ├── log_tenant_id (TEXT)
│   ├── log_action (TEXT) -- ENTRADA, SAIDA, FALHA_AUTENTICACAO
│   ├── log_origin (TEXT) -- LOCAL, SSO, GOV_BR, APPLE, GOOGLE, CHAVE_API
│   ├── log_ip (TEXT)
│   ├── log_user_agent (TEXT)
│   ├── log_details (JSONB)
│   └── log_created_at (TIMESTAMPTZ)
│
└── api_logs
    ├── log_id (BIGINT)
    ├── log_method (TEXT) -- POST, PUT, PATCH, DELETE (somente escritas de API)
    ├── log_endpoint (TEXT)
    ├── log_status (SMALLINT)
    ├── log_client (TEXT)
    ├── log_user (TEXT)
    ├── log_ip (TEXT)
    ├── log_request_body (JSONB)
    ├── log_duration_ms (INTEGER)
    └── log_created_at (TIMESTAMPTZ)


# Premissas do Ecossistema, SaaS e Evolução

A aplicação **AxysGestorSL** é uma solução **SaaS de Gestão Integrada** para lojas e franquias que operam em parceria com o grupo **Santa Lolla**. No escopo atual, a plataforma resolve de forma canônica e unificada o **controle de pedidos**, **controle de compras**, **controle de tickets (contestações)** e o **controle e conciliação de royalties**. 

### Planeamento de Evoluções (Provisionadas de Antemão)
- **Planejamento de Compras/Coleções**: Mapeamento, projeção orçamentária e direcionamento estratégico de mix de compras focado.
- **Integrações de API (ERP Stores > AxysGestorSL)**: Sink automático e robusto de entradas de NF, vendas e cadastros oriundos dos sistemas de frente diretamente para a plataforma de gestão.
- **Integrações com Ferramentas do Ecossistema**: Provisionar a comunicação direta bidirecional via API entre `AxysGestorSL` e serviços satélites da franqueadora (Ex: MultiREP, QualidadeWEB, TECEO, entre outros).

### Grupos de Clientes (SaaS Clients)
- **Grupo 1) Lojas que operam com a SL**: O lojista propriamente dito, que utiliza a plataforma de forma operacional para auditar faturamentos, enviar tíquetes de divergência, confrontar cobranças e visualizar a saúde de seus pedidos e notas recebidas.
- **Grupo 2) Representantes que representam a SL**: Perfil de agente operando na evolução de planejamento da coleção, auxiliando a orientar as compras do mix ideal, fechar pedidos e direcionar metas por parceiro/loja.
- **Grupo 3) SL Brand (A evolução / pico)**: A própria marca franqueadora (Santa Lolla). O objetivo é potencializar as vendas das filiais, dar visibilidade transparente do andamento de pedidos aos lojistas, estreitar e melhorar o traquejo de cobrança de taxas e reduzir perdas financeiras no fluxo de ponta a ponta.


# Observações de Evolução, Auditoria e Regras de Negócio

1. **Escopo Focado**:
   - A operação de calçados (grades de tamanhos) é o foco central deste escopo arquitetural. Toda a documentação e modelagem se aplicam exclusivamente ao ecossistema da **Lunalô / Santa Lolla**.

2. **Auditoria Geral unificada**:
   - Todas as tabelas do ecossistema, onde aplicável, possuem colunas de auditoria nativas: `created_at`, `updated_at`, `created_by` e `updated_by`. A propriedade `created_by` e `updated_by` registra qual UUID de usuário/partner realizou a alteração.

3. **Chaves Primárias e Vinculação de Lojas/Parceiros/Tenants**:
   - Chaves primárias de tabelas transacionais usam `BIGINT` para garantir escalabilidade.
   - Tabelas transacionais como `order`, `purchase`, `ticket` e `royalty_statement` gravam prioritariamente o **`store_uuid`**. A vinculação do `tenant_uuid` e do `partner_uuid` (o representante de vendas que acessa a aplicação) é resolvida via join natural em banco de dados usando a tabela ponte `tenant_store`, evitando replicação desnecessária e redundância de chaves nas tabelas de negócio transacionais.

4. **Multiplicidade de Devedores nos Tickets (Debt Splits)**:
   - Para suportar até 3 devedores e destinatários distintos de repasse e abatimentos, introduziu-se a tabela `ticket_debtor_split`.
   - Um único `ticket` pode ter splits distribuídos entre:
     - **FORNECEDOR**: custo físico de mercadoria repassado ao fornecedor.
     - **FRANQUIA_ROYALTIES**: abatimento de taxas de royalties com a franqueadora (Santa Lolla).
     - **FRANQUIA_MARKETING**: abatimento de taxas de propaganda/imagem com a franqueadora (Santa Lolla).
   - Isso garante uma perfeita integridade financeira na conciliação, uma vez que estas entidades faturam e efetuam cobranças de formas e termos independentes.
   - Os splits de devedor agora amparam chaves estrangeiras opcionais p/ `brand_revenue_id` e `group_enterprise_uuid`, facilitando saber se o crédito deve ser descontado em faturamento corporativo consolidado específico ou lançado contra receitas segregadas de Royalties ou Imagem/Marketing.

5. **Evolução de Margens e Separação de Royalties / Imagem / Marketing**:
   - *Ressalva de Negócio Importante*: No fluxo atual de pedidos da Santa Lolla, trabalha-se apenas com a taxa consolidada de faturamento, não existindo a separação fina e por item entre royalties (ex: 65% do royalty) e marketing/imagem (ex: 35% do royalty) na geração da compra ou do pedido de fábrica devido às quebras de arredondamento de centavos (`numeric 14,2`).
   - Portanto, para o MVP, a taxa agregada reside nos pedidos e compras. A separação fina de faturamento entre **Royalties** e **Marketing/Imagem** ocorre exclusivamente na consolidação e conciliação do fechamento em `royalty_statement_detail` e `royalty_statement`, espelhando fielmente o fechamento operacional do LunalôSys secundário.
   - Caso o ecossistema evolua no futuro para uma segregação de preços unitários no pedido (onde a fábrica passaria a fornecer códigos de preços unitários distintos para royalties e marketing), o schema e o front-end poderão ser estendidos de forma retrocompatível adicionando as colunas `unit_price_marketing` de forma isolada sem quebrar a raiz da arquitetura unificada.

6. **Grupo Empresarial (`group_enterprise`) e Natureza de Receitas (`brand_revenue`)**:
   - Para espelhar com exatidão a estrutura corporativa da marca de vestuário/calçados (que opera com faturamentos e braços empresariais autônomos para cobrança de taxas), moveu-se `brand` de catálogo para a camada de Organização e introduziu-se `group_enterprise` como representação unificada desses parceiros.
   - A tabela `brand_revenue` cadastra o escopo das naturezas de receita faturáveis ({Royalties/Imagem}, {Taxa de Marketing}), permitindo que o sistema saiba criar e amarrar múltiplas folhas de declaração (`royalty_statement`) para uma mesma marca e período baseados na sua respectiva natureza corporativa.


