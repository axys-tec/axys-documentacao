-- P1 Easy MCP: distingue a origem do login MCP na trilha de auditoria.
-- Idempotente para bancos que já receberam esta ampliação.
ALTER TABLE audit.login_log
    DROP CONSTRAINT IF EXISTS ck_login_log_origin;

ALTER TABLE audit.login_log
    ADD CONSTRAINT ck_login_log_origin
    CHECK (origin IN ('LOCAL', 'SSO', 'GOV_BR', 'APPLE', 'GOOGLE', 'API_KEY', 'easy-mcp'));
