BEGIN;

-- ============================================================
-- AxysHub — Analytics V1A DDL Test Script
-- Banco-alvo: PostgreSQL limpo com schema.sql já aplicado
-- Objetivo:
--   Validar exclusivamente o comportamento do DDL do domínio analytics.
-- Escopo:
--   - constraints
--   - foreign keys
--   - cascatas e restrições
--   - tipos e checks
-- Fora de escopo:
--   - FastAPI
--   - Analytics Worker
--   - migrations incrementais
-- Segurança:
--   Todo o ensaio roda dentro de transação e termina em ROLLBACK.
-- ============================================================

-- ============================================================
-- Preparação
-- ============================================================

-- Contexto fixo para o ensaio.
CREATE TEMP TABLE test_ctx (
    ctx_key     TEXT PRIMARY KEY,
    uuid_value  UUID,
    int_value   INTEGER,
    bigint_value BIGINT,
    text_value  TEXT
);

INSERT INTO test_ctx (ctx_key, uuid_value) VALUES
    ('visitor_main', '11111111-1111-1111-1111-111111111111'),
    ('visitor_delete', '11111111-1111-1111-1111-111111111112'),
    ('session_main', '22222222-2222-2222-2222-222222222221'),
    ('session_secondary', '22222222-2222-2222-2222-222222222222'),
    ('session_delete', '22222222-2222-2222-2222-222222222223'),
    ('page_view_main', '33333333-3333-3333-3333-333333333331'),
    ('page_view_secondary', '33333333-3333-3333-3333-333333333332'),
    ('page_view_delete', '33333333-3333-3333-3333-333333333333'),
    ('event_main', '44444444-4444-4444-4444-444444444441'),
    ('event_without_page', '44444444-4444-4444-4444-444444444442'),
    ('event_delete', '44444444-4444-4444-4444-444444444443'),
    ('ingestion_page_main', '55555555-5555-5555-5555-555555555551'),
    ('ingestion_page_secondary', '55555555-5555-5555-5555-555555555552'),
    ('ingestion_page_delete', '55555555-5555-5555-5555-555555555553'),
    ('ingestion_event_main', '66666666-6666-6666-6666-666666666661'),
    ('ingestion_event_without_page', '66666666-6666-6666-6666-666666666662'),
    ('ingestion_event_delete', '66666666-6666-6666-6666-666666666663');

INSERT INTO test_ctx (ctx_key, int_value)
SELECT 'product_existing', p.product_id
FROM product.product AS p
ORDER BY p.product_id
LIMIT 1;

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM test_ctx WHERE ctx_key = 'product_existing' AND int_value IS NOT NULL) THEN
        RAISE EXCEPTION 'TESTE BLOQUEADO: schema.sql precisa ter ao menos um product.product seedado';
    END IF;
END
$$;

-- ============================================================
-- 1. Provider config
-- ============================================================

-- Objetivo:
--   Validar inserção, unicidade, formato de JSON e ausência de segredo bruto.
-- Resultado esperado:
--   1 sucesso e falhas controladas para duplicidade e JSON inválido.

-- SUCEDER: inserção válida.
INSERT INTO analytics.provider_config (
    site_code,
    provider_code,
    provider_name,
    provider_type,
    status,
    measurement_id,
    secret_ref,
    config_json
) VALUES (
    'HUB_PUBLIC',
    'GA4',
    'Google Analytics 4',
    'analytics',
    'active',
    'G-TEST1234',
    'env:GA4_SECRET',
    '{"stream":"main","sample_rate":100}'::jsonb
);

-- Conferência: registro inserido e nenhuma coluna api_key presente.
SELECT provider_config_id, site_code, provider_code, provider_type, secret_ref
FROM analytics.provider_config
WHERE site_code = 'HUB_PUBLIC'
  AND provider_code = 'GA4';

SELECT column_name
FROM information_schema.columns
WHERE table_schema = 'analytics'
  AND table_name = 'provider_config'
ORDER BY ordinal_position;

-- FALHAR: duplicidade de (site_code, provider_code).
DO $$
BEGIN
    BEGIN
        INSERT INTO analytics.provider_config (
            site_code,
            provider_code,
            provider_name,
            provider_type,
            config_json
        ) VALUES (
            'HUB_PUBLIC',
            'GA4',
            'Google Analytics 4 Duplicate',
            'analytics',
            '{}'::jsonb
        );
        RAISE EXCEPTION 'TESTE FALHOU: duplicidade de provider_config deveria ser rejeitada';
    EXCEPTION
        WHEN unique_violation THEN
            RAISE NOTICE 'OK: uq_provider_config_site_provider rejeitou duplicidade';
    END;
END
$$;

-- FALHAR: config_json como array.
DO $$
BEGIN
    BEGIN
        INSERT INTO analytics.provider_config (
            site_code,
            provider_code,
            provider_name,
            provider_type,
            config_json
        ) VALUES (
            'HUB_PUBLIC',
            'GTM',
            'Google Tag Manager',
            'tag_manager',
            '[]'::jsonb
        );
        RAISE EXCEPTION 'TESTE FALHOU: array em config_json deveria ser rejeitado';
    EXCEPTION
        WHEN check_violation THEN
            RAISE NOTICE 'OK: ck_provider_config_json_object rejeitou array';
    END;
END
$$;

-- FALHAR: config_json como escalar.
DO $$
BEGIN
    BEGIN
        INSERT INTO analytics.provider_config (
            site_code,
            provider_code,
            provider_name,
            provider_type,
            config_json
        ) VALUES (
            'HUB_PUBLIC',
            'META_PIXEL',
            'Meta Pixel',
            'pixel',
            '"secret"'::jsonb
        );
        RAISE EXCEPTION 'TESTE FALHOU: escalar em config_json deveria ser rejeitado';
    EXCEPTION
        WHEN check_violation THEN
            RAISE NOTICE 'OK: ck_provider_config_json_object rejeitou escalar';
    END;
END
$$;

-- ============================================================
-- 2. Visitor
-- ============================================================

-- Objetivo:
--   Validar criação, reuso idempotente, checks temporais, path e códigos.

-- SUCEDER: inserção válida.
INSERT INTO analytics.visitor (
    visitor_id,
    site_code,
    first_seen_at,
    last_seen_at,
    first_referrer_url,
    first_landing_path,
    first_country_code,
    first_region_code,
    first_city,
    preferred_language
)
SELECT
    (SELECT uuid_value FROM test_ctx WHERE ctx_key = 'visitor_main'),
    'HUB_PUBLIC',
    TIMESTAMPTZ '2026-07-17 10:00:00+00',
    TIMESTAMPTZ '2026-07-17 10:05:00+00',
    'https://google.com',
    '/',
    'BR',
    'SP',
    'Sao Paulo',
    'pt-BR';

-- SUCEDER: reuso idempotente do mesmo visitor_id sem segundo registro.
INSERT INTO analytics.visitor (
    visitor_id,
    site_code,
    first_seen_at,
    last_seen_at,
    first_landing_path,
    first_country_code
)
SELECT
    (SELECT uuid_value FROM test_ctx WHERE ctx_key = 'visitor_main'),
    'HUB_PUBLIC',
    TIMESTAMPTZ '2026-07-17 10:00:00+00',
    TIMESTAMPTZ '2026-07-17 10:10:00+00',
    '/',
    'BR'
