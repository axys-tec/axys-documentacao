-- Fonte TENANT na config de fontes do ativo: guarda a edição-base da fonte tenant
-- (tenant_catalogo.edicoes; SEM FK física, padrão tenant). NULL para fonte de catálogo,
-- que segue em opa_edicao_id (FK catalogo.edicoes). Ver doutrina bancada TRUNC / integração tenant.
ALTER TABLE ativo.orcamento_parametros ADD COLUMN IF NOT EXISTS opa_tenant_edicao_id INTEGER;
