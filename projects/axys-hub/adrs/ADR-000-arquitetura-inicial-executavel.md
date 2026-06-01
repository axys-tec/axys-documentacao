# ADR-000 — Arquitetura Inicial Executável

- **Status:** Aceito
- **Data:** 2026-01-26
- **Autor:** AxysHub Core
- **Contexto:** Ecossistema Axys
- **Decisão Relacionada a:** Regra-Mãe / Contrato Geral

---

## 1. Contexto

O ecossistema Axys é composto por múltiplos sistemas (AxysHub, AxysHub e MicroApps), com responsabilidades distintas e evolução prevista ao longo do tempo.

Antes da implementação extensiva de módulos, torna-se necessário estabelecer uma arquitetura inicial executável que permita iniciar o desenvolvimento de forma segura, sem engessar decisões futuras nem violar a governança documental do projeto.

---

## 2. Decisão

Fica definido que:

- o desenvolvimento inicial do ecossistema Axys terá como ponto de partida uma arquitetura executável mínima, capaz de sustentar autenticação, governança, modularização e persistência básica;
- esta arquitetura não representa um estado final do sistema;
- decisões técnicas específicas poderão evoluir, desde que respeitados a Regra-Mãe e o Contrato Geral do AxysHub.

---

## 3. Escopo

Esta ADR:
- estabelece diretrizes para o **bootstrap arquitetural** do sistema;
- não define tecnologias definitivas;
- não congela a divisão entre Hub, Pro e MicroApps;
- não substitui ADRs específicas de módulos ou domínios.

---

## 4. Consequências

- permite iniciar o desenvolvimento sem risco estrutural;
- preserva liberdade de evolução arquitetural;
- cria base comum para ADRs subsequentes.

---

## 5. Hierarquia

Esta ADR é subordinada à Regra-Mãe e ao Contrato Geral, prevalecendo estes em caso de conflito.

---

## 6. Registro

Esta decisão inaugura a camada de decisões arquiteturais executáveis do Axys, servindo como referência inicial para implementação.
