# ADR-001 — Estratégia de Tenancy e Isolamento de Dados

- **Status:** Aceito
- **Data:** 2026-01-25
- **Autor:** AxysHub Core
- **Contexto:** AxysHub Core e MicroApps
- **Decisão Relacionada a:** —

---
> **Hierarquia Documental**
>
> Esta ADR é subordinada à **Regra-Mãe do Ecossistema Axys** e ao **Contrato Geral do AxysHub**.
> Suas decisões não congelam arquitetura nem impedem evolução técnica, devendo ser
> interpretadas como decisões arquiteturais válidas para o contexto descrito,
> passíveis de revisão mediante novo ADR devidamente justificado.
>

## 1. Contexto

O ecossistema Axys foi concebido para atender tanto a uso interno de um escritório de engenharia quanto a múltiplas empresas externas por meio de microapps.

As soluções de mercado analisadas apresentaram limitações relevantes quanto a:
- isolamento inadequado de dados entre empresas;
- dependência excessiva de filtros por usuário;
- risco de vazamento acidental de informações;
- dificuldade de escalar volume de dados e clientes.

Diante disso, tornou-se necessário definir uma **estratégia clara, defensável e escalável de tenancy**, aplicável de forma consistente em todo o ecossistema Axys.

---

## 2. Forças e Restrições

- necessidade de isolamento rigoroso entre empresas;
- possibilidade de múltiplos tenants com grandes volumes de dados;
- existência de um Core Axys responsável por governança;
- microapps com naturezas distintas (mensal, por uso, híbridas);
- viabilidade técnica de múltiplos bancos por servidor;
- obrigação de evitar soluções frágeis baseadas apenas em permissões de usuário.

---

## 3. Opções Consideradas

### 3.1 Opção A — Filtro por usuário (`id_user`)
Isolamento lógico baseado em usuário.

**Prós:**
- simplicidade inicial;
- menor esforço de implementação.

**Contras:**
- alto risco de vazamento de dados;
- acoplamento entre identidade e domínio;
- escalabilidade limitada;
- abordagem considerada tecnicamente frágil.

---

### 3.2 Opção B — Filtro por tenant em todas as tabelas
Isolamento lógico por coluna `tenant_id`.

**Prós:**
- isolamento explícito;
- compatível com banco único.

**Contras:**
- risco de erro em consultas;
- dependência constante de disciplina de desenvolvimento;
- dificuldade de migração futura para bancos dedicados.

---

### 3.3 Opção C — Banco de dados por tenant (com Control Plane)
Isolamento estrutural entre empresas, com um Core central.

**Prós:**
- isolamento real e incontornável;
- facilidade de backup, restore e migração;
- escalabilidade previsível;
- alinhamento com arquitetura de longo prazo.

**Contras:**
- necessidade de automação de migrations;
- maior complexidade operacional inicial.

---

## 4. Decisão

Fica definido que:

- o **AxysHub Core opera em regime single-tenant**, como plano de controle (control plane);
- **microapps do ecossistema Axys operam em regime multi-tenant**;
- o isolamento entre tenants deve ser **estrutural**, preferencialmente por **banco de dados dedicado por tenant**;
- soluções baseadas exclusivamente em `id_user`, concatenação de nomes ou filtros implícitos são **proibidas**.

---

## 5. Justificativa

A decisão por isolamento estrutural garante:
- segurança de dados entre empresas;
- previsibilidade operacional;
- facilidade de escala;
- redução de risco humano em queries e integrações;
- liberdade para evolução futura sem ruptura arquitetural.

Embora a abordagem exija maior disciplina inicial, ela se alinha aos princípios de governança e longevidade do Axys.

---

## 6. Consequências

### 6.1 Consequências Positivas
- isolamento absoluto entre tenants;
- backups e restores independentes;
- migração seletiva de clientes;
- facilidade de auditoria.

### 6.2 Consequências Negativas / Custos
- necessidade de automação de migrations;
- gestão de múltiplos bancos;
- maior cuidado com pool de conexões.

### 6.3 Impactos Técnicos
- introdução de Control Plane para tenants;
- padronização de acesso a banco por tenant;
- impossibilidade de consultas cruzadas entre empresas.

---

## 7. Escopo e Limitações

Esta decisão:
- **aplica-se** a todas as microapps Axys;
- **não se aplica** ao Core AxysHub;
- **não permite exceções** baseadas em conveniência de implementação.

---

## 8. Diretrizes de Implementação

- o tenant deve ser resolvido antes de qualquer acesso a dados;
- cada tenant deve possuir datastore isolado;
- migrations devem ser versionadas e automatizadas;
- o Core mantém apenas metadados e governança.

---

## 9. Revisão e Evolução

- Esta decisão pode ser revista?  
  - ( ) Não  
  - (X) Sim, apenas se surgirem limitações técnicas graves comprovadas.

- Indicadores de reavaliação:
  - inviabilidade operacional comprovada;
  - mudança estrutural do modelo de negócios.

---

## 10. Registro

Esta decisão integra o **histórico arquitetural oficial do Axys**.

Qualquer alteração que a contradiga deve ser formalizada por meio de um novo ADR, referenciando explicitamente este documento.

---

### Histórico
- **ADR-001:** Criado e aceito
