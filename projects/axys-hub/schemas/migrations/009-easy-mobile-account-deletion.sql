BEGIN;

ALTER TABLE identity.client_easy_mobile
    ALTER COLUMN full_name DROP NOT NULL,
    ALTER COLUMN phone DROP NOT NULL,
    ALTER COLUMN email DROP NOT NULL,
    ALTER COLUMN password_hash DROP NOT NULL,
    ALTER COLUMN notification_preferences DROP NOT NULL;

ALTER TABLE identity.client_easy_mobile
    ADD COLUMN IF NOT EXISTS deletion_contact_consent_at TIMESTAMPTZ,
    ADD COLUMN IF NOT EXISTS deletion_contact_retain_until TIMESTAMPTZ;

CREATE TABLE IF NOT EXISTS analytics.easy_mobile_deletion_feedback (
    feedback_uuid UUID NOT NULL DEFAULT gen_random_uuid(),
    reason TEXT NOT NULL,
    reason_detail TEXT,
    accepts_contact BOOLEAN NOT NULL DEFAULT FALSE,
    days_of_use INTEGER NOT NULL DEFAULT 0,
    uf CHAR(2),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT easy_mobile_deletion_feedback_pkey PRIMARY KEY (feedback_uuid),
    CONSTRAINT ck_easy_mobile_deletion_feedback_reason CHECK (btrim(reason) <> ''),
    CONSTRAINT ck_easy_mobile_deletion_feedback_detail CHECK (
        reason_detail IS NULL OR char_length(reason_detail) <= 280
    ),
    CONSTRAINT ck_easy_mobile_deletion_feedback_days CHECK (days_of_use >= 0),
    CONSTRAINT ck_easy_mobile_deletion_feedback_uf CHECK (uf IS NULL OR uf ~ '^[A-Z]{2}$')
);

COMMENT ON COLUMN identity.client_easy_mobile.deletion_contact_consent_at IS
    'Consentimento específico para contato após exclusão da conta.';
COMMENT ON COLUMN identity.client_easy_mobile.deletion_contact_retain_until IS
    'Limite para retenção temporária de full_name e phone após exclusão com opt-in.';
COMMENT ON TABLE analytics.easy_mobile_deletion_feedback IS
    'Pesquisa de exclusão sem FK para identidade; preserva feedback sem reidentificar o titular.';
COMMENT ON CONSTRAINT fk_easy_mobile_event_client ON analytics.easy_mobile_event IS
    'ON DELETE SET NULL atua apenas em exclusão física; exclusão lógica preserva client_uuid para coerência histórica.';

COMMIT;
