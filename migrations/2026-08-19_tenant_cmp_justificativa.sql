-- tenant_catalogo.composicoes: memorial da montagem (justificativa). Idempotente. Só tenant_catalogo.
ALTER TABLE tenant_catalogo.composicoes ADD COLUMN IF NOT EXISTS cmp_justificativa TEXT;
