-- Migration PROD/HOMOLOG: flags de conversão por fonte — SÓ no nível ATIVO (orcamento_parametros).
-- Contexto: R3 do ringue de conversão inter-fontes. As flags são por-linha (por-fonte), persistidas,
-- e reprocessam o orçamento ao vivo. REG = regime mensalista (SINAPI-exclusivo, auto pelo ativo_ls).
--
-- Decisão 2026-08-13 (Renan): a CONVERSÃO (LS/MDO/INS/REG) é decisão de execução POR-ATIVO — depende
-- do ativo_ls (regime/LS) e da fonte favorita do ativo. O empreendimento carrega SÓ a IDENTIDADE da
-- fonte-base (fonte/edição/UF/modalidade/★). Logo, as flags NÃO se replicam no nível empreendimento:
-- ficam só em orcamento_parametros e as epa_converter_* são removidas (a v1 desta migration as criou;
-- a epa_converter_ls era pré-existente). Idempotente — rodar UMA vez em cada banco.
-- Dev: schema.sql é a foto (já sem as epa_converter_*).

-- 1) ATIVO: as 3 flags novas (opa_converter_ls já existia)
ALTER TABLE ativo.orcamento_parametros
  ADD COLUMN IF NOT EXISTS opa_converter_mdo BOOLEAN NOT NULL DEFAULT FALSE,
  ADD COLUMN IF NOT EXISTS opa_converter_ins BOOLEAN NOT NULL DEFAULT FALSE,
  ADD COLUMN IF NOT EXISTS opa_converter_reg BOOLEAN NOT NULL DEFAULT FALSE;

-- 2) EMPREENDIMENTO: conversão NÃO vive aqui → remove as 4 (idempotente)
ALTER TABLE ativo.empreendimento_parametros
  DROP COLUMN IF EXISTS epa_converter_ls,
  DROP COLUMN IF EXISTS epa_converter_mdo,
  DROP COLUMN IF EXISTS epa_converter_ins,
  DROP COLUMN IF EXISTS epa_converter_reg;
