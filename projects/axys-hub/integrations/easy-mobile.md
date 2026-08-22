# Easy Mobile — autenticação e MFA

## Autenticação do cliente

As rotas de cadastro e MFA exigem HTTP Basic com o cliente SSO configurado para
`easy-mobile`. Rotas de perfil exigem o JWT retornado pelo Hub como Bearer token.

## Cadastro e MFA

- `POST /api/easy-mobile/cadastro`
- `POST /api/easy-mobile/verificar-mfa`
- `POST /api/easy-mobile/reenviar-mfa`

O campo `mfa_canal` no cadastro e o campo `canal` no reenvio aceitam `email` ou
`whatsapp`. Para WhatsApp, números nacionais de 10 ou 11 dígitos recebem o DDI
`55` antes do envio à Z-API. Números já informados com `55` são preservados.

Após a confirmação correta, `POST /api/easy-mobile/verificar-mfa` preserva os
campos históricos `client_uuid` e `status` e acrescenta a autenticação:

```json
{
  "client_uuid": "uuid",
  "status": "active",
  "access_token": "jwt",
  "token": "jwt",
  "token_type": "bearer",
  "expires_in": 2592000,
  "user": {}
}
```

O alias `token` é mantido junto de `access_token` para consistência com os demais
fluxos SSO. O JWT possui `aud=easy-mobile`, `subject_type=easy_mobile_client` e
`sub` igual ao `client_uuid`, e pode ser usado imediatamente em
`GET /api/easy-mobile/me`.

O token tem vida útil de 30 dias (`2592000` segundos), sem refresh token nesta
etapa. Após a expiração, o aplicativo inicia um novo handshake com o Hub.

Para identidades vinculadas a tenant, o JWT também inclui uma personalização
versionada. Na v0, somente a logo é consumida:

```json
{
  "personalizacao": {
    "versao": 1,
    "revisao": 1,
    "logo": {
      "url": "https://public.axys-tec.com.br/assets/tenants/<sha256>.png",
      "sha256": "<sha256>",
      "mime_type": "image/png"
    }
  }
}
```

Sem configuração ou sem tenant, `logo` é `null` e o consumidor usa a marca
padrão Axys. `revision` permite invalidar cache; `settings_json` no banco fica
reservado para versões posteriores do contrato.

## Z-API

Variáveis:

- `ZAPI_SENDER_ENABLED`
- `ZAPI_INSTANCE_ID`
- `ZAPI_TOKEN`
- `ZAPI_CLIENT_TOKEN`
- `ZAPI_HTTP_TIMEOUT_TEXT` (padrão: `30` segundos)
- `ZAPI_DELAY_MESSAGE` (padrão: `2`)
- `ZAPI_HTTP_MAX_ATTEMPTS` (padrão: `3`, máximo: `5`)
- `ZAPI_HTTP_RETRY_DELAY_SECONDS` (padrão: `0.5`, máximo: `10`)

O cliente chama `POST {ZAPI_BASE_URL}/send-text` com:

```json
{
  "phone": "5511999999999",
  "message": "Seu código Easy Mobile é 123456.",
  "delayMessage": 2
}
```

O `Client-Token` segue somente no header e não deve ser registrado. A mensagem
acima é apenas ilustrativa. Em produção, o código MFA não é devolvido pela API;
`dev_code` existe apenas fora de produção. Logs registram somente os quatro
últimos dígitos do telefone e nunca registram a mensagem.

Falhas de rede, HTTP 429 e HTTP 5xx são retentadas conforme a configuração. Se a
entrega falhar em produção, o desafio criado é imediatamente expirado e a API
responde HTTP 503.

## Limites

- Cadastro: 5 tentativas por IP/e-mail em 1 hora.
- Verificação: 6 requisições por IP/desafio em 15 minutos.
- Um desafio aceita no máximo 5 códigos incorretos.
- Reenvio: 3 requisições por IP/cliente em 15 minutos.
- Um reenvio expira todos os desafios anteriores ainda ativos.

## Credencial de telemetria

A Easy Mobile API conecta diretamente ao PostgreSQL com um usuário `LOGIN`
exclusivo, membro apenas de `easy_mobile_analytics_writer`. A role concede
`USAGE` no schema `analytics`, `INSERT` em `analytics.easy_mobile_event` e uso da
sequence da chave; não concede leitura nem acesso às tabelas de identidade,
licença, produto ou billing.

Em desenvolvimento, carregue `.env.local` e execute:

```bash
python scripts/setup_easy_mobile_analytics_user.py
```

O serviço consumidor recebe `EASY_MOBILE_ANALYTICS_DB_URL`; nunca deve receber
`HUB_DB_URL`.
