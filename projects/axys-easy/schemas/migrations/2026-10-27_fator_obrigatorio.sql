-- 2026-10-27_fator_obrigatorio.sql
--
-- Contrato: docs/projects/axys-easy/contracts/catalogo/vinculacoes.md §3.4 · "Classes de conversão"
--
-- Descrição: o fator de conversão de catalogo.equivalencias_ins / _cpu passa a ser OBRIGATÓRIO e
--            positivo. Sem fator não é associação: associação responde "tanto faz" (trocar um pelo
--            outro não muda a obra); item que depende de quantificar (limpeza por m² × por un) não
--            se associa (Renan, 27/10/2026). A curadoria já recusa (_grava_par); o banco passa a
--            recusar também.
--
-- Ordem: ADITIVA. Pode rodar antes do deploy. Falha (de propósito) se houver par com fator nulo
--        ou ≤ 0 — conferir antes: dev tinha 0 de 2.227 pares.
--
-- Idempotente: SET NOT NULL é no-op quando já vale; constraint em DO $$ … duplicate_object.
--
-- Rollback: ALTER TABLE … ALTER COLUMN …_fator_conversao DROP NOT NULL;
--           ALTER TABLE … DROP CONSTRAINT IF EXISTS ck_ei_fator / ck_ec_fator;
-- Data: 27/10/2026

ALTER TABLE catalogo.equivalencias_ins ALTER COLUMN ei_fator_conversao SET NOT NULL;
ALTER TABLE catalogo.equivalencias_cpu ALTER COLUMN ec_fator_conversao SET NOT NULL;

DO $$ BEGIN
    ALTER TABLE catalogo.equivalencias_ins ADD CONSTRAINT ck_ei_fator CHECK (ei_fator_conversao > 0);
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
    ALTER TABLE catalogo.equivalencias_cpu ADD CONSTRAINT ck_ec_fator CHECK (ec_fator_conversao > 0);
EXCEPTION WHEN duplicate_object THEN NULL; END $$;