ON CONFLICT (visitor_id) DO UPDATE
SET last_seen_at = EXCLUDED.last_seen_at,
    updated_at = now();

-- Conferência: continua existindo um único visitor_id.
SELECT visitor_id, site_code, first_seen_at, last_seen_at
FROM analytics.visitor
WHERE visitor_id = (SELECT uuid_value FROM test_ctx WHERE ctx_key = 'visitor_main');

SELECT COUNT(*) AS visitor_main_count
FROM analytics.visitor
WHERE visitor_id = (SELECT uuid_value FROM test_ctx WHERE ctx_key = 'visitor_main');

-- SUCEDER: visitor adicional para testes de cascata.
INSERT INTO analytics.visitor (
    visitor_id,
    site_code,
    first_seen_at,
    last_seen_at,
    first_landing_path,
    first_country_code
)
SELECT
    (SELECT uuid_value FROM test_ctx WHERE ctx_key = 'visitor_delete'),
    'HUB_PUBLIC',
    TIMESTAMPTZ '2026-07-17 12:00:00+00',
    TIMESTAMPTZ '2026-07-17 12:00:00+00',
    '/delete-flow',
    'BR';

-- FALHAR: last_seen_at < first_seen_at.
DO $$
BEGIN
    BEGIN
        INSERT INTO analytics.visitor (
            site_code,
            first_seen_at,
            last_seen_at
        ) VALUES (
            'HUB_PUBLIC',
            TIMESTAMPTZ '2026-07-17 11:00:00+00',
            TIMESTAMPTZ '2026-07-17 10:59:59+00'
        );
        RAISE EXCEPTION 'TESTE FALHOU: ordem temporal inválida em visitor deveria ser rejeitada';
    EXCEPTION
        WHEN check_violation THEN
            RAISE NOTICE 'OK: ck_analytics_visitor_seen_order rejeitou ordem temporal inválida';
    END;
END
$$;

-- FALHAR: site_code inválido.
DO $$
BEGIN
    BEGIN
        INSERT INTO analytics.visitor (site_code) VALUES ('hub-public');
        RAISE EXCEPTION 'TESTE FALHOU: site_code inválido deveria ser rejeitado';
    EXCEPTION
        WHEN check_violation THEN
            RAISE NOTICE 'OK: ck_analytics_visitor_site_code rejeitou site_code inválido';
    END;
END
$$;

-- FALHAR: first_landing_path inválido.
DO $$
BEGIN
    BEGIN
        INSERT INTO analytics.visitor (
            site_code,
            first_landing_path
        ) VALUES (
            'HUB_PUBLIC',
            'landing-sem-barra'
        );
        RAISE EXCEPTION 'TESTE FALHOU: first_landing_path inválido deveria ser rejeitado';
    EXCEPTION
        WHEN check_violation THEN
            RAISE NOTICE 'OK: ck_analytics_visitor_landing_path rejeitou path inválido';
    END;
END
$$;

-- SUCEDER: país válido.
INSERT INTO analytics.visitor (
    site_code,
    first_country_code
) VALUES (
    'HUB_PUBLIC',
    'BRA'
);

-- FALHAR: país inválido.
DO $$
BEGIN
    BEGIN
        INSERT INTO analytics.visitor (
            site_code,
            first_country_code
        ) VALUES (
            'HUB_PUBLIC',
            'BRASIL'
        );
        RAISE EXCEPTION 'TESTE FALHOU: first_country_code inválido deveria ser rejeitado';
    EXCEPTION
        WHEN check_violation THEN
            RAISE NOTICE 'OK: ck_analytics_visitor_country_code rejeitou código inválido';
    END;
END
$$;

-- ============================================================
-- 3. Session
-- ============================================================

-- Objetivo:
--   Validar contexto temporal, FKs, consolidação e checks de device/tela.

-- SUCEDER: criação válida.
INSERT INTO analytics.session (
    session_id,
    visitor_id,
    started_at,
    last_activity_at,
    ended_at,
    duration_ms,
    exit_path,
    device_type,
    browser_family,
    os_family,
    screen_width,
    screen_height,
    timezone,
    country_code,
    region_code,
    city,
    referrer_url,
    utm_source,
    utm_medium,
    utm_campaign,
    utm_term,
    utm_content,
    landing_path
)
SELECT
    (SELECT uuid_value FROM test_ctx WHERE ctx_key = 'session_main'),
    (SELECT uuid_value FROM test_ctx WHERE ctx_key = 'visitor_main'),
    TIMESTAMPTZ '2026-07-17 10:00:00+00',
    TIMESTAMPTZ '2026-07-17 10:15:00+00',
    TIMESTAMPTZ '2026-07-17 10:15:00+00',
    900000,
    '/pricing',
    'desktop',
    'Chrome',
    'macOS',
    1440,
    900,
    'America/Sao_Paulo',
    'BR',
    'SP',
    'Sao Paulo',
    'https://google.com',
    'google',
    'cpc',
    'brand',
    'axys',
    'hero',
    '/'
;

-- SUCEDER: segunda sessão para teste de sequence_no repetido em outra sessão.
INSERT INTO analytics.session (
    session_id,
    visitor_id,
    started_at,
    last_activity_at,
    landing_path
)
SELECT
    (SELECT uuid_value FROM test_ctx WHERE ctx_key = 'session_secondary'),
    (SELECT uuid_value FROM test_ctx WHERE ctx_key = 'visitor_main'),
    TIMESTAMPTZ '2026-07-17 11:00:00+00',
    TIMESTAMPTZ '2026-07-17 11:01:00+00',
    '/combo';

-- SUCEDER: sessão para testes de deleção em cascata.
INSERT INTO analytics.session (
    session_id,
    visitor_id,
    started_at,
    last_activity_at,
    landing_path
)
SELECT
    (SELECT uuid_value FROM test_ctx WHERE ctx_key = 'session_delete'),
    (SELECT uuid_value FROM test_ctx WHERE ctx_key = 'visitor_delete'),
    TIMESTAMPTZ '2026-07-17 12:00:00+00',
    TIMESTAMPTZ '2026-07-17 12:05:00+00',
    '/delete-flow';

-- Conferência.
SELECT session_id, visitor_id, started_at, last_activity_at, ended_at, duration_ms
FROM analytics.session
WHERE session_id IN (
    (SELECT uuid_value FROM test_ctx WHERE ctx_key = 'session_main'),
    (SELECT uuid_value FROM test_ctx WHERE ctx_key = 'session_secondary'),
    (SELECT uuid_value FROM test_ctx WHERE ctx_key = 'session_delete')
)
ORDER BY started_at;

-- FALHAR: FK para visitor inexistente.
DO $$
BEGIN
    BEGIN
        INSERT INTO analytics.session (
            visitor_id,
            started_at,
            last_activity_at
        ) VALUES (
            'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
            now(),
            now()
        );
        RAISE EXCEPTION 'TESTE FALHOU: session com visitor inexistente deveria ser rejeitada';
    EXCEPTION
        WHEN foreign_key_violation THEN
            RAISE NOTICE 'OK: fk_analytics_session_visitor rejeitou visitor inexistente';
    END;
