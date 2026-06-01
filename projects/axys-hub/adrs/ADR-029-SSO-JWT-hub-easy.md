# ADR-029 — Autenticação SSO com JWT entre AxysHub e AxysEasy

- **Status:** Aceito
- **Data:** 2026-05-23
- **Autor:** AxysHub Core
- **Contexto:** Infraestrutura / Autenticação cross-serviço
- **Decisão Relacionada a:** ADR-002 (Licenciamento Centralizado), ADR-003 (Separação Core/Módulos/Microapps), ADR-025 (Licenciamento Lease Token), ADR-026 (Autenticação Client Credentials)

---

## 1. Contexto

O ecossistema Axys será composto por dois sistemas independentes com repositórios, deploys e bancos de dados separados:

- **AxysHub** (`axys-tec.com.br`) — plataforma de licenciamento, billing, gestão de tenants e portal do cliente.
- **AxysEasy** (`easy.axys-tec.com.br`) — ecossistema de microapps operacionais (Easy CPU, Easy Price, Easy Orça, EasyDocs, Easy ProjectManager, Easy BuildDiary, Easy FinControl, Easy LicitPlan).

O usuário precisa transitar entre os dois sistemas sem perceber a separação — experiência de produto unificada. O AxysEasy precisa identificar o tenant e validar quais microapps estão licenciadas, sem manter cadastro próprio de usuários e sem acessar o banco do hub diretamente.

O hub atualmente emite tokens opacos (hash SHA-256/HMAC). Essa estrutura não é diretamente validável por um serviço externo sem consultar o hub a cada request.

---

## 2. Forças e Restrições

- Os dois sistemas são isolados fisicamente — sem banco compartilhado.
- O AxysEasy não deve manter cadastro próprio de tenants ou usuários.
- A validação de identidade e licença não pode criar dependência de runtime entre os serviços (se o hub cair, o easy não pode parar de funcionar para sessões já abertas).
- O cancelamento de assinatura deve ser refletido em tempo razoável (não pode o usuário continuar usando indefinidamente após cancelar).
- Dados financeiros e de identidade permanecem exclusivamente no hub.
- O AxysEasy precisa persistir dados operacionais (histórico de processamentos, arquivos gerados) vinculados ao tenant.

---

## 3. Opções Consideradas

### 3.1 Opção A — Token opaco com validação por chamada de API (introspection)

O easy chama `GET /auth/me` no hub a cada request autenticado para validar o token e obter dados do tenant.

**Prós:**
- Revogação imediata (hub invalida o token, easy rejeita na próxima chamada)
- Simples de implementar no easy

**Contras:**
- Acoplamento de runtime: se o hub ficar indisponível, o easy para de autenticar
- Latência adicional em todo request autenticado
- Não escala bem sob carga alta

---

### 3.2 Opção B — JWT assinado pelo hub, validado localmente pelo easy

O hub emite um JWT de vida curta (1h) assinado com chave privada RSA ou ECDSA. O easy valida localmente com a chave pública — sem chamar o hub. Um refresh token de vida longa é usado para renovar o JWT; o hub invalida o refresh token no cancelamento.

**Prós:**
- Zero latência de validação no easy (validação local, criptográfica)
- Easy funciona mesmo se hub estiver momentaneamente indisponível
- Padrão amplamente adotado na indústria (OAuth 2.0 / OIDC)
- Revogação efetiva via refresh token (vida curta do access token limita janela de exposição)

**Contras:**
- Exige evolução do mecanismo atual de token do hub (tokens opacos → JWT)
- Janela de exposição de até 1h se um access token for comprometido antes de expirar

---

### 3.3 Opção C — Cadastro próprio de tenant no easy com sincronização

O easy mantém sua própria tabela de tenants, sincronizada via webhook do hub.

**Contras:**
- Duplicação de dados de identidade
- Problema de consistência (resíduo de dados desatualizados)
- Contradiz o princípio de isolamento de responsabilidades

---

## 4. Decisão

Fica definido que a autenticação entre AxysHub e AxysEasy será baseada em **SSO com JWT assinado pelo hub e validado localmente pelo easy**.

- O hub é o **único emissor** de tokens de identidade no ecossistema.
- O easy **nunca** armazena senhas, dados de identidade ou informações financeiras.
- O easy usa o `tenant_uuid` extraído do JWT como chave estrangeira em seus dados operacionais — sem tabela própria de tenants.
- É permitido que `easy.axys-tec.com.br` exiba uma tela de login própria, desde que essa tela chame o endpoint de autenticação do hub (não autentique localmente).

---

## 5. Justificativa

O JWT é o padrão consolidado para SSO em ecossistemas SaaS multi-serviço (Atlassian, Google Workspace, HubSpot). Resolve o problema de isolamento físico sem criar dependência de runtime, mantendo o hub como única fonte de verdade sobre identidade e licenciamento.

