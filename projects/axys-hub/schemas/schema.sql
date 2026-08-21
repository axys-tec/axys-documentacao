-- ============================================================
-- AxysHub — Schema Alvo Consolidado
-- Banco: PostgreSQL 14+
-- Schemas: identity · auth · product · orders · billing · gateway · fiscal · analytics · commercial · audit
--
-- Status: CONTRATO CANÔNICO EM EVOLUÇÃO
-- Data: 2026-06-18
--
-- OBJETIVO
-- Este arquivo consolida a visão alvo do banco AxysHub a partir das decisões
-- arquiteturais discutidas até aqui. Ainda não é uma migration de produção.
-- Serve como base de validação conceitual, revisão de regras de negócio e
-- evolução incremental do schema canônico do Hub.
--
-- PRINCÍPIOS FECHADOS
--
-- 1. TENANT
--    Tenant é a unidade canônica de isolamento, governança, assinatura e
--    contexto-alvo do ecossistema Axys.
--
--    Regra mental:
--      tenant isola.
--      store especializa somente quando o domínio exigir.
--
-- 2. STORE
--    Store é extensão opcional de domínio. Não substitui tenant.
--    Usos esperados: AxysGestor, filiais, lojas, unidades operacionais.
--    Apps como Easy continuam operando por tenant.
--
-- 3. USER
--    hub_user é identidade global. O usuário pode existir sem tenant ativo,
--    pode pertencer a múltiplos tenants e pode cair em zona neutra.
--
-- 4. CLIENT PORTAL
--    Cliente opera por tenant. Onboarding cria tenant + owner.
--    Login inicial: email + senha + CPF/CNPJ do tenant.
--    Troca de empresa na área logada é reautenticação contextual assistida.
--
-- 5. PRODUCT
--    Produto não é preço. Produto é o que existe.
--    Oferta é como vende.
--    Entitlement é o que libera.
--    Preço é quanto custa.
--    Combo é agrupamento comercial.
--
-- 6. COMMERCIAL
--    Partner traz o tenant. Quem trouxe o cliente é dono do cliente.
--    Comissão é por receita recebida, não por venda.
--
-- 7. FISCAL
--    1 compra/pedido pago = 1 NFS-e.
--    Itens fiscais podem ser consolidados por ecossistema, respeitando a
--    transação realizada. Lista de softwares/ofertas entra em observação.
--
-- 8. AUDIT
--    Auditoria é schema próprio. Billing, login, troca de conta, liberações,
--    comissões, owner transfer e ações sensíveis devem gerar trilha auditável.
--
-- CONVENÇÕES
-- - Tabelas mantêm prefixo hub_ quando representam entidade central do Hub.
-- - PKs: UUID DEFAULT gen_random_uuid()
-- - Timestamps: TIMESTAMPTZ DEFAULT now()
-- - Valores monetários: BIGINT em centavos
-- - Soft delete / bloqueio: is_active ou status, conforme natureza da tabela
-- - Seeds estruturais devem ficar próximos das tabelas correspondentes no
--   schema canônico futuro.
--
-- EXTENSÕES
-- ============================================================

-- schema tecnico criado apenas para hospedar a extensao pgcrypto
-- e expor funcoes utilitarias como gen_random_uuid(), crypt() e gen_salt()
CREATE SCHEMA IF NOT EXISTS public;
SET search_path TO public;
CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA public;

-- ============================================================
-- SCHEMAS
-- ============================================================

CREATE SCHEMA IF NOT EXISTS identity;
CREATE SCHEMA IF NOT EXISTS auth;
CREATE SCHEMA IF NOT EXISTS product;
CREATE SCHEMA IF NOT EXISTS orders;
CREATE SCHEMA IF NOT EXISTS billing;
CREATE SCHEMA IF NOT EXISTS gateway;
CREATE SCHEMA IF NOT EXISTS fiscal;
CREATE SCHEMA IF NOT EXISTS analytics;
CREATE SCHEMA IF NOT EXISTS commercial;
CREATE SCHEMA IF NOT EXISTS audit;

-- ============================================================
-- SCHEMA: identity
-- Função:
--   Identidade global, tenants, vínculos de usuário, stores opcionais
--   e especialização user-by-store.
-- ============================================================

-- ------------------------------------------------------------
-- identity.hub_user
-- Função:
--   Identidade global do usuário. Independente de tenant.
--   Um usuário pode existir sem tenant ativo e pode pertencer a vários tenants.
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS identity.hub_user (
    user_id         UUID        NOT NULL DEFAULT gen_random_uuid(),
    name            TEXT        NOT NULL,
    email           TEXT        NOT NULL,
    password_hash   TEXT,
    phone           TEXT,
    avatar_url      TEXT,
    locale          TEXT        NOT NULL DEFAULT 'pt-BR',
    cpf             TEXT,
    address_json    JSONB       NOT NULL DEFAULT '{}',
    sys_role        TEXT        NOT NULL DEFAULT 'user',
    status          TEXT        NOT NULL DEFAULT 'active',
    is_active       BOOLEAN     NOT NULL DEFAULT TRUE,
    failed_attempts SMALLINT    NOT NULL DEFAULT 0,
    locked_until    TIMESTAMPTZ,
    last_login      TIMESTAMPTZ,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT hub_user_pkey PRIMARY KEY (user_id),
    CONSTRAINT uq_hub_user_email UNIQUE (email),
    CONSTRAINT uq_hub_user_cpf UNIQUE (cpf),
    CONSTRAINT ck_hub_user_sys_role CHECK (sys_role IN ('hub_admin', 'user')),
    CONSTRAINT ck_hub_user_status CHECK (status IN ('active', 'suspended', 'deleted')),
    CONSTRAINT ck_hub_user_cpf_format CHECK (cpf IS NULL OR cpf ~ '^\d{11}$'),
    CONSTRAINT ck_hub_user_name_notempty CHECK (btrim(name) <> '')
);

CREATE INDEX IF NOT EXISTS idx_hub_user_email ON identity.hub_user (lower(email));

-- ------------------------------------------------------------
-- identity.hub_tenant
-- Função:
--   Unidade canônica de isolamento e contexto-alvo do ecossistema.
--   Sistemas filhos devem isolar seus dados por tenant_id.
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS identity.hub_tenant (
    tenant_id   UUID        NOT NULL DEFAULT gen_random_uuid(),
    tenant_code TEXT        NOT NULL,
    tenant_name TEXT        NOT NULL,
    document    TEXT        NOT NULL,
    status      TEXT        NOT NULL DEFAULT 'active',
    is_active   BOOLEAN     NOT NULL DEFAULT TRUE,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT hub_tenant_pkey PRIMARY KEY (tenant_id),
    CONSTRAINT uq_hub_tenant_code UNIQUE (tenant_code),
    CONSTRAINT uq_hub_tenant_document UNIQUE (document),
    CONSTRAINT ck_hub_tenant_code CHECK (tenant_code ~ '^[A-Z][A-Z0-9_]{2,29}$'),
    CONSTRAINT ck_hub_tenant_document CHECK (document ~ '^\d{11}$' OR document ~ '^\d{14}$'),
    CONSTRAINT ck_hub_tenant_status CHECK (status IN ('active', 'suspended', 'deleted'))
);

-- ------------------------------------------------------------
-- identity.hub_tenant_profile
-- Função:
--   Perfil do tenant por app/produto consumidor.
--   Não substitui tenant; classifica o papel macro daquele tenant
--   em um contexto de produto, sem trazer permissões operacionais
--   para dentro do Hub.
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS identity.hub_tenant_profile (
    tenant_id  UUID        NOT NULL,
    app_code   TEXT        NOT NULL,
    actor_type TEXT        NOT NULL,
    is_active  BOOLEAN     NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT hub_tenant_profile_pkey PRIMARY KEY (tenant_id, app_code),
    CONSTRAINT fk_hub_tenant_profile_tenant FOREIGN KEY (tenant_id)
        REFERENCES identity.hub_tenant (tenant_id) ON DELETE CASCADE,
    CONSTRAINT ck_hub_tenant_profile_app CHECK (app_code IN ('easy', 'gestor')),
    CONSTRAINT ck_hub_tenant_profile_actor CHECK (
        actor_type IN ('internal', 'client', 'partner', 'brand_representative')
    )
);

CREATE INDEX IF NOT EXISTS idx_hub_tenant_profile_app_actor
    ON identity.hub_tenant_profile (app_code, actor_type)
    WHERE is_active = TRUE;

-- ------------------------------------------------------------
-- identity.hub_user_tenant
-- Função:
--   Vínculo global usuário ↔ tenant. Regra geral de acesso.
--   user-by-tenant é obrigatório para operar em qualquer tenant.
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS identity.hub_user_tenant (
    user_tenant_id UUID        NOT NULL DEFAULT gen_random_uuid(),
    tenant_id      UUID        NOT NULL,
    user_id        UUID        NOT NULL,
    role           TEXT        NOT NULL DEFAULT 'user',
    is_active      BOOLEAN     NOT NULL DEFAULT TRUE,
    created_at     TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at     TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT hub_user_tenant_pkey PRIMARY KEY (user_tenant_id),
    CONSTRAINT uq_hub_user_tenant UNIQUE (tenant_id, user_id),
    CONSTRAINT fk_hub_user_tenant_tenant FOREIGN KEY (tenant_id)
        REFERENCES identity.hub_tenant (tenant_id) ON DELETE CASCADE,
    CONSTRAINT fk_hub_user_tenant_user FOREIGN KEY (user_id)
        REFERENCES identity.hub_user (user_id) ON DELETE CASCADE,
    CONSTRAINT ck_hub_user_tenant_role CHECK (role IN (
        'owner',
        'admin',
        'user',
        'viewer',
        'internal_owner',
        'internal_admin',
        'internal_financeiro',
        'internal_user'
    ))
);

CREATE INDEX IF NOT EXISTS idx_hub_user_tenant_tenant ON identity.hub_user_tenant (tenant_id);
CREATE INDEX IF NOT EXISTS idx_hub_user_tenant_user ON identity.hub_user_tenant (user_id);

-- ------------------------------------------------------------
-- identity.hub_store
-- Função:
--   Unidade operacional opcional de um tenant.
--   Não substitui tenant e não é obrigatória para apps como Easy.
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS identity.hub_store (
    store_id   UUID        NOT NULL DEFAULT gen_random_uuid(),
    tenant_id  UUID        NOT NULL,
    store_code TEXT        NOT NULL,
    store_name TEXT        NOT NULL,
    document   TEXT,
    status     TEXT        NOT NULL DEFAULT 'active',
    is_active  BOOLEAN     NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT hub_store_pkey PRIMARY KEY (store_id),
    CONSTRAINT uq_hub_store_tenant_code UNIQUE (tenant_id, store_code),
    CONSTRAINT fk_hub_store_tenant FOREIGN KEY (tenant_id)
        REFERENCES identity.hub_tenant (tenant_id) ON DELETE CASCADE,
    CONSTRAINT ck_hub_store_status CHECK (status IN ('active', 'inactive', 'deleted')),
    CONSTRAINT ck_hub_store_document CHECK (document IS NULL OR document ~ '^\d{11}$' OR document ~ '^\d{14}$')
);

CREATE INDEX IF NOT EXISTS idx_hub_store_tenant ON identity.hub_store (tenant_id);

-- ------------------------------------------------------------
-- identity.hub_user_store
-- Função:
--   Especialização de acesso do usuário dentro de uma store.
--   Só faz sentido para módulos store-aware, como AxysGestor.
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS identity.hub_user_store (
    tenant_id  UUID        NOT NULL,
    user_id    UUID        NOT NULL,
    store_id   UUID        NOT NULL,
    role       TEXT        NOT NULL DEFAULT 'user',
    is_active  BOOLEAN     NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT hub_user_store_pkey PRIMARY KEY (tenant_id, user_id, store_id),
    CONSTRAINT fk_hub_user_store_tenant FOREIGN KEY (tenant_id)
        REFERENCES identity.hub_tenant (tenant_id) ON DELETE CASCADE,
    CONSTRAINT fk_hub_user_store_user FOREIGN KEY (user_id)
        REFERENCES identity.hub_user (user_id) ON DELETE CASCADE,
    CONSTRAINT fk_hub_user_store_store FOREIGN KEY (store_id)
        REFERENCES identity.hub_store (store_id) ON DELETE CASCADE,
    CONSTRAINT fk_hub_user_store_user_tenant FOREIGN KEY (tenant_id, user_id)
        REFERENCES identity.hub_user_tenant (tenant_id, user_id) ON DELETE CASCADE,
    CONSTRAINT ck_hub_user_store_role CHECK (role IN ('admin', 'user', 'viewer'))
);

-- ============================================================
-- SCHEMA: auth
-- Função:
--   Autenticação, sessões, tokens e credenciais programáticas.
-- ============================================================

