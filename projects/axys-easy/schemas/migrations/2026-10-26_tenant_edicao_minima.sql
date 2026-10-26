-- 2026-10-26_tenant_edicao_minima.sql
--
-- Contrato: docs/projects/axys-easy/contracts/catalogo/identidade_fonte.md §3, §4, §5
-- Plano:    docs/projects/axys-easy/next-steps/bug2.md (passo 4, estágio A)
--
-- Descrição (Renan, 26/10/2026):
--   1. A EDIÇÃO PRÓPRIA passa a ser do TENANT, não da fonte, e mínima: só o mês. Edições de rótulos
--      diferentes no mesmo mês se fundem numa; os preços, os custos e a escolha do orçamento são
--      remapeados para a edição que fica. Saem a L.S. da edição (a MO própria leva a L.S. da
--      bancada) e o rótulo livre (a descrição deriva do mês).
--   2. O custo guardado da composição própria é UM só, SEM ENCARGOS (sai o par SD/CD, que trazia a
--      L.S. da edição). Fica NULL aqui: o recálculo é do app — rodar, depois desta migration,
--      z_scripts_apoio/manutencao/recalcular_custos_proprios.py.
--   3. O item da composição própria não congela mais a edição do filho (`ci_edi_id`): filho do
--      catálogo global usa a edição mais recente da fonte dele; filho próprio, a edição em questão.
--   4. No orçamento, a própria é UMA linha identificada pela ORIGEM (`opa_origem` = 'T'), não pelo
--      texto da fonte — o texto 'PROPRIA' × 'PRÓPRIA' foi o bug 2. A própria não converte L.S. nem
--      pode ser a favorita; a revisão que a tinha como favorita passa a favorita para a fonte do
--      catálogo com mais composições naquele orçamento. Ganha a flag `opa_propria_ultimo_preco`.
--   5. Tabela de DEPENDÊNCIAS entre edições do catálogo (fonte derivada: COMPESA 7/26 consome SICRO
--      4/26), criada VAZIA.
--
-- Ordem: junto com o código do estágio B em diante (a fusão de edições muda o que "edição da fonte"
--        significa para o código antigo). Depois dela, o recálculo de custos próprios.
--
-- Idempotente: cada bloco confere se já foi aplicado. Rodada duas vezes em dev, a segunda é no-op.
-- Falha alto: se um insumo tiver preço em duas edições que se fundiriam, RECUSA (nada é escolhido
-- em silêncio).
--
-- Rollback: não há automático — a fusão apaga edições. Restaurar do backup tirado antes.
-- Data: 26/10/2026

