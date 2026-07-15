# TRD — AxysHub

**Data:** 2026-07-08  
**Objetivo deste TRD:** cruzar o que já existe no Hub, o que está pendente na documentação e a trilha recomendada para levar o projeto a um MVP funcional, coerente com o schema canônico e apresentável em produção.

---

## 1. Leitura executiva

O Hub **não está no zero**. Já existe base real de:

- app FastAPI rodando;
- login contextual por `email + senha + documento do tenant`;
- sessão autenticada;
- telas privadas do portal;
- reset de senha no próprio Hub;
- SSO Hub → Easy;
- integração contratual com serviço externo de Gestor.

O principal problema hoje **não é ausência de app**.  
O principal problema é **desalinhamento entre o backend atual e o schema canônico novo**.

Em termos práticos:

- a app atual já entrega valor;
- o contrato arquitetural amadureceu bastante;
- mas o backend ainda conversa majoritariamente com **modelo legado**;
- então o próximo passo correto não é “inventar mais domínio”;
- é **alinhar a implementação ao contrato canônico do Hub** sem perder o que já está funcionando.

Conclusão objetiva:

> O curso natural recomendado faz sentido, mas no AxysHub ele deve ser lido como **ajuste e consolidação do que já existe**, e não como construção do zero.

Frase de fechamento desta etapa:

> O Hub já deixou de ser um projeto de arquitetura e passou a ser um projeto de consolidação. A maior parte do esforço restante está na convergência entre implementação e contrato, e não na criação de novos domínios.

---

## 2. Não fazer

Neste momento do projeto, alguns movimentos precisam ficar explicitamente proibidos para evitar dispersão e retrabalho.

- **Não** iniciar Billing profundo antes da consolidação do schema e da eliminação do modelo legado no backend.
- **Não** criar novas telas administrativas grandes antes de estabilizar o `Client Portal` mínimo e a camada atual de `/console`.
- **Não** aprofundar Asaas agora.
- **Não** expandir o domínio comercial além do que já está contratado.
- **Não** criar novos módulos ou novas frentes de produto antes da convergência backend ↔ contrato.

Esses itens funcionam como freio de mão do projeto.

---

## 3. Domínios congelados

O objetivo desta seção é impedir que o projeto volte a discutir modelagem já suficientemente amadurecida.

### 3.1 Congelados

- `Identity` — congelado
- `Auth` — congelado
- `Product` — congelado
- `Orders` — congelado
- `Gateway` — congelado
- `Commercial` — congelado

### 3.2 Congelados com margem apenas para correção

- `Billing` — apenas correções e convergência
- `Fiscal` — apenas correções e convergência

Leitura prática:

- não reabrir modelagem desses domínios sem problema técnico real;
- toda energia nova deve ir para implementação aderente;
- a discussão principal saiu de domínio e entrou em consolidação.

---

## 4. Recomendação-base usada como referência

A recomendação trazida foi:

1. Bootstrap FastAPI do Hub
2. Identity
3. Auth contextual
4. Seeds mínimos
5. Client Portal mínimo
6. SSO para Easy
7. Depois billing/Asaas/fiscal

Essa ordem está conceitualmente correta.

No caso do AxysHub, porém, boa parte disso **já foi parcialmente construída**.  
Então a ordem recomendada precisa ser reinterpretada assim:

1. estabilizar bootstrap/runtime/deploy;
2. alinhar identity/auth do código ao schema canônico;
3. consolidar o Client Portal mínimo com dados reais;
4. endurecer SSO/integrações sobre a base já pronta;
5. só depois aprofundar Internal Console e Billing/Asaas.

---

## 5. Cross-check — recomendação x estado atual

### 5.1 Bootstrap FastAPI do Hub

**Status:** parcialmente atendido

**O que já existe**

- `backend/app.py` com FastAPI do Hub/site público
- middleware de sessão
- CORS
- branding
- carregamento de `.env.local`
- `render.yaml` para blueprint inicial do Hub (não aplicado em produção -- a ser empregado)

**Como foi feito**

- o Hub sobe como app única;
- o projeto usa `gunicorn + uvicorn worker` no `render.yaml`;
- o runtime local já foi simplificado para depender só de `.env.local`.

**Gap**

