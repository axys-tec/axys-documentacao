-- 2026-10-20_aoc_descritivo.sql
--
-- Descrição: o DESCRITIVO da composição passa a poder ser editado NO ORÇAMENTO (forma de medição,
--            o que remunera e — quando a composição é própria — a justificativa). NULL = herda do
--            catálogo / da própria, como sempre foi. Editado = vale só neste orçamento e é o que o
--            Caderno de Encargos imprime. Decisão do Renan, 2026-10-20 (EASY_MCP_CONTRATO.md §4.5).
--
-- Forma: `aoc_descritivo` repete a de catalogo.composicoes.cmp_descritivo ({modo, versoes:[…]});
--        `aoc_justificativa` repete tenant_catalogo.composicoes.cmp_justificativa.
--
-- Ordem: ADITIVA (colunas anuláveis, sem default). Pode rodar antes do deploy: o código antigo não
--        lê as colunas; o novo trata NULL como "herda".
--
-- Rollback: ALTER TABLE ativo.ativo_orcamento_composicoes DROP COLUMN aoc_descritivo,
--                                                         DROP COLUMN aoc_justificativa;
-- Data: 20/10/2026

ALTER TABLE ativo.ativo_orcamento_composicoes
  ADD COLUMN IF NOT EXISTS aoc_descritivo JSONB,
  ADD COLUMN IF NOT EXISTS aoc_justificativa TEXT;
