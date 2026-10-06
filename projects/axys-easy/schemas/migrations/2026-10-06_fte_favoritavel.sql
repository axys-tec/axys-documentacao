-- 2026-10-06_fte_favoritavel.sql
--
-- Descrição: acrescenta `catalogo.fontes.fte_favoritavel`, que o schema.sql e o código já usavam
--            mas nunca foi aplicada em banco nenhum — `/fontes-base` estava QUEBRADA em dev e em
--            PRODUÇÃO com `UndefinedColumn: column f.fte_favoritavel does not exist`.
--
-- A coluna diz quais fontes PODEM ser escolhidas como favorita (não qual FOI escolhida — essa é
-- `ativo.orcamento_parametros.opa_default`). Default FALSE: ninguém vira favoritável sozinho.
--
-- Ordem: é ADITIVA e o código já espera a coluna, então aplicar CONSERTA o que está no ar. Pode
-- rodar antes do deploy sem risco.
--
-- Rollback: ALTER TABLE catalogo.fontes DROP COLUMN fte_favoritavel;
-- Data: 06/10/2026

ALTER TABLE catalogo.fontes
  ADD COLUMN IF NOT EXISTS fte_favoritavel BOOLEAN NOT NULL DEFAULT FALSE;
