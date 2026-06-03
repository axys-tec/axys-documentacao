# ADR-002 — Arquitetura de Licenciamento Centralizado

- **Status:** Aceito
- **Data:** 2026-01-25
- **Autor:** AxysHub Core
- **Contexto:** AxysHub Core e todas as aplicações Axys
- **Decisão Relacionada a:** ADR-001

---

## 1. Contexto

O ecossistema Axys contempla aplicações executadas tanto em ambiente cloud quanto em servidores locais dos clientes, podendo operar com conectividade intermitente.

Era necessário definir um modelo de licenciamento que:
- não dependesse exclusivamente de conexão contínua;
- fosse resistente a tentativas de burla;
- não corrompesse dados em cenários de bloqueio;
- fosse aplicável a múltiplas modalidades de uso (mensal, por uso, híbrido);
- permanecesse sob controle central da plataforma.

---

## 2. Forças e Restrições

- necessidade de controle financeiro centralizado;
- operação possível em ambientes offline;
- existência de um Core Axys como plano de controle;
- obrigação de evitar lógica de licenciamento distribuída em módulos;
- exigência de proteção contra cópia, reutilização ou adulteração de licença.

---

## 3. Opções Consideradas

### 3.1 Opção A — Licenciamento local por flag ou tabela
Controle de licença armazenado localmente na aplicação.

**Prós:**
- simplicidade de implementação.

**Contras:**
- altamente vulnerável a burla;
- ausência de governança central;
- dependência total do ambiente local.

---

### 3.2 Opção B — Validação online obrigatória contínua
Aplicação só funciona com conexão ativa ao servidor central.

**Prós:**
- controle central rígido.

**Contras:**
- inviável para ambientes com internet instável;
- risco operacional;
- experiência de uso degradada.

---

### 3.3 Opção C — Licenciamento central com token assinado e tolerância offline
Licenças emitidas centralmente e validadas localmente por assinatura criptográfica.

**Prós:**
- controle centralizado;
- funcionamento offline controlado;
- resistência a adulteração;
- independência de módulos.

**Contras:**
- maior complexidade inicial;
- necessidade de gestão de chaves.

---

## 4. Decisão

Fica definido que o licenciamento do ecossistema Axys será:

- **centralizado no AxysHub Core**;
- baseado em **licenças assinadas criptograficamente**;
- consumido pelas aplicações cliente como artefato válido;
- independente de validação online contínua, respeitando tolerância offline controlada.

Nenhuma aplicação, módulo ou microapp pode implementar lógica própria de licenciamento.

---

## 5. Justificativa

Essa abordagem equilibra:
- segurança;
- controle financeiro;
- experiência do usuário;
- viabilidade técnica em ambientes reais.

A centralização no Core preserva governança e permite evolução futura sem refatoração dos clientes.

---

## 6. Consequências

### 6.1 Consequências Positivas
- bloqueio controlado sem perda de dados;
- antifraude por camadas;
- padronização do modelo de licença;
- independência entre financeiro e operação.

### 6.2 Consequências Negativas / Custos
- necessidade de infraestrutura de licenciamento;
- gestão segura de chaves criptográficas.

### 6.3 Impactos Técnicos
- inclusão de camada de validação local nas apps;
- necessidade de sincronização periódica.

---

## 7. Escopo e Limitações

Esta decisão:
- aplica-se a todas as aplicações Axys;
- não permite exceções locais;
- não autoriza licenciamento distribuído.

---

## 8. Diretrizes de Implementação

- licenças devem ser artefatos assinados;
- a app deve validar assinatura e prazo;
- o Core é a única autoridade emissora;
- falhas de licença não podem corromper dados.

---

## 9. Revisão e Evolução

- Esta decisão pode ser revista?  
  - ( ) Não  
  - (X) Sim, mediante mudança estrutural do modelo de negócio.

---

## 10. Registro

Esta decisão integra o histórico arquitetural oficial do Axys.

---

### Histórico
- **ADR-002:** Criado e aceito