END
$$;

-- FALHAR: last_activity_at < started_at.
DO $$
BEGIN
    BEGIN
        INSERT INTO analytics.session (
            visitor_id,
            started_at,
            last_activity_at
        ) VALUES (
            (SELECT uuid_value FROM test_ctx WHERE ctx_key = 'visitor_main'),
            TIMESTAMPTZ '2026-07-17 14:00:00+00',
            TIMESTAMPTZ '2026-07-17 13:59:59+00'
        );
        RAISE EXCEPTION 'TESTE FALHOU: last_activity_at < started_at deveria ser rejeitado';
    EXCEPTION
        WHEN check_violation THEN
            RAISE NOTICE 'OK: ck_analytics_session_activity_order rejeitou atividade inválida';
    END;
END
$$;

-- SUCEDER: ended_at = last_activity_at.
INSERT INTO analytics.session (
    visitor_id,
    started_at,
    last_activity_at,
    ended_at,
    duration_ms,
    landing_path
) VALUES (
    (SELECT uuid_value FROM test_ctx WHERE ctx_key = 'visitor_main'),
    TIMESTAMPTZ '2026-07-17 15:00:00+00',
    TIMESTAMPTZ '2026-07-17 15:05:00+00',
    TIMESTAMPTZ '2026-07-17 15:05:00+00',
    300000,
    '/worker-close'
);

-- FALHAR: ended_at diferente de last_activity_at.
DO $$
BEGIN
    BEGIN
        INSERT INTO analytics.session (
            visitor_id,
            started_at,
            last_activity_at,
            ended_at,
            landing_path
        ) VALUES (
            (SELECT uuid_value FROM test_ctx WHERE ctx_key = 'visitor_main'),
            TIMESTAMPTZ '2026-07-17 16:00:00+00',
            TIMESTAMPTZ '2026-07-17 16:05:00+00',
            TIMESTAMPTZ '2026-07-17 16:06:00+00',
            '/invalid-close'
        );
        RAISE EXCEPTION 'TESTE FALHOU: ended_at diferente de last_activity_at deveria ser rejeitado';
    EXCEPTION
        WHEN check_violation THEN
            RAISE NOTICE 'OK: ck_analytics_session_end_activity rejeitou fechamento divergente';
    END;
END
$$;

-- FALHAR: duration_ms sem ended_at.
DO $$
BEGIN
    BEGIN
        INSERT INTO analytics.session (
            visitor_id,
            started_at,
            last_activity_at,
            duration_ms,
            landing_path
        ) VALUES (
            (SELECT uuid_value FROM test_ctx WHERE ctx_key = 'visitor_main'),
            TIMESTAMPTZ '2026-07-17 17:00:00+00',
            TIMESTAMPTZ '2026-07-17 17:02:00+00',
            120000,
            '/duration-without-end'
        );
        RAISE EXCEPTION 'TESTE FALHOU: duration_ms sem ended_at deveria ser rejeitado';
    EXCEPTION
        WHEN check_violation THEN
            RAISE NOTICE 'OK: ck_analytics_session_duration_end rejeitou duração sem encerramento';
    END;
END
$$;

-- FALHAR: duração negativa.
DO $$
BEGIN
    BEGIN
        INSERT INTO analytics.session (
            visitor_id,
            started_at,
            last_activity_at,
            ended_at,
            duration_ms,
            landing_path
        ) VALUES (
            (SELECT uuid_value FROM test_ctx WHERE ctx_key = 'visitor_main'),
            TIMESTAMPTZ '2026-07-17 18:00:00+00',
            TIMESTAMPTZ '2026-07-17 18:01:00+00',
            TIMESTAMPTZ '2026-07-17 18:01:00+00',
            -1,
            '/negative-duration'
        );
        RAISE EXCEPTION 'TESTE FALHOU: duração negativa deveria ser rejeitada';
    EXCEPTION
        WHEN check_violation THEN
            RAISE NOTICE 'OK: ck_analytics_session_duration rejeitou duração negativa';
    END;
END
$$;

-- FALHAR: dimensões de tela inválidas.
DO $$
BEGIN
    BEGIN
        INSERT INTO analytics.session (
            visitor_id,
            started_at,
            last_activity_at,
            screen_width,
            screen_height,
            landing_path
        ) VALUES (
            (SELECT uuid_value FROM test_ctx WHERE ctx_key = 'visitor_main'),
            TIMESTAMPTZ '2026-07-17 19:00:00+00',
            TIMESTAMPTZ '2026-07-17 19:01:00+00',
            0,
            -1,
            '/invalid-screen'
        );
        RAISE EXCEPTION 'TESTE FALHOU: dimensões inválidas deveriam ser rejeitadas';
    EXCEPTION
        WHEN check_violation THEN
            RAISE NOTICE 'OK: checks de screen_width/screen_height rejeitaram dimensões inválidas';
    END;
END
$$;

-- FALHAR: device_type inválido.
DO $$
BEGIN
    BEGIN
        INSERT INTO analytics.session (
            visitor_id,
            started_at,
            last_activity_at,
            device_type,
            landing_path
        ) VALUES (
            (SELECT uuid_value FROM test_ctx WHERE ctx_key = 'visitor_main'),
            TIMESTAMPTZ '2026-07-17 20:00:00+00',
            TIMESTAMPTZ '2026-07-17 20:01:00+00',
            'smarttv',
            '/invalid-device'
        );
        RAISE EXCEPTION 'TESTE FALHOU: device_type inválido deveria ser rejeitado';
    EXCEPTION
        WHEN check_violation THEN
            RAISE NOTICE 'OK: ck_analytics_session_device_type rejeitou device_type inválido';
    END;
END
$$;

-- ============================================================
-- 4. Page view
-- ============================================================

-- Objetivo:
--   Validar fato bruto, idempotência por ingestion_key, sequência e FKs.

-- SUCEDER: inserção válida.
INSERT INTO analytics.page_view (
    page_view_id,
    session_id,
    ingestion_key,
    sequence_no,
    page_path,
    page_title,
    page_type,
    product_id,
    dwell_ms,
    referrer_path,
    viewed_at
)
SELECT
    (SELECT uuid_value FROM test_ctx WHERE ctx_key = 'page_view_main'),
    (SELECT uuid_value FROM test_ctx WHERE ctx_key = 'session_main'),
    (SELECT uuid_value FROM test_ctx WHERE ctx_key = 'ingestion_page_main'),
    1,
    '/',
    'Home',
    'landing',
    (SELECT int_value FROM test_ctx WHERE ctx_key = 'product_existing'),
    45000,
    NULL,
    TIMESTAMPTZ '2026-07-17 10:00:10+00';

