-- Telemetria do Easy Mobile — schema no banco do HUB
-- Contrato: docs/projects/axys-easy/modules/easy-mobile/projeto.md § Telemetria
--
-- Quem escreve: a Easy Mobile API, com role própria. O banco do Easy segue SEM ESCRITA
-- alguma (§3 da Central de Custos) — por isso a telemetria mora aqui e não lá.
--
-- DUAS TABELAS, e a razão não é volume: `eventos` é append-only e `interesses` MUDA —
-- alguém marca como contatado, anota, altera status. Registro mutável em tabela
-- append-only é erro de modelagem. E a separação é fronteira de privacidade: dar acesso
-- comercial ao lead não pode dar acesso ao histórico de navegação de ninguém.

CREATE SCHEMA IF NOT EXISTS easymobile_metrics;

-- ── uso ──────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS easymobile_metrics.eventos (
    evt_id             bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    -- Gerada no APP. Com fila offline e retentativa o mesmo evento chega duas vezes:
    -- rede que cai depois de o servidor gravar e antes de o app receber a confirmação.
    evt_chave          uuid        NOT NULL UNIQUE,
    evt_nome           text        NOT NULL,
    evt_sub            text,
    evt_subject_type   text,
    -- ocorrido_em é no APARELHO; registrado_em é no servidor. Evento offline chega horas
    -- depois: sem as duas, o uso de quem estava sem sinal se concentra no momento em que
    -- o sinal voltou, e a métrica por hora do dia mente.
    evt_ocorrido_em    timestamptz NOT NULL,
    evt_registrado_em  timestamptz NOT NULL DEFAULT now(),
    evt_payload        jsonb       NOT NULL DEFAULT '{}'::jsonb,
    CONSTRAINT evt_nome_conhecido CHECK (evt_nome IN (
        'busca', 'composicao_aberta', 'insumo_aberto',
        'conteudo_aberto', 'busca_conhecimento', 'app_aberto'
    ))
);

-- Dois índices, não mais: tabela append-only de alto volume paga escrita em cada um.
CREATE INDEX IF NOT EXISTS ix_evt_nome_data
    ON easymobile_metrics.eventos (evt_nome, evt_ocorrido_em DESC);
-- Cobre o item de maior valor: termo buscado que não achou nada.
CREATE INDEX IF NOT EXISTS ix_evt_busca_sem_resultado
    ON easymobile_metrics.eventos ((evt_payload ->> 'termo'))
    WHERE evt_nome = 'busca' AND (evt_payload ->> 'resultados') = '0';

COMMENT ON TABLE  easymobile_metrics.eventos IS
    'Uso do app. APPEND-ONLY. Retenção: 180 dias no detalhe, agregado depois.';
COMMENT ON COLUMN easymobile_metrics.eventos.evt_payload IS
    'O que varia por evento. busca: termo/tipo/fonte/uf/resultados · conteudo_aberto: grupo/id';

-- ── lead ─────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS easymobile_metrics.interesses (
    int_id             bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    -- Idempotência importa mais aqui do que em eventos: lead duplicado faz alguém ligar
    -- duas vezes para a mesma pessoa.
    int_chave          uuid        NOT NULL UNIQUE,
    int_sub            text        NOT NULL,
    int_subject_type   text,
    int_solucao_id     text        NOT NULL,
    int_acao           text        NOT NULL,
    int_ocorrido_em    timestamptz NOT NULL,
    int_registrado_em  timestamptz NOT NULL DEFAULT now(),
    -- A jornada NO INSTANTE do clique: buscas feitas, conteúdos abertos, dias de uso. Um
    -- "contratar" de quem usou três semanas vale diferente do de quem instalou há cinco
    -- minutos, e reconstruir isso depois exige varrer a tabela inteira.
    int_contexto       jsonb       NOT NULL DEFAULT '{}'::jsonb,
    int_situacao       text        NOT NULL DEFAULT 'NOVO',
    int_observacao     text,
    int_atualizado_em  timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT int_acao_conhecida CHECK (int_acao IN (
        'saber_mais', 'contratar', 'video', 'site'
    )),
    CONSTRAINT int_situacao_conhecida CHECK (int_situacao IN (
        'NOVO', 'CONTATADO', 'QUALIFICADO', 'CONVERTIDO', 'DESCARTADO'
    ))
);

CREATE INDEX IF NOT EXISTS ix_int_situacao
    ON easymobile_metrics.interesses (int_situacao, int_ocorrido_em DESC);

COMMENT ON TABLE easymobile_metrics.interesses IS
    'Lead qualificado. MUTÁVEL. Sem expurgo automático: vive até a conta ser excluída ou '
    'o negócio fechar. Finalidade distinta dos eventos na LGPD — existe para CONTATAR.';

-- ── role da API ──────────────────────────────────────────────────────────────
-- Só o necessário. NUNCA a credencial ampla do Hub. `interesses` recebe UPDATE porque o
-- comercial muda situação e observação; `eventos` nunca muda depois de gravado.
-- (criar a role e a senha fora daqui, no dashboard)
--
--   GRANT USAGE ON SCHEMA easymobile_metrics TO easy_mobile_analytics_writer;
--   GRANT INSERT ON easymobile_metrics.eventos     TO easy_mobile_analytics_writer;
--   GRANT INSERT, UPDATE, SELECT ON easymobile_metrics.interesses TO easy_mobile_analytics_writer;
--   GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA easymobile_metrics TO easy_mobile_analytics_writer;
