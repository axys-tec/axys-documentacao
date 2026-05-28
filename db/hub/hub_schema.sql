-- ============================================================
-- AxysHub — Schema SQL
-- Banco: PostgreSQL 14+
-- Schema: public
--
-- O Hub é o núcleo de identidade, autenticação, licenciamento
-- e gestão comercial do ecossistema Axys. Ele não contém
-- lógica de produto — apenas gerencia quem tem acesso ao quê.
--
-- Responsabilidades do Hub:
-- - Identidade de usuários e tenants
-- - Autenticação (JWT emitido aqui, validado nos sistemas)
-- - Licenças, assinaturas e planos
-- - Pedidos e pagamentos
-- - Registro de sistemas e APIs externas
-- - Audit log
--
-- Regras operacionais:
--
-- USUÁRIOS:
-- - hub_user: identidade global do usuário (cross-tenant)
-- - hub_user_tenant: vínculo usuário ↔ tenant com role local
--   (owner | admin | member)
-- - sys_role em hub_user: role de sistema (hub_admin | user)
--   distinto do role de tenant
-- - CPF: opcional, único quando informado, 11 dígitos numéricos
-- - address_json: endereço em JSONB (flexível por região)
-- - Segurança: failed_attempts + locked_until para proteção
--   contra força bruta; last_login para auditoria de acesso
--
-- TENANTS:
-- - Unidade de isolamento de dados nos sistemas filhos
-- - tenant_code: identificador curto, imutável, uppercase
--   formato: ^[A-Z][A-Z0-9_]{2,19}$
-- - document: CNPJ ou CPF do titular (sem máscara)
--
-- LICENÇAS:
-- - hub_sistema: produto/sistema do ecossistema
-- - hub_plano: configuração comercial de um sistema
-- - hub_assinatura: contrato ativo de um tenant para um sistema
-- - hub_licenca: licença técnica que habilita o acesso
-- - hub_licenca_chave: chave criptográfica da licença (SHA-256)
-- - hub_ativacao_licenca: registro de validação por ambiente
--
-- PAGAMENTOS:
-- - Valores em centavos (bigint), moeda BRL por padrão
-- - hub_pedido → hub_pedido_item → hub_pagamento → eventos
-- - hub_gateway_pagamento: cadastro de gateways (Stripe, Asaas…)
-- - hub_gateway_evento: webhooks brutos recebidos do gateway
--
-- PADRÃO DE NOMENCLATURA:
-- - Tabelas: prefixo hub_
-- - PKs: UUID DEFAULT gen_random_uuid()
-- - Timestamps: TIMESTAMPTZ DEFAULT now()
-- - Valores monetários: BIGINT em centavos
-- - Constraints nomeadas: uq_, ck_, fk_, idx_
--
-- EXTENSÃO NECESSÁRIA:
-- - pgcrypto: para crypt() na verificação de senha
--   CREATE EXTENSION IF NOT EXISTS pgcrypto;
-- ============================================================

CREATE EXTENSION IF NOT EXISTS pgcrypto;

GRANT USAGE ON SCHEMA public TO "axys_tec";

ALTER DEFAULT PRIVILEGES IN SCHEMA public
    GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO "axys_tec";

ALTER DEFAULT PRIVILEGES IN SCHEMA public
    GRANT USAGE, SELECT ON SEQUENCES TO "axys_tec";


-- ============================================================
-- TABELA: hub_user
-- Identidade global do usuário — independente de tenant.
-- Um usuário pode pertencer a múltiplos tenants via
-- hub_user_tenant.
--
-- sys_role: papel no sistema operacional do Hub
--   'hub_admin' — acesso ao painel de administração do Hub
--   'user'      — usuário regular (padrão)
--
-- address_json estrutura sugerida:
-- {
--   "logradouro": "Rua X", "numero": "100",
--   "complemento": "Ap 1", "bairro": "Centro",
--   "cidade": "São Paulo", "estado": "SP", "cep": "01310100"
-- }
-- ============================================================
CREATE TABLE IF NOT EXISTS hub_user (
    user_id         UUID        NOT NULL DEFAULT gen_random_uuid(),
    name            TEXT        NOT NULL,
    email           TEXT        NOT NULL,
    password_hash   TEXT,
    phone           TEXT,
    avatar_url      TEXT,
    locale          TEXT        NOT NULL DEFAULT 'pt-BR',
    cpf             TEXT        NOT NULL,
    address_json    JSONB       NOT NULL DEFAULT '{}',
    sys_role        TEXT        NOT NULL DEFAULT 'user',
    status          TEXT        NOT NULL DEFAULT 'active',
    is_active       BOOLEAN     NOT NULL DEFAULT TRUE,
    failed_attempts SMALLINT    NOT NULL DEFAULT 0,
    locked_until    TIMESTAMPTZ,
    last_login      TIMESTAMPTZ,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT hub_user_pkey
        PRIMARY KEY (user_id),

    CONSTRAINT uq_hub_user_email
        UNIQUE (email),

    CONSTRAINT uq_hub_user_cpf
        UNIQUE (cpf),

    CONSTRAINT ck_hub_user_sys_role
        CHECK (sys_role IN ('hub_admin', 'user')),

    CONSTRAINT ck_hub_user_status
        CHECK (status IN ('active', 'suspended', 'deleted')),

    CONSTRAINT ck_hub_user_cpf_format
        CHECK (cpf ~ '^\d{11}$'),

    CONSTRAINT ck_hub_user_name_notempty
        CHECK (btrim(name) <> '')
);