-- SUCEDER: mesmo sequence_no em sessão diferente.
INSERT INTO analytics.page_view (
    page_view_id,
    session_id,
    ingestion_key,
    sequence_no,
    page_path,
    page_title,
    viewed_at
)
SELECT
    (SELECT uuid_value FROM test_ctx WHERE ctx_key = 'page_view_secondary'),
    (SELECT uuid_value FROM test_ctx WHERE ctx_key = 'session_secondary'),
    (SELECT uuid_value FROM test_ctx WHERE ctx_key = 'ingestion_page_secondary'),
    1,
    '/combo',
    'Combo',
    TIMESTAMPTZ '2026-07-17 11:00:10+00';

-- SUCEDER: page_view para fluxo de deleção.
INSERT INTO analytics.page_view (
    page_view_id,
    session_id,
    ingestion_key,
    sequence_no,
    page_path,
    page_title,
    viewed_at
)
SELECT
    (SELECT uuid_value FROM test_ctx WHERE ctx_key = 'page_view_delete'),
    (SELECT uuid_value FROM test_ctx WHERE ctx_key = 'session_delete'),
    (SELECT uuid_value FROM test_ctx WHERE ctx_key = 'ingestion_page_delete'),
    1,
    '/delete-flow',
    'Delete Flow',
    TIMESTAMPTZ '2026-07-17 12:00:10+00';

-- Conferência.
SELECT page_view_id, session_id, sequence_no, page_path, product_id
FROM analytics.page_view
WHERE page_view_id IN (
    (SELECT uuid_value FROM test_ctx WHERE ctx_key = 'page_view_main'),
    (SELECT uuid_value FROM test_ctx WHERE ctx_key = 'page_view_secondary'),
    (SELECT uuid_value FROM test_ctx WHERE ctx_key = 'page_view_delete')
)
ORDER BY viewed_at;

-- FALHAR: ingestion_key duplicada.
DO $$
BEGIN
    BEGIN
        INSERT INTO analytics.page_view (
            session_id,
            ingestion_key,
            sequence_no,
            page_path
        ) VALUES (
            (SELECT uuid_value FROM test_ctx WHERE ctx_key = 'session_main'),
            (SELECT uuid_value FROM test_ctx WHERE ctx_key = 'ingestion_page_main'),
            2,
            '/duplicate-ingestion'
        );
        RAISE EXCEPTION 'TESTE FALHOU: ingestion_key duplicada deveria ser rejeitada em page_view';
    EXCEPTION
        WHEN unique_violation THEN
            RAISE NOTICE 'OK: uq_analytics_page_view_ingestion rejeitou duplicidade';
    END;
END
$$;

-- FALHAR: sequence_no repetido na mesma sessão.
DO $$
BEGIN
    BEGIN
        INSERT INTO analytics.page_view (
            session_id,
            ingestion_key,
            sequence_no,
            page_path
        ) VALUES (
            (SELECT uuid_value FROM test_ctx WHERE ctx_key = 'session_main'),
            '55555555-5555-5555-5555-555555555559',
            1,
            '/duplicate-sequence'
        );
        RAISE EXCEPTION 'TESTE FALHOU: sequence_no repetido na mesma sessão deveria ser rejeitado';
    EXCEPTION
        WHEN unique_violation THEN
            RAISE NOTICE 'OK: uq_analytics_page_view_session_sequence rejeitou repetição na mesma sessão';
    END;
END
$$;

-- FALHAR: sequência menor que 1.
DO $$
BEGIN
    BEGIN
        INSERT INTO analytics.page_view (
            session_id,
            ingestion_key,
            sequence_no,
            page_path
        ) VALUES (
            (SELECT uuid_value FROM test_ctx WHERE ctx_key = 'session_main'),
            '55555555-5555-5555-5555-555555555560',
            0,
            '/invalid-sequence'
        );
        RAISE EXCEPTION 'TESTE FALHOU: sequence_no < 1 deveria ser rejeitado';
    EXCEPTION
        WHEN check_violation THEN
            RAISE NOTICE 'OK: ck_analytics_page_view_sequence rejeitou sequência inválida';
    END;
END
$$;

-- FALHAR: path inválido.
DO $$
BEGIN
    BEGIN
        INSERT INTO analytics.page_view (
            session_id,
            ingestion_key,
            sequence_no,
            page_path
        ) VALUES (
            (SELECT uuid_value FROM test_ctx WHERE ctx_key = 'session_main'),
            '55555555-5555-5555-5555-555555555561',
            2,
            'pricing'
        );
        RAISE EXCEPTION 'TESTE FALHOU: page_path inválido deveria ser rejeitado';
    EXCEPTION
        WHEN check_violation THEN
            RAISE NOTICE 'OK: ck_analytics_page_view_page_path rejeitou path inválido';
    END;
END
$$;

-- FALHAR: dwell_ms negativo.
DO $$
BEGIN
    BEGIN
        INSERT INTO analytics.page_view (
            session_id,
            ingestion_key,
            sequence_no,
            page_path,
            dwell_ms
        ) VALUES (
            (SELECT uuid_value FROM test_ctx WHERE ctx_key = 'session_main'),
            '55555555-5555-5555-5555-555555555562',
            2,
            '/negative-dwell',
            -1
        );
        RAISE EXCEPTION 'TESTE FALHOU: dwell_ms negativo deveria ser rejeitado';
    EXCEPTION
        WHEN check_violation THEN
            RAISE NOTICE 'OK: ck_analytics_page_view_dwell rejeitou dwell_ms negativo';
    END;
END
$$;

-- SUCEDER: product_id válido em nova page view.
INSERT INTO analytics.page_view (
    session_id,
    ingestion_key,
    sequence_no,
    page_path,
    product_id
) VALUES (
    (SELECT uuid_value FROM test_ctx WHERE ctx_key = 'session_main'),
    '55555555-5555-5555-5555-555555555563',
    2,
    '/easy',
    (SELECT int_value FROM test_ctx WHERE ctx_key = 'product_existing')
);

-- FALHAR: product_id inexistente.
DO $$
BEGIN
    BEGIN
        INSERT INTO analytics.page_view (
            session_id,
            ingestion_key,
            sequence_no,
            page_path,
            product_id
        ) VALUES (
            (SELECT uuid_value FROM test_ctx WHERE ctx_key = 'session_main'),
            '55555555-5555-5555-5555-555555555564',
            3,
            '/ghost-product',
            999999999
        );
        RAISE EXCEPTION 'TESTE FALHOU: product_id inexistente deveria ser rejeitado';
    EXCEPTION
        WHEN foreign_key_violation THEN
            RAISE NOTICE 'OK: fk_analytics_page_view_product rejeitou product_id inexistente';
    END;
END
$$;

-- FALHAR: sessão inexistente.
DO $$
BEGIN
    BEGIN
        INSERT INTO analytics.page_view (
            session_id,
            ingestion_key,
            sequence_no,
            page_path
        ) VALUES (
            'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb',
            '55555555-5555-5555-5555-555555555565',
            1,
            '/missing-session'
        );
        RAISE EXCEPTION 'TESTE FALHOU: page_view com sessão inexistente deveria ser rejeitada';
    EXCEPTION
        WHEN foreign_key_violation THEN
            RAISE NOTICE 'OK: fk_analytics_page_view_session rejeitou sessão inexistente';
    END;
END
$$;

