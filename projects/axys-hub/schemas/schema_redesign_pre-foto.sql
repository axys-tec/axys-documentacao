-- ============================================================
-- AxysHub — Schema Alvo Consolidado
-- Banco: PostgreSQL 14+
-- Schemas: identity · auth · product · orders · billing · gateway · fiscal · commercial · audit
--
-- Status: PRÉ-FOTO ARQUITETURAL
-- Data: 2026-06-18
--
-- OBJETIVO
-- Este arquivo consolida a visão alvo do banco AxysHub a partir das decisões
-- arquiteturais discutidas até aqui. Ainda não é uma migration de produção.
-- Serve como base de validação conceitual, revisão de regras de negócio e
-- futura evolução do schema.sql canônico.
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

CREATE EXTENSION IF NOT EXISTS pgcrypto;

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
-- ============================================================

-- ------------------------------------------------------------
-- product.ecossistema
-- Função:
--   Agrupador estratégico dos produtos Axys: Easy, Pro, Gestor.
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS product.ecossistema (
    ecossistema_id UUID        NOT NULL DEFAULT gen_random_uuid(),
    codigo         TEXT        NOT NULL,
    nome           TEXT        NOT NULL,
    descricao      TEXT,
    ativo          BOOLEAN     NOT NULL DEFAULT TRUE,
    criado_em      TIMESTAMPTZ NOT NULL DEFAULT now(),
    atualizado_em  TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT ecossistema_pkey PRIMARY KEY (ecossistema_id),
    CONSTRAINT uq_ecossistema_codigo UNIQUE (codigo),
    CONSTRAINT ck_ecossistema_codigo_vazio CHECK (btrim(codigo) <> '')
);

INSERT INTO product.ecossistema (codigo, nome, descricao)
VALUES
    ('EASY', 'AxysEasy', 'Ecossistema AxysEasy'),
    ('PRO', 'AxysPro', 'Ecossistema AxysPro'),
    ('GESTOR', 'AxysGestor', 'Ecossistema AxysGestor')
ON CONFLICT (codigo) DO NOTHING;

-- ------------------------------------------------------------
-- product.produto
-- Função:
--   Produto ou solução comercial Axys.
--   Ex.: PR1, CPU, BDR, AXYSPRO, AXYSGESTOR.
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS product.produto (
    produto_id      UUID        NOT NULL DEFAULT gen_random_uuid(),
    ecossistema_id  UUID        NOT NULL,
    codigo          TEXT        NOT NULL,
    nome            TEXT        NOT NULL,
    descricao       TEXT,
    ativo           BOOLEAN     NOT NULL DEFAULT TRUE,
    criado_em       TIMESTAMPTZ NOT NULL DEFAULT now(),
    atualizado_em   TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT produto_pkey PRIMARY KEY (produto_id),
    CONSTRAINT uq_produto_ecossistema_codigo UNIQUE (ecossistema_id, codigo),
    CONSTRAINT fk_produto_ecossistema FOREIGN KEY (ecossistema_id)
        REFERENCES product.ecossistema (ecossistema_id) ON DELETE RESTRICT,
    CONSTRAINT ck_produto_codigo_vazio CHECK (btrim(codigo) <> '')
);

INSERT INTO product.produto (ecossistema_id, codigo, nome, descricao)
SELECT e.ecossistema_id, v.codigo, v.nome, v.descricao
FROM product.ecossistema e
JOIN (
    VALUES
        ('EASY', 'PR1', 'Easy Price', 'Motor paramétrico base do Easy Price'),
        ('EASY', 'CPU', 'Easy CPU', 'Produto Easy CPU'),
        ('EASY', 'DOC', 'Easy Docs', 'Produto Easy Docs'),
        ('EASY', 'PM', 'Easy ProjectManager', 'Produto Easy ProjectManager'),
        ('EASY', 'LIC', 'Easy LicitPlan', 'Produto Easy LicitPlan'),
        ('EASY', 'ORC', 'Easy Orça', 'Produto Easy Orça'),
        ('EASY', 'BDR', 'Easy BuildDiary', 'Produto Easy BuildDiary'),
        ('EASY', 'FIN', 'Easy FinControl', 'Produto Easy FinControl'),
        ('EASY', 'FIS', 'Easy One', 'Produto premium que aglutina todas as funcoes do ecossistema'),
        ('PRO', 'AXYSPRO', 'AxysPro', 'Produto principal do ecossistema AxysPro'),
        ('GESTOR', 'AXYSGESTOR', 'AxysGestor', 'Produto principal do ecossistema AxysGestor')
) AS v(codigo_ecossistema, codigo, nome, descricao)
    ON v.codigo_ecossistema = e.codigo
ON CONFLICT (ecossistema_id, codigo) DO NOTHING;

