-- ------------------------------------------------------------
-- analytics.easy_mobile_lead
-- Função:
--   Interesse manifestado por usuário do Easy Mobile em uma solução Axys.
-- Motivo:
--   É lead quente e ISOLADO: nasce no app, não vem de campanha nem de parceiro, e por
--   isso não se liga ao schema commercial. O que o distingue de analytics.easy_mobile_event
--   é que ele MUDA — alguém marca como contatado, anota o que conversou, altera o status.
--   Registro mutável em tabela append-only seria erro de modelagem.
-- Nível de controle:
--   Altíssimo. Dado pessoal com finalidade de CONTATO, base legal distinta da telemetria.
-- Como funciona:
--   A Easy Mobile API grava um registro por clique em solução (evento pesquisa_solucao no
--   app). `ingestion_key` torna o reenvio da fila offline inofensivo — sem ela, alguém
--   ligaria duas vezes para a mesma pessoa.
-- Como ler/usar:
--   Fila de atendimento por `status`, e `context_json` para priorizar: um "contratar" de
--   quem usa o app há três semanas vale diferente do de quem instalou há cinco minutos.
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS analytics.easy_mobile_lead (
    lead_id         BIGINT      GENERATED ALWAYS AS IDENTITY,
    lead_uuid       UUID        NOT NULL DEFAULT gen_random_uuid(),
    ingestion_key   TEXT        NOT NULL,
    solution_code   TEXT        NOT NULL,
    action_code     TEXT        NOT NULL,
    -- Ator. Os três podem ficar NULOS: é o estado após pedido de exclusão, em que os
    -- dados pessoais saem e a linha sobrevive identificada só pelo próprio lead_uuid —
    -- desvincular sem apagar o agregado, que é o que a LGPD pede.
    --
    -- NÃO existe CHECK exigindo ao menos um ator preenchido. Ele pareceria proteger, mas
    -- tornaria a anonimização impossível: zerar o último ator violaria a própria regra.
    -- A garantia de que todo INSERT traz ator é da API.
    client_uuid     UUID,
    hub_user_uuid   UUID,
    anonymous_id    TEXT,
    session_id      TEXT,
    -- Quando o titular pediu exclusão. Distingue "nasceu anônimo" de "foi anonimizado",
    -- e é a evidência de atendimento ao pedido.
    anonymized_at   TIMESTAMPTZ,
    -- A jornada NO INSTANTE do clique: buscas feitas, conteúdos abertos, dias de uso.
    -- Reconstruir isso depois exigiria varrer a tabela de eventos inteira.
    context_json    JSONB       NOT NULL DEFAULT '{}',
    status          TEXT        NOT NULL DEFAULT 'novo',
    note            TEXT,
    occurred_at     TIMESTAMPTZ NOT NULL,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT easy_mobile_lead_pkey PRIMARY KEY (lead_id),
    CONSTRAINT uq_easy_mobile_lead_uuid UNIQUE (lead_uuid),
    CONSTRAINT uq_easy_mobile_lead_ingestion UNIQUE (ingestion_key),
    -- SET NULL e não CASCADE: apagar a conta não apaga o lead, só o vínculo pessoal.
    CONSTRAINT fk_easy_mobile_lead_client FOREIGN KEY (client_uuid)
        REFERENCES identity.client_easy_mobile (client_uuid) ON DELETE SET NULL,
    CONSTRAINT fk_easy_mobile_lead_hub_user FOREIGN KEY (hub_user_uuid)
        REFERENCES identity.hub_user (user_id) ON DELETE SET NULL,
    CONSTRAINT ck_easy_mobile_lead_action CHECK (
        action_code IN ('saber_mais', 'contratar', 'video', 'site')
    ),
    CONSTRAINT ck_easy_mobile_lead_status CHECK (
        status IN ('novo', 'contatado', 'qualificado', 'convertido', 'descartado')
    ),
    CONSTRAINT ck_easy_mobile_lead_solution CHECK (btrim(solution_code) <> ''),
    CONSTRAINT ck_easy_mobile_lead_context CHECK (jsonb_typeof(context_json) = 'object')
);

CREATE INDEX IF NOT EXISTS idx_easy_mobile_lead_status_occurred
    ON analytics.easy_mobile_lead (status, occurred_at DESC);
CREATE INDEX IF NOT EXISTS idx_easy_mobile_lead_client_occurred
    ON analytics.easy_mobile_lead (client_uuid, occurred_at DESC);

COMMENT ON TABLE analytics.easy_mobile_lead IS
    'Lead quente do Easy Mobile. MUTÁVEL (status/note). Isolado do schema commercial. '
    'Sem expurgo automático: vive até a conta ser excluída ou o negócio fechar.';


-- ------------------------------------------------------------
-- CORREÇÃO em analytics.easy_mobile_event
--
-- A tabela já existe (fora do schema.sql) com `ck_easy_mobile_event_actor`, exigindo ao
-- menos um ator preenchido, E `ON DELETE SET NULL` nas duas FKs. Os dois não convivem:
-- um evento gravado só com client_uuid — o caso normal de usuário logado — faz o SET NULL
-- virar um UPDATE que viola o próprio CHECK, e a EXCLUSÃO DA CONTA FALHA.
--
-- Verificado em 12/09/2026 reproduzindo o cenário no Postgres: CHECK é reavaliado no
-- UPDATE, e o SET NULL é um UPDATE.
--
-- Hoje não quebra porque a tabela tem zero linhas. Quebraria no primeiro usuário que
-- apagasse a conta depois de usar o app — e excluir dentro do app é exigência da App
-- Store e da LGPD, já implementada no Easy Mobile.
-- ------------------------------------------------------------
ALTER TABLE analytics.easy_mobile_event
    DROP CONSTRAINT IF EXISTS ck_easy_mobile_event_actor;

ALTER TABLE analytics.easy_mobile_event
    ADD COLUMN IF NOT EXISTS anonymized_at TIMESTAMPTZ;

COMMENT ON COLUMN analytics.easy_mobile_event.anonymized_at IS
    'Quando o titular pediu exclusão. Distingue "nasceu anônimo" de "foi anonimizado".';
