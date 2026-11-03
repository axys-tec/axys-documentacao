BEGIN;

CREATE TABLE IF NOT EXISTS commercial.campaign_registration (
    registration_id      UUID        NOT NULL DEFAULT gen_random_uuid(),
    campaign_code        TEXT        NOT NULL,
    name                 TEXT        NOT NULL,
    profession           TEXT        NOT NULL,
    email                TEXT        NOT NULL,
    phone                TEXT        NOT NULL,
    participation_status TEXT        NOT NULL DEFAULT 'REGISTERED',
    privacy_accepted_at  TIMESTAMPTZ NOT NULL,
    news_consent_at      TIMESTAMPTZ NOT NULL,
    rules_accepted_at    TIMESTAMPTZ,
    visitor_id           UUID,
    session_id           UUID,
    utm_source           TEXT,
    utm_medium           TEXT,
    utm_campaign         TEXT,
    referrer_url         TEXT,
    source_platform      TEXT        NOT NULL DEFAULT 'other',
    confirmation_email_sent_at    TIMESTAMPTZ,
    confirmation_whatsapp_sent_at TIMESTAMPTZ,
    confirmation_last_error       TEXT,
    created_at           TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at           TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT campaign_registration_pkey PRIMARY KEY (registration_id),
    CONSTRAINT ck_campaign_registration_code CHECK (campaign_code ~ '^[A-Z][A-Z0-9_]{2,79}$'),
    CONSTRAINT ck_campaign_registration_status CHECK (
        participation_status IN ('REGISTERED', 'ELIGIBLE', 'INELIGIBLE', 'SELECTED', 'NOT_SELECTED', 'CANCELLED')
    ),
    CONSTRAINT ck_campaign_registration_name CHECK (btrim(name) <> ''),
    CONSTRAINT ck_campaign_registration_profession CHECK (btrim(profession) <> ''),
    CONSTRAINT ck_campaign_registration_email CHECK (btrim(email) <> ''),
    CONSTRAINT ck_campaign_registration_phone CHECK (phone ~ '^\d{10,15}$'),
    CONSTRAINT ck_campaign_registration_platform CHECK (source_platform IN ('ios', 'android', 'other')),
    CONSTRAINT fk_campaign_registration_visitor FOREIGN KEY (visitor_id)
        REFERENCES analytics.visitor (visitor_id) ON DELETE SET NULL,
    CONSTRAINT fk_campaign_registration_session FOREIGN KEY (session_id)
        REFERENCES analytics.session (session_id) ON DELETE SET NULL
);

ALTER TABLE commercial.campaign_registration
    ADD COLUMN IF NOT EXISTS source_platform TEXT NOT NULL DEFAULT 'other',
    ADD COLUMN IF NOT EXISTS confirmation_email_sent_at TIMESTAMPTZ,
    ADD COLUMN IF NOT EXISTS confirmation_whatsapp_sent_at TIMESTAMPTZ,
    ADD COLUMN IF NOT EXISTS confirmation_last_error TEXT;

DO $$ BEGIN
    ALTER TABLE commercial.campaign_registration
        ADD CONSTRAINT ck_campaign_registration_platform
        CHECK (source_platform IN ('ios', 'android', 'other'));
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

ALTER TABLE commercial.campaign_registration
    ALTER COLUMN participation_status SET DEFAULT 'REGISTERED';

ALTER TABLE commercial.campaign_registration
    DROP CONSTRAINT IF EXISTS ck_campaign_registration_status;

UPDATE commercial.campaign_registration
SET participation_status = 'REGISTERED', updated_at = now()
WHERE participation_status = 'PRE_REGISTERED';

ALTER TABLE commercial.campaign_registration
    ADD CONSTRAINT ck_campaign_registration_status CHECK (
        participation_status IN ('REGISTERED', 'ELIGIBLE', 'INELIGIBLE', 'SELECTED', 'NOT_SELECTED', 'CANCELLED')
    );

CREATE UNIQUE INDEX IF NOT EXISTS uq_campaign_registration_email
    ON commercial.campaign_registration (campaign_code, lower(email));
CREATE UNIQUE INDEX IF NOT EXISTS uq_campaign_registration_phone
    ON commercial.campaign_registration (campaign_code, phone);
CREATE INDEX IF NOT EXISTS idx_campaign_registration_created
    ON commercial.campaign_registration (campaign_code, created_at DESC);

COMMIT;