-- ------------------------------------------------------------
-- product.modulo
-- Função:
--   Módulo funcional/licenciável dentro de um produto.
--   Pode ter hierarquia interna via modulo_pai_id.
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS product.modulo (
    modulo_id       UUID        NOT NULL DEFAULT gen_random_uuid(),
    produto_id      UUID        NOT NULL,
    modulo_pai_id   UUID,
    codigo          TEXT        NOT NULL,
    nome            TEXT        NOT NULL,
    descricao       TEXT,
    ativo           BOOLEAN     NOT NULL DEFAULT TRUE,
    criado_em       TIMESTAMPTZ NOT NULL DEFAULT now(),
    atualizado_em   TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT modulo_pkey PRIMARY KEY (modulo_id),
    CONSTRAINT uq_modulo_produto_codigo UNIQUE (produto_id, codigo),
    CONSTRAINT fk_modulo_produto FOREIGN KEY (produto_id)
        REFERENCES product.produto (produto_id) ON DELETE CASCADE,
    CONSTRAINT fk_modulo_pai FOREIGN KEY (modulo_pai_id)
        REFERENCES product.modulo (modulo_id) ON DELETE SET NULL,
    CONSTRAINT ck_modulo_codigo_vazio CHECK (btrim(codigo) <> '')
);

-- ------------------------------------------------------------
-- product.oferta
-- Função:
--   Forma comercial de vender um produto/módulo.
--   Ex.: EASY-PR1-SIN, EASY-PR1-STA, EASY-BDR-UNL.
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS product.oferta (
    oferta_id         UUID        NOT NULL DEFAULT gen_random_uuid(),
    produto_id        UUID        NOT NULL,
    modulo_id         UUID,
    oferta_codigo     TEXT        NOT NULL,
    nome              TEXT        NOT NULL,
    modelo_cobranca   TEXT        NOT NULL,
    ativo             BOOLEAN     NOT NULL DEFAULT TRUE,
    criado_em         TIMESTAMPTZ NOT NULL DEFAULT now(),
    atualizado_em     TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT oferta_pkey PRIMARY KEY (oferta_id),
    CONSTRAINT uq_oferta_codigo UNIQUE (oferta_codigo),
    CONSTRAINT fk_oferta_produto FOREIGN KEY (produto_id)
        REFERENCES product.produto (produto_id) ON DELETE RESTRICT,
    CONSTRAINT fk_oferta_modulo FOREIGN KEY (modulo_id)
        REFERENCES product.modulo (modulo_id) ON DELETE SET NULL,
    CONSTRAINT ck_oferta_codigo_vazio CHECK (btrim(oferta_codigo) <> ''),
    CONSTRAINT ck_oferta_modelo_cobranca CHECK (modelo_cobranca IN ('uso_unico', 'mensal', 'anual', 'por_uso', 'personalizado'))
);

-- ------------------------------------------------------------
-- product.oferta_concessao
-- Função:
--   Define o que a oferta libera: usos, recursos ativos, módulos,
--   ilimitado, store-aware etc.
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS product.oferta_concessao (
    concessao_id      UUID        NOT NULL DEFAULT gen_random_uuid(),
    oferta_id         UUID        NOT NULL,
    modulo_id         UUID,
    modelo_concessao  TEXT        NOT NULL,
    unidade           TEXT,
    quantidade        INTEGER,
    unidade_periodo   TEXT,
    regra_json        JSONB       NOT NULL DEFAULT '{}',
    ativo             BOOLEAN     NOT NULL DEFAULT TRUE,
    criado_em         TIMESTAMPTZ NOT NULL DEFAULT now(),
    atualizado_em     TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT oferta_concessao_pkey PRIMARY KEY (concessao_id),
    CONSTRAINT fk_concessao_oferta FOREIGN KEY (oferta_id)
        REFERENCES product.oferta (oferta_id) ON DELETE CASCADE,
    CONSTRAINT fk_concessao_modulo FOREIGN KEY (modulo_id)
        REFERENCES product.modulo (modulo_id) ON DELETE SET NULL,
    CONSTRAINT ck_oferta_concessao_modelo CHECK (modelo_concessao IN (
        'uso_unico',
        'contador_uso',
        'limite_usuario',
        'limite_recurso_ativo',
        'acesso_modulo',
        'ilimitado',
        'limite_store',
        'personalizado'
    )),
    CONSTRAINT ck_oferta_concessao_quantidade CHECK (quantidade IS NULL OR quantidade >= 0)
);

