# ADR-016 — Estratégia de Internacionalização (i18n) e Localização (l10n)

- **Status:** Aceito
- **Data:** 2026-01-25
- **Autor:** AxysHub Core
- **Contexto:** AxysHub Core, UX e Módulos Funcionais
- **Decisão Relacionada a:** ADR-003, ADR-014, ADR-015

---

## 1. Contexto

O Axys nasce em ambiente nacional, porém com potencial de uso por:
- empresas com operações em múltiplos países;
- usuários com preferências regionais distintas;
- requisitos legais, fiscais e culturais variados.

Era necessário definir uma estratégia que permitisse internacionalização futura **sem refatorações estruturais**, mesmo que o uso inicial seja em um único idioma.

---

## 2. Forças e Restrições

- base inicial monolíngue (pt-BR);
- necessidade de UX consistente;
- ambientes offline possíveis;
- diversidade futura de formatos (datas, moedas, números);
- evitar acoplamento de idioma à lógica de negócio.

---

## 3. Opções Consideradas

### 3.1 Opção A — Strings fixas no código
Textos embutidos diretamente na aplicação.

**Prós:**
- rapidez inicial.

**Contras:**
- inviabiliza internacionalização;
- alto custo de refatoração futura.

---

### 3.2 Opção B — Internacionalização tardia
Adicionar i18n apenas quando necessário.

**Prós:**
- menor esforço inicial.

**Contras:**
- dívida técnica acumulada;
- risco de inconsistência.

---

### 3.3 Opção C — Preparação estrutural desde o Core
Estrutura pronta para i18n, mesmo com um idioma ativo.

**Prós:**
- evolução segura;
- baixo custo futuro;
- alinhamento arquitetural.

**Contras:**
- maior rigor inicial.

---

## 4. Decisão

Fica definido que:

- o Axys será **estruturalmente preparado para i18n e l10n desde o Core**;
- strings de interface não devem ser codificadas diretamente;
- idioma padrão inicial será **pt-BR**;
- formatos regionais (data, moeda, número) devem ser abstraídos.

A existência de apenas um idioma ativo **não elimina** a obrigação de aderir à estrutura de i18n.

---

## 5. Justificativa

Essa decisão elimina retrabalho futuro, preserva consistência de UX e mantém o Axys tecnicamente preparado para expansão internacional.

---

## 6. Consequências

### 6.1 Consequências Positivas
- prontidão para novos mercados;
- separação clara entre texto e lógica;
- maior manutenibilidade.

### 6.2 Consequências Negativas / Custos
- maior disciplina no desenvolvimento;
- necessidade de revisão de strings em PRs.

### 6.3 Impactos Técnicos
- catálogos de mensagens;
- fallback de idioma;
- abstração de formatação regional.

---

## 7. Escopo e Limitações

Esta decisão:
- aplica-se a todo o ecossistema Axys;
- não obriga tradução imediata;
- proíbe strings fixas fora da camada de apresentação.

---

## 8. Diretrizes de Implementação

- toda string visível deve ser externalizada;
- idioma deve ser configurável por usuário/tenant;
- ausência de tradução deve usar fallback seguro;
- formatos regionais devem ser centralizados.

---

## 9. Revisão e Evolução

- Esta decisão pode ser revista?  
  - ( ) Não  
  - (X) Sim, conforme expansão internacional.

---

## 10. Registro

Esta decisão integra o histórico arquitetural oficial do Axys.

---

### Histórico
- **ADR-016:** Criado e aceito
