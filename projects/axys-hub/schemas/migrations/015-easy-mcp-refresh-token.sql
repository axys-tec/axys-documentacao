-- P3 SSO: refresh token opaco, rotativo e vinculado ao sid do Easy MCP.
CREATE TABLE IF NOT EXISTS auth.hub_refresh_token (
    refresh_id     UUID        NOT NULL DEFAULT gen_random_uuid(),
    sid            UUID        NOT NULL,
    token_hash     CHAR(64)    NOT NULL,
    created_at     TIMESTAMPTZ NOT NULL DEFAULT now(),
    expires_at     TIMESTAMPTZ NOT NULL,
    used_at        TIMESTAMPTZ,
    revoked_at     TIMESTAMPTZ,
    replaced_by_id UUID,

    CONSTRAINT hub_refresh_token_pkey PRIMARY KEY (refresh_id),
    CONSTRAINT uq_hub_refresh_token_hash UNIQUE (token_hash),
    CONSTRAINT fk_hub_refresh_token_session FOREIGN KEY (sid)
        REFERENCES auth.hub_sessao (sid) ON DELETE CASCADE,
    CONSTRAINT fk_hub_refresh_token_replacement FOREIGN KEY (replaced_by_id)
        REFERENCES auth.hub_refresh_token (refresh_id) ON DELETE SET NULL,
    CONSTRAINT ck_hub_refresh_token_expiry CHECK (expires_at > created_at)
);

CREATE INDEX IF NOT EXISTS idx_hub_refresh_token_sid
    ON auth.hub_refresh_token (sid, created_at DESC);