-- ============================================================
-- TABELA: product.oferta_politica
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
CREATE TABLE IF NOT EXISTS product.oferta_politica (

    politica_id UUID        NOT NULL DEFAULT gen_random_uuid(),
    oferta_id   UUID        NOT NULL,
    
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
    politica_json                  JSONB NOT NULL DEFAULT '{}',

    -- ── Controle ──────────────────────────────────────────
    ativo         BOOLEAN     NOT NULL DEFAULT TRUE,
    criado_em     TIMESTAMPTZ NOT NULL DEFAULT now(),
    atualizado_em TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT oferta_politica_pkey PRIMARY KEY (politica_id),
    CONSTRAINT uq_oferta_politica_oferta UNIQUE (oferta_id),
    CONSTRAINT fk_oferta_politica_oferta FOREIGN KEY (oferta_id)
        REFERENCES product.oferta (oferta_id)
        ON DELETE CASCADE,
    CONSTRAINT ck_oferta_politica_carencia_nao_negativa
        CHECK (dias_carencia >= 0),
    CONSTRAINT ck_oferta_politica_suspensao_nao_negativa
        CHECK (dias_auto_suspensao >= 0),
    CONSTRAINT ck_oferta_politica_cancelamento_nao_negativo
        CHECK (dias_auto_cancelamento IS NULL OR dias_auto_cancelamento >= 0),
    CONSTRAINT ck_oferta_politica_retry_nao_negativo
        CHECK (max_tentativas_pagamento >= 0)

);

CREATE INDEX idx_oferta_politica_oferta
    ON product.oferta_politica (oferta_id);

CREATE INDEX idx_oferta_politica_ativa
    ON product.oferta_politica (ativo)
    WHERE ativo = TRUE;

-- ------------------------------------------------------------
-- product.oferta_preco
-- Função:
--   Histórico de preços das ofertas. Nunca depender do preço atual
--   para saber por quanto algo foi vendido no passado.
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS product.oferta_preco (
    preco_id          UUID        NOT NULL DEFAULT gen_random_uuid(),
    oferta_id         UUID        NOT NULL,
    moeda             TEXT        NOT NULL DEFAULT 'BRL',
    valor_centavos    BIGINT      NOT NULL,
    periodo_cobranca  TEXT        NOT NULL,
    vigente_de        TIMESTAMPTZ NOT NULL DEFAULT now(),
    vigente_ate       TIMESTAMPTZ,
    ativo             BOOLEAN     NOT NULL DEFAULT TRUE,
    criado_em         TIMESTAMPTZ NOT NULL DEFAULT now(),
    atualizado_em     TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT oferta_preco_pkey PRIMARY KEY (preco_id),
    CONSTRAINT fk_oferta_preco_oferta FOREIGN KEY (oferta_id)
        REFERENCES product.oferta (oferta_id) ON DELETE CASCADE,
    CONSTRAINT ck_oferta_preco_valor CHECK (valor_centavos >= 0),
    CONSTRAINT ck_oferta_preco_periodo CHECK (periodo_cobranca IN ('uma_vez', 'mensal', 'semestral', 'anual', 'personalizado'))
);

INSERT INTO product.oferta (produto_id, modulo_id, oferta_codigo, nome, modelo_cobranca)
SELECT p.produto_id, NULL, v.oferta_codigo, v.nome, v.modelo_cobranca
FROM product.produto p
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
) AS v(codigo_produto, oferta_codigo, nome, modelo_cobranca)
    ON v.codigo_produto = p.codigo
ON CONFLICT (oferta_codigo) DO NOTHING;

INSERT INTO product.oferta_politica (
    oferta_id,
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
    politica_json
)
SELECT
    o.oferta_id,
    CASE WHEN o.oferta_codigo IN ('PR1-UNL', 'CPU-UNL', 'DOC-UNL', 'PM-UNL', 'LIC-UNL', 'ORC-UNL', 'BDR-UNL', 'FIN-UNL', 'FIS-UNL') THEN 5 ELSE 0 END,
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
FROM product.oferta o
ON CONFLICT (oferta_id) DO NOTHING;

INSERT INTO product.oferta_concessao (
    oferta_id,
    modulo_id,
    modelo_concessao,
    unidade,
    quantidade,
    unidade_periodo,
    regra_json
)
SELECT o.oferta_id, NULL, v.modelo_concessao, v.unidade, v.quantidade, v.unidade_periodo, v.regra_json::jsonb
FROM product.oferta o
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

        ('PM-SIN', 'limite_recurso_ativo', 'obra_ativa', 1, 'mes', '{}'),
        ('PM-SIN', 'limite_usuario', 'usuario', 1, 'mes', '{}'),
        ('PM-STA', 'limite_recurso_ativo', 'obra_ativa', 2, 'mes', '{}'),
        ('PM-STA', 'limite_usuario', 'usuario', 1, 'mes', '{}'),
        ('PM-ADV', 'limite_recurso_ativo', 'obra_ativa', 3, 'mes', '{}'),
        ('PM-ADV', 'limite_usuario', 'usuario', 1, 'mes', '{}'),
        ('PM-PRO', 'limite_recurso_ativo', 'obra_ativa', 6, 'mes', '{}'),
        ('PM-PRO', 'limite_usuario', 'usuario', 2, 'mes', '{}'),
        ('PM-UNL', 'ilimitado', 'obra_ativa', NULL, 'mes', '{}'),
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

        ('ORC-SIN', 'limite_recurso_ativo', 'obra_ativa', 1, 'mes', '{}'),
        ('ORC-SIN', 'limite_usuario', 'usuario', 1, 'mes', '{}'),
        ('ORC-STA', 'limite_recurso_ativo', 'obra_ativa', 2, 'mes', '{}'),
        ('ORC-STA', 'limite_usuario', 'usuario', 1, 'mes', '{}'),
        ('ORC-ADV', 'limite_recurso_ativo', 'obra_ativa', 3, 'mes', '{}'),
        ('ORC-ADV', 'limite_usuario', 'usuario', 1, 'mes', '{}'),
        ('ORC-PRO', 'limite_recurso_ativo', 'obra_ativa', 6, 'mes', '{}'),
        ('ORC-PRO', 'limite_usuario', 'usuario', 2, 'mes', '{}'),
        ('ORC-UNL', 'ilimitado', 'obra_ativa', NULL, 'mes', '{}'),
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
) AS v(oferta_codigo, modelo_concessao, unidade, quantidade, unidade_periodo, regra_json)
    ON v.oferta_codigo = o.oferta_codigo
