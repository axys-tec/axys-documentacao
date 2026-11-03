-- Contrato: contracts/ativo/pre_planejamento_execucao_contrato.md §17.4
-- Rascunho de trabalho por (ativo, assunto): o pré-planejamento deixa de guardar premissas e
-- sequência executiva no navegador e passa a guardá-las com o ativo.
-- Idempotente: em dev, onde a tabela já existe, é no-op completo.
BEGIN;

CREATE TABLE IF NOT EXISTS ativo.ativo_rascunhos (
    ras_atv_id          INTEGER NOT NULL,
    ras_assunto         TEXT    NOT NULL,
    ras_tenant_uuid     UUID    NOT NULL,
    ras_dados           JSONB   NOT NULL,
    ras_atualizado_por  TEXT,
    ras_atualizado_em   TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_ras PRIMARY KEY (ras_atv_id, ras_assunto)
);

DO $$ BEGIN
    ALTER TABLE ativo.ativo_rascunhos ADD CONSTRAINT fk_ras_atv
        FOREIGN KEY (ras_atv_id) REFERENCES ativo.ativos (atv_id) ON UPDATE CASCADE ON DELETE CASCADE;
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
    ALTER TABLE ativo.ativo_rascunhos ADD CONSTRAINT ck_ras_assunto
        CHECK (ras_assunto IN ('preplanejamento'));
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
    ALTER TABLE ativo.ativo_rascunhos ADD CONSTRAINT ck_ras_dados_obj
        CHECK (jsonb_typeof(ras_dados) = 'object');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

CREATE INDEX IF NOT EXISTS ix_ras_atualizado ON ativo.ativo_rascunhos (ras_atualizado_em);

COMMIT;