- não há `GET /health` do Hub principal;
- há duplicidade de helper de conexão (`backend/core/db.py` e `backend/modules/hub_portal/db.py`);
- ainda falta consolidar um bootstrap mais explícito do Hub como produto, não apenas como app web funcional.

**Leitura**

O bootstrap já existe, mas ainda está mais “orgânico” do que “fechado”.

### 5.1.1 Ajuste de direção já assumido

O antigo bloco `Gestor/AxysDash` deixou de fazer parte do runtime ativo do Hub.

Diretriz atual:

- o Gestor deve existir como serviço isolado;
- o Hub não deve mais subir essa app localmente;
- o código legado do Gestor foi arquivado fora do runtime ativo do repositório.

---

### 5.2 Identity

**Status:** conceitualmente fechado no schema, parcialmente implementado no backend

**O contrato atual**

No schema canônico, a base de identidade está em:

- `identity.hub_user`
- `identity.hub_tenant`
- `identity.hub_user_tenant`
- `identity.hub_store`
- `identity.hub_user_store`

**O que o backend já usa**

O backend já opera com a lógica correta de:

- usuário global;
- tenant como unidade canônica;
- vínculo usuário ↔ tenant;
- store opcional no Gestor.

Isso aparece, por exemplo, em:

- autenticação no `hub_portal`;
- sessão com `user_id` e `tenant_id`;
- consulta de store no Gestor;
- segregação entre papel externo e papel interno.

**Como foi feito**

- queries diretas em tabelas legadas como `hub_user`, `hub_tenant`, `hub_user_tenant`, `hub_store`;
- o Gestor usa `tenant_id` na sessão e no token;
- já existem verificações de `role`, `internal_role` e `is_staff`.

**Gap estrutural**

O código atual ainda consulta **tabelas legadas sem schema qualificado**, enquanto o schema novo já foi redesenhado por schemas lógicos (`identity`, `auth`, `product`, `billing` etc.).

Ou seja:

- o **domínio de identidade está certo**;
- a **implementação física ainda não está aderente ao schema canônico novo**.

Esse é um ponto central do projeto, mas não é mais o problema número 1 do Hub.

### 5.2.1 O problema número 1 hoje

O maior problema atual do Hub não é mais definição de `Identity`.

O maior problema é:

> **o backend ainda conversa com o modelo legado, enquanto o contrato e o schema canônico novo já estão maduros.**

Ou seja:

- o domínio já foi majoritariamente resolvido;
- o gargalo agora é técnico;
- o esforço principal precisa sair de modelagem e ir para convergência.

---

### 5.3 Auth contextual

**Status:** majoritariamente implementado

**O que já existe**

- login do Hub em `backend/modules/hub_portal/router.py`
- formulário em `backend/hub/templates/auth/login.html`
- fluxo com `email + senha + documento`
- persistência de sessão com:
  - `user_id`
  - `tenant_id`
  - `tenant_code`
  - `tenant_name`
  - `email`
  - `name`

**Como foi feito**

- `authenticate_easy_user(email, password, document)` resolve o usuário já no contexto do tenant;
- o documento é normalizado;
- a sessão atual já nasce contextual;
- o logout já audita `LOGIN`, `LOGIN_FALHA` e `LOGOUT`.

**Aderência à decisão de contrato**

Isso já implementa o núcleo da decisão:

```text
email + senha + CPF/CNPJ do tenant
↓
Hub resolve user + tenant
↓
entra diretamente naquele contexto
```

**Gap**

Ainda não existe a funcionalidade contratada de:

- `Trocar conta` / `Trocar empresa` no header;
- modal com lista de tenants do usuário;
- reautenticação contextual assistida;
- troca auditável de tenant sem multi-sessão.

**Leitura**

O auth contextual **já está vivo**.  
O que falta é a segunda metade da experiência: **troca de tenant na área logada**.

---

### 5.4 Seeds mínimos

**Status:** resolvido no plano documental, não consolidado como base executável única

**O que já existe**

- ADR de seed mínimo do Hub
- schema canônico consolidado em `docs/projects/axys-hub/schemas/schema.sql`
- decisões sobre tenant interno `AXYS`
- decisões sobre papéis internos

**Gap**

- o projeto está em fase de pré-foto/canônico, não em migração aplicada;
- o backend atual depende de tabelas e nomes herdados do modelo antigo;
- hoje não há uma trilha única e simples do tipo:
  - criar banco;
  - aplicar schema canônico;
  - subir app;
  - testar login e portal.

