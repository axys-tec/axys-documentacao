# ADR-011 — Política de Atualização e Deploy (Cloud e On-Premises)

- **Status:** Aceito
- **Data:** 2026-01-25
- **Autor:** AxysHub Core
- **Contexto:** AxysHub Core, Infraestrutura e Operação
- **Decisão Relacionada a:** ADR-003, ADR-004, ADR-005, ADR-009

---

## 1. Contexto

O Axys pode ser executado tanto em ambientes cloud quanto em servidores locais (on-premises), com diferentes níveis de conectividade, controle e autonomia do cliente.

Era necessário definir uma política de atualização e deploy que:
- preserve estabilidade operacional;
- respeite ambientes com restrições;
- permita evolução contínua do sistema;
- evite interrupções abruptas.

---

## 2. Forças e Restrições

- múltiplos ambientes de execução;
- tenants com níveis distintos de criticidade;
- operação offline possível;
- necessidade de compatibilidade entre versões.

---

## 3. Opções Consideradas

### 3.1 Opção A — Atualização forçada e centralizada
Todos os ambientes atualizados automaticamente.

**Prós:**
- uniformidade.

**Contras:**
- inviável para on-premises;
- alto risco operacional.

---

### 3.2 Opção B — Atualização totalmente manual
Atualizações sob total controle local.

**Prós:**
- autonomia máxima.

**Contras:**
- fragmentação de versões;
- risco de obsolescência.

---

### 3.3 Opção C — Atualização controlada por política
Atualizações governadas pelo Core, com controle local.

**Prós:**
- equilíbrio entre controle e flexibilidade;
- compatibilidade garantida;
- menor risco de ruptura.

**Contras:**
- maior disciplina de versionamento.

---

## 4. Decisão

Fica definido que:

- o Axys adota **política de atualização controlada por versão**;
- ambientes cloud podem receber atualizações automáticas;
- ambientes on-premises recebem atualizações assistidas ou manuais;
- compatibilidade entre versões é obrigatória dentro do mesmo MAJOR.

---

## 5. Justificativa

Essa política permite:
- evolução contínua;
- respeito às limitações de cada ambiente;
- previsibilidade operacional;
- redução de riscos em produção.

---

## 6. Consequências

### 6.1 Consequências Positivas
- estabilidade operacional;
- controle de compatibilidade;
- menor risco de falhas críticas.

### 6.2 Consequências Negativas / Custos
- necessidade de controle de versões;
- suporte a múltiplas versões ativas.

### 6.3 Impactos Técnicos
- validação de versão no Core;
- contratos de compatibilidade;
- processos de rollback.

---

## 7. Escopo e Limitações

Esta decisão:
- aplica-se a todo o ecossistema Axys;
- não permite atualização forçada em on-premises;
- exige respeito às políticas de versão.

---

## 8. Diretrizes de Implementação

- versões devem ser declaradas explicitamente;
- atualizações devem ser reversíveis;
- mudanças incompatíveis exigem versão MAJOR;
- Core pode recusar integração com versões incompatíveis.

---

## 9. Revisão e Evolução

- Esta decisão pode ser revista?  
  - ( ) Não  
  - (X) Sim, mediante mudança significativa de operação.

---

## 10. Registro

Esta decisão integra o histórico arquitetural oficial do Axys.

---

### Histórico
- **ADR-011:** Criado e aceito
