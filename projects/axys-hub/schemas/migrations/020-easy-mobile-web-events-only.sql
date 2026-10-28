-- O Hub mede somente o funil web. Eventos internos do aplicativo não são
-- ingeridos por este projeto e permanecem sob responsabilidade das lojas.
ALTER TABLE analytics.easy_mobile_acquisition_event
    DROP CONSTRAINT IF EXISTS ck_easy_mobile_acquisition_event_type;

ALTER TABLE analytics.easy_mobile_acquisition_event
    ADD CONSTRAINT ck_easy_mobile_acquisition_event_type CHECK (event_type IN (
        'campaign_passage', 'landing_view', 'store_click', 'store_redirect'
    ));
