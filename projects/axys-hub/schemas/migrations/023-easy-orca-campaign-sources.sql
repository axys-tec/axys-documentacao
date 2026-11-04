BEGIN;

ALTER TABLE commercial.campaign_registration
    ADD COLUMN IF NOT EXISTS acquisition_source TEXT NOT NULL DEFAULT 'META';

ALTER TABLE commercial.campaign_registration
    DROP CONSTRAINT IF EXISTS ck_campaign_registration_acquisition_source;
ALTER TABLE commercial.campaign_registration
    ADD CONSTRAINT ck_campaign_registration_acquisition_source CHECK (
        acquisition_source IN ('META', 'EASY_MOBILE', 'CONTATOS_RENAN')
    );

CREATE INDEX IF NOT EXISTS idx_campaign_registration_source_created
    ON commercial.campaign_registration (campaign_code, acquisition_source, created_at DESC);

CREATE TABLE IF NOT EXISTS commercial.campaign_invitation (
    invitation_uuid UUID NOT NULL DEFAULT gen_random_uuid(),
    campaign_code TEXT NOT NULL,
    acquisition_source TEXT NOT NULL,
    recipient_key TEXT NOT NULL,
    recipient_name TEXT NOT NULL,
    recipient_email TEXT,
    recipient_phone TEXT,
    channel TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT 'PENDING',
    is_test BOOLEAN NOT NULL DEFAULT false,
    sent_at TIMESTAMPTZ,
    last_error TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT campaign_invitation_pkey PRIMARY KEY (invitation_uuid),
    CONSTRAINT ck_campaign_invitation_source CHECK (acquisition_source IN ('EASY_MOBILE', 'CONTATOS_RENAN')),
    CONSTRAINT ck_campaign_invitation_channel CHECK (channel IN ('EMAIL', 'WHATSAPP')),
    CONSTRAINT ck_campaign_invitation_status CHECK (status IN ('PENDING', 'SENT', 'FAILED', 'SKIPPED')),
    CONSTRAINT ck_campaign_invitation_recipient CHECK (
        (channel = 'EMAIL' AND recipient_email IS NOT NULL)
        OR (channel = 'WHATSAPP' AND recipient_phone IS NOT NULL)
    ),
    CONSTRAINT uq_campaign_invitation_delivery UNIQUE (
        campaign_code, acquisition_source, recipient_key, channel, is_test
    )
);

CREATE INDEX IF NOT EXISTS idx_campaign_invitation_status
    ON commercial.campaign_invitation (campaign_code, acquisition_source, status, created_at DESC);

COMMIT;
