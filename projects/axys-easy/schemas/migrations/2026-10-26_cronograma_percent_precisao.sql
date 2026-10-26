-- 2026-10-26_cronograma_percent_precisao.sql
--
-- Descrição: REPARO DE PRODUÇÃO — `cri_percent` passa de numeric(9,6) para numeric(12,9), como o
--            schema.sql declara desde 14/10 (`820f509`): o cronograma deriva R$ do %, e com 6 casas o
--            % perde centavos na volta. A migration de reparo de 20/10 (cronograma_trava_e_medicoes)
--            repôs a trava e as medições e não cobriu esta coluna. Achado pelo `schema_fiel --prod`
--            na subida do bug 2 (26/10/2026).
--
-- Ordem: ADITIVA (só amplia: todo valor de (9,6) cabe em (12,9)). Pode rodar a qualquer hora.
--
-- Idempotente: só altera se a escala ainda não for 9 — em dev, onde já é, é no-op.
--
-- Rollback: não há (voltar a 6 casas perderia precisão já gravada).
-- Data: 26/10/2026

DO $$ BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.columns
                WHERE table_schema = 'ativo' AND table_name = 'ativo_orcamento_cronograma_itens'
                  AND column_name = 'cri_percent' AND numeric_scale IS DISTINCT FROM 9) THEN
        ALTER TABLE ativo.ativo_orcamento_cronograma_itens ALTER COLUMN cri_percent TYPE numeric(12,9);
    END IF;
END $$;
