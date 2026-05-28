# ADR-026 ? Autenticacao no AxysDash (Login Humano + Client Credentials)
**Status:** Revisado
**Data:** 2026-02-07
**Fase:** pre-producao

---

## 1) Contexto
O AxysDash e um aplicativo movel de leitura rapida, sem edicao de dados, destinado a acompanhamento diario.

Inicialmente a autenticacao foi definida apenas via Client Credentials. Com a evolucao do app iOS e
para manter o mesmo login do Dash web, passou a ser necessario permitir login humano com usuario e senha.

---

## 2) Decisao
O AxysDash passa a suportar dois fluxos:

- Login humano (iOS)
  - Endpoint: POST /api/v1/dash/auth/login-user
  - Credenciais: email e password
  - Resultado: access_token Bearer para leitura

- Client Credentials (ERP/ingest)
  - Endpoint: POST /api/v1/dash/auth/login
  - Credenciais: client_key e client_secret
  - Resultado: access_token Bearer para automacao e ingest

---

## 3) Justificativa
- Mantem o mesmo login do Dash web para usuarios finais.
- Permite que o app iOS nao dependa de API key fixa.
- Preserva automacao e ingest via client credentials.

---

## 4) Consequencias
### Positivas
- Experiencia do usuario consistente entre Web e iOS.
- Menos friccao de configuracao no app.
- ERP continua com fluxo de automacao dedicado.

### Negativas
- Superficie de autenticacao maior.
- Necessidade de proteger melhor o endpoint de login humano.

Essas consequencias sao aceitaveis no contexto atual.

---

## 5) Diretrizes
- Tokens nunca armazenados em texto plano.
- Login humano nao exige X-API-Key.
- Leitura com Bearer nao exige X-API-Key.
- Ingest e login client-credentials exigem X-API-Key.
- Rate limit por tenant/store/feature para ingest.

---

## 6) Registro
Esta ADR substitui a definicao anterior de client credentials como unico modelo.
Mudancas futuras exigem nova ADR.
