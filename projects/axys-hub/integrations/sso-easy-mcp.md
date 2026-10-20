# SSO do Easy MCP

O `easy-mcp` é um cliente SSO independente que usa a identidade, o tenant, as licenças e as
claims do Easy web. A audiência do JWT é exclusivamente `easy-mcp`; tokens `easy` e `easy-mcp`
não são intercambiáveis.

## Fluxo

1. O Easy inicia o login em
   `/login?app=easy-mcp&redirect_uri=<callback>&state=<state>`.
2. O Hub valida o callback por igualdade exata contra a allowlist e devolve um code curto e de uso
   único.
3. O Easy troca o code em `POST /auth/exchange`, usando Basic Auth próprio e o corpo:

   ```json
   {"code": "...", "app": "easy-mcp"}
   ```

   `redirect_uri` pode ser enviado no corpo e, quando presente, precisa ser idêntico ao callback
   vinculado ao code. Quando omitido, o Hub usa o callback único configurado para o app.

## Variáveis do Hub

- `EASY_MCP_SSO_CLIENT_ID`
- `EASY_MCP_SSO_CLIENT_SECRET`
- `EASY_MCP_SSO_ALLOWED_REDIRECT_URIS` — URLs separadas por vírgula; comparação exata
- `EASY_MCP_SSO_AUDIENCE` — padrão `easy-mcp`
- `EASY_MCP_JWT_TTL` — padrão `28800`, mínimo `300`
- `EASY_MCP_SSO_CODE_TTL_SECONDS` — opcional; padrão `90`, entre `30` e `300`
- `EASY_MCP_CALLBACK_URL` — opcional; necessário apenas se a allowlist tiver mais de uma URL e o
  cliente não mandar `redirect_uri` no exchange

Callback de desenvolvimento:

```text
https://mcp-dev.axys-tec.com.br/mcp/oauth/hub-callback
```

Callback de produção:

```text
https://easy.axys-tec.com.br/mcp/oauth/hub-callback
```
