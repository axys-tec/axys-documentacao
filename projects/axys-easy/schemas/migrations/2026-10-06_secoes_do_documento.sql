-- 2026-10-06_secoes_do_documento.sql
--
-- Descrição: `epa_secoes` e `atv_secoes` — o que o usuário deixou marcado na tab Finalização passa
--            a persistir, cada metade na linha de quem é dona da decisão.
--
-- POR QUE
--   `empreendimento_parametros` já guardava as decisões de APRESENTAÇÃO (estilo, ofício, local e
--   data). Faltava a outra metade: quais seções entram no documento. Elas viajavam só em `sec=` na
--   hora de exportar e voltavam ao padrão a cada reload — quem desmarcava oito seções reencontrava
--   as oito marcadas no dia seguinte, sem nada na tela dizendo que a escolha não fora guardada.
--
-- POR QUE DUAS COLUNAS, E NÃO UMA NO EMPREENDIMENTO
--   A chave da tela é `atv{id}.sintetico`. Num JSON único no empreendimento, o id do ativo viraria
--   CHAVE de JSON — id de outra tabela sem FK, que é o que a regra do P4 proíbe, e pela razão que
--   importa: apagar um ativo deixaria a chave órfã para sempre. Guardando na LINHA DO ATIVO o id
--   desaparece (ele É a linha) e apagar a obra leva a escolha dela junto, sem cascata para
--   escrever. Provado em dev.
--
--   Houve uma versão anterior disto como TABELA (`ativo.empreendimento_secoes`), aplicada só em
--   dev e nunca em produção. Ela resolvia o mesmo com FK e índice sobre COALESCE — mais peça para
--   o mesmo resultado. O DROP abaixo existe para o banco de dev, que a tem.
--
-- GUARDA O ESTADO, não só o marcado: chave ausente = "nunca configurada", e o checkbox cai no
-- default — o certo para a obra ou o parâmetro que nasceu DEPOIS da última gravação. Só o marcado
-- tornaria "desmarquei tudo" indistinguível de "nunca mexi".
--
-- Ordem: ADITIVA e o código novo precisa dela. ANTES do deploy.
--
-- Rollback:
--   ALTER TABLE ativo.empreendimento_parametros DROP COLUMN epa_secoes;
--   ALTER TABLE ativo.ativos DROP COLUMN atv_secoes;
-- Data: 06/10/2026

DROP TABLE IF EXISTS ativo.empreendimento_secoes;   -- só existiu em dev

-- O que o usuário deixou marcado na tab Finalização, em DUAS colunas JSONB — cada uma na linha de
-- quem é dona da decisão:
--
--   `epa_secoes`  o que é do DOCUMENTO: capa, ofício, campos do quadro resumo.
--   `atv_secoes`  o que é da OBRA: sintético, analítico, curvas, cronograma, LS, BDI, parâmetros.
--
-- Por que duas e não uma só no empreendimento: a chave da tela é `atv{id}.sintetico`, e um JSON
-- único no empreendimento guardaria o ID DO ATIVO como chave — id de outra tabela dentro de JSON,
-- sem FK, que é o que a regra do P4 proíbe. Guardando na LINHA DO ATIVO o id desaparece: ele é a
-- própria linha. Apagar a obra leva as escolhas dela junto, de graça, sem cascata para escrever.
--
-- Guarda o ESTADO (`{"sintetico": true, "analitico": false}`), não só o marcado. Chave ausente
-- significa "nunca configurada" e o checkbox cai no default — o certo para a obra ou o parâmetro
-- que nasceu DEPOIS da última gravação. Só o marcado tornaria "desmarquei tudo" indistinguível de
-- "nunca mexi".
ALTER TABLE ativo.empreendimento_parametros
  ADD COLUMN IF NOT EXISTS epa_secoes JSONB NOT NULL DEFAULT '{}'::jsonb;

ALTER TABLE ativo.ativos
  ADD COLUMN IF NOT EXISTS atv_secoes JSONB NOT NULL DEFAULT '{}'::jsonb;

-- objeto, sempre: `[]` ou um número aqui viraria erro de leitura lá na frente, longe daqui
ALTER TABLE ativo.empreendimento_parametros
  DROP CONSTRAINT IF EXISTS ck_epa_secoes;
ALTER TABLE ativo.empreendimento_parametros
  ADD CONSTRAINT ck_epa_secoes CHECK (jsonb_typeof(epa_secoes) = 'object');
ALTER TABLE ativo.ativos
  DROP CONSTRAINT IF EXISTS ck_atv_secoes;
ALTER TABLE ativo.ativos
  ADD CONSTRAINT ck_atv_secoes CHECK (jsonb_typeof(atv_secoes) = 'object');

-- Conferência: as duas colunas nascem como objeto vazio em TODA linha. Nenhum empreendimento
-- existente ganha ou perde seção — todos seguem no default até alguém mexer na tela.
DO $$
DECLARE a INTEGER; e INTEGER;
BEGIN
  SELECT count(*) INTO a FROM ativo.ativos WHERE atv_secoes <> '{}'::jsonb;
  SELECT count(*) INTO e FROM ativo.empreendimento_parametros WHERE epa_secoes <> '{}'::jsonb;
  IF a <> 0 OR e <> 0 THEN
    RAISE EXCEPTION 'as colunas deveriam nascer vazias: % ativo(s) e % parâmetro(s) com conteúdo', a, e;
  END IF;
  RAISE NOTICE 'OK — epa_secoes e atv_secoes criadas, vazias em todas as linhas.';
END $$;
