# ADR-017 — Política de Suporte, SLA e Níveis de Serviço

- **Status:** Aceito
- **Data:** 2026-01-25
- **Autor:** AxysHub Core
- **Contexto:** AxysHub Core, Operação e Relacionamento com Clientes
- **Decisão Relacionada a:** ADR-004, ADR-010, ADR-011

---

## 1. Contexto

O Axys será utilizado em contextos profissionais críticos, incluindo:
- gestão administrativa;
- controle financeiro;
- Arquivos técnicos e jurídicos.

Era necessário definir uma política clara de suporte e SLA que:
- estabeleça expectativas realistas;
- diferencie tipos de licenciamento;
- seja compatível com ambientes cloud e on-premises;
- evite compromissos operacionais inviáveis.

---

## 2. Forças e Restrições

- múltiplos modelos de licenciamento;
- operação local possível;
- dependência de infraestrutura do cliente em on-premises;
- necessidade de previsibilidade contratual.

---

## 3. Opções Consideradas

### 3.1 Opção A — Suporte informal e reativo
Atendimento sem níveis definidos.

**Prós:**
- flexibilidade.

**Contras:**
- expectativas desalinhadas;
- risco reputacional.

---

### 3.2 Opção B — SLA único para todos
Mesmos prazos e níveis para todos os clientes.

**Prós:**
- simplicidade.

**Contras:**
- inviável economicamente;
- não reflete criticidade real.

---

### 3.3 Opção C — SLA por nível de licença
Níveis de serviço associados ao tipo de licença.

**Prós:**
- previsibilidade;
- sustentabilidade operacional;
- clareza contratual.

**Contras:**
- necessidade de gestão de níveis.

---

## 4. Decisão

Fica definido que:

- o Axys adota **política de SLA por nível de licença**;
- SLAs diferenciam prazos de resposta e atuação;
- ambientes on-premises têm limitações explícitas;
- suporte não implica responsabilidade sobre infraestrutura do cliente.

---

## 5. Justificativa

Essa política protege o produto, o fornecedor e o cliente, evitando promessas inexequíveis e garantindo transparência operacional.

---

## 6. Consequências

### 6.1 Consequências Positivas
- alinhamento de expectativas;
- escalabilidade do suporte;
- redução de conflitos contratuais.

### 6.2 Consequências Negativas / Custos
- necessidade de categorização de tickets;
- gestão ativa de contratos.

### 6.3 Impactos Técnicos
- classificação de incidentes;
- registro de tempos de resposta;
- integração com sistemas de suporte.

---

## 7. Escopo e Limitações

Esta decisão:
- aplica-se a todos os clientes Axys;
- não garante disponibilidade absoluta;
- não cobre falhas de infraestrutura externa.

---

## 8. Diretrizes de Implementação

- SLAs devem ser documentados por licença;
- incidentes devem ser classificados;
- métricas de atendimento devem ser auditáveis;
- reincidências devem gerar revisão técnica.

---

## 9. Revisão e Evolução

- Esta decisão pode ser revista?  
  - ( ) Não  
  - (X) Sim, conforme maturidade do produto.

---

## 10. Registro

Esta decisão integra o histórico arquitetural oficial do Axys.

---

### Histórico
- **ADR-017:** Criado e aceito
