-- 2026-10-29 · sai catalogo.insumos_equivalencias (legada)
-- Plano: docs/projects/axys-easy/next-steps/final_associacoes.md §7
--
-- A equivalência insumo↔insumo "difusa" (score/tipo, cadastro manual na tela do insumo) foi
-- substituída pelas associações 1×1 entre fontes (equivalencias_ins/_cpu/_mo, motor do estágio
-- `associacoes`). A tela de cadastro e os leitores saíram junto; o selo "Equivalência" da listagem
-- de insumos passou a ler equivalencias_ins. Em 29/10 a tabela tinha 0 linha em dev (dev = prod no
-- catálogo).
--
-- TRAVA: se houver qualquer linha, a migration ABORTA — nada se apaga sem olhar.
-- IDEMPOTENTE: DROP ... IF EXISTS; sem a tabela, é no-op.
--
--   psql "$EASY_DB_URL" -v ON_ERROR_STOP=1 -f docs/projects/axys-easy/schemas/migrations/2026-10-29_drop_insumos_equivalencias.sql

BEGIN;

DO $$
DECLARE n bigint;
BEGIN
    IF to_regclass('catalogo.insumos_equivalencias') IS NOT NULL THEN
        EXECUTE 'SELECT count(*) FROM catalogo.insumos_equivalencias' INTO n;
        IF n > 0 THEN
            RAISE EXCEPTION 'catalogo.insumos_equivalencias tem % linha(s) — confira antes de apagar', n;
        END IF;
    END IF;
END $$;

DROP TABLE IF EXISTS catalogo.insumos_equivalencias;

COMMIT;
