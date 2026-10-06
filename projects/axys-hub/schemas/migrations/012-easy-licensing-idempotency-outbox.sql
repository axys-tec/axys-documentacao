-- Idempotência canônica por tenant/produto e entrega persistente Hub -> Easy.

ALTER TABLE billing.hub_usage_ledger
    DROP CONSTRAINT IF EXISTS uq_hub_usage_ledger_idempotency;

ALTER TABLE billing.hub_usage_ledger
    ADD CONSTRAINT uq_hub_usage_ledger_tenant_product_idempotency
        UNIQUE (tenant_id, product_id, idempotency_key);

CREATE TABLE IF NOT EXISTS billing.hub_easy_notification_outbox (
    notification_id  UUID        NOT NULL DEFAULT gen_random_uuid(),
    notification_key TEXT        NOT NULL,
    tenant_id        UUID        NOT NULL,
    product_id       INT,
    event_type       TEXT        NOT NULL,
    app_slug         TEXT,
    payload_json     JSONB       NOT NULL,
    status           TEXT        NOT NULL DEFAULT 'PENDING',
    attempts         INTEGER     NOT NULL DEFAULT 0,
    version          INTEGER     NOT NULL DEFAULT 1,
    next_attempt_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    last_error       TEXT,
    confirmed_at     TIMESTAMPTZ,
    created_at       TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at       TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT hub_easy_notification_outbox_pkey PRIMARY KEY (notification_id),
    CONSTRAINT uq_hub_easy_notification_outbox_key UNIQUE (notification_key),
    CONSTRAINT fk_hub_easy_notification_outbox_tenant FOREIGN KEY (tenant_id)
        REFERENCES identity.hub_tenant (tenant_id) ON DELETE CASCADE,
    CONSTRAINT fk_hub_easy_notification_outbox_product FOREIGN KEY (product_id)
        REFERENCES product.product (product_id) ON DELETE CASCADE,
    CONSTRAINT ck_hub_easy_notification_outbox_event
        CHECK (event_type IN ('capacity', 'access-mode')),
    CONSTRAINT ck_hub_easy_notification_outbox_status
        CHECK (status IN ('PENDING', 'CONFIRMED')),
    CONSTRAINT ck_hub_easy_notification_outbox_attempts CHECK (attempts >= 0),
    CONSTRAINT ck_hub_easy_notification_outbox_version CHECK (version > 0),
    CONSTRAINT ck_hub_easy_notification_outbox_payload
        CHECK (jsonb_typeof(payload_json) = 'object')
);

CREATE INDEX IF NOT EXISTS ix_hub_easy_notification_outbox_due
    ON billing.hub_easy_notification_outbox (next_attempt_at, created_at)
    WHERE status = 'PENDING';