CREATE INDEX idx_hub_user_email
    ON hub_user (lower(email));

CREATE INDEX idx_hub_user_sys_role
    ON hub_user (sys_role)
    WHERE sys_role = 'hub_admin';


-- ============================================================
-- TABELA: hub_tenant
-- Unidade de isolamento de dados. Representa uma empresa,
-- equipe ou conta. Todos os sistemas filhos usam tenant_id
-- para isolar seus dados.
--
-- tenant_code: identificador curto imutável (ex: AXYS, OBRA01)
-- document: CNPJ (14 dígitos) ou CPF (11 dígitos), sem máscara
-- ============================================================
CREATE TABLE IF NOT EXISTS hub_tenant (
    tenant_id   UUID        NOT NULL DEFAULT gen_random_uuid(),
    tenant_code TEXT        NOT NULL,
    tenant_name TEXT        NOT NULL,
    document    TEXT        NOT NULL,
    status      TEXT        NOT NULL DEFAULT 'active',
    is_active   BOOLEAN     NOT NULL DEFAULT TRUE,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT hub_tenant_pkey
        PRIMARY KEY (tenant_id),

    CONSTRAINT hub_tenant_tenant_code_key
        UNIQUE (tenant_code),

    CONSTRAINT chk_hub_tenant_code
        CHECK (tenant_code ~ '^[A-Z][A-Z0-9_]{2,19}$'),

    CONSTRAINT ck_hub_tenant_status
        CHECK (status IN ('active', 'suspended', 'deleted'))
);


-- ============================================================
-- TABELA: hub_sistema
-- Catálogo de produtos/sistemas do ecossistema Axys.
-- sha256_key: chave de validação criptográfica do sistema.
-- tipo: classifica o sistema (app, api, integration, etc.)
-- ============================================================
CREATE TABLE IF NOT EXISTS hub_sistema (
    sistema_id   UUID        NOT NULL DEFAULT gen_random_uuid(),
    sistema_code TEXT        NOT NULL,
    nome         TEXT        NOT NULL,
    descricao    TEXT,
    tipo         TEXT        NOT NULL,
    sha256_key   CHAR(64)    NOT NULL,
    status       TEXT        NOT NULL DEFAULT 'active',
    created_at   TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT hub_sistema_pkey
        PRIMARY KEY (sistema_id),

    CONSTRAINT hub_sistema_sistema_code_key
        UNIQUE (sistema_code),

    CONSTRAINT hub_sistema_sha256_key_key
        UNIQUE (sha256_key),

    CONSTRAINT ck_hub_sistema_status
        CHECK (status IN ('active', 'inactive', 'deprecated'))
);


-- ============================================================
-- TABELA: hub_gateway_pagamento
-- Cadastro de gateways de pagamento disponíveis
-- (Stripe, Asaas, PagSeguro, etc.).
-- ============================================================
CREATE TABLE IF NOT EXISTS hub_gateway_pagamento (
    gateway_id  UUID        NOT NULL DEFAULT gen_random_uuid(),
    nome        TEXT        NOT NULL,
    tipo        TEXT,
    versao_api  TEXT,
    status      TEXT        NOT NULL DEFAULT 'active',
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT hub_gateway_pagamento_pkey
        PRIMARY KEY (gateway_id),

    CONSTRAINT ck_hub_gateway_status
        CHECK (status IN ('active', 'inactive'))
);


-- ============================================================
-- TABELA: hub_api_registry
-- Registro de APIs externas que podem ser integradas
-- por tenants via hub_api_client.
-- ============================================================
CREATE TABLE IF NOT EXISTS hub_api_registry (
    api_id     UUID        NOT NULL DEFAULT gen_random_uuid(),
    api_code   TEXT        NOT NULL,
    nome       TEXT        NOT NULL,
    descricao  TEXT,
    base_path  TEXT,
    status     TEXT        NOT NULL DEFAULT 'active',
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT hub_api_registry_pkey
        PRIMARY KEY (api_id),

    CONSTRAINT hub_api_registry_api_code_key
        UNIQUE (api_code),

    CONSTRAINT ck_hub_api_registry_status
        CHECK (status IN ('active', 'inactive', 'deprecated'))
);


-- ============================================================
-- TABELA: hub_pacote_combo
-- Pacotes que agrupam múltiplos sistemas/planos para venda
-- conjunta com condições especiais.
-- ============================================================
CREATE TABLE IF NOT EXISTS hub_pacote_combo (
    pacote_id  UUID        NOT NULL DEFAULT gen_random_uuid(),
    nome       TEXT        NOT NULL,
    descricao  TEXT,
    status     TEXT        NOT NULL DEFAULT 'active',
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT hub_pacote_combo_pkey
        PRIMARY KEY (pacote_id),

    CONSTRAINT ck_hub_pacote_combo_status
        CHECK (status IN ('active', 'inactive'))
);


