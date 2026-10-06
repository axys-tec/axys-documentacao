-- 2026-10-06_diversos_sem_ordem.sql
--
-- Descrição: remove `ccl_ordem`, `drt_ordem` e `prf_ordem`. A ordenação dessas três tabelas de
--            domínio passa a ser ALFABÉTICA pelo nome, que é como o usuário procura — e aí a
--            coluna de ordem deixa de servir para alguma coisa.
--
-- Eram usadas só em três ORDER BY do rt_service e no índice ix_prf_conselho. O índice é recriado
-- sobre (prf_conselho, prf_nome), que é a ordem nova.
--
-- Rollback: ADD COLUMN de volta com DEFAULT 0 — o conteúdo não se recupera, e não faz falta: era
-- uma numeração manual que ninguém mantinha.
-- Data: 06/10/2026

DROP INDEX IF EXISTS catalogo.ix_prf_conselho;

ALTER TABLE catalogo.conselhos_classe DROP COLUMN IF EXISTS ccl_ordem;
ALTER TABLE catalogo.doc_resp_tecnica DROP COLUMN IF EXISTS drt_ordem;
ALTER TABLE catalogo.profissoes       DROP COLUMN IF EXISTS prf_ordem;

CREATE INDEX IF NOT EXISTS ix_prf_conselho ON catalogo.profissoes (prf_conselho, prf_nome);
