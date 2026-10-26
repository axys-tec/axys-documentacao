-- 2026-10-26_insumo_data_base.sql
--
-- Contrato: docs/projects/axys-easy/contracts/catalogo/identidade_fonte.md §4.6
--
-- Descrição: o preço de cada insumo no orçamento passa a guardar a sua DATA-BASE (o mês de quando é
--            aquele preço). Até aqui o orçamento sabia o valor e não sabia de quando: o insumo
--            próprio com "último preço registrado", o preço aplicado do histórico e a cotação feita
--            na bancada têm mês diferente do da edição declarada, e a tela Ver composição tem de
--            dizer qual (Renan, 26/10/2026).
--              - catálogo: o mês da edição de onde o preço veio;
--              - próprio: o mês da edição própria de onde o preço veio;
--              - cotação feita na bancada: o mês em que foi gravada.
--            Primeiro dia do mês. NULL = insumo sem preço.
--            A view do esparso ganha a coluna NO FIM (CREATE OR REPLACE só aceita coluna nova no fim).
--
-- Ordem: ADITIVA. Pode rodar antes do deploy. Depois dela, preencher as linhas que já existem:
--        z_scripts_apoio/manutencao/preencher_data_base_insumos.py [--prod]
--
-- Idempotente: ADD COLUMN IF NOT EXISTS; constraint em DO $$ … duplicate_object; CREATE OR REPLACE VIEW.
--
-- Rollback: recriar a view sem a coluna; ALTER TABLE ativo.ativo_orcamento_insumos_preco
--           DROP COLUMN IF EXISTS azp_data_base;
-- Data: 26/10/2026

ALTER TABLE ativo.ativo_orcamento_insumos_preco ADD COLUMN IF NOT EXISTS azp_data_base date;

DO $$ BEGIN
    ALTER TABLE ativo.ativo_orcamento_insumos_preco ADD CONSTRAINT ck_azp_data_base_mes
        CHECK (azp_data_base IS NULL OR azp_data_base = date_trunc('month', azp_data_base)::date);
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

CREATE OR REPLACE VIEW ativo.v_orcamento_insumo_preco AS
 SELECT DISTINCT ON (z.aoz_id, r.aor_id) r.aor_id,
    r.aor_num,
    z.aoz_ao_id,
    z.aoz_id,
    z.aoz_codigo,
    z.aoz_descricao,
    z.aoz_unidade,
    z.aoz_tipo,
    p.azp_valor AS valor,
    p.azp_data_base AS data_base
   FROM ativo.ativo_orcamento_insumos z
     JOIN ativo.ativo_orcamento_revisoes r ON r.aor_ao_id = z.aoz_ao_id
     JOIN ativo.ativo_orcamento_insumos_preco p ON p.azp_aoz_id = z.aoz_id
     JOIN ativo.ativo_orcamento_revisoes pr ON pr.aor_id = p.azp_aor_id AND pr.aor_num <= r.aor_num
  ORDER BY z.aoz_id, r.aor_id, pr.aor_num DESC;