-- ============================================================
-- TABELA: hub_user_tenant
-- Vínculo usuário ↔ tenant com role local.
-- role: papel do usuário dentro deste tenant específico
--   'owner'  — dono da conta, permissões máximas
--   'admin'  — administrador delegado
--   'member' — usuário padrão (padrão)
-- ============================================================
CREATE TABLE IF NOT EXISTS hub_user_tenant (
    user_tenant_id UUID        NOT NULL DEFAULT gen_random_uuid(),
    tenant_id      UUID        NOT NULL,
    user_id        UUID        NOT NULL,
    role           TEXT        NOT NULL DEFAULT 'member',
    is_active      BOOLEAN     NOT NULL DEFAULT TRUE,
    created_at     TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT hub_user_tenant_pkey
        PRIMARY KEY (user_tenant_id),

    CONSTRAINT hub_user_tenant_tenant_id_user_id_key
        UNIQUE (tenant_id, user_id),

    CONSTRAINT hub_user_tenant_tenant_id_fkey
        FOREIGN KEY (tenant_id)
        REFERENCES hub_tenant (tenant_id)
        ON DELETE CASCADE,

    CONSTRAINT hub_user_tenant_user_id_fkey
        FOREIGN KEY (user_id)
        REFERENCES hub_user (user_id)
        ON DELETE CASCADE,

    CONSTRAINT ck_hub_user_tenant_role
        CHECK (role IN ('owner', 'admin', 'member', 'internal_owner'))
);

CREATE INDEX idx_hub_user_tenant_tenant
    ON hub_user_tenant (tenant_id);

CREATE INDEX idx_hub_user_tenant_user
    ON hub_user_tenant (user_id);


-- ============================================================
-- TABELA: hub_auth_token
-- Tokens de sessão emitidos após autenticação.
-- token_hash: SHA-256 do token bruto (nunca armazenar o token).
-- revoked_at: preenchido no logout ou expiração forçada.
-- ============================================================
CREATE TABLE IF NOT EXISTS hub_auth_token (
    token_id   UUID        NOT NULL DEFAULT gen_random_uuid(),
    tenant_id  UUID        NOT NULL,
    user_id    UUID        NOT NULL,
    token_hash CHAR(64)    NOT NULL,
    issued_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    expires_at TIMESTAMPTZ NOT NULL,
    revoked_at TIMESTAMPTZ,

    CONSTRAINT hub_auth_token_pkey
        PRIMARY KEY (token_id),

    CONSTRAINT hub_auth_token_token_hash_key
        UNIQUE (token_hash),

    CONSTRAINT hub_auth_token_tenant_id_fkey
        FOREIGN KEY (tenant_id)
        REFERENCES hub_tenant (tenant_id)
        ON DELETE CASCADE,

    CONSTRAINT hub_auth_token_user_id_fkey
        FOREIGN KEY (user_id)
        REFERENCES hub_user (user_id)
        ON DELETE CASCADE
);

CREATE INDEX idx_hub_auth_token_user
    ON hub_auth_token (tenant_id, user_id);


-- ============================================================
-- TABELA: hub_api_key
-- Chaves de API estáticas associadas a um tenant.
-- key_value: chave bruta em CHAR(64) (SHA-256 gerado no backend).
-- ============================================================
CREATE TABLE IF NOT EXISTS hub_api_key (
    api_key_id UUID        NOT NULL DEFAULT gen_random_uuid(),
    tenant_id  UUID,
    key_value  CHAR(64)    NOT NULL,
    label      TEXT,
    status     TEXT        NOT NULL DEFAULT 'active',
    is_active  BOOLEAN     NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT hub_api_key_pkey
        PRIMARY KEY (api_key_id),

    CONSTRAINT hub_api_key_key_value_key
        UNIQUE (key_value),

    CONSTRAINT hub_api_key_tenant_id_fkey
        FOREIGN KEY (tenant_id)
        REFERENCES hub_tenant (tenant_id)
        ON DELETE CASCADE,

    CONSTRAINT ck_hub_api_key_status
        CHECK (status IN ('active', 'revoked'))
);

CREATE INDEX idx_hub_api_key_tenant
    ON hub_api_key (tenant_id);


-- ============================================================
-- TABELA: hub_api_client
-- Credenciais OAuth2-style de um tenant para uma API registrada.
-- client_key: identificador público do cliente.
-- client_secret_hash: hash do segredo (nunca armazenar em texto).
-- scopes: lista de permissões concedidas (JSONB array de strings).
-- ============================================================
CREATE TABLE IF NOT EXISTS hub_api_client (
    api_client_id      UUID        NOT NULL DEFAULT gen_random_uuid(),
    tenant_id          UUID        NOT NULL,
    api_id             UUID        NOT NULL,
    nome               TEXT,
    client_key         TEXT        NOT NULL,
    client_secret_hash CHAR(64)    NOT NULL,
    status             TEXT        NOT NULL DEFAULT 'active',
    scopes             JSONB       NOT NULL DEFAULT '[]',
    created_at         TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT hub_api_client_pkey
        PRIMARY KEY (api_client_id),

    CONSTRAINT hub_api_client_client_key_key
        UNIQUE (client_key),

    CONSTRAINT hub_api_client_tenant_id_fkey
        FOREIGN KEY (tenant_id)
        REFERENCES hub_tenant (tenant_id)
        ON DELETE CASCADE,

    CONSTRAINT hub_api_client_api_id_fkey
        FOREIGN KEY (api_id)
        REFERENCES hub_api_registry (api_id)
        ON DELETE CASCADE,

    CONSTRAINT ck_hub_api_client_scopes_array
        CHECK (jsonb_typeof(scopes) = 'array'),

    CONSTRAINT ck_hub_api_client_status
        CHECK (status IN ('active', 'revoked'))
);

CREATE INDEX idx_hub_api_client_tenant
    ON hub_api_client (tenant_id);


