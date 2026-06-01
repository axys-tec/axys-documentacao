# Checklist Axys — Documentação vs Implementação

Este checklist define, de forma **normativa e obrigatória**, o que **pode** e o que **não pode** constar na documentação oficial do ecossistema Axys.

Seu objetivo é:
- preservar a autoridade arquitetural da documentação;
- evitar acoplamento entre conceito e implementação;
- garantir evolução técnica sem ruptura conceitual;
- impedir que documentos se tornem obsoletos ou contraditórios.

---

## 1. Princípio Fundamental

A documentação Axys é **normativa**.

Ela define **regras, contratos e invariantes**.  
Ela **não descreve implementação física**, detalhes de stack ou código executável.

> **O sistema implementa a documentação.  
A documentação não implementa o sistema.**

---

## 2. O que PODE constar na documentação Axys

### 2.1 Conceitos e Entidades
- Definição conceitual de entidades (ex: Tenant, Licença, Usuário)
- Responsabilidade de cada entidade
- Relações lógicas entre entidades
- Invariantes e restrições conceituais

---

### 2.2 Arquitetura e Governança
- Princípios arquiteturais
- Estratégia de tenancy
- Estratégia de licenciamento
- Regras de isolamento
- Padrões de integração entre módulos
- Contratos de API em nível conceitual

---

### 2.3 Regras Operacionais
- O que é permitido ou proibido
- Fluxos conceituais (ex: pagamento → licença → ativação)
- Modos de operação (online, offline, degradado)
- Papéis e responsabilidades

---

### 2.4 Segurança e Conformidade
- Princípios de segurança
- Regras de acesso
- Diretrizes de criptografia
- Política de auditoria
- Tratamento de dados sensíveis

---

### 2.5 Evolução e Versionamento
- Estratégia de versionamento
- Política de breaking changes
- Diretrizes de compatibilidade
- Regras de migração conceitual

---

## 3. O que NÃO PODE constar na documentação Axys

### 3.1 Implementação Técnica
- Código-fonte (Python, SQL, JS, etc.)
- Trechos de código executável
- Funções, métodos ou classes reais
- Frameworks específicos (exceto quando estritamente conceituais)

---

### 3.2 Banco de Dados
- DDL (`CREATE TABLE`, `ALTER TABLE`, etc.)
- Tipos físicos de colunas
- Índices
- Engines de banco
- Scripts de migração

---

### 3.3 Infraestrutura
- Endereços IP
- Paths físicos de servidor
- Configurações de serviço
- Credenciais ou segredos
- Comandos de deploy

---

### 3.4 Detalhes Voláteis
- Ajustes pontuais
- Hotfixes
- Workarounds
- Decisões temporárias
- Soluções experimentais

---

## 4. Onde cada tipo de informação DEVE viver

| Tipo de Informação | Local Correto |
|-------------------|--------------|
| Regras e contratos | Documentação Axys |
| Conceitos e entidades | Documentação Axys |
| Código-fonte | Repositório |
| DDL / migrations | `database/ddl` |
| Scripts auxiliares | Repositório |
| Configuração de ambiente | `.env` / Infra |
| Logs e eventos | Runtime |

---

## 5. Regra de Validação de Documentação

Antes de qualquer documento ser considerado **válido**, deve responder positivamente às perguntas:

- Este conteúdo descreve **o que o sistema é**, e não **como ele foi implementado**?
- Este texto continuará válido se:
  - o banco mudar?
  - o framework mudar?
  - a infraestrutura mudar?
- Este conteúdo define uma **regra**, não um detalhe técnico?

Se alguma resposta for **não**, o conteúdo **não pertence à documentação Axys**.

---

## 6. Autoridade do Checklist

Este checklist é **vinculante** para:
- o AxysPro Core;
- todos os módulos funcionais;
- todas as microapps;
- qualquer documentação futura do ecossistema Axys.

Qualquer violação deve ser considerada **erro arquitetural** e corrigida.

---

## 7. Encerramento

A documentação Axys é um **contrato arquitetural**.

Ela deve permanecer:
- limpa;
- estável;
- atemporal;
- tecnicamente defensável.

Tudo o que for volátil pertence ao código.