-- ============================================================
-- 5. Event type
-- ============================================================

-- Objetivo:
--   Validar catálogo semântico, PK gerada e governança de versão/payload.

-- SUCEDER: inserção válida sem fornecer event_type_id.
INSERT INTO analytics.event_type (
    event_code,
    event_version,
    event_name,
    category,
    scope,
    description,
    is_public,
    is_enabled,
    is_scoreable,
    payload_schema_json,
    valid_from
) VALUES (
    'pricing_open',
    1,
    'Pricing Open',
    'discovery',
    'site_public',
    'Visitante abriu a área de preços.',
    TRUE,
    TRUE,
    TRUE,
    '{"type":"object","properties":{"plan_code":{"type":"string"}}}'::jsonb,
    TIMESTAMPTZ '2026-07-17 00:00:00+00'
)
RETURNING event_type_id;

INSERT INTO test_ctx (ctx_key, bigint_value)
SELECT 'event_type_pricing_v1', event_type_id
FROM analytics.event_type
WHERE event_code = 'pricing_open'
  AND event_version = 1;

-- SUCEDER: mesma event_code em versão diferente.
INSERT INTO analytics.event_type (
    event_code,
    event_version,
    event_name,
    category,
    scope,
    description,
    payload_schema_json,
    valid_from
) VALUES (
    'pricing_open',
    2,
    'Pricing Open V2',
    'discovery',
    'site_public',
    'Visitante abriu a área de preços com nova semântica.',
    '{"type":"object","properties":{"plan_code":{"type":"string"},"variant":{"type":"string"}}}'::jsonb,
    TIMESTAMPTZ '2026-08-01 00:00:00+00'
);

INSERT INTO analytics.event_type (
    event_code,
    event_version,
    event_name,
    category,
    scope,
    description,
    payload_schema_json,
    valid_from
) VALUES (
    'cta_click',
    1,
    'CTA Click',
    'conversion',
    'site_public',
    'Visitante clicou em CTA principal.',
    '{"type":"object","properties":{"target":{"type":"string"}}}'::jsonb,
    TIMESTAMPTZ '2026-07-17 00:00:00+00'
);

INSERT INTO test_ctx (ctx_key, bigint_value)
SELECT 'event_type_cta_v1', event_type_id
FROM analytics.event_type
WHERE event_code = 'cta_click'
  AND event_version = 1;

-- Conferência: PK gerada automaticamente.
SELECT event_type_id, event_code, event_version, category, scope
FROM analytics.event_type
WHERE event_code IN ('pricing_open', 'cta_click')
ORDER BY event_code, event_version;

-- FALHAR: duplicidade de (event_code, event_version).
DO $$
BEGIN
    BEGIN
        INSERT INTO analytics.event_type (
            event_code,
            event_version,
            category,
            scope,
            description,
            payload_schema_json
        ) VALUES (
            'pricing_open',
            1,
            'discovery',
            'site_public',
            'Duplicado',
            '{}'::jsonb
        );
        RAISE EXCEPTION 'TESTE FALHOU: duplicidade de event_code/event_version deveria ser rejeitada';
    EXCEPTION
        WHEN unique_violation THEN
            RAISE NOTICE 'OK: uq_analytics_event_type_code_version rejeitou duplicidade';
    END;
END
$$;

-- FALHAR: versão menor que 1.
DO $$
BEGIN
    BEGIN
        INSERT INTO analytics.event_type (
            event_code,
            event_version,
            category,
            scope,
            description,
            payload_schema_json
        ) VALUES (
            'invalid_version',
            0,
            'system',
            'other',
            'Versão inválida',
            '{}'::jsonb
        );
        RAISE EXCEPTION 'TESTE FALHOU: event_version < 1 deveria ser rejeitado';
    EXCEPTION
        WHEN check_violation THEN
            RAISE NOTICE 'OK: ck_analytics_event_type_version rejeitou versão inválida';
    END;
END
$$;

-- FALHAR: category inválida.
DO $$
BEGIN
    BEGIN
        INSERT INTO analytics.event_type (
            event_code,
            event_version,
            category,
            scope,
            description,
            payload_schema_json
        ) VALUES (
            'invalid_category',
            1,
            'sales',
            'site_public',
            'Categoria inválida',
            '{}'::jsonb
        );
        RAISE EXCEPTION 'TESTE FALHOU: category inválida deveria ser rejeitada';
    EXCEPTION
        WHEN check_violation THEN
            RAISE NOTICE 'OK: ck_analytics_event_type_category rejeitou category inválida';
    END;
END
$$;

-- FALHAR: scope inválido.
DO $$
BEGIN
    BEGIN
        INSERT INTO analytics.event_type (
            event_code,
            event_version,
            category,
            scope,
            description,
            payload_schema_json
        ) VALUES (
            'invalid_scope',
            1,
            'system',
            'mobile_app',
            'Scope inválido',
            '{}'::jsonb
        );
        RAISE EXCEPTION 'TESTE FALHOU: scope inválido deveria ser rejeitado';
    EXCEPTION
        WHEN check_violation THEN
            RAISE NOTICE 'OK: ck_analytics_event_type_scope rejeitou scope inválido';
    END;
END
$$;

-- FALHAR: descrição vazia.
DO $$
BEGIN
    BEGIN
        INSERT INTO analytics.event_type (
            event_code,
            event_version,
            category,
            scope,
            description,
            payload_schema_json
        ) VALUES (
            'empty_description',
            1,
            'system',
            'other',
            '   ',
            '{}'::jsonb
        );
        RAISE EXCEPTION 'TESTE FALHOU: descrição vazia deveria ser rejeitada';
    EXCEPTION
        WHEN check_violation THEN
            RAISE NOTICE 'OK: ck_analytics_event_type_description_notempty rejeitou descrição vazia';
    END;
END
$$;

-- SUCEDER: payload_schema_json como objeto.
INSERT INTO analytics.event_type (
    event_code,
    event_version,
    category,
    scope,
    description,
    payload_schema_json
) VALUES (
    'faq_expand',
    1,
    'engagement',
    'site_public',
    'Visitante expandiu item de FAQ.',
    '{"type":"object","properties":{"question":{"type":"string"}}}'::jsonb
);

-- FALHAR: payload_schema_json como array.
DO $$
BEGIN
    BEGIN
        INSERT INTO analytics.event_type (
            event_code,
            event_version,
            category,
            scope,
            description,
            payload_schema_json
        ) VALUES (
            'payload_array',
            1,
            'system',
            'other',
            'Payload inválido',
            '[]'::jsonb
        );
        RAISE EXCEPTION 'TESTE FALHOU: payload_schema_json array deveria ser rejeitado';
    EXCEPTION
        WHEN check_violation THEN
            RAISE NOTICE 'OK: ck_analytics_event_type_payload_json_object rejeitou array';
    END;
END
$$;

-- FALHAR: payload_schema_json como escalar.
DO $$
BEGIN
    BEGIN
        INSERT INTO analytics.event_type (
            event_code,
            event_version,
            category,
            scope,
            description,
            payload_schema_json
        ) VALUES (
            'payload_scalar',
            1,
            'system',
            'other',
            'Payload inválido',
            '1'::jsonb
        );
        RAISE EXCEPTION 'TESTE FALHOU: payload_schema_json escalar deveria ser rejeitado';
    EXCEPTION
        WHEN check_violation THEN
            RAISE NOTICE 'OK: ck_analytics_event_type_payload_json_object rejeitou escalar';
    END;
