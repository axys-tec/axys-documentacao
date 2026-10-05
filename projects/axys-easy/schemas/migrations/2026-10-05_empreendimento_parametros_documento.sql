-- AxysEasy — `ativo.empreendimento_parametros` deixa de ser fonte-base e passa a ser a
-- configuração de DOCUMENTO do empreendimento (1 linha por empreendimento).
--
-- POR QUE TROCAR O USO DA MESMA TABELA
--   A tabela existia para herdar fonte-base do empreendimento para todos os ativos (decisão de
--   22/06/2026). Nunca foi usada: ZERO linhas em dev e em produção, contra 28 e 31 em
--   `orcamento_parametros` (por ativo). E é errada por modelo — empreendimento multi-ativo tem
--   ativos de épocas e tabelas-base diferentes, então fonte no nível do empreendimento não existe.
--   O código que a lia e escrevia foi removido no mesmo passo.
--
-- DESTRUTIVA? Na forma, sim: faz DROP da tabela. No conteúdo, não: ela está vazia nos dois
-- bancos. A CONFERÊNCIA ABAIXO É OBRIGATÓRIA e o próprio script a faz — se houver uma linha
-- sequer, ele aborta antes do DROP.
--
-- DEPENDE DE DEPLOY: sim, e nesta ordem — primeiro o código (que já não lê as colunas antigas),
-- depois esta migration. Ao contrário da do RT, aqui a ordem é inversa: migration antes do código
-- quebraria `get_contexto` enquanto a versão antiga estiver no ar.
--
-- ROLLBACK: recriar a tabela antiga a partir do schema.sql anterior a 05/10/2026. Sem perda de
-- dado, porque não havia dado.

BEGIN;

-- Trava de segurança: aborta se a tabela antiga tiver qualquer linha.
DO $$
DECLARE n INTEGER;
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.columns
               WHERE table_schema='ativo' AND table_name='empreendimento_parametros'
                 AND column_name='epa_fonte') THEN
        EXECUTE 'SELECT count(*) FROM ativo.empreendimento_parametros' INTO n;
        IF n > 0 THEN
            RAISE EXCEPTION 'empreendimento_parametros tem % linha(s) — migração abortada. '
                            'Havia dado onde não deveria; decida o destino antes de prosseguir.', n;
        END IF;
    END IF;
END $$;

DROP TABLE IF EXISTS ativo.empreendimento_parametros;

CREATE TABLE ativo.empreendimento_parametros (
    epa_emp_id          INTEGER PRIMARY KEY
                        REFERENCES ativo.empreendimentos (emp_id)
                        ON UPDATE CASCADE ON DELETE CASCADE,
    epa_estilo          SMALLINT NOT NULL DEFAULT 1,
    epa_ocultar_fonte   BOOLEAN NOT NULL DEFAULT FALSE,
    epa_ocultar_codigo  BOOLEAN NOT NULL DEFAULT FALSE,
    epa_direcionar      BOOLEAN NOT NULL DEFAULT FALSE,
    epa_prefixo         TEXT,
    epa_destinatario    TEXT,
    epa_local_data      BOOLEAN NOT NULL DEFAULT FALSE,
    epa_municipio       TEXT,
    epa_uf              CHAR(2),
    epa_data            DATE,
    epa_orient_curva_serv  TEXT NOT NULL DEFAULT 'H',
    epa_orient_curva_ins   TEXT NOT NULL DEFAULT 'H',
    epa_orient_cronograma  TEXT NOT NULL DEFAULT 'H',
    epa_orient_histo_sint  TEXT NOT NULL DEFAULT 'H',
    epa_orient_histo_anal  TEXT NOT NULL DEFAULT 'H',
    epa_entrega         TEXT NOT NULL DEFAULT 'UNICO',
    -- AGRUPAMENTO decide a FORMA do documento consolidado:
    --   ISOLADO  = cada ativo com seu sumário e seus documentos, em sequência. SEM repath — os
    --              itens mantêm a numeração que têm hoje dentro do ativo.
    --   AGRUPADO = capa única, sumário único, tudo misturado, COM repath: o ativo desce um nível
    --              e passa a ser 1., 2.… e os itens dele descem junto.
    epa_agrupamento     TEXT NOT NULL DEFAULT 'ISOLADO',

    -- EXECUÇÃO decide como os cronogramas de vários ativos se somam:
    --   CONCOMITANTE = obras ao mesmo tempo; mês 1 soma com mês 1 de cada ativo.
    --   ISOLADA      = obras em sequência; dois ativos de 10 meses viram 20 meses, em ordem.
    epa_execucao        TEXT NOT NULL DEFAULT 'CONCOMITANTE',

    epa_criado_em       TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    epa_atualizado_em   TIMESTAMPTZ,
    epa_criado_por      TEXT,
    epa_atualizado_por  TEXT,

    CONSTRAINT ck_epa_estilo   CHECK (epa_estilo IN (1, 2, 3)),
    CONSTRAINT ck_epa_agrup    CHECK (epa_agrupamento IN ('AGRUPADO', 'ISOLADO')),
    CONSTRAINT ck_epa_exec     CHECK (epa_execucao IN ('CONCOMITANTE', 'ISOLADA')),
    CONSTRAINT ck_epa_entrega  CHECK (epa_entrega IN ('UNICO', 'ISOLADO')),
    CONSTRAINT ck_epa_orient   CHECK (epa_orient_curva_serv IN ('H','V') AND epa_orient_curva_ins IN ('H','V')
                                  AND epa_orient_cronograma IN ('H','V') AND epa_orient_histo_sint IN ('H','V')
                                  AND epa_orient_histo_anal IN ('H','V')),
    CONSTRAINT ck_epa_direcionar CHECK (NOT epa_direcionar OR btrim(COALESCE(epa_destinatario,'')) <> ''),
    CONSTRAINT ck_epa_local      CHECK (NOT epa_local_data OR btrim(COALESCE(epa_municipio,'')) <> '')
);

COMMIT;

-- Conferência: deve devolver a forma nova (epa_emp_id como PK, sem epa_fonte).
-- SELECT column_name FROM information_schema.columns
--  WHERE table_schema='ativo' AND table_name='empreendimento_parametros' ORDER BY ordinal_position;
