# AxysPro Core

## 1. Identificação

- **Nome:** AxysPro Core
- **Tipo:** Módulo AxysPro (Core)
- **Stack:** Django
- **Status:** Ativo
- **Versão:** v1.0
- **Integração com AxysPro:** Sim (núcleo do ecossistema)

---

## 2. Objetivo do Módulo

O AxysPro Core é a **camada central de governança do ecossistema Axys**, responsável por definir regras estruturais, arquiteturais e contratuais que regem todos os módulos, APIs e MicroApps integrados.

Não é responsabilidade do AxysPro Core implementar regras de negócio específicas ou fluxos operacionais de módulos individuais.

---

## 3. Escopo Funcional

### 3.1 O que este módulo faz
- Define os princípios arquiteturais do ecossistema
- Estabelece contratos de integração entre módulos e APIs
- Centraliza identidade, autenticação e permissões
- Define regras de auditoria, logging e segurança
- Padroniza organização de código, dados e versionamento

### 3.2 O que este módulo não faz
- Não executa regras de negócio específicas
- Não implementa cálculos operacionais
- Não contém lógica funcional de módulos (ex: SysCost, Easy)

---

## 4. Enquadramento no Ecossistema Axys

Este módulo se enquadra como:

- (X) Módulo Core do AxysPro
- ( ) Módulo Funcional Integrado
- ( ) MicroApp Independente
- ( ) MicroApp Integrável

### 4.1 Dependências
- Outros módulos/APIs: N/A

---

## 5. Arquitetura Geral

### 5.1 Organização Interna
- Camada de identidade e autenticação
- Camada de permissões e governança
- Camada de contratos e integrações
- Camada de auditoria e logging
- Camada de documentação normativa

### 5.2 Armazenamento de Arquivos e Anexos

No AxysPro, arquivos e anexos não fazem parte do armazenamento primário
do banco de dados relacional.

Os arquivos são armazenados fora do banco de dados, em diretórios isolados
no filesystem ou em storage equivalente, conforme a infraestrutura disponível
(cloud ou on-premises).

Esses arquivos:
- são segregados fisicamente do banco de dados;
- não são acessíveis diretamente por usuários ou módulos;
- permanecem criptografados em repouso;
- têm seu acesso sempre mediado pelo AxysPro Core ou por contratos explícitos.

A classificação de um arquivo como sensível não depende de sua localização
física, mas de metadados de segurança e políticas de acesso definidas pelo sistema.

Esta abordagem está alinhada à decisão arquitetural formalizada na ADR-008.


---

## 6. Modelo de Dados (Visão Geral)

Entidades conceituais centrais:
- Usuários
- Papéis (roles)
- Permissões
- Tenants (empresas / unidades)
- Registros de auditoria
- Contratos de integração

---

## 7. Identidade, Permissões e Acesso

### 7.1 Modelo de Acesso
- (X) Controle próprio (AxysPro)
- ( ) Herdado
- ( ) Híbrido

### 7.2 Papéis
- Administrador Global
- Administrador de Tenant
- Usuário Operacional
- Usuário Leitor

---

## 8. Multiusuário e Multi-Tenant

- Tipo de tenant: Empresa / Unidade
- Estratégia: tenant por coluna
- Isolamento lógico obrigatório entre tenants

---

## 9. Integrações e Contratos

### 9.1 Integração com Módulos e APIs
- Autenticação centralizada
- Contratos explícitos via token / API
- Compartilhamento controlado de identidade, tenant e roles

---

## 10. Regras de Auditoria e Log

- Registro obrigatório de ações sensíveis
- Trilhas de auditoria imutáveis
- Logs estruturados para rastreabilidade

---

## 11. Versionamento e Evolução

- Versionamento semântico
- Compatibilidade retroativa sempre que possível
- Breaking changes apenas em versões maiores

---

## 12. Segurança

- Criptografia de dados sensíveis
- Controle rigoroso de acesso
- Segregação de responsabilidades

---

## 13. Limitações Conhecidas

- Não executa lógica funcional de módulos
- Atua exclusivamente como camada estrutural

---

## 14. Roadmap

- Evolução contínua dos contratos
- Ampliação de governança e auditoria

---

## 15. Referências

- Documentação Oficial AxysPro

-----------------------------------
-----------------------------------
-----------------------------------
-----------------------------------
-----------------------------------
-----------------------------------
-----------------------------------