END
$$;

-- FALHAR: intervalo temporal inválido.
DO $$
BEGIN
    BEGIN
        INSERT INTO analytics.event_type (
            event_code,
            event_version,
            category,
            scope,
            description,
            payload_schema_json,
            valid_from,
            valid_until
        ) VALUES (
            'invalid_range',
            1,
            'system',
            'other',
            'Intervalo inválido',
            '{}'::jsonb,
            TIMESTAMPTZ '2026-07-17 12:00:00+00',
            TIMESTAMPTZ '2026-07-17 11:59:59+00'
        );
        RAISE EXCEPTION 'TESTE FALHOU: valid_until < valid_from deveria ser rejeitado';
    EXCEPTION
        WHEN check_violation THEN
            RAISE NOTICE 'OK: ck_analytics_event_type_valid_range rejeitou intervalo inválido';
    END;
END
$$;

-- ============================================================
-- 6. Event
-- ============================================================

-- Objetivo:
--   Validar evento bruto, vínculo opcional com page_view e integridade composta.

-- SUCEDER: inserção válida ligada à sessão e à page_view da mesma sessão.
INSERT INTO analytics.event (
    event_id,
    session_id,
    page_view_id,
    ingestion_key,
    event_type_id,
    component,
    product_id,
    feature_code,
    value_numeric,
    metadata_json,
    occurred_at
)
SELECT
    (SELECT uuid_value FROM test_ctx WHERE ctx_key = 'event_main'),
    (SELECT uuid_value FROM test_ctx WHERE ctx_key = 'session_main'),
    (SELECT uuid_value FROM test_ctx WHERE ctx_key = 'page_view_main'),
    (SELECT uuid_value FROM test_ctx WHERE ctx_key = 'ingestion_event_main'),
    (SELECT bigint_value FROM test_ctx WHERE ctx_key = 'event_type_pricing_v1'),
    'pricing_modal',
    (SELECT int_value FROM test_ctx WHERE ctx_key = 'product_existing'),
    'pricing',
    1,
    '{"plan_code":"starter"}'::jsonb,
    TIMESTAMPTZ '2026-07-17 10:01:00+00';

-- SUCEDER: evento sem page_view.
INSERT INTO analytics.event (
    event_id,
    session_id,
    page_view_id,
    ingestion_key,
    event_type_id,
    component,
    metadata_json,
    occurred_at
)
SELECT
    (SELECT uuid_value FROM test_ctx WHERE ctx_key = 'event_without_page'),
    (SELECT uuid_value FROM test_ctx WHERE ctx_key = 'session_main'),
    NULL,
    (SELECT uuid_value FROM test_ctx WHERE ctx_key = 'ingestion_event_without_page'),
    (SELECT bigint_value FROM test_ctx WHERE ctx_key = 'event_type_cta_v1'),
    'hero_cta',
    '{"target":"signup"}'::jsonb,
    TIMESTAMPTZ '2026-07-17 10:02:00+00';

-- SUCEDER: evento para fluxo de deleção.
INSERT INTO analytics.event (
    event_id,
    session_id,
    page_view_id,
    ingestion_key,
    event_type_id,
    component,
    metadata_json,
    occurred_at
)
SELECT
    (SELECT uuid_value FROM test_ctx WHERE ctx_key = 'event_delete'),
    (SELECT uuid_value FROM test_ctx WHERE ctx_key = 'session_delete'),
    (SELECT uuid_value FROM test_ctx WHERE ctx_key = 'page_view_delete'),
    (SELECT uuid_value FROM test_ctx WHERE ctx_key = 'ingestion_event_delete'),
    (SELECT bigint_value FROM test_ctx WHERE ctx_key = 'event_type_cta_v1'),
    'delete_cta',
    '{"target":"contact"}'::jsonb,
    TIMESTAMPTZ '2026-07-17 12:01:00+00';

-- Conferência.
SELECT event_id, session_id, page_view_id, event_type_id, product_id, metadata_json
FROM analytics.event
WHERE event_id IN (
    (SELECT uuid_value FROM test_ctx WHERE ctx_key = 'event_main'),
    (SELECT uuid_value FROM test_ctx WHERE ctx_key = 'event_without_page'),
    (SELECT uuid_value FROM test_ctx WHERE ctx_key = 'event_delete')
)
ORDER BY occurred_at;

-- FALHAR: ingestion_key duplicada.
DO $$
BEGIN
    BEGIN
        INSERT INTO analytics.event (
            session_id,
            ingestion_key,
            event_type_id
        ) VALUES (
            (SELECT uuid_value FROM test_ctx WHERE ctx_key = 'session_main'),
            (SELECT uuid_value FROM test_ctx WHERE ctx_key = 'ingestion_event_main'),
            (SELECT bigint_value FROM test_ctx WHERE ctx_key = 'event_type_pricing_v1')
        );
        RAISE EXCEPTION 'TESTE FALHOU: ingestion_key duplicada deveria ser rejeitada em event';
    EXCEPTION
        WHEN unique_violation THEN
            RAISE NOTICE 'OK: uq_analytics_event_ingestion rejeitou duplicidade';
    END;
END
$$;

-- FALHAR: event_type inexistente.
DO $$
BEGIN
    BEGIN
        INSERT INTO analytics.event (
            session_id,
            ingestion_key,
            event_type_id
        ) VALUES (
            (SELECT uuid_value FROM test_ctx WHERE ctx_key = 'session_main'),
            '66666666-6666-6666-6666-666666666669',
            999999999
        );
        RAISE EXCEPTION 'TESTE FALHOU: event_type inexistente deveria ser rejeitado';
    EXCEPTION
        WHEN foreign_key_violation THEN
            RAISE NOTICE 'OK: fk_analytics_event_type rejeitou event_type inexistente';
    END;
END
$$;

-- FALHAR: session inexistente.
DO $$
BEGIN
    BEGIN
        INSERT INTO analytics.event (
            session_id,
            ingestion_key,
            event_type_id
        ) VALUES (
            'cccccccc-cccc-cccc-cccc-cccccccccccc',
            '66666666-6666-6666-6666-666666666670',
            (SELECT bigint_value FROM test_ctx WHERE ctx_key = 'event_type_pricing_v1')
        );
        RAISE EXCEPTION 'TESTE FALHOU: event com session inexistente deveria ser rejeitado';
    EXCEPTION
        WHEN foreign_key_violation THEN
            RAISE NOTICE 'OK: fk_analytics_event_session rejeitou session inexistente';
    END;
END
$$;

