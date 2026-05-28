# ADR-010 — Estratégia de Observabilidade, Métricas e Alertas

- **Status:** Aceito
- **Data:** 2026-01-25
- **Autor:** AxysHub Core
- **Contexto:** AxysHub Core, Infraestrutura e Operação
- **Decisão Relacionada a:** ADR-004, ADR-007, ADR-009

---

## 1. Contexto

O ecossistema Axys opera de forma distribuída, podendo estar hospedado em cloud, VPS ou servidores locais, com múltiplos tenants e aplicações em execução simultânea.

Era necessário definir uma estratégia de observabilidade que:
- permita monitorar saúde e desempenho do sistema;
- antecipe falhas e degradações;
- funcione em ambientes online e parcialmente offline;
- não dependa exclusivamente de inspeção manual.

---

## 2. Forças e Restrições

- múltiplas aplicações e ambientes;
- operação offline possível;
- necessidade de visibilidade centralizada;
- limitação de recursos em servidores locais;
- obrigação de evitar impacto excessivo de coleta.

---

## 3. Opções Consideradas

### 3.1 Opção A — Logs apenas reativos
Monitoramento apenas após falhas.

**Prós:**
- simplicidade.

**Contras:**
- baixa previsibilidade;
- resposta tardia a incidentes.

---

### 3.2 Opção B — Observabilidade completa em tempo real
Coleta contínua de métricas detalhadas.

**Prós:**
- alta visibilidade.

**Contras:**
- custo elevado;
- inviável em ambientes locais/offline.

---

### 3.3 Opção C — Observabilidade gradual e orientada a sinais
Coleta seletiva de métricas e eventos críticos.

**Prós:**
- equilíbrio entre custo e visibilidade;
- compatível com múltiplos ambientes;
- foco em indicadores relevantes.

**Contras:**
- menor granularidade em alguns cenários.

---

## 4. Decisão

Fica definido que o Axys adota uma estratégia de **observabilidade orientada a sinais**, baseada em:

- métricas essenciais de saúde e desempenho;
- eventos críticos auditáveis;
- alertas acionáveis;
- consolidação central quando possível.

Não é exigida coleta contínua e exaustiva de métricas em todos os ambientes.

---

## 5. Justificativa

Essa abordagem oferece:
- previsibilidade operacional;
- baixo impacto em ambientes restritos;
- visibilidade suficiente para tomada de decisão;
- compatibilidade com operação offline.

---

## 6. Consequências

### 6.1 Consequências Positivas
- redução de incidentes graves;
- detecção antecipada de falhas;
- melhor governança operacional.

### 6.2 Consequências Negativas / Custos
- necessidade de definir métricas relevantes;
- menor detalhamento em tempo real.

### 6.3 Impactos Técnicos
- definição de health checks;
- métricas padronizadas;
- fila de eventos para sincronização.

---

## 7. Escopo e Limitações

Esta decisão:
- aplica-se ao Core, módulos e microapps;
- não exige ferramentas específicas;
- não obriga observabilidade em tempo real contínuo.

---

## 8. Diretrizes de Implementação

- métricas devem ser padronizadas;
- alertas devem ser acionáveis;
- falhas de coleta não podem interromper operação;
- sincronização ocorre quando conectividade permitir.

---

## 9. Revisão e Evolução

- Esta decisão pode ser revista?  
  - ( ) Não  
  - (X) Sim, conforme crescimento de escala.

---

## 10. Registro

Esta decisão integra o histórico arquitetural oficial do Axys.

---

### Histórico
- **ADR-010:** Criado e aceito
