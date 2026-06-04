-- 002-add-sso-login-origem.sql
-- Descrição: Adiciona 'SSO' aos valores aceitos por audit.login_logs.log_origem,
--            para registrar logins via SSO do AxysHub (handshake A2 — ADR-021).
-- Rollback:  ver bloco no final (só é seguro se não houver linhas com 'SSO').
-- Data:      2026-06-03
--
-- Idempotente: recria o CHECK constraint sempre com o conjunto completo de valores.

ALTER TABLE audit.login_logs
    DROP CONSTRAINT IF EXISTS login_logs_log_origem_check;

ALTER TABLE audit.login_logs
    ADD CONSTRAINT login_logs_log_origem_check
    CHECK (log_origem IN (
        'LOCAL',
        'SSO',
        'GOV_BR',
        'APPLE',
        'GOOGLE',
        'API_KEY'
    ));

-- ─── Rollback ────────────────────────────────────────────────
-- ATENÇÃO: só rode se NÃO existir nenhuma linha com log_origem = 'SSO'
-- (senão o ADD CONSTRAINT falha). Verifique antes:
--   SELECT count(*) FROM audit.login_logs WHERE log_origem = 'SSO';
--
-- ALTER TABLE audit.login_logs
--     DROP CONSTRAINT IF EXISTS login_logs_log_origem_check;
-- ALTER TABLE audit.login_logs
--     ADD CONSTRAINT login_logs_log_origem_check
--     CHECK (log_origem IN ('LOCAL','GOV_BR','APPLE','GOOGLE','API_KEY'));
