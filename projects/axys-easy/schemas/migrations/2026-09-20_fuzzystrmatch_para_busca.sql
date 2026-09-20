-- AxysEasy — instala fuzzystrmatch para o ranking da busca.
--
-- POR QUE. O trigrama não distingue erro de digitação em palavra curta:
-- word_similarity('PIZO', X) devolve 0,400 IGUAL para PISO, PISTOLA e PINTURA, porque os
-- trigramas compartilhados entre elas são os mesmos. Resultado observado em uso: "pizo"
-- não achava piso nenhum, e "forna" trazia fornecimento em vez de forma.
--
-- A distância de edição separa na hora: PIZO→PISO = 1 troca, PIZO→PISTOLA = 4, PIZO→PINTURA
-- = 5. Com ela, "pizo" passa a abrir com PISO e "forna" com FORMA.
--
-- ONDE ENTRA. Só como BÔNUS de ranking, sobre a PRIMEIRA palavra da descrição
-- (`split_part(descricao, ' ', 1)`), nunca como filtro e nunca sobre o texto inteiro:
-- levenshtein não usa índice, e varrer descrição completa custaria caro.
--
-- SEGURO DE APLICAR. `backend/core/search/postgres_adapter.py` detecta a função em tempo de
-- consulta e, se não houver, monta o escore sem o bônus. A busca funciona com ou sem esta
-- migração; ela melhora a ordem, não é dependência. Aplicar não exige deploy coordenado.
--
-- SCHEMA. Vai em `catalogo` como as demais, porque este banco não tem `public` e os usos
-- são qualificados (catalogo.unaccent, catalogo.similarity, catalogo.levenshtein).
--
-- Exige papel com permissão de criar extensão.

CREATE EXTENSION IF NOT EXISTS fuzzystrmatch SCHEMA catalogo;

-- Conferência: deve devolver (1, 4, 5).
-- SELECT catalogo.levenshtein('PIZO','PISO'),
--        catalogo.levenshtein('PIZO','PISTOLA'),
--        catalogo.levenshtein('PIZO','PINTURA');
