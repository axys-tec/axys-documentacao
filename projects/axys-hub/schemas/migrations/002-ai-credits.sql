BEGIN;

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

INSERT INTO billing.hub_ai_credit_account (tenant_id, is_unlimited)
SELECT tenant_id, tenant_code IN ('AXYS', 'DIASECARDOZO', 'LUNALO')
FROM identity.hub_tenant
ON CONFLICT (tenant_id) DO UPDATE
SET is_unlimited = EXCLUDED.is_unlimited,
    updated_at = now();

COMMIT;
