# SSO Hub → AxysGestor — contrato de login

**Status:** 🟡 Implementado no Hub, aguardando configuração final da app cliente  
**Padrão:** AXYS-ADR-021 (Hub emite JWT, app cliente valida por JWKS)  
**Escopo:** autenticação do serviço/produto macro `gestor` por credenciais próprias e por SSO do Hub

---

## 0. Fronteira de responsabilidade

O Hub autentica, identifica o usuário e confirma licença ativa de ao menos um
produto do ecossistema `GESTOR`, aceitando `AXYSGESTOR` apenas como
compatibilidade de seed legado.

O AxysGestor decide internamente:

- quais produtos estão disponíveis (`sl`, `loccitane`, `gestor`);
- quais stores o usuário enxerga;
- quais permissões operacionais ele possui;
- qual contexto `tenant/store/product` está ativo.

Portanto, o Hub não emite permissões internas do Gestor e não trata
`SL Company` como app SSO separada.

## 1. Endpoints do Hub

### POST /auth/login

- Autentica o usuário no Hub e retorna JWT para `gestor`.
- Requer `Authorization: Basic base64(client_id:client_secret)`.
- Payload:

```json
{
  "email": "user@dominio.com",
  "password": "senha",
  "document": "somente_digitos",
  "app": "gestor"
}
```

- Resposta:

```json
{
  "token": "jwt-aqui",
  "access_token": "jwt-aqui"
}
```

### POST /auth/exchange

- Troca o `authorization code` de uso único por um JWT assinado pelo Hub.
- Requer `Authorization: Basic base64(client_id:client_secret)`.
- Payload:

```json
{
  "code": "authorization-code",
  "app": "gestor"
}
```

- Resposta:

```json
{
  "token": "jwt-aqui",
  "access_token": "jwt-aqui"
}
```

### GET /.well-known/jwks.json

- Publica as chaves públicas RS256 do Hub.
- O Gestor valida o JWT localmente por JWKS em produção.

---

## 2. Fluxos suportados

### Login por credenciais

1. O Gestor exibe a tela de login própria.
2. Envia `POST /auth/login` com `app=gestor`.
3. Recebe o JWT do Hub.
4. Valida por JWKS e segue para `/main`.

### Login por SSO

1. O Gestor redireciona o usuário para:

```text
GET {HUB}/login?app=gestor&redirect_uri=...&state=...
```

2. Após autenticação no Hub, o usuário retorna para:

```text
/sso/callback?code=...&state=...
```

3. O Gestor troca o `code` em `POST /auth/exchange`.
4. Recebe o JWT, valida por JWKS e segue para `/main`.

---

## 3. Claims mínimas do JWT

O Hub deve emitir, para `gestor`, pelo menos:

- `sub`
- `email`
- `name`
- `tenant_uuid`
- `tenant_code`
- `tenant_name`
- `store_uuid`
- `store_code`
- `store_name`
- `login_scope`
- `actor_type`
- `role`
- `tenant_role`
- `access_context`
- `is_staff`
- `apps_licenciadas`
- `app_labels`
- `licencas`
- `iat`
- `exp`

Exemplo:

```json
{
  "sub": "550e8400-e29b-41d4-a716-446655440000",
  "email": "user@axys-tec.com.br",
  "name": "Usuário Axys",
  "tenant_uuid": "9f1c1111-2222-3333-4444-555566667777",
  "tenant_code": "AXYS-TEC",
  "tenant_name": "Axys Tecnologia",
  "store_uuid": null,
  "store_code": null,
  "store_name": null,
  "login_scope": "tenant",
  "actor_type": "internal",
  "role": "internal_owner",
  "tenant_role": "internal_owner",
  "access_context": "internal",
  "is_staff": true,
  "apps_licenciadas": [
    "gestor-sl-company",
    "gestor-loccitane",
    "gestor-analista-vendas",
    "gestor-analista-compras",
    "gestor-notificador",
    "gestor-conciliador"
  ],
  "app_labels": {
    "gestor-sl-company": "Gestor SL Company",
    "gestor-loccitane": "Gestor L'Occitane",
    "gestor-analista-vendas": "Gestor Analista Vendas",
    "gestor-analista-compras": "Gestor Analista Compras",
    "gestor-notificador": "Gestor Notificador",
    "gestor-conciliador": "Gestor Conciliador"
  },
  "licencas": [
    {
      "app": "gestor-sl-company",
      "label": "Gestor SL Company",
      "modelo": "produto",
      "plano": "licensed",
      "status": "ACTIVE",
      "periodo_inicio": null,
      "periodo_fim": null
    }
  ],
  "iat": 1785312000,
  "exp": 1785340800
}
```

