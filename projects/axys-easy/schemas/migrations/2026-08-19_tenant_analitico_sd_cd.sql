-- tenant_catalogo — analítico da composição: edição de precificação por item + custo por regime SD/CD.
-- composicoes_itens.ci_edi_id: edição do filho p/ preço (polimórfica por ci_ref_origem: catalogo|tenant).
-- composicoes_custo: cc_custo (único) → cc_custo_sd + cc_custo_cd. Tabelas vazias. Idempotente.
ALTER TABLE tenant_catalogo.composicoes_itens ADD COLUMN IF NOT EXISTS ci_edi_id INTEGER;
ALTER TABLE tenant_catalogo.composicoes_custo  ADD COLUMN IF NOT EXISTS cc_custo_sd NUMERIC(14,2);
ALTER TABLE tenant_catalogo.composicoes_custo  ADD COLUMN IF NOT EXISTS cc_custo_cd NUMERIC(14,2);
ALTER TABLE tenant_catalogo.composicoes_custo  DROP COLUMN IF EXISTS cc_custo;
