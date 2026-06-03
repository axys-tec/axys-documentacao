# ADR-020 — Compliance, LGPD e Política de Retenção de Dados

- **Status:** Aceito
- **Data:** 2026-01-25
- **Autor:** AxysHub Core
- **Contexto:** AxysHub Core, Jurídico e Segurança
- **Decisão Relacionada a:** ADR-001, ADR-006, ADR-012

---

## 1. Contexto

O Axys lida com dados empresariais sensíveis, Arquivos técnicos, informações financeiras e registros de usuários.

Era necessário definir diretrizes de compliance que:
- atendam à LGPD;
- protejam dados dos tenants;
- definam retenção e descarte;
- sejam compatíveis com ambientes cloud e on-premises.

---

## 2. Forças e Restrições

- múltiplos tenants independentes;
- responsabilidade compartilhada em on-premises;
- necessidade de rastreabilidade;
- requisitos legais variáveis.

---

## 3. Decisão

Fica definido que:

- o Axys adota princípios da **LGPD por padrão**;
- dados pertencem ao tenant;
- retenção e descarte seguem política configurável;
- logs e auditorias possuem retenção mínima obrigatória;
- o Core mantém registros de governança, não dados operacionais.

---

## 4. Justificativa

Essa política protege usuários, clientes e o próprio ecossistema Axys, reduzindo riscos legais e operacionais.

---

## 5. Diretrizes de Implementação

- dados sensíveis devem ser classificados;
- exclusões devem ser auditáveis;
- backups respeitam política de retenção;
- exportação de dados deve ser possível.

---

## 6. Escopo e Limitações

Esta decisão:
- não substitui assessoria jurídica;
- define diretrizes técnicas mínimas;
- aplica-se a todo o ecossistema Axys.

---

## 7. Registro

Esta decisão integra o histórico arquitetural oficial do Axys.

---

### Histórico
- **ADR-020:** Criado e aceito