WHERE NOT EXISTS (
    SELECT 1
    FROM product.oferta_concessao e
    WHERE e.oferta_id = o.oferta_id
      AND e.modelo_concessao = v.modelo_concessao
      AND COALESCE(e.unidade, '') = COALESCE(v.unidade, '')
      AND COALESCE(e.quantidade, -1) = COALESCE(v.quantidade, -1)
      AND COALESCE(e.unidade_periodo, '') = COALESCE(v.unidade_periodo, '')
);

INSERT INTO product.oferta_preco (
    oferta_id,
    moeda,
    valor_centavos,
    periodo_cobranca,
    vigente_de
)
SELECT o.oferta_id, 'BRL', v.valor_centavos, v.periodo_cobranca, now()
FROM product.oferta o
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
) AS v(oferta_codigo, periodo_cobranca, valor_centavos)
    ON v.oferta_codigo = o.oferta_codigo
WHERE NOT EXISTS (
    SELECT 1
    FROM product.oferta_preco p
    WHERE p.oferta_id = o.oferta_id
      AND p.periodo_cobranca = v.periodo_cobranca
      AND p.valor_centavos = v.valor_centavos
      AND p.vigente_ate IS NULL
);

-- ------------------------------------------------------------
-- product.adicional
-- Função:
--   Capacidade adicional vendável vinculada a um produto.
--   Ex.: PRICE2/PRICE3/PRICE4 como evolução do motor do Price.
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS product.adicional (
    adicional_id       UUID        NOT NULL DEFAULT gen_random_uuid(),
    produto_id         UUID        NOT NULL,
    adicional_codigo   TEXT        NOT NULL,
    nome               TEXT        NOT NULL,
    descricao          TEXT,
    ativo              BOOLEAN     NOT NULL DEFAULT TRUE,
    criado_em          TIMESTAMPTZ NOT NULL DEFAULT now(),
    atualizado_em      TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT adicional_pkey PRIMARY KEY (adicional_id),
    CONSTRAINT uq_adicional_produto_codigo UNIQUE (produto_id, adicional_codigo),
    CONSTRAINT fk_adicional_produto FOREIGN KEY (produto_id)
        REFERENCES product.produto (produto_id) ON DELETE CASCADE,
    CONSTRAINT ck_adicional_codigo_vazio CHECK (btrim(adicional_codigo) <> '')
);

-- ------------------------------------------------------------
-- product.adicional_concessao
-- Função:
--   Define o que o add-on libera sobre o produto-base.
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS product.adicional_concessao (
    adicional_concessao_id UUID        NOT NULL DEFAULT gen_random_uuid(),
    adicional_id           UUID        NOT NULL,
    modelo_concessao       TEXT        NOT NULL,
    unidade                TEXT,
    quantidade             INTEGER,
    unidade_periodo        TEXT,
    regra_json             JSONB       NOT NULL DEFAULT '{}',
    ativo                  BOOLEAN     NOT NULL DEFAULT TRUE,
    criado_em              TIMESTAMPTZ NOT NULL DEFAULT now(),
    atualizado_em          TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT adicional_concessao_pkey PRIMARY KEY (adicional_concessao_id),
    CONSTRAINT fk_adicional_concessao_adicional FOREIGN KEY (adicional_id)
        REFERENCES product.adicional (adicional_id) ON DELETE CASCADE,
    CONSTRAINT ck_adicional_concessao_modelo CHECK (modelo_concessao IN (
        'acesso_capacidade',
        'contador_uso',
        'limite_recurso_ativo',
        'acesso_modulo',
        'ilimitado',
        'personalizado'
    )),
    CONSTRAINT ck_adicional_concessao_quantidade CHECK (quantidade IS NULL OR quantidade >= 0)
);

