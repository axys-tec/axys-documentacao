-- tenant_catalogo.insumos_preco — preço 2 casas + cotação estruturada (validação estatística à la Maringá).
-- pri_valor → NUMERIC(14,2) (padrão do ativo). pri_cotacoes: lista antiga → objeto
-- {preco_informado, metodo, itens:[{...,aplicada,path}]}. Idempotente. Só tenant_catalogo.
-- Contrato: docs/projects/axys-easy/contracts/catalogo/TENANT_CATALOGO_PROPOSTA.md

ALTER TABLE tenant_catalogo.insumos_preco ALTER COLUMN pri_valor TYPE NUMERIC(14,2);

UPDATE tenant_catalogo.insumos_preco
   SET pri_cotacoes = jsonb_build_object('preco_informado', true, 'metodo', 'MENOR',
                                         'itens', COALESCE(pri_cotacoes, '[]'::jsonb))
 WHERE pri_cotacoes IS NULL OR jsonb_typeof(pri_cotacoes) = 'array';
