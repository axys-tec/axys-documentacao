# ADR-005 — Política de Versionamento e Compatibilidade

- **Status:** Aceito
- **Data:** 2026-01-25
- **Autor:** AxysHub Core
- **Contexto:** AxysHub Core e todo o ecossistema Axys
- **Decisão Relacionada a:** ADR-003, ADR-004

---

## 1. Contexto

O Axys é um ecossistema em evolução contínua, composto por Core, módulos funcionais e microapps, com ciclos de atualização distintos.

Era necessário estabelecer uma política clara de versionamento que:
- preserve compatibilidade sempre que possível;
- permita evolução controlada;
- minimize impactos em produção;
- forneça previsibilidade a longo prazo.

---

## 2. Forças e Restrições

- múltiplas aplicações dependentes do Core;
- necessidade de estabilidade operacional;
- evolução incremental frequente;
- mudanças estruturais ocasionais.

---

## 3. Opções Consideradas

### 3.1 Opção A — Versionamento ad hoc
Versões sem padrão formal.

**Prós:**
- flexibilidade imediata.

**Contras:**
- imprevisibilidade;
- alto risco de quebra.

---

### 3.2 Opção B — Versionamento rígido sem compatibilidade
Quebras frequentes e não controladas.

**Prós:**
- simplicidade conceitual.

**Contras:**
- inviável operacionalmente;
- custo elevado de manutenção.

---

### 3.3 Opção C — Versionamento semântico com compatibilidade controlada
Uso de versão MAJOR.MINOR.PATCH.

**Prós:**
- previsibilidade;
- governança clara;
- alinhamento com boas práticas.

**Contras:**
- disciplina necessária.

---

## 4. Decisão

Fica definido que o ecossistema Axys adota **versionamento semântico**:

- **MAJOR:** mudanças incompatíveis (breaking changes);
- **MINOR:** novas funcionalidades compatíveis;
- **PATCH:** correções sem impacto funcional.

Breaking changes só podem ocorrer em versões MAJOR.

---

## 5. Justificativa

O versionamento semântico permite:
- evolução contínua;
- planejamento de atualizações;
- comunicação clara de impacto.

Preserva-se a confiança no ecossistema.

---

## 6. Consequências

### 6.1 Consequências Positivas
- estabilidade operacional;
- previsibilidade de upgrades;
- redução de regressões.

### 6.2 Consequências Negativas / Custos
- necessidade de disciplina de versionamento;
- manutenção de compatibilidade temporária.

### 6.3 Impactos Técnicos
- versionamento explícito de APIs;
- controle de compatibilidade entre Core e clientes.

---

## 7. Escopo e Limitações

Esta decisão:
- aplica-se a todo o ecossistema Axys;
- exige alinhamento entre Core, módulos e microapps;
- não permite exceções por conveniência.

---

## 8. Diretrizes de Implementação

- versões devem ser explícitas e documentadas;
- contratos entre Core e apps devem indicar versão;
- depreciações devem ser comunicadas previamente.

---

## 9. Revisão e Evolução

- Esta decisão pode ser revista?  
  - ( ) Não  
  - (X) Sim, mediante novo ADR.

---

## 10. Registro

Esta decisão integra o histórico arquitetural oficial do Axys.

---

### Histórico
- **ADR-005:** Criado e aceito
