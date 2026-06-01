# ADR-008 — Estratégia de Armazenamento de Arquivos e Anexos

- **Status:** Aceito
- **Data:** 2026-01-25
- **Autor:** AxysHub Core
- **Contexto:** AxysHub Core, Módulos Funcionais e MicroApps
- **Decisão Relacionada a:** ADR-001, ADR-003, ADR-006, ADR-007

---

## 1. Contexto

O ecossistema Axys lida intensivamente com arquivos e anexos, incluindo:
- Arquivos técnicos;
- contratos;
- imagens;
- relatórios;
- arquivos sensíveis e confidenciais.

Esses arquivos podem representar grande volume de dados, alto valor estratégico
e risco significativo em caso de exposição indevida.

Era necessário definir uma estratégia de armazenamento que:
- evitasse acoplamento entre banco de dados e arquivos;
- suportasse grandes volumes;
- fosse compatível com operação offline;
- garantisse segurança, rastreabilidade e governança;
- fosse aplicável tanto a ambientes cloud quanto on-premises.

---

## 2. Forças e Restrições

- necessidade de armazenar arquivos de grande porte;
- execução do Axys em ambientes cloud e servidores locais;
- existência de múltiplos contextos de execução (single-tenant por instância e microapps compartilhadas);
- exigência de controle de acesso rigoroso;
- necessidade de auditoria e rastreabilidade;
- obrigação de evitar dependência de tecnologia específica de storage.

---

## 3. Opções Consideradas

### 3.1 Opção A — Armazenar arquivos no banco de dados
Uso de BLOBs ou estruturas equivalentes.

**Prós:**
- centralização dos dados;
- simplicidade conceitual inicial.

**Contras:**
- degradação significativa de desempenho;
- dificuldade de escalabilidade;
- backups pesados e lentos;
- acoplamento forte entre dados e arquivos.

---

### 3.2 Opção B — Armazenamento em filesystem sem governança
Arquivos armazenados diretamente em diretórios locais, sem mediação.

**Prós:**
- simplicidade operacional;
- baixo custo inicial.

**Contras:**
- ausência de controle de acesso estruturado;
- risco elevado de vazamento ou exclusão indevida;
- difícil auditoria;
- dependência excessiva do filesystem.

---

### 3.3 Opção C — Armazenamento externo com metadados no banco
Arquivos armazenados fora do banco, com controle por metadados e mediação de acesso.

**Prós:**
- escalabilidade;
- melhor desempenho;
- separação clara de responsabilidades;
- compatibilidade com múltiplos backends (filesystem, object storage, etc.);
- governança e auditoria viáveis.

**Contras:**
- necessidade de camada adicional de controle e autorização.

---

## 4. Decisão

Fica definido que:

- **arquivos e anexos não serão armazenados diretamente no banco de dados**;
- o banco de dados armazenará apenas **metadados, referências e informações de controle**;
- o armazenamento físico dos arquivos será externo ao banco;
- o acesso a qualquer arquivo será **sempre mediado** pelo AxysHub Core ou por contratos explícitos;
- **arquivos devem permanecer criptografados em repouso**, independentemente do backend de armazenamento;
- a classificação de um arquivo como sensível será definida por **metadados e políticas de acesso**, e não pela sua localização física.

Esta decisão aplica-se tanto ao AxysHub executado como instância isolada (single-tenant)
quanto às microapps executadas em ambientes compartilhados.

---

## 5. Justificativa

A separação entre dados estruturados e arquivos:
- melhora o desempenho geral do sistema;
- reduz acoplamento entre camadas;
- facilita estratégias de backup e recuperação;
- permite controle de acesso mais rigoroso;
- reduz riscos sistêmicos associados a vazamento ou corrupção de dados.

A exigência de criptografia em repouso protege o conteúdo mesmo em cenários
de acesso indevido ao storage físico.

---

## 6. Consequências

### 6.1 Consequências Positivas
- escalabilidade de armazenamento;
- independência de tecnologia de banco de dados;
- maior controle de acesso e segurança;
- melhor aderência a requisitos de compliance.

### 6.2 Consequências Negativas / Custos
- necessidade de gerenciar storage separado;
- maior complexidade arquitetural;
- exigência de gestão de chaves criptográficas.

### 6.3 Impactos Técnicos
- criação de camada de abstração de storage;
- uso obrigatório de identificadores únicos para arquivos;
- associação de regras de acesso via metadados;
- integração com mecanismos de auditoria.

---

## 7. Escopo e Limitações

Esta decisão:
- aplica-se a todos os módulos e microapps do Axys;
- não permite armazenamento direto de arquivos no banco;
- não permite acesso direto ao storage físico por usuários ou módulos;
- não define tecnologia específica de criptografia ou storage.

---

## 8. Diretrizes de Implementação

- arquivos devem possuir identificador único e imutável;
- metadados devem incluir informações de controle, tipo e integridade;
- operações de criação, leitura e exclusão devem ser auditáveis;
- falhas de acesso ao storage não devem comprometer a integridade do banco.

---

## 9. Revisão e Evolução

- Esta decisão pode ser revista?  
  - ( ) Não  
  - (X) Sim, mediante mudança estrutural relevante de infraestrutura ou requisitos legais.

---

## 10. Registro

Esta decisão integra o histórico arquitetural oficial do Axys.

---

### Histórico
- **ADR-008:** Criado e aceito
