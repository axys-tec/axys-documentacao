# AXYS-ADR-021 — SSO via JWT entre Hub e aplicações

- **Status:** Aceito
- **Data:** 2026-01-25
- **Autor:** AxysHub Core
- **Contexto:** Ecossistema Axys
- **Decisão Relacionada a:** AXYS-ADR-002, AXYS-ADR-003, AXYS-ADR-006

---

## 1. Contexto

O ecossistema Axys é composto por múltiplas aplicações (Easy, Pro, Sync) que precisam autenticar usuários de forma centralizada (AxysHub).

Era necessário definir um padrão único de autenticação e autorização que:
- centralizasse validação de credenciais em AxysHub;
- permitisse que aplicações validassem tokens localmente (offline-first);
- mantivesse informações de permissões no token (self-contained);
- suportasse multitenancy;
- fosse stateless nas aplicações cliente.

---

## 2. Forças e Restrições

- múltiplas aplicações independentes (Easy, Pro, Sync);
- necessidade de operação offline controlada;
- segurança: validação de assinatura e expiração;
- aplicações precisam de claims (roles, tenant_uuid);
- padrão maduro (JWT é amplamente adotado).

---

## 3. Opções Consideradas

### 3.1 Opção A — Sessões no servidor (stateful)
Server-side sessions com token de sessão.

**Contras:**
- requer conexão contínua com Hub;
- não funciona offline;
- escalabilidade reduzida.

---

### 3.2 Opção B — JWT assinado por Hub (stateless)
Aplicações validam JWT localmente com chave pública de Hub.

**Prós:**
- stateless (escalável);
- funciona offline (validação local);
- self-contained (não precisa ir ao Hub para validar);
- padrão maduro (RFC 7519).

**Contras:**
- revogação de token requer lista de bloqueio (blacklist);
- token ativo até expiração.

---

## 4. Decisão

Adotar **JWT assinado por AxysHub (Opção B)** com:
- Algoritmo: **RS256** (assinatura assimétrica)
- Validação: Aplicações usam chave pública de Hub
- Claims: `sub`, `email`, `tenant_uuid`, `tenant_code`, `role`, `apps_licenciadas`
- TTL: 8 horas (padrão)
- Offline: Valida JWT offline até 24h (grace period)

---

## 5. Justificativa

RS256 (assimétrica) é superior a HS256 (simétrica) porque:
- apenas Hub possui chave privada (pode assinar);
- qualquer aplicação pode validar com chave pública (sem segredo compartilhado);
- segurança aumentada contra comprometimento de chave.

Offline-first permite operação mesmo sem contato com Hub, respeitando a arquitetura offline-tolerant do ecossistema.

---

## 6. Consequências

### 6.1 Positivas
- autenticação centralizada + autorização descentralizada (offline-first);
- cada aplicação não precisa validar no Hub toda requisição;
- token contém informações de permissões (claims);
- escalável (stateless).

### 6.2 Negativas / Custos
- revogação imediata não é possível (token ativo até expiração);
- necessidade de blacklist para revogação forçada;
- distribuição de chave pública para aplicações.

---

## 7. Escopo e Limitações

Esta decisão:
- aplica-se a toda autenticação no ecossistema Axys;
- define formato e algoritmo de JWT;
- não define armazenamento de token no cliente (cada app escolhe);
- não define refresh token (pode ser implementado separadamente).

---

## 8. Implementação

### Assinatura (Hub)

```python
import jwt
from datetime import datetime, timedelta

private_key = open('hub_private_key.pem').read()

claims = {
    'sub': 'user-uuid',
    'email': 'user@company.com',
    'name': 'User Name',
    'tenant_uuid': '550e8400-...',
    'tenant_code': 'ACME',
    'role': 'admin',
    'apps_licenciadas': ['easy-cpu', 'easy-price'],
    'iat': datetime.utcnow(),
    'exp': datetime.utcnow() + timedelta(hours=8)
}

token = jwt.encode(claims, private_key, algorithm='RS256')
```

### Validação (Easy/Pro/Sync)

```python
public_key = open('hub_public_key.pem').read()

try:
    claims = jwt.decode(token, public_key, algorithms=['RS256'])
    # Token válido
except jwt.ExpiredSignatureError:
    # Token expirado
except jwt.InvalidSignatureError:
    # Token falsificado
```

---

## 9. Revisão e Evolução

Esta decisão pode ser revista se:
- houver mudança em requirements de autenticação;
- necessidade de revogação imediata (implementar blacklist);
- mudança de infraestrutura.

---

## 10. Registro

Decisão integra o histórico arquitetural oficial do Axys.