**Leitura**

O problema não é “falta de seed”.  
O problema é **falta de convergência entre schema canônico e backend executável**.

---

### 5.5 Client Portal mínimo

**Status:** UI pronta em boa parte, backend parcialmente real

**O que já existe**

Rotas privadas:

- `/app/dashboard`
- `/app/account`
- `/app/users`
- `/app/products`
- `/app/billing`
- `/app/integrations`
- `/app/security`
- `/app/support`

Templates já criados:

- `backend/hub/templates/app/dashboard.html`
- `account.html`
- `users.html`
- `products.html`
- `billing.html`
- `integrations.html`
- `security.html`
- `support.html`

**Como foi feito**

- o dashboard já cruza catálogo + licenças para montar cards de produtos;
- existe noção de `gestor_access`;
- o portal já usa layout privado coerente;
- o menu/sidebar já está organizado como produto real.

**O que é real hoje**

- login;
- sessão;
- leitura do usuário/tenant;
- leitura de catálogo;
- leitura de licenças;
- geração de acesso ao Gestor;
- rotação de credenciais do Gestor;
- reset de senha no Hub.

**O que ainda é casca**

- `users` ainda está basicamente em modo placeholder;
- `billing` é majoritariamente institucional/placeholder;
- `account` e demais áreas ainda precisam aprofundar CRUD real;
- `Internal Console` existe só em camada mínima.

**Leitura**

O Client Portal mínimo **já existe como produto visual**.  
Ainda falta transformá-lo de “portal bem montado” em “portal operacional com dados e ações reais”.

---

### 5.6 SSO para Easy

**Status:** implementado em nível forte

**O que já existe**

- `/.well-known/jwks.json`
- `POST /auth/login`
- `POST /auth/exchange`
- `GET /sso/easy/start`
- assinatura do token via `backend/core/easy_sso.py`
- claims montadas em `build_easy_sso_claims`
- controle por licença ativa do usuário/tenant

**Como foi feito**

- fluxo do tipo authorization code + exchange;
- código de uso único persistido em `hub_auth_token`;
- emissão de JWT assinado pelo Hub;
- client credentials para o Easy;
- snapshot de licenças Easy embutido nas claims.

**Aderência à recomendação**

Esse ponto já entrega exatamente o valor que o ChatGPT apontou como núcleo:

```text
usuário entra no Hub
↓
Hub resolve tenant
↓
Hub sabe o que ele pode acessar
↓
Hub libera Easy
↓
Easy recebe contexto seguro
```

**Gap**

- ainda há inconsistências históricas de naming/slug entre Hub e Easy em alguns pontos documentados;
- o fluxo está apoiado em modelo legado de tabelas;
- ainda falta a convergência final com o schema canônico novo.

---

### 5.7 Billing / Asaas / Fiscal

**Status:** corretamente não priorizado para agora

**O que existe**

- contrato arquitetural já bem amadurecido;
- página de billing reservada;
- modelagem canônica já discutida;
- separação conceitual entre:
  - Client Portal
  - Internal Console
  - Billing comercial
  - ajustes internos sensíveis

**O que falta**

- desenho detalhado de Asaas;
- implementação de cobrança;
- integração de webhooks;
- aplicação de assinatura/pedido/fatura/licença ponta a ponta;
- console interno de operação de billing.

**Leitura**

A recomendação de **não começar por billing** continua correta.

---

## 6. Pendências registradas x backend x contrato

### 6.1 Pendências já registradas em docs

As pendências abertas mais relevantes hoje são:

1. `README.md`
   - materializar no código o mapa `Client Portal` × `Internal Console`
   - modelar billing/Asaas antes da refatoração profunda de telas
   - consolidar o domínio `Internal`

2. `ARCHITECTURE.md`
   - detalhar a próxima etapa contratual do `Internal Console`
   - detalhar a frente `Billing/Asaas`
   - concluir a implementação da troca de tenant em área logada

3. `contract_price/axys_product_prices.md`
   - definir as faixas de cadastro ativo do `Easy-One`

### 6.2 O que o backend confirma

O backend confirma que:

- login contextual já existe;
- reset de senha já migrou para o Hub;
- SSO para Easy já existe;
- Gestor já consome tenant/contexto/licença;
- o portal privado já está montado;
- o console interno ainda é mínimo;
- billing ainda não virou módulo real.