-- ============================================================
-- TABELA: hub_api_token
-- Tokens de acesso gerados para clientes OAuth2 (hub_api_client).
-- Vida curta — rotacionados pelo backend conforme necessário.
-- ============================================================
CREATE TABLE IF NOT EXISTS hub_api_token (
    token_id      UUID        NOT NULL DEFAULT gen_random_uuid(),
    api_client_id UUID        NOT NULL,
    tenant_id     UUID        NOT NULL,
    token_hash    CHAR(64)    NOT NULL,
    expires_at    TIMESTAMPTZ NOT NULL,
    revoked_at    TIMESTAMPTZ,
    created_at    TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT hub_api_token_pkey
        PRIMARY KEY (token_id),

    CONSTRAINT hub_api_token_token_hash_key
        UNIQUE (token_hash),

    CONSTRAINT hub_api_token_api_client_id_fkey
        FOREIGN KEY (api_client_id)
        REFERENCES hub_api_client (api_client_id)
        ON DELETE CASCADE,

    CONSTRAINT hub_api_token_tenant_id_fkey
        FOREIGN KEY (tenant_id)
        REFERENCES hub_tenant (tenant_id)
        ON DELETE CASCADE
);


-- ============================================================
-- TABELA: hub_plano
-- Configuração comercial de um sistema (preço, limites, billing).
-- limites_json: parâmetros do plano (ex: max_users, max_obras).
-- billing_model: mensal | anual | uso | licenca_perpetua
-- ============================================================
CREATE TABLE IF NOT EXISTS hub_plano (
    plano_id      UUID        NOT NULL DEFAULT gen_random_uuid(),
    sistema_id    UUID        NOT NULL,
    nome          TEXT        NOT NULL,
    descricao     TEXT,
    billing_model TEXT        NOT NULL,
    limites_json  JSONB       NOT NULL DEFAULT '{}',
    versao        INTEGER     NOT NULL DEFAULT 1,
    status        TEXT        NOT NULL DEFAULT 'active',
    created_at    TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT hub_plano_pkey
        PRIMARY KEY (plano_id),

    CONSTRAINT hub_plano_sistema_id_versao_nome_key
        UNIQUE (sistema_id, versao, nome),

    CONSTRAINT hub_plano_sistema_id_fkey
        FOREIGN KEY (sistema_id)
        REFERENCES hub_sistema (sistema_id)
        ON DELETE RESTRICT,

    CONSTRAINT ck_hub_plano_status
        CHECK (status IN ('active', 'inactive', 'deprecated')),

    CONSTRAINT ck_hub_plano_versao_positive
        CHECK (versao >= 1)
);


-- ============================================================
-- TABELA: hub_assinatura
-- Contrato ativo de um tenant para um sistema/plano.
-- canceled_at: preenchido no cancelamento (não deleta o registro).
-- ============================================================
CREATE TABLE IF NOT EXISTS hub_assinatura (
    assinatura_id UUID        NOT NULL DEFAULT gen_random_uuid(),
    tenant_id     UUID        NOT NULL,
    sistema_id    UUID        NOT NULL,
    plano_id      UUID        NOT NULL,
    status        TEXT        NOT NULL,
    started_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
    canceled_at   TIMESTAMPTZ,

    CONSTRAINT hub_assinatura_pkey
        PRIMARY KEY (assinatura_id),

    CONSTRAINT hub_assinatura_tenant_id_fkey
        FOREIGN KEY (tenant_id)
        REFERENCES hub_tenant (tenant_id)
        ON DELETE CASCADE,

    CONSTRAINT hub_assinatura_sistema_id_fkey
        FOREIGN KEY (sistema_id)
        REFERENCES hub_sistema (sistema_id)
        ON DELETE RESTRICT,

    CONSTRAINT hub_assinatura_plano_id_fkey
        FOREIGN KEY (plano_id)
        REFERENCES hub_plano (plano_id)
        ON DELETE RESTRICT,

    CONSTRAINT ck_hub_assinatura_status
        CHECK (status IN ('active', 'suspended', 'canceled', 'expired'))
);

CREATE INDEX idx_hub_assinatura_tenant
    ON hub_assinatura (tenant_id, status);


-- ============================================================
-- TABELA: hub_licenca
-- Licença técnica que habilita o acesso de um tenant a um
-- sistema. Gerada a partir de uma assinatura ativa.
-- Um tenant tem no máximo uma licença por sistema (UNIQUE).
-- ============================================================
CREATE TABLE IF NOT EXISTS hub_licenca (
    licenca_id    UUID        NOT NULL DEFAULT gen_random_uuid(),
    assinatura_id UUID,
    tenant_id     UUID        NOT NULL,
    sistema_id    UUID        NOT NULL,
    status        TEXT        NOT NULL,
    valid_from    TIMESTAMPTZ,
    valid_until   TIMESTAMPTZ,
    created_at    TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT hub_licenca_pkey
        PRIMARY KEY (licenca_id),

    CONSTRAINT hub_licenca_tenant_id_sistema_id_key
        UNIQUE (tenant_id, sistema_id),

    CONSTRAINT hub_licenca_assinatura_id_fkey
        FOREIGN KEY (assinatura_id)
        REFERENCES hub_assinatura (assinatura_id)
        ON DELETE SET NULL,

    CONSTRAINT hub_licenca_tenant_id_fkey
        FOREIGN KEY (tenant_id)
        REFERENCES hub_tenant (tenant_id)
        ON DELETE CASCADE,

    CONSTRAINT hub_licenca_sistema_id_fkey
        FOREIGN KEY (sistema_id)
        REFERENCES hub_sistema (sistema_id)
        ON DELETE RESTRICT,

    CONSTRAINT ck_hub_licenca_status
        CHECK (status IN ('active', 'suspended', 'expired', 'revoked'))
);