-- ── 1. Edição própria do tenant, só o mês ──
DO $$
DECLARE n INTEGER;
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                    WHERE table_schema = 'tenant_catalogo' AND table_name = 'edicoes'
                      AND column_name = 'edi_fte_id') THEN
        RETURN;   -- já aplicada
    END IF;

    -- a edição que fica em cada (tenant, mês): a ativa, a que um orçamento usa, a mais antiga
    CREATE TEMP TABLE _edi_mapa ON COMMIT DROP AS
    WITH e AS (
        SELECT e.edi_id, e.edi_tenant_uuid, date_trunc('month', e.edi_referencia)::date AS mes,
               e.edi_ativa,
               EXISTS (SELECT 1 FROM ativo.ativo_orcamento_parametros p
                        WHERE p.opa_tenant_edicao_id = e.edi_id) AS usada
          FROM tenant_catalogo.edicoes e
    )
    SELECT e.edi_id AS de,
           first_value(e.edi_id) OVER (PARTITION BY e.edi_tenant_uuid, e.mes
                                       ORDER BY e.edi_ativa DESC, e.usada DESC, e.edi_id) AS para,
           e.mes,
           bool_or(e.edi_ativa) OVER (PARTITION BY e.edi_tenant_uuid, e.mes) AS ativa
      FROM e;

    SELECT count(*) INTO n FROM (
        SELECT p.pri_ins_id, m.para FROM tenant_catalogo.insumos_preco p
          JOIN _edi_mapa m ON m.de = p.pri_edi_id GROUP BY 1, 2 HAVING count(*) > 1) x;
    IF n > 0 THEN
        RAISE EXCEPTION 'Fusão de edições próprias recusada: % insumo(s) com preço em duas edições do mesmo mês.', n;
    END IF;
    SELECT count(*) INTO n FROM (
        SELECT c.cc_cmp_id, m.para FROM tenant_catalogo.composicoes_custo c
          JOIN _edi_mapa m ON m.de = c.cc_edi_id GROUP BY 1, 2 HAVING count(*) > 1) x;
    IF n > 0 THEN
        RAISE EXCEPTION 'Fusão de edições próprias recusada: % composição(ões) com custo em duas edições do mesmo mês.', n;
    END IF;

    UPDATE tenant_catalogo.insumos_preco p SET pri_edi_id = m.para
      FROM _edi_mapa m WHERE m.de = p.pri_edi_id AND m.de <> m.para;
    UPDATE tenant_catalogo.composicoes_custo c SET cc_edi_id = m.para
      FROM _edi_mapa m WHERE m.de = c.cc_edi_id AND m.de <> m.para;
    UPDATE ativo.ativo_orcamento_parametros p SET opa_tenant_edicao_id = m.para
      FROM _edi_mapa m WHERE m.de = p.opa_tenant_edicao_id AND m.de <> m.para;
    DELETE FROM tenant_catalogo.edicoes e USING _edi_mapa m WHERE m.de = e.edi_id AND m.de <> m.para;
    UPDATE tenant_catalogo.edicoes e SET edi_referencia = m.mes, edi_ativa = m.ativa
      FROM _edi_mapa m WHERE m.de = e.edi_id AND m.de = m.para;

    ALTER TABLE tenant_catalogo.edicoes DROP CONSTRAINT IF EXISTS uq_tce_fte_ref;
    ALTER TABLE tenant_catalogo.edicoes DROP CONSTRAINT IF EXISTS fk_tce_fte;
    DROP INDEX IF EXISTS tenant_catalogo.ix_tce_fte;
    ALTER TABLE tenant_catalogo.edicoes
        DROP COLUMN edi_fte_id,
        DROP COLUMN IF EXISTS edi_codigo_versao,
        DROP COLUMN IF EXISTS edi_ls_horista_sd,
        DROP COLUMN IF EXISTS edi_ls_horista_cd;
END $$;

DO $$ BEGIN
    ALTER TABLE tenant_catalogo.edicoes
        ADD CONSTRAINT uq_tce_tenant_mes UNIQUE (edi_tenant_uuid, edi_referencia);
EXCEPTION WHEN duplicate_object OR duplicate_table THEN NULL; END $$;
DO $$ BEGIN
    ALTER TABLE tenant_catalogo.edicoes
        ADD CONSTRAINT ck_tce_mes CHECK (edi_referencia = date_trunc('month', edi_referencia)::date);
EXCEPTION WHEN duplicate_object THEN NULL; END $$;
CREATE INDEX IF NOT EXISTS ix_tce_tenant_mes ON tenant_catalogo.edicoes (edi_tenant_uuid, edi_referencia DESC);

-- ── 2. Custo da composição própria: um só, sem encargos (o recálculo é do app) ──
ALTER TABLE tenant_catalogo.composicoes_custo ADD COLUMN IF NOT EXISTS cc_custo NUMERIC(14,2);
ALTER TABLE tenant_catalogo.composicoes_custo
    DROP COLUMN IF EXISTS cc_custo_sd,
    DROP COLUMN IF EXISTS cc_custo_cd;

-- ── 3. O item da própria não congela a edição do filho ──
ALTER TABLE tenant_catalogo.composicoes_itens DROP COLUMN IF EXISTS ci_edi_id;

-- ── 4. No orçamento, a própria é identificada pela ORIGEM ──
ALTER TABLE ativo.ativo_orcamento_parametros
    ADD COLUMN IF NOT EXISTS opa_origem CHAR(1) NOT NULL DEFAULT 'C';
DO $$ BEGIN
    ALTER TABLE ativo.ativo_orcamento_parametros
        ADD CONSTRAINT ck_ao_opa_origem CHECK (opa_origem IN ('C', 'T'));
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

