# ADR-003 — Separação entre Core, Módulos Funcionais e MicroApps

- **Status:** Aceito
- **Data:** 2026-01-25
- **Autor:** AxysHub Core
- **Contexto:** Arquitetura Geral do Axys
- **Decisão Relacionada a:** ADR-001, ADR-002

---

## 1. Contexto

O crescimento do Axys exige uma distinção clara entre:
- governança;
- regras estruturais;
- funcionalidades operacionais;
- aplicações independentes.

Sem essa separação, há risco de:
- acoplamento excessivo;
- duplicação de regras;
- dificuldade de evolução;
- violações de segurança e licenciamento.

---

## 2. Forças e Restrições

- necessidade de governança central;
- coexistência de aplicações com finalidades distintas;
- necessidade de reutilização controlada;
- preservação de autonomia funcional;
- escalabilidade do ecossistema.

---

## 3. Opções Consideradas

### 3.1 Opção A — Monólito único
Tudo concentrado em uma única aplicação.

**Prós:**
- simplicidade inicial.

**Contras:**
- acoplamento elevado;
- baixa escalabilidade;
- alto risco de regressão.

---

### 3.2 Opção B — Microserviços sem Core definido
Serviços independentes sem plano de controle central.

**Prós:**
- autonomia máxima.

**Contras:**
- ausência de governança;
- duplicação de regras;
- inconsistência entre apps.

---

### 3.3 Opção C — Core central + módulos + microapps
Separação explícita de responsabilidades.

**Prós:**
- governança clara;
- isolamento de responsabilidades;
- evolução independente;
- controle de licenças e identidade centralizado.

**Contras:**
- necessidade de disciplina arquitetural.

---

## 4. Decisão

Fica definido que o ecossistema Axys será estruturado em três camadas:

- **AxysHub Core:** governança, contratos, identidade, tenancy, licenciamento;
- **Módulos Funcionais:** funcionalidades operacionais dependentes do Core;
- **MicroApps:** aplicações independentes, integráveis ao Core conforme contrato.

Nenhuma dessas camadas pode assumir responsabilidades da outra.

---

## 5. Justificativa

Essa separação:
- reduz acoplamento;
- facilita manutenção;
- permite escalar equipes e produtos;
- preserva autoridade arquitetural do Core.

---

## 6. Consequências

### 6.1 Consequências Positivas
- clareza de papéis;
- evolução independente;
- redução de riscos sistêmicos.

### 6.2 Consequências Negativas / Custos
- necessidade de contratos bem definidos;
- maior rigor em revisões de PR.

### 6.3 Impactos Técnicos
- definição clara de APIs e tokens;
- validação central de identidade e licença.

---

## 7. Escopo e Limitações

Esta decisão:
- aplica-se a todo o ecossistema Axys;
- não permite exceções por conveniência;
- exige aderência estrita ao Core.

---

## 8. Diretrizes de Implementação

- módulos não implementam governança;
- microapps só acessam o Core via contratos explícitos;
- regras transversais vivem exclusivamente no Core.

---

## 9. Revisão e Evolução

- Esta decisão pode ser revista?  
  - ( ) Não  
  - (X) Sim, apenas mediante novo ADR.

---

## 10. Registro

Esta decisão integra o histórico arquitetural oficial do Axys.

---

### Histórico
- **ADR-003:** Criado e aceito
