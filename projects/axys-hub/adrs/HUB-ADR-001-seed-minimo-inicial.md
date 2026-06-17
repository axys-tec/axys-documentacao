# ADR-011 — AxysHub: Seed Mínimo Inicial

**Status:** Aprovado — Atualizado em 2026-05-25
**Data original:** 2026-02-03
**Contexto:** AxysHub
**Tipo:** Arquitetural / Governança / Dados

---

## 1. Contexto

O AxysHub é o núcleo de governança do ecossistema Axys, responsável por:

- Tenancy (multi-tenant real)
- Identidade de usuários e vínculos com tenants
- Catálogo de sistemas e microapps
- Licenciamento e assinaturas
- Auditoria central
- Integração com sistemas externos (AxysGestor, AxysPro, etc.)

Este ADR define o **Seed Mínimo Inicial** como referência canônica do projeto, servindo como:

- Base para onboarding de ambientes novos
- Contrato técnico entre backend, dados e mobile
- Proteção contra decisões improvisadas no setup inicial

O arquivo de execução é: `db/hub_seed.sql`

---

## 2. Decisão

Seed mínimo obrigatório, idempotente (ON CONFLICT seguro), versionado neste ADR.

### 2.1 Sistemas (hub_sistema)

10 sistemas vendáveis do ecossistema cadastrados no seed:

| sistema_code       | nome               | tipo     |
|:-------------------|:-------------------|:---------|
| AXYSPRO            | AxysPro            | suite    |
| AXYSGESTOR         | AxysGestor         | microapp |
| EASYCPU            | EasyCPU            | microapp |
| EASYORCA           | EasyOrça           | microapp |
| EASYPRICE2         | EasyPrice 2        | microapp |
| EASYPRICE          | EasyPrice          | microapp |
| EASYPROJECTMANAGER | EasyProjectManager | microapp |
| EASYBUILDDIARY     | EasyBuildDiary     | microapp |
| EASYLICITPLAN      | EasyLicitPlan      | microapp |
| EASYFINCONTROL     | EasyFinControl     | microapp |
| EASYDOCS           | EasyDocs           | microapp |

### 2.2 Tenants (hub_tenant)

| tenant_code | tenant_name | document (fiscal)  | Natureza            |
|:------------|:------------|:-------------------|:--------------------|
| AXYS        | Axys Engenharia e Tecnologia Ltda | 38060729810 (CPF)  | Conta interna Axys  |
| LUNALO      | Lunalô      | 45580611000194     | Cliente             |
| DCENG       | D&CEng      | 17695703000184     | Cliente             |

`document`: CNPJ (14 dígitos) ou CPF (11 dígitos), sem máscara, **NOT NULL**.

### 2.3 Usuários (hub_user)

| email                            | name            | sys_role  | tenant  | role (tenant)   |
|:---------------------------------|:----------------|:----------|:--------|:----------------|
| rdias07@live.com                 | Renan Dias      | hub_admin | AXYS    | internal_owner  |
| thays_hernandes@hotmail.com      | Thaís           | user      | AXYS    | internal_user   |
| lunalocalcados@hotmail.com       | Lunalô Calcados | user      | LUNALO  | admin           |
| rdias07@live.com                 | Renan Dias      | hub_admin | DCENG   | owner           |
| thays_hernandes@hotmail.com      | Thaís           | user      | DCENG   | admin           |
| diasecardozo@diasecardozo.com.br | Dias e Cardozo  | user      | DCENG   | user            |

Campos obrigatórios preenchidos no seed:

- `cpf`: **NOT NULL** — seed usa placeholders `0000000000X` (substituir com CPFs reais antes de produção)
- `address_json`: **NOT NULL** — seed usa `{}` (atualizar com endereço real)
- `sys_role`: `hub_admin` para rdias07 (acesso ao painel admin do Hub); `user` para os demais
- `password_hash`: bcrypt de `axys@seed2026` — **trocar manualmente em produção**

### 2.4 Stores (hub_store)

| store_code | store_name                    | tenant  |
|:-----------|:------------------------------|:--------|
| AXYSSYSTEM | AxysSystem                    | AXYS    |
| OUROESTE   | Lunalô Ouroeste               | LUNALO  |
| JALES      | Lunalô Jales                  | LUNALO  |
| LOC-JALES  | L'Occitane Jales              | LUNALO  |
| DCENG      | Dias & Cardozo - Eng. e Arq.  | DCENG   |

### 2.5 Licenças (hub_licenca)

- **AXYS**: sistemas internos e apps Easy liberados no bootstrap inicial
- **LUNALO**: apenas `AXYSGESTOR` (`AxysGestor`)
- **DCENG**: apps Easy liberadas no bootstrap inicial

### 2.6 Princípios obrigatórios

- Nenhuma exceção hardcoded por tenant na lógica de produto
- Planos e licenças resolvem privilégios
- UUID como chave primária
- Tokens e chaves nunca armazenados em texto puro
- Seed idempotente — seguro para re-execução em produção
- `ON CONFLICT (email) DO NOTHING` em hub_user: nunca sobrescreve senha de produção

---

## 3. Consequências

**Positivas:**
- Onboarding previsível e reproduzível
- Ambientes de dev/staging sincronizados com produção na estrutura
- Seed como contrato vivo — alterações exigem atualização deste ADR

**Negativas / compensações:**
- CPFs e endereços reais não podem ser commitados no repositório
- Seed mais extenso que o mínimo absoluto (10 sistemas vendáveis + 3 tenants + 4 usuários)

---

## 4. Arquivo de execução

```
db/hub_seed.sql
```

Executar após `db/hub_schema.sql`. Idempotente — pode ser re-executado a qualquer momento.

Pós-execução obrigatória em ambientes reais:
```sql
-- Substituir CPFs placeholder pelos reais
UPDATE hub_user SET cpf = '<cpf_real>' WHERE email = '<email>';

-- Atualizar endereços
UPDATE hub_user SET address_json = '{...}' WHERE email = '<email>';

-- Trocar senha padrão de seed
UPDATE hub_user SET password_hash = crypt('<nova_senha>', gen_salt('bf', 10))
WHERE email = '<email>';
```

---

## 5. Versionamento

Alterações estruturais no seed (novos tenants, usuários ou sistemas canônicos) exigem:
1. Atualização de `db/hub_seed.sql`
2. Atualização deste ADR (seção 2)
3. Migration em `db/migration/` se o banco já existir em produção
