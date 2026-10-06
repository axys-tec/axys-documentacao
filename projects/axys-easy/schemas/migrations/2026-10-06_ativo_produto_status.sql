-- 2026-10-06_ativo_produto_status.sql
--
-- Descrição: cria `ativo.ativo_produto_status` — a ocupação de capacidade, um vínculo por
--            (ativo, produto) — e a UNIQUE em `ativo.ativos (atv_id, atv_tenant_uuid)` que serve
--            de alvo para a FK composta.
--
-- Origem: proposta do time do Hub em 06/10 (contracts/axys_easy_modelo_licenciamento.md §10.1),
--         aprovada no conceito e revisada tecnicamente aqui. O conceito é forçado pelo comercial:
--         capacidade não forma saldo comum entre produtos, então o mesmo ativo pode estar em
--         andamento no Orça sem ocupar nada no Docs — o que não cabe numa coluna de status do
--         ativo. O Hub NUNCA escreve nesta tabela; ele pergunta a ocupação pelo endpoint interno.
--
-- Revisão aplicada sobre a proposta:
--   · nomes na convenção da casa (prefixo `atvp_`, português);
--   · `atvp_tenant_uuid` deixou de ser regra escrita e passou a ser FK COMPOSTA — o banco recusa o
--     par incoerente (a lição do P4: regra merece guarda, não só texto);
--   · `atvp_ativado_em` é a PRIMEIRA ativação e nunca se reescreve; ida e volta ficam em audit.logs;
--   · índice PARCIAL de ocupação: a contagem roda dentro do lock, no caminho de criar/desarquivar.
--
-- NÃO acompanha código: nada no app lê ou escreve esta tabela ainda. O gate de capacidade que
-- está no ar conta ocupação por TENANT, sem produto, e é justamente o que esta tabela vai
-- substituir — ver a pendência registrada em governanca/pendencias.md.
--
-- Ordem: ADITIVA e sem leitor. Pode rodar antes ou depois do deploy, tanto faz.
--
-- Rollback:
--   DROP TABLE IF EXISTS ativo.ativo_produto_status;
--   ALTER TABLE ativo.ativos DROP CONSTRAINT IF EXISTS uq_ativos_id_tenant;
-- Data: 06/10/2026

-- Redundante por si (atv_id já é a PK): existe só para ser ALVO da FK composta abaixo.
ALTER TABLE ativo.ativos
  ADD CONSTRAINT uq_ativos_id_tenant UNIQUE (atv_id, atv_tenant_uuid);

-- ── Ocupação de capacidade: um vínculo por (ativo, produto) ───────────────────────────────────
-- Proposta do time do Hub em 06/10 (`contracts/axys_easy_modelo_licenciamento.md` §10.1), revisada
-- aqui. O CONCEITO é forçado pelo comercial: capacidade não forma saldo comum entre produtos, logo
-- "Orça 5 e Docs 5" são dois tetos, e o MESMO ativo pode estar em andamento no Orça sem ocupar
-- nada no Docs. Isso não cabe numa coluna de status do ativo — daí a tabela.
--
-- O slot é SEMPRE do ativo: empreendimento é agrupador e nunca ocupa nada (decisão de 01/10).
-- Criar empreendimento, ou só o cadastro-base do ativo, não cria vínculo. O vínculo nasce na
-- primeira operação que põe o ativo em andamento DENTRO de um produto. Concluir, revisar, reabrir,
-- recalcular ou emitir documento não geram consumo novo enquanto o vínculo seguir EM_ANDAMENTO.
--
-- O Hub NUNCA escreve aqui e nunca escolhe qual ativo arquivar. Ele pergunta a ocupação pelo
-- endpoint interno e aplica o próprio teto.
--
-- O QUE MUDOU DA PROPOSTA, e por quê:
--   · nomes na convenção da casa (prefixo `atvp_`, português) — a tabela é nossa, o Hub só lê pelo
--     endpoint, então nome em inglês sem prefixo seria dívida de leitura sem ganho nenhum;
--   · `atvp_tenant_uuid` ganhou GUARDA: a proposta dizia "deve corresponder ao tenant do ativo", e
--     regra sem guarda é a lição do P4. Aqui é FK COMPOSTA — o banco recusa o par incoerente;
--   · o tenant repetido se paga no índice parcial abaixo: a contagem de ocupação roda dentro do
--     lock, no caminho crítico de criar/desarquivar, e assim não precisa juntar `ativos`;
--   · `atvp_ativado_em` é a PRIMEIRA ativação e nunca se reescreve; quem registra ida e volta é
--     `audit.logs`, que é onde transição de estado mora nesta casa.
CREATE TABLE IF NOT EXISTS ativo.ativo_produto_status (
    atvp_atv_id         INTEGER NOT NULL,
    atvp_tenant_uuid    UUID    NOT NULL,
    -- produto operacional onde o ativo está em trabalho
    atvp_produto        TEXT    NOT NULL,
    -- licença que SUPORTA o slot; igual ao produto, exceto no Easy One, que consolida em 'ONE'
    atvp_licenca        TEXT    NOT NULL,
    atvp_status         TEXT    NOT NULL DEFAULT 'EM_ANDAMENTO',
    atvp_ativado_em     TIMESTAMPTZ NOT NULL DEFAULT now(),   -- primeira ativação, nunca reescrita
    atvp_arquivado_em   TIMESTAMPTZ,
    atvp_atualizado_em  TIMESTAMPTZ,
    atvp_atualizado_por TEXT,

    -- a chave natural é (ativo, produto); id próprio sem função não entra
    PRIMARY KEY (atvp_atv_id, atvp_produto),
    CONSTRAINT fk_atvp_ativo FOREIGN KEY (atvp_atv_id, atvp_tenant_uuid)
        REFERENCES ativo.ativos (atv_id, atv_tenant_uuid) ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT ck_atvp_produto CHECK (atvp_produto IN ('ORC', 'DOC', 'PM', 'LIC', 'BDR', 'FIN')),
    CONSTRAINT ck_atvp_licenca CHECK (atvp_licenca IN ('ORC', 'DOC', 'PM', 'LIC', 'BDR', 'FIN', 'ONE')),
    CONSTRAINT ck_atvp_status  CHECK (atvp_status IN ('EM_ANDAMENTO', 'ARQUIVADO')),
    -- data de arquivamento e status não podem discordar
    CONSTRAINT ck_atvp_arquivado CHECK ((atvp_status = 'ARQUIVADO') = (atvp_arquivado_em IS NOT NULL))
);

-- A pergunta que o gate faz, e a única que precisa ser rápida: quantos slots desta licença estão
-- ocupados neste tenant. Índice PARCIAL porque arquivado não conta e não precisa ser indexado.
CREATE INDEX IF NOT EXISTS ix_atvp_ocupacao
    ON ativo.ativo_produto_status (atvp_tenant_uuid, atvp_licenca)
    WHERE atvp_status = 'EM_ANDAMENTO';

-- Conferência: a tabela nasce vazia e nenhum ativo existente ganha vínculo. Slot só nasce quando o
-- app puser o ativo em andamento num produto — e o app ainda não faz isso.
DO $$
DECLARE n INTEGER;
BEGIN
  SELECT count(*) INTO n FROM ativo.ativo_produto_status;
  IF n <> 0 THEN
    RAISE EXCEPTION 'ativo_produto_status deveria nascer vazia, tem % linha(s)', n;
  END IF;
  RAISE NOTICE 'OK — ativo.ativo_produto_status criada e vazia.';
END $$;
