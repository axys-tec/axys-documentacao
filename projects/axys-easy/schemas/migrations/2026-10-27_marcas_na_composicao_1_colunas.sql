-- 2026-10-27_marcas_na_composicao_1_colunas.sql
--
-- Contrato: docs/projects/axys-easy/contracts/ativo/EASY_ATIVO_CONTRATO.md §6.3 e §8 (v1.4)
--
-- Descrição: as MARCAS da conversão (REG/LS/⚠, divisor aplicado, INF…) e a L.S. com que a
--            composição foi calculada passam a morar NA COMPOSIÇÃO do orçamento, junto do custo
--            (ativo_orcamento_composicoes_custo), e não no item — o mesmo mal do custo copiado
--            (Renan, 27/10/2026). Parte 1 de 2: cria as colunas e as preenche a partir dos itens.
--            Entre irmãos as marcas batiam em prod (27/10); só o regime divergia, vazio × H em 66
--            composições — fica o preenchido (item mais recente, e o que tem o registro do divisor).
--
-- Ordem: ANTES do deploy (o código novo grava nestas colunas). Aditiva: o código antigo as ignora.
--        A parte 2 (trava + limpeza do item) vai DEPOIS do deploy.
--
-- Idempotente: ADD COLUMN IF NOT EXISTS; constraints em DO $$ … duplicate_object; o preenchimento
--              só toca registro ainda vazio.
--
-- Rollback: ALTER TABLE ativo.ativo_orcamento_composicoes_custo
--             DROP COLUMN IF EXISTS acc_marcas, DROP COLUMN IF EXISTS acc_ls_regime, DROP COLUMN IF EXISTS acc_ls_percent;
-- Data: 27/10/2026

ALTER TABLE ativo.ativo_orcamento_composicoes_custo
    ADD COLUMN IF NOT EXISTS acc_marcas jsonb,
    ADD COLUMN IF NOT EXISTS acc_ls_regime character(1),
    ADD COLUMN IF NOT EXISTS acc_ls_percent numeric(7,4);

DO $$ BEGIN
    ALTER TABLE ativo.ativo_orcamento_composicoes_custo
      ADD CONSTRAINT ck_acc_marcas_obj CHECK ((acc_marcas IS NULL) OR (jsonb_typeof(acc_marcas) = 'object'));
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
    ALTER TABLE ativo.ativo_orcamento_composicoes_custo
      ADD CONSTRAINT ck_acc_ls_regime CHECK ((acc_ls_regime IS NULL) OR (acc_ls_regime = ANY (ARRAY['H'::bpchar, 'M'::bpchar])));
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

UPDATE ativo.ativo_orcamento_composicoes_custo cc
       SET acc_marcas = NULLIF(src.marcas, '{}'::jsonb), acc_ls_regime = src.regime, acc_ls_percent = src.pct
      FROM (SELECT DISTINCT ON (i.ati_aor_id, i.ati_cmp_id)
                   i.ati_aor_id AS aor, i.ati_cmp_id AS aoc,
                   (SELECT COALESCE(jsonb_object_agg(k, v), '{}'::jsonb)
                      FROM jsonb_each(COALESCE(i.ati_meta_json, '{}'::jsonb)) e(k, v)
                     WHERE k IN ('mdo_estado','mo_qtd_alerta','mo_encarece','mo_base','conv','mdo_div',
                                 'cmp_descontinuada','custo_nao_recalculado')) AS marcas,
                   i.ati_ls_regime AS regime, i.ati_ls_percent AS pct
              FROM ativo.ativo_orcamento_itens i
             WHERE i.ati_tipo = 'SERVIÇO' AND i.ati_cmp_id IS NOT NULL AND NOT i.ati_preco_fixado
             ORDER BY i.ati_aor_id, i.ati_cmp_id, (i.ati_ls_regime IS NULL),
                      (COALESCE(i.ati_meta_json, '{}'::jsonb) ? 'mdo_div') DESC, i.ati_id DESC) src
     WHERE cc.acc_aor_id = src.aor AND cc.acc_aoc_id = src.aoc
       AND cc.acc_marcas IS NULL AND cc.acc_ls_regime IS NULL AND cc.acc_ls_percent IS NULL;