-- ============================================================
-- TABELA: hub_licenca_chave
-- Chave criptográfica (SHA-256) associada a uma licença.
-- Um histórico de chaves é mantido — a mais recente com
-- status='active' é a vigente.
-- ============================================================
CREATE TABLE IF NOT EXISTS hub_licenca_chave (
    licenca_chave_id UUID        NOT NULL DEFAULT gen_random_uuid(),
    licenca_id       UUID        NOT NULL,
    sha256_key       CHAR(64)    NOT NULL,
    issued_at        TIMESTAMPTZ NOT NULL DEFAULT now(),
    expires_at       TIMESTAMPTZ,
    status           TEXT        NOT NULL DEFAULT 'active',

    CONSTRAINT hub_licenca_chave_pkey
        PRIMARY KEY (licenca_chave_id),

    CONSTRAINT hub_licenca_chave_licenca_id_fkey
        FOREIGN KEY (licenca_id)
        REFERENCES hub_licenca (licenca_id)
        ON DELETE CASCADE,

    CONSTRAINT ck_hub_licenca_chave_status
        CHECK (status IN ('active', 'expired', 'revoked'))
);

CREATE INDEX idx_hub_licenca_chave_licenca
    ON hub_licenca_chave (licenca_id, issued_at DESC);


-- ============================================================
-- TABELA: hub_ativacao_licenca
-- Registro de validação de licença por ambiente (instância
-- do sistema). Rastreia quando e onde cada licença foi validada.
-- ============================================================
CREATE TABLE IF NOT EXISTS hub_ativacao_licenca (
    ativacao_id        UUID        NOT NULL DEFAULT gen_random_uuid(),
    licenca_id         UUID        NOT NULL,
    ambiente_id        TEXT,
    last_validation_at TIMESTAMPTZ,
    status             TEXT        NOT NULL DEFAULT 'ok',
    created_at         TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT hub_ativacao_licenca_pkey
        PRIMARY KEY (ativacao_id),

    CONSTRAINT hub_ativacao_licenca_licenca_id_fkey
        FOREIGN KEY (licenca_id)
        REFERENCES hub_licenca (licenca_id)
        ON DELETE CASCADE,

    CONSTRAINT ck_hub_ativacao_status
        CHECK (status IN ('ok', 'invalid', 'expired'))
);

CREATE INDEX idx_hub_ativacao_licenca
    ON hub_ativacao_licenca (licenca_id, last_validation_at DESC);


-- ============================================================
-- TABELA: hub_microapp_instance
-- Instância de um sistema/microapp ativada para um tenant.
-- slug: identificador de rota da instância (ex: easy-orca).
-- ============================================================
CREATE TABLE IF NOT EXISTS hub_microapp_instance (
    instance_id UUID        NOT NULL DEFAULT gen_random_uuid(),
    tenant_id   UUID        NOT NULL,
    sistema_id  UUID        NOT NULL,
    slug        TEXT        NOT NULL,
    status      TEXT        NOT NULL DEFAULT 'active',
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT hub_microapp_instance_pkey
        PRIMARY KEY (instance_id),

    CONSTRAINT hub_microapp_instance_tenant_id_sistema_id_key
        UNIQUE (tenant_id, sistema_id),

    CONSTRAINT hub_microapp_instance_tenant_id_fkey
        FOREIGN KEY (tenant_id)
        REFERENCES hub_tenant (tenant_id)
        ON DELETE CASCADE,

    CONSTRAINT hub_microapp_instance_sistema_id_fkey
        FOREIGN KEY (sistema_id)
        REFERENCES hub_sistema (sistema_id)
        ON DELETE RESTRICT,

    CONSTRAINT ck_hub_microapp_instance_status
        CHECK (status IN ('active', 'inactive'))
);

CREATE INDEX idx_hub_microapp_tenant
    ON hub_microapp_instance (tenant_id);


-- ============================================================
-- TABELA: hub_microapp_config
-- Configuração customizada de uma instância de microapp
-- por tenant. JSONB livre — cada sistema define seu schema.
-- Relação 1:1 com hub_microapp_instance.
-- ============================================================
CREATE TABLE IF NOT EXISTS hub_microapp_config (
    config_id   UUID        NOT NULL DEFAULT gen_random_uuid(),
    instance_id UUID        NOT NULL,
    config_json JSONB       NOT NULL DEFAULT '{}',
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT hub_microapp_config_pkey
        PRIMARY KEY (config_id),

    CONSTRAINT hub_microapp_config_instance_id_key
        UNIQUE (instance_id),

    CONSTRAINT hub_microapp_config_instance_id_fkey
        FOREIGN KEY (instance_id)
        REFERENCES hub_microapp_instance (instance_id)
        ON DELETE CASCADE
);


