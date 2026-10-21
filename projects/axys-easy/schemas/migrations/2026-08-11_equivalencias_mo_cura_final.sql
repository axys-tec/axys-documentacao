-- ============================================================
-- MIGRATION — curadoria final do equivalencias_mo (fonte MO ↔ SINAPI)
-- Data: 2026-08-11
--
-- Decisão do curador sobre as 75 propostas:
--   1) EXCLUIR as 2 equivalências ERRADAS (fuzzy sem sentido):
--        CDHU B.01.000.010198  TÉCNICO EQUIPAMENTOS INFORMÁTICA → SEGURANÇA DO TRABALHO
--        CDHU B.01.000.010197  OFICIAL DE ELETRIFICAÇÃO         → SERVENTE
--      (sem equivalência → essas funções caem em LSN/vermelho no mensalista, correto.)
--   2) CONFIRMAR todas as demais (58 exatas + 15 fuzzy plausíveis) → 73 confirmadas.
--
-- Self-contained (inclui o que o script 'confirma_exatas' fazia). Idempotente.
-- Não altera preço até o usuário ligar mensalista.
-- ============================================================

-- 1) Excluir as 2 erradas (pelo insumo-fonte)
DELETE FROM catalogo.equivalencias_mo em
 USING catalogo.insumos i
 WHERE i.ins_id = em.mo_fte_item_id
   AND upper(em.mo_fte_codigo) = 'CDHU'
   AND i.ins_codigo IN ('B.01.000.010198', 'B.01.000.010197');

-- 2) Confirmar todas as demais
UPDATE catalogo.equivalencias_mo
   SET mo_status         = 'confirmado',
       mo_atualizado_em  = now(),
       mo_atualizado_por = 'curadoria-mdo-2026-08-11'
 WHERE mo_status <> 'confirmado';

-- Conferência (opcional):
--   SELECT mo_status, count(*) FROM catalogo.equivalencias_mo GROUP BY mo_status;
--   -> esperado: confirmado 73  (e 0 pendente; 2 linhas removidas)
