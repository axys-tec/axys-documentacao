BEGIN;

-- O nome histórico da coluna é mantido por compatibilidade. Neste fluxo, o valor
-- identifica a frente de entrada; a aquisição real permanece em UTM, referrer e
-- sessão de analytics, quando o consentimento permite essa associação.
ALTER TABLE commercial.campaign_registration
    DROP CONSTRAINT IF EXISTS ck_campaign_registration_acquisition_source;
ALTER TABLE commercial.campaign_registration
    ADD CONSTRAINT ck_campaign_registration_acquisition_source CHECK (
        acquisition_source IN ('META', 'EASY_MOBILE', 'CONTATOS_RENAN', 'HUB_SITE')
    );

COMMIT;
