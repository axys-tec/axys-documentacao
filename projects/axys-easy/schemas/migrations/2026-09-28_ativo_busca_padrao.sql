-- Motor de busca por ativo: padrão (relevância pura) ou ranqueado pela fonte favorita.
--
-- JÁ APLICADO em dev e em prod em 2026-09-28. Fica registrado para quem reconstruir do zero.
--
-- É coluna própria, e não um efeito colateral de ter favorita, porque são DUAS decisões: a
-- favorita existe para CONVERTER (insumo/MDO), e quem converte nem sempre quer que a ordem da
-- busca mude por causa disso. Amarrar as duas tirava do usuário uma escolha.
--
-- DEFAULT TRUE preserva o comportamento atual: quem não escolher nada não vê diferença. E como
-- a coluna nasce com default, os 26 ativos existentes (dev e prod) já entraram como `true` —
-- não há seed a rodar. No Postgres 11+ isto não reescreve a tabela.
ALTER TABLE ativo.ativos
    ADD COLUMN IF NOT EXISTS atv_busca_padrao BOOLEAN NOT NULL DEFAULT TRUE;
