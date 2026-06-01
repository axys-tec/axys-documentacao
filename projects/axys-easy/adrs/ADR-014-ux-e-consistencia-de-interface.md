# ADR-014 — Política de UX e Consistência de Interface (Desktop-like)

- **Status:** Aceito
- **Data:** 2026-01-25
- **Autor:** AxysHub Core
- **Contexto:** AxysHub Core, Módulos Funcionais e MicroApps
- **Decisão Relacionada a:** ADR-003, ADR-010, ADR-011

---

## 1. Contexto

O Axys nasce da necessidade de substituir soluções genéricas que, apesar de completas, apresentam interfaces lentas, poluídas ou pouco previsíveis para uso profissional intensivo.

O público-alvo do Axys utiliza o sistema diariamente, por longos períodos, exigindo:
- rapidez de navegação;
- leitura clara das informações;
- previsibilidade de comportamento;
- baixa carga cognitiva.

Era necessário definir uma política clara de UX que orientasse todas as interfaces do ecossistema.

---

## 2. Forças e Restrições

- uso contínuo e profissional do sistema;
- diversidade de módulos e microapps;
- execução em navegador, mas com expectativa de fluidez de software desktop;
- necessidade de padronização visual e comportamental;
- limitação de recursos em ambientes locais.

---

## 3. Opções Consideradas

### 3.1 Opção A — UX orientada a websites tradicionais
Interface similar a portais web genéricos.

**Prós:**
- facilidade de desenvolvimento.

**Contras:**
- baixa eficiência operacional;
- excesso de navegação;
- leitura fragmentada.

---

### 3.2 Opção B — UX totalmente customizada por módulo
Cada módulo define sua própria experiência.

**Prós:**
- autonomia visual.

**Contras:**
- inconsistência;
- curva de aprendizado elevada;
- baixa previsibilidade.

---

### 3.3 Opção C — UX padronizada, desktop-like
Experiência unificada, inspirada em ERPs desktop.

**Prós:**
- eficiência operacional;
- consistência;
- menor curva de aprendizado.

**Contras:**
- maior rigor de design.

---

## 4. Decisão

Fica definido que o Axys adota uma **política de UX desktop-like**, caracterizada por:

- telas densas em informação, porém organizadas;
- navegação direta, com poucos níveis hierárquicos;
- botões e ações sempre visíveis;
- previsibilidade de layout e comportamento;
- padronização visual entre Core, módulos e microapps.

Nenhum módulo pode adotar UX divergente sem justificativa arquitetural.

---

## 5. Justificativa

Essa abordagem maximiza produtividade, reduz erros operacionais e alinha o Axys às expectativas de usuários profissionais, sem sacrificar a flexibilidade do ambiente web.

---

## 6. Consequências

### 6.1 Consequências Positivas
- maior produtividade do usuário;
- menor tempo de treinamento;
- identidade visual consistente.

### 6.2 Consequências Negativas / Custos
- maior esforço de padronização;
- necessidade de revisão de UI em PRs.

### 6.3 Impactos Técnicos
- definição de componentes reutilizáveis;
- layout base compartilhado;
- validação de UX como critério de revisão.

---

## 7. Escopo e Limitações

Esta decisão:
- aplica-se a todo o ecossistema Axys;
- não impede evolução visual;
- exige aderência aos padrões definidos pelo Core.

---

## 8. Diretrizes de Implementação

- ações críticas devem estar sempre visíveis;
- evitar navegação profunda;
- estados e feedbacks devem ser claros;
- comportamento consistente entre módulos.

---

## 9. Revisão e Evolução

- Esta decisão pode ser revista?  
  - ( ) Não  
  - (X) Sim, mediante revisão global de UX.

---

## 10. Registro

Esta decisão integra o histórico arquitetural oficial do Axys.

---

### Histórico
- **ADR-014:** Criado e aceito