A vida curta do access token (1h) é o trade-off aceito entre segurança (revogação) e disponibilidade. Para a fase inicial do produto, essa janela é adequada.

---

## 6. Consequências

### 6.1 Consequências Positivas
- Experiência de produto unificada: usuário loga uma vez, usa todos os serviços.
- Easy funciona de forma autônoma para sessões abertas, mesmo com hub indisponível.
- Escalabilidade: validação local não gera carga no hub.
- Dados de identidade e financeiros ficam exclusivamente no hub.

### 6.2 Consequências Negativas / Custos
- Exige refatoração do mecanismo de token do hub: tokens opacos atuais → JWT assinado.
- Janela de até 1h de acesso após revogação do refresh token (mitigável com tokens de vida ainda mais curta).
- Gestão de par de chaves pública/privada (rotação, segurança da chave privada).

### 6.3 Impactos Técnicos

**Hub (AxysHub):**
- Novo endpoint de emissão de JWT: `POST /auth/token` (access token + refresh token)
- Novo endpoint de refresh: `POST /auth/refresh`
- Novo endpoint de revogação: `POST /auth/revoke` (invalida refresh token no cancelamento)
- Chave pública exposta em: `GET /.well-known/jwks.json`
- Payload mínimo do JWT: `{ tenant_uuid, tenant_name, email, apps_licenciadas[], exp, iat, iss }`

**Easy (AxysEasy):**
- Middleware de validação JWT com chave pública do hub
- Tabela `tenant_uuid` como FK em todos os dados operacionais
- Sem tabela de usuários própria
- Renovação automática de access token via refresh token

---

## 7. Escopo e Limitações

- Esta decisão se aplica à autenticação entre AxysHub e AxysEasy.
- Não cobre autenticação de integrações com ERPs externos (coberta por ADR-012 e ADR-027).
- Não cobre autenticação máquina-a-máquina entre microapps internas (Client Credentials, coberto por ADR-026).
- O AxysEasy não está autorizado a emitir tokens — apenas o hub.

---

## 8. Diretrizes de Implementação

- O hub deve assinar JWTs com **RS256 ou ES256** (assimétrico) — nunca HS256 (simétrico compartilhado).
- O access token deve ter vida máxima de **1 hora**.
- O refresh token deve ter vida máxima de **30 dias**, com renovação por uso (sliding window).
- A chave pública deve estar disponível em `/.well-known/jwks.json` no hub para que o easy possa rotacionar sem redeploy.
- No cancelamento de assinatura: o hub invalida o refresh token imediatamente; o access token expira naturalmente.
- O campo `apps_licenciadas` no JWT deve listar apenas as microapps com licença ativa no momento da emissão.

### 8.1 Refatoração necessária no AxysHub (pré-condição para integração com o AxysEasy)

> **Estado atual do hub:** o mecanismo de autenticação existente (`backend/core/security.py`, `backend/api/axysdash/routes_auth.py`, `backend/api/axysdash/service_auth.py`) emite **tokens opacos** armazenados com hash SHA-256/HMAC. Esse mecanismo não é validável por um serviço externo sem consultar o hub.

Esta refatoração **não é urgente agora** — deve ser executada quando o AxysEasy estiver pronto para integrar. Os itens obrigatórios são:

| Componente | Mudança necessária |
|---|---|
| `service_auth.py` | Emitir JWT assinado (RS256) em vez de token opaco |
| `security.py` | Adicionar validação de JWT além do hash atual |
| Nova rota `POST /auth/refresh` | Renovação de access token via refresh token |
| Nova rota `POST /auth/revoke` | Revogação de refresh token (acionada no cancelamento) |
| Nova rota `GET /.well-known/jwks.json` | Expor chave pública para validação pelo easy |
| Banco do hub | Tabela de refresh tokens com flag de revogação |

O mecanismo atual de tokens opacos pode coexistir durante a transição — usado para autenticação interna do hub (AxysDash, Client Credentials) enquanto o JWT é adotado progressivamente para SSO com o easy.

---

## 9. Revisão e Evolução

- (x) Sim, sob as seguintes condições:
  - Adoção de provedor de identidade externo dedicado (Keycloak, Auth0) — nesse caso esta ADR é substituída por implementação OIDC completa.
  - Mudança no modelo de licenciamento que exija validação em tempo real por request.

---

## 10. Registro

Esta decisão integra o **histórico arquitetural oficial do Axys**.

Qualquer mudança que a contradiga deve ser registrada em um novo ADR, referenciando explicitamente este documento.

---

### Histórico
- **ADR-029:** Criado em 2026-05-23
