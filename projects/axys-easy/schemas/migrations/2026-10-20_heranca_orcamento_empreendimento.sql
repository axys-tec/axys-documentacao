-- Herança de orçamento por empreendimento (opt-in por pauta) — PROD.
-- Contrato: docs/projects/axys-easy/contracts/HERANCA_ORCAMENTO_EMPREENDIMENTO.md
-- Idempotente. Nasce FALSE (dados de hoje seguros); o cadastro de empreendimento novo grava TRUE.
-- Passo 1 de N (só as flags). O portador de config do empreendimento + resolvers vêm nos próximos passos.

ALTER TABLE ativo.empreendimentos
    ADD COLUMN IF NOT EXISTS emp_fontes_unica boolean NOT NULL DEFAULT false,
    ADD COLUMN IF NOT EXISTS emp_bdi_unico    boolean NOT NULL DEFAULT false,
    ADD COLUMN IF NOT EXISTS emp_ls_unico     boolean NOT NULL DEFAULT false;

-- Portador de config do empreendimento: o orçamento passa a poder ser de ATIVO ou de EMPREENDIMENTO.
-- Aditivo/seguro: linhas de hoje têm ao_atv_id preenchido e ao_emp_id NULL → passam no CHECK.
ALTER TABLE ativo.ativo_orcamento ALTER COLUMN ao_atv_id DROP NOT NULL;
ALTER TABLE ativo.ativo_orcamento ADD COLUMN IF NOT EXISTS ao_emp_id integer;
DO $$ BEGIN
    ALTER TABLE ativo.ativo_orcamento ADD CONSTRAINT fk_ao_emp
        FOREIGN KEY (ao_emp_id) REFERENCES ativo.empreendimentos(emp_id) ON DELETE CASCADE;
EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN
    ALTER TABLE ativo.ativo_orcamento ADD CONSTRAINT ck_ao_escopo
        CHECK ((ao_atv_id IS NOT NULL) <> (ao_emp_id IS NOT NULL));
EXCEPTION WHEN duplicate_object THEN NULL; END $$;
CREATE UNIQUE INDEX IF NOT EXISTS uq_ao_emp ON ativo.ativo_orcamento (ao_emp_id) WHERE ao_emp_id IS NOT NULL;
