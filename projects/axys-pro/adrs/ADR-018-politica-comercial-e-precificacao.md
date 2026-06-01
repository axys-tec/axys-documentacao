# ADR-018 — Política Comercial e Estratégia de Precificação

- **Status:** Aceito
- **Data:** 2026-01-25
- **Autor:** AxysHub Core
- **Contexto:** AxysHub Core, Comercial e Licenciamento
- **Decisão Relacionada a:** ADR-004, ADR-007, ADR-017

---

## 1. Contexto

O ecossistema Axys contempla aplicações de naturezas distintas:
- Core e módulos estruturantes;
- MicroApps de apoio operacional;
- Soluções de uso contínuo e soluções orientadas a consumo.

Era necessário definir uma política comercial que:
- seja sustentável financeiramente;
- reflita valor entregue;
- permita múltiplos modelos de cobrança;
- não comprometa governança técnica.

---

## 2. Forças e Restrições

- diversidade de perfis de clientes;
- diferentes níveis de criticidade;
- operação cloud e on-premises;
- necessidade de previsibilidade financeira;
- controle centralizado de licenças.

---

## 3. Opções Consideradas

### 3.1 Opção A — Preço único para todo o ecossistema
Modelo flat para todos os módulos.

**Prós:**
- simplicidade comercial.

**Contras:**
- desbalanceamento de valor;
- inviável para microapps.

---

### 3.2 Opção B — Precificação totalmente customizada
Preço definido caso a caso.

**Prós:**
- flexibilidade.

**Contras:**
- difícil escala;
- alto custo operacional.

---

### 3.3 Opção C — Precificação por categoria de aplicação
Modelos distintos conforme tipo de app.

**Prós:**
- alinhamento valor × uso;
- escalabilidade comercial;
- clareza contratual.

**Contras:**
- maior complexidade inicial.

---

## 4. Decisão

Fica definido que:

- **aplicações grandes** adotam licenciamento **mensal recorrente**;
- **microapps** podem operar em modelo **mensal** ou **por uso**;
- o Core Axys centraliza controle comercial e de licenças;
- preços não influenciam arquitetura técnica.

---

## 5. Justificativa

Essa política equilibra previsibilidade financeira, flexibilidade comercial e governança técnica, evitando distorções entre valor entregue e preço cobrado.

---

## 6. Consequências

### 6.1 Consequências Positivas
- escalabilidade comercial;
- clareza para clientes;
- sustentabilidade do produto.

### 6.2 Consequências Negativas / Custos
- necessidade de controle financeiro robusto;
- integração com billing.

---

## 7. Diretrizes de Implementação

- preços associados a licenças, não a usuários individuais;
- controle de uso auditável;
- inadimplência deve acionar políticas técnicas (ver ADR-007).

---

## 8. Registro

Esta decisão integra o histórico arquitetural oficial do Axys.

---

### Histórico
- **ADR-018:** Criado e aceito