-- ------------------------------------------------------------
-- auth.hub_auth_token
-- Função:
--   Tokens de sessão emitidos pelo Hub. token_hash nunca armazena token bruto.
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS auth.hub_auth_token (
    token_id   UUID        NOT NULL DEFAULT gen_random_uuid(),
    tenant_id  UUID        NOT NULL,
    user_id    UUID        NOT NULL,
    token_hash CHAR(64)    NOT NULL,
    issued_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    expires_at TIMESTAMPTZ NOT NULL,
    revoked_at TIMESTAMPTZ,

    CONSTRAINT hub_auth_token_pkey PRIMARY KEY (token_id),
    CONSTRAINT uq_hub_auth_token_hash UNIQUE (token_hash),
    CONSTRAINT fk_hub_auth_token_tenant FOREIGN KEY (tenant_id)
        REFERENCES identity.hub_tenant (tenant_id) ON DELETE CASCADE,
    CONSTRAINT fk_hub_auth_token_user FOREIGN KEY (user_id)
        REFERENCES identity.hub_user (user_id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_hub_auth_token_user ON auth.hub_auth_token (tenant_id, user_id);

-- ------------------------------------------------------------
-- auth.hub_api_registry
-- Função:
--   Registro de APIs externas ou internas integráveis por tenants.
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS auth.hub_api_registry (
    api_id     UUID        NOT NULL DEFAULT gen_random_uuid(),
    api_code   TEXT        NOT NULL,
    name       TEXT        NOT NULL,
    description TEXT,
    base_path  TEXT,
    status     TEXT        NOT NULL DEFAULT 'active',
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT hub_api_registry_pkey PRIMARY KEY (api_id),
    CONSTRAINT uq_hub_api_registry_code UNIQUE (api_code),
    CONSTRAINT ck_hub_api_registry_status CHECK (status IN ('active', 'inactive', 'deprecated'))
);

INSERT INTO auth.hub_api_registry (api_code, name, description, base_path, status)
VALUES
    ('AXYSGESTOR', 'AxysGestor API', 'API administrativa e operacional do AxysGestor.', '/api/v1/gestor', 'active')
ON CONFLICT (api_code) DO UPDATE SET
    name = EXCLUDED.name,
    description = EXCLUDED.description,
    base_path = EXCLUDED.base_path,
    status = EXCLUDED.status;

-- ------------------------------------------------------------
-- auth.hub_api_key
-- Função:
--   Chaves estáticas por tenant para autenticação programática.
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS auth.hub_api_key (
    api_key_id UUID        NOT NULL DEFAULT gen_random_uuid(),
    tenant_id  UUID,
    key_hash   CHAR(64)    NOT NULL,
    label      TEXT,
    status     TEXT        NOT NULL DEFAULT 'active',
    is_active  BOOLEAN     NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT hub_api_key_pkey PRIMARY KEY (api_key_id),
    CONSTRAINT uq_hub_api_key_hash UNIQUE (key_hash),
    CONSTRAINT fk_hub_api_key_tenant FOREIGN KEY (tenant_id)
        REFERENCES identity.hub_tenant (tenant_id) ON DELETE CASCADE,
    CONSTRAINT ck_hub_api_key_status CHECK (status IN ('active', 'revoked'))
);

-- ------------------------------------------------------------
-- auth.hub_api_client
-- Função:
--   Credenciais OAuth2-style de tenant para API registrada.
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS auth.hub_api_client (
    api_client_id      UUID        NOT NULL DEFAULT gen_random_uuid(),
    tenant_id          UUID        NOT NULL,
    api_id             UUID        NOT NULL,
    name               TEXT,
    client_key         TEXT        NOT NULL,
    client_secret_hash CHAR(64)    NOT NULL,
    status             TEXT        NOT NULL DEFAULT 'active',
    scopes             JSONB       NOT NULL DEFAULT '[]',
    created_at         TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT hub_api_client_pkey PRIMARY KEY (api_client_id),
    CONSTRAINT uq_hub_api_client_key UNIQUE (client_key),
    CONSTRAINT fk_hub_api_client_tenant FOREIGN KEY (tenant_id)
        REFERENCES identity.hub_tenant (tenant_id) ON DELETE CASCADE,
    CONSTRAINT fk_hub_api_client_api FOREIGN KEY (api_id)
        REFERENCES auth.hub_api_registry (api_id) ON DELETE CASCADE,
    CONSTRAINT ck_hub_api_client_scopes_array CHECK (jsonb_typeof(scopes) = 'array'),
    CONSTRAINT ck_hub_api_client_status CHECK (status IN ('active', 'revoked'))
);

-- ------------------------------------------------------------
-- auth.hub_api_token
-- Função:
--   Tokens de curta vida emitidos para api_clients.
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS auth.hub_api_token (
    token_id      UUID        NOT NULL DEFAULT gen_random_uuid(),
    api_client_id UUID        NOT NULL,
    tenant_id     UUID        NOT NULL,
    token_hash    CHAR(64)    NOT NULL,
    expires_at    TIMESTAMPTZ NOT NULL,
    revoked_at    TIMESTAMPTZ,
    created_at    TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT hub_api_token_pkey PRIMARY KEY (token_id),
    CONSTRAINT uq_hub_api_token_hash UNIQUE (token_hash),
    CONSTRAINT fk_hub_api_token_client FOREIGN KEY (api_client_id)
        REFERENCES auth.hub_api_client (api_client_id) ON DELETE CASCADE,
    CONSTRAINT fk_hub_api_token_tenant FOREIGN KEY (tenant_id)
        REFERENCES identity.hub_tenant (tenant_id) ON DELETE CASCADE
);

-- ============================================================
-- SCHEMA: product
-- Função:
--   Catálogo de ecossistemas, produtos, módulos, ofertas, políticas,
--   preços, adicionais, concessões e combos.
-- Diretriz de identidade (contratual):
--   Nesta pré-foto o bloco permanece em UUID para manter coesão com o
--   restante do rascunho executável. Porém, na rodada de redesign efetiva,
--   o domínio de catálogo/billing deve preferir chaves internas numéricas
--   (INT/BIGINT, conforme volume) em vez de UUID indiscriminado.
--   UUID permanece como escolha natural para domínios client-facing
--   (tenant, user, sessão, convite, vínculo externo e afins).
--   Em especial:
--   - product: preferir chave técnica numérica + codigo estável de negócio;
--   - billing: preferir BIGINT nas entidades transacionais e escaláveis.
-- ============================================================

-- ------------------------------------------------------------
-- product.ecosystem
-- Função:
--   Agrupador estratégico dos produtos Axys: Easy, Pro, Gestor.
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS product.ecosystem (
    ecosystem_id INT         GENERATED ALWAYS AS IDENTITY,
    code         TEXT        NOT NULL,
    name         TEXT        NOT NULL,
    description  TEXT,
    is_active    BOOLEAN     NOT NULL DEFAULT TRUE,
    created_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at   TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT ecosystem_pkey PRIMARY KEY (ecosystem_id),
    CONSTRAINT uq_ecosystem_code UNIQUE (code),
    CONSTRAINT ck_ecosystem_code_not_blank CHECK (btrim(code) <> '')
);

INSERT INTO product.ecosystem (code, name, description)
VALUES
    ('EASY', 'AxysEasy', 'Ecossistema AxysEasy'),
    ('PRO', 'AxysPro', 'Ecossistema AxysPro'),
    ('GESTOR', 'AxysGestor', 'Ecossistema AxysGestor')
ON CONFLICT (code) DO NOTHING;

-- ------------------------------------------------------------
-- product.product
-- Função:
--   Produto ou solução comercial Axys.
--   Ex.: PRI, CPU, BDR, AXYSPRO, AXYSGESTOR.
-- Nota de modelagem:
--   O catálogo usa chave interna numérica e preserva `codigo` como
--   identificador estável de negócio/exposição contratual.
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS product.product (
    product_id     INT         GENERATED ALWAYS AS IDENTITY,
    ecosystem_id   INT         NOT NULL,
    code           TEXT        NOT NULL,
    name           TEXT        NOT NULL,
    description    TEXT,
    is_active      BOOLEAN     NOT NULL DEFAULT TRUE,
    created_at     TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at     TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT product_pkey PRIMARY KEY (product_id),
    CONSTRAINT uq_product_ecosystem_code UNIQUE (ecosystem_id, code),
    CONSTRAINT fk_product_ecosystem FOREIGN KEY (ecosystem_id)
        REFERENCES product.ecosystem (ecosystem_id) ON DELETE RESTRICT,
    CONSTRAINT ck_product_code_not_blank CHECK (btrim(code) <> '')
);

INSERT INTO product.product (ecosystem_id, code, name, description)
SELECT e.ecosystem_id, v.code, v.name, v.description
FROM product.ecosystem e
JOIN (
    VALUES
        ('PRO', 'AXYSPRO', 'AxysPro', 'Suite AxysPro'),
        ('GESTOR', 'AXYSGESTOR', 'AxysGestor', 'Produto AxysGestor'),
        ('GESTOR', 'SL-COMPANY', 'Gestor SL Company', 'Produto AxysGestor para operacoes Santa Lolla'),
        ('GESTOR', 'LOCCITANE', 'Gestor L''Occitane', 'Produto AxysGestor para operacoes L''Occitane'),
        ('GESTOR', 'ANALISTA-VENDAS', 'Gestor Analista Vendas', 'Produto AxysGestor para analise de vendas'),
        ('GESTOR', 'ANALISTA-COMPRAS', 'Gestor Analista Compras', 'Produto AxysGestor para analise de compras'),
        ('GESTOR', 'NOTIFICADOR', 'Gestor Notificador', 'Produto AxysGestor para notificacoes operacionais'),
        ('GESTOR', 'CONCILIADOR', 'Gestor Conciliador', 'Produto AxysGestor para conciliacao operacional'),
        ('EASY', 'PRI', 'Easy Price', 'Motor paramétrico base do Easy Price'),
        ('EASY', 'CPU', 'Easy CPU', 'Produto Easy CPU'),
        ('EASY', 'DOC', 'Easy Docs', 'Produto Easy Docs'),
        ('EASY', 'PM', 'Easy ProjectManager', 'Produto Easy ProjectManager'),
        ('EASY', 'LIC', 'Easy LicitPlan', 'Produto Easy LicitPlan'),
        ('EASY', 'ORC', 'Easy Orça', 'Produto Easy Orça'),
        ('EASY', 'BDR', 'Easy BuildDiary', 'Produto Easy BuildDiary'),
        ('EASY', 'FIN', 'Easy FinControl', 'Produto Easy FinControl'),
        ('EASY', 'ONE', 'Easy One', 'Produto premium que aglutina todas as funcoes do ecossistema')
) AS v(ecosystem_code, code, name, description)
    ON v.ecosystem_code = e.code
ON CONFLICT (ecosystem_id, code) DO NOTHING;

-- ------------------------------------------------------------
-- product.module
-- Função:
--   Módulo funcional/licenciável dentro de um produto.
--   Pode ter hierarquia interna via parent_module_id.
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS product.module (
    module_id         INT         GENERATED ALWAYS AS IDENTITY,
    product_id        INT         NOT NULL,
    parent_module_id  INT,
    code              TEXT        NOT NULL,
    name              TEXT        NOT NULL,
    description       TEXT,
    is_active         BOOLEAN     NOT NULL DEFAULT TRUE,
    created_at        TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at        TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT module_pkey PRIMARY KEY (module_id),
    CONSTRAINT uq_module_product_code UNIQUE (product_id, code),
    CONSTRAINT fk_module_product FOREIGN KEY (product_id)
        REFERENCES product.product (product_id) ON DELETE CASCADE,
    CONSTRAINT fk_module_parent FOREIGN KEY (parent_module_id)
        REFERENCES product.module (module_id) ON DELETE SET NULL,
    CONSTRAINT ck_module_code_not_blank CHECK (btrim(code) <> '')
);

-- ------------------------------------------------------------
-- product.offer
-- Função:
--   Forma comercial de vender um produto/módulo.
--   Ex.: EASY-PR1-SIN, EASY-PR1-STA, EASY-BDR-UNL.
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS product.offer (
    offer_id         INT         GENERATED ALWAYS AS IDENTITY,
    product_id       INT         NOT NULL,
    module_id        INT,
    offer_code       TEXT        NOT NULL,
    name             TEXT        NOT NULL,
    billing_model    TEXT        NOT NULL,
    is_active        BOOLEAN     NOT NULL DEFAULT TRUE,
    created_at       TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at       TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT offer_pkey PRIMARY KEY (offer_id),
    CONSTRAINT uq_offer_code UNIQUE (offer_code),
    CONSTRAINT fk_offer_product FOREIGN KEY (product_id)
        REFERENCES product.product (product_id) ON DELETE RESTRICT,
    CONSTRAINT fk_offer_module FOREIGN KEY (module_id)
        REFERENCES product.module (module_id) ON DELETE SET NULL,
    CONSTRAINT ck_offer_code_not_blank CHECK (btrim(offer_code) <> ''),
    CONSTRAINT ck_offer_billing_model CHECK (billing_model IN ('uso_unico', 'mensal', 'anual', 'por_uso', 'personalizado'))
);

-- ------------------------------------------------------------
-- product.offer_entitlement
-- Função:
--   Define o que a oferta libera: usos, recursos ativos, módulos,
--   ilimitado, store-aware etc.
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS product.offer_entitlement (
    entitlement_id    INT         GENERATED ALWAYS AS IDENTITY,
    offer_id          INT         NOT NULL,
    module_id         INT,
    grant_model       TEXT        NOT NULL,
    unit              TEXT,
    quantity          INTEGER,
    period_unit       TEXT,
    rule_json         JSONB       NOT NULL DEFAULT '{}',
    is_active         BOOLEAN     NOT NULL DEFAULT TRUE,
    created_at        TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at        TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT offer_entitlement_pkey PRIMARY KEY (entitlement_id),
    CONSTRAINT fk_offer_entitlement_offer FOREIGN KEY (offer_id)
        REFERENCES product.offer (offer_id) ON DELETE CASCADE,
    CONSTRAINT fk_offer_entitlement_module FOREIGN KEY (module_id)
        REFERENCES product.module (module_id) ON DELETE SET NULL,
    CONSTRAINT ck_offer_entitlement_grant_model CHECK (grant_model IN (
        'uso_unico',
        'contador_uso',
        'limite_usuario',
        'limite_recurso_ativo',
        'acesso_modulo',
        'ilimitado',
        'limite_store',
        'personalizado'
    )),
    CONSTRAINT ck_offer_entitlement_quantity CHECK (quantity IS NULL OR quantity >= 0)
);

-- ============================================================
-- TABELA: product.offer_policy
--
-- Política operacional e comercial da oferta.
--
-- Define como uma oferta se comporta após a venda:
--
-- - período de tolerância (grace period);
-- - suspensão automática;
-- - cancelamento automático;
-- - tentativas de cobrança;
-- - renovação automática;
-- - elegibilidade para comissão;
-- - emissão fiscal automática;
-- - permissões de override manual.
--
-- A política pertence à OFERTA e não ao PRODUTO.
--
-- Motivo:
--
-- Um mesmo produto pode possuir múltiplas ofertas com
-- comportamentos comerciais distintos.
--
-- Exemplo:
--
-- Produto:
--   Easy Price (PR1)
--
-- Ofertas:
--
--   PR1-SIN
--   - uso único
--   - sem renovação
--   - grace = 0
--
--   PR1-STA
--   - mensal
--   - renovação automática
--   - grace = 0
--
--   PR1-UNL
--   - anual
--   - renovação automática
--   - grace = 5
--
-- Fluxo operacional:
--
-- oferta
--   ↓
-- oferta_politica
--   ↓
-- subscription
--   ↓
-- cobrança
--   ↓
-- suspensão/cancelamento
--
-- Regra:
--
-- Cada oferta possui exatamente uma política vigente.
--
-- Histórico de políticas, se necessário no futuro,
-- deverá ser realizado por versionamento e não por
-- múltiplas políticas simultâneas.
--
-- politica_json:
--
-- Reserva técnica para regras futuras que ainda não
-- justificam colunas dedicadas.
--
-- Exemplo:
--
-- {
--   "notify_before_expiration_days": 7,
--   "allow_reactivation": true
-- }
-- ============================================================
CREATE TABLE IF NOT EXISTS product.offer_policy (

    policy_id INT         GENERATED ALWAYS AS IDENTITY,
    offer_id  INT         NOT NULL,
    
    -- ── Cobrança / inadimplência ──────────────────────────
    dias_carencia           INTEGER NOT NULL DEFAULT 0,
    dias_auto_suspensao     INTEGER NOT NULL DEFAULT 0,
    dias_auto_cancelamento  INTEGER,
    
    -- ── Renovação ─────────────────────────────────────────
    renova_automaticamente         BOOLEAN NOT NULL DEFAULT TRUE,
    retry_pagamento_habilitado     BOOLEAN NOT NULL DEFAULT TRUE,
    max_tentativas_pagamento       INTEGER NOT NULL DEFAULT 3,
    
    -- ── Operação interna ──────────────────────────────────
    permite_override_manual        BOOLEAN NOT NULL DEFAULT TRUE,
    max_dias_override_manual       INTEGER,
    
    -- ── Comissão ──────────────────────────────────────────
    elegivel_comissao              BOOLEAN NOT NULL DEFAULT TRUE,

    -- ── Fiscal ────────────────────────────────────────────
    emissao_fiscal_automatica      BOOLEAN NOT NULL DEFAULT TRUE,

    -- ── Extensão futura ───────────────────────────────────
    policy_json                    JSONB NOT NULL DEFAULT '{}',

    -- ── Controle ──────────────────────────────────────────
    is_active     BOOLEAN     NOT NULL DEFAULT TRUE,
    created_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at    TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT offer_policy_pkey PRIMARY KEY (policy_id),
    CONSTRAINT uq_offer_policy_offer UNIQUE (offer_id),
    CONSTRAINT fk_offer_policy_offer FOREIGN KEY (offer_id)
        REFERENCES product.offer (offer_id)
        ON DELETE CASCADE,
    CONSTRAINT ck_offer_policy_grace_non_negative
        CHECK (dias_carencia >= 0),
    CONSTRAINT ck_offer_policy_suspend_non_negative
        CHECK (dias_auto_suspensao >= 0),
    CONSTRAINT ck_offer_policy_cancel_non_negative
        CHECK (dias_auto_cancelamento IS NULL OR dias_auto_cancelamento >= 0),
    CONSTRAINT ck_offer_policy_retry_non_negative
        CHECK (max_tentativas_pagamento >= 0)

);

CREATE INDEX IF NOT EXISTS idx_offer_policy_active
    ON product.offer_policy (is_active)
    WHERE is_active = TRUE;

-- ------------------------------------------------------------
-- product.offer_price
-- Função:
--   Histórico de preços das ofertas. Nunca depender do preço atual
--   para saber por quanto algo foi vendido no passado.
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS product.offer_price (
    price_id         INT         GENERATED ALWAYS AS IDENTITY,
    offer_id         INT         NOT NULL,
    currency         TEXT        NOT NULL DEFAULT 'BRL',
    amount_cents     BIGINT      NOT NULL,
    billing_period   TEXT        NOT NULL,
    valid_from       TIMESTAMPTZ NOT NULL DEFAULT now(),
    valid_to         TIMESTAMPTZ,
    is_active        BOOLEAN     NOT NULL DEFAULT TRUE,
    created_at       TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at       TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT offer_price_pkey PRIMARY KEY (price_id),
    CONSTRAINT fk_offer_price_offer FOREIGN KEY (offer_id)
        REFERENCES product.offer (offer_id) ON DELETE CASCADE,
    CONSTRAINT ck_offer_price_amount CHECK (amount_cents >= 0),
    CONSTRAINT ck_offer_price_period CHECK (billing_period IN ('uma_vez', 'mensal', 'semestral', 'anual', 'personalizado'))
);

INSERT INTO product.offer (product_id, module_id, offer_code, name, billing_model)
SELECT p.product_id, NULL, v.offer_code, v.name, v.billing_model
FROM product.product p
JOIN (
    VALUES
        ('PR1', 'PR1-SIN', 'Easy Price Single', 'mensal'),
        ('PR1', 'PR1-STA', 'Easy Price Starter', 'mensal'),
        ('PR1', 'PR1-ADV', 'Easy Price Advanced', 'mensal'),
        ('PR1', 'PR1-PRO', 'Easy Price Pro', 'mensal'),
        ('PR1', 'PR1-UNL', 'Easy Price Unlimited', 'mensal'),
        ('CPU', 'CPU-SIN', 'Easy CPU Single', 'mensal'),
        ('CPU', 'CPU-STA', 'Easy CPU Starter', 'mensal'),
        ('CPU', 'CPU-ADV', 'Easy CPU Advanced', 'mensal'),
        ('CPU', 'CPU-PRO', 'Easy CPU Pro', 'mensal'),
        ('CPU', 'CPU-UNL', 'Easy CPU Unlimited', 'mensal'),
        ('DOC', 'DOC-SIN', 'Easy Docs Single', 'mensal'),
        ('DOC', 'DOC-STA', 'Easy Docs Starter', 'mensal'),
        ('DOC', 'DOC-ADV', 'Easy Docs Advanced', 'mensal'),
        ('DOC', 'DOC-PRO', 'Easy Docs Pro', 'mensal'),
        ('DOC', 'DOC-UNL', 'Easy Docs Unlimited', 'mensal'),
        ('PM', 'PM-SIN', 'Easy ProjectManager Single', 'mensal'),
        ('PM', 'PM-STA', 'Easy ProjectManager Starter', 'mensal'),
        ('PM', 'PM-ADV', 'Easy ProjectManager Advanced', 'mensal'),
        ('PM', 'PM-PRO', 'Easy ProjectManager Pro', 'mensal'),
        ('PM', 'PM-UNL', 'Easy ProjectManager Unlimited', 'mensal'),
        ('LIC', 'LIC-SIN', 'Easy LicitPlan Single', 'mensal'),
        ('LIC', 'LIC-STA', 'Easy LicitPlan Starter', 'mensal'),
        ('LIC', 'LIC-ADV', 'Easy LicitPlan Advanced', 'mensal'),
        ('LIC', 'LIC-PRO', 'Easy LicitPlan Pro', 'mensal'),
        ('LIC', 'LIC-UNL', 'Easy LicitPlan Unlimited', 'mensal'),
        ('ORC', 'ORC-SIN', 'Easy Orça Single', 'mensal'),
        ('ORC', 'ORC-STA', 'Easy Orça Starter', 'mensal'),
        ('ORC', 'ORC-ADV', 'Easy Orça Advanced', 'mensal'),
        ('ORC', 'ORC-PRO', 'Easy Orça Pro', 'mensal'),
        ('ORC', 'ORC-UNL', 'Easy Orça Unlimited', 'mensal'),
        ('BDR', 'BDR-SIN', 'Easy BuildDiary Single', 'mensal'),
        ('BDR', 'BDR-STA', 'Easy BuildDiary Starter', 'mensal'),
        ('BDR', 'BDR-ADV', 'Easy BuildDiary Advanced', 'mensal'),
        ('BDR', 'BDR-PRO', 'Easy BuildDiary Pro', 'mensal'),
        ('BDR', 'BDR-UNL', 'Easy BuildDiary Unlimited', 'mensal'),
        ('FIN', 'FIN-SIN', 'Easy FinControl Single', 'mensal'),
        ('FIN', 'FIN-STA', 'Easy FinControl Starter', 'mensal'),
        ('FIN', 'FIN-ADV', 'Easy FinControl Advanced', 'mensal'),
        ('FIN', 'FIN-PRO', 'Easy FinControl Pro', 'mensal'),
        ('FIN', 'FIN-UNL', 'Easy FinControl Unlimited', 'mensal'),
        ('FIS', 'FIS-UNL', 'Easy One Unlimited', 'mensal')
) AS v(product_code, offer_code, name, billing_model)
    ON v.product_code = p.code
ON CONFLICT (offer_code) DO NOTHING;

INSERT INTO product.offer_policy (
    offer_id,
    dias_carencia,
    dias_auto_suspensao,
    dias_auto_cancelamento,
    renova_automaticamente,
    retry_pagamento_habilitado,
    max_tentativas_pagamento,
    permite_override_manual,
    max_dias_override_manual,
    elegivel_comissao,
    emissao_fiscal_automatica,
    policy_json
)
SELECT
    o.offer_id,
    CASE WHEN o.offer_code IN ('PR1-UNL', 'CPU-UNL', 'DOC-UNL', 'PM-UNL', 'LIC-UNL', 'ORC-UNL', 'BDR-UNL', 'FIN-UNL', 'FIS-UNL') THEN 5 ELSE 0 END,
    5,
    30,
    TRUE,
    TRUE,
    3,
    TRUE,
    15,
    TRUE,
    TRUE,
    '{}'::jsonb
FROM product.offer o
ON CONFLICT (offer_id) DO NOTHING;

INSERT INTO product.offer_entitlement (
    offer_id,
    module_id,
    grant_model,
    unit,
    quantity,
    period_unit,
    rule_json
)
SELECT o.offer_id, NULL, v.grant_model, v.unit, v.quantity, v.period_unit, v.rule_json::jsonb
FROM product.offer o
JOIN (
    VALUES
        ('PR1-SIN', 'contador_uso', 'artefato', 1, 'mes', '{}'),
        ('PR1-SIN', 'limite_usuario', 'usuario', 1, 'mes', '{}'),
        ('PR1-STA', 'contador_uso', 'artefato', 2, 'mes', '{}'),
        ('PR1-STA', 'limite_usuario', 'usuario', 1, 'mes', '{}'),
        ('PR1-ADV', 'contador_uso', 'artefato', 3, 'mes', '{}'),
        ('PR1-ADV', 'limite_usuario', 'usuario', 1, 'mes', '{}'),
        ('PR1-PRO', 'contador_uso', 'artefato', 6, 'mes', '{}'),
        ('PR1-PRO', 'limite_usuario', 'usuario', 2, 'mes', '{}'),
        ('PR1-UNL', 'ilimitado', 'artefato', NULL, 'mes', '{}'),
        ('PR1-UNL', 'limite_usuario', 'usuario', 5, 'mes', '{}'),

        ('CPU-SIN', 'contador_uso', 'artefato', 1, 'mes', '{}'),
        ('CPU-SIN', 'limite_usuario', 'usuario', 1, 'mes', '{}'),
        ('CPU-STA', 'contador_uso', 'artefato', 2, 'mes', '{}'),
        ('CPU-STA', 'limite_usuario', 'usuario', 1, 'mes', '{}'),
        ('CPU-ADV', 'contador_uso', 'artefato', 3, 'mes', '{}'),
        ('CPU-ADV', 'limite_usuario', 'usuario', 1, 'mes', '{}'),
        ('CPU-PRO', 'contador_uso', 'artefato', 6, 'mes', '{}'),
        ('CPU-PRO', 'limite_usuario', 'usuario', 2, 'mes', '{}'),
        ('CPU-UNL', 'ilimitado', 'artefato', NULL, 'mes', '{}'),
        ('CPU-UNL', 'limite_usuario', 'usuario', 5, 'mes', '{}'),

        ('DOC-SIN', 'contador_uso', 'artefato', 1, 'mes', '{}'),
        ('DOC-SIN', 'limite_usuario', 'usuario', 1, 'mes', '{}'),
        ('DOC-STA', 'contador_uso', 'artefato', 2, 'mes', '{}'),
        ('DOC-STA', 'limite_usuario', 'usuario', 1, 'mes', '{}'),
        ('DOC-ADV', 'contador_uso', 'artefato', 3, 'mes', '{}'),
        ('DOC-ADV', 'limite_usuario', 'usuario', 1, 'mes', '{}'),
        ('DOC-PRO', 'contador_uso', 'artefato', 6, 'mes', '{}'),
        ('DOC-PRO', 'limite_usuario', 'usuario', 2, 'mes', '{}'),
        ('DOC-UNL', 'ilimitado', 'artefato', NULL, 'mes', '{}'),
        ('DOC-UNL', 'limite_usuario', 'usuario', 5, 'mes', '{}'),

        ('PM-SIN', 'contador_uso', 'artefato', 1, 'mes', '{}'),
        ('PM-SIN', 'limite_usuario', 'usuario', 1, 'mes', '{}'),
        ('PM-STA', 'contador_uso', 'artefato', 2, 'mes', '{}'),
        ('PM-STA', 'limite_usuario', 'usuario', 1, 'mes', '{}'),
        ('PM-ADV', 'contador_uso', 'artefato', 3, 'mes', '{}'),
        ('PM-ADV', 'limite_usuario', 'usuario', 1, 'mes', '{}'),
        ('PM-PRO', 'contador_uso', 'artefato', 6, 'mes', '{}'),
        ('PM-PRO', 'limite_usuario', 'usuario', 2, 'mes', '{}'),
        ('PM-UNL', 'ilimitado', 'artefato', NULL, 'mes', '{}'),
        ('PM-UNL', 'limite_usuario', 'usuario', 5, 'mes', '{}'),

        ('LIC-SIN', 'contador_uso', 'artefato', 1, 'mes', '{}'),
        ('LIC-SIN', 'limite_usuario', 'usuario', 1, 'mes', '{}'),
        ('LIC-STA', 'contador_uso', 'artefato', 2, 'mes', '{}'),
        ('LIC-STA', 'limite_usuario', 'usuario', 1, 'mes', '{}'),
        ('LIC-ADV', 'contador_uso', 'artefato', 3, 'mes', '{}'),
        ('LIC-ADV', 'limite_usuario', 'usuario', 1, 'mes', '{}'),
        ('LIC-PRO', 'contador_uso', 'artefato', 6, 'mes', '{}'),
        ('LIC-PRO', 'limite_usuario', 'usuario', 2, 'mes', '{}'),
        ('LIC-UNL', 'ilimitado', 'artefato', NULL, 'mes', '{}'),
        ('LIC-UNL', 'limite_usuario', 'usuario', 5, 'mes', '{}'),

        ('ORC-SIN', 'contador_uso', 'artefato', 1, 'mes', '{}'),
        ('ORC-SIN', 'limite_usuario', 'usuario', 1, 'mes', '{}'),
        ('ORC-STA', 'contador_uso', 'artefato', 2, 'mes', '{}'),
        ('ORC-STA', 'limite_usuario', 'usuario', 1, 'mes', '{}'),
        ('ORC-ADV', 'contador_uso', 'artefato', 3, 'mes', '{}'),
        ('ORC-ADV', 'limite_usuario', 'usuario', 1, 'mes', '{}'),
        ('ORC-PRO', 'contador_uso', 'artefato', 6, 'mes', '{}'),
        ('ORC-PRO', 'limite_usuario', 'usuario', 2, 'mes', '{}'),
        ('ORC-UNL', 'ilimitado', 'artefato', NULL, 'mes', '{}'),
        ('ORC-UNL', 'limite_usuario', 'usuario', 5, 'mes', '{}'),

        ('BDR-SIN', 'limite_recurso_ativo', 'obra_ativa', 1, 'mes', '{}'),
        ('BDR-SIN', 'limite_usuario', 'usuario', 1, 'mes', '{}'),
        ('BDR-STA', 'limite_recurso_ativo', 'obra_ativa', 2, 'mes', '{}'),
        ('BDR-STA', 'limite_usuario', 'usuario', 1, 'mes', '{}'),
        ('BDR-ADV', 'limite_recurso_ativo', 'obra_ativa', 3, 'mes', '{}'),
        ('BDR-ADV', 'limite_usuario', 'usuario', 1, 'mes', '{}'),
        ('BDR-PRO', 'limite_recurso_ativo', 'obra_ativa', 6, 'mes', '{}'),
        ('BDR-PRO', 'limite_usuario', 'usuario', 2, 'mes', '{}'),
        ('BDR-UNL', 'ilimitado', 'obra_ativa', NULL, 'mes', '{}'),
        ('BDR-UNL', 'limite_usuario', 'usuario', 5, 'mes', '{}'),

        ('FIN-SIN', 'limite_recurso_ativo', 'obra_ativa', 1, 'mes', '{}'),
        ('FIN-SIN', 'limite_usuario', 'usuario', 1, 'mes', '{}'),
        ('FIN-STA', 'limite_recurso_ativo', 'obra_ativa', 2, 'mes', '{}'),
        ('FIN-STA', 'limite_usuario', 'usuario', 1, 'mes', '{}'),
        ('FIN-ADV', 'limite_recurso_ativo', 'obra_ativa', 3, 'mes', '{}'),
        ('FIN-ADV', 'limite_usuario', 'usuario', 1, 'mes', '{}'),
        ('FIN-PRO', 'limite_recurso_ativo', 'obra_ativa', 6, 'mes', '{}'),
        ('FIN-PRO', 'limite_usuario', 'usuario', 2, 'mes', '{}'),
        ('FIN-UNL', 'ilimitado', 'obra_ativa', NULL, 'mes', '{}'),
        ('FIN-UNL', 'limite_usuario', 'usuario', 5, 'mes', '{}'),

        ('FIS-UNL', 'ilimitado', 'obra_ativa', NULL, 'mes', '{}'),
        ('FIS-UNL', 'limite_usuario', 'usuario', 5, 'mes', '{}'),
        ('FIS-UNL', 'personalizado', 'pacote_governanca', 1, 'mes', '{"inclui":["BDR","FIN","PM","LIC","ORC"]}')
) AS v(offer_code, grant_model, unit, quantity, period_unit, rule_json)
    ON v.offer_code = o.offer_code
WHERE NOT EXISTS (
    SELECT 1
    FROM product.offer_entitlement e
    WHERE e.offer_id = o.offer_id
      AND e.grant_model = v.grant_model
      AND COALESCE(e.unit, '') = COALESCE(v.unit, '')
      AND COALESCE(e.quantity, -1) = COALESCE(v.quantity, -1)
      AND COALESCE(e.period_unit, '') = COALESCE(v.period_unit, '')
);

INSERT INTO product.offer_price (
    offer_id,
    currency,
    amount_cents,
    billing_period,
    valid_from
)
SELECT o.offer_id, 'BRL', v.amount_cents, v.billing_period, now()
FROM product.offer o
JOIN (
    VALUES
        ('PR1-SIN', 'mensal', 1490),
        ('PR1-STA', 'mensal', 1990),
        ('PR1-ADV', 'mensal', 2990),
        ('PR1-PRO', 'mensal', 5990),
        ('PR1-UNL', 'mensal', 9990),

        ('CPU-SIN', 'mensal', 1990),
        ('CPU-STA', 'mensal', 3490),
        ('CPU-ADV', 'mensal', 4990),
        ('CPU-PRO', 'mensal', 6990),
        ('CPU-UNL', 'mensal', 9990),

        ('DOC-SIN', 'mensal', 1990),
        ('DOC-STA', 'mensal', 3490),
        ('DOC-ADV', 'mensal', 4990),
        ('DOC-PRO', 'mensal', 6990),
        ('DOC-UNL', 'mensal', 9990),

        ('PM-SIN', 'mensal', 1490),
        ('PM-STA', 'mensal', 1990),
        ('PM-ADV', 'mensal', 2990),
        ('PM-PRO', 'mensal', 5990),
        ('PM-UNL', 'mensal', 9990),

        ('LIC-SIN', 'mensal', 12990),
        ('LIC-STA', 'mensal', 19990),
        ('LIC-ADV', 'mensal', 29990),
        ('LIC-PRO', 'mensal', 39990),
        ('LIC-UNL', 'mensal', 49990),

        ('ORC-SIN', 'mensal', 9990),
        ('ORC-STA', 'mensal', 14990),
        ('ORC-ADV', 'mensal', 19990),
        ('ORC-PRO', 'mensal', 29990),
        ('ORC-UNL', 'mensal', 39990),

        ('BDR-SIN', 'mensal', 3990),
        ('BDR-STA', 'mensal', 5990),
        ('BDR-ADV', 'mensal', 9990),
        ('BDR-PRO', 'mensal', 19990),
        ('BDR-UNL', 'mensal', 29990),

        ('FIN-SIN', 'mensal', 3990),
        ('FIN-STA', 'mensal', 5990),
        ('FIN-ADV', 'mensal', 9990),
        ('FIN-PRO', 'mensal', 19990),
        ('FIN-UNL', 'mensal', 29990),

        ('FIS-UNL', 'mensal', 199990)
) AS v(offer_code, billing_period, amount_cents)
    ON v.offer_code = o.offer_code
WHERE NOT EXISTS (
    SELECT 1
    FROM product.offer_price p
    WHERE p.offer_id = o.offer_id
      AND p.billing_period = v.billing_period
      AND p.amount_cents = v.amount_cents
      AND p.valid_to IS NULL
);

-- ------------------------------------------------------------
-- product.addon
-- Função:
--   Capacidade adicional vendável vinculada a um produto.
--   Ex.: PRICE2/PRICE3/PRICE4 como evolução do motor do Price.
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS product.addon (
    addon_id       INT         GENERATED ALWAYS AS IDENTITY,
    product_id     INT         NOT NULL,
    addon_code     TEXT        NOT NULL,
    name           TEXT        NOT NULL,
    description    TEXT,
    is_active      BOOLEAN     NOT NULL DEFAULT TRUE,
    created_at     TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at     TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT addon_pkey PRIMARY KEY (addon_id),
    CONSTRAINT uq_addon_product_code UNIQUE (product_id, addon_code),
    CONSTRAINT fk_addon_product FOREIGN KEY (product_id)
        REFERENCES product.product (product_id) ON DELETE CASCADE,
    CONSTRAINT ck_addon_code_not_blank CHECK (btrim(addon_code) <> '')
);

-- ------------------------------------------------------------
-- product.addon_entitlement
-- Função:
--   Define o que o add-on libera sobre o produto-base.
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS product.addon_entitlement (
    addon_entitlement_id INT         GENERATED ALWAYS AS IDENTITY,
    addon_id             INT         NOT NULL,
    grant_model          TEXT        NOT NULL,
    unit                 TEXT,
    quantity             INTEGER,
    period_unit          TEXT,
    rule_json            JSONB       NOT NULL DEFAULT '{}',
    is_active            BOOLEAN     NOT NULL DEFAULT TRUE,
    created_at           TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at           TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT addon_entitlement_pkey PRIMARY KEY (addon_entitlement_id),
    CONSTRAINT fk_addon_entitlement_addon FOREIGN KEY (addon_id)
        REFERENCES product.addon (addon_id) ON DELETE CASCADE,
    CONSTRAINT ck_addon_entitlement_grant_model CHECK (grant_model IN (
        'acesso_capacidade',
        'contador_uso',
        'limite_recurso_ativo',
        'acesso_modulo',
        'ilimitado',
        'personalizado'
    )),
    CONSTRAINT ck_addon_entitlement_quantity CHECK (quantity IS NULL OR quantity >= 0)
);

-- ------------------------------------------------------------
-- product.addon_price
-- Função:
--   Histórico de preço do add-on.
--   Pode manter regra comercial própria, independente da oferta-base.
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS product.addon_price (
    addon_price_id   INT         GENERATED ALWAYS AS IDENTITY,
    addon_id         INT         NOT NULL,
    currency         TEXT        NOT NULL DEFAULT 'BRL',
    amount_cents     BIGINT      NOT NULL,
    billing_period   TEXT        NOT NULL,
    valid_from       TIMESTAMPTZ NOT NULL DEFAULT now(),
    valid_to         TIMESTAMPTZ,
    is_active        BOOLEAN     NOT NULL DEFAULT TRUE,
    created_at       TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at       TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT addon_price_pkey PRIMARY KEY (addon_price_id),
    CONSTRAINT fk_addon_price_addon FOREIGN KEY (addon_id)
        REFERENCES product.addon (addon_id) ON DELETE CASCADE,
    CONSTRAINT ck_addon_price_amount CHECK (amount_cents >= 0),
    CONSTRAINT ck_addon_price_period CHECK (billing_period IN ('uma_vez', 'mensal', 'semestral', 'anual', 'personalizado'))
);

INSERT INTO product.addon (product_id, addon_code, name, description)
SELECT p.product_id, 'PRICE2', 'Adicional Price2', 'Capacidade adicional do Easy Price, cobrada cheia sem desconto de recorrência'
FROM product.product p
WHERE p.code = 'PR1'
ON CONFLICT (product_id, addon_code) DO NOTHING;

INSERT INTO product.addon_entitlement (
    addon_id,
    grant_model,
    unit,
    quantity,
    period_unit,
    rule_json
)
SELECT a.addon_id, 'acesso_capacidade', 'motor_precificacao', 1, 'mes', '{"capacidade":"PRICE2"}'::jsonb
FROM product.addon a
WHERE a.addon_code = 'PRICE2'
  AND NOT EXISTS (
      SELECT 1
      FROM product.addon_entitlement e
      WHERE e.addon_id = a.addon_id
        AND e.grant_model = 'acesso_capacidade'
        AND COALESCE(e.unit, '') = 'motor_precificacao'
  );

INSERT INTO product.addon_price (
    addon_id,
    currency,
    amount_cents,
    billing_period,
    valid_from
)
SELECT a.addon_id, 'BRL', v.amount_cents, v.billing_period, now()
FROM product.addon a
JOIN (
    VALUES
        ('PRICE2', 'mensal', 990),
        ('PRICE2', 'semestral', 990),
        ('PRICE2', 'anual', 990)
) AS v(addon_code, billing_period, amount_cents)
    ON v.addon_code = a.addon_code
WHERE NOT EXISTS (
    SELECT 1
    FROM product.addon_price p
    WHERE p.addon_id = a.addon_id
      AND p.billing_period = v.billing_period
      AND p.amount_cents = v.amount_cents
      AND p.valid_to IS NULL
);

-- ------------------------------------------------------------
-- product.combo
-- Função:
--   Agrupamento comercial de ofertas com condição própria.
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS product.combo (
    combo_id      INT         GENERATED ALWAYS AS IDENTITY,
    codigo        TEXT        NOT NULL,
    nome          TEXT        NOT NULL,
    descricao     TEXT,
    ativo         BOOLEAN     NOT NULL DEFAULT TRUE,
    criado_em     TIMESTAMPTZ NOT NULL DEFAULT now(),
    atualizado_em TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT combo_pkey PRIMARY KEY (combo_id),
    CONSTRAINT uq_combo_codigo UNIQUE (codigo),
    CONSTRAINT ck_combo_codigo_vazio CHECK (btrim(codigo) <> '')
);

-- ------------------------------------------------------------
-- product.combo_item
-- Função:
--   Ofertas incluídas em um combo.
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS product.combo_item (
    combo_item_id  INT         GENERATED ALWAYS AS IDENTITY,
    combo_id       INT         NOT NULL,
    offer_id       INT         NOT NULL,
    quantity       INTEGER     NOT NULL DEFAULT 1,
    is_active      BOOLEAN     NOT NULL DEFAULT TRUE,
    created_at     TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at     TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT combo_item_pkey PRIMARY KEY (combo_item_id),
    CONSTRAINT uq_combo_item UNIQUE (combo_id, offer_id),
    CONSTRAINT fk_combo_item_combo FOREIGN KEY (combo_id)
        REFERENCES product.combo (combo_id) ON DELETE CASCADE,
    CONSTRAINT fk_combo_item_offer FOREIGN KEY (offer_id)
        REFERENCES product.offer (offer_id) ON DELETE RESTRICT,
    CONSTRAINT ck_combo_item_quantity CHECK (quantity >= 1)
);

-- ============================================================
-- SCHEMA: analytics
-- Função:
--   Coleta canônica de analytics do site público da Axys.
--   Mantém contexto de visitor/session, fatos brutos de page_view/event
--   e catálogo semântico de eventos, deixando score e interpretações
--   para camadas posteriores.
-- ============================================================

-- ------------------------------------------------------------
-- analytics.provider_config
-- Função:
--   Configuração de integrações externas de analytics/marketing.
-- Motivo:
--   Centralizar conectores de terceiros por propriedade digital.
-- Nível de controle:
--   Alto. A Axys liga, desliga e versiona providers externamente.
-- Como funciona:
--   Cada provider fica registrado por site_code com seus parâmetros
--   operacionais e segredos referenciados.
-- Como ler/usar:
--   Ler para saber o que pode ser carregado no frontend/backend em cada
--   propriedade digital pública.
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS analytics.provider_config (
    provider_config_id INT         GENERATED ALWAYS AS IDENTITY,
    site_code          TEXT        NOT NULL,
    provider_code      TEXT        NOT NULL,
    provider_name      TEXT        NOT NULL,
    provider_type      TEXT        NOT NULL,
    status             TEXT        NOT NULL DEFAULT 'active',
    measurement_id     TEXT,
    secret_ref         TEXT,
    config_json        JSONB       NOT NULL DEFAULT '{}',
    created_at         TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at         TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT provider_config_pkey PRIMARY KEY (provider_config_id),
    CONSTRAINT uq_provider_config_site_provider UNIQUE (site_code, provider_code),
    CONSTRAINT ck_provider_config_site_code CHECK (site_code ~ '^[A-Z][A-Z0-9_]{2,49}$'),
    CONSTRAINT ck_provider_config_provider_code CHECK (provider_code ~ '^[A-Z][A-Z0-9_]{2,49}$'),
    CONSTRAINT ck_provider_config_status CHECK (status IN ('active', 'inactive', 'testing', 'deprecated')),
    CONSTRAINT ck_provider_config_provider_type CHECK (provider_type IN ('analytics', 'tag_manager', 'pixel', 'session_replay', 'other')),
    CONSTRAINT ck_provider_config_name_notempty CHECK (btrim(provider_name) <> ''),
    CONSTRAINT ck_provider_config_json_object CHECK (jsonb_typeof(config_json) = 'object')
);

CREATE INDEX IF NOT EXISTS idx_provider_config_site ON analytics.provider_config (site_code);

-- ------------------------------------------------------------
-- analytics.visitor
-- Função:
--   Continuidade anônima de navegação em uma propriedade digital.
-- Motivo:
--   Permitir rastrear retorno e jornada sem depender de identidade real.
-- Nível de controle:
--   Altíssimo. É a raiz contextual da captura pública.
-- Como funciona:
--   O visitor nasce com UUID e fica escopado por site_code.
--   Reuso do mesmo visitor atualiza last_seen_at sem duplicar entidade.
-- Como ler/usar:
--   Ler para coortes de visitantes únicos, recorrência e futura ligação
--   com lead/user/tenant.
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS analytics.visitor (
    visitor_id          UUID        NOT NULL DEFAULT gen_random_uuid(),
    site_code           TEXT        NOT NULL,
    first_seen_at       TIMESTAMPTZ NOT NULL DEFAULT now(),
    last_seen_at        TIMESTAMPTZ NOT NULL DEFAULT now(),
    first_referrer_url  TEXT,
    first_landing_path  TEXT,
    first_country_code  TEXT,
    first_region_code   TEXT,
    first_city          TEXT,
    preferred_language  TEXT,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT analytics_visitor_pkey PRIMARY KEY (visitor_id),
    CONSTRAINT ck_analytics_visitor_site_code CHECK (site_code ~ '^[A-Z][A-Z0-9_]{2,49}$'),
    CONSTRAINT ck_analytics_visitor_seen_order CHECK (last_seen_at >= first_seen_at),
    CONSTRAINT ck_analytics_visitor_landing_path CHECK (
        first_landing_path IS NULL OR first_landing_path = '' OR first_landing_path LIKE '/%'
    ),
    CONSTRAINT ck_analytics_visitor_country_code CHECK (
        first_country_code IS NULL OR first_country_code ~ '^[A-Z]{2,3}$'
    ),
    CONSTRAINT ck_analytics_visitor_language_notempty CHECK (
        preferred_language IS NULL OR btrim(preferred_language) <> ''
    )
);

CREATE INDEX IF NOT EXISTS idx_analytics_visitor_site ON analytics.visitor (site_code);
CREATE INDEX IF NOT EXISTS idx_analytics_visitor_last_seen ON analytics.visitor (last_seen_at);

-- ------------------------------------------------------------
-- analytics.session
-- Função:
--   Contexto técnico de uma visita do início até o fechamento canônico.
-- Motivo:
--   Organizar aquisição imediata, device e janela temporal da jornada.
-- Nível de controle:
--   Alto. É contexto, não substitui os fatos detalhados.
-- Como funciona:
--   A sessão nasce com started_at e last_activity_at. O worker fecha a
--   sessão após 30 minutos de inatividade, consolidando ended_at.
-- Como ler/usar:
--   Ler para jornada por visitor, contexto de origem e janela de sessão.
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS analytics.session (
    session_id       UUID        NOT NULL DEFAULT gen_random_uuid(),
    visitor_id       UUID        NOT NULL,
    started_at       TIMESTAMPTZ NOT NULL DEFAULT now(),
    last_activity_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    ended_at         TIMESTAMPTZ,
    duration_ms      BIGINT,
    exit_path        TEXT,
    device_type      TEXT,
    browser_family   TEXT,
    os_family        TEXT,
    screen_width     INTEGER,
    screen_height    INTEGER,
    timezone         TEXT,
    country_code     TEXT,
    region_code      TEXT,
    city             TEXT,
    referrer_url     TEXT,
    utm_source       TEXT,
    utm_medium       TEXT,
    utm_campaign     TEXT,
    utm_term         TEXT,
    utm_content      TEXT,
    landing_path     TEXT,
    created_at       TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at       TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT analytics_session_pkey PRIMARY KEY (session_id),
    CONSTRAINT fk_analytics_session_visitor FOREIGN KEY (visitor_id)
        REFERENCES analytics.visitor (visitor_id) ON DELETE CASCADE,
    CONSTRAINT ck_analytics_session_activity_order CHECK (last_activity_at >= started_at),
    CONSTRAINT ck_analytics_session_end_order CHECK (ended_at IS NULL OR ended_at >= started_at),
    CONSTRAINT ck_analytics_session_end_activity CHECK (ended_at IS NULL OR ended_at = last_activity_at),
    CONSTRAINT ck_analytics_session_duration CHECK (duration_ms IS NULL OR duration_ms >= 0),
    CONSTRAINT ck_analytics_session_duration_end CHECK (duration_ms IS NULL OR ended_at IS NOT NULL),
    CONSTRAINT ck_analytics_session_exit_path CHECK (exit_path IS NULL OR exit_path = '' OR exit_path LIKE '/%'),
    CONSTRAINT ck_analytics_session_landing_path CHECK (landing_path IS NULL OR landing_path = '' OR landing_path LIKE '/%'),
    CONSTRAINT ck_analytics_session_country_code CHECK (country_code IS NULL OR country_code ~ '^[A-Z]{2,3}$'),
    CONSTRAINT ck_analytics_session_screen_width CHECK (screen_width IS NULL OR screen_width >= 1),
    CONSTRAINT ck_analytics_session_screen_height CHECK (screen_height IS NULL OR screen_height >= 1),
    CONSTRAINT ck_analytics_session_device_type CHECK (
        device_type IS NULL OR device_type IN ('desktop', 'mobile', 'tablet', 'bot', 'other')
    )
);

CREATE INDEX IF NOT EXISTS idx_analytics_session_visitor_started
    ON analytics.session (visitor_id, started_at);
CREATE INDEX IF NOT EXISTS idx_analytics_session_started
    ON analytics.session (started_at);
CREATE INDEX IF NOT EXISTS idx_analytics_session_last_activity
    ON analytics.session (last_activity_at);

-- ------------------------------------------------------------
-- analytics.page_view
-- Função:
--   Fato bruto de visualização de página lógica.
-- Motivo:
--   Registrar a jornada navegacional sem confundir página com clique ou modal.
-- Nível de controle:
--   Altíssimo. É fato primário de funil e sequência.
-- Como funciona:
--   Cada mudança de página lógica gera um page_view com sequence_no e
--   ingestion_key para deduplicação.
-- Como ler/usar:
--   Ler para funis, sequência por sessão, páginas mais vistas e tempo por página.
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS analytics.page_view (
    page_view_id   UUID        NOT NULL DEFAULT gen_random_uuid(),
    session_id     UUID        NOT NULL,
    ingestion_key  UUID        NOT NULL,
    sequence_no    INTEGER     NOT NULL,
    page_path      TEXT        NOT NULL,
    page_title     TEXT,
    page_type      TEXT,
    product_id     INT,
    dwell_ms       BIGINT,
    referrer_path  TEXT,
    viewed_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    created_at     TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT analytics_page_view_pkey PRIMARY KEY (page_view_id),
    CONSTRAINT uq_analytics_page_view_ingestion UNIQUE (ingestion_key),
    CONSTRAINT uq_analytics_page_view_session_sequence UNIQUE (session_id, sequence_no),
    CONSTRAINT uq_analytics_page_view_id_session UNIQUE (page_view_id, session_id),
    CONSTRAINT fk_analytics_page_view_session FOREIGN KEY (session_id)
        REFERENCES analytics.session (session_id) ON DELETE CASCADE,
    CONSTRAINT fk_analytics_page_view_product FOREIGN KEY (product_id)
        REFERENCES product.product (product_id) ON DELETE SET NULL,
    CONSTRAINT ck_analytics_page_view_sequence CHECK (sequence_no >= 1),
    CONSTRAINT ck_analytics_page_view_page_path CHECK (page_path LIKE '/%'),
    CONSTRAINT ck_analytics_page_view_referrer_path CHECK (
        referrer_path IS NULL OR referrer_path = '' OR referrer_path LIKE '/%'
    ),
    CONSTRAINT ck_analytics_page_view_dwell CHECK (dwell_ms IS NULL OR dwell_ms >= 0)
);

CREATE INDEX IF NOT EXISTS idx_analytics_page_view_session_viewed
    ON analytics.page_view (session_id, viewed_at);
CREATE INDEX IF NOT EXISTS idx_analytics_page_view_path
    ON analytics.page_view (page_path);

-- ------------------------------------------------------------
-- analytics.event_type
-- Função:
--   Catálogo semântico versionado dos eventos rastreáveis.
-- Motivo:
--   Evitar typo, versionar significado e governar o payload aceito.
-- Nível de controle:
--   Altíssimo. É a dimensão semântica do domínio.
-- Como funciona:
--   O backend registra event_code + event_version e documenta o payload em
--   payload_schema_json. O fato analytics.event só referencia esse catálogo.
-- Como ler/usar:
--   Ler para documentação, governança de eventos ativos e interpretação histórica.
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS analytics.event_type (
    event_type_id       BIGINT      GENERATED ALWAYS AS IDENTITY,
    event_code          TEXT        NOT NULL,
    event_version       INTEGER     NOT NULL DEFAULT 1,
    event_name          TEXT,
    category            TEXT        NOT NULL,
    scope               TEXT        NOT NULL DEFAULT 'site_public',
    description         TEXT        NOT NULL,
    is_public           BOOLEAN     NOT NULL DEFAULT TRUE,
    is_enabled          BOOLEAN     NOT NULL DEFAULT TRUE,
    is_scoreable        BOOLEAN     NOT NULL DEFAULT FALSE,
    payload_schema_json JSONB       NOT NULL DEFAULT '{}',
    valid_from          TIMESTAMPTZ NOT NULL DEFAULT now(),
    valid_until         TIMESTAMPTZ,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT analytics_event_type_pkey PRIMARY KEY (event_type_id),
    CONSTRAINT uq_analytics_event_type_code_version UNIQUE (event_code, event_version),
    CONSTRAINT ck_analytics_event_type_code CHECK (event_code ~ '^[a-z][a-z0-9_]{2,99}$'),
    CONSTRAINT ck_analytics_event_type_version CHECK (event_version >= 1),
    CONSTRAINT ck_analytics_event_type_category CHECK (
        category IN ('navigation', 'discovery', 'conversion', 'engagement', 'system')
    ),
    CONSTRAINT ck_analytics_event_type_scope CHECK (
        scope IN ('site_public', 'landing', 'campaign', 'other')
    ),
    CONSTRAINT ck_analytics_event_type_valid_range CHECK (
        valid_until IS NULL OR valid_until >= valid_from
    ),
    CONSTRAINT ck_analytics_event_type_description_notempty CHECK (btrim(description) <> ''),
    CONSTRAINT ck_analytics_event_type_payload_json_object CHECK (jsonb_typeof(payload_schema_json) = 'object')
);

CREATE INDEX IF NOT EXISTS idx_analytics_event_type_category_enabled
    ON analytics.event_type (category, is_enabled);

-- ------------------------------------------------------------
-- analytics.event
-- Função:
--   Fato bruto de interação ou comportamento dentro de uma sessão.
-- Motivo:
--   Registrar intenção e interação fina sem embutir interpretação comercial.
-- Nível de controle:
--   Altíssimo. É o fato mais granular do domínio.
-- Como funciona:
--   Cada ocorrência relevante é gravada com event_type_id e ingestion_key.
--   Quando houver vínculo com página, page_view_id precisa pertencer à mesma sessão.
-- Como ler/usar:
--   Ler para intenção por produto, etapas de conversão e sinais para camadas derivadas.
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS analytics.event (
    event_id        UUID          NOT NULL DEFAULT gen_random_uuid(),
    session_id      UUID          NOT NULL,
    page_view_id    UUID,
    ingestion_key   UUID          NOT NULL,
    event_type_id   BIGINT        NOT NULL,
    component       TEXT,
    product_id      INT,
    feature_code    TEXT,
    value_numeric   NUMERIC(18,6),
    metadata_json   JSONB         NOT NULL DEFAULT '{}',
    occurred_at     TIMESTAMPTZ   NOT NULL DEFAULT now(),
    created_at      TIMESTAMPTZ   NOT NULL DEFAULT now(),

    CONSTRAINT analytics_event_pkey PRIMARY KEY (event_id),
    CONSTRAINT uq_analytics_event_ingestion UNIQUE (ingestion_key),
    CONSTRAINT fk_analytics_event_session FOREIGN KEY (session_id)
        REFERENCES analytics.session (session_id) ON DELETE CASCADE,
    CONSTRAINT fk_analytics_event_page_view_session FOREIGN KEY (page_view_id, session_id)
        REFERENCES analytics.page_view (page_view_id, session_id) ON DELETE RESTRICT,
    CONSTRAINT fk_analytics_event_type FOREIGN KEY (event_type_id)
        REFERENCES analytics.event_type (event_type_id) ON DELETE RESTRICT,
    CONSTRAINT fk_analytics_event_product FOREIGN KEY (product_id)
        REFERENCES product.product (product_id) ON DELETE SET NULL,
    CONSTRAINT ck_analytics_event_metadata_json_object CHECK (jsonb_typeof(metadata_json) = 'object')
);

CREATE INDEX IF NOT EXISTS idx_analytics_event_session_occurred
    ON analytics.event (session_id, occurred_at);
CREATE INDEX IF NOT EXISTS idx_analytics_event_type_occurred
    ON analytics.event (event_type_id, occurred_at);
CREATE INDEX IF NOT EXISTS idx_analytics_event_page_view
    ON analytics.event (page_view_id);

-- ============================================================
-- SCHEMA: commercial
-- Função:
--   Parceiros, leads, atribuição comercial e comissões.
--   Partner é canal de aquisição. Comissão é por receita recebida.
-- ============================================================

-- ------------------------------------------------------------
-- commercial.partner
-- Função:
--   Parceiro comercial, afiliado, revendedor, consultor ou canal.
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS commercial.partner (
    partner_id      INT         GENERATED ALWAYS AS IDENTITY,
    partner_code    TEXT        NOT NULL,
    name            TEXT        NOT NULL,
    document        TEXT,
    email           TEXT,
    phone           TEXT,
    commission_model TEXT       NOT NULL DEFAULT 'revenue_share',
    status          TEXT        NOT NULL DEFAULT 'active',
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT partner_pkey PRIMARY KEY (partner_id),
    CONSTRAINT uq_partner_code UNIQUE (partner_code),
    CONSTRAINT ck_partner_status CHECK (status IN ('active', 'inactive', 'blocked')),
    CONSTRAINT ck_partner_commission_model CHECK (commission_model IN ('revenue_share', 'fixed', 'custom'))
);

-- ------------------------------------------------------------
-- commercial.lead
-- Função:
--   Lead capturado antes ou durante o onboarding. Pode virar tenant.
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS commercial.lead (
    lead_id    INT         GENERATED ALWAYS AS IDENTITY,
    tenant_id  UUID,
    name       TEXT,
    email      TEXT,
    phone      TEXT,
    origin     TEXT,
    ref_code   TEXT,
    status     TEXT        NOT NULL DEFAULT 'new',
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT lead_pkey PRIMARY KEY (lead_id),
    CONSTRAINT fk_lead_tenant FOREIGN KEY (tenant_id)
        REFERENCES identity.hub_tenant (tenant_id) ON DELETE SET NULL,
    CONSTRAINT ck_lead_status CHECK (status IN ('new', 'registered', 'converted', 'discarded'))
);

-- ------------------------------------------------------------
-- analytics.visitor_identity_link
-- Função:
--   Vínculo canônico entre visitor identificado e lead formal.
-- Motivo:
--   Marcar o instante em que a navegação deixa de ser apenas anônima
--   e passa a representar uma pessoa identificável no contexto comercial.
-- Nível de controle:
--   Altíssimo. Une comportamento analítico e identificação explícita.
-- Como funciona:
--   Quando um formulário público identifica a pessoa, o Hub cria ou
--   atualiza o vínculo visitor -> lead, preservando fonte e dados de
--   identificação conhecidos naquele momento.
-- Como ler/usar:
--   Ler para reconciliar jornada anônima, momento de identificação e
--   continuidade comercial da pessoa conhecida.
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS analytics.visitor_identity_link (
    visitor_identity_link_id BIGINT      GENERATED ALWAYS AS IDENTITY,
    visitor_id               UUID        NOT NULL,
    lead_id                  INT         NOT NULL,
    identified_name          TEXT,
    identified_email         TEXT,
    identified_phone         TEXT,
    identification_source    TEXT        NOT NULL,
    first_identified_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    last_identified_at       TIMESTAMPTZ NOT NULL DEFAULT now(),
    created_at               TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at               TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT analytics_visitor_identity_link_pkey PRIMARY KEY (visitor_identity_link_id),
    CONSTRAINT uq_analytics_visitor_identity_link UNIQUE (visitor_id, lead_id),
    CONSTRAINT fk_analytics_visitor_identity_link_visitor FOREIGN KEY (visitor_id)
        REFERENCES analytics.visitor (visitor_id) ON DELETE CASCADE,
    CONSTRAINT fk_analytics_visitor_identity_link_lead FOREIGN KEY (lead_id)
        REFERENCES commercial.lead (lead_id) ON DELETE CASCADE,
    CONSTRAINT ck_analytics_visitor_identity_link_source CHECK (
        identification_source IN ('SITE_CONTACT', 'SITE_SIGNUP', 'SITE_CAPTURE_MODAL', 'MANUAL', 'OTHER')
    ),
    CONSTRAINT ck_analytics_visitor_identity_link_order CHECK (last_identified_at >= first_identified_at),
    CONSTRAINT ck_analytics_visitor_identity_link_email_notempty CHECK (
        identified_email IS NULL OR btrim(identified_email) <> ''
    ),
    CONSTRAINT ck_analytics_visitor_identity_link_name_notempty CHECK (
        identified_name IS NULL OR btrim(identified_name) <> ''
    )
);

CREATE INDEX IF NOT EXISTS idx_analytics_visitor_identity_link_visitor
    ON analytics.visitor_identity_link (visitor_id, last_identified_at);
CREATE INDEX IF NOT EXISTS idx_analytics_visitor_identity_link_lead
    ON analytics.visitor_identity_link (lead_id, last_identified_at);

-- ------------------------------------------------------------
-- commercial.referral_visit
-- Função:
--   Registro da visita com código de parceiro/ref.
--   Captura ocorre no ato da entrada.
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS commercial.referral_visit (
    visit_id    INT         GENERATED ALWAYS AS IDENTITY,
    partner_id  INT,
    ref_code    TEXT,
    ip          TEXT,
    user_agent  TEXT,
    landing_url TEXT,
    cookie_id   TEXT,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT referral_visit_pkey PRIMARY KEY (visit_id),
    CONSTRAINT fk_referral_visit_partner FOREIGN KEY (partner_id)
        REFERENCES commercial.partner (partner_id) ON DELETE SET NULL
);

-- ------------------------------------------------------------
-- commercial.tenant_attribution
-- Função:
--   Define o dono comercial do tenant.
--   Regra: quem trouxe o cliente é dono do cliente enquanto houver recorrência.
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS commercial.tenant_attribution (
    attribution_id   INT         GENERATED ALWAYS AS IDENTITY,
    tenant_id        UUID        NOT NULL,
    partner_id       INT,
    attribution_type TEXT        NOT NULL DEFAULT 'partner',
    status           TEXT        NOT NULL DEFAULT 'active',
    started_at       TIMESTAMPTZ NOT NULL DEFAULT now(),
    ended_at         TIMESTAMPTZ,
    reason           TEXT,

    CONSTRAINT tenant_attribution_pkey PRIMARY KEY (attribution_id),
    CONSTRAINT fk_tenant_attribution_tenant FOREIGN KEY (tenant_id)
        REFERENCES identity.hub_tenant (tenant_id) ON DELETE CASCADE,
    CONSTRAINT fk_tenant_attribution_partner FOREIGN KEY (partner_id)
        REFERENCES commercial.partner (partner_id) ON DELETE SET NULL,
    CONSTRAINT ck_tenant_attribution_type CHECK (attribution_type IN ('partner', 'manual', 'axys')),
    CONSTRAINT ck_tenant_attribution_status CHECK (status IN ('active', 'ended'))
);

CREATE UNIQUE INDEX IF NOT EXISTS uq_tenant_attribution_active
    ON commercial.tenant_attribution (tenant_id)
    WHERE status = 'active';

-- ------------------------------------------------------------
-- commercial.commission_rule
-- Função:
--   Regra de comissão por parceiro/ecossistema/produto.
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS commercial.commission_rule (
    rule_id      INT         GENERATED ALWAYS AS IDENTITY,
    partner_id   INT,
    ecosystem_id INT,
    product_id   INT,
    percent      NUMERIC(7,4),
    fixed_cents  BIGINT,
    status       TEXT        NOT NULL DEFAULT 'active',
    valid_from   TIMESTAMPTZ NOT NULL DEFAULT now(),
    valid_until  TIMESTAMPTZ,

    CONSTRAINT commission_rule_pkey PRIMARY KEY (rule_id),
    CONSTRAINT fk_commission_rule_partner FOREIGN KEY (partner_id)
        REFERENCES commercial.partner (partner_id) ON DELETE CASCADE,
    CONSTRAINT fk_commission_rule_ecosystem FOREIGN KEY (ecosystem_id)
        REFERENCES product.ecosystem (ecosystem_id) ON DELETE SET NULL,
    CONSTRAINT fk_commission_rule_product FOREIGN KEY (product_id)
        REFERENCES product.product (product_id) ON DELETE SET NULL,
    CONSTRAINT ck_commission_rule_percent CHECK (percent IS NULL OR (percent >= 0 AND percent <= 100)),
    CONSTRAINT ck_commission_rule_fixed CHECK (fixed_cents IS NULL OR fixed_cents >= 0),
    CONSTRAINT ck_commission_rule_status CHECK (status IN ('active', 'inactive', 'expired'))
);

-- ------------------------------------------------------------
-- commercial.commission_event
-- Função:
--   Comissão gerada por receita recebida. Base recomendada: payment_id.
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS commercial.commission_event (
    commission_event_id BIGINT      GENERATED ALWAYS AS IDENTITY,
    partner_id          INT         NOT NULL,
    tenant_id           UUID        NOT NULL,
    payment_id          BIGINT,
    base_amount_cents   BIGINT      NOT NULL,
    percent             NUMERIC(7,4),
    commission_amount_cents BIGINT  NOT NULL,
    status              TEXT        NOT NULL DEFAULT 'pending',
    created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT commission_event_pkey PRIMARY KEY (commission_event_id),
    CONSTRAINT fk_commission_event_partner FOREIGN KEY (partner_id)
        REFERENCES commercial.partner (partner_id) ON DELETE RESTRICT,
    CONSTRAINT fk_commission_event_tenant FOREIGN KEY (tenant_id)
        REFERENCES identity.hub_tenant (tenant_id) ON DELETE CASCADE,
    CONSTRAINT ck_commission_event_base CHECK (base_amount_cents >= 0),
    CONSTRAINT ck_commission_event_amount CHECK (commission_amount_cents >= 0),
    CONSTRAINT ck_commission_event_status CHECK (status IN ('pending', 'approved', 'paid', 'canceled', 'reversed'))
);

-- ------------------------------------------------------------
-- commercial.commission_payout
-- Função:
--   Lote de pagamento de comissão ao parceiro.
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS commercial.commission_payout (
    payout_id     INT         GENERATED ALWAYS AS IDENTITY,
    partner_id    INT         NOT NULL,
    amount_cents  BIGINT      NOT NULL,
    status        TEXT        NOT NULL DEFAULT 'pending',
    paid_at       TIMESTAMPTZ,
    payload_json  JSONB       NOT NULL DEFAULT '{}',
    created_at    TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT commission_payout_pkey PRIMARY KEY (payout_id),
    CONSTRAINT fk_commission_payout_partner FOREIGN KEY (partner_id)
        REFERENCES commercial.partner (partner_id) ON DELETE RESTRICT,
    CONSTRAINT ck_commission_payout_amount CHECK (amount_cents >= 0),
    CONSTRAINT ck_commission_payout_status CHECK (status IN ('pending', 'paid', 'canceled'))
);

-- ============================================================
-- SCHEMA: orders
-- Função:
--   Pedido comercial e snapshot da compra.
--   Cada item guarda o valor efetivo vendido, independente do preço atual.
-- ============================================================

-- ------------------------------------------------------------
-- orders.hub_order
-- Função:
--   Pedido/compra realizada por tenant.
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS orders.hub_order (
    order_id    BIGINT      GENERATED ALWAYS AS IDENTITY,
    tenant_id   UUID        NOT NULL,
    user_id     UUID        NOT NULL,
    partner_id  INT,
    order_no    BIGINT      NOT NULL GENERATED BY DEFAULT AS IDENTITY,
    status      TEXT        NOT NULL DEFAULT 'draft',
    total_cents BIGINT      NOT NULL DEFAULT 0,
    currency    TEXT        NOT NULL DEFAULT 'BRL',
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT hub_order_pkey PRIMARY KEY (order_id),
    CONSTRAINT uq_hub_order_tenant_no UNIQUE (tenant_id, order_no),
    CONSTRAINT fk_hub_order_tenant FOREIGN KEY (tenant_id)
        REFERENCES identity.hub_tenant (tenant_id) ON DELETE CASCADE,
    CONSTRAINT fk_hub_order_user FOREIGN KEY (user_id)
        REFERENCES identity.hub_user (user_id) ON DELETE RESTRICT,
    CONSTRAINT fk_hub_order_partner FOREIGN KEY (partner_id)
        REFERENCES commercial.partner (partner_id) ON DELETE SET NULL,
    CONSTRAINT ck_hub_order_status CHECK (status IN ('draft', 'pending', 'paid', 'canceled', 'refunded')),
    CONSTRAINT ck_hub_order_total CHECK (total_cents >= 0)
);

-- ------------------------------------------------------------
-- orders.hub_order_item
-- Função:
--   Snapshot itemizado da venda. Base para métricas, fiscal e billing.
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS orders.hub_order_item (
    order_item_id       BIGINT  GENERATED ALWAYS AS IDENTITY,
    order_id            BIGINT  NOT NULL,
    ecosystem_id        INT,
    product_id          INT,
    offer_id            INT,
    price_id            INT,
    offer_code_snapshot TEXT,
    descricao_snapshot    TEXT,
    quantity             INTEGER NOT NULL DEFAULT 1,
    unit_cents           BIGINT  NOT NULL DEFAULT 0,
    discount_cents       BIGINT  NOT NULL DEFAULT 0,
    final_cents          BIGINT  NOT NULL DEFAULT 0,
    payload_json         JSONB   NOT NULL DEFAULT '{}',

    CONSTRAINT hub_order_item_pkey PRIMARY KEY (order_item_id),
    CONSTRAINT fk_order_item_order FOREIGN KEY (order_id)
        REFERENCES orders.hub_order (order_id) ON DELETE CASCADE,
    CONSTRAINT fk_order_item_ecosystem FOREIGN KEY (ecosystem_id)
        REFERENCES product.ecosystem (ecosystem_id) ON DELETE SET NULL,
    CONSTRAINT fk_order_item_product FOREIGN KEY (product_id)
        REFERENCES product.product (product_id) ON DELETE SET NULL,
    CONSTRAINT fk_order_item_offer FOREIGN KEY (offer_id)
        REFERENCES product.offer (offer_id) ON DELETE SET NULL,
    CONSTRAINT fk_order_item_price FOREIGN KEY (price_id)
        REFERENCES product.offer_price (price_id) ON DELETE SET NULL,
    CONSTRAINT ck_order_item_qty CHECK (quantity >= 1),
    CONSTRAINT ck_order_item_values CHECK (unit_cents >= 0 AND discount_cents >= 0 AND final_cents >= 0)
);

-- ------------------------------------------------------------
-- orders.hub_order_event
-- Função:
--   Log imutável do ciclo de vida do pedido.
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS orders.hub_order_event (
    order_event_id BIGINT      GENERATED ALWAYS AS IDENTITY,
    order_id       BIGINT      NOT NULL,
    tenant_id      UUID        NOT NULL,
    user_id        UUID,
    event_type     TEXT        NOT NULL,
    payload_json   JSONB       NOT NULL DEFAULT '{}',
    created_at     TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT hub_order_event_pkey PRIMARY KEY (order_event_id),
    CONSTRAINT fk_order_event_order FOREIGN KEY (order_id)
        REFERENCES orders.hub_order (order_id) ON DELETE CASCADE,
    CONSTRAINT fk_order_event_tenant FOREIGN KEY (tenant_id)
        REFERENCES identity.hub_tenant (tenant_id) ON DELETE CASCADE,
    CONSTRAINT fk_order_event_user FOREIGN KEY (user_id)
        REFERENCES identity.hub_user (user_id) ON DELETE SET NULL
);

-- ============================================================
-- SCHEMA: billing
-- Função:
--   Assinaturas, períodos, licenças, liberações e vínculo usuário-app.
-- ============================================================

-- ------------------------------------------------------------
-- billing.hub_subscription
-- Função:
--   Assinatura comercial recorrente de um tenant.
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS billing.hub_subscription (
    subscription_id INT         GENERATED ALWAYS AS IDENTITY,
    tenant_id       UUID        NOT NULL,
    partner_id      INT,
    status          TEXT        NOT NULL DEFAULT 'active',
    billing_cycle   TEXT        NOT NULL DEFAULT 'monthly',
    started_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    canceled_at     TIMESTAMPTZ,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT hub_subscription_pkey PRIMARY KEY (subscription_id),
    CONSTRAINT fk_subscription_tenant FOREIGN KEY (tenant_id)
        REFERENCES identity.hub_tenant (tenant_id) ON DELETE CASCADE,
    CONSTRAINT fk_subscription_partner FOREIGN KEY (partner_id)
        REFERENCES commercial.partner (partner_id) ON DELETE SET NULL,
    CONSTRAINT ck_subscription_status CHECK (status IN ('active', 'suspended', 'canceled', 'expired')),
    CONSTRAINT ck_subscription_cycle CHECK (billing_cycle IN ('monthly', 'annual', 'custom'))
);

-- ------------------------------------------------------------
-- billing.hub_subscription_item
-- Função:
--   Item de assinatura apontando para uma oferta comprada.
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS billing.hub_subscription_item (
    subscription_item_id INT         GENERATED ALWAYS AS IDENTITY,
    subscription_id      INT         NOT NULL,
    offer_id             INT         NOT NULL,
    price_id             INT,
    quantity             INTEGER     NOT NULL DEFAULT 1,
    status               TEXT        NOT NULL DEFAULT 'active',
    started_at           TIMESTAMPTZ NOT NULL DEFAULT now(),
    ended_at             TIMESTAMPTZ,

    CONSTRAINT hub_subscription_item_pkey PRIMARY KEY (subscription_item_id),
    CONSTRAINT fk_subscription_item_subscription FOREIGN KEY (subscription_id)
        REFERENCES billing.hub_subscription (subscription_id) ON DELETE CASCADE,
    CONSTRAINT fk_subscription_item_offer FOREIGN KEY (offer_id)
        REFERENCES product.offer (offer_id) ON DELETE RESTRICT,
    CONSTRAINT fk_subscription_item_price FOREIGN KEY (price_id)
        REFERENCES product.offer_price (price_id) ON DELETE SET NULL,
    CONSTRAINT ck_subscription_item_qty CHECK (quantity >= 1),
    CONSTRAINT ck_subscription_item_status CHECK (status IN ('active', 'inactive', 'canceled'))
);

-- ------------------------------------------------------------
-- billing.hub_subscription_period
-- Função:
--   Competências/períodos de cobrança de uma assinatura.
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS billing.hub_subscription_period (
    period_id       INT         GENERATED ALWAYS AS IDENTITY,
    subscription_id INT         NOT NULL,
    competencia     TEXT        NOT NULL,
    status          TEXT        NOT NULL DEFAULT 'pending',
    due_date        DATE,
    paid_at         TIMESTAMPTZ,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT hub_subscription_period_pkey PRIMARY KEY (period_id),
    CONSTRAINT uq_subscription_period UNIQUE (subscription_id, competencia),
    CONSTRAINT fk_period_subscription FOREIGN KEY (subscription_id)
        REFERENCES billing.hub_subscription (subscription_id) ON DELETE CASCADE,
    CONSTRAINT ck_period_competencia CHECK (competencia ~ '^\d{4}-\d{2}$'),
    CONSTRAINT ck_period_status CHECK (status IN ('pending', 'paid', 'overdue', 'canceled'))
);

-- ------------------------------------------------------------
-- billing.hub_license
-- Função:
--   Licença técnica que habilita produto para tenant.
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS billing.hub_license (
    license_id      INT         GENERATED ALWAYS AS IDENTITY,
    subscription_id INT,
    tenant_id       UUID        NOT NULL,
    product_id      INT         NOT NULL,
    status          TEXT        NOT NULL DEFAULT 'active',
    valid_from      TIMESTAMPTZ,
    valid_until     TIMESTAMPTZ,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT hub_license_pkey PRIMARY KEY (license_id),
    CONSTRAINT uq_license_tenant_product UNIQUE (tenant_id, product_id),
    CONSTRAINT fk_license_subscription FOREIGN KEY (subscription_id)
        REFERENCES billing.hub_subscription (subscription_id) ON DELETE SET NULL,
    CONSTRAINT fk_license_tenant FOREIGN KEY (tenant_id)
        REFERENCES identity.hub_tenant (tenant_id) ON DELETE CASCADE,
    CONSTRAINT fk_license_product FOREIGN KEY (product_id)
        REFERENCES product.product (product_id) ON DELETE RESTRICT,
    CONSTRAINT ck_license_status CHECK (status IN ('active', 'suspended', 'expired', 'revoked'))
);

-- ------------------------------------------------------------
-- billing.hub_license_key
-- Função:
--   Chaves criptográficas de licença.
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS billing.hub_license_key (
    license_key_id INT         GENERATED ALWAYS AS IDENTITY,
    license_id     INT         NOT NULL,
    sha256_key      CHAR(64)    NOT NULL,
    issued_at       TIMESTAMPTZ NOT NULL DEFAULT now(),
    expires_at      TIMESTAMPTZ,
    status          TEXT        NOT NULL DEFAULT 'active',

    CONSTRAINT hub_license_key_pkey PRIMARY KEY (license_key_id),
    CONSTRAINT uq_license_key_sha UNIQUE (sha256_key),
    CONSTRAINT fk_license_key_license FOREIGN KEY (license_id)
        REFERENCES billing.hub_license (license_id) ON DELETE CASCADE,
    CONSTRAINT ck_license_key_status CHECK (status IN ('active', 'expired', 'revoked'))
);

-- ------------------------------------------------------------
-- billing.hub_license_activation
-- Função:
--   Registro de validação de licença por ambiente.
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS billing.hub_license_activation (
    activation_id      BIGINT      GENERATED ALWAYS AS IDENTITY,
    license_id         INT         NOT NULL,
    environment_id     TEXT,
    last_validation_at TIMESTAMPTZ,
    status             TEXT        NOT NULL DEFAULT 'ok',
    created_at         TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT hub_license_activation_pkey PRIMARY KEY (activation_id),
    CONSTRAINT fk_license_activation_license FOREIGN KEY (license_id)
        REFERENCES billing.hub_license (license_id) ON DELETE CASCADE,
    CONSTRAINT ck_license_activation_status CHECK (status IN ('ok', 'invalid', 'expired'))
);

-- ------------------------------------------------------------
-- billing.hub_user_app
-- Função:
--   Vínculo efetivo user ↔ product/app dentro do tenant.
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS billing.hub_user_app (
    tenant_id  UUID        NOT NULL,
    user_id    UUID        NOT NULL,
    product_id INT         NOT NULL,
    status     TEXT        NOT NULL DEFAULT 'active',
    granted_at TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT hub_user_app_pkey PRIMARY KEY (tenant_id, user_id, product_id),
    CONSTRAINT fk_user_app_tenant FOREIGN KEY (tenant_id)
        REFERENCES identity.hub_tenant (tenant_id) ON DELETE CASCADE,
    CONSTRAINT fk_user_app_user FOREIGN KEY (user_id)
        REFERENCES identity.hub_user (user_id) ON DELETE CASCADE,
    CONSTRAINT fk_user_app_product FOREIGN KEY (product_id)
        REFERENCES product.product (product_id) ON DELETE CASCADE,
    CONSTRAINT ck_user_app_status CHECK (status IN ('active', 'inactive'))
);

-- ------------------------------------------------------------
-- billing.hub_ai_credit_account
-- Função:
--   Saldo corrente de créditos de IA por tenant. Contas ilimitadas
--   podem ficar negativas para mensurar o consumo sem bloquear uso.
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS billing.hub_ai_credit_account (
    account_id        UUID        NOT NULL DEFAULT gen_random_uuid(),
    tenant_id         UUID        NOT NULL,
    status            TEXT        NOT NULL DEFAULT 'active',
    is_unlimited      BOOLEAN     NOT NULL DEFAULT FALSE,
    balance_credits   BIGINT      NOT NULL DEFAULT 0,
    tokens_per_credit INTEGER     NOT NULL DEFAULT 1000,
    created_at        TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at        TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT hub_ai_credit_account_pkey PRIMARY KEY (account_id),
    CONSTRAINT uq_hub_ai_credit_account_tenant UNIQUE (tenant_id),
    CONSTRAINT fk_ai_credit_account_tenant FOREIGN KEY (tenant_id)
        REFERENCES identity.hub_tenant (tenant_id) ON DELETE CASCADE,
    CONSTRAINT ck_ai_credit_account_status CHECK (status IN ('active', 'suspended', 'closed')),
    CONSTRAINT ck_ai_credit_tokens_per_credit CHECK (tokens_per_credit > 0),
    CONSTRAINT ck_ai_credit_limited_balance CHECK (is_unlimited OR balance_credits >= 0)
);

-- ------------------------------------------------------------
-- billing.hub_ai_credit_ledger
-- Função:
--   Livro-caixa imutável e idempotente das movimentações de crédito.
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS billing.hub_ai_credit_ledger (
    entry_id          UUID        NOT NULL DEFAULT gen_random_uuid(),
    account_id        UUID        NOT NULL,
    entry_type        TEXT        NOT NULL,
    quantity_credits  BIGINT      NOT NULL,
    credits_delta     BIGINT      NOT NULL,
    balance_after     BIGINT      NOT NULL,
    reason            TEXT        NOT NULL,
    idempotency_key   TEXT        NOT NULL,
    metadata          JSONB       NOT NULL DEFAULT '{}'::jsonb,
    occurred_at       TIMESTAMPTZ NOT NULL DEFAULT now(),
    created_at        TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT hub_ai_credit_ledger_pkey PRIMARY KEY (entry_id),
    CONSTRAINT uq_ai_credit_ledger_idempotency UNIQUE (account_id, idempotency_key),
    CONSTRAINT fk_ai_credit_ledger_account FOREIGN KEY (account_id)
        REFERENCES billing.hub_ai_credit_account (account_id) ON DELETE RESTRICT,
    CONSTRAINT ck_ai_credit_ledger_type CHECK (
        entry_type IN ('purchase', 'grant', 'debit', 'adjustment', 'refund', 'expiration')
    ),
    CONSTRAINT ck_ai_credit_ledger_quantity CHECK (quantity_credits > 0),
    CONSTRAINT ck_ai_credit_ledger_key CHECK (length(idempotency_key) BETWEEN 1 AND 200)
);

CREATE INDEX IF NOT EXISTS idx_ai_credit_ledger_account_occurred
    ON billing.hub_ai_credit_ledger (account_id, occurred_at DESC);

-- ------------------------------------------------------------
-- billing.hub_microapp_instance
-- Função:
--   Instância de app/produto habilitada para tenant.
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS billing.hub_microapp_instance (
    instance_id INT         GENERATED ALWAYS AS IDENTITY,
    tenant_id   UUID        NOT NULL,
    product_id  INT         NOT NULL,
    slug        TEXT        NOT NULL,
    status      TEXT        NOT NULL DEFAULT 'active',
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT hub_microapp_instance_pkey PRIMARY KEY (instance_id),
    CONSTRAINT uq_microapp_instance UNIQUE (tenant_id, product_id),
    CONSTRAINT fk_microapp_instance_tenant FOREIGN KEY (tenant_id)
        REFERENCES identity.hub_tenant (tenant_id) ON DELETE CASCADE,
    CONSTRAINT fk_microapp_instance_product FOREIGN KEY (product_id)
        REFERENCES product.product (product_id) ON DELETE RESTRICT,
    CONSTRAINT ck_microapp_instance_status CHECK (status IN ('active', 'inactive'))
);

-- ------------------------------------------------------------
-- billing.hub_microapp_config
-- Função:
--   Configuração JSONB de instância de microapp/produto por tenant.
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS billing.hub_microapp_config (
    config_id   INT         GENERATED ALWAYS AS IDENTITY,
    instance_id INT         NOT NULL,
    config_json JSONB       NOT NULL DEFAULT '{}',
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT hub_microapp_config_pkey PRIMARY KEY (config_id),
    CONSTRAINT uq_microapp_config_instance UNIQUE (instance_id),
    CONSTRAINT fk_microapp_config_instance FOREIGN KEY (instance_id)
        REFERENCES billing.hub_microapp_instance (instance_id) ON DELETE CASCADE
);

-- ============================================================
-- SEED CANÔNICO MÍNIMO
-- Função:
--   Bootstrap idempotente de tenants, usuários, vínculos, stores,
--   assinaturas, licenças, apps por usuário e instâncias iniciais.
--   Este bloco é a fonte canônica do seed inicial do AxysHub.
-- ============================================================

INSERT INTO identity.hub_tenant (tenant_id, tenant_code, tenant_name, document, status, is_active)
VALUES
    ('7847231a-4ba3-5138-b2d6-6943beb8e3f9', 'AXYS', 'Axys Engenharia e Tecnologia Ltda', '38060729810', 'active', TRUE),
    ('9b1c7c20-2a4c-5b76-9f72-0e9a4f2d4c8f', 'LUNALO', 'Lunalô Calçados e Perfumaria Ltda', '45580611000194', 'active', TRUE),
    ('d47aef9a-299d-5b8a-9fa2-b58a6050a4b0', 'DIASECARDOZO', 'Dias & Cardozo Engenharia Ltda', '17695703000184', 'active', TRUE)
ON CONFLICT (tenant_code) DO UPDATE SET
    tenant_name = EXCLUDED.tenant_name,
    document = EXCLUDED.document,
    status = EXCLUDED.status,
    is_active = EXCLUDED.is_active,
    updated_at = now();

INSERT INTO identity.hub_user (
    user_id,
    name,
    email,
    password_hash,
    phone,
    locale,
    cpf,
    address_json,
    sys_role,
    status,
    is_active
)
VALUES
    ('a40bdb6c-c47b-5ad0-bb36-8c89641005e7', 'Renan Dias', 'rdias07@live.com', crypt('axys@seed2026', gen_salt('bf', 10)), NULL, 'pt-BR', '00000000001', '{}'::jsonb, 'hub_admin', 'active', TRUE),
    ('279ae6ae-52e1-52e0-ad90-df80cbf5cd1b', 'Thaís', 'thays_hernandes@hotmail.com', crypt('axys@seed2026', gen_salt('bf', 10)), NULL, 'pt-BR', '40716917866', '{}'::jsonb, 'user', 'active', TRUE),
    ('733fa25d-157e-596f-9f86-4ad8db423881', 'Dias e Cardozo', 'diasecardozo@diasecardozo.com.br', crypt('axys@seed2026', gen_salt('bf', 10)), NULL, 'pt-BR', '00000000002', '{}'::jsonb, 'user', 'active', TRUE),
    ('993ef59d-1f49-4c7d-862e-b2bb8ddcb30f', 'Maicon Franzin', 'eng.maicon@diasecardozo.com.br', crypt('axys@seed2026', gen_salt('bf', 10)), NULL, 'pt-BR', '00000000005', '{}'::jsonb, 'user', 'active', TRUE),
    ('3464c27d-d4b4-41ba-a847-192465b2d37e', 'Julia Santana', 'eng.julia@diasecardozo.com.br', crypt('axys@seed2026', gen_salt('bf', 10)), NULL, 'pt-BR', '00000000006', '{}'::jsonb, 'user', 'active', TRUE),
    ('de059dca-0e0d-4690-9fb6-78ad4189f036', 'Vitoria', 'eng.vitoria@diasecardozo.com.br', crypt('axys@seed2026', gen_salt('bf', 10)), NULL, 'pt-BR', '00000000007', '{}'::jsonb, 'user', 'active', TRUE),
    ('c26f90c5-96d7-431b-8140-90058d88f122', 'Washington Keneddy', 'eng.washington@diasecardozo.com.br', crypt('axys@seed2026', gen_salt('bf', 10)), NULL, 'pt-BR', '00000000008', '{}'::jsonb, 'user', 'active', TRUE),
    ('83557f7e-e3f4-4002-a543-f09cc681f9ae', 'Lunalô Calcados', 'lunalocalcados@hotmail.com', crypt('axys@seed2026', gen_salt('bf', 10)), NULL, 'pt-BR', '00000000004', '{}'::jsonb, 'user', 'active', TRUE)
ON CONFLICT (email) DO NOTHING;

UPDATE identity.hub_user
SET name = 'Thais Hernandes',
    cpf = '40716917866',
    updated_at = now()
WHERE email = 'thays_hernandes@hotmail.com';

INSERT INTO identity.hub_user_tenant (tenant_id, user_id, role, is_active)
SELECT t.tenant_id, u.user_id, v.role, TRUE
FROM (
    VALUES
        ('AXYS', 'rdias07@live.com', 'internal_owner'),
        ('AXYS', 'thays_hernandes@hotmail.com', 'internal_user'),
        ('LUNALO', 'thays_hernandes@hotmail.com', 'admin'),
        ('LUNALO', 'lunalocalcados@hotmail.com', 'admin'),
        ('DIASECARDOZO', 'rdias07@live.com', 'owner'),
        ('DIASECARDOZO', 'thays_hernandes@hotmail.com', 'admin'),
        ('DIASECARDOZO', 'diasecardozo@diasecardozo.com.br', 'user'),
        ('DIASECARDOZO', 'eng.maicon@diasecardozo.com.br', 'admin'),
        ('DIASECARDOZO', 'eng.julia@diasecardozo.com.br', 'user'),
        ('DIASECARDOZO', 'eng.vitoria@diasecardozo.com.br', 'user'),
        ('DIASECARDOZO', 'eng.washington@diasecardozo.com.br', 'user')
) AS v(tenant_code, email, role)
JOIN identity.hub_tenant t ON t.tenant_code = v.tenant_code
JOIN identity.hub_user u ON u.email = v.email
ON CONFLICT (tenant_id, user_id) DO UPDATE SET
    role = EXCLUDED.role,
    is_active = EXCLUDED.is_active,
    updated_at = now();

INSERT INTO identity.hub_store (store_id, tenant_id, store_code, store_name, status, is_active)
SELECT
    v.store_id::uuid,
    t.tenant_id,
    v.store_code,
    v.store_name,
    'active',
    TRUE
FROM (
    VALUES
        ('4f64d633-a304-5fb2-ab3a-0fb92291f18d', 'AXYS', 'AXYS-TEC', 'AXYS-TEC'),
        ('50d4970e-b91e-56a7-988f-d5ecf615f55a', 'LUNALO', 'OUROESTE', 'Lunalô Ouroeste'),
        ('d6e937a1-47bd-5d3e-a4d3-11c210e3b22a', 'LUNALO', 'JALES', 'Lunalô Jales'),
        ('b09ab7ef-3f97-4bad-8b28-1aee900c5d7a', 'LUNALO', 'LOC-JALES', 'L''Occitane Jales'),
        ('74b34022-49ce-5366-8d7c-5d90526e9c85', 'DIASECARDOZO', 'DIASECARDOZO', 'Dias & Cardozo - Eng. e Arq.')
) AS v(store_id, tenant_code, store_code, store_name)
JOIN identity.hub_tenant t ON t.tenant_code = v.tenant_code
ON CONFLICT (tenant_id, store_code) DO UPDATE SET
    store_name = EXCLUDED.store_name,
    status = EXCLUDED.status,
    is_active = EXCLUDED.is_active,
    updated_at = now();

INSERT INTO identity.hub_user_store (tenant_id, user_id, store_id, role, is_active)
SELECT
    t.tenant_id,
    u.user_id,
    s.store_id,
    'user',
    TRUE
FROM (
    VALUES
        ('AXYS', 'rdias07@live.com', 'AXYS-TEC'),
        ('AXYS', 'thays_hernandes@hotmail.com', 'AXYS-TEC'),
        ('LUNALO', 'thays_hernandes@hotmail.com', 'OUROESTE'),
        ('LUNALO', 'thays_hernandes@hotmail.com', 'JALES'),
        ('LUNALO', 'thays_hernandes@hotmail.com', 'LOC-JALES'),
        ('LUNALO', 'lunalocalcados@hotmail.com', 'OUROESTE'),
        ('LUNALO', 'lunalocalcados@hotmail.com', 'JALES'),
        ('DIASECARDOZO', 'rdias07@live.com', 'DIASECARDOZO'),
        ('DIASECARDOZO', 'thays_hernandes@hotmail.com', 'DIASECARDOZO'),
        ('DIASECARDOZO', 'diasecardozo@diasecardozo.com.br', 'DIASECARDOZO'),
        ('DIASECARDOZO', 'eng.maicon@diasecardozo.com.br', 'DIASECARDOZO'),
        ('DIASECARDOZO', 'eng.julia@diasecardozo.com.br', 'DIASECARDOZO'),
        ('DIASECARDOZO', 'eng.vitoria@diasecardozo.com.br', 'DIASECARDOZO'),
        ('DIASECARDOZO', 'eng.washington@diasecardozo.com.br', 'DIASECARDOZO')
) AS v(tenant_code, email, store_code)
JOIN identity.hub_tenant t ON t.tenant_code = v.tenant_code
JOIN identity.hub_user u ON u.email = v.email
JOIN identity.hub_store s
  ON s.tenant_id = t.tenant_id
 AND s.store_code = v.store_code
ON CONFLICT (tenant_id, user_id, store_id) DO UPDATE SET
    role = EXCLUDED.role,
    is_active = EXCLUDED.is_active,
    updated_at = now();

INSERT INTO billing.hub_subscription (tenant_id, partner_id, status, billing_cycle, started_at)
SELECT t.tenant_id, NULL, 'active', 'monthly', now()
FROM identity.hub_tenant t
WHERE NOT EXISTS (
    SELECT 1
    FROM billing.hub_subscription s
    WHERE s.tenant_id = t.tenant_id
      AND s.status = 'active'
);

INSERT INTO billing.hub_license (subscription_id, tenant_id, product_id, status, valid_from, valid_until)
SELECT
    s.subscription_id,
    t.tenant_id,
    p.product_id,
    'active',
    s.started_at,
    NULL
FROM billing.hub_subscription s
JOIN identity.hub_tenant t ON t.tenant_id = s.tenant_id
JOIN product.product p
  ON (
      t.tenant_code = 'AXYS'
      AND p.code IN ('AXYSPRO', 'AXYSGESTOR', 'PRI', 'CPU', 'DOC', 'PM', 'LIC', 'ORC', 'BDR', 'FIN', 'ONE')
  )
  OR (
      t.tenant_code = 'LUNALO'
      AND p.code IN ('AXYSGESTOR')
  )
  OR (
      t.tenant_code = 'DIASECARDOZO'
      AND p.code IN ('PRI', 'CPU', 'DOC', 'PM', 'LIC', 'ORC', 'BDR', 'FIN')
  )
WHERE s.status = 'active'
ON CONFLICT (tenant_id, product_id) DO UPDATE SET
    subscription_id = EXCLUDED.subscription_id,
    status = EXCLUDED.status,
    valid_from = EXCLUDED.valid_from,
    valid_until = EXCLUDED.valid_until;

INSERT INTO identity.hub_tenant_profile (tenant_id, app_code, actor_type, is_active)
SELECT DISTINCT
    t.tenant_id,
    'gestor',
    CASE
        WHEN t.tenant_code = 'AXYS' THEN 'internal'
        ELSE 'client'
    END,
    TRUE
FROM billing.hub_license l
JOIN identity.hub_tenant t ON t.tenant_id = l.tenant_id
JOIN product.product p ON p.product_id = l.product_id
WHERE l.status = 'active'
  AND p.code = 'AXYSGESTOR'
ON CONFLICT (tenant_id, app_code) DO UPDATE SET
    actor_type = EXCLUDED.actor_type,
    is_active = EXCLUDED.is_active,
    updated_at = now();

INSERT INTO billing.hub_user_app (tenant_id, user_id, product_id, status, granted_at)
SELECT
    t.tenant_id,
    u.user_id,
    p.product_id,
    'active',
    now()
FROM (
    VALUES
        ('AXYS', 'rdias07@live.com'),
        ('AXYS', 'thays_hernandes@hotmail.com'),
        ('LUNALO', 'thays_hernandes@hotmail.com'),
        ('LUNALO', 'lunalocalcados@hotmail.com'),
        ('DIASECARDOZO', 'rdias07@live.com'),
        ('DIASECARDOZO', 'thays_hernandes@hotmail.com'),
        ('DIASECARDOZO', 'diasecardozo@diasecardozo.com.br'),
        ('DIASECARDOZO', 'eng.maicon@diasecardozo.com.br'),
        ('DIASECARDOZO', 'eng.julia@diasecardozo.com.br'),
        ('DIASECARDOZO', 'eng.vitoria@diasecardozo.com.br'),
        ('DIASECARDOZO', 'eng.washington@diasecardozo.com.br')
) AS v(tenant_code, email)
JOIN identity.hub_tenant t ON t.tenant_code = v.tenant_code
JOIN identity.hub_user u ON u.email = v.email
JOIN product.product p
  ON (
      t.tenant_code = 'AXYS'
      AND p.code IN ('AXYSPRO', 'AXYSGESTOR', 'PRI', 'CPU', 'DOC', 'PM', 'LIC', 'ORC', 'BDR', 'FIN', 'ONE')
  )
  OR (
      t.tenant_code = 'LUNALO'
      AND p.code IN ('AXYSGESTOR')
  )
  OR (
      t.tenant_code = 'DIASECARDOZO'
      AND p.code IN ('PRI', 'CPU', 'DOC', 'PM', 'LIC', 'ORC', 'BDR', 'FIN')
  )
ON CONFLICT (tenant_id, user_id, product_id) DO UPDATE SET
    status = EXCLUDED.status,
    granted_at = EXCLUDED.granted_at;

INSERT INTO billing.hub_microapp_instance (tenant_id, product_id, slug, status)
SELECT
    t.tenant_id,
    p.product_id,
    v.slug,
    'active'
FROM (
    VALUES
        ('AXYSPRO', 'axyspro'),
        ('AXYSGESTOR', 'axysgestor'),
        ('PRI', 'easy-price-1'),
        ('CPU', 'easy-cpu'),
        ('DOC', 'easy-docs'),
        ('PM', 'easy-pm'),
        ('LIC', 'easy-licit-plan'),
        ('ORC', 'easy-orca'),
        ('BDR', 'easy-build-diary'),
        ('FIN', 'easy-fin-control'),
        ('ONE', 'easyone')
) AS v(product_code, slug)
JOIN product.product p ON p.code = v.product_code
JOIN billing.hub_license l ON l.product_id = p.product_id AND l.status = 'active'
JOIN identity.hub_tenant t ON t.tenant_id = l.tenant_id
ON CONFLICT (tenant_id, product_id) DO UPDATE SET
    slug = EXCLUDED.slug,
    status = EXCLUDED.status;

-- ------------------------------------------------------------
-- Seed adicional AxysGestor
-- Função:
--   Adiciona o guarda-chuva operacional da Thais, representante de marca,
--   tenant de cliente e as licenças iniciais do ecossistema Gestor sem
--   remover o seed legado.
-- ------------------------------------------------------------

INSERT INTO identity.hub_tenant (tenant_id, tenant_code, tenant_name, document, status, is_active)
VALUES
    ('279ae6ae-52e1-52e0-ad90-df80cbf5cd1b', 'THAIS', 'Thais Hernandes', '40716917866', 'active', TRUE),
    ('5f1d9cf3-c79f-5c6d-92da-5e99d68f0e11', 'MENZANI', 'Menzani e Carvalho Representacoes', '11222333000144', 'active', TRUE),
    ('61b97a83-9d3f-5f94-89d9-cfbe5b9d6721', 'CRISQUARESMA', 'Cris Quaresma Sapatos', '22333444000155', 'active', TRUE)
ON CONFLICT (tenant_code) DO UPDATE SET
    tenant_name = EXCLUDED.tenant_name,
    document = EXCLUDED.document,
    status = EXCLUDED.status,
    is_active = EXCLUDED.is_active,
    updated_at = now();

INSERT INTO identity.hub_user (
    user_id,
    name,
    email,
    password_hash,
    phone,
    locale,
    cpf,
    address_json,
    sys_role,
    status,
    is_active
)
VALUES
    ('cb80f78b-153a-5faa-b2fb-c8e4c3edb7aa', 'Marcio Menzani', 'mr.menzani@gmail.com', crypt('axys@seed2026', gen_salt('bf', 10)), NULL, 'pt-BR', '11122233344', '{}'::jsonb, 'user', 'active', TRUE),
    ('37bb4148-dc37-5683-8053-7f39488f2ef1', 'Amanda', 'amanda@crisquaresma.com.br', crypt('axys@seed2026', gen_salt('bf', 10)), NULL, 'pt-BR', '22233344455', '{}'::jsonb, 'user', 'active', TRUE)
ON CONFLICT (email) DO UPDATE SET
    name = EXCLUDED.name,
    cpf = EXCLUDED.cpf,
    status = EXCLUDED.status,
    is_active = EXCLUDED.is_active,
    updated_at = now();

INSERT INTO identity.hub_user_tenant (tenant_id, user_id, role, is_active)
SELECT t.tenant_id, u.user_id, v.role, TRUE
FROM (
    VALUES
        ('THAIS', 'thays_hernandes@hotmail.com', 'owner'),
        ('MENZANI', 'mr.menzani@gmail.com', 'owner'),
        ('CRISQUARESMA', 'amanda@crisquaresma.com.br', 'owner'),
        ('CRISQUARESMA', 'mr.menzani@gmail.com', 'viewer')
) AS v(tenant_code, email, role)
JOIN identity.hub_tenant t ON t.tenant_code = v.tenant_code
JOIN identity.hub_user u ON u.email = v.email
ON CONFLICT (tenant_id, user_id) DO UPDATE SET
    role = EXCLUDED.role,
    is_active = EXCLUDED.is_active,
    updated_at = now();

INSERT INTO identity.hub_store (store_id, tenant_id, store_code, store_name, document, status, is_active)
SELECT
    v.store_id::uuid,
    t.tenant_id,
    v.store_code,
    v.store_name,
    v.document,
    'active',
    TRUE
FROM (
    VALUES
        ('ceeedf19-787d-49ee-8102-42cf5689b19b', 'THAIS', 'LUNALO-OUROESTE', 'Lunalo Ouroeste', '45580611000194'),
        ('c665bd74-de9c-4ccd-a278-3aebe0977893', 'THAIS', 'LUNALO-JALES', 'Lunalo Jales', '45580611000275'),
        ('2fdb67ef-41ff-4a18-a21d-50557e1880ed', 'CRISQUARESMA', 'CRISQUARESMA', 'Cris Quaresma Sapatos', NULL)
) AS v(store_id, tenant_code, store_code, store_name, document)
JOIN identity.hub_tenant t ON t.tenant_code = v.tenant_code
ON CONFLICT (tenant_id, store_code) DO UPDATE SET
    store_name = EXCLUDED.store_name,
    document = EXCLUDED.document,
    status = EXCLUDED.status,
    is_active = EXCLUDED.is_active,
    updated_at = now();

INSERT INTO identity.hub_user_store (tenant_id, user_id, store_id, role, is_active)
SELECT
    t.tenant_id,
    u.user_id,
    s.store_id,
    v.role,
    TRUE
FROM (
    VALUES
        ('THAIS', 'thays_hernandes@hotmail.com', 'LUNALO-OUROESTE', 'admin'),
        ('THAIS', 'thays_hernandes@hotmail.com', 'LUNALO-JALES', 'admin'),
        ('CRISQUARESMA', 'amanda@crisquaresma.com.br', 'CRISQUARESMA', 'admin'),
        ('CRISQUARESMA', 'mr.menzani@gmail.com', 'CRISQUARESMA', 'viewer')
) AS v(tenant_code, email, store_code, role)
JOIN identity.hub_tenant t ON t.tenant_code = v.tenant_code
JOIN identity.hub_user u ON u.email = v.email
JOIN identity.hub_store s
  ON s.tenant_id = t.tenant_id
 AND s.store_code = v.store_code
ON CONFLICT (tenant_id, user_id, store_id) DO UPDATE SET
    role = EXCLUDED.role,
    is_active = EXCLUDED.is_active,
    updated_at = now();

INSERT INTO billing.hub_subscription (tenant_id, partner_id, status, billing_cycle, started_at)
SELECT t.tenant_id, NULL, 'active', 'monthly', now()
FROM identity.hub_tenant t
WHERE t.tenant_code IN ('THAIS', 'MENZANI', 'CRISQUARESMA')
  AND NOT EXISTS (
      SELECT 1
      FROM billing.hub_subscription s
      WHERE s.tenant_id = t.tenant_id
        AND s.status = 'active'
  );

INSERT INTO billing.hub_license (subscription_id, tenant_id, product_id, status, valid_from, valid_until)
SELECT
    s.subscription_id,
    t.tenant_id,
    p.product_id,
    'active',
    s.started_at,
    NULL
FROM billing.hub_subscription s
JOIN identity.hub_tenant t ON t.tenant_id = s.tenant_id
JOIN product.ecosystem e ON e.code = 'GESTOR'
JOIN product.product p
  ON p.ecosystem_id = e.ecosystem_id
 AND p.code IN ('SL-COMPANY', 'LOCCITANE', 'ANALISTA-VENDAS', 'ANALISTA-COMPRAS', 'NOTIFICADOR', 'CONCILIADOR')
WHERE s.status = 'active'
  AND t.tenant_code IN ('THAIS', 'MENZANI', 'CRISQUARESMA')
ON CONFLICT (tenant_id, product_id) DO UPDATE SET
    subscription_id = EXCLUDED.subscription_id,
    status = EXCLUDED.status,
    valid_from = EXCLUDED.valid_from,
    valid_until = EXCLUDED.valid_until;

INSERT INTO identity.hub_tenant_profile (tenant_id, app_code, actor_type, is_active)
SELECT t.tenant_id, 'gestor', v.actor_type, TRUE
FROM (
    VALUES
        ('THAIS', 'client'),
        ('MENZANI', 'brand_representative'),
        ('CRISQUARESMA', 'client')
) AS v(tenant_code, actor_type)
JOIN identity.hub_tenant t ON t.tenant_code = v.tenant_code
ON CONFLICT (tenant_id, app_code) DO UPDATE SET
    actor_type = EXCLUDED.actor_type,
    is_active = EXCLUDED.is_active,
    updated_at = now();

INSERT INTO billing.hub_user_app (tenant_id, user_id, product_id, status, granted_at)
SELECT
    t.tenant_id,
    u.user_id,
    p.product_id,
    'active',
    now()
FROM (
    VALUES
        ('THAIS', 'thays_hernandes@hotmail.com'),
        ('MENZANI', 'mr.menzani@gmail.com'),
        ('CRISQUARESMA', 'amanda@crisquaresma.com.br')
) AS v(tenant_code, email)
JOIN identity.hub_tenant t ON t.tenant_code = v.tenant_code
JOIN identity.hub_user u ON u.email = v.email
JOIN product.ecosystem e ON e.code = 'GESTOR'
JOIN product.product p
  ON p.ecosystem_id = e.ecosystem_id
 AND p.code IN ('SL-COMPANY', 'LOCCITANE', 'ANALISTA-VENDAS', 'ANALISTA-COMPRAS', 'NOTIFICADOR', 'CONCILIADOR')
ON CONFLICT (tenant_id, user_id, product_id) DO UPDATE SET
    status = EXCLUDED.status,
    granted_at = EXCLUDED.granted_at;

INSERT INTO billing.hub_microapp_instance (tenant_id, product_id, slug, status)
SELECT
    t.tenant_id,
    p.product_id,
    CASE p.code
        WHEN 'SL-COMPANY' THEN 'gestor-sl-company'
        WHEN 'LOCCITANE' THEN 'gestor-loccitane'
        WHEN 'ANALISTA-VENDAS' THEN 'gestor-analista-vendas'
        WHEN 'ANALISTA-COMPRAS' THEN 'gestor-analista-compras'
        WHEN 'NOTIFICADOR' THEN 'gestor-notificador'
        WHEN 'CONCILIADOR' THEN 'gestor-conciliador'
    END,
    'active'
FROM identity.hub_tenant t
JOIN billing.hub_license l ON l.tenant_id = t.tenant_id AND l.status = 'active'
JOIN product.product p ON p.product_id = l.product_id
JOIN product.ecosystem e ON e.ecosystem_id = p.ecosystem_id AND e.code = 'GESTOR'
WHERE t.tenant_code IN ('THAIS', 'MENZANI', 'CRISQUARESMA')
  AND p.code IN ('SL-COMPANY', 'LOCCITANE', 'ANALISTA-VENDAS', 'ANALISTA-COMPRAS', 'NOTIFICADOR', 'CONCILIADOR')
ON CONFLICT (tenant_id, product_id) DO UPDATE SET
    slug = EXCLUDED.slug,
    status = EXCLUDED.status;

-- ============================================================
-- SCHEMA: gateway
-- Função:
--   Provedores de pagamento, transações, eventos e webhooks brutos.
-- ============================================================

-- ------------------------------------------------------------
-- gateway.provider
-- Função:
--   Cadastro de provedores de pagamento. Ex.: ASAAS.
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS gateway.provider (
    provider_id INT         GENERATED ALWAYS AS IDENTITY,
    code        TEXT        NOT NULL,
    name        TEXT        NOT NULL,
    type        TEXT,
    api_version TEXT,
    status      TEXT        NOT NULL DEFAULT 'active',
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT provider_pkey PRIMARY KEY (provider_id),
    CONSTRAINT uq_provider_code UNIQUE (code),
    CONSTRAINT ck_provider_status CHECK (status IN ('active', 'inactive'))
);

-- ------------------------------------------------------------
-- gateway.payment
-- Função:
--   Transação de pagamento recebida/criada em gateway.
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS gateway.payment (
    payment_id         BIGINT      GENERATED ALWAYS AS IDENTITY,
    order_id           BIGINT      NOT NULL,
    tenant_id          UUID        NOT NULL,
    provider_id        INT         NOT NULL,
    payment_no         BIGINT      NOT NULL GENERATED BY DEFAULT AS IDENTITY,
    status             TEXT        NOT NULL DEFAULT 'pending',
    amount_cents       BIGINT      NOT NULL DEFAULT 0,
    external_reference TEXT,
    idempotency_key    TEXT,
    created_at         TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at         TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT payment_pkey PRIMARY KEY (payment_id),
    CONSTRAINT uq_payment_tenant_no UNIQUE (tenant_id, payment_no),
    CONSTRAINT fk_payment_order FOREIGN KEY (order_id)
        REFERENCES orders.hub_order (order_id) ON DELETE CASCADE,
    CONSTRAINT fk_payment_tenant FOREIGN KEY (tenant_id)
        REFERENCES identity.hub_tenant (tenant_id) ON DELETE CASCADE,
    CONSTRAINT fk_payment_provider FOREIGN KEY (provider_id)
        REFERENCES gateway.provider (provider_id) ON DELETE RESTRICT,
    CONSTRAINT ck_payment_status CHECK (status IN ('pending', 'authorized', 'paid', 'failed', 'refunded', 'canceled')),
    CONSTRAINT ck_payment_amount CHECK (amount_cents >= 0)
);

-- adiciona FK opcional commercial.commission_event.payment_id após gateway.payment existir
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM pg_constraint
        WHERE conname = 'fk_commission_event_payment'
          AND conrelid = 'commercial.commission_event'::regclass
    ) THEN
        ALTER TABLE commercial.commission_event
            ADD CONSTRAINT fk_commission_event_payment
            FOREIGN KEY (payment_id)
            REFERENCES gateway.payment (payment_id)
            ON DELETE SET NULL;
    END IF;
END
$$;

-- ------------------------------------------------------------
-- gateway.payment_event
-- Função:
--   Log de eventos associados a um pagamento.
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS gateway.payment_event (
    payment_event_id BIGINT      GENERATED ALWAYS AS IDENTITY,
    payment_id       BIGINT      NOT NULL,
    event_type       TEXT        NOT NULL,
    payload_json     JSONB       NOT NULL DEFAULT '{}',
    created_at       TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT payment_event_pkey PRIMARY KEY (payment_event_id),
    CONSTRAINT fk_payment_event_payment FOREIGN KEY (payment_id)
        REFERENCES gateway.payment (payment_id) ON DELETE CASCADE
);

-- ------------------------------------------------------------
-- gateway.webhook_event
-- Função:
--   Webhooks brutos recebidos de provedores.
--   processed=false enquanto aguarda processamento.
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS gateway.webhook_event (
    webhook_event_id BIGINT      GENERATED ALWAYS AS IDENTITY,
    provider_id      INT         NOT NULL,
    external_event_id TEXT,
    payload_raw      JSONB       NOT NULL DEFAULT '{}',
    processed        BOOLEAN     NOT NULL DEFAULT FALSE,
    received_at      TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT webhook_event_pkey PRIMARY KEY (webhook_event_id),
    CONSTRAINT uq_webhook_event_provider_external UNIQUE (provider_id, external_event_id),
    CONSTRAINT fk_webhook_event_provider FOREIGN KEY (provider_id)
        REFERENCES gateway.provider (provider_id) ON DELETE RESTRICT
);

-- ============================================================
-- SCHEMA: fiscal
-- Função:
--   Parâmetros fiscais e emissão de NFS-e.
--   Regra: 1 pedido pago = 1 NFS-e.
-- ============================================================

-- ------------------------------------------------------------
-- fiscal.company_profile
-- Função:
--   Perfil fiscal da Axys emissora.
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS fiscal.company_profile (
    company_profile_id INT         GENERATED ALWAYS AS IDENTITY,
    legal_name         TEXT        NOT NULL,
    document           TEXT        NOT NULL,
    municipal_registration TEXT,
    city_code          TEXT,
    tax_regime         TEXT,
    api_config_json    JSONB       NOT NULL DEFAULT '{}',
    status             TEXT        NOT NULL DEFAULT 'active',
    created_at         TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT company_profile_pkey PRIMARY KEY (company_profile_id),
    CONSTRAINT ck_company_profile_status CHECK (status IN ('active', 'inactive'))
);

-- ------------------------------------------------------------
-- fiscal.service_profile
-- Função:
--   Parametrização de serviço fiscal por ecossistema.
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS fiscal.service_profile (
    service_profile_id INT         GENERATED ALWAYS AS IDENTITY,
    ecosystem_id       INT,
    lc116_code         TEXT,
    municipal_service_code TEXT,
    cnae               TEXT,
    description_template TEXT,
    iss_rate           NUMERIC(7,4),
    tax_json           JSONB       NOT NULL DEFAULT '{}',
    status             TEXT        NOT NULL DEFAULT 'active',
    created_at         TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT service_profile_pkey PRIMARY KEY (service_profile_id),
    CONSTRAINT fk_service_profile_ecosystem FOREIGN KEY (ecosystem_id)
        REFERENCES product.ecosystem (ecosystem_id) ON DELETE SET NULL,
    CONSTRAINT ck_service_profile_iss CHECK (iss_rate IS NULL OR (iss_rate >= 0 AND iss_rate <= 100)),
    CONSTRAINT ck_service_profile_status CHECK (status IN ('active', 'inactive'))
);

-- ------------------------------------------------------------
-- fiscal.invoice
-- Função:
--   NFS-e consolidada por pedido pago.
--   A identidade técnica da invoice é independente da numeração comercial
--   do Hub e da numeração oficial retornada pela prefeitura.
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS fiscal.invoice (
    invoice_id        BIGINT      GENERATED ALWAYS AS IDENTITY,
    order_id          BIGINT      NOT NULL,
    tenant_id         UUID        NOT NULL,
    company_profile_id INT        NOT NULL,
    invoice_year      SMALLINT    NOT NULL,
    invoice_seq       INTEGER     NOT NULL,
    invoice_number    TEXT GENERATED ALWAYS AS (
        'AXYS-HUB-' ||
        invoice_year::text ||
        '-' ||
        LPAD(invoice_seq::text, 3, '0')
    ) STORED,
    status            TEXT        NOT NULL DEFAULT 'pending',
    total_cents       BIGINT      NOT NULL DEFAULT 0,
    service_description TEXT,
    notes             TEXT,
    nfse_number       TEXT,
    verification_code TEXT,
    issued_at         TIMESTAMPTZ,
    payload_json      JSONB       NOT NULL DEFAULT '{}',
    response_json     JSONB       NOT NULL DEFAULT '{}',
    created_at        TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT invoice_pkey PRIMARY KEY (invoice_id),
    CONSTRAINT uq_invoice_order UNIQUE (order_id),
    CONSTRAINT uq_invoice_year_seq UNIQUE (invoice_year, invoice_seq),
    CONSTRAINT uq_invoice_number UNIQUE (invoice_number),
    CONSTRAINT fk_invoice_order FOREIGN KEY (order_id)
        REFERENCES orders.hub_order (order_id) ON DELETE RESTRICT,
    CONSTRAINT fk_invoice_tenant FOREIGN KEY (tenant_id)
        REFERENCES identity.hub_tenant (tenant_id) ON DELETE CASCADE,
    CONSTRAINT fk_invoice_company FOREIGN KEY (company_profile_id)
        REFERENCES fiscal.company_profile (company_profile_id) ON DELETE RESTRICT,
    CONSTRAINT ck_invoice_year_positive CHECK (invoice_year >= 2000),
    CONSTRAINT ck_invoice_seq_positive CHECK (invoice_seq >= 1),
    CONSTRAINT ck_invoice_total CHECK (total_cents >= 0),
    CONSTRAINT ck_invoice_status CHECK (status IN ('pending', 'issued', 'failed', 'canceled'))
);

-- ------------------------------------------------------------
-- fiscal.invoice_item
-- Função:
--   Item fiscal consolidado, preferencialmente por ecossistema.
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS fiscal.invoice_item (
    invoice_item_id BIGINT GENERATED ALWAYS AS IDENTITY,
    invoice_id      BIGINT NOT NULL,
    ecosystem_id    INT,
    description     TEXT   NOT NULL,
    amount_cents    BIGINT NOT NULL,
    notes           TEXT,

    CONSTRAINT invoice_item_pkey PRIMARY KEY (invoice_item_id),
    CONSTRAINT fk_invoice_item_invoice FOREIGN KEY (invoice_id)
        REFERENCES fiscal.invoice (invoice_id) ON DELETE CASCADE,
    CONSTRAINT fk_invoice_item_ecosystem FOREIGN KEY (ecosystem_id)
        REFERENCES product.ecosystem (ecosystem_id) ON DELETE SET NULL,
    CONSTRAINT ck_invoice_item_amount CHECK (amount_cents >= 0)
);

-- ------------------------------------------------------------
-- fiscal.invoice_event
-- Função:
--   Eventos da emissão/retorno/cancelamento de NFS-e.
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS fiscal.invoice_event (
    invoice_event_id BIGINT      GENERATED ALWAYS AS IDENTITY,
    invoice_id       BIGINT      NOT NULL,
    event_type       TEXT        NOT NULL,
    payload_json     JSONB       NOT NULL DEFAULT '{}',
    created_at       TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT invoice_event_pkey PRIMARY KEY (invoice_event_id),
    CONSTRAINT fk_invoice_event_invoice FOREIGN KEY (invoice_id)
        REFERENCES fiscal.invoice (invoice_id) ON DELETE CASCADE
);

-- ============================================================
-- SCHEMA: audit
-- Função:
--   Auditoria geral, login, billing e segurança.
--   Não substitui eventos técnicos de gateway/order/fiscal; complementa com
--   ação administrativa, ator, motivo e entidade afetada.
-- ============================================================

-- ------------------------------------------------------------
-- audit.audit_log
-- Função:
--   Trilha geral imutável de ações relevantes no Hub.
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS audit.audit_log (
    audit_id       BIGINT      GENERATED ALWAYS AS IDENTITY,
    tenant_id      UUID,
    actor_user_id  UUID,
    target_user_id UUID,
    entity_type    TEXT,
    entity_id      TEXT,
    event_type     TEXT        NOT NULL,
    severity       TEXT        NOT NULL DEFAULT 'info',
    reason         TEXT,
    payload_json   JSONB       NOT NULL DEFAULT '{}',
    created_at     TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT audit_log_pkey PRIMARY KEY (audit_id),
    CONSTRAINT fk_audit_log_tenant FOREIGN KEY (tenant_id)
        REFERENCES identity.hub_tenant (tenant_id) ON DELETE SET NULL,
    CONSTRAINT fk_audit_log_actor FOREIGN KEY (actor_user_id)
        REFERENCES identity.hub_user (user_id) ON DELETE SET NULL,
    CONSTRAINT fk_audit_log_target FOREIGN KEY (target_user_id)
        REFERENCES identity.hub_user (user_id) ON DELETE SET NULL,
    CONSTRAINT ck_audit_log_severity CHECK (severity IN ('debug', 'info', 'warning', 'critical'))
);

-- ------------------------------------------------------------
-- audit.login_log
-- Função:
--   Eventos de autenticação, logout, falha e troca assistida de conta.
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS audit.login_log (
    login_id    BIGINT      GENERATED ALWAYS AS IDENTITY,
    user_id     UUID,
    tenant_id   UUID,
    email       TEXT,
    action      TEXT        NOT NULL,
    origin      TEXT        NOT NULL DEFAULT 'LOCAL',
    ip          TEXT,
    user_agent  TEXT,
    details     JSONB,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT login_log_pkey PRIMARY KEY (login_id),
    CONSTRAINT fk_login_log_user FOREIGN KEY (user_id)
        REFERENCES identity.hub_user (user_id) ON DELETE SET NULL,
    CONSTRAINT fk_login_log_tenant FOREIGN KEY (tenant_id)
        REFERENCES identity.hub_tenant (tenant_id) ON DELETE SET NULL,
    CONSTRAINT ck_login_log_action CHECK (action IN ('LOGIN', 'LOGOUT', 'LOGIN_FALHA', 'TROCAR_CONTA')),
    CONSTRAINT ck_login_log_origin CHECK (origin IN ('LOCAL', 'SSO', 'GOV_BR', 'APPLE', 'GOOGLE', 'API_KEY'))
);

-- ------------------------------------------------------------
-- audit.billing_audit_log
-- Função:
--   Auditoria específica de ações sensíveis de billing.
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS audit.billing_audit_log (
    billing_audit_id BIGINT      GENERATED ALWAYS AS IDENTITY,
    tenant_id        UUID,
    actor_user_id    UUID,
    action           TEXT        NOT NULL,
    entity_type      TEXT,
    entity_id        TEXT,
    reason           TEXT        NOT NULL,
    before_json      JSONB,
    after_json       JSONB,
    created_at       TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT billing_audit_log_pkey PRIMARY KEY (billing_audit_id),
    CONSTRAINT fk_billing_audit_tenant FOREIGN KEY (tenant_id)
        REFERENCES identity.hub_tenant (tenant_id) ON DELETE SET NULL,
    CONSTRAINT fk_billing_audit_actor FOREIGN KEY (actor_user_id)
        REFERENCES identity.hub_user (user_id) ON DELETE SET NULL
);

-- ------------------------------------------------------------
-- audit.security_event
-- Função:
--   Eventos de segurança, bloqueios, tentativas suspeitas e alertas.
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS audit.security_event (
    security_event_id BIGINT      GENERATED ALWAYS AS IDENTITY,
    tenant_id         UUID,
    user_id           UUID,
    event_type        TEXT        NOT NULL,
    severity          TEXT        NOT NULL DEFAULT 'info',
    payload_json      JSONB       NOT NULL DEFAULT '{}',
    created_at        TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT security_event_pkey PRIMARY KEY (security_event_id),
    CONSTRAINT fk_security_event_tenant FOREIGN KEY (tenant_id)
        REFERENCES identity.hub_tenant (tenant_id) ON DELETE SET NULL,
    CONSTRAINT fk_security_event_user FOREIGN KEY (user_id)
        REFERENCES identity.hub_user (user_id) ON DELETE SET NULL,
    CONSTRAINT ck_security_event_severity CHECK (severity IN ('debug', 'info', 'warning', 'critical'))
);

-- ------------------------------------------------------------
-- SEED — contas de créditos de IA
-- Todos os tenants começam em zero. As contas internas/provisórias
-- ilimitadas registram consumo como saldo negativo sem bloqueio.
-- ------------------------------------------------------------
INSERT INTO billing.hub_ai_credit_account (tenant_id, is_unlimited)
SELECT tenant_id, tenant_code IN ('AXYS', 'DIASECARDOZO', 'LUNALO')
FROM identity.hub_tenant
ON CONFLICT (tenant_id) DO UPDATE
SET is_unlimited = EXCLUDED.is_unlimited,
    updated_at = now();

-- ============================================================
-- EASY MOBILE — identidade gratuita isolada e telemetria
-- ============================================================
CREATE TABLE IF NOT EXISTS identity.client_easy_mobile (
    client_uuid UUID NOT NULL DEFAULT gen_random_uuid(),
    client_hub_uuid UUID,
    full_name TEXT NOT NULL,
    phone TEXT NOT NULL,
    email TEXT NOT NULL,
    pending_email TEXT,
    pending_phone TEXT,
    password_hash TEXT NOT NULL,
    cpf TEXT,
    uf CHAR(2),
    profession TEXT,
    status TEXT NOT NULL DEFAULT 'pending_verification',
    email_verified_at TIMESTAMPTZ,
    phone_verified_at TIMESTAMPTZ,
    notification_preferences JSONB NOT NULL DEFAULT '{"new_edition":true,"new_publication":true}'::jsonb,
    deleted_at TIMESTAMPTZ,
    last_login_at TIMESTAMPTZ,
    failed_attempts SMALLINT NOT NULL DEFAULT 0,
    locked_until TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT client_easy_mobile_pkey PRIMARY KEY (client_uuid),
    CONSTRAINT fk_client_easy_mobile_hub_user FOREIGN KEY (client_hub_uuid)
        REFERENCES identity.hub_user (user_id) ON DELETE SET NULL,
    CONSTRAINT ck_client_easy_mobile_status CHECK (
        status IN ('pending_verification', 'active', 'converted', 'deleted', 'blocked')
    ),
    CONSTRAINT ck_client_easy_mobile_email CHECK (position('@' in email) > 1),
    CONSTRAINT ck_client_easy_mobile_phone CHECK (phone ~ '^\d{10,15}$'),
    CONSTRAINT ck_client_easy_mobile_cpf CHECK (cpf IS NULL OR cpf ~ '^\d{11}$'),
    CONSTRAINT ck_client_easy_mobile_uf CHECK (uf IS NULL OR uf ~ '^[A-Z]{2}$'),
    CONSTRAINT ck_client_easy_mobile_notifications CHECK (jsonb_typeof(notification_preferences) = 'object')
);
CREATE UNIQUE INDEX IF NOT EXISTS uq_client_easy_mobile_email_active
    ON identity.client_easy_mobile (lower(email)) WHERE status <> 'deleted';
CREATE UNIQUE INDEX IF NOT EXISTS uq_client_easy_mobile_phone_active
    ON identity.client_easy_mobile (phone) WHERE status <> 'deleted';
CREATE UNIQUE INDEX IF NOT EXISTS uq_client_easy_mobile_cpf_active
    ON identity.client_easy_mobile (cpf) WHERE cpf IS NOT NULL AND status <> 'deleted';
CREATE INDEX IF NOT EXISTS idx_client_easy_mobile_hub_user
    ON identity.client_easy_mobile (client_hub_uuid) WHERE client_hub_uuid IS NOT NULL;

CREATE TABLE IF NOT EXISTS auth.easy_mobile_mfa_challenge (
    challenge_uuid UUID NOT NULL DEFAULT gen_random_uuid(),
    client_uuid UUID NOT NULL,
    channel TEXT NOT NULL,
    code_hash CHAR(64) NOT NULL,
    expires_at TIMESTAMPTZ NOT NULL,
    attempts SMALLINT NOT NULL DEFAULT 0,
    verified_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT easy_mobile_mfa_challenge_pkey PRIMARY KEY (challenge_uuid),
    CONSTRAINT fk_easy_mobile_mfa_client FOREIGN KEY (client_uuid)
        REFERENCES identity.client_easy_mobile (client_uuid) ON DELETE CASCADE,
    CONSTRAINT ck_easy_mobile_mfa_channel CHECK (channel IN ('email', 'whatsapp')),
    CONSTRAINT ck_easy_mobile_mfa_attempts CHECK (attempts BETWEEN 0 AND 5)
);
CREATE INDEX IF NOT EXISTS idx_easy_mobile_mfa_pending
    ON auth.easy_mobile_mfa_challenge (client_uuid, expires_at DESC) WHERE verified_at IS NULL;

CREATE TABLE IF NOT EXISTS auth.easy_mobile_auth_code (
    auth_code_uuid UUID NOT NULL DEFAULT gen_random_uuid(),
    client_uuid UUID NOT NULL,
    token_hash CHAR(64) NOT NULL,
    expires_at TIMESTAMPTZ NOT NULL,
    consumed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT easy_mobile_auth_code_pkey PRIMARY KEY (auth_code_uuid),
    CONSTRAINT uq_easy_mobile_auth_code_hash UNIQUE (token_hash),
    CONSTRAINT fk_easy_mobile_auth_code_client FOREIGN KEY (client_uuid)
        REFERENCES identity.client_easy_mobile (client_uuid) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS auth.easy_mobile_rate_limit (
    scope_key TEXT NOT NULL,
    action TEXT NOT NULL,
    window_started_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    attempts INTEGER NOT NULL DEFAULT 0,
    blocked_until TIMESTAMPTZ,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT easy_mobile_rate_limit_pkey PRIMARY KEY (scope_key, action),
    CONSTRAINT ck_easy_mobile_rate_limit_attempts CHECK (attempts >= 0)
);
CREATE INDEX IF NOT EXISTS idx_easy_mobile_rate_limit_blocked
    ON auth.easy_mobile_rate_limit (blocked_until) WHERE blocked_until IS NOT NULL;

CREATE TABLE IF NOT EXISTS analytics.easy_mobile_event (
    event_id BIGINT GENERATED ALWAYS AS IDENTITY,
    event_uuid UUID NOT NULL DEFAULT gen_random_uuid(),
    ingestion_key TEXT NOT NULL,
    event_name TEXT NOT NULL,
    client_uuid UUID,
    hub_user_uuid UUID,
    anonymous_id TEXT,
    session_id TEXT,
    occurred_at TIMESTAMPTZ NOT NULL,
    properties_json JSONB NOT NULL DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT easy_mobile_event_pkey PRIMARY KEY (event_id),
    CONSTRAINT uq_easy_mobile_event_uuid UNIQUE (event_uuid),
    CONSTRAINT uq_easy_mobile_event_ingestion UNIQUE (ingestion_key),
    CONSTRAINT fk_easy_mobile_event_client FOREIGN KEY (client_uuid)
        REFERENCES identity.client_easy_mobile (client_uuid) ON DELETE SET NULL,
    CONSTRAINT fk_easy_mobile_event_hub_user FOREIGN KEY (hub_user_uuid)
        REFERENCES identity.hub_user (user_id) ON DELETE SET NULL,
    CONSTRAINT ck_easy_mobile_event_name CHECK (btrim(event_name) <> ''),
    CONSTRAINT ck_easy_mobile_event_actor CHECK (
        client_uuid IS NOT NULL OR hub_user_uuid IS NOT NULL OR anonymous_id IS NOT NULL
    ),
    CONSTRAINT ck_easy_mobile_event_properties CHECK (jsonb_typeof(properties_json) = 'object')
);
CREATE INDEX IF NOT EXISTS idx_easy_mobile_event_name_occurred
    ON analytics.easy_mobile_event (event_name, occurred_at DESC);
CREATE INDEX IF NOT EXISTS idx_easy_mobile_event_client_occurred
    ON analytics.easy_mobile_event (client_uuid, occurred_at DESC) WHERE client_uuid IS NOT NULL;

-- ============================================================
-- NOTAS DE VALIDAÇÃO FUTURA
--
-- 1. Separar seeds estruturais dos seeds de ambiente, mantendo ambos próximos
--    das tabelas no schema canônico futuro.
--
-- 2. Validar se `cpf` em identity.hub_user deve ser obrigatório no onboarding
--    ou nullable durante convite/autocadastro parcial.
--
-- 3. Fechar matriz de alçadas internal_user / internal_financeiro /
--    internal_admin / internal_owner.
--
-- 4. Fechar Billing/Asaas:
--    checkout, assinatura, cobrança, inadimplência, webhook, renegociação,
--    provisões, liberação manual e suspensão.
--
-- 5. Fechar fiscal/NFS-e:
--    códigos municipais, LC116, CNAE, regime tributário, API emissora,
--    retenções e descrição fiscal final.
--
-- 6. Fechar commission:
--    percentuais, exceções, payout, estorno, reversão e fim de ownership
--    quando o tenant cancela e retorna sem partner após período sem receita.
--
-- ============================================================
