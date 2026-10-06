-- Alinha o catálogo comercial do AxysEasy ao contrato canônico de licenciamento.
-- PRI/CPU: uso isolado. Demais produtos: capacidade recorrente por ativo.

INSERT INTO product.offer (product_id, module_id, offer_code, name, billing_model)
SELECT p.product_id, NULL, v.offer_code, v.name, 'mensal'
FROM product.product p
JOIN (VALUES
    ('PRI','PRI-SIN','Easy Price Single'),
    ('PRI','PRI-STA','Easy Price Starter'),
    ('PRI','PRI-ADV','Easy Price Advanced'),
    ('PRI','PRI-PRO','Easy Price Pro'),
    ('PRI','PRI-UNL','Easy Price Unlimited'),
    ('ONE','ONE-UNL','Easy One Unlimited')
) AS v(product_code, offer_code, name) ON p.code=v.product_code
ON CONFLICT (offer_code) DO UPDATE SET
    product_id=EXCLUDED.product_id, name=EXCLUDED.name, billing_model=EXCLUDED.billing_model;

INSERT INTO product.offer_policy (
    offer_id,dias_carencia,dias_auto_suspensao,dias_auto_cancelamento,
    renova_automaticamente,retry_pagamento_habilitado,max_tentativas_pagamento,
    permite_override_manual,max_dias_override_manual,elegivel_comissao,
    emissao_fiscal_automatica,policy_json
)
SELECT o.offer_id,7,7,30,TRUE,TRUE,3,TRUE,15,TRUE,TRUE,'{}'::jsonb
FROM product.offer o
JOIN product.product p ON p.product_id=o.product_id
WHERE p.code IN ('PRI','CPU','DOC','PM','LIC','ORC','BDR','FIN','ONE')
ON CONFLICT (offer_id) DO UPDATE SET
    dias_carencia=7,dias_auto_suspensao=7,dias_auto_cancelamento=30,updated_at=now();

-- O contrato não licencia assentos: todos os usuários do tenant compartilham o direito.
DELETE FROM product.offer_entitlement e
USING product.offer o, product.product p
WHERE e.offer_id=o.offer_id AND o.product_id=p.product_id
  AND p.code IN ('PRI','CPU','DOC','PM','LIC','ORC','BDR','FIN','ONE')
  AND e.grant_model='limite_usuario';

-- Remove modelos históricos incompatíveis; a reinserção abaixo é determinística.
DELETE FROM product.offer_entitlement e
USING product.offer o, product.product p
WHERE e.offer_id=o.offer_id AND o.product_id=p.product_id
  AND p.code IN ('PRI','CPU','DOC','PM','LIC','ORC','BDR','FIN','ONE')
  AND e.grant_model IN ('contador_uso','limite_recurso_ativo','ilimitado');

INSERT INTO product.offer_entitlement
    (offer_id,module_id,grant_model,unit,quantity,period_unit,rule_json)
SELECT o.offer_id,NULL,
       CASE
         WHEN right(o.offer_code,3)='UNL' THEN 'ilimitado'
         WHEN p.code IN ('PRI','CPU') THEN 'contador_uso'
         ELSE 'limite_recurso_ativo'
       END,
       CASE WHEN p.code IN ('PRI','CPU') THEN 'uso_confirmado' ELSE 'ativo_em_andamento' END,
       CASE right(o.offer_code,3)
         WHEN 'SIN' THEN 1 WHEN 'STA' THEN 2 WHEN 'ADV' THEN 5 WHEN 'PRO' THEN 10
         ELSE NULL
       END,
       CASE WHEN p.code IN ('PRI','CPU') THEN NULL ELSE 'mes' END,
       '{}'::jsonb
FROM product.offer o
JOIN product.product p ON p.product_id=o.product_id
WHERE p.code IN ('PRI','CPU','DOC','PM','LIC','ORC','BDR','FIN','ONE')
  AND right(o.offer_code,3) IN ('SIN','STA','ADV','PRO','UNL');

