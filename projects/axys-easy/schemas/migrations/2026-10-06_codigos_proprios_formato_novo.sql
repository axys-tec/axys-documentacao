-- 2026-10-06_codigos_proprios_formato_novo.sql
--
-- Descrição: converte os códigos PRÓPRIOS que ainda estão no formato antigo
--            (`XX-000.000-INS` / `XX-000.000-CPU`, onde XX vinha das 2 primeiras letras do código
--            da fonte) para o formato decidido no item 8 do refino: `I-000001` / `C-000001`,
--            seis dígitos, sequencial POR TENANT, com o número guardado em `ins_seq` / `cmp_seq`.
--
-- Por que é seguro: o orçamento referencia composição/insumo por ID (`ati_cmp_id` + `ati_cmp_origem`),
-- nunca por código. Varredura em TODAS as colunas de texto de `ativo`, `tenant_catalogo` e `catalogo`
-- confirmou: fora as próprias colunas de código (e as `*_busca`, que são regeneradas por trigger),
-- nenhuma outra guarda o código antigo. Memória de cálculo: 0 ocorrências. JSONs dos itens: 0.
--
-- Regras do item 8 respeitadas:
--   • converte SÓ o que está no formato antigo AUTOMÁTICO — código digitado à mão fica como está;
--   • nunca reaproveita número: começa em max(seq)+1 do tenant e segue;
--   • se o número cair em cima de um código já existente (digitado à mão no formato reservado),
--     pula para o próximo livre — colisão não vira erro.
--
-- Rollback: não há volta automática. O código antigo derivava do nome da fonte e era justamente o
-- que o item 8 veio matar; para desfazer, restaurar do backup.
-- Data: 06/10/2026

DO $$
DECLARE
  t        record;      -- tenant (laço externo) — NÃO reusar `r`: o laço interno sobrescreveria
  r        record;      -- linha a converter (laço interno)
  prox     integer;
  cod      text;
  n_ins    integer := 0;
  n_cmp    integer := 0;
BEGIN
  -- ── INSUMOS ──
  FOR t IN SELECT DISTINCT ins_tenant_uuid AS tenant FROM tenant_catalogo.insumos
            WHERE ins_codigo ~ '^[A-Z&0-9]{2}-[0-9]{3}[.][0-9]{3}-INS$'
  LOOP
    SELECT coalesce(max(ins_seq), 0) + 1 INTO prox
      FROM tenant_catalogo.insumos WHERE ins_tenant_uuid = t.tenant;
    FOR r IN SELECT ins_id, ins_tenant_uuid FROM tenant_catalogo.insumos
              WHERE ins_tenant_uuid = t.tenant
                AND ins_codigo ~ '^[A-Z&0-9]{2}-[0-9]{3}[.][0-9]{3}-INS$'
              ORDER BY ins_id
    LOOP
      LOOP      -- pula número já ocupado por código digitado à mão
        cod := 'I-' || lpad(prox::text, 6, '0');
        EXIT WHEN NOT EXISTS (SELECT 1 FROM tenant_catalogo.insumos
                               WHERE ins_tenant_uuid = r.ins_tenant_uuid AND ins_codigo = cod);
        prox := prox + 1;
      END LOOP;
      UPDATE tenant_catalogo.insumos SET ins_codigo = cod, ins_seq = prox WHERE ins_id = r.ins_id;
      prox  := prox + 1;
      n_ins := n_ins + 1;
    END LOOP;
  END LOOP;

  -- ── COMPOSIÇÕES ──
  FOR t IN SELECT DISTINCT cmp_tenant_uuid AS tenant FROM tenant_catalogo.composicoes
            WHERE cmp_codigo ~ '^[A-Z&0-9]{2}-[0-9]{3}[.][0-9]{3}-CPU$'
  LOOP
    SELECT coalesce(max(cmp_seq), 0) + 1 INTO prox
      FROM tenant_catalogo.composicoes WHERE cmp_tenant_uuid = t.tenant;
    FOR r IN SELECT cmp_id, cmp_tenant_uuid FROM tenant_catalogo.composicoes
              WHERE cmp_tenant_uuid = t.tenant
                AND cmp_codigo ~ '^[A-Z&0-9]{2}-[0-9]{3}[.][0-9]{3}-CPU$'
              ORDER BY cmp_id
    LOOP
      LOOP
        cod := 'C-' || lpad(prox::text, 6, '0');
        EXIT WHEN NOT EXISTS (SELECT 1 FROM tenant_catalogo.composicoes
                               WHERE cmp_tenant_uuid = r.cmp_tenant_uuid AND cmp_codigo = cod);
        prox := prox + 1;
      END LOOP;
      UPDATE tenant_catalogo.composicoes SET cmp_codigo = cod, cmp_seq = prox WHERE cmp_id = r.cmp_id;
      prox  := prox + 1;
      n_cmp := n_cmp + 1;
    END LOOP;
  END LOOP;

  RAISE NOTICE 'convertidos: % insumo(s), % composicao(oes)', n_ins, n_cmp;
END $$;
