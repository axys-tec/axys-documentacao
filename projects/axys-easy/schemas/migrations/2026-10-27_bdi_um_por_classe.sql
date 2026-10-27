-- 2026-10-27_bdi_um_por_classe.sql
--
-- Contrato: docs/projects/axys-easy/contracts/ativo/ (BDI por ativo — Acórdão 2622/2013)
--
-- Descrição: no máximo UM BDI por classe em cada revisão do orçamento — um NORMAL e um REDUZIDO.
--            Salvar a mesma classe sobrescreve (bdi_service._gravar_bdi). Até aqui o "novo BDI"
--            inseria outra linha da mesma classe, e o orçamento ficava com dois REDUZIDOS
--            (Renan, 27/10/2026: "é erro").
--            Duplicados existentes: fica o que está EM USO pelas linhas do orçamento (o mais usado);
--            se nenhum, o mais recente. As linhas que apontavam para os outros são repontadas para
--            o que fica; se um dos que saem era o default, o que fica herda o default.
--            (Dev em 27/10: revisões 5 e 45, REDUZIDO ×2, nenhum em uso.)
--
-- Ordem: pode rodar antes do deploy (o código antigo só falharia ao criar um 2º da mesma classe).
--
-- Idempotente: sem duplicados o bloco não toca nada; CREATE UNIQUE INDEX IF NOT EXISTS.
--
-- Rollback: DROP INDEX IF EXISTS ativo.uq_ao_abd_classe;  (os duplicados apagados não voltam)
-- Data: 27/10/2026

DO $$
DECLARE d RECORD;
BEGIN
    CREATE TEMP TABLE _abd_dup ON COMMIT DROP AS
    SELECT abd_id, abd_default,
           first_value(abd_id) OVER w AS fica,
           row_number()        OVER w AS rn
      FROM (SELECT b.abd_id, b.abd_aor_id, b.abd_classe, b.abd_default,
                   (SELECT count(*) FROM ativo.ativo_orcamento_itens i WHERE i.ati_bdi_id = b.abd_id) AS uso
              FROM ativo.ativo_orcamento_bdi b) x
    WINDOW w AS (PARTITION BY abd_aor_id, abd_classe ORDER BY uso DESC, abd_id DESC);

    FOR d IN SELECT abd_id, fica, abd_default FROM _abd_dup WHERE rn > 1 LOOP
        UPDATE ativo.ativo_orcamento_itens SET ati_bdi_id = d.fica WHERE ati_bdi_id = d.abd_id;
        DELETE FROM ativo.ativo_orcamento_bdi WHERE abd_id = d.abd_id;          -- cascade: composição
        IF d.abd_default THEN
            UPDATE ativo.ativo_orcamento_bdi SET abd_default = TRUE WHERE abd_id = d.fica;
        END IF;
        RAISE NOTICE 'BDI % removido (duplicado de %)', d.abd_id, d.fica;
    END LOOP;
END $$;

CREATE UNIQUE INDEX IF NOT EXISTS uq_ao_abd_classe ON ativo.ativo_orcamento_bdi USING btree (abd_aor_id, abd_classe);
