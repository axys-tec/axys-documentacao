# ADR-013 — Política de Extensibilidade e Plugins

- **Status:** Aceito
- **Data:** 2026-01-25
- **Autor:** AxysHub Core
- **Contexto:** AxysHub Core, Módulos Funcionais e MicroApps
- **Decisão Relacionada a:** ADR-003, ADR-005, ADR-011

---

## 1. Contexto

O Axys deve permitir extensões de funcionalidade sem comprometer estabilidade, segurança e governança do Core.

Era necessário definir uma política de extensibilidade que:
- permita evolução modular;
- evite modificações diretas no Core;
- preserve contratos e versionamento;
- reduza risco de código não confiável.

---

## 2. Forças e Restrições

- necessidade de customizações específicas;
- preservação da autoridade do Core;
- múltiplos módulos e microapps;
- controle de compatibilidade e segurança.

---

## 3. Opções Consideradas

### 3.1 Opção A — Customização direta no Core
Alterações pontuais no Core para cada necessidade.

**Prós:**
- rapidez inicial.

**Contras:**
- quebra de governança;
- risco sistêmico;
- manutenção inviável.

---

### 3.2 Opção B — Extensões livres sem controle
Plugins executando sem contrato.

**Prós:**
- flexibilidade máxima.

**Contras:**
- alto risco de segurança;
- instabilidade;
- ausência de controle.

---

### 3.3 Opção C — Plugins controlados por contrato
Extensões com contratos, versionamento e permissões.

**Prós:**
- extensibilidade segura;
- governança mantida;
- evolução controlada.

**Contras:**
- maior rigor de integração.

---

## 4. Decisão

Fica definido que:

- extensões ocorrerão por **mecanismo de plugins controlados**;
- plugins **não podem** alterar o Core diretamente;
- contratos de plugin devem ser explícitos, versionados e auditáveis;
- permissões de plugin devem ser restritivas por padrão.

---

## 5. Justificativa

A política de plugins controlados permite crescimento do ecossistema sem comprometer segurança, estabilidade ou governança arquitetural.

---

## 6. Consequências

### 6.1 Consequências Positivas
- extensibilidade segura;
- redução de fork do Core;
- manutenção previsível.

### 6.2 Consequências Negativas / Custos
- necessidade de framework de plugins;
- curva de aprendizado.

### 6.3 Impactos Técnicos
- definição de lifecycle de plugins;
- validação de compatibilidade;
- sandboxing quando aplicável.

---

## 7. Escopo e Limitações

Esta decisão:
- aplica-se a todo o ecossistema Axys;
- não permite plugins com acesso irrestrito;
- exige revisão e aprovação de contratos.

---

## 8. Diretrizes de Implementação

- plugins devem declarar versão e compatibilidade;
- falhas de plugin não podem derrubar o Core;
- plugins devem ser desativáveis;
- eventos de plugin devem ser auditáveis.

---

## 9. Revisão e Evolução

- Esta decisão pode ser revista?  
  - ( ) Não  
  - (X) Sim, mediante evolução do modelo de extensões.

---

## 10. Registro

Esta decisão integra o histórico arquitetural oficial do Axys.

---

### Histórico
- **ADR-013:** Criado e aceito
