-- Migration — tenant_catalogo: coluna de busca normalizada + trigger + índice GIN pg_trgm.
-- Idempotente. Extensões unaccent/pg_trgm já existem no schema catalogo (uso qualificado).
ALTER TABLE tenant_catalogo.insumos     ADD COLUMN IF NOT EXISTS ins_busca TEXT;
ALTER TABLE tenant_catalogo.composicoes ADD COLUMN IF NOT EXISTS cmp_busca TEXT;

CREATE OR REPLACE FUNCTION tenant_catalogo.set_busca() RETURNS trigger AS $$
BEGIN
    IF TG_TABLE_NAME = 'insumos' THEN
        NEW.ins_busca := upper(catalogo.unaccent(coalesce(NEW.ins_codigo, '') || ' ' || coalesce(NEW.ins_descricao, '')));
    ELSIF TG_TABLE_NAME = 'composicoes' THEN
        NEW.cmp_busca := upper(catalogo.unaccent(coalesce(NEW.cmp_codigo, '') || ' ' || coalesce(NEW.cmp_descricao, '')));
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_tci_busca ON tenant_catalogo.insumos;
CREATE TRIGGER trg_tci_busca BEFORE INSERT OR UPDATE ON tenant_catalogo.insumos
    FOR EACH ROW EXECUTE FUNCTION tenant_catalogo.set_busca();

DROP TRIGGER IF EXISTS trg_tcc_busca ON tenant_catalogo.composicoes;
CREATE TRIGGER trg_tcc_busca BEFORE INSERT OR UPDATE ON tenant_catalogo.composicoes
    FOR EACH ROW EXECUTE FUNCTION tenant_catalogo.set_busca();

CREATE INDEX IF NOT EXISTS ix_tci_busca_trgm ON tenant_catalogo.insumos     USING GIN (ins_busca catalogo.gin_trgm_ops);
CREATE INDEX IF NOT EXISTS ix_tcc_busca_trgm ON tenant_catalogo.composicoes USING GIN (cmp_busca catalogo.gin_trgm_ops);
