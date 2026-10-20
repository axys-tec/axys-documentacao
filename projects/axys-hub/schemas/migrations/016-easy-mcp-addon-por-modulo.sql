-- P4 Easy MCP: add-on comercial e autorizacao por modulo Easy.

CREATE TABLE IF NOT EXISTS billing.hub_license_addon (
    license_addon_id BIGINT      GENERATED ALWAYS AS IDENTITY,
    license_id       INT         NOT NULL,
    addon_id         INT         NOT NULL,
    status           TEXT        NOT NULL DEFAULT 'active',
    plan_code        TEXT        NOT NULL DEFAULT 'unlimited',
    access_mode      TEXT        NOT NULL DEFAULT 'ACTIVE',
    valid_from       TIMESTAMPTZ NOT NULL DEFAULT now(),
    valid_until      TIMESTAMPTZ,
    created_at       TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at       TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT hub_license_addon_pkey PRIMARY KEY (license_addon_id),
    CONSTRAINT uq_hub_license_addon UNIQUE (license_id, addon_id),
    CONSTRAINT fk_hub_license_addon_license FOREIGN KEY (license_id)
        REFERENCES billing.hub_license (license_id) ON DELETE CASCADE,
    CONSTRAINT fk_hub_license_addon_addon FOREIGN KEY (addon_id)
        REFERENCES product.addon (addon_id) ON DELETE RESTRICT,
    CONSTRAINT ck_hub_license_addon_status
        CHECK (status IN ('active', 'suspended', 'expired', 'revoked')),
    CONSTRAINT ck_hub_license_addon_access_mode
        CHECK (access_mode IN ('ACTIVE', 'VIEW_ONLY', 'BLOCKED')),
    CONSTRAINT ck_hub_license_addon_period
        CHECK (valid_until IS NULL OR valid_until > valid_from)
);

CREATE INDEX IF NOT EXISTS idx_hub_license_addon_active
    ON billing.hub_license_addon (license_id, status, access_mode);

-- Um add-on MCP comercialmente independente para cada produto Easy.
INSERT INTO product.addon (product_id, addon_code, name, description)
SELECT
    p.product_id,
    'MCP',
    'MCP para ' || p.name,
    'Autoriza o uso, via IA/MCP, dos endpoints do modulo ' || p.name
FROM product.product p
WHERE p.code IN ('CPU', 'PRI', 'ORC', 'DOC', 'PM', 'BDR', 'FIN', 'LIC', 'ONE')
ON CONFLICT (product_id, addon_code) DO UPDATE
SET name = EXCLUDED.name,
    description = EXCLUDED.description,
    is_active = TRUE,
    updated_at = now();

INSERT INTO product.addon_entitlement (
    addon_id, grant_model, unit, quantity, period_unit, rule_json
)
SELECT
    a.addon_id,
    'ilimitado',
    'mcp',
    NULL,
    'mes',
    jsonb_build_object('app', 'easy-mcp', 'product_code', p.code)
FROM product.addon a
JOIN product.product p ON p.product_id = a.product_id
WHERE a.addon_code = 'MCP'
  AND p.code IN ('CPU', 'PRI', 'ORC', 'DOC', 'PM', 'BDR', 'FIN', 'LIC', 'ONE')
  AND NOT EXISTS (
      SELECT 1 FROM product.addon_entitlement e
      WHERE e.addon_id = a.addon_id AND e.unit = 'mcp' AND e.is_active = TRUE
  );

-- Graca comercial: MCP unlimited para cada modulo Easy ja ativo de AXYS e DIASECARDOZO.
-- LUNALO permanece somente no Gestor e, portanto, nao recebe add-on Easy MCP.
INSERT INTO billing.hub_license_addon (
    license_id, addon_id, status, plan_code, access_mode, valid_from, valid_until
)
SELECT
    l.license_id,
    a.addon_id,
    'active',
    'unlimited',
    'ACTIVE',
    COALESCE(l.valid_from, now()),
    NULL
FROM billing.hub_license l
JOIN identity.hub_tenant t ON t.tenant_id = l.tenant_id
JOIN product.product p ON p.product_id = l.product_id
JOIN product.addon a ON a.product_id = p.product_id AND a.addon_code = 'MCP'
WHERE t.tenant_code IN ('AXYS', 'DIASECARDOZO')
  AND p.code IN ('CPU', 'PRI', 'ORC', 'DOC', 'PM', 'BDR', 'FIN', 'LIC', 'ONE')
  AND l.status = 'active'
  AND (l.valid_until IS NULL OR l.valid_until > now())
ON CONFLICT (license_id, addon_id) DO UPDATE
SET status = 'active',
    plan_code = 'unlimited',
    access_mode = 'ACTIVE',
    valid_until = NULL,
    updated_at = now();