-- FALHAR: page_view pertencente a outra sessão.
DO $$
BEGIN
    BEGIN
        INSERT INTO analytics.event (
            session_id,
            page_view_id,
            ingestion_key,
            event_type_id
        ) VALUES (
            (SELECT uuid_value FROM test_ctx WHERE ctx_key = 'session_main'),
            (SELECT uuid_value FROM test_ctx WHERE ctx_key = 'page_view_secondary'),
            '66666666-6666-6666-6666-666666666671',
            (SELECT bigint_value FROM test_ctx WHERE ctx_key = 'event_type_pricing_v1')
        );
        RAISE EXCEPTION 'TESTE FALHOU: event com page_view de outra sessão deveria ser rejeitado';
    EXCEPTION
        WHEN foreign_key_violation THEN
            RAISE NOTICE 'OK: fk_analytics_event_page_view_session rejeitou page_view de outra sessão';
    END;
END
$$;

-- SUCEDER: metadata_json como objeto.
INSERT INTO analytics.event (
    session_id,
    ingestion_key,
    event_type_id,
    metadata_json
) VALUES (
    (SELECT uuid_value FROM test_ctx WHERE ctx_key = 'session_main'),
    '66666666-6666-6666-6666-666666666672',
    (SELECT bigint_value FROM test_ctx WHERE ctx_key = 'event_type_cta_v1'),
    '{"target":"contact_form","position":"footer"}'::jsonb
);

-- FALHAR: metadata_json como array.
DO $$
BEGIN
    BEGIN
        INSERT INTO analytics.event (
            session_id,
            ingestion_key,
            event_type_id,
            metadata_json
        ) VALUES (
            (SELECT uuid_value FROM test_ctx WHERE ctx_key = 'session_main'),
            '66666666-6666-6666-6666-666666666673',
            (SELECT bigint_value FROM test_ctx WHERE ctx_key = 'event_type_cta_v1'),
            '[]'::jsonb
        );
        RAISE EXCEPTION 'TESTE FALHOU: metadata_json array deveria ser rejeitado';
    EXCEPTION
        WHEN check_violation THEN
            RAISE NOTICE 'OK: ck_analytics_event_metadata_json_object rejeitou array';
    END;
END
$$;

-- FALHAR: metadata_json como escalar.
DO $$
BEGIN
    BEGIN
        INSERT INTO analytics.event (
            session_id,
            ingestion_key,
            event_type_id,
            metadata_json
        ) VALUES (
            (SELECT uuid_value FROM test_ctx WHERE ctx_key = 'session_main'),
            '66666666-6666-6666-6666-666666666674',
            (SELECT bigint_value FROM test_ctx WHERE ctx_key = 'event_type_cta_v1'),
            '1'::jsonb
        );
        RAISE EXCEPTION 'TESTE FALHOU: metadata_json escalar deveria ser rejeitado';
    EXCEPTION
        WHEN check_violation THEN
            RAISE NOTICE 'OK: ck_analytics_event_metadata_json_object rejeitou escalar';
    END;
END
$$;

-- SUCEDER: product_id válido.
INSERT INTO analytics.event (
    session_id,
    ingestion_key,
    event_type_id,
    product_id,
    metadata_json
) VALUES (
    (SELECT uuid_value FROM test_ctx WHERE ctx_key = 'session_main'),
    '66666666-6666-6666-6666-666666666675',
    (SELECT bigint_value FROM test_ctx WHERE ctx_key = 'event_type_pricing_v1'),
    (SELECT int_value FROM test_ctx WHERE ctx_key = 'product_existing'),
    '{"plan_code":"pro"}'::jsonb
);

-- FALHAR: product_id inexistente.
DO $$
BEGIN
    BEGIN
        INSERT INTO analytics.event (
            session_id,
            ingestion_key,
            event_type_id,
            product_id
        ) VALUES (
            (SELECT uuid_value FROM test_ctx WHERE ctx_key = 'session_main'),
            '66666666-6666-6666-6666-666666666676',
            (SELECT bigint_value FROM test_ctx WHERE ctx_key = 'event_type_pricing_v1'),
            999999999
        );
        RAISE EXCEPTION 'TESTE FALHOU: product_id inexistente deveria ser rejeitado em event';
    EXCEPTION
        WHEN foreign_key_violation THEN
            RAISE NOTICE 'OK: fk_analytics_event_product rejeitou product_id inexistente';
    END;
END
$$;

-- ============================================================
-- 7. Exclusões e integridade
-- ============================================================

-- Objetivo:
--   Validar RESTRICT entre fatos e CASCADE nos contextos-raiz.

-- FALHAR: exclusão de page_view com event vinculado.
DO $$
DECLARE
    v_constraint_name TEXT;
BEGIN
    BEGIN
        DELETE FROM analytics.page_view
        WHERE page_view_id = (SELECT uuid_value FROM test_ctx WHERE ctx_key = 'page_view_main');
        RAISE EXCEPTION 'TESTE FALHOU: page_view com event vinculado deveria ser protegido por RESTRICT';
    EXCEPTION
        WHEN foreign_key_violation THEN
            RAISE NOTICE 'OK: fk_analytics_event_page_view_session protegeu page_view com event vinculado';
        WHEN OTHERS THEN
            GET STACKED DIAGNOSTICS v_constraint_name = CONSTRAINT_NAME;
            IF v_constraint_name = 'fk_analytics_event_page_view_session' THEN
                RAISE NOTICE 'OK: fk_analytics_event_page_view_session protegeu page_view com event vinculado';
            ELSE
                RAISE;
            END IF;
    END;
END
$$;

-- FALHAR: exclusão de event_type em uso.
DO $$
DECLARE
    v_constraint_name TEXT;
BEGIN
    BEGIN
        DELETE FROM analytics.event_type
        WHERE event_type_id = (SELECT bigint_value FROM test_ctx WHERE ctx_key = 'event_type_pricing_v1');
        RAISE EXCEPTION 'TESTE FALHOU: event_type em uso deveria ser protegido por RESTRICT';
    EXCEPTION
        WHEN foreign_key_violation THEN
            RAISE NOTICE 'OK: fk_analytics_event_type protegeu event_type em uso';
        WHEN OTHERS THEN
            GET STACKED DIAGNOSTICS v_constraint_name = CONSTRAINT_NAME;
            IF v_constraint_name = 'fk_analytics_event_type' THEN
                RAISE NOTICE 'OK: fk_analytics_event_type protegeu event_type em uso';
            ELSE
                RAISE;
            END IF;
    END;
END
$$;

-- SUCEDER: exclusão de sessão remove page_views e events associados.
DELETE FROM analytics.session
WHERE session_id = (SELECT uuid_value FROM test_ctx WHERE ctx_key = 'session_delete');

SELECT
    (SELECT COUNT(*) FROM analytics.session WHERE session_id = (SELECT uuid_value FROM test_ctx WHERE ctx_key = 'session_delete')) AS session_delete_count,
    (SELECT COUNT(*) FROM analytics.page_view WHERE session_id = (SELECT uuid_value FROM test_ctx WHERE ctx_key = 'session_delete')) AS page_view_delete_count,
    (SELECT COUNT(*) FROM analytics.event WHERE session_id = (SELECT uuid_value FROM test_ctx WHERE ctx_key = 'session_delete')) AS event_delete_count;