-- ------------------------------------------------------------
-- product.adicional_preco
-- Função:
--   Histórico de preço do add-on.
--   Pode manter regra comercial própria, independente da oferta-base.
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS product.adicional_preco (
    adicional_preco_id UUID        NOT NULL DEFAULT gen_random_uuid(),
    adicional_id       UUID        NOT NULL,
    moeda              TEXT        NOT NULL DEFAULT 'BRL',
    valor_centavos     BIGINT      NOT NULL,
    periodo_cobranca   TEXT        NOT NULL,
    vigente_de         TIMESTAMPTZ NOT NULL DEFAULT now(),
    vigente_ate        TIMESTAMPTZ,
    ativo              BOOLEAN     NOT NULL DEFAULT TRUE,
    criado_em          TIMESTAMPTZ NOT NULL DEFAULT now(),
    atualizado_em      TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT adicional_preco_pkey PRIMARY KEY (adicional_preco_id),
    CONSTRAINT fk_adicional_preco_adicional FOREIGN KEY (adicional_id)
        REFERENCES product.adicional (adicional_id) ON DELETE CASCADE,
    CONSTRAINT ck_adicional_preco_valor CHECK (valor_centavos >= 0),
    CONSTRAINT ck_adicional_preco_periodo CHECK (periodo_cobranca IN ('uma_vez', 'mensal', 'semestral', 'anual', 'personalizado'))
);

INSERT INTO product.adicional (produto_id, adicional_codigo, nome, descricao)
SELECT p.produto_id, 'PRICE2', 'Adicional Price2', 'Capacidade adicional do Easy Price, cobrada cheia sem desconto de recorrência'
FROM product.produto p
WHERE p.codigo = 'PR1'
ON CONFLICT (produto_id, adicional_codigo) DO NOTHING;

INSERT INTO product.adicional_concessao (
    adicional_id,
    modelo_concessao,
    unidade,
    quantidade,
    unidade_periodo,
    regra_json
)
SELECT a.adicional_id, 'acesso_capacidade', 'motor_precificacao', 1, 'mes', '{"capacidade":"PRICE2"}'::jsonb
FROM product.adicional a
WHERE a.adicional_codigo = 'PRICE2'
  AND NOT EXISTS (
      SELECT 1
      FROM product.adicional_concessao e
      WHERE e.adicional_id = a.adicional_id
        AND e.modelo_concessao = 'acesso_capacidade'
        AND COALESCE(e.unidade, '') = 'motor_precificacao'
  );

INSERT INTO product.adicional_preco (
    adicional_id,
    moeda,
    valor_centavos,
    periodo_cobranca,
    vigente_de
)
SELECT a.adicional_id, 'BRL', v.valor_centavos, v.periodo_cobranca, now()
FROM product.adicional a
JOIN (
    VALUES
        ('PRICE2', 'mensal', 990),
        ('PRICE2', 'semestral', 990),
        ('PRICE2', 'anual', 990)
) AS v(adicional_codigo, periodo_cobranca, valor_centavos)
    ON v.adicional_codigo = a.adicional_codigo
WHERE NOT EXISTS (
    SELECT 1
    FROM product.adicional_preco p
    WHERE p.adicional_id = a.adicional_id
      AND p.periodo_cobranca = v.periodo_cobranca
      AND p.valor_centavos = v.valor_centavos
      AND p.vigente_ate IS NULL
);