### 6.3 O que o backend também expõe como risco

O backend também deixa claro que:

- ainda está ancorado em **schema legado**;
- usa nomes e tabelas herdadas como:
  - `hub_user`
  - `hub_tenant`
  - `hub_sistema`
  - `hub_licenca`
  - `hub_assinatura`
  - `hub_plano`
- enquanto o schema novo já está organizado em:
  - `identity.*`
  - `auth.*`
  - `product.*`
  - `orders.*`
  - `billing.*`
  - `gateway.*`
  - `fiscal.*`
  - `commercial.*`
  - `audit.*`

Esse gap é hoje a pendência estrutural central.

---

## 7. Diagnóstico consolidado

### 7.1 O que está sólido

- visão arquitetural do Hub amadurecida;
- schema canônico novo já suficientemente definido para sair do debate;
- login contextual pronto;
- reset de senha no Hub pronto;
- SSO Hub → Easy pronto em base séria;
- portal privado já com boa base visual;
- deploy via Render já encaminhado.

### 7.2 O que está “meio pronto”

- Client Portal com páginas reais, mas nem todas operacionais;
- Internal Console com intenção correta, mas quase sem profundidade;
- integração com Gestor funcional, porém ainda acoplada à modelagem anterior;
- seed/schema/documentação fortes, mas não traduzidos numa trilha única de runtime.

### 7.3 O que está faltando de verdade

1. alinhar backend ao schema canônico novo;
2. terminar a experiência de tenant switching;
3. trocar placeholders do portal por operações reais;
4. estabilizar a fundação antes de abrir Billing/Asaas.

### 7.4 Estado atual — matriz de varredura completa

Abaixo está a matriz consolidada a partir da varredura dos arquivos de backend, UI e `schema.sql`.

