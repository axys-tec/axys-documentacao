BEGIN;

ALTER TABLE identity.client_easy_mobile
    ADD COLUMN IF NOT EXISTS failed_attempts SMALLINT NOT NULL DEFAULT 0,
    ADD COLUMN IF NOT EXISTS locked_until TIMESTAMPTZ;

CREATE TABLE IF NOT EXISTS identity.easy_mobile_hub_user_profile (
    hub_user_uuid UUID NOT NULL,
    status TEXT NOT NULL DEFAULT 'active',
    notification_preferences JSONB NOT NULL
        DEFAULT '{"new_edition":true,"new_publication":true}'::jsonb,
    deleted_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT easy_mobile_hub_user_profile_pkey PRIMARY KEY (hub_user_uuid),
    CONSTRAINT fk_easy_mobile_hub_profile_user FOREIGN KEY (hub_user_uuid)
        REFERENCES identity.hub_user (user_id) ON DELETE CASCADE,
    CONSTRAINT ck_easy_mobile_hub_profile_status CHECK (status IN ('active', 'deleted', 'blocked')),
    CONSTRAINT ck_easy_mobile_hub_profile_notifications CHECK (
        jsonb_typeof(notification_preferences) = 'object'
    )
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
    ON auth.easy_mobile_rate_limit (blocked_until)
    WHERE blocked_until IS NOT NULL;

COMMIT;
