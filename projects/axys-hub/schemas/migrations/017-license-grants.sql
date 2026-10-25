-- Concessoes administrativas de licencas por convite de uso unico.
CREATE SCHEMA IF NOT EXISTS granting;

CREATE TABLE IF NOT EXISTS granting.license_grant (
    grant_id UUID NOT NULL DEFAULT gen_random_uuid(),
    created_by UUID NOT NULL,
    contact_name TEXT NOT NULL,
    email TEXT,
    phone TEXT,
    document TEXT,
    tenant_name TEXT,
    tenant_document TEXT,
    role TEXT NOT NULL DEFAULT 'owner',
    status TEXT NOT NULL DEFAULT 'draft',
    license_days INTEGER NOT NULL DEFAULT 90,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    completed_at TIMESTAMPTZ,
    completed_user_id UUID,
    completed_tenant_id UUID,
    CONSTRAINT license_grant_pkey PRIMARY KEY (grant_id),
    CONSTRAINT fk_license_grant_creator FOREIGN KEY (created_by)
        REFERENCES identity.hub_user (user_id) ON DELETE RESTRICT,
    CONSTRAINT fk_license_grant_user FOREIGN KEY (completed_user_id)
        REFERENCES identity.hub_user (user_id) ON DELETE SET NULL,
    CONSTRAINT fk_license_grant_tenant FOREIGN KEY (completed_tenant_id)
        REFERENCES identity.hub_tenant (tenant_id) ON DELETE SET NULL,
    CONSTRAINT ck_license_grant_identifier CHECK (
        NULLIF(btrim(COALESCE(email, '')), '') IS NOT NULL OR
        NULLIF(btrim(COALESCE(phone, '')), '') IS NOT NULL OR
        NULLIF(btrim(COALESCE(document, '')), '') IS NOT NULL
    ),
    CONSTRAINT ck_license_grant_status CHECK (status IN ('draft','issued','completed','revoked','expired')),
    CONSTRAINT ck_license_grant_days CHECK (license_days BETWEEN 1 AND 3650),
    CONSTRAINT ck_license_grant_role CHECK (role IN ('owner','admin','user','viewer'))
);

CREATE TABLE IF NOT EXISTS granting.license_grant_item (
    grant_item_id BIGINT GENERATED ALWAYS AS IDENTITY,
    grant_id UUID NOT NULL,
    product_id INT NOT NULL,
    plan_code TEXT NOT NULL DEFAULT 'unlimited',
    entitlement_model TEXT,
    capacity INTEGER,
    usage_balance BIGINT,
    include_mcp BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT license_grant_item_pkey PRIMARY KEY (grant_item_id),
    CONSTRAINT uq_license_grant_item UNIQUE (grant_id, product_id),
    CONSTRAINT fk_license_grant_item_grant FOREIGN KEY (grant_id)
        REFERENCES granting.license_grant (grant_id) ON DELETE CASCADE,
    CONSTRAINT fk_license_grant_item_product FOREIGN KEY (product_id)
        REFERENCES product.product (product_id) ON DELETE RESTRICT,
    CONSTRAINT ck_license_grant_item_model CHECK (entitlement_model IS NULL OR entitlement_model IN ('capacity','usage')),
    CONSTRAINT ck_license_grant_item_capacity CHECK (capacity IS NULL OR capacity > 0),
    CONSTRAINT ck_license_grant_item_usage CHECK (usage_balance IS NULL OR usage_balance >= 0)
);

CREATE TABLE IF NOT EXISTS granting.license_grant_invite (
    invite_id UUID NOT NULL DEFAULT gen_random_uuid(),
    grant_id UUID NOT NULL,
    token_hash CHAR(64) NOT NULL,
    status TEXT NOT NULL DEFAULT 'active',
    expires_at TIMESTAMPTZ NOT NULL,
    consumed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT license_grant_invite_pkey PRIMARY KEY (invite_id),
    CONSTRAINT uq_license_grant_invite_token UNIQUE (token_hash),
    CONSTRAINT fk_license_grant_invite_grant FOREIGN KEY (grant_id)
        REFERENCES granting.license_grant (grant_id) ON DELETE CASCADE,
    CONSTRAINT ck_license_grant_invite_status CHECK (status IN ('active','consumed','revoked','expired'))
);

CREATE UNIQUE INDEX IF NOT EXISTS uq_license_grant_one_active_invite
    ON granting.license_grant_invite (grant_id) WHERE status = 'active';
CREATE INDEX IF NOT EXISTS idx_license_grant_status_created
    ON granting.license_grant (status, created_at DESC);
CREATE UNIQUE INDEX IF NOT EXISTS uq_license_grant_open_email
    ON granting.license_grant (lower(email))
    WHERE email IS NOT NULL AND status IN ('draft','issued');
CREATE UNIQUE INDEX IF NOT EXISTS uq_license_grant_open_phone
    ON granting.license_grant (phone)
    WHERE phone IS NOT NULL AND status IN ('draft','issued');
CREATE UNIQUE INDEX IF NOT EXISTS uq_license_grant_open_document
    ON granting.license_grant (document)
    WHERE document IS NOT NULL AND status IN ('draft','issued');

CREATE TABLE IF NOT EXISTS granting.license_grant_verification (
    verification_id UUID NOT NULL DEFAULT gen_random_uuid(),
    grant_id UUID NOT NULL,
    channel TEXT NOT NULL,
    destination TEXT NOT NULL,
    code_hash CHAR(64) NOT NULL,
    attempts SMALLINT NOT NULL DEFAULT 0,
    expires_at TIMESTAMPTZ NOT NULL,
    verified_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT license_grant_verification_pkey PRIMARY KEY (verification_id),
    CONSTRAINT fk_license_grant_verification_grant FOREIGN KEY (grant_id)
        REFERENCES granting.license_grant (grant_id) ON DELETE CASCADE,
    CONSTRAINT ck_license_grant_verification_channel CHECK (channel IN ('whatsapp','email')),
    CONSTRAINT ck_license_grant_verification_attempts CHECK (attempts BETWEEN 0 AND 6)
);

CREATE INDEX IF NOT EXISTS idx_license_grant_verification_active
    ON granting.license_grant_verification (grant_id, created_at DESC);

CREATE TABLE IF NOT EXISTS audit.license_grant_log (
    log_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    grant_id UUID NOT NULL,
    actor_user_id UUID,
    action TEXT NOT NULL,
    ip TEXT,
    details JSONB NOT NULL DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT fk_license_grant_log_grant FOREIGN KEY (grant_id)
        REFERENCES granting.license_grant (grant_id) ON DELETE CASCADE,
    CONSTRAINT fk_license_grant_log_actor FOREIGN KEY (actor_user_id)
        REFERENCES identity.hub_user (user_id) ON DELETE SET NULL
);