| Área | Estado atual | O que já existe | O que é necessário ampliar |
|---|---|---|---|
| Runtime Hub | Parcialmente consolidado | `backend/app.py`, middleware, sessão, branding, páginas públicas, `render.yaml` | Criar `GET /health` do Hub, unificar helpers de DB, endurecer bootstrap/config e observabilidade |
| Runtime Gestor legado | Arquivado | código removido do runtime ativo e guardado em lixo controlado | manter isolado; não reativar dentro do Hub |
| Identity | Implementado no legado, fechado no contrato novo | login resolve `hub_user` + `hub_tenant` + `hub_user_tenant`; Gestor usa `hub_store`; roles internas já existem | Migrar queries para `identity.*`, revisar nomes/colunas e fechar compatibilidade entre legado e canônico |
| Auth web | Funcional | `/login`, `/logout`, sessão contextual, auditoria de login/logout/falha | Implementar troca de tenant assistida, revisar sessão/cookies e alinhar persistência com `auth.*` |
| Password reset | Funcional no Hub | fluxo próprio com e-mail + WhatsApp MFA, `hub_password_reset_session`, auditoria, telas de reset | Aderir ao schema final de `auth/audit`, revisar se a tabela transitória fica como contrato definitivo ou migra para estrutura mais explícita |
| SSO Hub → Easy | Forte | JWKS, `POST /auth/login`, `POST /auth/exchange`, code de uso único, JWT assinado, claims com licenças | Alinhar definitivamente slugs/claims com Easy, migrar para tabelas canônicas (`auth.hub_auth_token`, `billing.hub_user_app`, `billing.hub_license`) |
| Client Portal UI | Bem montado | dashboard, account, users, products, billing, integrations, security, support; layout privado consistente | Transformar placeholders em CRUD e leitura real; incluir `Trocar conta`; revisar copy para produção |
| Dashboard | Semi-real | cruza catálogo + licenças, mostra tenant, papel, acesso Gestor e atalhos | Exibir métricas reais de tenant, usuários, licenças e estados comerciais com base canônica |
| Account | Casca útil | tela dedicada e contexto do usuário/tenant já disponível | Exibir e editar dados reais do usuário e do tenant conforme contrato |
| Users | Placeholder | rota e tela dedicadas, base visual definida | Listagem real, convites, inativação, regras de cota/swap, distinção owner/admin/user |
| Products | Parcialmente real | catálogo e cards com estado de licença, CTA para Easy/Gestor | Ligar ao catálogo novo `product.*`, mostrar oferta/plano/licença de forma contratual |
| Billing page | Placeholder institucional | rota própria e separação visual do módulo | Tornar read-only real com assinatura, pedidos, plano, histórico e limites do Client Portal |
| Internal Console | Mínimo | `/console`, tela inicial, grant/revoke interno, noção de `internal_*` | Mapear telas, visões e operações internas por alçada; adicionar auditoria operacional e gestão de tenants/licenças |
| Gestor legado | Arquivado | código legado preservado apenas como referência controlada | tratar como serviço externo, não como runtime do Hub |
| Branding/assets | Funcional | manifesto remoto, helpers e injeção global em templates | Só ampliar se virar dependência crítica de deploy; por ora está suficiente |
| DB access layer | Inconsistente | `backend/core/db.py` e `backend/modules/hub_portal/db.py` coexistem | Consolidar uma única camada de acesso e preparar repositórios/queries por domínio |
| Schema identity | Fechado no canônico | `identity.hub_user`, `hub_tenant`, `hub_user_tenant`, `hub_store`, `hub_user_store` | Aplicar de fato no runtime e fazer o código parar de depender de nomes não qualificados |
| Schema auth | Fechado no canônico | `auth.hub_auth_token`, `hub_api_registry`, `hub_api_key`, `hub_api_client`, `hub_api_token` | Ajustar backend atual que ainda usa colunas/tabelas legadas como `key_value` em vez de `key_hash` e nomes sem schema |
| Schema product | Muito maduro | `product.ecosystem`, `product.product`, `module`, `offer`, `offer_entitlement`, `offer_policy`, `offer_price`, `addon`, `combo` com seed estrutural | Conectar catálogo visual e regras de produto/preço/licença do backend ao modelo novo; hoje o backend ainda consome `hub_sistema` |
| Schema commercial | Fechado no contrato | partner, lead, attribution, commission_rule/event/payout | Ainda não consumido pelo app atual; abrir só depois da convergência core |
| Schema orders | Fechado no contrato | `orders.hub_order`, item e event | Ainda não materializado no portal; será base futura para billing/pedidos |
| Schema billing | Fechado no contrato | subscription, subscription_item, period, license, license_key, activation, user_app, microapp_instance, microapp_config | É a principal frente de migração do backend atual, que ainda usa `hub_licenca`, `hub_assinatura`, `hub_plano`, `hub_user_app` legado |
| Schema gateway | Fechado no contrato | provider, payment, payment_event, webhook_event | Não puxar agora para implementação profunda; só preparar aderência futura |
| Schema fiscal | Bem encaminhado | company_profile, service_profile, invoice, invoice_item, invoice_event | Manter fora do ciclo atual; depende de orders/gateway/billing consolidados |
| Schema audit | Fechado no contrato | `audit.audit_log`, `login_log`, `billing_audit_log`, `security_event` | Migrar escrita de auditoria do backend atual, que ainda grava em `hub_audit_log` e `hub_login_log` legados |
| Deploy/documentação operacional | Parcial | `render.yaml`, `README`, docs de arquitetura, deploy e integrações | Limpar pendências soltas, centralizar backlog no TRD e revisar runbooks de subida/validação |

**Leitura da matriz**

O estado atual confirma três camadas diferentes convivendo ao mesmo tempo:

1. uma camada de **produto já visível e utilizável**;
2. uma camada de **backend funcional, porém ainda legado em estrutura de dados**;
3. uma camada de **schema canônico novo, mais madura do que a implementação física atual**.

### 7.5 Síntese objetiva da matriz

O backend do Hub já está suficientemente grande para não tratar mais o projeto como protótipo trivial.

Ao mesmo tempo:

- o `schema.sql` novo já está suficientemente detalhado para virar a verdade;
- o código atual ainda não aderiu a ele;
- portanto o principal trabalho agora é **convergência**, não expansão indiscriminada.

### 7.6 Ordem prática de ampliação sugerida pela matriz

1. `identity` + `auth`
2. `audit`
3. `billing` mínimo de licenças/vínculos
4. `Client Portal` real
5. `SSO` e integrações externas sobre a base nova
6. `Internal Console`
7. `orders/gateway/fiscal`

---

## 8. Diretriz recomendada para implementação