-- ------------------------------------------------------------
-- product.combo
-- Função:
--   Agrupamento comercial de ofertas com condição própria.
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS product.combo (
    combo_id      UUID        NOT NULL DEFAULT gen_random_uuid(),
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
    combo_item_id  UUID        NOT NULL DEFAULT gen_random_uuid(),
    combo_id       UUID        NOT NULL,
    oferta_id      UUID        NOT NULL,
    quantidade     INTEGER     NOT NULL DEFAULT 1,
    ativo          BOOLEAN     NOT NULL DEFAULT TRUE,
    criado_em      TIMESTAMPTZ NOT NULL DEFAULT now(),
    atualizado_em  TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT combo_item_pkey PRIMARY KEY (combo_item_id),
    CONSTRAINT uq_combo_item UNIQUE (combo_id, oferta_id),
    CONSTRAINT fk_combo_item_combo FOREIGN KEY (combo_id)
        REFERENCES product.combo (combo_id) ON DELETE CASCADE,
    CONSTRAINT fk_combo_item_oferta FOREIGN KEY (oferta_id)
        REFERENCES product.oferta (oferta_id) ON DELETE RESTRICT,
    CONSTRAINT ck_combo_item_quantidade CHECK (quantidade >= 1)
);

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
    partner_id      UUID        NOT NULL DEFAULT gen_random_uuid(),
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
    lead_id    UUID        NOT NULL DEFAULT gen_random_uuid(),
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
-- commercial.referral_visit
-- Função:
--   Registro da visita com código de parceiro/ref.
--   Captura ocorre no ato da entrada.
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS commercial.referral_visit (
    visit_id    UUID        NOT NULL DEFAULT gen_random_uuid(),
    partner_id  UUID,
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
    attribution_id   UUID        NOT NULL DEFAULT gen_random_uuid(),
    tenant_id        UUID        NOT NULL,
    partner_id       UUID,
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
    rule_id      UUID        NOT NULL DEFAULT gen_random_uuid(),
    partner_id   UUID,
    ecossistema_id UUID,
    produto_id      UUID,
    percent      NUMERIC(7,4),
    fixed_cents  BIGINT,
    status       TEXT        NOT NULL DEFAULT 'active',
    valid_from   TIMESTAMPTZ NOT NULL DEFAULT now(),
    valid_until  TIMESTAMPTZ,

    CONSTRAINT commission_rule_pkey PRIMARY KEY (rule_id),
    CONSTRAINT fk_commission_rule_partner FOREIGN KEY (partner_id)
        REFERENCES commercial.partner (partner_id) ON DELETE CASCADE,
    CONSTRAINT fk_commission_rule_ecossistema FOREIGN KEY (ecossistema_id)
        REFERENCES product.ecossistema (ecossistema_id) ON DELETE SET NULL,
    CONSTRAINT fk_commission_rule_produto FOREIGN KEY (produto_id)
        REFERENCES product.produto (produto_id) ON DELETE SET NULL,
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
    commission_event_id UUID        NOT NULL DEFAULT gen_random_uuid(),
    partner_id          UUID        NOT NULL,
    tenant_id           UUID        NOT NULL,
    payment_id          UUID,
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
    payout_id     UUID        NOT NULL DEFAULT gen_random_uuid(),
    partner_id    UUID        NOT NULL,
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
    order_id    UUID        NOT NULL DEFAULT gen_random_uuid(),
    tenant_id   UUID        NOT NULL,
    user_id     UUID        NOT NULL,
    partner_id  UUID,
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
    order_item_id       UUID    NOT NULL DEFAULT gen_random_uuid(),
    order_id            UUID    NOT NULL,
    ecossistema_id        UUID,
    produto_id            UUID,
    oferta_id             UUID,
    preco_id              UUID,
    oferta_codigo_snapshot TEXT,
    descricao_snapshot    TEXT,
    quantity             INTEGER NOT NULL DEFAULT 1,
    unit_cents           BIGINT  NOT NULL DEFAULT 0,
    discount_cents       BIGINT  NOT NULL DEFAULT 0,
    final_cents          BIGINT  NOT NULL DEFAULT 0,
    payload_json         JSONB   NOT NULL DEFAULT '{}',

    CONSTRAINT hub_order_item_pkey PRIMARY KEY (order_item_id),
    CONSTRAINT fk_order_item_order FOREIGN KEY (order_id)
        REFERENCES orders.hub_order (order_id) ON DELETE CASCADE,
    CONSTRAINT fk_order_item_ecossistema FOREIGN KEY (ecossistema_id)
        REFERENCES product.ecossistema (ecossistema_id) ON DELETE SET NULL,
    CONSTRAINT fk_order_item_produto FOREIGN KEY (produto_id)
        REFERENCES product.produto (produto_id) ON DELETE SET NULL,
    CONSTRAINT fk_order_item_oferta FOREIGN KEY (oferta_id)
        REFERENCES product.oferta (oferta_id) ON DELETE SET NULL,
    CONSTRAINT fk_order_item_preco FOREIGN KEY (preco_id)
        REFERENCES product.oferta_preco (preco_id) ON DELETE SET NULL,
    CONSTRAINT ck_order_item_qty CHECK (quantity >= 1),
    CONSTRAINT ck_order_item_values CHECK (unit_cents >= 0 AND discount_cents >= 0 AND final_cents >= 0)
);

-- ------------------------------------------------------------
-- orders.hub_order_event
-- Função:
--   Log imutável do ciclo de vida do pedido.
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS orders.hub_order_event (
    order_event_id UUID        NOT NULL DEFAULT gen_random_uuid(),
    order_id       UUID        NOT NULL,
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
    subscription_id UUID        NOT NULL DEFAULT gen_random_uuid(),
    tenant_id       UUID        NOT NULL,
    partner_id      UUID,
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
    subscription_item_id UUID        NOT NULL DEFAULT gen_random_uuid(),
    subscription_id      UUID        NOT NULL,
    oferta_id            UUID        NOT NULL,
    preco_id             UUID,
    quantity             INTEGER     NOT NULL DEFAULT 1,
    status               TEXT        NOT NULL DEFAULT 'active',
    started_at           TIMESTAMPTZ NOT NULL DEFAULT now(),
    ended_at             TIMESTAMPTZ,

    CONSTRAINT hub_subscription_item_pkey PRIMARY KEY (subscription_item_id),
    CONSTRAINT fk_subscription_item_subscription FOREIGN KEY (subscription_id)
        REFERENCES billing.hub_subscription (subscription_id) ON DELETE CASCADE,
    CONSTRAINT fk_subscription_item_oferta FOREIGN KEY (oferta_id)
        REFERENCES product.oferta (oferta_id) ON DELETE RESTRICT,
    CONSTRAINT fk_subscription_item_preco FOREIGN KEY (preco_id)
        REFERENCES product.oferta_preco (preco_id) ON DELETE SET NULL,
    CONSTRAINT ck_subscription_item_qty CHECK (quantity >= 1),
    CONSTRAINT ck_subscription_item_status CHECK (status IN ('active', 'inactive', 'canceled'))
);