UPDATE ativo.ativo_orcamento_parametros
   SET opa_origem = 'T', opa_fonte = 'PRÓPRIA', opa_converter_ls = FALSE
 WHERE opa_tenant_edicao_id IS NOT NULL
   AND (opa_origem <> 'T' OR opa_fonte <> 'PRÓPRIA' OR opa_converter_ls);

-- a própria não é favorita: a favorita vai para a fonte do catálogo com mais composições no orçamento
WITH fav_t AS (
    SELECT p.opa_id, p.opa_aor_id FROM ativo.ativo_orcamento_parametros p
     WHERE p.opa_default AND p.opa_origem = 'T'
), alvo AS (
    SELECT DISTINCT ON (f.opa_aor_id) f.opa_aor_id, c.opa_id
      FROM fav_t f
      JOIN ativo.ativo_orcamento_parametros c ON c.opa_aor_id = f.opa_aor_id AND c.opa_origem = 'C'
      JOIN ativo.ativo_orcamento_revisoes r ON r.aor_id = f.opa_aor_id
      LEFT JOIN ativo.ativo_orcamento_composicoes k
             ON k.aoc_ao_id = r.aor_ao_id AND k.aoc_origem = 'C'
            AND upper(k.aoc_fonte) = upper(c.opa_fonte)
     GROUP BY f.opa_aor_id, c.opa_id
     ORDER BY f.opa_aor_id, count(k.aoc_id) DESC, c.opa_id
), tira AS (
    UPDATE ativo.ativo_orcamento_parametros p SET opa_default = FALSE
      FROM fav_t f WHERE p.opa_id = f.opa_id
    RETURNING p.opa_aor_id
)
UPDATE ativo.ativo_orcamento_parametros p SET opa_default = TRUE
  FROM alvo a WHERE p.opa_id = a.opa_id AND a.opa_aor_id IN (SELECT opa_aor_id FROM tira);

DO $$ BEGIN
    ALTER TABLE ativo.ativo_orcamento_parametros
        ADD CONSTRAINT ck_ao_opa_propria CHECK (
            opa_origem = 'C' AND opa_tenant_edicao_id IS NULL
         OR opa_origem = 'T' AND opa_edicao_id IS NULL AND NOT opa_default AND NOT opa_converter_ls);
EXCEPTION WHEN duplicate_object THEN NULL; END $$;
CREATE UNIQUE INDEX IF NOT EXISTS uq_ao_opa_uma_propria
    ON ativo.ativo_orcamento_parametros (opa_aor_id) WHERE opa_origem = 'T';

-- A flag da linha PRÓPRIA (Renan, 26/10/2026): sem preço do insumo na edição própria declarada, usar o
-- ÚLTIMO PREÇO REGISTRADO até o mês dela (nunca de mês posterior). Desligada (padrão): o insumo entra
-- sem preço e a composição que o usa, sem custo — nada some em silêncio, a menos que o usuário queira.
ALTER TABLE ativo.ativo_orcamento_parametros
    ADD COLUMN IF NOT EXISTS opa_propria_ultimo_preco BOOLEAN NOT NULL DEFAULT FALSE;
DO $$ BEGIN
    ALTER TABLE ativo.ativo_orcamento_parametros
        ADD CONSTRAINT ck_ao_opa_ultimo_preco CHECK (opa_origem = 'T' OR NOT opa_propria_ultimo_preco);
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

-- ── 5. Dependências entre edições do catálogo (fonte derivada) — vazia ──
CREATE TABLE IF NOT EXISTS catalogo.edicoes_dependencias (
    edd_id            INTEGER GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    edd_edi_id        INTEGER NOT NULL,   -- a edição da fonte DERIVADA (ex.: COMPESA 7/26)
    edd_edi_id_base   INTEGER NOT NULL,   -- a edição de outra fonte que ela consome (ex.: SICRO 4/26)
    edd_criado_em     TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    edd_criado_por    TEXT,
    CONSTRAINT fk_edd_edi      FOREIGN KEY (edd_edi_id)      REFERENCES catalogo.edicoes (edi_id)
        ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_edd_edi_base FOREIGN KEY (edd_edi_id_base) REFERENCES catalogo.edicoes (edi_id)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT uq_edd UNIQUE (edd_edi_id, edd_edi_id_base),
    CONSTRAINT ck_edd_outra CHECK (edd_edi_id <> edd_edi_id_base)
);
