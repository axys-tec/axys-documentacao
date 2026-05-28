# ADR-004 — Operação Offline e Modo Degradado Controlado

- **Status:** Aceito
- **Data:** 2026-01-25
- **Autor:** AxysHub Core
- **Contexto:** AxysHub Core, Módulos Funcionais e MicroApps
- **Decisão Relacionada a:** ADR-001, ADR-002, ADR-003

---

## 1. Contexto

Parte das aplicações do ecossistema Axys pode operar em ambientes com conectividade limitada, intermitente ou temporariamente indisponível, incluindo servidores locais conectados à internet.

Era necessário definir uma estratégia que:
- permita continuidade operacional;
- não comprometa a integridade dos dados;
- respeite as regras de licenciamento;
- evite bloqueios abruptos ou comportamento imprevisível.

---

## 2. Forças e Restrições

- operação possível em ambientes offline;
- licenciamento centralizado com tolerância offline;
- necessidade de proteger dados e evitar corrupção;
- exigência de previsibilidade de comportamento;
- obrigação de evitar dependência total de conectividade contínua.

---

## 3. Opções Consideradas

### 3.1 Opção A — Bloqueio total sem internet
Aplicações param de funcionar na ausência de conectividade.

**Prós:**
- controle rígido.

**Contras:**
- inviável operacionalmente;
- risco elevado para usuários;
- experiência de uso inadequada.

---

### 3.2 Opção B — Operação offline irrestrita
Aplicações continuam funcionando indefinidamente sem validação.

**Prós:**
- simplicidade.

**Contras:**
- alto risco de burla;
- ausência de governança;
- quebra do modelo de licenciamento.

---

### 3.3 Opção C — Operação offline com tolerância e modo degradado
Funcionamento offline limitado, com restrições progressivas.

**Prós:**
- equilíbrio entre segurança e usabilidade;
- proteção de dados;
- previsibilidade de comportamento.

**Contras:**
- maior complexidade de implementação.

---

## 4. Decisão

Fica definido que as aplicações Axys:

- podem operar offline por período limitado, conforme licença;
- devem implementar **modo degradado controlado** ao exceder a tolerância offline;
- **não podem** corromper, apagar ou impedir acesso a dados existentes;
- devem exigir revalidação para retomada plena de funcionalidades.

---

## 5. Justificativa

O modo degradado controlado preserva:
- continuidade mínima de operação;
- integridade dos dados;
- respeito às regras de licenciamento.

Evita-se tanto o bloqueio abrupto quanto a operação irrestrita sem controle.

---

## 6. Consequências

### 6.1 Consequências Positivas
- previsibilidade operacional;
- proteção contra burla;
- melhor experiência do usuário.

### 6.2 Consequências Negativas / Custos
- necessidade de lógica adicional nas aplicações;
- gestão de estados de operação.

### 6.3 Impactos Técnicos
- registro de última validação online;
- detecção de inconsistências temporais;
- sincronização de eventos ao reconectar.

---

## 7. Escopo e Limitações

Esta decisão:
- aplica-se a todas as aplicações Axys;
- não permite exceções por módulo;
- depende das regras definidas no licenciamento central.

---

## 8. Diretrizes de Implementação

- modo degradado deve ser explícito ao usuário;
- dados existentes devem permanecer acessíveis;
- novas operações críticas podem ser bloqueadas;
- revalidação online restaura operação plena.

---

## 9. Revisão e Evolução

- Esta decisão pode ser revista?  
  - ( ) Não  
  - (X) Sim, se houver mudança no modelo de licenciamento.

---

## 10. Registro

Esta decisão integra o histórico arquitetural oficial do Axys.

---

### Histórico
- **ADR-004:** Criado e aceito