-- ------------------------------------------------------------
-- billing.hub_subscription_period
-- Função:
--   Competências/períodos de cobrança de uma assinatura.
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS billing.hub_subscription_period (
    period_id       UUID        NOT NULL DEFAULT gen_random_uuid(),
    subscription_id UUID        NOT NULL,
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
    license_id      UUID        NOT NULL DEFAULT gen_random_uuid(),
    subscription_id UUID,
    tenant_id       UUID        NOT NULL,
    produto_id      UUID        NOT NULL,
    status          TEXT        NOT NULL DEFAULT 'active',
    valid_from      TIMESTAMPTZ,
    valid_until     TIMESTAMPTZ,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT hub_license_pkey PRIMARY KEY (license_id),
    CONSTRAINT uq_license_tenant_product UNIQUE (tenant_id, produto_id),
    CONSTRAINT fk_license_subscription FOREIGN KEY (subscription_id)
        REFERENCES billing.hub_subscription (subscription_id) ON DELETE SET NULL,
    CONSTRAINT fk_license_tenant FOREIGN KEY (tenant_id)
        REFERENCES identity.hub_tenant (tenant_id) ON DELETE CASCADE,
    CONSTRAINT fk_license_produto FOREIGN KEY (produto_id)
        REFERENCES product.produto (produto_id) ON DELETE RESTRICT,
    CONSTRAINT ck_license_status CHECK (status IN ('active', 'suspended', 'expired', 'revoked'))
);

-- ------------------------------------------------------------
-- billing.hub_license_key
-- Função:
--   Chaves criptográficas de licença.
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS billing.hub_license_key (
    license_key_id UUID        NOT NULL DEFAULT gen_random_uuid(),
    license_id     UUID        NOT NULL,
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
    activation_id      UUID        NOT NULL DEFAULT gen_random_uuid(),
    license_id         UUID        NOT NULL,
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
    produto_id UUID        NOT NULL,
    status     TEXT        NOT NULL DEFAULT 'active',
    granted_at TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT hub_user_app_pkey PRIMARY KEY (tenant_id, user_id, produto_id),
    CONSTRAINT fk_user_app_tenant FOREIGN KEY (tenant_id)
        REFERENCES identity.hub_tenant (tenant_id) ON DELETE CASCADE,
    CONSTRAINT fk_user_app_user FOREIGN KEY (user_id)
        REFERENCES identity.hub_user (user_id) ON DELETE CASCADE,
    CONSTRAINT fk_user_app_produto FOREIGN KEY (produto_id)
        REFERENCES product.produto (produto_id) ON DELETE CASCADE,
    CONSTRAINT ck_user_app_status CHECK (status IN ('active', 'inactive'))
);

-- ------------------------------------------------------------
-- billing.hub_microapp_instance
-- Função:
--   Instância de app/produto habilitada para tenant.
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS billing.hub_microapp_instance (
    instance_id UUID        NOT NULL DEFAULT gen_random_uuid(),
    tenant_id   UUID        NOT NULL,
    produto_id  UUID        NOT NULL,
    slug        TEXT        NOT NULL,
    status      TEXT        NOT NULL DEFAULT 'active',
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT hub_microapp_instance_pkey PRIMARY KEY (instance_id),
    CONSTRAINT uq_microapp_instance UNIQUE (tenant_id, produto_id),
    CONSTRAINT fk_microapp_instance_tenant FOREIGN KEY (tenant_id)
        REFERENCES identity.hub_tenant (tenant_id) ON DELETE CASCADE,
    CONSTRAINT fk_microapp_instance_produto FOREIGN KEY (produto_id)
        REFERENCES product.produto (produto_id) ON DELETE RESTRICT,
    CONSTRAINT ck_microapp_instance_status CHECK (status IN ('active', 'inactive'))
);

-- ------------------------------------------------------------
-- billing.hub_microapp_config
-- Função:
--   Configuração JSONB de instância de microapp/produto por tenant.
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS billing.hub_microapp_config (
    config_id   UUID        NOT NULL DEFAULT gen_random_uuid(),
    instance_id UUID        NOT NULL,
    config_json JSONB       NOT NULL DEFAULT '{}',
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT hub_microapp_config_pkey PRIMARY KEY (config_id),
    CONSTRAINT uq_microapp_config_instance UNIQUE (instance_id),
    CONSTRAINT fk_microapp_config_instance FOREIGN KEY (instance_id)
        REFERENCES billing.hub_microapp_instance (instance_id) ON DELETE CASCADE
);

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
    provider_id UUID        NOT NULL DEFAULT gen_random_uuid(),
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
    payment_id         UUID        NOT NULL DEFAULT gen_random_uuid(),
    order_id           UUID        NOT NULL,
    tenant_id          UUID        NOT NULL,
    provider_id        UUID        NOT NULL,
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
ALTER TABLE commercial.commission_event
    ADD CONSTRAINT fk_commission_event_payment
    FOREIGN KEY (payment_id)
    REFERENCES gateway.payment (payment_id)
    ON DELETE SET NULL;