## TEXTO ANTIGO DESATUALIZADO QUE PRECISA SER COMPATIBILIZADO COM O TEMPLATE ATUAL OU SUGERIR OUTRO LUGAR

***precisa ser verificado também as tabelas e funcionalidades - de antemão afirmo: precisa revisar***

## 7.1 Camada Fundamental AxysPro

### Generalidades

A **Camada Fundamental do AxysPro** representa o conjunto de **entidades, serviços e estruturas transversais**, utilizadas por **todos os módulos atuais e futuros** do sistema.

Essa camada **não é tratada como um módulo funcional**, pois não corresponde a uma funcionalidade de negócio específica.  
Ela constitui a **infraestrutura lógica mínima** necessária para que o AxysPro opere de forma:

- consistente  
- auditável  
- escalável  
- rastreável  

Todas as funcionalidades do AxysPro, sem exceção, **dependem direta ou indiretamente** desta camada.

---

### 7.1.1 Sobre a Camada Fundamental

A Camada Fundamental concentra responsabilidades **estruturais e sistêmicas**, comuns a qualquer domínio funcional do AxysPro.

Entre suas principais atribuições estão:

- autenticação e identificação de usuários  
- representação de pessoas físicas e jurídicas  
- controle, armazenamento e proteção de documentos e anexos  
- registro de eventos operacionais e de negócio (log do sistema)  

Esses elementos **não pertencem a um módulo específico**, sendo compartilhados de forma integrada por todo o ecossistema.

> **Regra sistêmica:**  
> Nenhum módulo pode criar estruturas paralelas que substituam ou dupliquem entidades da Camada Fundamental.

Essa diretriz garante:

- integridade estrutural  
- padronização de comportamento  
- rastreabilidade unificada  
- evolução controlada do sistema  

---

### 7.1.2 Tabelas da Camada Fundamental

As principais tabelas que compõem a Camada Fundamental incluem, entre outras:

- `pessoa`  
  Representa pessoas físicas ou jurídicas relacionadas ao sistema  
  (usuários, fornecedores, prestadores, terceiros).

- `usuario`  
  Representa o acesso autenticado ao sistema, sempre vinculado a uma pessoa.

- `tipo_documento`  
  Classificação lógica dos documentos utilizados no sistema.

- `anexo`  
  Registro de documentos físicos vinculados a entidades do sistema, com controle sistêmico e tratamento de documentos sensíveis.

- `log_sistema`  
  Registro transversal de eventos operacionais e de negócio, responsável por garantir rastreabilidade, auditoria e análise de uso.

Essas tabelas são consideradas **compartilhadas** e **imutáveis do ponto de vista conceitual**, sendo utilizadas por todos os módulos do AxysPro.

---

### 7.1.3 Arquivos e Diretórios da Camada Fundamental

A Camada Fundamental não possui telas ou rotas próprias de negócio, porém define **estruturas e diretórios obrigatórios**, utilizados por todo o sistema.

#### Backend (Infraestrutura)

```text
backend/
  core/
    auth/
    db.py
    paths.py
```

Esses arquivos concentram:

- autenticação e controle de acesso  
- configuração de banco de dados  
- definição de paths oficiais do sistema  

Em relação a comunicação com o banco, sendo o banco padrão o **PostgreSQL** o arquivo db.py deve conter:

- configuração de conexão com o banco de dados PostgreSQL  
- gerenciamento de sessões e conexões  
- abstração de acesso ao banco para os módulos  


---

#### Templates Base

```text
backend/templates/
  base.html
  header.html
  footer.html
```

Templates estruturais obrigatórios, herdados por todas as páginas do sistema.

---

#### Arquivos Estáticos Globais

```text
static/
  css/
    axyspro.css
  js/
    core/
      axyspro.core.js
```

Arquivos responsáveis por:

- identidade visual do sistema  
- comportamento global de interface  
- modais universais  
- alertas, confirmações e utilitários  

---

#### Documentos, Uploads e Logs

```text
instance/
  docs/
    anexos/
    sensiveis/
  uploads/
    tmp/
    imports/
  logs/
```

Estrutura responsável por:

- armazenamento definitivo de documentos  
- processamento temporário de arquivos  
- logs de aplicação e auditoria  

---

> **Regra Final da Camada Fundamental:**  
> Toda funcionalidade do AxysPro deve utilizar exclusivamente as estruturas definidas nesta camada, sendo **vedada a criação de soluções paralelas ou fora do padrão sistêmico**.

