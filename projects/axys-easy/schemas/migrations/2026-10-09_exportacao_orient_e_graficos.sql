-- AxysEasy — parâmetros de apresentação: orientação das Composições Próprias e gráficos opcionais
-- Contrato: docs/projects/axys-easy/contracts/ativo/apresentacao_orcamento_contrato.md
--
-- epa_orient_proprias: a seção de Composições Próprias é a composição aberta item a item — a
--   mesma tabela do Analítico em outro recorte, e em retrato a descrição do insumo quebra
--   enquanto as colunas de número sobram. Vira escolha, como já são as Curvas, o Cronograma e os
--   Histogramas. Default 'H', que é o formato em que ela cabe.
--
-- epa_grafico_*: a Curva S, as barras do histograma e o Pareto da ABC são ILUSTRAÇÃO, não
--   a peça — quem analisa um orçamento lê a tabela. Passam a entrar só quando pedidas, e por isso
--   nascem FALSE.
BEGIN;

ALTER TABLE ativo.empreendimento_parametros
  ADD COLUMN IF NOT EXISTS epa_orient_proprias TEXT    NOT NULL DEFAULT 'H',
  ADD COLUMN IF NOT EXISTS epa_grafico_crono   BOOLEAN NOT NULL DEFAULT FALSE,
  ADD COLUMN IF NOT EXISTS epa_grafico_histo   BOOLEAN NOT NULL DEFAULT FALSE,
  ADD COLUMN IF NOT EXISTS epa_grafico_curva   BOOLEAN NOT NULL DEFAULT FALSE;

ALTER TABLE ativo.empreendimento_parametros DROP CONSTRAINT IF EXISTS ck_epa_orient;
ALTER TABLE ativo.empreendimento_parametros
  ADD CONSTRAINT ck_epa_orient CHECK (epa_orient_curva_serv IN ('H','V') AND epa_orient_curva_ins IN ('H','V')
                                  AND epa_orient_cronograma IN ('H','V') AND epa_orient_histo_sint IN ('H','V')
                                  AND epa_orient_histo_anal IN ('H','V')
                                  AND epa_orient_proprias IN ('H','V'));

COMMIT;
