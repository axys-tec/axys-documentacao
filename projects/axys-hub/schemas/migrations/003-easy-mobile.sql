BEGIN;

CREATE TABLE IF NOT EXISTS identity.client_easy_mobile (
    client_uuid       UUID        NOT NULL DEFAULT gen_random_uuid(),
    client_hub_uuid   UUID,
    full_name         TEXT        NOT NULL,
    phone             TEXT        NOT NULL,
    email             TEXT        NOT NULL,
    pending_email     TEXT,
    pending_phone     TEXT,
    password_hash     TEXT        NOT NULL,
    cpf               TEXT,
    uf                CHAR(2),
    profession        TEXT,
    status            TEXT        NOT NULL DEFAULT 'pending_verification',
    email_verified_at TIMESTAMPTZ,
    phone_verified_at TIMESTAMPTZ,
    notification_preferences JSONB NOT NULL DEFAULT '{"new_edition":true,"new_publication":true}'::jsonb,
    deleted_at        TIMESTAMPTZ,
    last_login_at     TIMESTAMPTZ,
    created_at        TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at        TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT client_easy_mobile_pkey PRIMARY KEY (client_uuid),
    CONSTRAINT fk_client_easy_mobile_hub_user FOREIGN KEY (client_hub_uuid)
        REFERENCES identity.hub_user (user_id) ON DELETE SET NULL,
    CONSTRAINT ck_client_easy_mobile_status CHECK (
        status IN ('pending_verification', 'active', 'deleted', 'blocked')
    ),
    CONSTRAINT ck_client_easy_mobile_email CHECK (position('@' in email) > 1),
    CONSTRAINT ck_client_easy_mobile_phone CHECK (phone ~ '^\d{10,15}$'),
    CONSTRAINT ck_client_easy_mobile_cpf CHECK (cpf IS NULL OR cpf ~ '^\d{11}$'),
    CONSTRAINT ck_client_easy_mobile_uf CHECK (uf IS NULL OR uf ~ '^[A-Z]{2}$'),
    CONSTRAINT ck_client_easy_mobile_notifications CHECK (jsonb_typeof(notification_preferences) = 'object')
);

ALTER TABLE identity.client_easy_mobile ADD COLUMN IF NOT EXISTS pending_email TEXT;
ALTER TABLE identity.client_easy_mobile ADD COLUMN IF NOT EXISTS pending_phone TEXT;

CREATE UNIQUE INDEX IF NOT EXISTS uq_client_easy_mobile_email_active
    ON identity.client_easy_mobile (lower(email))
    WHERE status <> 'deleted';
CREATE UNIQUE INDEX IF NOT EXISTS uq_client_easy_mobile_phone_active
    ON identity.client_easy_mobile (phone)
    WHERE status <> 'deleted';
CREATE UNIQUE INDEX IF NOT EXISTS uq_client_easy_mobile_cpf_active
    ON identity.client_easy_mobile (cpf)
    WHERE cpf IS NOT NULL AND status <> 'deleted';
CREATE INDEX IF NOT EXISTS idx_client_easy_mobile_hub_user
    ON identity.client_easy_mobile (client_hub_uuid)
    WHERE client_hub_uuid IS NOT NULL;

CREATE TABLE IF NOT EXISTS auth.easy_mobile_mfa_challenge (
    challenge_uuid UUID        NOT NULL DEFAULT gen_random_uuid(),
    client_uuid    UUID        NOT NULL,
    channel        TEXT        NOT NULL,
    code_hash      CHAR(64)    NOT NULL,
    expires_at     TIMESTAMPTZ NOT NULL,
    attempts       SMALLINT    NOT NULL DEFAULT 0,
    verified_at    TIMESTAMPTZ,
    created_at     TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT easy_mobile_mfa_challenge_pkey PRIMARY KEY (challenge_uuid),
    CONSTRAINT fk_easy_mobile_mfa_client FOREIGN KEY (client_uuid)
        REFERENCES identity.client_easy_mobile (client_uuid) ON DELETE CASCADE,
    CONSTRAINT ck_easy_mobile_mfa_channel CHECK (channel IN ('email', 'whatsapp')),
    CONSTRAINT ck_easy_mobile_mfa_attempts CHECK (attempts BETWEEN 0 AND 5)
);

CREATE INDEX IF NOT EXISTS idx_easy_mobile_mfa_pending
    ON auth.easy_mobile_mfa_challenge (client_uuid, expires_at DESC)
    WHERE verified_at IS NULL;

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

CREATE TABLE IF NOT EXISTS analytics.easy_mobile_event (
    event_id         BIGINT      GENERATED ALWAYS AS IDENTITY,
    event_uuid       UUID        NOT NULL DEFAULT gen_random_uuid(),
    ingestion_key    TEXT        NOT NULL,
    event_name       TEXT        NOT NULL,
    client_uuid      UUID,
    hub_user_uuid    UUID,
    anonymous_id     TEXT,
    session_id       TEXT,
    occurred_at      TIMESTAMPTZ NOT NULL,
    properties_json  JSONB       NOT NULL DEFAULT '{}'::jsonb,
    created_at       TIMESTAMPTZ NOT NULL DEFAULT now(),

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
    ON analytics.easy_mobile_event (client_uuid, occurred_at DESC)
    WHERE client_uuid IS NOT NULL;

DO $role$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'easy_mobile_analytics_writer') THEN
        IF (SELECT rolcreaterole OR rolsuper FROM pg_roles WHERE rolname = current_user) THEN
            CREATE ROLE easy_mobile_analytics_writer NOLOGIN;
        ELSE
            RAISE NOTICE 'Role easy_mobile_analytics_writer requer execução administrativa separada.';
        END IF;
    END IF;
END
$role$;

DO $grants$
BEGIN
    IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'easy_mobile_analytics_writer') THEN
        REVOKE ALL ON SCHEMA identity, auth, product, orders, billing, gateway, fiscal, commercial, audit
            FROM easy_mobile_analytics_writer;
        REVOKE ALL ON ALL TABLES IN SCHEMA analytics FROM easy_mobile_analytics_writer;
        GRANT USAGE ON SCHEMA analytics TO easy_mobile_analytics_writer;
        GRANT INSERT ON analytics.easy_mobile_event TO easy_mobile_analytics_writer;
        GRANT USAGE, SELECT ON SEQUENCE analytics.easy_mobile_event_event_id_seq
            TO easy_mobile_analytics_writer;
    END IF;
END
$grants$;

COMMIT;
