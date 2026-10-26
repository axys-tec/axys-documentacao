-- 2026-10-26_fonte_perfil_bdi.sql
--
-- Contrato: docs/projects/axys-easy/contracts/catalogo/identidade_fonte.md §2.1
--
-- Descrição: dois comportamentos da fonte do catálogo global deixam de ser decididos pelo código
--            ('CDHU', 'FDE') e viram atributo (Renan, 26/10/2026):
--              - fte_perfil_arred: como a fonte arredonda — TRUNC (SINAPI), ROUND (CDHU),
--                CHEIA (FDE: unitário e linha cheios, total arredondado). Rege a reprodução do
--                import (o oráculo) e, nas telas de insumo, a MO com L.S.: ROUND arredonda, o resto
--                trunca — o que já era feito, agora escrito. A bancada não lê: trunca tudo.
--              - fte_preco_com_bdi: o preço publicado embute BDI (FDE) — a conferência e a
--                newsletter usam o custo limpo.
--            Nenhum número muda: os valores reproduzem o que o código fazia pelo nome.
--
-- Ordem: ADITIVA. Pode rodar antes do deploy (o código antigo ignora as colunas).
--
-- Idempotente: ADD COLUMN IF NOT EXISTS; constraint em DO $$ … duplicate_object; UPDATE por código
--              com o mesmo valor.
--
-- Rollback: ALTER TABLE catalogo.fontes DROP COLUMN IF EXISTS fte_perfil_arred,
--           DROP COLUMN IF EXISTS fte_preco_com_bdi;
-- Data: 26/10/2026

ALTER TABLE catalogo.fontes ADD COLUMN IF NOT EXISTS fte_perfil_arred TEXT NOT NULL DEFAULT 'ROUND';
ALTER TABLE catalogo.fontes ADD COLUMN IF NOT EXISTS fte_preco_com_bdi BOOLEAN NOT NULL DEFAULT FALSE;

DO $$ BEGIN
    ALTER TABLE catalogo.fontes ADD CONSTRAINT ck_fontes_perfil_arred
        CHECK (fte_perfil_arred IN ('TRUNC', 'ROUND', 'CHEIA'));
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

UPDATE catalogo.fontes SET fte_perfil_arred = 'TRUNC' WHERE fte_codigo = 'SINAPI' AND fte_perfil_arred <> 'TRUNC';
UPDATE catalogo.fontes SET fte_perfil_arred = 'CHEIA', fte_preco_com_bdi = TRUE
 WHERE fte_codigo = 'FDE' AND (fte_perfil_arred <> 'CHEIA' OR NOT fte_preco_com_bdi);