-- ============================================================
-- TABELA: hub_pacote_combo_itens
-- Itens de um pacote combo (sistemas + planos incluídos).
-- plano_id: opcional — quando NULL, o combo inclui qualquer
-- plano do sistema.
-- ============================================================
CREATE TABLE IF NOT EXISTS hub_pacote_combo_itens (
    pacote_item_id UUID NOT NULL DEFAULT gen_random_uuid(),
    pacote_id      UUID NOT NULL,
    sistema_id     UUID NOT NULL,
    plano_id       UUID,

    CONSTRAINT hub_pacote_combo_itens_pkey
        PRIMARY KEY (pacote_item_id),

    CONSTRAINT hub_pacote_combo_itens_pacote_id_fkey
        FOREIGN KEY (pacote_id)
        REFERENCES hub_pacote_combo (pacote_id)
        ON DELETE CASCADE,

    CONSTRAINT hub_pacote_combo_itens_sistema_id_fkey
        FOREIGN KEY (sistema_id)
        REFERENCES hub_sistema (sistema_id)
        ON DELETE RESTRICT,

    CONSTRAINT hub_pacote_combo_itens_plano_id_fkey
        FOREIGN KEY (plano_id)
        REFERENCES hub_plano (plano_id)
        ON DELETE RESTRICT
);

CREATE INDEX idx_hub_combo_itens_pacote
    ON hub_pacote_combo_itens (pacote_id);


-- ============================================================
-- TABELA: hub_periodo_assinatura
-- Períodos de cobrança de uma assinatura (competências mensais).
-- competencia: formato 'YYYY-MM' (ex: '2025-01')
-- ============================================================
CREATE TABLE IF NOT EXISTS hub_periodo_assinatura (
    periodo_id    UUID        NOT NULL DEFAULT gen_random_uuid(),
    assinatura_id UUID        NOT NULL,
    competencia   TEXT        NOT NULL,
    status        TEXT        NOT NULL,
    due_date      DATE,
    paid_at       TIMESTAMPTZ,
    created_at    TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT hub_periodo_assinatura_pkey
        PRIMARY KEY (periodo_id),

    CONSTRAINT hub_periodo_assinatura_assinatura_id_competencia_key
        UNIQUE (assinatura_id, competencia),

    CONSTRAINT hub_periodo_assinatura_assinatura_id_fkey
        FOREIGN KEY (assinatura_id)
        REFERENCES hub_assinatura (assinatura_id)
        ON DELETE CASCADE,

    CONSTRAINT ck_hub_periodo_status
        CHECK (status IN ('pending', 'paid', 'overdue', 'canceled'))
);


-- ============================================================
-- TABELA: hub_pedido
-- Pedido comercial de um tenant.
-- order_no: número sequencial de pedido por tenant (IDENTITY).
-- total_cents: valor total em centavos.
-- ============================================================
CREATE TABLE IF NOT EXISTS hub_pedido (
    pedido_id   UUID        NOT NULL DEFAULT gen_random_uuid(),
    tenant_id   UUID        NOT NULL,
    user_id     UUID        NOT NULL,
    order_no    BIGINT      NOT NULL GENERATED BY DEFAULT AS IDENTITY,
    status      TEXT        NOT NULL,
    total_cents BIGINT      NOT NULL DEFAULT 0,
    currency    TEXT        NOT NULL DEFAULT 'BRL',
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT hub_pedido_pkey
        PRIMARY KEY (pedido_id),

    CONSTRAINT uq_hub_pedido_tenant_order_no
        UNIQUE (tenant_id, order_no),

    CONSTRAINT hub_pedido_tenant_id_fkey
        FOREIGN KEY (tenant_id)
        REFERENCES hub_tenant (tenant_id)
        ON DELETE CASCADE,

    CONSTRAINT hub_pedido_user_id_fkey
        FOREIGN KEY (user_id)
        REFERENCES hub_user (user_id)
        ON DELETE RESTRICT,

    CONSTRAINT ck_hub_pedido_status
        CHECK (status IN ('draft', 'pending', 'paid', 'canceled', 'refunded')),

    CONSTRAINT ck_hub_pedido_total_nonnegative
        CHECK (total_cents >= 0)
);

CREATE INDEX idx_hub_pedido_tenant
    ON hub_pedido (tenant_id, created_at DESC);

CREATE INDEX idx_hub_pedido_tenant_order_no
    ON hub_pedido (tenant_id, order_no);


-- ============================================================
-- TABELA: hub_pedido_item
-- Itens de um pedido (sistemas e planos adquiridos).
-- valor_unitario_cents: preço unitário no momento da compra.
-- payload_json: dados adicionais do item (snapshot do plano).
-- ============================================================
CREATE TABLE IF NOT EXISTS hub_pedido_item (
    pedido_item_id       UUID    NOT NULL DEFAULT gen_random_uuid(),
    pedido_id            UUID    NOT NULL,
    sistema_id           UUID,
    plano_id             UUID,
    quantidade           INTEGER NOT NULL DEFAULT 1,
    valor_unitario_cents BIGINT  NOT NULL DEFAULT 0,
    payload_json         JSONB   NOT NULL DEFAULT '{}',

    CONSTRAINT hub_pedido_item_pkey
        PRIMARY KEY (pedido_item_id),

    CONSTRAINT hub_pedido_item_pedido_id_fkey
        FOREIGN KEY (pedido_id)
        REFERENCES hub_pedido (pedido_id)
        ON DELETE CASCADE,

    CONSTRAINT hub_pedido_item_sistema_id_fkey
        FOREIGN KEY (sistema_id)
        REFERENCES hub_sistema (sistema_id)
        ON DELETE RESTRICT,

    CONSTRAINT hub_pedido_item_plano_id_fkey
        FOREIGN KEY (plano_id)
        REFERENCES hub_plano (plano_id)
        ON DELETE RESTRICT,

    CONSTRAINT ck_hub_pedido_item_qty_positive
        CHECK (quantidade >= 1),

    CONSTRAINT ck_hub_pedido_item_valor_nonnegative
        CHECK (valor_unitario_cents >= 0)
);

