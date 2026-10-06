-- AxysEasy — entitlement canônico por licença + consumo isolado idempotente.
-- Compatibilidade: licenças existentes ficam unlimited e ACTIVE até receberem um plano explícito.

ALTER TABLE billing.hub_license
    ADD COLUMN IF NOT EXISTS entitlement_model TEXT,
    ADD COLUMN IF NOT EXISTS plan_code TEXT,
    ADD COLUMN IF NOT EXISTS capacity INTEGER,
    ADD COLUMN IF NOT EXISTS usage_balance BIGINT,
    ADD COLUMN IF NOT EXISTS access_mode TEXT NOT NULL DEFAULT 'ACTIVE',
    ADD COLUMN IF NOT EXISTS suspended_at TIMESTAMPTZ,
    ADD COLUMN IF NOT EXISTS view_only_until TIMESTAMPTZ,
    ADD COLUMN IF NOT EXISTS blocked_at TIMESTAMPTZ,
    ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ NOT NULL DEFAULT now();

UPDATE billing.hub_license l
SET entitlement_model = CASE WHEN p.code IN ('PRI', 'CPU') THEN 'usage' ELSE 'capacity' END,
    plan_code = COALESCE(l.plan_code, 'unlimited'),
    access_mode = CASE
        WHEN l.status = 'revoked' THEN 'BLOCKED'
        WHEN l.status IN ('suspended', 'expired') THEN 'VIEW_ONLY'
        ELSE COALESCE(l.access_mode, 'ACTIVE')
    END,
    updated_at = now()
FROM product.product p
WHERE p.product_id = l.product_id
  AND p.code IN ('PRI','CPU','DOC','PM','LIC','ORC','BDR','FIN','ONE')
  AND l.entitlement_model IS NULL;

ALTER TABLE billing.hub_license
    DROP CONSTRAINT IF EXISTS ck_hub_license_entitlement_model,
    DROP CONSTRAINT IF EXISTS ck_hub_license_capacity,
    DROP CONSTRAINT IF EXISTS ck_hub_license_usage_balance,
    DROP CONSTRAINT IF EXISTS ck_hub_license_access_mode;

ALTER TABLE billing.hub_license
    ADD CONSTRAINT ck_hub_license_entitlement_model
        CHECK (entitlement_model IS NULL OR entitlement_model IN ('capacity', 'usage')),
    ADD CONSTRAINT ck_hub_license_capacity
        CHECK (capacity IS NULL OR capacity > 0),
    ADD CONSTRAINT ck_hub_license_usage_balance
        CHECK (usage_balance IS NULL OR usage_balance >= 0),
    ADD CONSTRAINT ck_hub_license_access_mode
        CHECK (access_mode IN ('ACTIVE', 'VIEW_ONLY', 'BLOCKED'));

CREATE OR REPLACE FUNCTION billing.hub_license_entitlement_defaults()
RETURNS trigger LANGUAGE plpgsql AS $$
DECLARE product_code TEXT;
BEGIN
    SELECT code INTO product_code FROM product.product WHERE product_id = NEW.product_id;
    IF product_code IN ('PRI', 'CPU') THEN
        NEW.entitlement_model := COALESCE(NEW.entitlement_model, 'usage');
    ELSIF product_code IN ('DOC','PM','LIC','ORC','BDR','FIN','ONE') THEN
        NEW.entitlement_model := COALESCE(NEW.entitlement_model, 'capacity');
    END IF;
    NEW.plan_code := COALESCE(NEW.plan_code, 'unlimited');
    NEW.updated_at := now();
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_hub_license_entitlement_defaults ON billing.hub_license;
CREATE TRIGGER trg_hub_license_entitlement_defaults
BEFORE INSERT OR UPDATE OF product_id, entitlement_model, plan_code
ON billing.hub_license FOR EACH ROW
EXECUTE FUNCTION billing.hub_license_entitlement_defaults();

CREATE TABLE IF NOT EXISTS billing.hub_usage_ledger (
    usage_entry_id  UUID        NOT NULL DEFAULT gen_random_uuid(),
    license_id      INT         NOT NULL,
    tenant_id       UUID        NOT NULL,
    user_id         UUID,
    product_id      INT         NOT NULL,
    resource_id     TEXT        NOT NULL,
    event_type      TEXT        NOT NULL,
    quantity        INTEGER     NOT NULL DEFAULT 1,
    balance_before  BIGINT,
    balance_after   BIGINT,
    idempotency_key TEXT        NOT NULL,
    metadata_json   JSONB       NOT NULL DEFAULT '{}'::jsonb,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT hub_usage_ledger_pkey PRIMARY KEY (usage_entry_id),
    CONSTRAINT uq_hub_usage_ledger_idempotency UNIQUE (license_id, idempotency_key),
    CONSTRAINT fk_hub_usage_ledger_license FOREIGN KEY (license_id)
        REFERENCES billing.hub_license (license_id) ON DELETE RESTRICT,
    CONSTRAINT fk_hub_usage_ledger_tenant FOREIGN KEY (tenant_id)
        REFERENCES identity.hub_tenant (tenant_id) ON DELETE RESTRICT,
    CONSTRAINT fk_hub_usage_ledger_user FOREIGN KEY (user_id)
        REFERENCES identity.hub_user (user_id) ON DELETE SET NULL,
    CONSTRAINT fk_hub_usage_ledger_product FOREIGN KEY (product_id)
        REFERENCES product.product (product_id) ON DELETE RESTRICT,
    CONSTRAINT ck_hub_usage_ledger_quantity CHECK (quantity > 0),
    CONSTRAINT ck_hub_usage_ledger_metadata CHECK (jsonb_typeof(metadata_json) = 'object')
);

CREATE INDEX IF NOT EXISTS idx_hub_usage_ledger_tenant_product_created
    ON billing.hub_usage_ledger (tenant_id, product_id, created_at DESC);

CREATE TABLE IF NOT EXISTS billing.hub_retention_policy (
    policy_code          TEXT        NOT NULL,
    customer_days        INTEGER     NOT NULL,
    recovery_margin_days INTEGER     NOT NULL,
    is_active            BOOLEAN     NOT NULL DEFAULT TRUE,
    updated_at           TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT hub_retention_policy_pkey PRIMARY KEY (policy_code),
    CONSTRAINT ck_hub_retention_policy_days CHECK (customer_days >= 0 AND recovery_margin_days >= 0)
);

INSERT INTO billing.hub_retention_policy (policy_code, customer_days, recovery_margin_days)
VALUES ('usage', 30, 30), ('capacity', 60, 60), ('unlimited', 120, 60)
ON CONFLICT (policy_code) DO UPDATE SET
    customer_days = EXCLUDED.customer_days,
    recovery_margin_days = EXCLUDED.recovery_margin_days,
    updated_at = now();
