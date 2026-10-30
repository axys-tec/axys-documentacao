-- 2026-10-29 · catalogo.composicoes.cmp_descritivo perde o campo `modo`
-- Plano:    docs/projects/axys-easy/next-steps/final_associacoes.md §3 e §7 (IA_local extinto)
-- Contrato: docs/projects/axys-easy/contracts/catalogo/CTC_DESCRITIVO_FILL.md
--
-- O QUE MUDA. O descritivo tinha dois modos (`AXYS_CPU_DESC_MODO`): IA_local, que deixava a versão
-- nova `em_revisao` até alguém rodar get_md/put_md fora do app, e IA_auto, que preenchia no import.
-- Fica só o preenchimento no import (estágio Documentos), sem chave de modo. O campo `modo` que o
-- import gravava em cmp_descritivo não tem leitor; sai. O formato passa a ser {versoes:[...]}.
-- A origem de cada texto continua em versoes[].origem (IA_auto, IA_refino, IA_local nos antigos).
--
-- Só o catálogo. O `modo` de tenant_catalogo.composicoes e de ativo_orcamento_composicoes é outro
-- conceito (origem do texto no tenant: MANUAL/HERDADO/ORCAMENTO) e fica.
--
-- IDEMPOTENTE: só toca linha que ainda tem a chave.
--
--   psql "$EASY_DB_URL" -v ON_ERROR_STOP=1 -f docs/projects/axys-easy/schemas/migrations/2026-10-29_cmp_descritivo_sem_modo.sql

BEGIN;

UPDATE catalogo.composicoes
   SET cmp_descritivo = cmp_descritivo - 'modo'
 WHERE cmp_descritivo ? 'modo';

COMMIT;
