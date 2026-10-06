-- 2026-10-06_uso_isolado_nome_da_casa.sql
--
-- Descrição: `audit.license_usage_event` → `audit.uso_isolado`, com colunas, constraints e índice
--            na convenção da casa (português, prefixo = conceito).
--
-- POR QUE AGORA
--   A tabela foi criada direto nos dois bancos pelo time do Hub, com nomes em inglês e sem
--   prefixo — fora do padrão de `audit.logs`/`audit.login_logs` e de todo o resto do schema. Está
--   VAZIA em dev e em produção, e o único arquivo que a referencia (`backend/core/licensing.py`)
--   não tem chamador: `consume_isolated_usage` não é invocado em lugar nenhum, porque Price e CPU
--   ainda não existem. Renomear hoje custa este arquivo; depois do primeiro evento gravado custa
--   migração de dado, janela e risco.
--
-- POR QUE RENAME E NÃO DROP+CREATE
--   RENAME preserva PK, UNIQUE, CHECKs, índice e defaults sem recriar nada e sem tocar linha. Um
--   drop+create seria mais código para chegar ao mesmo lugar, e com a chance de divergir do que o
--   banco tinha.
--
-- VALORES. `uso_sync` passa a falar a língua da casa: pending/confirmed/failed →
-- PENDENTE/CONFIRMADO/FALHOU. O UPDATE abaixo é no-op com a tabela vazia, e está aqui porque
-- migration que só funciona em banco vazio é migration que mente.
--
-- ORDEM. O código novo (`licensing.py` com os nomes novos) e esta migration precisam andar juntos.
-- Na prática nada quebra em qualquer ordem, porque não há chamador — mas a regra não se afrouxa
-- por isso: aplicar junto com o deploy.
--
-- Rollback: inverter os RENAMEs e devolver os valores em inglês (o arquivo é simétrico).
-- Data: 06/10/2026

DO $$
BEGIN
  IF to_regclass('audit.uso_isolado') IS NOT NULL THEN
    RAISE NOTICE 'audit.uso_isolado já existe — nada a fazer.';
    RETURN;
  END IF;
  IF to_regclass('audit.license_usage_event') IS NULL THEN
    RAISE EXCEPTION 'nem audit.uso_isolado nem audit.license_usage_event existem';
  END IF;

  -- ── colunas ──
  ALTER TABLE audit.license_usage_event RENAME COLUMN event_uuid      TO uso_id;
  ALTER TABLE audit.license_usage_event RENAME COLUMN tenant_uuid     TO uso_tenant_uuid;
  ALTER TABLE audit.license_usage_event RENAME COLUMN user_uuid       TO uso_usuario_uuid;
  ALTER TABLE audit.license_usage_event RENAME COLUMN product_code    TO uso_produto;
  ALTER TABLE audit.license_usage_event RENAME COLUMN resource_id     TO uso_recurso;
  ALTER TABLE audit.license_usage_event RENAME COLUMN event_type      TO uso_evento;
  ALTER TABLE audit.license_usage_event RENAME COLUMN quantity        TO uso_qtd;
  ALTER TABLE audit.license_usage_event RENAME COLUMN idempotency_key TO uso_chave_idem;
  ALTER TABLE audit.license_usage_event RENAME COLUMN status          TO uso_sync;
  ALTER TABLE audit.license_usage_event RENAME COLUMN balance_before  TO uso_saldo_antes;
  ALTER TABLE audit.license_usage_event RENAME COLUMN balance_after   TO uso_saldo_depois;
  ALTER TABLE audit.license_usage_event RENAME COLUMN metadata_json   TO uso_meta_json;
  ALTER TABLE audit.license_usage_event RENAME COLUMN error_message   TO uso_erro;
  ALTER TABLE audit.license_usage_event RENAME COLUMN created_at      TO uso_criado_em;
  ALTER TABLE audit.license_usage_event RENAME COLUMN confirmed_at    TO uso_confirmado_em;
  ALTER TABLE audit.license_usage_event RENAME COLUMN updated_at      TO uso_atualizado_em;

  -- ── valores do estado de sincronização, antes do CHECK novo ──
  ALTER TABLE audit.license_usage_event DROP CONSTRAINT ck_license_usage_event_status;
  UPDATE audit.license_usage_event SET uso_sync = CASE uso_sync
      WHEN 'pending'   THEN 'PENDENTE'
      WHEN 'confirmed' THEN 'CONFIRMADO'
      WHEN 'failed'    THEN 'FALHOU'
      ELSE upper(uso_sync) END;
  ALTER TABLE audit.license_usage_event ALTER COLUMN uso_sync SET DEFAULT 'PENDENTE';

  -- ── constraints e índice ──
  ALTER TABLE audit.license_usage_event
      RENAME CONSTRAINT uq_license_usage_event_idempotency TO uq_uso_idem;
  ALTER TABLE audit.license_usage_event
      RENAME CONSTRAINT ck_license_usage_event_quantity TO ck_uso_qtd;
  ALTER TABLE audit.license_usage_event
      RENAME CONSTRAINT ck_license_usage_event_metadata TO ck_uso_meta;
  ALTER TABLE audit.license_usage_event
      RENAME CONSTRAINT license_usage_event_pkey TO uso_isolado_pkey;
  ALTER TABLE audit.license_usage_event
      ADD CONSTRAINT ck_uso_sync CHECK (uso_sync IN ('PENDENTE', 'CONFIRMADO', 'FALHOU'));
  -- guarda que não existia: data de confirmação e estado não podem discordar
  ALTER TABLE audit.license_usage_event
      ADD CONSTRAINT ck_uso_confirmado
      CHECK ((uso_sync = 'CONFIRMADO') = (uso_confirmado_em IS NOT NULL));

  DROP INDEX IF EXISTS audit.idx_license_usage_event_pending;
  CREATE INDEX ix_uso_pendente ON audit.license_usage_event (uso_atualizado_em)
      WHERE uso_sync IN ('PENDENTE', 'FALHOU');

  -- ── a tabela, por último: assim os RENAMEs acima leem o nome antigo ──
  ALTER TABLE audit.license_usage_event RENAME TO uso_isolado;

  RAISE NOTICE 'OK — audit.license_usage_event renomeada para audit.uso_isolado.';
END $$;

-- Conferência: nada do nome antigo pode sobrar.
DO $$
DECLARE n INTEGER;
BEGIN
  IF to_regclass('audit.license_usage_event') IS NOT NULL THEN
    RAISE EXCEPTION 'o nome antigo ainda existe';
  END IF;
  SELECT count(*) INTO n FROM information_schema.columns
   WHERE table_schema = 'audit' AND table_name = 'uso_isolado'
     AND column_name NOT LIKE 'uso\_%';
  IF n > 0 THEN
    RAISE EXCEPTION '% coluna(s) fora do prefixo uso_', n;
  END IF;
  RAISE NOTICE 'OK — 16 colunas, todas com prefixo uso_.';
END $$;
