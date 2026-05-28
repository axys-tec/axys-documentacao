# ADR-009 — Política de Backup e Disaster Recovery

- **Status:** Aceito
- **Data:** 2026-01-25
- **Autor:** AxysHub Core
- **Contexto:** AxysHub Core e Infraestrutura
- **Decisão Relacionada a:** ADR-001, ADR-006, ADR-008

---

## 1. Contexto

O Axys é uma plataforma crítica para operação e gestão, armazenando dados estratégicos e Arquivos sensíveis.

Era necessário definir uma política clara de backup e recuperação que:
- minimize perda de dados;
- permita recuperação por tenant;
- seja compatível com múltiplos ambientes;
- suporte incidentes, falhas e desastres.

---

## 2. Forças e Restrições

- múltiplos bancos e tenants;
- separação entre dados e arquivos;
- necessidade de recuperação seletiva;
- custos operacionais controlados.

---

## 3. Opções Consideradas

### 3.1 Opção A — Backup único global
Snapshot completo do ambiente.

**Prós:**
- simplicidade.

**Contras:**
- recuperação lenta;
- impacto em todos os tenants.

---

### 3.2 Opção B — Backup parcial não padronizado
Backups manuais ou inconsistentes.

**Prós:**
- flexibilidade.

**Contras:**
- alto risco;
- ausência de previsibilidade.

---

### 3.3 Opção C — Backup estruturado por camada e tenant
Backups independentes e recuperáveis.

**Prós:**
- recuperação seletiva;
- menor impacto;
- governança clara.

**Contras:**
- maior disciplina operacional.

---

## 4. Decisão

Fica definido que:

- backups devem ser **automatizados e periódicos**;
- bancos de dados devem permitir **recuperação por tenant**;
- arquivos devem possuir backup independente do banco;
- procedimentos de restore devem ser documentados e testados.

---

## 5. Justificativa

Essa abordagem garante:
- continuidade operacional;
- menor impacto em falhas localizadas;
- recuperação rápida e controlada.

---

## 6. Consequências

### 6.1 Consequências Positivas
- redução de risco de perda de dados;
- maior confiança operacional;
- recuperação granular.

### 6.2 Consequências Negativas / Custos
- custo de armazenamento de backup;
- necessidade de testes periódicos.

### 6.3 Impactos Técnicos
- automação de backup;
- versionamento de snapshots;
- política de retenção.

---

## 7. Escopo e Limitações

Esta decisão:
- aplica-se a todo o ecossistema Axys;
- não permite ausência de backup;
- exige aderência aos procedimentos definidos.

---

## 8. Diretrizes de Implementação

- backups devem ser criptografados;
- retenção deve seguir política definida;
- restores devem ser testados periodicamente;
- falhas de backup devem gerar alertas.

---

## 9. Revisão e Evolução

- Esta decisão pode ser revista?  
  - ( ) Não  
  - (X) Sim, mediante mudança significativa de escala.

---

## 10. Registro

Esta decisão integra o histórico arquitetural oficial do Axys.

---

### Histórico
- **ADR-009:** Criado e aceito
