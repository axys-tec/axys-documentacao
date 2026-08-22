BEGIN;

ALTER TABLE identity.hub_tenant_customization
    ADD COLUMN IF NOT EXISTS logo_json JSONB;

DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema='identity'
          AND table_name='hub_tenant_customization'
          AND column_name='logo_url'
    ) THEN
        UPDATE identity.hub_tenant_customization
        SET logo_json = CASE
            WHEN logo_url IS NULL THEN NULL
            ELSE jsonb_build_object(
                'url', logo_url,
                'sha256', btrim(logo_sha256),
                'mime_type', logo_mime_type
            )
        END
        WHERE logo_json IS NULL;
    END IF;
END $$;

ALTER TABLE identity.hub_tenant_customization
    DROP CONSTRAINT IF EXISTS ck_hub_tenant_customization_logo_bundle,
    DROP CONSTRAINT IF EXISTS ck_hub_tenant_customization_logo_url,
    DROP CONSTRAINT IF EXISTS ck_hub_tenant_customization_logo_sha256,
    DROP CONSTRAINT IF EXISTS ck_hub_tenant_customization_logo_mime,
    DROP COLUMN IF EXISTS logo_url,
    DROP COLUMN IF EXISTS logo_sha256,
    DROP COLUMN IF EXISTS logo_mime_type;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname='ck_hub_tenant_customization_logo_json'
          AND conrelid='identity.hub_tenant_customization'::regclass
    ) THEN
        ALTER TABLE identity.hub_tenant_customization
        ADD CONSTRAINT ck_hub_tenant_customization_logo_json CHECK (
            logo_json IS NULL OR (
                jsonb_typeof(logo_json) = 'object'
                AND logo_json ?& ARRAY['url', 'sha256', 'mime_type']
                AND logo_json->>'url' ~ '^https://[^[:space:]]+$'
                AND length(logo_json->>'url') <= 2048
                AND logo_json->>'sha256' ~ '^[0-9a-f]{64}$'
                AND logo_json->>'mime_type' IN ('image/png', 'image/svg+xml')
            )
        );
    END IF;
END $$;

INSERT INTO identity.hub_tenant_customization (tenant_id, logo_json)
SELECT
    tenant_id,
    CASE tenant_code
        WHEN 'AXYS' THEN jsonb_build_object(
            'url', 'https://public.axys-tec.com.br/assets/axys/axys_black-n-blue.png',
            'sha256', '9abcdad50599da054f3fba35cb0da6b75041d017957e2a67df810eaa91ce7584',
            'mime_type', 'image/png'
        )
        WHEN 'DIASECARDOZO' THEN jsonb_build_object(
            'url', 'https://public.axys-tec.com.br/assets/tenants/71044850799d79bb.png',
            'sha256', '71044850799d79bbc254885ab00a2291793af9543b6886d0e5d6dce58a86295a',
            'mime_type', 'image/png'
        )
    END
FROM identity.hub_tenant
WHERE tenant_code IN ('AXYS', 'DIASECARDOZO')
ON CONFLICT (tenant_id) DO UPDATE
SET logo_json = EXCLUDED.logo_json,
    revision = 1,
    updated_at = CASE
        WHEN hub_tenant_customization.logo_json IS DISTINCT FROM EXCLUDED.logo_json
        THEN now()
        ELSE hub_tenant_customization.updated_at
    END;

-- A personalização ainda está na versão inicial, sem revisão publicada anterior.
UPDATE identity.hub_tenant_customization
SET revision = 1
WHERE revision <> 1;

COMMIT;
