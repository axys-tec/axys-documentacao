-- Aquisição e mensuração do EasyMobile.
-- Não registra instalação por inferência: primeira abertura e primeira ação
-- só existem quando recebidas do aplicativo pelo endpoint autenticado.

CREATE TABLE IF NOT EXISTS analytics.easy_mobile_campaign_link (
    link_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    code TEXT NOT NULL,
    source_platform TEXT NOT NULL,
    campaign_code TEXT,
    creative_code TEXT,
    objective TEXT NOT NULL,
    destination TEXT NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    metadata_json JSONB NOT NULL DEFAULT '{}'::jsonb,
    created_by UUID,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT uq_easy_mobile_campaign_link_code UNIQUE (code),
    CONSTRAINT fk_easy_mobile_campaign_link_creator FOREIGN KEY (created_by)
        REFERENCES identity.hub_user (user_id) ON DELETE SET NULL,
    CONSTRAINT ck_easy_mobile_campaign_link_code CHECK (code ~ '^[a-z0-9][a-z0-9_-]{1,63}$'),
    CONSTRAINT ck_easy_mobile_campaign_link_objective CHECK (objective IN ('awareness','direct_acquisition')),
    CONSTRAINT ck_easy_mobile_campaign_link_destination CHECK (destination IN ('landing','auto_store','google_play','app_store')),
    CONSTRAINT ck_easy_mobile_campaign_link_awareness CHECK (objective <> 'awareness' OR destination = 'landing'),
    CONSTRAINT ck_easy_mobile_campaign_link_metadata CHECK (jsonb_typeof(metadata_json) = 'object')
);

CREATE INDEX IF NOT EXISTS idx_easy_mobile_campaign_link_active
    ON analytics.easy_mobile_campaign_link (is_active, source_platform, campaign_code);

CREATE TABLE IF NOT EXISTS analytics.easy_mobile_acquisition_event (
    event_id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
    ingestion_key UUID NOT NULL,
    link_id BIGINT,
    source_platform TEXT,
    campaign_code TEXT,
    creative_code TEXT,
    touch_id UUID NOT NULL,
    event_type TEXT NOT NULL,
    campaign_visitor_id UUID,
    visitor_id UUID,
    session_id UUID,
    page_view_id UUID,
    client_uuid UUID,
    detected_os TEXT,
    destination TEXT,
    store_platform TEXT,
    attribution_status TEXT NOT NULL DEFAULT 'unknown',
    utm_source TEXT,
    utm_medium TEXT,
    utm_campaign TEXT,
    utm_term TEXT,
    utm_content TEXT,
    gclid TEXT,
    gbraid TEXT,
    wbraid TEXT,
    is_bot BOOLEAN NOT NULL DEFAULT FALSE,
    is_preview BOOLEAN NOT NULL DEFAULT FALSE,
    metadata_json JSONB NOT NULL DEFAULT '{}'::jsonb,
    occurred_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT uq_easy_mobile_acquisition_ingestion UNIQUE (ingestion_key),
    CONSTRAINT fk_easy_mobile_acquisition_link FOREIGN KEY (link_id)
        REFERENCES analytics.easy_mobile_campaign_link (link_id) ON DELETE SET NULL,
    CONSTRAINT fk_easy_mobile_acquisition_visitor FOREIGN KEY (visitor_id)
        REFERENCES analytics.visitor (visitor_id) ON DELETE SET NULL,
    CONSTRAINT fk_easy_mobile_acquisition_session FOREIGN KEY (session_id)
        REFERENCES analytics.session (session_id) ON DELETE SET NULL,
    CONSTRAINT fk_easy_mobile_acquisition_page_view FOREIGN KEY (page_view_id)
        REFERENCES analytics.page_view (page_view_id) ON DELETE SET NULL,
    CONSTRAINT fk_easy_mobile_acquisition_client FOREIGN KEY (client_uuid)
        REFERENCES identity.client_easy_mobile (client_uuid) ON DELETE SET NULL,
    CONSTRAINT ck_easy_mobile_acquisition_event_type CHECK (event_type IN (
        'campaign_passage','landing_view','store_click','store_redirect',
        'first_app_open','first_relevant_action'
    )),
    CONSTRAINT ck_easy_mobile_acquisition_attribution CHECK (attribution_status IN ('confirmed','aggregated','modelled','unknown')),
    CONSTRAINT ck_easy_mobile_acquisition_store CHECK (store_platform IS NULL OR store_platform IN ('android','ios')),
    CONSTRAINT ck_easy_mobile_acquisition_metadata CHECK (jsonb_typeof(metadata_json) = 'object')
);

-- Mantém a migration reaplicável em ambientes que tenham recebido uma versão
-- de desenvolvimento anterior à inclusão dos snapshots da campanha.
ALTER TABLE analytics.easy_mobile_acquisition_event
    ADD COLUMN IF NOT EXISTS source_platform TEXT,
    ADD COLUMN IF NOT EXISTS campaign_code TEXT,
    ADD COLUMN IF NOT EXISTS creative_code TEXT;

CREATE INDEX IF NOT EXISTS idx_easy_mobile_acquisition_link_occurred
    ON analytics.easy_mobile_acquisition_event (link_id, occurred_at DESC);
CREATE INDEX IF NOT EXISTS idx_easy_mobile_acquisition_touch
    ON analytics.easy_mobile_acquisition_event (touch_id, occurred_at);
CREATE INDEX IF NOT EXISTS idx_easy_mobile_acquisition_event_occurred
    ON analytics.easy_mobile_acquisition_event (event_type, occurred_at DESC);
CREATE INDEX IF NOT EXISTS idx_easy_mobile_acquisition_confirmed_client
    ON analytics.easy_mobile_acquisition_event (client_uuid, event_type)
    WHERE client_uuid IS NOT NULL;

