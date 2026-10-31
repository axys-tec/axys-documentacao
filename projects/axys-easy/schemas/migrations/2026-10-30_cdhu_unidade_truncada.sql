-- Contrato: contracts/catalogo/imports/cdhu.md (unidade truncada em 5 caracteres pela CDHU).
-- A CDHU publica a unidade cortada em 5 caracteres: M2XME (M2XMES) e CJXDI (CJXDIA). O parser passou a
-- repor a unidade (parser_cdhu._UNIDADE_TRUNCADA_CDHU, commit 0052260); este UPDATE corrige o que já
-- estava gravado, para o próximo import não ver "mudou" e reabrir a associação desses itens.
-- Idempotente: casa por fonte + código + unidade antiga; rodada de novo, não acha nada.
BEGIN;

UPDATE catalogo.insumos i
   SET ins_unidade = 'M2XMES'
  FROM catalogo.fontes f
 WHERE f.fte_id = i.ins_fte_id AND f.fte_codigo = 'CDHU'
   AND i.ins_codigo = 'S.04.000.021094' AND i.ins_unidade = 'M2XME';

UPDATE catalogo.insumos i
   SET ins_unidade = 'CJXDIA'
  FROM catalogo.fontes f
 WHERE f.fte_id = i.ins_fte_id AND f.fte_codigo = 'CDHU'
   AND i.ins_codigo = 'A.04.000.098084' AND i.ins_unidade = 'CJXDI';

UPDATE catalogo.composicoes c
   SET cmp_unidade = 'CJXDIA'
  FROM catalogo.fontes f
 WHERE f.fte_id = c.cmp_fte_id AND f.fte_codigo = 'CDHU'
   AND c.cmp_codigo = '08.07.060' AND c.cmp_unidade = 'CJXDI';

COMMIT;