CREATE INDEX idx_hub_pedido_item_pedido
    ON hub_pedido_item (pedido_id);


-- ============================================================
-- TABELA: hub_pedido_evento
-- Log imutável de eventos do ciclo de vida de um pedido.
-- pedido_evento_no: sequencial global por tenant (auditoria).
-- ============================================================
CREATE TABLE IF NOT EXISTS hub_pedido_evento (
    pedido_evento_id UUID        NOT NULL DEFAULT gen_random_uuid(),
    pedido_id        UUID        NOT NULL,
    tenant_id        UUID        NOT NULL,
    user_id          UUID,
    pedido_evento_no BIGINT      NOT NULL GENERATED BY DEFAULT AS IDENTITY,
    tipo_evento      TEXT        NOT NULL,
    payload_json     JSONB       NOT NULL DEFAULT '{}',
    created_at       TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT hub_pedido_evento_pkey
        PRIMARY KEY (pedido_evento_id),

    CONSTRAINT uq_hub_pedido_evento_tenant_no
        UNIQUE (tenant_id, pedido_evento_no),

    CONSTRAINT hub_pedido_evento_pedido_id_fkey
        FOREIGN KEY (pedido_id)
        REFERENCES hub_pedido (pedido_id)
        ON DELETE CASCADE,

    CONSTRAINT hub_pedido_evento_tenant_id_fkey
        FOREIGN KEY (tenant_id)
        REFERENCES hub_tenant (tenant_id)
        ON DELETE CASCADE,

    CONSTRAINT hub_pedido_evento_user_id_fkey
        FOREIGN KEY (user_id)
        REFERENCES hub_user (user_id)
        ON DELETE SET NULL
);

CREATE INDEX idx_hub_pedido_evento_pedido
    ON hub_pedido_evento (pedido_id, pedido_evento_id);

CREATE INDEX idx_hub_pedido_evento_tenant_no
    ON hub_pedido_evento (tenant_id, pedido_evento_no);


-- ============================================================
-- TABELA: hub_pagamento
-- Transação de pagamento vinculada a um pedido e gateway.
-- payment_no: sequencial por tenant.
-- referencia_externa: ID da transação no gateway.
-- idempotency_key: chave de idempotência para evitar duplicatas.
-- ============================================================
CREATE TABLE IF NOT EXISTS hub_pagamento (
    pagamento_id        UUID        NOT NULL DEFAULT gen_random_uuid(),
    pedido_id           UUID        NOT NULL,
    tenant_id           UUID        NOT NULL,
    gateway_id          UUID        NOT NULL,
    payment_no          BIGINT      NOT NULL GENERATED BY DEFAULT AS IDENTITY,
    status              TEXT        NOT NULL,
    valor_cents         BIGINT      NOT NULL DEFAULT 0,
    referencia_externa  TEXT,
    idempotency_key     TEXT,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT hub_pagamento_pkey
        PRIMARY KEY (pagamento_id),

    CONSTRAINT uq_hub_pagamento_tenant_payment_no
        UNIQUE (tenant_id, payment_no),

    CONSTRAINT hub_pagamento_pedido_id_fkey
        FOREIGN KEY (pedido_id)
        REFERENCES hub_pedido (pedido_id)
        ON DELETE CASCADE,

    CONSTRAINT hub_pagamento_tenant_id_fkey
        FOREIGN KEY (tenant_id)
        REFERENCES hub_tenant (tenant_id)
        ON DELETE CASCADE,

    CONSTRAINT hub_pagamento_gateway_id_fkey
        FOREIGN KEY (gateway_id)
        REFERENCES hub_gateway_pagamento (gateway_id)
        ON DELETE RESTRICT,

    CONSTRAINT ck_hub_pagamento_status
        CHECK (status IN ('pending', 'authorized', 'paid', 'failed', 'refunded', 'canceled')),

    CONSTRAINT ck_hub_pagamento_valor_nonnegative
        CHECK (valor_cents >= 0)
);

CREATE INDEX idx_hub_pagamento_pedido
    ON hub_pagamento (pedido_id);

CREATE INDEX idx_hub_pagamento_refext
    ON hub_pagamento (referencia_externa)
    WHERE referencia_externa IS NOT NULL;

CREATE INDEX idx_hub_pagamento_tenant_payment_no
    ON hub_pagamento (tenant_id, payment_no);


-- ============================================================
-- TABELA: hub_pagamento_evento
-- Log imutável de eventos de um pagamento (webhook, retorno
-- de gateway, mudança de status).
-- ============================================================
CREATE TABLE IF NOT EXISTS hub_pagamento_evento (
    pagamento_evento_id UUID        NOT NULL DEFAULT gen_random_uuid(),
    pagamento_id        UUID        NOT NULL,
    pagamento_evento_no BIGINT      NOT NULL GENERATED BY DEFAULT AS IDENTITY,
    tipo_evento         TEXT        NOT NULL,
    payload_json        JSONB       NOT NULL DEFAULT '{}',
    created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT hub_pagamento_evento_pkey
        PRIMARY KEY (pagamento_evento_id),

    CONSTRAINT hub_pagamento_evento_pagamento_id_fkey
        FOREIGN KEY (pagamento_id)
        REFERENCES hub_pagamento (pagamento_id)
        ON DELETE CASCADE
);