### Diretriz principal

O próximo ciclo do AxysHub deve ser:

> **consolidar o Hub como control plane real**, sem expandir billing/fiscal antes da base estar aderente ao modelo canônico.

### Ordem recomendada

1. **Alinhar backend ao schema canônico novo**
2. **Eliminar o modelo legado do backend**
3. **Estabilizar o Client Portal mínimo funcional**
4. **Estabilizar SSO e integrações**
5. **Só então abrir Billing/Asaas e Internal Console profundo**

---

## 9. Sprint 0

### Objetivo

Eliminar a dívida técnica estrutural do Hub antes de qualquer nova expansão funcional.

### Entrega esperada

- backend usando o schema novo;
- migrations coerentes com a base canônica;
- seed minimamente executável para validação;
- login funcionando;
- portal funcionando.

### Regra da Sprint 0

Nada novo é desenvolvido em domínio ou produto.

Esta sprint existe apenas para:

- adaptar queries;
- adaptar services;
- adaptar routers;
- adaptar models/estruturas de acesso;
- remover dependências do modelo legado.

Leitura prática:

> a Sprint 0 é o ponto de inflexão do AxysHub. Antes dela, o projeto ainda carrega dívida estrutural. Depois dela, ele passa a crescer sobre fundação consolidada.

---

## 10. TRD de execução por etapas

## Etapa 1 — Convergência backend ↔ schema canônico

**Objetivo**

Fazer o backend passar a conversar com o modelo novo do Hub, e não mais com o legado implícito.

**Essa é a etapa mais importante do projeto agora.**

**O que precisa ser atacado**

1. mapear todas as queries do backend atual por domínio:
   - identity
   - auth
   - product
   - billing
   - audit

2. comparar cada uma com o schema canônico:
   - tabela atual usada
   - tabela canônica alvo
   - colunas equivalentes
   - gaps de nomenclatura

3. decidir a estratégia de convergência:
   - adaptação do backend ao schema novo;
   - ou camada transitória de compatibilidade.

**Recomendação**

Preferir convergência por domínio, nesta ordem:

1. `identity`
2. `auth`
3. `audit`
4. `billing` mínimo para licenças e vínculo usuário-app
5. `product`

**Resultado esperado**

- o código para de depender do “schema velho invisível”;
- o schema canônico passa a ser realmente a base do Hub;
- a fundação deixa de ser ambígua.

---

## Etapa 2 — Fundacão técnica do Hub

**Objetivo**

Deixar a aplicação com base estável de execução, deploy e observabilidade mínima.

**O que já foi feito**

- `render.yaml` criado
- `.env.local` como fonte local única
- runtime simplificado para subir apenas o Hub

**O que falta fazer**

1. criar `GET /health` no Hub principal;
2. decidir e consolidar um único helper de conexão DB;
3. revisar runtime/config para eliminar variações desnecessárias;
4. validar subida limpa do Hub apenas com:
   - dependências
   - `.env.local`
   - banco local

**Resultado esperado**

- app sobe previsivelmente;
- blueprint do Render fica reproduzível;
- ambiente local deixa de depender de conhecimento tácito.

---

## Etapa 3 — Client Portal mínimo funcional

**Objetivo**

Transformar o portal privado de “boa casca” em “MVP operacional real”.

**Escopo mínimo recomendado**

1. `Dashboard`
   - manter como hub de navegação
   - exibir dados reais do tenant
   - exibir resumo real de licenças
   - exibir estado real do acesso ao Gestor e Easy

2. `Account`
   - exibir dados do usuário autenticado
   - exibir dados do tenant atual
   - permitir edição do que já estiver fechado no contrato

3. `Users`
   - listar usuários do tenant
   - listar roles/vínculos
   - refletir regras de owner/admin/user
   - não abrir ainda o que o contrato marcou como não self-service

4. `Products`
   - listar produtos/licenças reais
   - mostrar contratado, liberado, pendente, expirado
   - integrar melhor com atalhos de acesso

5. `Billing`
   - manter inicialmente read-only
   - exibir assinatura, plano, histórico e pedidos quando a base existir
   - sem ações sensíveis fora do contrato

**Ponto obrigatório desta etapa**

Implementar `Trocar conta` / `Trocar empresa`:

- no header;
- com modal;
- lista de tenants do usuário;
- confirmação por senha;
- encerramento de contexto atual;
- nova sessão/JWT;
- trilha auditável.

**Resultado esperado**

- o usuário percebe o Hub como produto real;
- o fluxo multiempresa deixa de estar incompleto;
- o portal fica coerente com o contrato já fechado.

---

## Etapa 4 — SSO e integrações

**Objetivo**

Endurecer o que já está funcional e consolidar o Hub como fonte de contexto.

**O que já está bem encaminhado**

- JWKS
- exchange code
- emissão de token
- claims
- bloqueio por licença

**O que precisa fechar**

1. alinhar definitivamente os slugs Hub ↔ Easy;
2. validar a aderência completa do token emitido ao consumo real do Easy;
3. revisar TTL, auditoria e rotação de segredo;
4. garantir que o SSO use apenas a base canônica nova após convergência;
5. revisar a integração do Gestor sob a mesma lógica de governança do Hub.

**Resultado esperado**

- o Hub vira o ponto central de identidade e autorização do ecossistema;
- Easy e Gestor passam a confiar numa base estável.

---

## Etapa 5 — Internal Console

**Objetivo**

Subir a camada interna de forma contratualmente coerente, sem inflar UI antes da hora.

**O que já existe**

- `/console`
- noção de `internal_user`, `internal_financeiro`, `internal_admin`, `internal_owner`
- endpoints mínimos de grant/revoke

**O que falta**

- mapa formal de telas e operações internas;
- separação real entre:
  - rotina operacional;
  - financeiro;
  - gestão administrativa sensível;
  - decisões máximas.

**Recomendação**

Começar pelo mínimo:

1. visão de tenants;
2. visão de vínculos/roles;
3. visão de licenças;
4. auditoria de ações;
5. operações internas simples.

Sem abrir ainda renegociação/billing profundo.

---

## Etapa 6 — Billing / Asaas

**Objetivo**

Entrar na frente de cobrança só quando a base Hub já estiver coerente.

**Por que deixar depois**

- o contrato de billing já está relativamente bem discutido;
- mas sua implementação depende de identidade, pedido, licença, auditoria e console interno;
- fazer isso antes só reabriria a fundação.

**Escopo inicial recomendado quando chegar a hora**

1. pedido/assinatura/licença ponta a ponta;
2. read-only no Client Portal;
3. operações sensíveis na Internal Console;
4. webhooks Asaas;
5. transição controlada para invoice/fiscal.

---

## 11. Definição prática de MVP do Hub

O MVP funcional do AxysHub, para considerar a base “boa para crescer”, deve ser:

1. usuário consegue logar com `email + senha + documento do tenant`;
2. Hub resolve corretamente usuário, tenant e role;
3. usuário consegue trocar de empresa na área logada;
4. portal exibe dados reais de tenant, usuários e licenças;
5. Hub libera Easy com token correto;
6. Gestor respeita contexto seguro do tenant;
7. tudo isso roda sobre a base canônica consolidada do Hub.

Se isso estiver pronto, o Hub deixa de ser “refactor em aberto” e passa a ser:

> **control plane executável do ecossistema Axys**

---

## 12. Recomendação final

Se a pergunta for “qual o próximo movimento mais inteligente?”, a resposta é:

> **não abrir Billing/Asaas agora**  
> **não abrir novas telas grandes agora**  
> **não redesenhar mais domínio agora**

O próximo movimento correto é:

1. alinhar backend ao schema canônico;
2. eliminar o modelo legado do backend;
3. fechar o Client Portal mínimo funcional;
4. completar a troca de tenant;
5. endurecer SSO/integrações.

Depois disso, sim:

- Internal Console ganha corpo;
- Billing/Asaas entra com muito menos retrabalho;
- o Hub passa a escalar sem refatoração traumática.

---

## 13. Síntese curta

O Hub já passou da fase de ideia.  
Ele também ainda não chegou na fase de fundação fechada.

Hoje ele está exatamente no ponto de:

> **parar de discutir demais o modelo e começar a consolidar a base real já construída**

Essa consolidação deve ser guiada por um princípio simples:

> **o schema canônico novo precisa virar a verdade do backend, e o portal já existente precisa virar operação real**

Outra forma de dizer a mesma coisa:

> o AxysHub precisa parar de evoluir horizontalmente e começar a consolidar verticalmente.
