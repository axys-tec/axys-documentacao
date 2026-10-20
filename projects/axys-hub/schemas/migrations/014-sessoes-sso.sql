-- P2 SSO: registro e revogacao de sessoes por usuario e aplicativo.
CREATE TABLE IF NOT EXISTS auth.hub_sessao (
    sid               UUID        NOT NULL DEFAULT gen_random_uuid(),
    jti               UUID        NOT NULL DEFAULT gen_random_uuid(),
    subject_id        UUID        NOT NULL,
    subject_type      TEXT        NOT NULL,
    user_id           UUID,
    tenant_id         UUID,
    app               TEXT        NOT NULL,
    ip                TEXT,
    user_agent        TEXT,
    created_at        TIMESTAMPTZ NOT NULL DEFAULT now(),
    last_seen_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    revoked_at        TIMESTAMPTZ,
    revocation_reason TEXT,
    replaced_by_sid   UUID,

    CONSTRAINT hub_sessao_pkey PRIMARY KEY (sid),
    CONSTRAINT uq_hub_sessao_jti UNIQUE (jti),
    CONSTRAINT fk_hub_sessao_user FOREIGN KEY (user_id)
        REFERENCES identity.hub_user (user_id) ON DELETE CASCADE,
    CONSTRAINT fk_hub_sessao_tenant FOREIGN KEY (tenant_id)
        REFERENCES identity.hub_tenant (tenant_id) ON DELETE CASCADE,
    CONSTRAINT fk_hub_sessao_replacement FOREIGN KEY (replaced_by_sid)
        REFERENCES auth.hub_sessao (sid) ON DELETE SET NULL,
    CONSTRAINT ck_hub_sessao_subject_type
        CHECK (subject_type IN ('hub_user', 'easy_mobile_client')),
    CONSTRAINT ck_hub_sessao_app
        CHECK (app IN ('easy', 'easy-mcp', 'easy-mobile', 'gestor')),
    CONSTRAINT ck_hub_sessao_hub_user
        CHECK (subject_type <> 'hub_user' OR (user_id IS NOT NULL AND user_id = subject_id)),
    CONSTRAINT ck_hub_sessao_tenant
        CHECK (app = 'easy-mobile' OR tenant_id IS NOT NULL)
);

CREATE UNIQUE INDEX IF NOT EXISTS uq_hub_sessao_single_active
    ON auth.hub_sessao (subject_id, COALESCE(tenant_id, '00000000-0000-0000-0000-000000000000'::uuid), app)
    WHERE revoked_at IS NULL AND app IN ('easy', 'easy-mcp', 'gestor');

CREATE INDEX IF NOT EXISTS idx_hub_sessao_status
    ON auth.hub_sessao (sid, app, revoked_at);

CREATE INDEX IF NOT EXISTS idx_hub_sessao_mobile_active
    ON auth.hub_sessao (subject_id, tenant_id, created_at)
    WHERE revoked_at IS NULL AND app = 'easy-mobile';

ALTER TABLE audit.login_log
    DROP CONSTRAINT IF EXISTS ck_login_log_action;

ALTER TABLE audit.login_log
    ADD CONSTRAINT ck_login_log_action
    CHECK (action IN (
        'LOGIN', 'LOGOUT', 'LOGIN_FALHA', 'TROCAR_CONTA',
        'SESSAO_DERRUBADA', 'SESSAO_REVOGADA'
    ));