CREATE INDEX idx_hub_pagamento_evento_no
    ON hub_pagamento_evento (pagamento_evento_no);

CREATE INDEX idx_hub_pagamento_evento_pag
    ON hub_pagamento_evento (pagamento_id, pagamento_evento_id);


-- ============================================================
-- TABELA: hub_gateway_evento
-- Webhooks brutos recebidos de gateways de pagamento.
-- processed: false enquanto aguarda processamento.
-- evento_externo_id: ID do evento no gateway (idempotência).
-- ============================================================
CREATE TABLE IF NOT EXISTS hub_gateway_evento (
    gateway_evento_id UUID        NOT NULL DEFAULT gen_random_uuid(),
    gateway_id        UUID        NOT NULL,
    evento_externo_id TEXT,
    payload_bruto     JSONB       NOT NULL DEFAULT '{}',
    processed         BOOLEAN     NOT NULL DEFAULT FALSE,
    received_at       TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT hub_gateway_evento_pkey
        PRIMARY KEY (gateway_evento_id),

    CONSTRAINT hub_gateway_evento_gateway_id_evento_externo_id_key
        UNIQUE (gateway_id, evento_externo_id),

    CONSTRAINT hub_gateway_evento_gateway_id_fkey
        FOREIGN KEY (gateway_id)
        REFERENCES hub_gateway_pagamento (gateway_id)
        ON DELETE RESTRICT
);


-- ============================================================
-- TABELA: hub_audit_log
-- Log imutável de ações relevantes no Hub.
-- audit_no: sequencial global (para ordenação e referência).
-- tenant_id / user_id: nullable — eventos de sistema sem
-- vínculo a tenant ou usuário específico.
-- ============================================================
CREATE TABLE IF NOT EXISTS hub_audit_log (
    audit_id     UUID        NOT NULL DEFAULT gen_random_uuid(),
    tenant_id    UUID,
    user_id      UUID,
    audit_no     BIGINT      NOT NULL GENERATED BY DEFAULT AS IDENTITY,
    evento       TEXT        NOT NULL,
    payload_json JSONB       NOT NULL DEFAULT '{}',
    created_at   TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT hub_audit_log_pkey
        PRIMARY KEY (audit_id),

    CONSTRAINT hub_audit_log_tenant_id_fkey
        FOREIGN KEY (tenant_id)
        REFERENCES hub_tenant (tenant_id)
        ON DELETE CASCADE,

    CONSTRAINT hub_audit_log_user_id_fkey
        FOREIGN KEY (user_id)
        REFERENCES hub_user (user_id)
        ON DELETE SET NULL
);

CREATE INDEX idx_hub_audit_no
    ON hub_audit_log (audit_no);

CREATE INDEX idx_hub_audit_tenant
    ON hub_audit_log (tenant_id, created_at DESC)
    WHERE tenant_id IS NOT NULL;


-- ============================================================
-- TABELA: hub_store
-- Filiais / unidades de negócio de um tenant.
-- Um usuário pode estar vinculado a uma ou mais stores via
-- hub_user_store.
-- ============================================================
CREATE TABLE IF NOT EXISTS hub_store (
    store_id   UUID        NOT NULL DEFAULT gen_random_uuid(),
    tenant_id  UUID        NOT NULL,
    store_code TEXT        NOT NULL,
    store_name TEXT        NOT NULL,
    status     TEXT        NOT NULL DEFAULT 'active',
    is_active  BOOLEAN     NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT hub_store_pkey
        PRIMARY KEY (store_id),

    CONSTRAINT hub_store_tenant_id_store_code_key
        UNIQUE (tenant_id, store_code),

    CONSTRAINT hub_store_tenant_id_fkey
        FOREIGN KEY (tenant_id)
        REFERENCES hub_tenant (tenant_id)
        ON DELETE CASCADE,

    CONSTRAINT ck_hub_store_status
        CHECK (status IN ('active', 'inactive'))
);

CREATE INDEX idx_hub_store_tenant
    ON hub_store (tenant_id);


-- ============================================================
-- TABELA: hub_user_store
-- Vínculo de um usuário a uma store dentro de um tenant.
-- PK composta: (tenant_id, user_id, store_id).
-- ============================================================
CREATE TABLE IF NOT EXISTS hub_user_store (
    tenant_id UUID NOT NULL,
    user_id   UUID NOT NULL,
    store_id  UUID NOT NULL,

    CONSTRAINT hub_user_store_pkey
        PRIMARY KEY (tenant_id, user_id, store_id),

    CONSTRAINT hub_user_store_tenant_id_fkey
        FOREIGN KEY (tenant_id)
        REFERENCES hub_tenant (tenant_id)
        ON DELETE CASCADE,

    CONSTRAINT hub_user_store_user_id_fkey
        FOREIGN KEY (user_id)
        REFERENCES hub_user (user_id)
        ON DELETE CASCADE,

    CONSTRAINT hub_user_store_store_id_fkey
        FOREIGN KEY (store_id)
        REFERENCES hub_store (store_id)
        ON DELETE CASCADE
);
