# HUB V1 Freeze

**Data:** 2026-07-08  
**Status:** Ativo

---

## Objetivo

Marcar formalmente o fim da fase principal de arquitetura/modelagem do AxysHub V1 e o início da fase de consolidação e implementação.

---

## Freeze

### Artefatos congelados

- `schema.sql` do Hub: congelado para V1, salvo correções pontuais
- `trd_axyshub.md`: congelado como referência de execução
- ADRs do Hub: só entram novas ADRs se surgir decisão realmente nova

### Domínios congelados

- `Identity`
- `Auth`
- `Product`
- `Orders`
- `Gateway`
- `Commercial`

### Domínios com margem apenas para correção e convergência

- `Billing`
- `Fiscal`

---

## Regra de decisão

Daqui em diante, todo trabalho do Hub deve responder à pergunta:

> **Isso aproxima a implementação do contrato canônico?**

Se a resposta for **não**, a tendência é que o item não entre na sprint.

---

## Restrições

- Não reabrir discussões amplas de modelagem sem problema técnico real.
- Não criar novos módulos antes da consolidação do backend sobre o schema canônico.
- Não aprofundar Billing/Asaas antes da convergência do core.
- Não expandir novas telas administrativas grandes antes da estabilização do portal atual.

---

## Foco da fase atual

O AxysHub V1 entra oficialmente em fase de:

> **consolidação vertical**

Prioridade:

1. alinhar backend ao schema canônico
2. eliminar o modelo legado
3. estabilizar login, sessão, portal e SSO
4. só depois expandir funcionalidades

---

## Critério para mudanças estruturais

Mudanças estruturais relevantes em schema, domínio ou arquitetura só devem ocorrer mediante revisão arquitetural explícita.

Correções pontuais, ajustes de implementação e convergência técnica continuam permitidos e esperados.
