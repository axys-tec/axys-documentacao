# ADR-022 — Licenciamento Centralizado e Validação Local no ERP

**Status:** Aprovado  
**Data:** 2026-02-03  
**Stack:** AxysHub (FastAPI) + ERP Local  
**Escopo:** Licenciamento, operação offline, validação local, modo degradado

---

## 1. Contexto

O ecossistema Axys contempla cenários onde o **ERP local** pode operar com conectividade
limitada ou temporariamente indisponível, sem comprometer:

- Continuidade operacional mínima
- Segurança de licenciamento
- Governança centralizada
- Capacidade de auditoria posterior

Historicamente, modelos de licenciamento acoplados à conectividade online geram:
- Interrupções críticas de operação
- Exceções locais não rastreáveis
- Divergência de regras entre servidor e cliente

Este ADR define o **modelo oficial de licenciamento do Axys**, no qual o **AxysHub é a autoridade central**
e o **ERP executa validações locais temporárias**, de forma controlada.

> **Regra-mãe:** o Hub controla; o ERP executa; o frontend apenas exibe.

---

## 2. Decisão

Foi decidido implementar um **modelo de licenciamento centralizado no AxysHub**, com
**validação local no ERP via Lease Token temporário**, permitindo operação offline limitada.

### 2.1 Princípios obrigatórios

- O AxysHub é a **fonte da verdade** de licenças e planos
- O ERP **não decide licenciamento**
- Tokens são **temporários, assinados e auditáveis**
- Offline é **modo degradado**, nunca modo pleno
- Toda validação local é **derivada de decisão central**

---

## 3. Componentes do Modelo

### 3.1 Endpoints do AxysHub

- `POST /api/v1/dash/auth/login-user`  
  Autentica??o do usu?rio e emiss?o de `access_token`.

- `POST /api/v1/dash/auth/login`  
  Autentica??o client-credentials (ERP/ingest).

- `POST /api/licensing/lease`  
  Emite um **Lease Token** (JWT) para validação local.

- `GET /api/policies/{tenant_id}/bundle`  
  Retorna bundle de políticas e limites vigentes.

### 3.2 Lease Token (JWT)

O Lease Token é um **direito temporário de execução local**.

**Claims obrigatórias:**
- `iss`
- `tenant_id`
- `license_id`
- `plan_code`
- `modules`
- `limits`
- `policy_version`
- `fingerprint`
- `iat`
- `exp`

Tokens expirados ou inválidos **não autorizam operação plena**.

---

## 4. Validação Local no ERP

### 4.1 Middleware de Licenciamento

Fluxo obrigatório no ERP:

1. Carregar Lease Token do cache local
2. Validar assinatura criptográfica
3. Validar expiração (`exp`)
4. Validar `fingerprint`
5. Aplicar escopo de módulos e limites

### 4.2 Falha de Validação

Em caso de falha:

- Bloquear funcionalidades não essenciais
- Ativar **modo degradado**
- Registrar evento local para auditoria futura

---

## 5. Cache Local

### 5.1 Diretrizes

- Armazenamento local criptografado
- Um cache por tenant
- Persistência mínima necessária
- Registro de data/hora da última renovação

O cache **não substitui** o Hub e **não estende validade** do token.

---

## 6. Renovação em Background

- Scheduler local executa **1x ao dia**
- Tentativa silenciosa de renovação
- Falha de renovação não interrompe operação imediata
- Expiração final do token força modo degradado

---

## 7. Assinatura de Artefatos (Opcional)

O Hub pode atuar como **autoridade de assinatura** para documentos e artefatos.

Endpoint:
- `POST /api/sign/artifact`

Uso:
- Validação de integridade
- Prova temporal
- Auditoria técnica

---

## 8. Segurança

- Tokens sempre assinados
- Fingerprint obrigatório por ambiente
- Logs sem exposição de dados sensíveis
- Nenhum segredo armazenado em texto puro
- ERP nunca emite nem altera tokens

---

## 9. Consequências

### Positivas
- Operação resiliente a falhas de conexão
- Governança central preservada
- Auditoria clara de licenciamento
- Redução de exceções locais

### Negativas
- Complexidade adicional no ERP
- Implementação inicial mais rigorosa

Essas consequências são consideradas **aceitáveis e desejáveis**.

---

## 10. Status Final

Este ADR é **normativo** para todo o ecossistema Axys.

Qualquer alteração em:
- estrutura do Lease Token
- política offline
- fingerprint
- modo degradado

**exige novo ADR**. Modificações silenciosas são proibidas.
