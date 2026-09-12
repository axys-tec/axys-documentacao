BEGIN;

-- Interesse comercial do Easy Mobile. É separado dos eventos append-only porque
-- status e note mudam durante o atendimento e possuem política de retenção própria.
CREATE TABLE IF NOT EXISTS analytics.easy_mobile_lead (
    lead_uuid UUID NOT NULL DEFAULT gen_random_uuid(),
    ingestion_key TEXT NOT NULL,
    event_name TEXT NOT NULL DEFAULT 'solucao_interesse',
    client_uuid UUID,
    hub_user_uuid UUID,
    session_id TEXT NOT NULL,
    occurred_at TIMESTAMPTZ NOT NULL,
    properties_json JSONB NOT NULL DEFAULT '{}'::jsonb,
    status TEXT NOT NULL DEFAULT 'novo',
    note TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT easy_mobile_lead_pkey PRIMARY KEY (lead_uuid),
    CONSTRAINT uq_easy_mobile_lead_ingestion UNIQUE (ingestion_key),
    CONSTRAINT fk_easy_mobile_lead_client FOREIGN KEY (client_uuid)
        REFERENCES identity.client_easy_mobile (client_uuid) ON DELETE RESTRICT,
    CONSTRAINT fk_easy_mobile_lead_hub_user FOREIGN KEY (hub_user_uuid)
        REFERENCES identity.hub_user (user_id) ON DELETE RESTRICT,
    CONSTRAINT ck_easy_mobile_lead_event CHECK (event_name = 'solucao_interesse'),
    CONSTRAINT ck_easy_mobile_lead_ingestion CHECK (btrim(ingestion_key) <> ''),
    CONSTRAINT ck_easy_mobile_lead_actor CHECK (
        (client_uuid IS NOT NULL AND hub_user_uuid IS NULL)
        OR (client_uuid IS NULL AND hub_user_uuid IS NOT NULL)
    ),
    CONSTRAINT ck_easy_mobile_lead_session CHECK (btrim(session_id) <> ''),
    CONSTRAINT ck_easy_mobile_lead_status CHECK (
        status IN ('novo', 'contatado', 'qualificado', 'convertido', 'descartado')
    ),
    CONSTRAINT ck_easy_mobile_lead_properties CHECK (
        jsonb_typeof(properties_json) = 'object'
        AND properties_json ? 'solucao_id'
        AND properties_json ? 'acao'
        AND properties_json ? 'contexto'
        AND properties_json->'solucao_id' <> 'null'::jsonb
        AND jsonb_typeof(properties_json->'acao') = 'string'
        AND properties_json->>'acao' IN ('saber_mais', 'contratar', 'video', 'site')
        AND jsonb_typeof(properties_json->'contexto') = 'object'
    )
);

CREATE INDEX IF NOT EXISTS idx_easy_mobile_lead_status_occurred
    ON analytics.easy_mobile_lead (status, occurred_at DESC);
CREATE INDEX IF NOT EXISTS idx_easy_mobile_lead_client_occurred
    ON analytics.easy_mobile_lead (client_uuid, occurred_at DESC)
    WHERE client_uuid IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_easy_mobile_lead_hub_user_occurred
    ON analytics.easy_mobile_lead (hub_user_uuid, occurred_at DESC)
    WHERE hub_user_uuid IS NOT NULL;

COMMENT ON TABLE analytics.easy_mobile_event IS
    'Telemetria append-only do Easy Mobile; acesso da API limitado a SELECT e INSERT.';
COMMENT ON TABLE analytics.easy_mobile_lead IS
    'Interesse comercial do Easy Mobile; a API altera somente status, note e updated_at.';

DO $grants$
BEGIN
    IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'easy_mobile_analytics_writer') THEN
        -- easy_mobile_api herda somente esta role. Eventos são append-only; leads
        -- permitem alterar apenas os campos operacionais do atendimento.
        GRANT SELECT, INSERT ON analytics.easy_mobile_event TO easy_mobile_analytics_writer;
        GRANT SELECT, INSERT ON analytics.easy_mobile_lead TO easy_mobile_analytics_writer;
        GRANT UPDATE (status, note, updated_at)
            ON analytics.easy_mobile_lead TO easy_mobile_analytics_writer;
    END IF;
END
$grants$;

COMMIT;