-- ------------------------------------------------------------
-- gateway.payment_event
-- Função:
--   Log de eventos associados a um pagamento.
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS gateway.payment_event (
    payment_event_id UUID        NOT NULL DEFAULT gen_random_uuid(),
    payment_id       UUID        NOT NULL,
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
    webhook_event_id UUID        NOT NULL DEFAULT gen_random_uuid(),
    provider_id      UUID        NOT NULL,
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
    company_profile_id UUID        NOT NULL DEFAULT gen_random_uuid(),
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
    service_profile_id UUID        NOT NULL DEFAULT gen_random_uuid(),
    ecossistema_id     UUID,
    lc116_code         TEXT,
    municipal_service_code TEXT,
    cnae               TEXT,
    description_template TEXT,
    iss_rate           NUMERIC(7,4),
    tax_json           JSONB       NOT NULL DEFAULT '{}',
    status             TEXT        NOT NULL DEFAULT 'active',
    created_at         TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT service_profile_pkey PRIMARY KEY (service_profile_id),
    CONSTRAINT fk_service_profile_ecossistema FOREIGN KEY (ecossistema_id)
        REFERENCES product.ecossistema (ecossistema_id) ON DELETE SET NULL,
    CONSTRAINT ck_service_profile_iss CHECK (iss_rate IS NULL OR (iss_rate >= 0 AND iss_rate <= 100)),
    CONSTRAINT ck_service_profile_status CHECK (status IN ('active', 'inactive'))
);

-- ------------------------------------------------------------
-- fiscal.invoice
-- Função:
--   NFS-e consolidada por pedido pago.
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS fiscal.invoice (
    invoice_id        UUID        NOT NULL DEFAULT gen_random_uuid(),
    order_id          UUID        NOT NULL,
    tenant_id         UUID        NOT NULL,
    company_profile_id UUID      NOT NULL,
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
    CONSTRAINT fk_invoice_order FOREIGN KEY (order_id)
        REFERENCES orders.hub_order (order_id) ON DELETE RESTRICT,
    CONSTRAINT fk_invoice_tenant FOREIGN KEY (tenant_id)
        REFERENCES identity.hub_tenant (tenant_id) ON DELETE CASCADE,
    CONSTRAINT fk_invoice_company FOREIGN KEY (company_profile_id)
        REFERENCES fiscal.company_profile (company_profile_id) ON DELETE RESTRICT,
    CONSTRAINT ck_invoice_total CHECK (total_cents >= 0),
    CONSTRAINT ck_invoice_status CHECK (status IN ('pending', 'issued', 'failed', 'canceled'))
);

-- ------------------------------------------------------------
-- fiscal.invoice_item
-- Função:
--   Item fiscal consolidado, preferencialmente por ecossistema.
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS fiscal.invoice_item (
    invoice_item_id UUID   NOT NULL DEFAULT gen_random_uuid(),
    invoice_id      UUID   NOT NULL,
    ecossistema_id  UUID,
    description     TEXT   NOT NULL,
    amount_cents    BIGINT NOT NULL,
    notes           TEXT,

    CONSTRAINT invoice_item_pkey PRIMARY KEY (invoice_item_id),
    CONSTRAINT fk_invoice_item_invoice FOREIGN KEY (invoice_id)
        REFERENCES fiscal.invoice (invoice_id) ON DELETE CASCADE,
    CONSTRAINT fk_invoice_item_ecossistema FOREIGN KEY (ecossistema_id)
        REFERENCES product.ecossistema (ecossistema_id) ON DELETE SET NULL,
    CONSTRAINT ck_invoice_item_amount CHECK (amount_cents >= 0)
);

-- ------------------------------------------------------------
-- fiscal.invoice_event
-- Função:
--   Eventos da emissão/retorno/cancelamento de NFS-e.
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS fiscal.invoice_event (
    invoice_event_id UUID        NOT NULL DEFAULT gen_random_uuid(),
    invoice_id       UUID        NOT NULL,
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
    audit_id       UUID        NOT NULL DEFAULT gen_random_uuid(),
    tenant_id      UUID,
    actor_user_id  UUID,
    target_user_id UUID,
    entity_type    TEXT,
    entity_id      UUID,
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
    login_id    UUID        NOT NULL DEFAULT gen_random_uuid(),
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
    billing_audit_id UUID        NOT NULL DEFAULT gen_random_uuid(),
    tenant_id        UUID,
    actor_user_id    UUID,
    action           TEXT        NOT NULL,
    entity_type      TEXT,
    entity_id        UUID,
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
    security_event_id UUID        NOT NULL DEFAULT gen_random_uuid(),
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
