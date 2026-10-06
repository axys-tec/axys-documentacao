-- 2026-10-06_empreendimento_secoes.sql
--
-- Descrição: cria `ativo.empreendimento_secoes` — o que o usuário deixou marcado na tab
--            Finalização (quais seções entram no documento).
--
-- POR QUE
--   `empreendimento_parametros` já guardava as decisões de APRESENTAÇÃO (estilo, ofício, local e
--   data). Faltava a outra metade: as seções. Elas viajavam só em `sec=` na hora de exportar e
--   voltavam ao padrão a cada reload — quem desmarcava oito seções reencontrava as oito marcadas
--   no dia seguinte, e não havia como saber que a escolha não tinha sido guardada.
--
-- POR QUE TABELA E NÃO COLUNA JSON
--   A chave da tela é `atv{id}.sintetico`: carrega o ID DO ATIVO. Em JSON isso é id de outra
--   tabela sem FK — o que a regra do P4 proíbe, e pela razão que importa: apagar um ativo deixaria
--   a chave órfã no JSON para sempre. Com o id em COLUNA e FK ON DELETE CASCADE, o banco limpa
--   sozinho (provado em dev: apagada a obra, só as chaves dela saíram; apagado o empreendimento,
--   saiu tudo). A chave guardada é só o SUFIXO, porque o id já é coluna.
--
-- GUARDA O ESTADO, não só o marcado: "sem linha" significa "nunca configurado" e o checkbox cai no
-- default — o certo para a obra ou o parâmetro que nasceu DEPOIS da última gravação. Guardar só o
-- marcado tornaria "desmarquei tudo" indistinguível de "nunca mexi".
--
-- Ordem: ADITIVA e o código novo precisa dela. ANTES do deploy; rodar depois faz a tela tentar ler
-- tabela que não existe.
--
-- Rollback: DROP TABLE IF EXISTS ativo.empreendimento_secoes;
-- Data: 06/10/2026


-- ------------------------------------------------------------
-- ativo.empreendimento_secoes — o que o usuário deixou marcado na tab Finalização
-- ------------------------------------------------------------
-- `empreendimento_parametros` guarda as decisões de APRESENTAÇÃO (estilo, ofício, local e data).
-- O que faltava era a outra metade: QUAIS SEÇÕES entram no documento. Elas viajavam só em `sec=`
-- na hora de exportar e voltavam ao padrão a cada reload — quem desmarcava oito seções
-- reencontrava as oito marcadas no dia seguinte.
--
-- POR QUE TABELA E NÃO UMA COLUNA JSON em `empreendimento_parametros`:
-- a chave da tela é `atv{id}.sintetico`, ou seja, carrega o ID DO ATIVO. Em JSON isso é um id de
-- outra tabela sem FK — exatamente o que a regra do P4 proíbe, e pela razão que importa aqui:
-- apagar um ativo deixaria a chave órfã no JSON para sempre. Com o id em COLUNA e FK, o banco
-- limpa sozinho. A chave guardada é só o SUFIXO (`sintetico`), porque o id já é coluna.
--
-- GUARDA O ESTADO, não só o marcado. "Sem linha" significa "nunca configurado" e o checkbox cai no
-- default — que é o certo para ativo ou parâmetro que nasceu DEPOIS da última gravação. Guardar só
-- o marcado tornaria "desmarquei tudo" indistinguível de "nunca mexi".
CREATE TABLE IF NOT EXISTS ativo.empreendimento_secoes (
    eps_emp_id  INTEGER NOT NULL,
    -- NULL = seção do DOCUMENTO ou do empreendimento (capa, ofício, campos do quadro resumo)
    eps_atv_id  INTEGER,
    eps_chave   TEXT    NOT NULL,     -- sufixo: `sintetico`, `curva:servicos`, `param:Área`…
    eps_marcada BOOLEAN NOT NULL,

    CONSTRAINT fk_eps_emp FOREIGN KEY (eps_emp_id)
        REFERENCES ativo.empreendimentos (emp_id) ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_eps_atv FOREIGN KEY (eps_atv_id)
        REFERENCES ativo.ativos (atv_id) ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT ck_eps_chave CHECK (btrim(eps_chave) <> '')
);

-- COALESCE porque NULL não participa de UNIQUE: sem isto, duas linhas `(20, NULL, 'capa')`
-- conviveriam e a última leitura venceria por sorte.
CREATE UNIQUE INDEX IF NOT EXISTS uq_eps_chave
    ON ativo.empreendimento_secoes (eps_emp_id, COALESCE(eps_atv_id, 0), eps_chave);

-- Conferência: nasce vazia. Nenhum empreendimento existente ganha seção — todos continuam no
-- default até alguém mexer na tela, que é o comportamento de hoje.
DO $$
DECLARE n INTEGER;
BEGIN
  SELECT count(*) INTO n FROM ativo.empreendimento_secoes;
  IF n <> 0 THEN
    RAISE EXCEPTION 'empreendimento_secoes deveria nascer vazia, tem % linha(s)', n;
  END IF;
  RAISE NOTICE 'OK — ativo.empreendimento_secoes criada e vazia.';
END $$;
