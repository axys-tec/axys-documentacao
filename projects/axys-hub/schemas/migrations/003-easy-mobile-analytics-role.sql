-- Executar como administrador PostgreSQL. Não colocar senha neste arquivo.
-- Depois, definir LOGIN/password pelo provedor e montar HUB_ANALYTICS_DB_URL.
DO $role$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'easy_mobile_analytics_writer') THEN
        CREATE ROLE easy_mobile_analytics_writer NOLOGIN;
    END IF;
END
$role$;

REVOKE ALL ON SCHEMA identity, auth, product, orders, billing, gateway, fiscal, commercial, audit
    FROM easy_mobile_analytics_writer;
REVOKE ALL ON ALL TABLES IN SCHEMA analytics FROM easy_mobile_analytics_writer;
GRANT USAGE ON SCHEMA analytics TO easy_mobile_analytics_writer;
GRANT INSERT ON analytics.easy_mobile_event TO easy_mobile_analytics_writer;
GRANT USAGE, SELECT ON SEQUENCE analytics.easy_mobile_event_event_id_seq
    TO easy_mobile_analytics_writer;
