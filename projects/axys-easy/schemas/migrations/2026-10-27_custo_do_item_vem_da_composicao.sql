-- 2026-10-27_custo_do_item_vem_da_composicao.sql
--
-- Contrato: docs/projects/axys-easy/contracts/ativo/EASY_ATIVO_CONTRATO.md §6.3 e §8 (v1.3)
--
-- Descrição: o preço de todo item da bancada é o custo da SUA composição (Renan, 27/10/2026).
--            O custo mora na composição do orçamento (ativo_orcamento_composicoes_custo.acc_valor);
--            o item só guarda valor quando o preço é FIXADO à mão. A cópia no item quebrava em
--            silêncio: a composição mudava de custo e o item ficava para trás (ativo 35, C-000089:
--            12 serviços a 0,00 com a composição a 244,44).
--
--            1. confere: item não fixado cujo valor difere do custo da composição → ABORTA e lista
--               (zerar a cópia mudaria o preço apresentado; recapturar antes —
--               z_scripts_apoio/manutencao/recapturar_analitico.py);
--            2. zera a cópia nos itens não fixados;
--            3. trava ck_ati_custo_so_fixado (valor no item só com preço fixado);
--            4. a view v_compat_ativo_itens passa a entregar o custo da composição.
--
-- Ordem: DEPOIS do deploy. O código novo lê o custo da composição e não grava mais a cópia; o
--        antigo ainda grava, e a trava o derrubaria.
--
-- Idempotente: na segunda vez não há cópia a zerar, a trava já existe (duplicate_object) e a view
--              é CREATE OR REPLACE com as mesmas colunas.
--
-- Rollback: ALTER TABLE ativo.ativo_orcamento_itens DROP CONSTRAINT IF EXISTS ck_ati_custo_so_fixado;
--           UPDATE ativo.ativo_orcamento_itens i SET ati_custo_unit = cc.acc_valor
--             FROM ativo.ativo_orcamento_composicoes_custo cc
--            WHERE NOT i.ati_preco_fixado AND cc.acc_aoc_id = i.ati_cmp_id AND cc.acc_aor_id = i.ati_aor_id;
--           e a view anterior (i.ati_custo_unit cru).
-- Data: 27/10/2026

DO $$
DECLARE
    n   integer;
    lst text;
BEGIN
    SELECT count(*), string_agg(format('ati %s: item %s × composição %s', i.ati_id, i.ati_custo_unit, cc.acc_valor),
                                '; ' ORDER BY i.ati_id)
      INTO n, lst
      FROM ativo.ativo_orcamento_itens i
      LEFT JOIN ativo.ativo_orcamento_composicoes_custo cc
             ON cc.acc_aoc_id = i.ati_cmp_id AND cc.acc_aor_id = i.ati_aor_id
     WHERE NOT i.ati_preco_fixado
       AND i.ati_custo_unit IS NOT NULL
       AND i.ati_custo_unit IS DISTINCT FROM cc.acc_valor;
    IF n > 0 THEN
        RAISE EXCEPTION 'custo do item difere do da composição em % item(ns): %', n, left(lst, 2000);
    END IF;
END $$;

UPDATE ativo.ativo_orcamento_itens
   SET ati_custo_unit = NULL
 WHERE NOT ati_preco_fixado AND ati_custo_unit IS NOT NULL;

DO $$ BEGIN
    ALTER TABLE ativo.ativo_orcamento_itens
      ADD CONSTRAINT ck_ati_custo_so_fixado CHECK (ati_custo_unit IS NULL OR ati_preco_fixado);
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

CREATE OR REPLACE VIEW ativo.v_compat_ativo_itens AS
SELECT i.ati_id,
       o.ao_atv_id              AS ati_atv_id,     -- era o dono; hoje vem pela revisão
       i.ati_num, i.ati_parent_id, i.ati_ordem, i.ati_path, i.ati_tipo, i.ati_descricao,
       CASE c.aoc_origem WHEN 'C' THEN 'CATALOGO' WHEN 'T' THEN 'TENANT' END
                                AS ati_cmp_origem, -- reconstruída: mora na composição
       c.aoc_cmp_id_origem      AS ati_cmp_id,     -- o id NA ORIGEM, como a app espera
       -- o preço do item é o custo da composição; só o FIXADO guarda valor no item (orcamento_fonte.custo_item_sql)
       (CASE WHEN i.ati_preco_fixado THEN i.ati_custo_unit
             ELSE (SELECT cc.acc_valor FROM ativo.ativo_orcamento_composicoes_custo cc
                    WHERE cc.acc_aoc_id = i.ati_cmp_id AND cc.acc_aor_id = i.ati_aor_id) END)::numeric(14,2) AS ati_custo_unit,
       i.ati_quantidade, i.ati_unidade, i.ati_bdi_id, i.ati_ajuste_json,
       i.ati_have_memory_calc, i.ati_preco_fixado, i.ati_is_alo, i.ati_regras_json, i.ati_meta_json,
       i.ati_criado_em, i.ati_atualizado_em, i.ati_criado_por, i.ati_atualizado_por,
       -- as de verdade do schema novo, para quem souber usá-las
       i.ati_aor_id, i.ati_cmp_id AS ati_aoc_id, c.aoc_desc_alterada, i.ati_ls_regime, i.ati_ls_percent
  FROM ativo.ativo_orcamento_itens i
  JOIN ativo.ativo_orcamento_revisoes r ON r.aor_id = i.ati_aor_id AND r.aor_vigente
  JOIN ativo.ativo_orcamento o ON o.ao_id = r.aor_ao_id
  LEFT JOIN ativo.ativo_orcamento_composicoes c ON c.aoc_id = i.ati_cmp_id;
