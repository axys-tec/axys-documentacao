BEGIN;

CREATE TABLE IF NOT EXISTS analytics.public_endpoint_hit (
    hit_id          BIGINT      GENERATED ALWAYS AS IDENTITY,
    route_path      TEXT        NOT NULL,
    referrer_host   TEXT,
    utm_source      TEXT,
    utm_medium      TEXT,
    utm_campaign    TEXT,
    device_family   TEXT        NOT NULL DEFAULT 'unknown',
    is_bot          BOOLEAN     NOT NULL DEFAULT FALSE,
    is_preview      BOOLEAN     NOT NULL DEFAULT FALSE,
    occurred_at     TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT public_endpoint_hit_pkey PRIMARY KEY (hit_id),
    CONSTRAINT ck_public_endpoint_hit_route CHECK (route_path LIKE '/%'),
    CONSTRAINT ck_public_endpoint_hit_device CHECK (
        device_family IN ('android', 'ios', 'ipados', 'desktop', 'unknown')
    )
);

CREATE INDEX IF NOT EXISTS idx_public_endpoint_hit_route_occurred
    ON analytics.public_endpoint_hit (route_path, occurred_at DESC);
CREATE INDEX IF NOT EXISTS idx_public_endpoint_hit_human_occurred
    ON analytics.public_endpoint_hit (occurred_at DESC)
    WHERE NOT is_bot AND NOT is_preview;

COMMENT ON TABLE analytics.public_endpoint_hit IS
    'Contagem técnica server-side de chegada a endpoints públicos, sem cookie, IP ou identificador persistente; isolada do analytics comportamental sujeito a consentimento.';

COMMIT;
