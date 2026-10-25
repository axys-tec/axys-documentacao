-- Telefone e chave de identidade/MFA no Hub. A unicidade considera apenas
-- digitos para impedir que mascaras diferentes representem duas identidades.
--
-- A identidade gratuita do Easy Mobile permanece em sua tabela e conserva
-- suas rotas e constraints atuais. A colisao entre os dois domínios e tratada
-- pelo servico de onboarding, sem alterar o contrato publicado do aplicativo.
-- Colisao ativa nao abre uma segunda identidade: deve seguir recuperacao ou
-- vinculacao do cadastro existente.
CREATE UNIQUE INDEX IF NOT EXISTS uq_hub_user_phone_normalized
    ON identity.hub_user ((regexp_replace(phone, '\D', '', 'g')))
    WHERE phone IS NOT NULL AND regexp_replace(phone, '\D', '', 'g') <> '';