---

## 3.1 Resolução do document

O campo `document` enviado no login por credenciais é uma chave de contexto.

Ordem de resolução:

1. O Hub autentica `email` e `password`.
2. Para apps store-aware como `gestor`, o Hub tenta resolver `document` em
   `identity.hub_store.document`, exigindo store ativa, tenant ativo e vínculo
   ativo do usuário com a store.
3. Se encontrar store, emite token com `login_scope = "store"` e preenche
   `store_uuid`, `store_code` e `store_name`.
4. Se não encontrar store, tenta resolver `document` em `identity.hub_tenant.document`,
   exigindo vínculo ativo do usuário com o tenant.
5. Se encontrar tenant, emite token com `login_scope = "tenant"` e campos de store nulos.
6. Se não encontrar nenhum contexto válido, o login falha.

`store_uuid`, `store_code` e `store_name` são sempre `null` em login de tenant.

`login_scope` é obrigatório para o Gestor e possui valores:

- `tenant`
- `store`

---

## 4. Regras de role e contexto

O Hub emite `role`, `tenant_role` e `access_context` como informação básica
de identidade. A autorização fina pertence ao AxysGestor.

### access_context

- `internal`
- `partner`
- `client`

Para `gestor`, tenants com `actor_type = partner` ou
`actor_type = brand_representative` são emitidos com
`access_context = partner`.

### role

O Hub repassa o papel macro do vínculo usuário ↔ tenant:

- `owner`
- `admin`
- `user`
- `viewer`
- `internal_owner`
- `internal_admin`
- `internal_financeiro`
- `internal_user`

O Gestor transforma esse contexto em permissões próprias dentro dos produtos
`sl`, `loccitane` e `gestor`.

### actor_type

`actor_type` vem de `identity.hub_tenant_profile` para o par
`tenant_id + app_code`.

Valores aceitos:

- `internal`
- `client`
- `partner`
- `brand_representative`

Para `app=gestor`, o Hub consulta `identity.hub_tenant_profile` com
`app_code = 'gestor'`.

Se não existir profile ativo, o Hub deve usar a regra conservadora:

- tenant interno Axys: `internal`;
- demais tenants: `client`.

`actor_type` não representa permissão operacional. Ele apenas informa ao
AxysGestor a natureza macro do tenant autenticado.

---

## 5. Regras de emissão

- O produto/app é sempre identificado como `gestor`.
- O JWT segue o mesmo padrão estrutural já usado pelo AxysEasy.
- O Hub só emite token se o tenant possuir licença ativa de ao menos um produto do ecossistema `GESTOR` ou, por compatibilidade, `AXYSGESTOR`.
- O Hub classifica `actor_type` por `identity.hub_tenant_profile`.
- O authorization code é opaco, de uso único e com TTL curto.

### Catálogo inicial de apps licenciadas

O Gestor espelha a estrutura do Easy nas claims `apps_licenciadas`,
`app_labels` e `licencas`.

Slugs iniciais:

- `gestor-sl-company`
- `gestor-loccitane`
- `gestor-analista-vendas`
- `gestor-analista-compras`
- `gestor-notificador`
- `gestor-conciliador`

---

## 6. Configuração esperada no Hub

Variáveis equivalentes às do Easy:

- `GESTOR_BASE_URL`
- `GESTOR_CALLBACK_URL`
- `GESTOR_SSO_AUDIENCE`
- `GESTOR_SSO_ALLOWED_REDIRECT_URIS`
- `GESTOR_SSO_CLIENT_ID`
- `GESTOR_SSO_CLIENT_SECRET`
- `GESTOR_SSO_CODE_TTL_SECONDS`

Sem essas variáveis, o fluxo para `gestor` não autentica clientes externos.