-- Recria cadeia mínima para testar exclusão de visitor.
INSERT INTO analytics.session (
    session_id,
    visitor_id,
    started_at,
    last_activity_at,
    landing_path
)
VALUES (
    '22222222-2222-2222-2222-222222222224',
    (SELECT uuid_value FROM test_ctx WHERE ctx_key = 'visitor_delete'),
    TIMESTAMPTZ '2026-07-17 12:10:00+00',
    TIMESTAMPTZ '2026-07-17 12:15:00+00',
    '/delete-visitor'
);

INSERT INTO analytics.page_view (
    page_view_id,
    session_id,
    ingestion_key,
    sequence_no,
    page_path
) VALUES (
    '33333333-3333-3333-3333-333333333334',
    '22222222-2222-2222-2222-222222222224',
    '55555555-5555-5555-5555-555555555566',
    1,
    '/delete-visitor'
);

INSERT INTO analytics.event (
    event_id,
    session_id,
    page_view_id,
    ingestion_key,
    event_type_id
) VALUES (
    '44444444-4444-4444-4444-444444444444',
    '22222222-2222-2222-2222-222222222224',
    '33333333-3333-3333-3333-333333333334',
    '66666666-6666-6666-6666-666666666677',
    (SELECT bigint_value FROM test_ctx WHERE ctx_key = 'event_type_cta_v1')
);

-- SUCEDER: exclusão de visitor remove sessões e fatos associados.
DELETE FROM analytics.visitor
WHERE visitor_id = (SELECT uuid_value FROM test_ctx WHERE ctx_key = 'visitor_delete');

SELECT
    (SELECT COUNT(*) FROM analytics.visitor WHERE visitor_id = (SELECT uuid_value FROM test_ctx WHERE ctx_key = 'visitor_delete')) AS visitor_delete_count,
    (SELECT COUNT(*) FROM analytics.session WHERE visitor_id = (SELECT uuid_value FROM test_ctx WHERE ctx_key = 'visitor_delete')) AS session_by_deleted_visitor_count,
    (SELECT COUNT(*)
     FROM analytics.page_view pv
     JOIN analytics.session s ON s.session_id = pv.session_id
     WHERE s.visitor_id = (SELECT uuid_value FROM test_ctx WHERE ctx_key = 'visitor_delete')) AS page_view_by_deleted_visitor_count,
    (SELECT COUNT(*)
     FROM analytics.event e
     JOIN analytics.session s ON s.session_id = e.session_id
     WHERE s.visitor_id = (SELECT uuid_value FROM test_ctx WHERE ctx_key = 'visitor_delete')) AS event_by_deleted_visitor_count;

-- ============================================================
-- 8. Consultas finais de conferência
-- ============================================================

-- Objetivo:
--   Consolidar uma leitura humana do estado final da transação de ensaio.

-- Quantidade de visitors.
SELECT COUNT(*) AS visitors_total
FROM analytics.visitor;

-- Sessões por visitor.
SELECT visitor_id, COUNT(*) AS session_count
FROM analytics.session
GROUP BY visitor_id
ORDER BY session_count DESC, visitor_id;

-- Sequência de page views por sessão.
SELECT session_id, sequence_no, page_path, viewed_at
FROM analytics.page_view
ORDER BY session_id, sequence_no;

-- Eventos por event_type.
SELECT et.event_code, et.event_version, COUNT(e.event_id) AS event_count
FROM analytics.event_type et
LEFT JOIN analytics.event e ON e.event_type_id = et.event_type_id
GROUP BY et.event_type_id, et.event_code, et.event_version
ORDER BY et.event_code, et.event_version;

-- Ausência de duplicidade de ingestion_key.
SELECT 'page_view' AS fact_name, ingestion_key, COUNT(*) AS repeated_count
FROM analytics.page_view
GROUP BY ingestion_key
HAVING COUNT(*) > 1
UNION ALL
SELECT 'event' AS fact_name, ingestion_key, COUNT(*) AS repeated_count
FROM analytics.event
GROUP BY ingestion_key
HAVING COUNT(*) > 1;

-- Integridade entre event, page_view e session.
SELECT
    e.event_id,
    e.session_id AS event_session_id,
    e.page_view_id,
    pv.session_id AS page_view_session_id,
    CASE
        WHEN e.page_view_id IS NULL THEN 'NO_PAGE_VIEW'
        WHEN e.session_id = pv.session_id THEN 'OK'
        ELSE 'MISMATCH'
    END AS integrity_status
FROM analytics.event e
LEFT JOIN analytics.page_view pv ON pv.page_view_id = e.page_view_id
ORDER BY e.occurred_at;

-- Produto associado aos fatos.
SELECT
    'page_view' AS fact_name,
    pv.page_view_id AS fact_id,
    pv.product_id,
    p.code AS product_code
FROM analytics.page_view pv
LEFT JOIN product.product p ON p.product_id = pv.product_id
WHERE pv.product_id IS NOT NULL
UNION ALL
SELECT
    'event' AS fact_name,
    e.event_id AS fact_id,
    e.product_id,
    p.code AS product_code
FROM analytics.event e
LEFT JOIN product.product p ON p.product_id = e.product_id
WHERE e.product_id IS NOT NULL
ORDER BY fact_name, fact_id;

-- Sessões ainda abertas e sessões consolidadas.
SELECT
    session_id,
    visitor_id,
    started_at,
    last_activity_at,
    ended_at,
    duration_ms,
    CASE
        WHEN ended_at IS NULL THEN 'OPEN'
        ELSE 'CONSOLIDATED'
    END AS session_state
FROM analytics.session
ORDER BY started_at;

-- ============================================================
-- Resumo do ensaio
-- ============================================================

-- Testes positivos previstos:
-- - inserção válida em provider_config
-- - inserção e reuso idempotente de visitor
-- - criação válida de session
-- - criação válida de page_view
-- - criação válida de event_type com PK gerada
-- - criação válida de event com e sem page_view
-- - cascata de session -> page_view/event
-- - cascata de visitor -> session/page_view/event
--
-- Testes negativos previstos:
-- - duplicidades semânticas em provider_config, page_view, event_type e event
-- - FKs inválidas em session, page_view e event
-- - checks temporais, de path, país, device, telas, payload e metadata
-- - RESTRICT em page_view com event vinculado
-- - RESTRICT em event_type em uso
--
-- Constraints cobertas:
-- - UNIQUE
-- - FOREIGN KEY
-- - CHECK
-- - PK gerada por IDENTITY
--
-- Comportamentos ainda dependentes da FastAPI:
-- - geração e persistência consistente de ingestion_key
-- - política amigável de idempotência com ON CONFLICT e retorno de payload
-- - resolução de event_type por código/versão
-- - mapeamento de product_id a partir da navegação e dos contratos da app
--
-- Comportamentos ainda dependentes do Analytics Worker:
-- - fechamento canônico de sessão por inatividade
-- - consolidação de ended_at, duration_ms e exit_path
-- - enriquecimento geográfico e sanitização de dados temporários
-- - camadas derivadas como score, snapshots e dashboards
--
-- Resultado esperado:
--   Este roteiro valida apenas o DDL do domínio analytics em PostgreSQL limpo.
--   Não declara runtime aprovado.

ROLLBACK;
