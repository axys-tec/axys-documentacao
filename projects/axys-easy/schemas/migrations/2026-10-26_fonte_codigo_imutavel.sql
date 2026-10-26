-- 2026-10-26_fonte_codigo_imutavel.sql
--
-- Contrato: docs/projects/axys-easy/contracts/catalogo/identidade_fonte.md §2
--
-- Descrição: o código da fonte do catálogo global (SINAPI, CDHU, FDE…) é o IDENTIFICADOR da fonte e
--            não muda. Renomear não existe: nome novo = fonte nova (Renan, 26/10/2026). A guarda é
--            um gatilho que recusa o UPDATE da coluna quando o valor muda.
--
-- Ordem: ADITIVA. Pode rodar antes do deploy: nenhum fluxo legítimo troca o código (o form já o
--        trava; o seed casa por ele e nunca o reescreve).
--
-- Idempotente: CREATE OR REPLACE na função; DROP IF EXISTS + CREATE no gatilho.
--
-- Rollback: DROP TRIGGER IF EXISTS t_fte_codigo_imutavel ON catalogo.fontes;
--           DROP FUNCTION IF EXISTS catalogo.trg_fte_codigo_imutavel();
-- Data: 26/10/2026

-- O CÓDIGO DA FONTE É O IDENTIFICADOR, e não muda (contracts/catalogo/identidade_fonte.md §2).
-- Renomear não existe: nome novo = fonte nova. A guarda é do banco para não depender de alguém
-- lembrar — o form já trava o campo, mas um POST direto o trocaria. Compara OLD × NEW porque o
-- `UPDATE OF` dispara sempre que a coluna está no SET, mesmo com o valor igual.
CREATE OR REPLACE FUNCTION catalogo.trg_fte_codigo_imutavel() RETURNS trigger AS $$
BEGIN
    RAISE EXCEPTION 'O código da fonte é imutável (% -> %). Nome novo = fonte nova (identidade_fonte.md §2).',
        OLD.fte_codigo, NEW.fte_codigo;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS t_fte_codigo_imutavel ON catalogo.fontes;
CREATE TRIGGER t_fte_codigo_imutavel
    BEFORE UPDATE OF fte_codigo ON catalogo.fontes
    FOR EACH ROW WHEN (OLD.fte_codigo IS DISTINCT FROM NEW.fte_codigo)
    EXECUTE FUNCTION catalogo.trg_fte_codigo_imutavel();
