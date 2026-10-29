-- 2026-10-28 · ids da composição em BIGINT
-- Contrato: docs/projects/axys-easy/contracts/ativo/EASY_ATIVO_CONTRATO.md (família ativo_orcamento_*)
--
-- O QUE MUDA. `aoc_id` (a composição do orçamento) é BIGINT, e as duas colunas que apontam para ele
-- eram INTEGER: `ativo_orcamento_itens.ati_cmp_id` (o item → a composição dele) e
-- `ativo_orcamento_composicoes_itens.aci_aoc_id` (a linha → a composição dona). As outras FKs para
-- composição e insumo (`acc_aoc_id`, `aci_cmp_filho_id`, `aci_ins_id`, `azp_aoz_id`, `aot_aoz_id`) já
-- eram BIGINT. `ati_id` fica INTEGER: ele e tudo o que aponta para ele são INTEGER, sem descompasso.
--
-- POR QUÊ AGORA. Com as tabelas pequenas (28/10: 2.647 itens, 6.895 linhas de composição) o ALTER
-- reescreve em segundos; depois, é janela de manutenção. E o dia em que `aoc_id` passasse de 2^31,
-- a FK aceitaria o pai e recusaria o filho.
--
-- A VIEW. `v_compat_ativo_itens` lê `ati_cmp_id` e trava o ALTER TYPE: sai antes e volta igual,
-- recriada pelo dono (só ele tem privilégio nela — conferido em dev e em prod).
--
-- IDEMPOTENTE: só mexe se a coluna ainda é INTEGER; a view é CREATE OR REPLACE com a mesma definição.
--
--   psql "$EASY_DB_URL" -v ON_ERROR_STOP=1 -f docs/projects/axys-easy/schemas/migrations/2026-10-28_ids_da_composicao_bigint.sql

BEGIN;

DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.columns
                WHERE table_schema = 'ativo'
                  AND ((table_name = 'ativo_orcamento_itens' AND column_name = 'ati_cmp_id')
                    OR (table_name = 'ativo_orcamento_composicoes_itens' AND column_name = 'aci_aoc_id'))
                  AND data_type = 'integer') THEN
        DROP VIEW IF EXISTS ativo.v_compat_ativo_itens;
        ALTER TABLE ativo.ativo_orcamento_itens             ALTER COLUMN ati_cmp_id TYPE bigint;
        ALTER TABLE ativo.ativo_orcamento_composicoes_itens ALTER COLUMN aci_aoc_id TYPE bigint;
    END IF;
END $$;

CREATE OR REPLACE VIEW ativo.v_compat_ativo_itens AS
SELECT i.ati_id,
       o.ao_atv_id              AS ati_atv_id,     -- era o dono; hoje vem pela revisão
       i.ati_num, i.ati_parent_id, i.ati_ordem, i.ati_path, i.ati_tipo, i.ati_descricao,
       CASE c.aoc_origem WHEN 'C' THEN 'CATALOGO' WHEN 'T' THEN 'TENANT' END
                                AS ati_cmp_origem, -- reconstruída: mora na composição
       c.aoc_cmp_id_origem      AS ati_cmp_id,     -- o id NA ORIGEM, como a app espera
       -- o preço do item é o custo da composição; só o FIXADO guarda valor no item (orcamento_fonte.custo_item_sql)
       (CASE WHEN i.ati_preco_fixado THEN i.ati_custo_unit ELSE cc.acc_valor END)::numeric(14,2) AS ati_custo_unit,
       i.ati_quantidade, i.ati_unidade, i.ati_bdi_id, i.ati_ajuste_json,
       i.ati_have_memory_calc, i.ati_preco_fixado, i.ati_is_alo, i.ati_regras_json,
       -- as marcas da conversão são da composição; o fixado não tem marca (orcamento_fonte.meta_item_sql)
       (COALESCE(i.ati_meta_json, '{}'::jsonb)
          || CASE WHEN i.ati_preco_fixado THEN '{}'::jsonb ELSE COALESCE(cc.acc_marcas, '{}'::jsonb) END) AS ati_meta_json,
       i.ati_criado_em, i.ati_atualizado_em, i.ati_criado_por, i.ati_atualizado_por,
       -- as de verdade do schema novo, para quem souber usá-las
       i.ati_aor_id, i.ati_cmp_id AS ati_aoc_id, c.aoc_desc_alterada,
       (CASE WHEN i.ati_preco_fixado THEN NULL ELSE cc.acc_ls_regime END)::character(1) AS ati_ls_regime,
       (CASE WHEN i.ati_preco_fixado THEN NULL ELSE cc.acc_ls_percent END)::numeric(7,4) AS ati_ls_percent
  FROM ativo.ativo_orcamento_itens i
  JOIN ativo.ativo_orcamento_revisoes r ON r.aor_id = i.ati_aor_id AND r.aor_vigente
  JOIN ativo.ativo_orcamento o ON o.ao_id = r.aor_ao_id
  LEFT JOIN ativo.ativo_orcamento_composicoes c ON c.aoc_id = i.ati_cmp_id
  LEFT JOIN ativo.ativo_orcamento_composicoes_custo cc ON cc.acc_aoc_id = i.ati_cmp_id AND cc.acc_aor_id = i.ati_aor_id;

COMMIT;
