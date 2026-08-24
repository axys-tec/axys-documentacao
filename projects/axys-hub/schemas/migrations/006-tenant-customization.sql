BEGIN;

CREATE TABLE IF NOT EXISTS identity.hub_tenant_customization (
    tenant_id       UUID        NOT NULL,
    schema_version  INTEGER     NOT NULL DEFAULT 1,
    revision        BIGINT      NOT NULL DEFAULT 1,
    logo_url        TEXT,
    logo_sha256     CHAR(64),
    logo_mime_type  TEXT,
    settings_json   JSONB       NOT NULL DEFAULT '{}'::jsonb,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT hub_tenant_customization_pkey PRIMARY KEY (tenant_id),
    CONSTRAINT fk_hub_tenant_customization_tenant FOREIGN KEY (tenant_id)
        REFERENCES identity.hub_tenant (tenant_id) ON DELETE CASCADE,
    CONSTRAINT ck_hub_tenant_customization_version CHECK (schema_version > 0),
    CONSTRAINT ck_hub_tenant_customization_revision CHECK (revision > 0),
    CONSTRAINT ck_hub_tenant_customization_settings CHECK (jsonb_typeof(settings_json) = 'object'),
    CONSTRAINT ck_hub_tenant_customization_logo_bundle CHECK (
        (logo_url IS NULL AND logo_sha256 IS NULL AND logo_mime_type IS NULL)
        OR
        (logo_url IS NOT NULL AND logo_sha256 IS NOT NULL AND logo_mime_type IS NOT NULL)
    ),
    CONSTRAINT ck_hub_tenant_customization_logo_url CHECK (
        logo_url IS NULL OR (logo_url ~ '^https://[^[:space:]]+$' AND length(logo_url) <= 2048)
    ),
    CONSTRAINT ck_hub_tenant_customization_logo_sha256 CHECK (
        logo_sha256 IS NULL OR logo_sha256 ~ '^[0-9a-f]{64}$'
    ),
    CONSTRAINT ck_hub_tenant_customization_logo_mime CHECK (
        logo_mime_type IS NULL OR logo_mime_type IN ('image/png', 'image/svg+xml')
    )
);

INSERT INTO identity.hub_tenant_customization (
    tenant_id, logo_url, logo_sha256, logo_mime_type
)
SELECT
    tenant_id,
    CASE tenant_code
        WHEN 'AXYS' THEN 'https://public.axys-tec.com.br/assets/axys/axys_black-n-blue.png'
        WHEN 'DIASECARDOZO' THEN 'https://public.axys-tec.com.br/assets/tenants/71044850799d79bbc254885ab00a2291793af9543b6886d0e5d6dce58a86295a.png'
    END,
    CASE tenant_code
        WHEN 'AXYS' THEN '9abcdad50599da054f3fba35cb0da6b75041d017957e2a67df810eaa91ce7584'
        WHEN 'DIASECARDOZO' THEN '71044850799d79bbc254885ab00a2291793af9543b6886d0e5d6dce58a86295a'
    END,
    'image/png'
FROM identity.hub_tenant
WHERE tenant_code IN ('AXYS', 'DIASECARDOZO')
ON CONFLICT (tenant_id) DO UPDATE
SET logo_url = EXCLUDED.logo_url,
    logo_sha256 = EXCLUDED.logo_sha256,
    logo_mime_type = EXCLUDED.logo_mime_type,
    revision = CASE
        WHEN hub_tenant_customization.logo_url IS DISTINCT FROM EXCLUDED.logo_url
          OR hub_tenant_customization.logo_sha256 IS DISTINCT FROM EXCLUDED.logo_sha256
          OR hub_tenant_customization.logo_mime_type IS DISTINCT FROM EXCLUDED.logo_mime_type
        THEN hub_tenant_customization.revision + 1
        ELSE hub_tenant_customization.revision
    END,
    updated_at = CASE
        WHEN hub_tenant_customization.logo_url IS DISTINCT FROM EXCLUDED.logo_url
          OR hub_tenant_customization.logo_sha256 IS DISTINCT FROM EXCLUDED.logo_sha256
          OR hub_tenant_customization.logo_mime_type IS DISTINCT FROM EXCLUDED.logo_mime_type
        THEN now()
        ELSE hub_tenant_customization.updated_at
    END;

COMMIT;
