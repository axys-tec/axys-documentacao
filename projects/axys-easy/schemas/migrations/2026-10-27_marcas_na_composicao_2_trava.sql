-- 2026-10-27_marcas_na_composicao_2_trava.sql
--
-- Contrato: docs/projects/axys-easy/contracts/ativo/EASY_ATIVO_CONTRATO.md §6.3 e §8 (v1.4)
--
-- Descrição: parte 2 de 2 das marcas na composição. Repete o preenchimento (só o que ainda está
--            vazio), tira as marcas do ati_meta_json, cria a trava ck_ati_sem_marcas, a view
--            v_compat_ativo_itens passa a entregar marcas e L.S. da composição, e saem as colunas
--            ati_ls_regime / ati_ls_percent do item.
--
-- Ordem: DEPOIS do deploy (o código antigo grava as marcas no item e a trava o derrubaria) e
--        depois da parte 1.
--
-- Idempotente: o preenchimento só roda enquanto as colunas do item existem; a limpeza não acha o
--              que tirar na segunda vez; trava em DO $$ … duplicate_object; view CREATE OR REPLACE;
--              DROP COLUMN IF EXISTS.
--
-- Rollback: não há volta automática das colunas do item (a verdade passou a ser a composição);
--           ALTER TABLE ativo.ativo_orcamento_itens DROP CONSTRAINT IF EXISTS ck_ati_sem_marcas;
-- Data: 27/10/2026

DO $$ BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.columns
                WHERE table_schema = 'ativo' AND table_name = 'ativo_orcamento_itens' AND column_name = 'ati_ls_regime') THEN
        EXECUTE $q$ UPDATE ativo.ativo_orcamento_composicoes_custo cc
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
       AND cc.acc_marcas IS NULL AND cc.acc_ls_regime IS NULL AND cc.acc_ls_percent IS NULL $q$;
    END IF;
END $$;

UPDATE ativo.ativo_orcamento_itens
   SET ati_meta_json = NULLIF(ati_meta_json - ARRAY['mdo_estado','mo_qtd_alerta','mo_encarece','mo_base','conv','mdo_div',
                                                    'cmp_descontinuada','custo_nao_recalculado'], '{}'::jsonb)
 WHERE ati_meta_json ?| ARRAY['mdo_estado','mo_qtd_alerta','mo_encarece','mo_base','conv','mdo_div',
                              'cmp_descontinuada','custo_nao_recalculado'];

DO $$ BEGIN
    ALTER TABLE ativo.ativo_orcamento_itens
      ADD CONSTRAINT ck_ati_sem_marcas CHECK (NOT (COALESCE(ati_meta_json, '{}'::jsonb) ?| ARRAY['mdo_estado','mo_qtd_alerta',
          'mo_encarece','mo_base','conv','mdo_div','cmp_descontinuada','custo_nao_recalculado']));
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

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

ALTER TABLE ativo.ativo_orcamento_itens
    DROP COLUMN IF EXISTS ati_ls_regime,
    DROP COLUMN IF EXISTS ati_ls_percent;
