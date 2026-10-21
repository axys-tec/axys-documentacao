-- tenant_catalogo — estado ativo/inativo UNIFORME + soft-delete guardado por dependentes.
-- Remove o enum edi_situacao (não há rascunho/publicada no universo próprio) e adiciona
-- edi_ativa/ins_ativo/cmp_ativa (fte_ativa já existia). Idempotente.
-- Contrato: docs/projects/axys-easy/contracts/catalogo/TENANT_CATALOGO_PROPOSTA.md

ALTER TABLE tenant_catalogo.edicoes     DROP CONSTRAINT IF EXISTS ck_tce_situacao;
ALTER TABLE tenant_catalogo.edicoes     ADD  COLUMN IF NOT EXISTS edi_ativa BOOLEAN NOT NULL DEFAULT TRUE;
ALTER TABLE tenant_catalogo.edicoes     DROP COLUMN IF EXISTS edi_situacao;
ALTER TABLE tenant_catalogo.insumos     ADD  COLUMN IF NOT EXISTS ins_ativo BOOLEAN NOT NULL DEFAULT TRUE;
ALTER TABLE tenant_catalogo.composicoes ADD  COLUMN IF NOT EXISTS cmp_ativa BOOLEAN NOT NULL DEFAULT TRUE;

-- L.S. horista da edição por regime SD/CD (substitui o edi_ls_horista único).
ALTER TABLE tenant_catalogo.edicoes     ADD  COLUMN IF NOT EXISTS edi_ls_horista_sd NUMERIC(8,4);
ALTER TABLE tenant_catalogo.edicoes     ADD  COLUMN IF NOT EXISTS edi_ls_horista_cd NUMERIC(8,4);
ALTER TABLE tenant_catalogo.edicoes     DROP COLUMN IF EXISTS edi_ls_horista;
