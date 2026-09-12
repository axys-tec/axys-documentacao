BEGIN;

ALTER TABLE identity.client_easy_mobile
    DROP CONSTRAINT IF EXISTS ck_client_easy_mobile_status;
ALTER TABLE identity.client_easy_mobile
    ADD CONSTRAINT ck_client_easy_mobile_status CHECK (
        status IN ('pending_verification', 'active', 'converted', 'deleted', 'blocked')
    );

-- O Mobile nunca mantém perfil paralelo para hub_user. Usuários principais
-- autenticam no app, mas seus dados continuam governados exclusivamente pelo Hub.
DROP TABLE IF EXISTS identity.easy_mobile_hub_user_profile;

COMMIT;
