**AxysPro — Documentação Oficial do Sistema**

# Visão Geral do Ecossistema Axys

O **Axys** é concebido como um **ecossistema de sistemas**, projetado para oferecer organização, padronização e governança de informações **operacionais, gerenciais e estratégicas**de empresas, projetos, obras e unidades de negócio.

O **AxysPro** é o **sistema principal desse ecossistema**, atuando como a plataforma robusta e multifuncional de gestão por empresa.
Além dele, o ecossistema contempla **MicroApps independentes** e um **sistema central de governança e licenciamento**, todos integrados conceitualmente por contratos e diretrizes comuns.

Essa separação é **intencional e estrutural**, permitindo:
- isolamento por empresa;
- escalabilidade técnica e comercial;
- evolução independente de sistemas;
- governança clara de acesso, licenças e funcionalidades.

---

## 0.1 Sistemas que compõem o Ecossistema

### Sistema 1 — AxysPro
Sistema principal, robusto e multifuncional, executado de forma **isolada por empresa**, com banco de dados próprio e controle interno de identidade, permissões e auditoria.

### Sistema 2 — AxysHub
Sistema central hospedado na infraestrutura da **Axys Engenharia e Tecnologia Ltda.**, responsável por **licenciamento, billing e governança externa do ecossistema**.

### Sistema 3 — AxysApps (MicroApps)
Conjunto de aplicações independentes, com **ciclo de vida próprio**, que podem operar de forma isolada ou integrada ao ecossistema Axys, sempre sob controle do AxysHub.

Cada **módulo**, **API** ou **MicroApp** integrante do ecossistema Axys possui **documentação própria**, responsável por detalhar:
- regras de negócio específicas;
- modelos de dados;
- fluxos operacionais;
- endpoints e integrações.

---

Diferentemente de soluções genéricas, o AxysPro é fundamentado em uma **arquitetura técnica sólida**, com previsibilidade estrutural e evolução controlada, priorizando regras claras, padronização rigorosa e compatibilidade contínua entre todos os componentes do ecossistema.

O sistema foi projetado para atuar como uma **base única e confiável de gestão**, atendendo cenários que exigem:
- rastreabilidade completa das informações;
- consistência entre dados operacionais e gerenciais;
- leitura gerencial clara e estruturada;
- crescimento progressivo sem refatorações estruturais.

Desde sua concepção, o AxysPro adota a filosofia de **contratos explícitos**, onde diretrizes de:
- modelagem de dados,
- organização de diretórios,
- padronização de interface,
- comportamento de código,
- estrutura de módulos  

são **normativas** e válidas para todo o ecossistema, sem exceções pontuais.

Embora estruturado de forma modular, o AxysPro **não é um conjunto de sistemas isolados**. Cada módulo pode operar de forma autônoma quando necessário, porém sempre com **modelagem, nomenclatura e princípios plenamente compatíveis**, permitindo integração nativa, expansão gradual e reutilização de componentes sem rupturas ou retrabalho.

Este documento estabelece as **bases oficiais do AxysPro**, definindo:
- diretrizes fundamentais do sistema;
- padrões técnicos obrigatórios;
- princípios de organização estrutural;
- enquadramento do AxysPro no ecossistema Axys.

Trata-se de um **documento normativo, vivo e evolutivo**, que deve ser utilizado como
**referência técnica permanente** para o desenvolvimento, manutenção e expansão contínua do AxysPro.

---

## 0.2 Sistema 1 — AxysPro (ERP Principal)

### 0.2.1 Características Fundamentais

- Execução **single-tenant por instalação**
- Banco de dados **exclusivo por empresa**
- Pode operar:
  - em ambiente cloud
  - em servidor local (on-premises)
- Interface orientada à produtividade, inspirada em ERPs desktop
- Forte uso de documentos, anexos e informações técnicas

### 0.2.2 Isolamento e Segurança

- Não existe separação por tenant no banco de dados
- O isolamento é garantido por:
  - identidade e autenticação
  - papéis e permissões (RBAC)
  - auditoria obrigatória de ações críticas

#### Arquivos e Anexos
- armazenados fora do banco de dados;
- criptografados em repouso;
- acesso sempre mediado pelo AxysPro Core.

---

## 0.3 Sistema 2 — AxysHub (Portal Central)

> **Nota:** Este sistema **não é um módulo** do AxysPro.

### 0.3.1 Responsabilidades Conceituais

- Cadastro e gestão de empresas/clientes Axys
- Controle de licenças do AxysPro
- Definição de planos e funcionalidades habilitadas
- Controle de acesso e liberação de MicroApps
- Centralização de billing e financeiro do ecossistema

### 0.3.2 Integração com AxysPro

- O AxysPro consulta o AxysHub para validação de licenças
- Deve existir mecanismo de tolerância a falhas de internet (*grace period*)
- O AxysHub é a **autoridade central**, mas **não executa lógica operacional** do AxysPro

---

## 0.4 Sistema 3 — AxysApps (MicroApps)

### 0.4.1 Conceito

MicroApps são aplicações **independentes**, não acopladas funcionalmente ao AxysPro,
mas que podem se integrar ao ecossistema Axys por contratos definidos.

### 0.4.2 Características

- Ciclo de vida próprio
- Podem ser:
  - instaladas localmente
  - hospedadas externamente
- Licenciamento:
  - mensal
  - por uso
- Governadas pelo AxysHub

### 0.4.3 Organização Conceitual

Exemplo de hierarquia lógica:

- AxysApps
  - AxysEasy
  - AxysDocs
  - AxysEng
  - Outras MicroApps futuras

---

## 0.5 Documentação Contínua

A documentação do Axys:
- **não é estática**;
- evolui junto com funcionalidades, telas e regras;
- possui níveis distintos:
  - **Core** (normativo)
  - **ADRs** (decisões arquiteturais)
  - **Módulos**
  - **Telas (UI)**

A documentação é **parte integrante do sistema**, e não um artefato externo.

---

## Escopo da Documentação AxysPro

A documentação do AxysPro tem como objetivo estabelecer:
- princípios arquiteturais do ecossistema;
- regras de organização de código, dados e módulos;
- contratos mínimos de integração entre sistemas;
- diretrizes de segurança, permissões e auditoria;
- padrões de nomenclatura, versionamento e evolução.

Esta documentação **não descreve regras de negócio internas**, telas, fluxos específicos
ou cálculos de módulos individuais.
Esses conteúdos devem constar exclusivamente na
**documentação própria de cada módulo, API ou MicroApp**.


# 1. Diretrizes Básicas e Regras do Sistema

Esta seção estabelece as **regras fundamentais, inegociáveis e normativas** do AxysPro.  
Tudo o que está aqui se aplica **a todo o sistema e a todos os módulos**, sem exceção.

## 1.1 Princípios Arquiteturais

- O AxysPro é um **ecossistema modular**
- Cada módulo possui domínio próprio, mas segue regras globais
- O sistema deve crescer **sem refatorações estruturais**
- Evoluções ocorrem por **contrato**, não por improviso
- Não existem exceções locais ou “gambiarras” de módulo

### Separação entre Ecossistema, Módulos e APIs

O AxysPro adota a separação clara entre:

- **Ecossistema AxysPro**  
  Responsável por definir regras estruturais, governança, identidade, permissões, auditoria e contratos de integração.

- **Módulos AxysPro**  
  Aplicações funcionais integradas ao ecossistema, que seguem integralmente suas regras e compartilham identidade, permissões e padrões comuns.

- **APIs e MicroApps**  
  Aplicações independentes, com escopo funcional específico, que podem ou não se integrar ao AxysPro por meio de contratos explícitos.

### Responsabilidade da Documentação

- A documentação AxysPro é **normativa e transversal**.
- A documentação de módulos e APIs é **funcional e específica**.

Nenhum módulo ou API deve introduzir regras que contrariem esta documentação.
Em caso de conflito, **prevalece a documentação do AxysPro**.

### Contratos de Integração

A integração entre módulos, APIs e o AxysPro ocorre exclusivamente por meio de **contratos explícitos**, que definem:

- identidade e autenticação
- escopo de permissões
- contexto de tenant/unidade
- responsabilidades de auditoria e logging

Não é permitido acoplamento direto de código ou dependência implícita entre sistemas.


### 1.1.1 Premissa de Framework por Categoria de Aplicação

- O **AxysPro (plataforma central do ecossistema)** será desenvolvido em **Django**.
- **MicroApps** (apps isoladas e específicas, comercializadas separadamente) serão desenvolvidas em **FastAPI**.
- Uma MicroApp **pode** ser integrada ao AxysPro e atuar como **módulo**, ou **pode** operar de forma **independente**, mantendo contratos mínimos de compatibilidade quando integrada.
- Integrações entre AxysPro e MicroApps devem ocorrer por **contratos explícitos** (API, autenticação, permissão, auditoria/log), sem acoplamento direto de código entre projetos.

## 1.2 Banco de Dados

O banco de dados oficial do AxysPro é o **PostgreSQL**.
A modelagem, nomenclatura de tabelas e regras de integridade devem ser compatíveis com PostgreSQL desde a origem, evitando dependência de recursos específicos de outros SGBDs.

- **Um banco de dados por empresa**
- Bancos são independentes entre empresas
- Modelagem compatível entre módulos
- Migrações devem ser versionadas
- Migrações são executadas por versão do AxysPro, e aplicadas em cada banco (empresa)

## 1.3 Convenções de Modelagem

- Todas as tabelas no **singular**
- Todas as colunas seguem o padrão:  
  `nome_tabela_nome_campo` (exceto tabela usuario, cujos campos seguem user_*)
- Datas no formato ISO: `YYYY-MM-DD`
- Competência no formato: `YYYY-MM`
- Valores monetários armazenados como `NUMERIC(14,2)`
- Valores monetários devem ser tratados como Decimal na aplicação, nunca float
- Exclusões físicas devem ser evitadas  
  → priorizar **inativação lógica**

## 1.4 Regras Normativas — 

## 1.4.1 Domínios Textuais e CHECK Constraints

No AxysPro, campos textuais que representam **domínios controlados** seguem os seguintes princípios:

- **Domínios evolutivos e controlados**  
  (ex.: status, origem, tipo de ação com conjunto conhecido e evolução previsível)  
  → devem ser modelados como `TEXT` com `CHECK constraint`, **sem uso de ENUM**, permitindo expansão controlada sem refatorações estruturais.

- **Domínios altamente mutáveis ou extensíveis**  
  (ex.: ações de log, eventos técnicos, operações internas, integrações externas)  
  → devem ser modelados como `TEXT` **sem CHECK constraint**, com validação e padronização realizadas exclusivamente na camada de aplicação.

Essa diretriz evita engessamento do banco de dados, preserva integridade semântica e mantém flexibilidade para evolução contínua do sistema.

### 1.4.2 Campos *_datahora_atualizacao

Os campos `*_datahora_atualizacao` **não são atualizados automaticamente pelo banco de dados**.

Sua manutenção é responsabilidade da **camada de aplicação do AxysPro** ou de uma **trigger padrão definida pelo sistema**, devendo refletir fielmente a última alteração efetiva do registro.


## 1.5 Segurança

- Senhas armazenadas **exclusivamente** com **hash Argon2id**
- Nunca armazenar senhas em texto puro
- Controle de acesso é responsabilidade do sistema, não do arquivo
- Documentos sensíveis exigem controle sistêmico

### 1.5.1 Criptografia de Documentos em Repouso

No AxysPro, a segurança de documentos sensíveis é garantida prioritariamente por **criptografia em repouso**, e não por mecanismos de restrição no frontend.

#### Diretrizes Obrigatórias

- Todo documento marcado como sensível (`anexo_sensivel = TRUE`) **deve ser armazenado criptografado em disco**.
- O arquivo físico armazenado **não pode ser aberto, interpretado ou utilizado fora do sistema**, mesmo que acessado diretamente no servidor.
- A criptografia deve utilizar algoritmo forte e consolidado (ex.: **AES-256-GCM** ou equivalente).
- A **chave de criptografia**:
  - não deve ser armazenada no banco de dados;
  - não deve estar versionada em repositório de código;
  - deve ser fornecida exclusivamente via **variável de ambiente segura** ou **serviço de segredo**.

#### Proibição Explícita

É terminantemente proibido:

- armazenar documentos sensíveis em formato legível em disco;
- servir o arquivo original criptografado ou descriptografado diretamente ao frontend;
- confiar em proteções de PDF (senha, bloqueio de cópia, impressão) como mecanismo primário de segurança.

> **Regra sistêmica:**  
> No AxysPro, a proteção de documentos ocorre **antes da interface**, na camada de armazenamento e renderização controlada.


## 1.6 Campos Booleanos

- `TRUE` → verdadeiro / ativo / sim  
- `FALSE` → falso / inativo / não

---

# 2. Arquitetura de Tenancy e Escalabilidade

Esta seção estabelece as **premissas arquiteturais oficiais** do AxysPro no que se refere a **isolamento de dados, organização multiempresa (tenancy)** e **estratégia de escalabilidade**.

As diretrizes aqui descritas são **normativas** e servem como base para decisões futuras de modelagem, infraestrutura e evolução do ecossistema Axys.

---

## 2.1. Premissa Geral de Tenancy no Ecossistema Axys

O AxysPro é concebido como um **ecossistema modular**, composto por:

- um **Core AxysPro**, voltado ao uso interno do escritório de engenharia, operando em regime **single-tenant**;  
- **microapps independentes** (ex.: AxysEasy, AxysDocs, AxysEng), que **podem operar em regime multi-tenant**, conforme a natureza do serviço prestado.

O modelo de tenancy **não é imposto globalmente**, sendo adotado **exclusivamente nas microapps** que demandam isolamento entre empresas distintas.

O Core AxysPro:
- não implementa lógica de tenant;
- representa um ambiente único e controlado;
- serve como base administrativa, conceitual e, quando aplicável, como plano de controle (control plane).

---

## 2.2. Estratégia de Isolamento por Empresa (Tenant)

Nas microapps do ecossistema Axys, cada empresa atendida é tratada como um **tenant isolado**, obedecendo às seguintes diretrizes:

- um tenant **não possui visibilidade sobre dados de outros tenants**;
- o isolamento é **estrutural**, e não apenas lógico ou baseado em permissões de usuário;
- **usuários não são utilizados como mecanismo primário de isolamento**;
- **nomes de empresas, strings normalizadas ou concatenações não são utilizados para roteamento de dados ou definição de base**.

O isolamento entre empresas é sempre definido por um **identificador de tenant explícito (`tenant_id`)**, resolvido de forma determinística pelo sistema.

Essa abordagem evita:
- vazamentos acidentais de dados;
- dependência de regras frágeis de autorização;
- acoplamento entre identidade de usuário e domínio de dados.

---

## 2.3. Control Plane e Bases de Dados

A arquitetura do Axys separa claramente:

- **Control Plane (Core Axys)**  
  Responsável por informações globais e compartilhadas, tais como:
  - cadastro de tenants;
  - usuários e associações usuário ↔ tenant;
  - permissões globais;
  - configurações da plataforma;
  - tabelas-mãe e catálogos comuns às microapps.

- **Data Store por Tenant (Microapps)**  
  Responsável exclusivamente pelos dados operacionais de cada empresa:
  - documentos;
  - processamentos;
  - registros técnicos;
  - históricos e eventos;
  - anexos (armazenados externamente, com metadados no banco).

Cada tenant pode operar:
- inicialmente em um **banco compartilhado**, preparado para evolução; ou
- em um **banco dedicado**, quando requisitos de escala, volume ou isolamento assim exigirem.

A escolha do modelo **não altera a semântica do sistema**, apenas sua topologia.

---

## 2.4. Estratégia de Evolução e Escala

O Axys é projetado para **iniciar simples e escalar de forma controlada**, obedecendo às seguintes premissas:

- microapps podem iniciar operando sobre **um único banco de dados compartilhado**;
- a arquitetura já nasce preparada para:
  - pool de bancos (sharding por tenant);
  - migração gradual de tenants para bases dedicadas;
- a migração ocorre **tenant a tenant**, sem necessidade de indisponibilidade global do sistema.

Não são permitidas decisões arquiteturais que:
- criem dependências entre dados de tenants distintos;
- exijam consultas cruzadas entre tenants;
- impeçam a realocação de um tenant para outra base no futuro.

Essa diretriz garante longevidade, previsibilidade e governança ao ecossistema Axys.


## 3. Arquitetura de Licenciamento e Controle de Uso

Esta seção define as **diretrizes oficiais de licenciamento** do ecossistema Axys, aplicáveis a todas as aplicações (AxysPro, AxysEasy, AxysDocs, AxysEng e futuras).

O objetivo do modelo de licenciamento é garantir:
- controle financeiro centralizado;
- isolamento entre tenants;
- funcionamento seguro em ambientes com ou sem conexão contínua à internet;
- resistência a tentativas de uso indevido ou burla;
- preservação total dos dados do usuário, mesmo em cenários de bloqueio.

---

### 3.1. Princípio Fundamental de Licenciamento

O controle de licenças **não reside nas aplicações cliente**.

Todas as decisões relativas a:
- validade de licença;
- status financeiro;
- limites de uso;
- bloqueios e suspensões;

são centralizadas em um **Servidor de Licenciamento Axys**, hospedado e controlado pela infraestrutura oficial da plataforma.

As aplicações Axys **consomem licenças** emitidas por esse servidor, mas **não decidem** sobre sua validade.

---

### 3.2. Servidor Central de Licenciamento (Licensing Server)

O Servidor de Licenciamento Axys é a **fonte única da verdade** e é responsável por:

- cadastro e gerenciamento de tenants;
- definição de planos e modalidades de licença;
- controle de status financeiro;
- emissão, renovação e revogação de licenças;
- auditoria de uso e eventos críticos;
- aplicação de bloqueios de forma controlada.

Esse servidor opera de forma independente das aplicações cliente e permanece sempre acessível via internet.

---

### 3.3. Modalidades de Licença

O ecossistema Axys suporta múltiplas modalidades de licenciamento, incluindo, mas não se limitando a:

- **Licenças mensais** (aplicações completas);
- **Licenças por uso** (microapps e serviços pontuais);
- **Licenças híbridas**, combinando período de validade e limites operacionais.

Os limites e características de cada plano são definidos de forma explícita e versionada, não sendo codificados diretamente nas aplicações.

---

### 3.4. Licença como Artefato Assinado

A licença Axys é tratada como um **artefato criptograficamente assinado**, e não como uma simples flag ou registro local.

Cada licença emitida contém, no mínimo:
- identificação do tenant;
- identificação da aplicação;
- plano e limites associados;
- período de validade;
- tolerância máxima de operação offline;
- vínculo com a instalação (fingerprint).

A assinatura é realizada com **chave privada exclusiva do Axys**, sendo validada localmente pelas aplicações por meio da **chave pública correspondente**.

Essa abordagem garante:
- impossibilidade de falsificação;
- detecção de alterações indevidas;
- independência de validação contínua via internet.

---

### 3.5. Operação Offline Controlada

As aplicações Axys podem operar em ambientes com conectividade limitada ou intermitente, respeitando as seguintes regras:

- a licença é validada localmente quanto à assinatura, integridade e prazo;
- é permitido funcionamento offline por um período máximo definido na licença;
- a ausência prolongada de validação online resulta em **modo degradado ou bloqueio funcional controlado**.

Em nenhuma hipótese o sistema:
- corrompe dados;
- apaga informações;
- impede acesso a dados já registrados.

---

### 3.6. Prevenção de Uso Indevido e Burla

O modelo de licenciamento Axys adota **múltiplas camadas de proteção**, incluindo:

- vínculo da licença à instalação;
- validação de timestamps e detecção de inconsistências temporais;
- exigência periódica de validação online;
- registro e envio de eventos de auditoria ao servidor central.

Tentativas de uso indevido resultam em:
- restrição progressiva de funcionalidades;
- exigência de revalidação;
- eventual bloqueio controlado, sem impacto à integridade dos dados.

---

### 3.7. Integração com Fluxo Financeiro

A liberação ou renovação de licenças **não ocorre diretamente por eventos financeiros**.

O fluxo correto é:
1. registro ou confirmação de pagamento;
2. atualização do status financeiro no servidor central;
3. emissão ou renovação de licença válida;
4. disponibilização da nova licença para a aplicação cliente.

Essa separação garante robustez, auditabilidade e independência entre os sistemas financeiro e operacional.

---

### 3.8. Diretrizes de Evolução

O modelo de licenciamento do Axys é projetado para:

- funcionar em ambientes cloud ou em servidores locais conectados à internet;
- suportar crescimento do número de tenants e aplicações;
- permitir ajustes de política sem necessidade de refatoração das aplicações cliente.

Qualquer implementação futura deve respeitar integralmente as diretrizes aqui estabelecidas.


# 4. Estrutura de Diretórios e Paths Oficiais

> **Código é imutável. Dados, documentos e logs são runtime.**

Arquivos de dados **não** devem residir dentro do pacote Python.

## 4.1 Estrutura Oficial do Projeto

```
AXYSPRO/
├── .github/                       # Governança de repositório (CI/CD, PRs, Issues)
│   ├── workflows/                 # GitHub Actions (build, lint, tests, release)
│   ├── ISSUE_TEMPLATE/            # Templates de issue
│   ├── PULL_REQUEST_TEMPLATE.md   # Template de PR
│   └── CODEOWNERS                 # (opcional) donos por área
├── .venv/              # runtime local (NÃO versionado)
├── scripts/
│   ├── dev_setup.ps1
│   ├── dev_setup.sh
│   └── run_dev.sh
├── backend/
│   ├── app.py
│   ├── config.py
│   ├── core/
│   │   ├── paths.py
│   │   ├── db.py
│   │   └── auth/
│   ├── modules/
│   │   ├── syscost/
│   │   ├── documentos/
│   │   └── ...
│   ├── templates/                 # Templates Jinja (UI)
│   │   ├── components/
│   │   └── pages/
│   │       ├── syscost/
│   │       └── documentos/
│   └── static/                    # PUBLICADO / SERVIDO
│       └── dist/                  # Build do frontend
│
├── static/                        # FONTE CSS/JS do sistema
│   ├── css/
│   │   ├── axyspro.css
│   │   └── modules/
│   └── js/
│       ├── core/
│       ├── widgets/
│       └── pages/
│
├── frontend/                      # FONTE frontend (quando aplicável)
│   ├── package.json
│   ├── vite.config.js
│   ├── src/
│   └── public/
│
├── docs/                          # DOCUMENTAÇÃO OFICIAL (VERSIONADA)
│   ├── core/
│   │   ├── axyspro_core.md
│   │   └── axys_modules_core.md
│   ├── adr/
│   │   ├── ADR-000-template.md
│   │   ├── ADR-001.md
│   │   └── ...
│   ├── modules/
│   │   ├── general.md
│   │   ├── syscost.md
│   │   └── ...
│   └── ui/                        # DOCUMENTAÇÃO POR TELA
│       ├── README.md
│       └── pages/
│           ├── syscost/
│           │   ├── despesas_listar.md
│           │   └── despesas_cadastrar.md
│           └── documentos/
│               └── anexos_listar.md
│
├── instance/                      # RUNTIME (NÃO VERSIONADO)
│   ├── db_artifacts/              # Artefatos do banco (Postgres é externo)
│   │   ├── migrations/
│   │   └── snapshots/
│   ├── storage/                   # Arquivos governados e criptografados
│   │   └── objects/
│   ├── uploads/                   # Entrada temporária
│   │   ├── tmp/
│   │   └── imports/
│   ├── logs/                      # Logs e auditoria
│   └── customer_docs/             # Docs operacionais do cliente (não normativas)
│
└── README.md
```

OBS: Diretório destinado a artefatos relacionados ao banco de dados, tais como:

- scripts de criação e migração
- dumps de backup
- arquivos auxiliares de manutenção

O banco de dados PostgreSQL **não reside neste diretório**, sendo executado como serviço externo.

OBS — Modelo de Isolamento (AxysPro)

O AxysPro, em sua distribuição principal, é **single-tenant por instalação**: cada cliente possui uma instância isolada (cloud ou on-premises).  
Portanto, **não existe separação por tenant dentro do banco** nesta modalidade.

O isolamento de acesso ocorre por:
- **identidade, papéis e permissões (RBAC)**
- **regras de acesso a documentos (incluindo conteúdo sensível)**
- **auditoria obrigatória de ações críticas**

A estratégia multi-tenant aplica-se às **MicroApps** quando executadas em ambiente compartilhado.

## 4.2 Definições Canônicas

## 4.2 Definições Canônicas (atualizado)

**Diretórios base:**
- `root_dir` → raiz do projeto  
- `backend_dir` → `backend/`  
- `static_dir` → `static/` (fonte CSS/JS do sistema)  
- `frontend_dir` → `frontend/`  
- `docs_dir` → `docs/` (versionada)  
- `ui_docs_dir` → `docs/ui/` (documentação por tela)  

**Runtime (instance):**
- `instance_dir` → `instance/`  
- `db_artifacts_dir` → `instance/db_artifacts/`  
- `migrations_dir` → `instance/db_artifacts/migrations/`  
- `snapshots_dir` → `instance/db_artifacts/snapshots/`  
- `storage_dir` → `instance/storage/`  
- `uploads_dir` → `instance/uploads/`  
- `tmp_dir` → `instance/uploads/tmp/`  
- `imports_dir` → `instance/uploads/imports/`  
- `logs_dir` → `instance/logs/`  
- `customer_docs_dir` → `instance/customer_docs/`  

## 4.3 Regras de Uso
- **uploads/**: entrada temporária (pode ser apagado após processamento)  
- **docs/**: armazenamento definitivo de anexos/documentos (persistente)  
- **tmp/**: processamento (extrações, conversões, importações)  
- **logs/**: logs de aplicação e auditoria (rotacionáveis)  
- Documentos sensíveis devem ficar em `docs/sensiveis/` e o acesso é controlado por permissão (sem senha de desbloqueio no arquivo).

---

# 5. Padronização Geral do Sistema

Esta seção concentra **todas as regras de padronização do AxysPro**, sendo **normativa, obrigatória e transversal** a todo o ecossistema.  
Nenhum módulo, tela ou componente pode violar os padrões aqui definidos.

O objetivo desta padronização é garantir:

- consistência visual e comportamental  
- previsibilidade técnica  
- reutilização segura de componentes  
- redução de divergências e bugs  
- evolução controlada do sistema  

Tudo o que for padronizável **deve estar aqui**.  
O que não estiver documentado **não está autorizado**.

---

## 5.1 Padronização de CSS e Comportamento Visual

O AxysPro adota um **Design System centralizado**, único e evolutivo, responsável por definir a identidade visual e os comportamentos básicos de interface do sistema.

### 5.1.1 Regras Gerais

- É **proibido** o uso de CSS inline (`style="..."`)
- É **proibido** o uso de `<style>` dentro de templates HTML
- Todo estilo deve ser aplicado exclusivamente via **classes CSS**
- Necessidades novas de interface devem resultar em **evolução do CSS oficial**, nunca em soluções locais

### 5.1.2 Arquivos Oficiais de Estilo

- CSS global do sistema:  
  `static/css/axyspro.css`
- CSS específico de módulo (somente quando inevitável):  
  `static/css/modules/syscost.css`

### 5.1.3 Tokens de Tema

O sistema deve definir variáveis globais no seletor `:root`, incluindo obrigatoriamente:

- cores principais, secundárias e estados (sucesso, erro, alerta, info)
- tipografia (família, tamanhos, pesos)
- espaçamentos
- bordas, sombras e radius
- larguras máximas de layout

Esses tokens representam a **identidade visual oficial do AxysPro** e devem ser reutilizados em todo o sistema.

### 5.1.4 Componentes Padronizados

Devem existir classes e estruturas padronizadas para:

- Header institucional
- Cards
- Botões (primário, secundário, perigo, mini)
- Formulários
- Tabelas (com hover e cabeçalho destacado)
- Alertas
- Badges / tags de status
- Modal universal

Componentes **não devem conter lógica de negócio**, apenas estrutura e estilo.

---

## 5.2 Padronização de JavaScript

Esta seção define regras **claras, únicas e obrigatórias** para organização, reutilização e carregamento de JavaScript no AxysPro.

O objetivo é eliminar:

- duplicação de código  
- divergências de comportamento  
- scripts espalhados em templates  
- dependências ocultas entre telas  

### 5.2.1 Princípios Gerais

- É **terminantemente proibido** JavaScript inline em templates HTML
- Templates HTML não devem conter lógica JavaScript, exceto inclusão de arquivos `.js`
- JavaScript deve ser classificado por responsabilidade:
  - **Core** (global)
  - **Widgets** (componentes reutilizáveis)
  - **Pages** (específico de tela)

### 5.2.2 Estrutura Oficial de Diretórios

```text
static/js/
├─ core/
│  └─ axyspro.core.js
├─ widgets/
│  ├─ modal.js
│  ├─ file_preview.js
│  ├─ table_filters.js
│  └─ confirm_actions.js
└─ pages/
   └─ <modulo>/
      └─ <pagina>.js
```

### 5.2.3 Core JavaScript

Arquivo obrigatório carregado em **todas as páginas autenticadas**.

**Responsabilidades do Core:**

- Modal universal (abrir, fechar, ESC, backdrop, download e impressão)
- Confirmações e prompts padronizados
- Alertas globais
- Utilitários globais
- Helpers de `fetch` / AJAX
- Comportamentos globais de UX

**Regra absoluta:**  
Se uma função é usada em **mais de uma tela**, ela **deve estar no Core**.

### 5.2.4 Widgets

Widgets são **componentes reutilizáveis**, desacoplados do contexto da página.

**Exemplos:**

- Visualizador de arquivos (imagem / PDF)
- Modais reutilizáveis
- Filtros de tabela
- Botões de download e impressão

**Regra:**  
Widgets **não conhecem o contexto da página** e **não acessam campos específicos de tela**.

### 5.2.5 JavaScript de Página

Código **exclusivo** de uma tela específica.

**Exemplos:**

- Integração ViaCEP
- Validações específicas
- Cálculos locais

**Regra:**  
Somente código que depende diretamente dos campos daquela tela pode residir em JS de página.

### 5.2.6 Inclusão de JavaScript nos Templates

- `axyspro.core.js` é **obrigatório**
- Cada página pode carregar **apenas um JS próprio**
- Inclusão sempre no **final do `<body>`**

### 5.2.7 Política de Reutilização

- Usou em **2 telas** → mover para Core ou Widget
- Modal / confirmação / preview → **nunca** em JS de página
- É proibido copiar e colar funções entre páginas

### 5.2.8 Proibições Explícitas

É terminantemente proibido:

- JavaScript inline
- Scripts longos em templates
- Duplicação de lógica
- Modais específicos por página
- Dependência cruzada entre Widgets e Pages

---

## 5.3 Padronização de Templates HTML — AxysPro / SysCost

Esta seção define o **contrato estrutural obrigatório** para uso e organização de templates HTML em todo o ecossistema **AxysPro**, aplicável ao módulo **SysCost** e a todos os módulos futuros.

Este padrão tem como objetivo:

- garantir **consistência visual e estrutural**
- reduzir retrabalho e conflitos de estilo
- eliminar divergências entre páginas
- facilitar manutenção, leitura e evolução do sistema

Este contrato **não define layout gráfico, cores ou identidade visual**.  
Ele define **estrutura, responsabilidades e limites**.

---

### 5.3.1 Princípios Fundamentais

Os princípios abaixo são **normativos e inegociáveis**:

1. Nenhuma página HTML é autônoma  
2. Toda página **herda estrutura base**
3. CSS e JavaScript **não são definidos dentro da página**
4. Componentes visuais seguem **contrato reutilizável**
5. Templates devem ser **previsíveis e auditáveis**

---

### 5.3.2 Localização Oficial dos Templates

Todos os templates HTML devem residir obrigatoriamente em:

```text
backend/templates/
```

Estrutura mínima obrigatória:

```text
templates/
├─ base.html
├─ header.html
├─ footer.html
├─ components/
└─ pages/
```

É **proibido** criar templates HTML fora dessa hierarquia.

---

### 5.3.3 Template Base (`base.html`)

O arquivo `base.html` é o **contrato estrutural máximo** do AxysPro.

#### Responsabilidades do `base.html`

- Definir a estrutura `<html>`, `<head>` e `<body>`
- Realizar a inclusão global de:
  - CSS padrão do sistema
  - JavaScript global (Core)
- Definir os blocos oficiais de extensão

#### Proibições

Nenhuma página pode:

- redefinir `<html>` ou `<body>`
- importar CSS adicional
- importar JavaScript global manualmente

---

### 5.3.4 Header e Footer

#### `header.html`

Responsável por:

- cabeçalho institucional
- navegação principal
- identidade visual
- informações do usuário autenticado

#### `footer.html`

Responsável por:

- informações institucionais
- identificação do usuário logado
- versão do sistema
- data e hora, quando aplicável

**Regra absoluta:**  
Header e footer **não são opcionais** em páginas pós-login.

---

### 5.3.5 Organização das Páginas

Todas as páginas finais devem residir em:

```
templates/pages/
```

Exemplos:

- `pages/despesas_listar.html`
- `pages/despesas_cadastrar.html`
- `pages/pessoas_cadastrar.html`

É **proibido** criar páginas soltas diretamente na raiz de `templates/`.

---

### 5.3.6 Componentes Reutilizáveis

Componentes reutilizáveis devem residir em:

```text
templates/components/
```

Exemplos de componentes:

- tabelas
- modais
- blocos de alerta
- cards
- filtros
- formulários reutilizáveis

**Regra:**  
Se um trecho HTML for utilizado em **mais de um local**, ele **deve obrigatoriamente se tornar um componente**.

---

### 5.3.7 Blocos Permitidos

Os únicos blocos Jinja permitidos nos templates são:

- `{% block title %}`
- `{% block content %}`
- `{% block scripts_page %}`

Nenhum outro bloco é permitido sem documentação e aprovação prévia.

---

## 5.4 Contratos de Interface (UI/UX)
 **UI = User Interface | UX = User Experience** 

Os contratos de interface definem **comportamentos obrigatórios do sistema**, não decisões estéticas.

### 5.4.1 Modal Universal

O AxysPro adota **um único Modal Universal**, reutilizável e previsível.

Todo modal deve obrigatoriamente:

- possuir botão explícito de fechar
- fechar ao pressionar **ESC**
- fechar ao clicar no **backdrop**
- bloquear interação com o fundo
- suportar exibição de:
  - formulários
  - imagens
  - arquivos PDF

Funcionalidades adicionais suportadas pelo modal:

- download
- impressão

É **proibido** criar modais específicos por página.

---

### 5.4.2 Estados Visuais Obrigatórios

Toda ação relevante do sistema deve apresentar **feedback visual claro**.

Estados obrigatórios:

- loading
- vazio
- erro
- sucesso
- confirmação crítica

Nenhuma ação relevante pode ocorrer sem **estado visual explícito**.

---

## 5.5 Segurança de Documentos e Visualização Controlada

Esta seção estabelece as regras **normativas, obrigatórias e transversais** para visualização de documentos sensíveis no AxysPro.

Para evitar interpretações ambíguas entre os conceitos de visualização e renderização, estabelece-se que:
- Renderização refere-se ao processo técnico server-side de conversão do documento original em representação segura.
- Visualização refere-se ao ato do usuário acessar a representação renderizada.

### 5.5.1 Princípio Fundamental

No AxysPro, **nenhum usuário comum recebe o arquivo original** de documentos sensíveis, independentemente do formato (PDF, imagem, etc.).

A visualização ocorre exclusivamente por meio de **representações renderizadas**, garantindo que:

- não seja possível copiar texto sensível;
- não seja possível extrair conteúdo oculto;
- não seja possível abrir o documento fora do sistema.

O acesso ao arquivo original é restrito a usuários com permissão especial (ex.: *UserMaster*), por rotas segregadas, auditadas e nunca expostas por padrão.

O AxysPro preserva o documento original íntegro (inclusive quando assinado digitalmente), e o acesso ao original é governado por permissões elevadas e auditado, enquanto a operação cotidiana ocorre por renderização controlada.

---

### 5.5.2 Renderização como Camada de Segurança

Ao solicitar a visualização de um documento sensível:

1. O backend valida permissões do usuário **por código de sensibilidade**, seguindo a ordem definida em 3.5.5.1.
2. O arquivo original é descriptografado **apenas em memória**.
3. O sistema gera uma **renderização raster por página**.
4. O frontend recebe **somente imagens**, nunca o binário original.

Opcionalmente, o sistema pode gerar um **PDF derivado composto exclusivamente por imagens**, simulando uma impressão digitalizada, para download controlado.

---

### 5.5.3 Redaction (Tarjamento Real de Conteúdo)

A ocultação de informações sensíveis é implementada por **redaction real**, aplicada **durante a renderização server-side**.

A tarja:

- não é apenas um overlay visual;
- remove definitivamente o conteúdo da representação entregue ao usuário;
- impede seleção, cópia, impressão ou reconstrução da informação.

---

### 5.5.4 Sensibilidade por Região do Documento

Cada documento pode conter múltiplas regiões sensíveis, classificadas por **códigos de sensibilidade**, tais como:

- `FINANCEIRO`
- `DADOS_PESSOAIS`
- `JURIDICO`
- `RH`

Para cada região sensível devem ser registrados:

- página do documento;
- coordenadas da região (x, y, largura, altura);
- código de sensibilidade;
- usuário responsável;
- data do registro.

---

### 5.5.5 Associação entre Sensibilidade e Permissões

As permissões são atribuídas aos **códigos de sensibilidade**, e não diretamente às regiões.

Durante a renderização:

- se o usuário possui permissão para o código → a região é exibida;
- se não possui → a região é tarjada de forma definitiva na imagem gerada.

Esse modelo permite que um mesmo documento seja exibido de formas diferentes conforme o perfil do usuário, sem duplicação física de arquivos.

A decisão final deve obedecer obrigatoriamente à **Ordem de Avaliação de Permissões** definida em 3.5.5.1.

---

### 5.5.5.1 Ordem de Avaliação de Permissões (Regra Sistêmica)

Esta regra constitui o **algoritmo oficial de autorização documental do AxysPro**, devendo ser aplicada de forma idêntica em todos os módulos, telas, serviços e rotinas.

A decisão de exibir ou tarjar uma região sensível durante a renderização é resultado de uma **avaliação determinística e auditável** de permissões.

A ordem obrigatória de avaliação é:

1. **Bloqueio explícito por usuário** (se existir regra de negação específica e vigente)  
   → prevalece sobre qualquer permissão herdada.

2. **Permissão explícita por usuário** (`usuario_sensibilidade`)  
   → se o usuário possui permissão direta para o `sensibilidade_codigo`, a região pode ser exibida, renderizada ou disponibilizada para download conforme as flags de autorização
   (ver sem tarja / baixar derivado sem tarja / baixar original).

3. **Permissão herdada por perfil** (`usuario_perfil` + `perfil_sensibilidade`)  
   → se não houver permissão direta no usuário, avalia-se a permissão herdada do(s) perfil(is) vinculados ao usuário.

4. **Fallback padrão: negar**  
   → na ausência de permissão explícita (direta ou herdada), a região é **tarjada obrigatoriamente**.

Regras complementares:

- A autorização é sempre avaliada **por código de sensibilidade**, nunca por coordenada isolada.
- O resultado da avaliação deve ser registrável (via `log_documento_acesso` e/ou `log_sistema`) por meio de `log_meta`
  contendo, quando aplicável: `codigo_sensibilidade`, `resultado` (permitido/tarjado), `origem_permissao` (usuario/perfil/negado).
- Esta ordem garante previsibilidade, reduz exceções ocultas e permite auditoria jurídica e administrativa.


---
### 5.5.6 Cache e Performance

As renderizações podem ser armazenadas em cache temporário considerando:

- identificador do documento;
- hash das permissões do usuário;
- número da página.

O cache deve possuir:

- TTL configurável;
- política de descarte automático (ex.: LRU).

**Cache de Renderização**

O AxysPro deve utilizar mecanismos de cache para otimizar a renderização de documentos sensíveis.

- **TTL (Time To Live):** define por quanto tempo uma renderização permanece válida em cache.
- **LRU (Least Recently Used):** política de descarte que remove do cache os itens menos acessados quando o limite é atingido.

**Regra de Invalidação de Cache**

O cache de renderização de documentos deve ser invalidado automaticamente sempre que ocorrer qualquer uma das seguintes alterações:
- modificação de regiões sensíveis do documento,
- alteração de permissões de acesso (perfil ou usuário),
- criação ou definição de uma nova versão vigente do documento.


---

### 5.5.7 Auditoria e Dissuasão

Toda visualização de documento sensível deve gerar registro no `log_sistema`, incluindo:

- usuário;
- documento;
- páginas acessadas;
- data e hora.

Toda renderização de documento sensível deve conter **marca d’água discreta**, com identificação do usuário e timestamp, como medida obrigatória de dissuasão e rastreabilidade.

Excepcionalmente, usuários com **permissão explícita e elevada**, definida no sistema de autorização, podem realizar **download de versões derivadas do documento**, com ou sem aplicação de tarjas, conforme sua autorização.

Como regra geral, o AxysPro `não disponibiliza` o arquivo original de documentos sensíveis para perfis operacionais, sendo todo acesso cotidiano realizado por renderização controlada, devidamente auditada e registrada no log_sistema.
Excepcionalmente, perfis com autorização elevada podem realizar download do original quando necessário (ex.: preservação jurídica), por rotas segregadas e auditadas.

O AxysPro admite que documentos podem ser **gerados fora do sistema**, incluindo contratos administrativos, documentos assinados digitalmente, certificados e demais arquivos com validade jurídica própria.

Nesses casos, o AxysPro atua como **repositório soberano e fonte única da verdade**, sendo o local oficial de armazenamento, preservação e governança do documento original após seu ingresso no sistema.

#### Preservação do Documento Original

O documento original:
- é armazenado de forma íntegra;
- pode ser criptografado em repouso quando classificado como sensível;
- **não é alterado**, modificado ou substituído por versões derivadas.

A preservação do arquivo original é obrigatória para garantir:
- validade jurídica;
- cadeia de custódia;
- comprovação futura;
- recuperação em horizontes de longo prazo (5, 10, 20 anos).

#### Visualização e Acesso

Como regra geral, a **visualização cotidiana** de documentos sensíveis ocorre por meio de **renderização controlada**, com aplicação de tarjas conforme permissões, garantindo segurança operacional e evitando vazamento indevido de informações.

O **download do documento original** é permitido exclusivamente a usuários com **nível elevado de autorização**, conforme política de permissões do sistema, incluindo, mas não se limitando a:
- Diretoria;
- Proprietários;
- Jurídico;
- outros perfis explicitamente autorizados.

Esse acesso:
- é auditado;
- é registrado no `log_sistema`;
- preserva a integridade do arquivo original.

#### Restrições Operacionais

Perfis operacionais, independentemente do módulo de acesso (financeiro, contratos, RH, etc.), **não possuem permissão automática para download do documento original**, tendo acesso restrito à visualização renderizada.

Essa distinção não é baseada no tipo de documento, mas no **nível de confiança do perfil do usuário**.

### Fonte Única da Verdade

Ressalta-se que, após o ingresso no AxysPro, **nenhuma versão paralela do documento é considerada válida**.

O AxysPro passa a ser:
- o repositório oficial;
- a fonte única da verdade documental;
- o ponto de preservação histórica e jurídica dos documentos da organização.

#### Valores Controlados (sem ENUM)

No AxysPro, campos categóricos evolutivos (ex.: `log_documento_acao`, `log_documento_origem`) devem ser armazenados como `TEXT` com **restrições `CHECK`** para limitar valores permitidos.

- É proibido usar `ENUM` nativo do PostgreSQL nesses casos.
- Mudanças de domínio devem ocorrer por **migração controlada**, ajustando o `CHECK`.
- O objetivo é manter integridade no banco com flexibilidade de evolução modular.

---

### 5.5.8 Diretriz Final

> **No AxysPro, segurança documental é garantida pela não entrega do conteúdo original, e não por bloqueios no frontend.**

Este modelo substitui práticas frágeis como:
- bloqueio de copiar/imprimir em PDF;
- tarjas aplicadas apenas na interface;
- múltiplas versões físicas do mesmo documento.


---

# 6. Estrutura de Dados — Tabelas do Sistema (AxysPro)

Esta seção documenta a **estrutura oficial de dados do AxysPro**, descrevendo as tabelas do sistema em formato de consulta técnica:  
**descrição conceitual**, **campos**, **exemplos de aplicação** e **DDL**.

> Documento normativo. Em caso de divergência, prevalece a **modelagem mais completa**.

---

## Resumo Semântico das Tabelas do Sistema (autoatualizável)

O banco de dados do AxysPro é estruturado na seguinte semântica:

**Tabelas da Seção 4.1 — Usuários e Segurança**  
- `pessoa`: registra o cadastro de pessoas físicas e jurídicas.  
- `usuario`: registra o cadastro de usuários do sistema.  
- `perfil`: define perfis funcionais de uso do sistema.  
- `usuario_perfil`: associa usuários a perfis por meio de relacionamento relacional (FK), permitindo herança de permissões.

**Tabelas da Seção 4.2 — Sensibilidade e Permissões Documentais**  
- `sensibilidade_codigo`: cataloga os códigos de sensibilidade utilizados no sistema.  
- `perfil_sensibilidade`: define permissões estruturais de acesso a informações sensíveis por perfil.  
- `usuario_sensibilidade`: define permissões explícitas por usuário, atuando como exceção ou override às regras de perfil.

**Tabelas da Seção 4.3 — Documentos, Versionamento e Auditoria**  
- `tipo_documento`: classifica logicamente os tipos de documentos do sistema.  
- `anexo`: representa o documento lógico raiz, contínuo no tempo.  
- `anexo_versao`: armazena as versões físicas e técnicas dos documentos.  
- `log_documento_acesso`: registra acessos e visualizações de documentos.  
- `log_sistema`: registra eventos e ações relevantes do sistema.

**Tabelas da Seção 4.4 — Estrutura Gerencial e Financeira**  
- `centro_custo`: define os centros de custo para classificação gerencial.  
- `plano_conta`: define contas macro para consolidação gerencial.  
- `sub_plano_conta`: define contas lançáveis vinculadas a um plano de contas.  
- `despesa`: registra a despesa em nível macro, com contexto gerencial.  
- `parcela_despesa`: registra a unidade real de cobrança e pagamento da despesa.  
- `despesa_rateio`: registra a distribuição gerencial do custo pago entre centros de custo.

Este resumo funciona como uma síntese estrutural do banco de dados, permitindo identificar rapidamente em qual seção se encontra cada domínio funcional do sistema.


## 6.1 Seção — Usuários e Segurança

### 6.1.1 Pessoas (`pessoa`)

Cadastro de pessoas físicas ou jurídicas relacionadas ao sistema: usuários, fornecedores, prestadores, colaboradores ou terceiros.

**Campos:**
- `pessoa_id` — PK (IDENTITY)  
- `pessoa_nome` — nome ou razão social  
- `pessoa_numerodoc1` — CPF ou CNPJ  
- `pessoa_numerodoc2` — RG ou IE  
- `pessoa_logradouro` — logradouro  
- `pessoa_numero` — número  
- `pessoa_complemento` — complemento  
- `pessoa_bairro` — bairro  
- `pessoa_cidade` — cidade  
- `pessoa_uf` — UF  
- `pessoa_cep` — CEP  
- `pessoa_celular` — celular  
- `pessoa_telefone` — telefone  
- `pessoa_ativo` — indica se a pessoa está ativa no sistema  
- `pessoa_datahora_criacao` — data e hora de criação do registro  
- `pessoa_datahora_atualizacao` — data e hora da última atualização do registro  

**Regra Normativa — Documentos de Identificação da Pessoa**

Os campos de identificação documental da tabela `pessoa` seguem a seguinte semântica obrigatória:

- `pessoa_numerodoc1`  
  Documento **principal** da pessoa:
  - CPF, quando pessoa física
  - CNPJ, quando pessoa jurídica

- `pessoa_numerodoc2`  
  Documento **secundário**, complementar ao documento principal:
  - RG, quando pessoa física
  - Inscrição Estadual (IE), quando pessoa jurídica

**Observações normativas:**
- O campo `pessoa_numerodoc1` deve ser sempre priorizado como identificador principal da pessoa.
- O campo `pessoa_numerodoc2` é opcional e complementar.
- A validação de formato (CPF/CNPJ/RG/IE) ocorre preferencialmente na camada de aplicação.
- CHECK constraints podem ser adicionadas futuramente, caso se deseje maior rigidez semântica no banco.


**DDL:**
```sql
-- ============================================================
-- Tabela: pessoa
-- Objetivo: Cadastro base de pessoas físicas/jurídicas
-- ============================================================

CREATE TABLE IF NOT EXISTS pessoa (
  pessoa_id                   BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY, -- Identificador da pessoa (PK)
  pessoa_nome                 TEXT NOT NULL,                                   -- Nome ou razão social
  pessoa_numerodoc1           TEXT,                                            -- Documento principal (CPF/CNPJ)
  pessoa_numerodoc2           TEXT,                                            -- Documento secundário (RG/IE/etc.)
  pessoa_logradouro           TEXT,                                            -- Logradouro
  pessoa_numero               TEXT,                                            -- Número
  pessoa_complemento          TEXT,                                            -- Complemento
  pessoa_bairro               TEXT,                                            -- Bairro
  pessoa_cidade               TEXT,                                            -- Cidade
  pessoa_uf                   TEXT,                                            -- UF
  pessoa_cep                  TEXT,                                            -- CEP
  pessoa_celular              TEXT,                                            -- Celular
  pessoa_telefone             TEXT,                                            -- Telefone

  -- Controle de estado
  pessoa_ativo                BOOLEAN NOT NULL DEFAULT TRUE,                   -- Indica se a pessoa está ativa

  -- Auditoria mínima
  pessoa_datahora_criacao     TIMESTAMPTZ NOT NULL DEFAULT now(),               -- Data/hora de criação
  pessoa_datahora_atualizacao TIMESTAMPTZ NOT NULL DEFAULT now()                -- Data/hora da última atualização
);

-- Comentários (metadados do banco, úteis para consulta e programação)
COMMENT ON TABLE pessoa IS
'Cadastro base de pessoas físicas ou jurídicas relacionadas ao sistema (usuários, fornecedores, prestadores, colaboradores, terceiros).';

COMMENT ON COLUMN pessoa.pessoa_id IS
'Identificador da pessoa (PK).';

COMMENT ON COLUMN pessoa.pessoa_nome IS
'Nome ou razão social.';

COMMENT ON COLUMN pessoa.pessoa_numerodoc1 IS
'Documento principal (CPF ou CNPJ).';

COMMENT ON COLUMN pessoa.pessoa_numerodoc2 IS
'Documento secundário (RG, IE, etc.).';

COMMENT ON COLUMN pessoa.pessoa_logradouro IS
'Logradouro.';

COMMENT ON COLUMN pessoa.pessoa_numero IS
'Número.';

COMMENT ON COLUMN pessoa.pessoa_complemento IS
'Complemento.';

COMMENT ON COLUMN pessoa.pessoa_bairro IS
'Bairro.';

COMMENT ON COLUMN pessoa.pessoa_cidade IS
'Cidade.';

COMMENT ON COLUMN pessoa.pessoa_uf IS
'UF.';

COMMENT ON COLUMN pessoa.pessoa_cep IS
'CEP.';

COMMENT ON COLUMN pessoa.pessoa_celular IS
'Celular.';

COMMENT ON COLUMN pessoa.pessoa_telefone IS
'Telefone.';

COMMENT ON COLUMN pessoa.pessoa_ativo IS
'Indica se a pessoa está ativa no sistema.';

COMMENT ON COLUMN pessoa.pessoa_datahora_criacao IS
'Data e hora de criação do registro da pessoa.';

COMMENT ON COLUMN pessoa.pessoa_datahora_atualizacao IS
'Data e hora da última atualização do registro da pessoa.';
```

---

### 6.1.2 Usuário (`usuario`)

Representa um **usuário do sistema**, sempre vinculado a uma pessoa.

**Campos:**
- `user_id` — PK (IDENTITY)  
- `user_pessoa_id` — FK para `pessoa`  
- `user_login` — login de acesso (UNIQUE)  
- `user_senha_hash` — hash da senha (Argon2id)  
- `user_ativo` — indica se o usuário está ativo no sistema  
- `user_datahora_criacao` — data e hora de criação do registro  
- `user_datahora_atualizacao` — data e hora da última atualização do registro  

**DDL:**
```sql
-- ============================================================
-- Tabela: usuario
-- Objetivo: Usuários autenticados do AxysPro (sempre vinculados a uma pessoa)
-- ============================================================

CREATE TABLE IF NOT EXISTS usuario (
  user_id                   BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY, -- Identificador do usuário (PK)
  user_pessoa_id            BIGINT NOT NULL,                                  -- Pessoa vinculada ao usuário
  user_login                TEXT NOT NULL UNIQUE,                             -- Login de acesso (único)
  user_senha_hash           TEXT NOT NULL,                                    -- Hash Argon2id (nunca armazenar senha em texto)

  -- Controle de estado
  user_ativo                BOOLEAN NOT NULL DEFAULT TRUE,                   -- Indica se o usuário está ativo

  -- Auditoria mínima
  user_datahora_criacao     TIMESTAMPTZ NOT NULL DEFAULT now(),               -- Data/hora de criação
  user_datahora_atualizacao TIMESTAMPTZ NOT NULL DEFAULT now()                -- Data/hora da última atualização
);

ALTER TABLE usuario
  ADD CONSTRAINT fk_user_pessoa
  FOREIGN KEY (user_pessoa_id)
  REFERENCES pessoa (pessoa_id);

-- Comentários (metadados do banco)
COMMENT ON TABLE usuario IS
'Usuários autenticados do sistema AxysPro. Sempre vinculados a uma pessoa.';

COMMENT ON COLUMN usuario.user_id IS
'Identificador do usuário (PK).';

COMMENT ON COLUMN usuario.user_pessoa_id IS
'Pessoa vinculada ao usuário (FK para pessoa).';

COMMENT ON COLUMN usuario.user_login IS
'Login de acesso (único).';

COMMENT ON COLUMN usuario.user_senha_hash IS
'Hash Argon2id da senha do usuário (nunca armazenar senha em texto puro).';

COMMENT ON COLUMN usuario.user_ativo IS
'Indica se o usuário está ativo no sistema.';

COMMENT ON COLUMN usuario.user_datahora_criacao IS
'Data e hora de criação do registro do usuário.';

COMMENT ON COLUMN usuario.user_datahora_atualizacao IS
'Data e hora da última atualização do registro do usuário.';

COMMENT ON CONSTRAINT fk_user_pessoa ON usuario IS
'Vincula o usuário à pessoa correspondente.';
```

---

### 6.1.3 Perfil (`perfil`)

A tabela `perfil` define os **perfis funcionais e hierárquicos de usuários** no AxysPro.

Um perfil representa um **conjunto estável de responsabilidades, atribuições e níveis de confiança**, utilizado como base para herança de permissões em diferentes domínios do sistema, incluindo acesso a documentos sensíveis.

Os perfis constituem a **política estrutural padrão de autorização**, sobre a qual podem existir exceções explícitas por usuário.

---

**Campos**
- `perfil_id` — identificador único do perfil (PK)
- `perfil_codigo` — código único e estável do perfil (ex.: `ADMIN`, `JURIDICO`, `DIRETOR`)
- `perfil_nome` — nome descritivo do perfil
- `perfil_descricao` — descrição funcional do perfil
- `perfil_ativo` — indica se o perfil está ativo no sistema
- `perfil_datahora_criacao` — data e hora de criação do perfil
- `perfil_datahora_atualizacao` — data e hora da última atualização do perfil

---

**DDL**
```sql
-- ============================================================
-- Tabela: perfil
-- Objetivo: Definir perfis funcionais e hierárquicos de usuários
-- ============================================================

CREATE TABLE IF NOT EXISTS perfil (
  perfil_id                   BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  perfil_codigo               TEXT NOT NULL UNIQUE,
  perfil_nome                 TEXT NOT NULL,
  perfil_descricao            TEXT,
  perfil_ativo                BOOLEAN NOT NULL DEFAULT TRUE,
  perfil_datahora_criacao     TIMESTAMPTZ NOT NULL DEFAULT now(),
  perfil_datahora_atualizacao TIMESTAMPTZ NOT NULL DEFAULT now()
);

COMMENT ON TABLE perfil IS
'Perfis funcionais e hierárquicos do AxysPro, utilizados como base estrutural de autorização.';
```

---

### 6.1.4 Usuário x Perfil (`usuario_perfil`)

A tabela `usuario_perfil` realiza a **associação entre usuários e perfis**, permitindo que um mesmo usuário possua **um ou mais perfis simultaneamente**.

Essa associação é a base para a **herança de permissões estruturais**, incluindo permissões relacionadas a códigos de sensibilidade documental.

---

**Campos**
- `usuario_perfil_id` — identificador único do vínculo (PK)
- `usuario_perfil_user_id` — usuário associado ao perfil (FK para `usuario`)
- `usuario_perfil_perfil_id` — perfil atribuído ao usuário (FK para `perfil`)
- `usuario_perfil_ativo` — indica se o vínculo usuário–perfil está ativo
- `usuario_perfil_datahora_criacao` — data e hora da criação do vínculo
- `usuario_perfil_datahora_atualizacao` — data e hora da última atualização do vínculo

---

**DDL**
```sql
-- ============================================================
-- Tabela: usuario_perfil
-- Objetivo: Associar usuários a perfis funcionais
-- ============================================================

CREATE TABLE IF NOT EXISTS usuario_perfil (
  usuario_perfil_id                    BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  usuario_perfil_user_id               BIGINT NOT NULL,
  usuario_perfil_perfil_id             BIGINT NOT NULL,
  usuario_perfil_ativo                 BOOLEAN NOT NULL DEFAULT TRUE,

  -- Auditoria mínima
  usuario_perfil_datahora_criacao      TIMESTAMPTZ NOT NULL DEFAULT now(),
  usuario_perfil_datahora_atualizacao  TIMESTAMPTZ NOT NULL DEFAULT now(),

  CONSTRAINT fk_usuario_perfil_user
    FOREIGN KEY (usuario_perfil_user_id)
    REFERENCES usuario (user_id),

  CONSTRAINT fk_usuario_perfil_perfil
    FOREIGN KEY (usuario_perfil_perfil_id)
    REFERENCES perfil (perfil_id),

  CONSTRAINT uq_usuario_perfil
    UNIQUE (usuario_perfil_user_id, usuario_perfil_perfil_id)
);

COMMENT ON TABLE usuario_perfil IS
'Associação entre usuários e perfis, permitindo herança de permissões estruturais e controle de ativação do vínculo.';
```

---


## 6.2 Seção — Sensibilidade e Permissões Documentais

### 6.2.1 Código de Sensibilidade (`sensibilidade_codigo`)

A tabela `sensibilidade_codigo` define o **catálogo central de códigos de sensibilidade** utilizados pelo AxysPro para classificar **informações sensíveis**, seja em documentos completos ou em **regiões específicas de documentos**.

Os códigos de sensibilidade representam uma **classificação semântica e normativa da informação**, e **não configuram permissões de acesso** por si só. Eles descrevem **a natureza do dado protegido**, permitindo que o sistema aplique políticas diferenciadas de visualização, auditoria e controle.

Os códigos definidos nesta tabela são utilizados como base para:
- aplicação de tarjas em renderizações controladas;
- associação de permissões por usuário ou perfil;
- auditoria de acesso a informações sensíveis;
- evolução futura das políticas de segurança e governança documental.

Exemplos típicos de códigos de sensibilidade incluem, mas não se limitam a:
- informações financeiras;
- dados pessoais;
- informações estratégicas;
- informações jurídicas;
- dados trabalhistas ou de recursos humanos.

#### Observação Importante

A tabela `sensibilidade_codigo` **não define regras de acesso, permissões ou comportamentos operacionais**.

Ela atua exclusivamente como **catálogo normativo, estável e centralizado**, sendo consumida pelas camadas de autorização, renderização e auditoria do AxysPro.

---

**Campos**

- `sensibilidade_codigo_id` — identificador único do código de sensibilidade (PK)  
- `sensibilidade_codigo` — código textual único de sensibilidade (ex.: FINANCEIRO, JURIDICO, RH)  
- `sensibilidade_desc` — descrição legível e normativa do código de sensibilidade  
- `sensibilidade_ativo` — indica se o código está ativo e disponível para uso no sistema  
- `sensibilidade_datahora_criacao` — data e hora de criação do código  
- `sensibilidade_datahora_atualizacao` — data e hora da última atualização do código  

---

**DDL**
```sql
-- ============================================================
-- Tabela: sensibilidade_codigo
-- Objetivo: Catálogo de códigos de sensibilidade utilizados no AxysPro
-- ============================================================

CREATE TABLE IF NOT EXISTS sensibilidade_codigo (
  sensibilidade_codigo_id           BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

  -- Identificação do código
  sensibilidade_codigo              TEXT NOT NULL UNIQUE,
  sensibilidade_desc                TEXT NOT NULL,

  -- Controle de uso
  sensibilidade_ativo               BOOLEAN NOT NULL DEFAULT TRUE,

  -- Auditoria mínima
  sensibilidade_datahora_criacao    TIMESTAMPTZ NOT NULL DEFAULT now(),
  sensibilidade_datahora_atualizacao TIMESTAMPTZ NOT NULL DEFAULT now()
);

COMMENT ON TABLE sensibilidade_codigo IS
'Catálogo central de códigos de sensibilidade utilizados para classificação semântica de informações sensíveis.';

COMMENT ON COLUMN sensibilidade_codigo.sensibilidade_codigo IS
'Código textual único de sensibilidade (ex.: FINANCEIRO, JURIDICO, RH).';

COMMENT ON COLUMN sensibilidade_codigo.sensibilidade_desc IS
'Descrição legível e normativa do código de sensibilidade.';

COMMENT ON COLUMN sensibilidade_codigo.sensibilidade_ativo IS
'Indica se o código de sensibilidade está ativo e disponível para uso no sistema.';

COMMENT ON COLUMN sensibilidade_codigo.sensibilidade_datahora_criacao IS
'Data e hora de criação do código de sensibilidade.';

COMMENT ON COLUMN sensibilidade_codigo.sensibilidade_datahora_atualizacao IS
'Data e hora da última atualização do código de sensibilidade.';
```

---


### 6.2.2 Perfil x Sensibilidade (`perfil_sensibilidade`)

A tabela `perfil_sensibilidade` define as **permissões estruturais padrão** de acesso a documentos sensíveis, associando **perfis** a **códigos de sensibilidade**.

As permissões definidas nesta tabela constituem a **política geral de autorização**, sendo aplicadas a todos os usuários vinculados ao perfil, salvo quando houver **exceção explícita por usuário** (`usuario_sensibilidade`).

---

**Campos**
- `perfil_sensibilidade_id` — identificador único da permissão estrutural (PK)
- `perfil_sensibilidade_perfil_id` — perfil ao qual a permissão se aplica (FK para `perfil`)
- `perfil_sensibilidade_codigo_id` — código de sensibilidade autorizado (FK para `sensibilidade_codigo`)
- `perfil_pode_ver_sem_tarja` — indica se o perfil pode visualizar conteúdo sem tarja
- `perfil_pode_baixar_derivado_sem_tarja` — indica se o perfil pode baixar versão derivada sem tarja
- `perfil_pode_baixar_original` — indica se o perfil pode baixar o documento original
- `perfil_sensibilidade_ativo` — indica se a permissão estrutural está ativa
- `perfil_sensibilidade_datahora_criacao` — data e hora da criação da permissão
- `perfil_sensibilidade_datahora_atualizacao` — data e hora da última atualização da permissão

---

**DDL**
```sql
-- ============================================================
-- Tabela: perfil_sensibilidade
-- Objetivo: Definir permissões estruturais por perfil e código de sensibilidade
-- ============================================================

CREATE TABLE IF NOT EXISTS perfil_sensibilidade (
  perfil_sensibilidade_id                     BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  perfil_sensibilidade_perfil_id              BIGINT NOT NULL,
  perfil_sensibilidade_codigo_id              BIGINT NOT NULL,

  perfil_pode_ver_sem_tarja                   BOOLEAN NOT NULL DEFAULT FALSE,
  perfil_pode_baixar_derivado_sem_tarja       BOOLEAN NOT NULL DEFAULT FALSE,
  perfil_pode_baixar_original                 BOOLEAN NOT NULL DEFAULT FALSE,

  perfil_sensibilidade_ativo                  BOOLEAN NOT NULL DEFAULT TRUE,

  -- Auditoria mínima
  perfil_sensibilidade_datahora_criacao       TIMESTAMPTZ NOT NULL DEFAULT now(),
  perfil_sensibilidade_datahora_atualizacao   TIMESTAMPTZ NOT NULL DEFAULT now(),

  CONSTRAINT fk_perfil_sensibilidade_perfil
    FOREIGN KEY (perfil_sensibilidade_perfil_id)
    REFERENCES perfil (perfil_id),

  CONSTRAINT fk_perfil_sensibilidade_codigo
    FOREIGN KEY (perfil_sensibilidade_codigo_id)
    REFERENCES sensibilidade_codigo (sensibilidade_codigo_id),

  CONSTRAINT uq_perfil_sensibilidade
    UNIQUE (perfil_sensibilidade_perfil_id, perfil_sensibilidade_codigo_id)
);

COMMENT ON TABLE perfil_sensibilidade IS
'Permissões estruturais padrão de acesso a documentos sensíveis, definidas por perfil, com controle de ativação e auditoria mínima.';
```

### 6.2.3 Permissão por Sensibilidade (`usuario_sensibilidade`)

A tabela `usuario_sensibilidade` registra as **permissões atribuídas a usuários em relação a códigos de sensibilidade**, permitindo ao AxysPro controlar **quem pode visualizar, baixar versões derivadas ou acessar o documento original**, conforme a natureza da informação protegida.

Essa abordagem dissocia **classificação da informação** (definida em `sensibilidade_codigo`) de **autorização de acesso**, possibilitando uma governança flexível, explícita e auditável.

As permissões são avaliadas sempre no contexto de:
- um usuário específico;
- um código de sensibilidade;
- uma ação pretendida (visualizar, baixar derivado, baixar original).

O modelo adotado evita regras implícitas e exceções ocultas, garantindo que **todo acesso sensível seja resultado de autorização explícita**.

#### Princípios de Controle

- As permissões são **granulares por código de sensibilidade**, e não por documento isolado.
- A ausência de permissão explícita implica **negação de acesso**.
- O controle é **positivo** (permissões concedidas), nunca inferido.
- Toda decisão de acesso é passível de **auditoria** por meio do `log_sistema`.

Essa estrutura permite atender simultaneamente:
- usuários operacionais com acesso restrito;
- perfis de confiança elevada (diretoria, jurídico);
- cenários futuros de delegação ou revisão de permissões.

#### Observação Importante

A tabela `usuario_sensibilidade` **não armazena decisões temporárias ou contextuais**.

Ela representa **permissões explícitas por usuário**, aplicáveis como exceção/override à política geral por perfil (perfil_sensibilidade). Na ausência de regra específica de usuário, a autorização deve ser resolvida pela permissão herdada do(s) perfil(is) do usuário.”

A avaliação de acesso deve seguir a ordem definida na Seção 3.5.5.1 (negação específica → permissão específica → permissão por perfil → negar).

---

**Campos**

- `usuario_sensibilidade_id` — identificador único do vínculo de permissão (PK)  
- `usuario_sensibilidade_user_id` — usuário ao qual a permissão está associada  
  (FK para `usuario`)  
- `usuario_sensibilidade_codigo_id` — código de sensibilidade ao qual a permissão se refere  
  (FK para `sensibilidade_codigo`)  
- `usuario_pode_ver_sem_tarja` — indica se o usuário pode visualizar o conteúdo sem aplicação de tarja  
- `usuario_pode_baixar_derivado_sem_tarja` — indica se o usuário pode realizar download de versão derivada (renderizada) sem aplicação de tarja  
- `usuario_pode_baixar_original` — indica se o usuário pode realizar download do documento original  
- `usuario_sensibilidade_origem` — origem da permissão atribuída ao usuário  
  (ex.: `EXCECAO`, `TEMPORARIA`, `IMPORTADA`)  
- `usuario_sensibilidade_justificativa` — justificativa formal para concessão da permissão excepcional ou diferenciada  
- `usuario_sensibilidade_valido_ate` — data limite de validade da permissão  
  (quando aplicável; após essa data, a permissão deve ser considerada expirada)  
- `usuario_sensibilidade_ativo` — indica se o vínculo de permissão está ativo no sistema  
- `usuario_sensibilidade_datahora_criacao` — data e hora de criação do registro da permissão no sistema  
- `usuario_sensibilidade_datahora_atualizacao` — data e hora da última atualização do registro da permissão no sistema  

---

**DDL**

```sql
-- ============================================================
-- Tabela: usuario_sensibilidade
-- Objetivo: Permissões explícitas por usuário (exceção/override)
-- Regra geral: perfil_sensibilidade (por perfil)
-- Exceção/override: usuario_sensibilidade (por usuário)
-- ============================================================

CREATE TABLE IF NOT EXISTS usuario_sensibilidade (
  usuario_sensibilidade_id                 BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY, -- PK

  -- Relacionamentos
  usuario_sensibilidade_user_id            BIGINT NOT NULL,                                 -- FK usuario
  usuario_sensibilidade_codigo_id          BIGINT NOT NULL,                                 -- FK sensibilidade_codigo

  -- Permissões explícitas (override)
  usuario_pode_ver_sem_tarja               BOOLEAN NOT NULL DEFAULT FALSE,
  usuario_pode_baixar_derivado_sem_tarja   BOOLEAN NOT NULL DEFAULT FALSE,
  usuario_pode_baixar_original             BOOLEAN NOT NULL DEFAULT FALSE,

  -- Controle de estado
  usuario_sensibilidade_ativo              BOOLEAN NOT NULL DEFAULT TRUE,

  -- Auditoria mínima
  usuario_sensibilidade_datahora_criacao     TIMESTAMPTZ NOT NULL DEFAULT now(),
  usuario_sensibilidade_datahora_atualizacao TIMESTAMPTZ NOT NULL DEFAULT now(),

  -- Campos "de adulto" (auditabilidade)
  usuario_sensibilidade_origem             TEXT NOT NULL DEFAULT 'EXCECAO',                 -- EXCECAO | TEMPORARIA | IMPORTADA
  usuario_sensibilidade_justificativa      TEXT,
  usuario_sensibilidade_valido_ate         DATE
);

-- ============================================================
-- FKs
-- ============================================================

ALTER TABLE usuario_sensibilidade
  ADD CONSTRAINT fk_usuario_sensibilidade_user
  FOREIGN KEY (usuario_sensibilidade_user_id)
  REFERENCES usuario (user_id);

ALTER TABLE usuario_sensibilidade
  ADD CONSTRAINT fk_usuario_sensibilidade_codigo
  FOREIGN KEY (usuario_sensibilidade_codigo_id)
  REFERENCES sensibilidade_codigo (sensibilidade_codigo_id);

-- ============================================================
-- Unicidade (1 regra por usuário + código)
-- ============================================================

ALTER TABLE usuario_sensibilidade
  ADD CONSTRAINT uq_usuario_sensibilidade_user_codigo
  UNIQUE (usuario_sensibilidade_user_id, usuario_sensibilidade_codigo_id);

-- ============================================================
-- CHECKs normativos (sem ENUM)
-- ============================================================

ALTER TABLE usuario_sensibilidade
  ADD CONSTRAINT ck_usuario_sensibilidade_origem
  CHECK (usuario_sensibilidade_origem IN ('EXCECAO', 'TEMPORARIA', 'IMPORTADA'));

-- Se for TEMPORARIA, é altamente recomendado informar validade.
-- (CHECK permissivo para não travar operação: só força validade quando TEMPORARIA)
ALTER TABLE usuario_sensibilidade
  ADD CONSTRAINT ck_usuario_sensibilidade_temp_requer_validade
  CHECK (
    usuario_sensibilidade_origem <> 'TEMPORARIA'
    OR usuario_sensibilidade_valido_ate IS NOT NULL
  );

-- Validade não pode estar no passado no momento do cadastro? (NÃO fazer check disso no banco)
-- Banco não deve depender de "hoje" (evita dor em migrações/replicações). Regra na aplicação.

-- Coerência de privilégios (opcional, mas recomendada):
-- baixar original implica poder ver sem tarja (senão vira incoerente de política)
ALTER TABLE usuario_sensibilidade
  ADD CONSTRAINT ck_usuario_sensibilidade_coerencia_flags
  CHECK (
    (usuario_pode_baixar_original = FALSE OR usuario_pode_ver_sem_tarja = TRUE)
    AND
    (usuario_pode_baixar_derivado_sem_tarja = FALSE OR usuario_pode_ver_sem_tarja = TRUE)
  );

-- ============================================================
-- Índices
-- ============================================================

CREATE INDEX IF NOT EXISTS idx_usuario_sensibilidade_user
  ON usuario_sensibilidade (usuario_sensibilidade_user_id);

CREATE INDEX IF NOT EXISTS idx_usuario_sensibilidade_codigo
  ON usuario_sensibilidade (usuario_sensibilidade_codigo_id);

CREATE INDEX IF NOT EXISTS idx_usuario_sensibilidade_validade
  ON usuario_sensibilidade (usuario_sensibilidade_valido_ate);

-- ============================================================
-- Comentários (metadados)
-- ============================================================

COMMENT ON TABLE usuario_sensibilidade IS
'Permissões explícitas por usuário para códigos de sensibilidade. Atua como exceção/override à política geral por perfil (perfil_sensibilidade).';

COMMENT ON COLUMN usuario_sensibilidade.usuario_sensibilidade_origem IS
'Origem do override: EXCECAO (caso a caso), TEMPORARIA (com validade), IMPORTADA (migrada/integrada).';

COMMENT ON COLUMN usuario_sensibilidade.usuario_sensibilidade_justificativa IS
'Justificativa auditável para a permissão específica (ex.: demanda jurídica, auditoria, diretoria).';

COMMENT ON COLUMN usuario_sensibilidade.usuario_sensibilidade_valido_ate IS
'Data limite de validade para overrides temporários (recomendado quando origem=TEMPORARIA).';

COMMENT ON COLUMN usuario_sensibilidade.usuario_sensibilidade_ativo IS
'Indica se o vínculo de permissão está ativo no sistema.';

COMMENT ON COLUMN usuario_sensibilidade.usuario_sensibilidade_datahora_criacao IS
'Data e hora de criação do registro da permissão no sistema.';

COMMENT ON COLUMN usuario_sensibilidade.usuario_sensibilidade_datahora_atualizacao IS
'Data e hora da última atualização do registro da permissão no sistema.';
```

---

## 6.3 Seção — Documentos, Versionamento e Auditoria

### 6.3.1 Tipo de Documento (`tipo_documento`)

Classificação lógica do tipo de documento.

**Campos:**
- `tipo_documento_id` — PK (IDENTITY)  
- `tipo_documento_desc` — descrição  
- `tipo_documento_ativo` — indica se o tipo de documento está ativo no sistema  
- `tipo_documento_datahora_criacao` — data e hora de criação do registro  
- `tipo_documento_datahora_atualizacao` — data e hora da última atualização do registro  

**DDL:**
```sql
-- ============================================================
-- Tabela: tipo_documento
-- Objetivo: Classificação lógica dos tipos de documentos do sistema
-- ============================================================

CREATE TABLE IF NOT EXISTS tipo_documento (
  tipo_documento_id                   BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY, -- Identificador do tipo de documento (PK)
  tipo_documento_desc                 TEXT NOT NULL,                                   -- Descrição do tipo de documento

  -- Controle de estado
  tipo_documento_ativo                BOOLEAN NOT NULL DEFAULT TRUE,                   -- Indica se o tipo de documento está ativo

  -- Auditoria mínima
  tipo_documento_datahora_criacao     TIMESTAMPTZ NOT NULL DEFAULT now(),               -- Data/hora de criação
  tipo_documento_datahora_atualizacao TIMESTAMPTZ NOT NULL DEFAULT now()                -- Data/hora da última atualização
);

-- Comentários (metadados do banco)
COMMENT ON TABLE tipo_documento IS
'Classificação lógica dos tipos de documentos utilizados no AxysPro (nota fiscal, contrato, boleto, comprovante, relatório, etc.).';

COMMENT ON COLUMN tipo_documento.tipo_documento_id IS
'Identificador do tipo de documento (PK).';

COMMENT ON COLUMN tipo_documento.tipo_documento_desc IS
'Descrição textual do tipo de documento.';

COMMENT ON COLUMN tipo_documento.tipo_documento_ativo IS
'Indica se o tipo de documento está ativo no sistema.';

COMMENT ON COLUMN tipo_documento.tipo_documento_datahora_criacao IS
'Data e hora de criação do registro do tipo de documento.';

COMMENT ON COLUMN tipo_documento.tipo_documento_datahora_atualizacao IS
'Data e hora da última atualização do registro do tipo de documento.';
```

---

### 6.3.2 Anexo (`anexo`)

A tabela `anexo` registra os **metadados de documentos físicos** associados ao AxysPro, independentemente de sua origem (interna ou externa ao sistema).

O AxysPro **não pressupõe que os documentos sejam gerados internamente**. Contratos administrativos, documentos assinados digitalmente, certificados e demais arquivos com validade jurídica própria podem ser produzidos fora do sistema e, após seu ingresso, passam a ser **preservados, governados e auditados** pelo AxysPro.

O `anexo` representa a **entidade documental raiz**, lógica e soberana de um documento no AxysPro.

Quando o versionamento está habilitado, o conteúdo físico do arquivo e os parâmetros técnicos (hash, tamanho, criptografia e armazenamento) passam a ser tratados **por versão** em `anexo_versao`, enquanto o `anexo` permanece como âncora documental, preservando a continuidade histórica do documento.

> **Regra sistêmica:**  
> A classificação de sensibilidade (`anexo_sensivel`) é atributo do **documento raiz** (`anexo`) e se aplica a todas as suas versões, salvo política explícita definida em versionamento (caso venha a existir).

Quando um documento é marcado como sensível (`anexo_sensivel = TRUE`), aplicam-se obrigatoriamente as seguintes regras:

#### Regras Normativas de Segurança

- O arquivo físico correspondente **deve ser armazenado criptografado em disco**.
- O caminho do artefato físico e seus parâmetros técnicos residem na **versão** (`anexo_versao`); o `anexo` mantém apenas a âncora documental e a referência para a versão vigente por meio do campo `anexo_versao_atual_id`.
- O documento original **não é servido diretamente ao frontend**, independentemente do nível do usuário.
- A visualização cotidiana ocorre exclusivamente por **renderização controlada**, conforme definido na Seção 3.5.
- O acesso ao documento original, quando permitido, ocorre apenas por **rotas segregadas, auditadas e explicitamente autorizadas**, nunca por acesso direto ao arquivo.

Essas regras garantem:
- preservação da integridade do documento original;
- proteção contra acesso externo ou bypass do sistema;
- aderência a requisitos jurídicos, administrativos e de compliance;
- sustentação de longo prazo do acervo documental.

#### Observação Importante

A tabela `anexo` **não controla permissões de visualização ou acesso**.

As permissões são tratadas exclusivamente pela camada de autenticação e autorização do sistema, associadas a:
- perfis e níveis de confiança de usuários;
- códigos de sensibilidade;
- regras de negócio da aplicação.

O `anexo` atua como **registro soberano, ponto de rastreabilidade e âncora documental**, não como mecanismo isolado de segurança.

**Campos**

- `anexo_id` — identificador único do documento raiz (PK)  
- `anexo_tipo_documento_id` — tipo lógico do documento  
  (FK para `tipo_documento`)  
- `anexo_sensivel` — indica se o documento é classificado como sensível  
  (a sensibilidade se aplica a todas as versões do documento)  
- `anexo_origem_externa` — indica se o documento foi gerado fora do AxysPro
  Documentos internos devem setar explicitamente FALSE
- `anexo_assinado_digital` — indica se o documento possui assinatura digital ou validade jurídica própria  
- `anexo_versao_atual_id` — referência para a versão vigente do documento  
  (FK para `anexo_versao`)  
- `anexo_datahora_criacao` — data e hora de criação do documento raiz no sistema  
- `anexo_user_id_criacao` — usuário responsável pela criação do registro documental raiz  

---

**DDL**

```sql
-- ============================================================
-- Tabela: anexo
-- Objetivo: Entidade documental raiz (lógica) do AxysPro
-- Observação: Metadados físicos e parâmetros técnicos residem em anexo_versao
--
-- IMPORTANTE (DDL):
-- Existe dependência cíclica entre:
--   - anexo.anexo_versao_atual_id  -> anexo_versao.anexo_versao_id
--   - anexo_versao.anexo_id        -> anexo.anexo_id
--
-- Por isso, a FK fk_anexo_versao_atual NÃO deve ser criada neste primeiro bloco.
-- Ela deve ser adicionada depois que a tabela anexo_versao existir (via ALTER TABLE).
-- ============================================================

CREATE TABLE IF NOT EXISTS anexo (
  anexo_id                  BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

  -- Tipificação documental
  anexo_tipo_documento_id   BIGINT NOT NULL,

  -- Classificações globais do documento
  anexo_sensivel            BOOLEAN NOT NULL DEFAULT FALSE,
  anexo_origem_externa      BOOLEAN NOT NULL DEFAULT TRUE,
  anexo_assinado_digital    BOOLEAN NOT NULL DEFAULT FALSE,

  -- Versionamento
  anexo_versao_atual_id     BIGINT,

  -- Auditoria de criação do documento raiz
  anexo_datahora_criacao    TIMESTAMPTZ NOT NULL DEFAULT now(),
  anexo_user_id_criacao     BIGINT NOT NULL,

  CONSTRAINT fk_anexo_tipo_documento
    FOREIGN KEY (anexo_tipo_documento_id)
    REFERENCES tipo_documento (tipo_documento_id),

  -- >>>>>> FK fk_anexo_versao_atual SERÁ CRIADA DEPOIS (ALTER TABLE)
  -- CONSTRAINT fk_anexo_versao_atual
  --   FOREIGN KEY (anexo_versao_atual_id)
  --   REFERENCES anexo_versao (anexo_versao_id),

  CONSTRAINT fk_anexo_user_criacao
    FOREIGN KEY (anexo_user_id_criacao)
    REFERENCES usuario (user_id)
);

CREATE INDEX IF NOT EXISTS idx_anexo_tipo_documento
  ON anexo (anexo_tipo_documento_id);

CREATE INDEX IF NOT EXISTS idx_anexo_sensivel
  ON anexo (anexo_sensivel);

CREATE INDEX IF NOT EXISTS idx_anexo_versao_atual
  ON anexo (anexo_versao_atual_id);

COMMENT ON TABLE anexo IS
'Entidade documental raiz do AxysPro. Representa o documento lógico, contínuo no tempo, cujo conteúdo físico é versionado em anexo_versao.';

COMMENT ON COLUMN anexo.anexo_sensivel IS
'Classificação de sensibilidade do documento raiz; aplica-se a todas as versões.';

COMMENT ON COLUMN anexo.anexo_versao_atual_id IS
'Referência para a versão vigente do documento, utilizada para leitura e renderização padrão.';
```

---

### 6.3.3 Versão de Documento (`anexo_versao`)

A tabela `anexo_versao` registra as **versões físicas e técnicas** de um documento armazenado no AxysPro.

Enquanto o `anexo` representa a **entidade documental raiz**, lógica e contínua no tempo, o `anexo_versao` representa **cada instância concreta do arquivo**, incluindo seu conteúdo físico, parâmetros de criptografia, integridade e auditoria de ingresso.

Cada nova submissão, substituição formal, correção ou reapresentação de um documento **gera obrigatoriamente um novo registro em `anexo_versao`**, sem sobrescrever versões anteriores.

Essa separação garante:

- preservação integral de versões históricas;
- rastreabilidade jurídica e administrativa;
- integridade técnica do acervo documental;
- suporte a auditorias, perícias e exigências legais de longo prazo;
- clareza absoluta entre documento lógico e arquivo físico.

O acesso cotidiano e a renderização padrão devem utilizar a **versão vigente**, apontada pelo campo `anexo.anexo_versao_atual_id`, salvo quando explicitamente solicitado acesso a versões históricas.

---

#### Princípios Normativos de Versionamento

- Nenhuma versão é apagada, sobrescrita ou alterada após seu registro.
- Cada versão possui identidade própria, hash próprio e parâmetros de segurança independentes.
- O versionamento é **sempre explícito**, nunca implícito.
- Logs de acesso devem registrar **qual versão** foi visualizada, renderizada ou baixada.
- A existência de múltiplas versões **não altera** a política de sensibilidade do documento raiz.

---

**Campos**

- `anexo_versao_id` — identificador único da versão do documento (PK)  
- `anexo_id` — documento raiz ao qual a versão pertence  
  (FK para `anexo`)  
- `anexo_versao_num` — número sequencial da versão do documento  
  (incremental, controlado pela aplicação)  
- `anexo_versao_nome_original` — nome original do arquivo no momento do upload da versão  
- `anexo_versao_mime` — MIME type do arquivo da versão  
  (ex.: `application/pdf`)  
- `anexo_versao_tamanho_bytes` — tamanho do arquivo da versão em bytes  
- `anexo_versao_hash_sha256` — hash SHA-256 do arquivo da versão  
  (verificação de integridade e unicidade técnica)  
- `anexo_versao_caminho` — caminho físico ou lógico do artefato armazenado  
  (não legível externamente ao sistema)  
- `anexo_versao_criptografado` — indica se o arquivo da versão está criptografado em disco  
- `anexo_versao_enc_alg` — algoritmo de criptografia utilizado  
  (ex.: `AES-256-GCM`)  
- `anexo_versao_enc_key_id` — identificador lógico da chave de criptografia  
  (nunca a chave em si)  
- `anexo_versao_enc_nonce` — nonce/IV utilizado na criptografia (quando aplicável)  
- `anexo_versao_enc_tag` — authentication tag (GCM), quando aplicável  
- `anexo_versao_datahora_cadastro` — data e hora de ingresso da versão no sistema  
- `anexo_versao_user_id_upload` — usuário responsável pelo upload da versão  
- `anexo_versao_observacao` — observações livres sobre a versão  
  (ex.: correção, reapresentação, substituição formal)

---

**DDL**

```sql
-- ============================================================
-- Tabela: anexo_versao
-- Objetivo: Armazenar versões físicas e técnicas de documentos do AxysPro
-- Observação: Cada registro representa uma versão imutável do arquivo
-- ============================================================

CREATE TABLE IF NOT EXISTS anexo_versao (
  anexo_versao_id               BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

  -- Relacionamento com documento raiz
  anexo_id                      BIGINT NOT NULL,

  -- Controle de versionamento
  anexo_versao_num              INTEGER NOT NULL,

  -- Metadados do arquivo
  anexo_versao_nome_original    TEXT,
  anexo_versao_mime             TEXT,
  anexo_versao_tamanho_bytes    BIGINT,
  anexo_versao_hash_sha256      TEXT NOT NULL,

  -- Armazenamento físico
  anexo_versao_caminho          TEXT NOT NULL,

  -- Criptografia em repouso
  anexo_versao_criptografado    BOOLEAN NOT NULL DEFAULT FALSE,
  anexo_versao_enc_alg          TEXT,
  anexo_versao_enc_key_id       TEXT,
  anexo_versao_enc_nonce        BYTEA,
  anexo_versao_enc_tag          BYTEA,

  -- Auditoria de ingresso
  anexo_versao_datahora_cadastro  TIMESTAMPTZ NOT NULL DEFAULT now(),
  anexo_versao_user_id_upload   BIGINT NOT NULL,

  -- Observações livres
  anexo_versao_observacao       TEXT,

  CONSTRAINT fk_anexo_versao_anexo
    FOREIGN KEY (anexo_id)
    REFERENCES anexo (anexo_id)
    ON DELETE CASCADE,

  CONSTRAINT fk_anexo_versao_user
    FOREIGN KEY (anexo_versao_user_id_upload)
    REFERENCES usuario (user_id),

  CONSTRAINT uq_anexo_versao_num
    UNIQUE (anexo_id, anexo_versao_num)
);

CREATE INDEX IF NOT EXISTS idx_anexo_versao_anexo
  ON anexo_versao (anexo_id);

CREATE INDEX IF NOT EXISTS idx_anexo_versao_hash
  ON anexo_versao (anexo_versao_hash_sha256);

CREATE INDEX IF NOT EXISTS idx_anexo_versao_data
  ON anexo_versao (anexo_versao_datahora_cadastro);

COMMENT ON TABLE anexo_versao IS
'Versões físicas e técnicas de documentos do AxysPro. Cada registro representa uma versão imutável do arquivo.';

COMMENT ON COLUMN anexo_versao.anexo_versao_hash_sha256 IS
'Hash SHA-256 do arquivo da versão, utilizado para integridade e verificação futura.';


-- ============================================================
-- FECHAMENTO DO CICLO (dependência cíclica)
-- Agora que anexo_versao existe, criamos a FK do anexo -> anexo_versao
-- ============================================================

ALTER TABLE anexo
  ADD CONSTRAINT fk_anexo_versao_atual
  FOREIGN KEY (anexo_versao_atual_id)
  REFERENCES anexo_versao (anexo_versao_id)
  ON DELETE SET NULL;

```



### 6.3.4 Log de Acesso a Documentos (`log_documento_acesso`)

A tabela `log_documento_acesso` é responsável por registrar, de forma **granular, explícita, determinística e auditável**, **todas as tentativas e eventos de acesso** a documentos armazenados no AxysPro, incluindo **visualização, renderização e download**, independentemente do resultado final da operação.

Ela **complementa** o `log_sistema`, atuando de forma **especializada no domínio documental**, onde o nível de criticidade, risco jurídico e exigência de rastreabilidade são substancialmente maiores.

Enquanto o `log_sistema` registra **eventos operacionais e sistêmicos genéricos**, o `log_documento_acesso` registra **eventos diretamente relacionados ao acesso ao conteúdo documental**, permitindo:

- comprovação inequívoca de quem **tentou acessar** determinado documento;
- identificação clara de **como o acesso foi solicitado** (visualização, renderização, download derivado ou original);
- distinção entre **tentativa de acesso** e **entrega efetiva de conteúdo**;
- diferenciação entre acesso **renderizado** e acesso ao **documento original**;
- rastreabilidade jurídica, administrativa e técnica;
- suporte robusto a auditorias, perícias, compliance e requisitos de LGPD.

Essa tabela é **obrigatória** para todo documento armazenado no AxysPro que possua qualquer forma de acesso controlado, não existindo acesso documental válido fora desse mecanismo.

Eventos registrados em `log_documento_acesso` devem **gerar registro correlato no `log_sistema`**, por meio de mecanismo de correlação lógica (ex.: `log_sistema_id` ou metadado equivalente), permitindo auditoria cruzada entre o evento documental e a ação sistêmica correspondente.

---

#### Princípios Normativos

O `log_documento_acesso` segue os seguintes princípios obrigatórios:

1. **Toda tentativa de acesso a documento gera log**, independentemente do perfil, nível de permissão ou resultado.
2. Não existe acesso, tentativa ou falha de acesso **silenciosa** a documentos no sistema.
3. A auditoria é **documento-cêntrica**, não apenas ação-cêntrica.
4. A existência de permissão **não elimina a necessidade de registro**.
5. O log registra explicitamente **tentativa e resultado** do acesso (`OK`, `DENY`, `ERROR`).
6. Logs de acesso **não são apagados**, podendo apenas ser arquivados futuramente conforme política de retenção (retenção e arquivamento são políticas futuras; o padrão é preservação).

---

#### Escopo de Registro

Devem obrigatoriamente gerar registros em `log_documento_acesso`:

- visualização renderizada em tela (modal, página, preview);
- geração de representação derivada (ex.: PDF gerado a partir de renderização em imagem);
- download de versão derivada (com ou sem tarja);
- download do documento original;
- tentativas de acesso negadas por política de segurança ou permissões;
- acessos realizados por rotinas automáticas, exportações, integrações internas ou APIs.

---

#### Integração com a Política de Segurança

O `log_documento_acesso` atua de forma integrada com:

- a tabela `anexo` (documento raiz);
- a tabela `anexo_versao` (versão física efetivamente acessada);
- a política de renderização controlada (Seção 3.5);
- o `log_sistema` (registro macro da ação);
- o sistema de permissões, perfis e níveis de confiança do usuário.

Quando houver **entrega efetiva de conteúdo** ao usuário — seja por visualização renderizada, geração de versão derivada ou download do documento original — o evento **deve registrar explicitamente a versão efetivamente servida do documento**, por meio do identificador `anexo_versao_id`.

> **Regra sistêmica:**  
> Nenhuma tentativa ou evento de acesso a documento é considerado válido no AxysPro se não gerar registro correspondente em `log_documento_acesso`.

---

#### Campos

- `log_documento_acesso_id` — identificador único do evento de acesso (PK)
- `log_documento_acesso_anexo_id` — documento raiz ao qual o acesso se refere (FK para `anexo`)
- `log_documento_acesso_anexo_versao_id` — versão do documento efetivamente acessada ou servida, quando aplicável (FK para `anexo_versao`)
- `log_documento_acesso_user_id` — usuário responsável pela tentativa de acesso (FK para `usuario`)
- `log_documento_acao` — tipo de ação documental realizada (`VISUALIZACAO`, `RENDERIZACAO`, `DOWNLOAD_DERIVADO`, `DOWNLOAD_ORIGINAL`)
- `log_documento_origem` — origem técnica do acesso (`TELA`, `MODAL`, `ROTINA`, `EXPORTACAO`, `API`)
- `log_documento_paginas` — páginas do documento acessadas ou renderizadas (ex.: `1`, `2,3`, `5-7`)
- `log_documento_resultado` — resultado do acesso (`OK`, `DENY`, `ERROR`)
- `log_documento_renderizado` — indica se o acesso ocorreu por renderização controlada
- `log_documento_com_tarja` — indica se houve aplicação de tarjas de sensibilidade
- `log_documento_marca_dagua` — indica se foi aplicada marca d’água
- `log_documento_datahora` — data e hora do evento de acesso
- `log_documento_observacao` — observações livres ou justificativas (opcional)
- `log_sistema_id` — identificador lógico de correlação com o `log_sistema` (sem obrigatoriedade de FK)

**Regra de Formato — Campo Páginas do Documento**

O campo de páginas do documento segue **formato textual padronizado**, permitindo representação simples, múltipla ou por intervalo.

**Formatos válidos:**
- Página única: `1`
- Lista de páginas: `2,3,5`
- Intervalo contínuo: `5-7`
- Combinação de formatos: `1,3-5,8`

**Regras normativas:**
- Páginas são sempre representadas por números inteiros positivos
- Intervalos usam hífen (`-`) sem espaços
- Listas usam vírgula (`,`) sem espaços
- A ordem deve ser crescente
- Não são permitidas sobreposições redundantes (ex.: `3,3-5`)

**Observação técnica:**
A validação de sintaxe e coerência ocorre na **camada de aplicação**.  
O banco de dados armazena apenas o valor textual informado, preservando flexibilidade e compatibilidade futura.


---

**DDL**

```sql
-- ============================================================
-- Tabela: log_documento_acesso
-- Objetivo: Auditoria específica de acesso, visualização e download de documentos
-- Observação: Complementa o log_sistema com granularidade documental
-- Estratégia: TEXT + CHECK (sem ENUM) + checks de coerência
-- ============================================================

CREATE TABLE IF NOT EXISTS log_documento_acesso (
  log_documento_acesso_id             BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

  -- Relacionamentos principais
  log_documento_acesso_anexo_id       BIGINT NOT NULL,
  log_documento_acesso_anexo_versao_id BIGINT,          -- versão efetivamente acessada/servida (quando aplicável)
  log_documento_acesso_user_id        BIGINT NOT NULL,

  -- Correlação com log_sistema (sem FK por robustez de auditoria)
  log_sistema_id                      BIGINT,

  -- Contexto do acesso (valores controlados por CHECK)
  log_documento_acao                  TEXT NOT NULL,
  log_documento_origem                TEXT NOT NULL,
  log_documento_paginas               TEXT,

  -- Resultado do acesso (importante juridicamente)
  log_documento_resultado             TEXT NOT NULL DEFAULT 'OK',  -- OK | DENY | ERROR
  log_documento_motivo                TEXT,                        -- motivo de negação/erro (opcional)

  -- Segurança e renderização (defaults conservadores: FALSE)
  log_documento_renderizado           BOOLEAN NOT NULL DEFAULT FALSE,
  log_documento_com_tarja             BOOLEAN NOT NULL DEFAULT FALSE,
  log_documento_marca_dagua           BOOLEAN NOT NULL DEFAULT FALSE,

  -- Auditoria temporal
  log_documento_datahora              TIMESTAMPTZ NOT NULL DEFAULT now(),

  -- Observações livres
  log_documento_observacao            TEXT
);

-- ============================================================
-- CHECKs normativos (valores permitidos) — sem ENUM
-- ============================================================

ALTER TABLE log_documento_acesso
  ADD CONSTRAINT ck_log_documento_acao
  CHECK (log_documento_acao IN (
    'VISUALIZACAO',
    'RENDERIZACAO',
    'DOWNLOAD_DERIVADO',
    'DOWNLOAD_ORIGINAL'
  ));

ALTER TABLE log_documento_acesso
  ADD CONSTRAINT ck_log_documento_origem
  CHECK (log_documento_origem IN (
    'TELA',
    'MODAL',
    'ROTINA',
    'EXPORTACAO',
    'API'
  ));

ALTER TABLE log_documento_acesso
  ADD CONSTRAINT ck_log_documento_resultado
  CHECK (log_documento_resultado IN (
    'OK',
    'DENY',
    'ERROR'
  ));

-- ============================================================
-- CHECKs de coerência
-- ============================================================

-- 1) DOWNLOAD_ORIGINAL não pode declarar render/tarja (representação derivada)
ALTER TABLE log_documento_acesso
  ADD CONSTRAINT ck_log_documento_coerencia_original
  CHECK (
    NOT (
      log_documento_acao = 'DOWNLOAD_ORIGINAL'
      AND (log_documento_renderizado = TRUE OR log_documento_com_tarja = TRUE OR log_documento_marca_dagua = TRUE)
    )
  );

-- 2) Se tem tarja, necessariamente é renderizado (tarja só existe na representação)
ALTER TABLE log_documento_acesso
  ADD CONSTRAINT ck_log_documento_coerencia_tarja
  CHECK (
    NOT (log_documento_com_tarja = TRUE AND log_documento_renderizado = FALSE)
  );

-- 3) Se resultado != OK, não faz sentido afirmar render/tarja/marca d'água como entrega efetiva
ALTER TABLE log_documento_acesso
  ADD CONSTRAINT ck_log_documento_coerencia_resultado
  CHECK (
    NOT (
      log_documento_resultado IN ('DENY','ERROR')
      AND (log_documento_renderizado = TRUE OR log_documento_com_tarja = TRUE OR log_documento_marca_dagua = TRUE)
    )
  );

-- (Opcional) 4) Se for download do original, páginas deveria ser NULL
-- ALTER TABLE log_documento_acesso
--   ADD CONSTRAINT ck_log_documento_paginas_original
--   CHECK (NOT (log_documento_acao = 'DOWNLOAD_ORIGINAL' AND log_documento_paginas IS NOT NULL));

-- ============================================================
-- FKs (anexo / versão / usuário)
-- ============================================================

ALTER TABLE log_documento_acesso
  ADD CONSTRAINT fk_log_documento_acesso_anexo
  FOREIGN KEY (log_documento_acesso_anexo_id)
  REFERENCES anexo (anexo_id);

ALTER TABLE log_documento_acesso
  ADD CONSTRAINT fk_log_documento_acesso_anexo_versao
  FOREIGN KEY (log_documento_acesso_anexo_versao_id)
  REFERENCES anexo_versao (anexo_versao_id);

ALTER TABLE log_documento_acesso
  ADD CONSTRAINT fk_log_documento_acesso_user
  FOREIGN KEY (log_documento_acesso_user_id)
  REFERENCES usuario (user_id);

-- ============================================================
-- Índices (auditoria e consulta rápida)
-- ============================================================

CREATE INDEX IF NOT EXISTS idx_log_documento_acesso_anexo
  ON log_documento_acesso (log_documento_acesso_anexo_id);

CREATE INDEX IF NOT EXISTS idx_log_documento_acesso_versao
  ON log_documento_acesso (log_documento_acesso_anexo_versao_id);

CREATE INDEX IF NOT EXISTS idx_log_documento_acesso_user
  ON log_documento_acesso (log_documento_acesso_user_id);

CREATE INDEX IF NOT EXISTS idx_log_documento_acesso_data
  ON log_documento_acesso (log_documento_datahora DESC);

CREATE INDEX IF NOT EXISTS idx_log_documento_acesso_anexo_data
  ON log_documento_acesso (log_documento_acesso_anexo_id, log_documento_datahora DESC);

-- ============================================================
-- Comentários (metadados do banco)
-- ============================================================

COMMENT ON TABLE log_documento_acesso IS
'Auditoria específica de acesso, visualização, renderização e download de documentos no AxysPro. Registra tentativas e resultados (OK/DENY/ERROR) e referencia a versão efetivamente servida quando aplicável.';

COMMENT ON COLUMN log_documento_acesso.log_sistema_id IS
'Identificador de correlação com log_sistema (sem FK por robustez de auditoria).';

COMMENT ON COLUMN log_documento_acesso.log_documento_resultado IS
'Resultado do acesso: OK (entregue), DENY (negado), ERROR (falha técnica).';

COMMENT ON COLUMN log_documento_acesso.log_documento_acesso_anexo_versao_id IS
'Versão efetivamente acessada/servida (quando aplicável).';
```

### 6.3.5 Log do Sistema (`log_sistema`)

O **Log do Sistema** é um componente **transversal, obrigatório e estratégico** do AxysPro.  
Ele não pertence a um módulo específico e está presente em **todo o ecossistema**, sendo responsável por registrar **eventos operacionais, decisórios e documentais**, e não apenas erros técnicos.

Diferentemente de logs de aplicação (debug, erro, stacktrace), o `log_sistema` tem como finalidade:

- rastreabilidade completa das ações realizadas no sistema  
- auditoria de alterações, acessos e decisões operacionais  
- governança e controle interno  
- análise de comportamento e uso por usuário  
- suporte a processos jurídicos, administrativos e de compliance  
- geração futura de métricas de dedicação por serviço, módulo e usuário  
- apoio à tomada de decisão e à evolução controlada do sistema  

No AxysPro, **toda ação que gere efeito persistente, impacto decisório ou acesso sensível deve obrigatoriamente gerar um registro de log**.

---

#### Princípios de Projeto

A modelagem do `log_sistema` segue os seguintes princípios:

1. O log é **único para todo o sistema**
2. O log é **independente de módulo**
3. O log **não armazena regras de negócio**, apenas eventos ocorridos
4. O log **não deve ser apagado** (no máximo arquivado futuramente)
5. O log deve ser **rico em contexto**, mesmo que nem todos os campos sejam utilizados em todos os eventos
6. O log deve ser **extensível sem refatoração estrutural**

Essa abordagem garante **evolução contínua**, aderência a auditorias e sustentação de longo prazo.

---

#### Regras Obrigatórias de Logging

Devem gerar registro no `log_sistema`, no mínimo:

- inserções de dados (INSERT)
- alterações de dados (UPDATE)
- exclusões lógicas
- vinculações e desvinculações entre entidades
- aprovações, reprovações e cancelamentos
- operações automáticas relevantes (rotinas, importações, processamentos em lote)
- visualização de documentos sensíveis (VIEW_DOC / RENDER_DOC)
- downloads de documentos, sejam eles derivados ou originais

Toda ação relevante deve estar associada, de forma explícita, a:

- um usuário
- um módulo
- uma funcionalidade
- uma ação claramente identificável
- um contexto técnico mínimo de rastreabilidade

---

#### Estrutura Conceitual do Log

A tabela `log_sistema` foi projetada para registrar:

- **quem** executou a ação  
- **o que** foi executado  
- **onde** ocorreu (módulo e funcionalidade)  
- **quando** ocorreu  
- **qual foi o impacto ou contexto do evento**  

Além dos campos tradicionais, o log admite o uso de **metadados estruturados**, permitindo o registro de informações adicionais como:

- páginas acessadas em documentos  
- tipo de visualização ou entrega (renderização, download derivado, download original)  
- aplicação de tarjas ou watermark  
- identificadores técnicos do documento  
- IP, user-agent e justificativas operacionais  

Essa flexibilidade permite que o `log_sistema` sustente cenários futuros **sem necessidade de alterações estruturais**.

**Campos**

- `log_sistema_id` — identificador único do log  
- `log_user_id` — usuário responsável pela ação  
- `log_modulo` — módulo de origem da ação (ex.: SysCost)  
- `log_funcionalidade` — funcionalidade ou contexto da ação  
- `log_acao` — tipo de ação realizada (INSERT, UPDATE, DELETE, RATEIO, APROVACAO, VIEW_DOC, DOWNLOAD, etc.)  
- `log_tabela_afetada` — tabela impactada (quando aplicável)  
- `log_registro_id` — identificador do registro afetado (quando aplicável)  
- `log_valor_anterior` — estado anterior dos dados (JSON, opcional)  
- `log_valor_novo` — estado posterior dos dados (JSON, opcional)  
- `log_meta` — metadados estruturados do evento (JSON, opcional; ex.: páginas acessadas, modo de entrega, flags de tarja/watermark, IP, user-agent, etc.)  
- `log_datahora` — data e hora da ação (timezone-aware)  
- `log_origem` — origem técnica da ação (tela, rotina automática, importação, script)  
- `log_observacao` — observações livres  

---

**DDL**

```sql
-- ============================================================
-- Tabela: log_sistema
-- Objetivo: Registro transversal de eventos operacionais e documentais
-- Observação: Tabela única para todo o AxysPro (não pertence a módulo específico)
-- ============================================================

CREATE TABLE IF NOT EXISTS log_sistema (
  log_sistema_id      BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

  -- Quem executou a ação
  log_user_id         BIGINT NOT NULL,

  -- Onde / contexto funcional
  log_modulo          TEXT NOT NULL,
  log_funcionalidade  TEXT NOT NULL,
  log_acao            TEXT NOT NULL,

  -- O que foi afetado
  log_tabela_afetada  TEXT,
  log_registro_id     BIGINT,

  -- Estado dos dados (quando aplicável)
  log_valor_anterior  JSONB,
  log_valor_novo      JSONB,

  -- Metadados adicionais do evento
  log_meta            JSONB,

  -- Quando
  log_datahora        TIMESTAMPTZ NOT NULL DEFAULT now(),

  -- Origem técnica
  log_origem          TEXT,
  log_observacao      TEXT
);


CREATE INDEX IF NOT EXISTS idx_log_sistema_user_data
  ON log_sistema (log_user_id, log_datahora DESC);

CREATE INDEX IF NOT EXISTS idx_log_sistema_modulo_data
  ON log_sistema (log_modulo, log_datahora DESC);

COMMENT ON TABLE log_sistema IS
'Registro transversal e auditável de eventos operacionais, decisórios e documentais do AxysPro.';
```

---


### 6.4 Seção — Estrutura Gerencial e Financeira

### 6.4.1 Centro de Custo (`centro_custo`)

Representa a origem gerencial de custos (loja, obra, projeto, unidade).

**Campos:**
- `centro_custo_id` — PK (IDENTITY)  
- `centro_custo_desc` — descrição  
- `centro_custo_ativo` — indica se o centro de custo está ativo no sistema  
- `centro_custo_datahora_criacao` — data e hora de criação do registro  
- `centro_custo_datahora_atualizacao` — data e hora da última atualização do registro  

**DDL:**
```sql
-- ============================================================
-- Tabela: centro_custo
-- Objetivo: Cadastro de centros de custo para classificação gerencial
-- ============================================================

CREATE TABLE IF NOT EXISTS centro_custo (
  centro_custo_id                   BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY, -- Identificador do centro de custo (PK)
  centro_custo_desc                 TEXT NOT NULL,                                   -- Descrição do centro de custo

  -- Controle de estado
  centro_custo_ativo                BOOLEAN NOT NULL DEFAULT TRUE,                   -- Indica se o centro de custo está ativo

  -- Auditoria mínima
  centro_custo_datahora_criacao     TIMESTAMPTZ NOT NULL DEFAULT now(),               -- Data/hora de criação
  centro_custo_datahora_atualizacao TIMESTAMPTZ NOT NULL DEFAULT now()                -- Data/hora da última atualização
);

-- Comentários (metadados do banco)
COMMENT ON TABLE centro_custo IS
'Cadastro de centros de custo utilizados para classificação e leitura gerencial (loja, obra, projeto, unidade).';

COMMENT ON COLUMN centro_custo.centro_custo_id IS
'Identificador do centro de custo (PK).';

COMMENT ON COLUMN centro_custo.centro_custo_desc IS
'Descrição do centro de custo.';

COMMENT ON COLUMN centro_custo.centro_custo_ativo IS
'Indica se o centro de custo está ativo (true) ou inativo (false).';

COMMENT ON COLUMN centro_custo.centro_custo_datahora_criacao IS
'Data e hora de criação do registro do centro de custo.';

COMMENT ON COLUMN centro_custo.centro_custo_datahora_atualizacao IS
'Data e hora da última atualização do registro do centro de custo.';
```

---

### 6.4.2 Plano de Contas (`plano_conta`)

conta MAE para leitura gerencial e consolidação (DRE, custos, resultados).

**Campos:**
- `plano_conta_id` — PK (IDENTITY)  
- `plano_conta_desc` — descrição  
- `plano_conta_ativo` — indica se o plano de contas está ativo no sistema  
- `plano_conta_datahora_criacao` — data e hora de criação do registro  
- `plano_conta_datahora_atualizacao` — data e hora da última atualização do registro  

**DDL:**
```sql
-- ============================================================
-- Tabela: plano_conta
-- Objetivo: Plano de contas em nível macro para consolidação gerencial
-- ============================================================

CREATE TABLE IF NOT EXISTS plano_conta (
  plano_conta_id                   BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY, -- Identificador do plano de contas (PK)
  plano_conta_desc                 TEXT NOT NULL,                                   -- Descrição da conta mãe

  -- Controle de estado
  plano_conta_ativo                BOOLEAN NOT NULL DEFAULT TRUE,                   -- Indica se a conta está ativa

  -- Auditoria mínima
  plano_conta_datahora_criacao     TIMESTAMPTZ NOT NULL DEFAULT now(),               -- Data/hora de criação
  plano_conta_datahora_atualizacao TIMESTAMPTZ NOT NULL DEFAULT now()                -- Data/hora da última atualização
);

-- Comentários (metadados do banco)
COMMENT ON TABLE plano_conta IS
'Plano de contas em nível macro (conta mãe) para leitura e consolidação gerencial.';

COMMENT ON COLUMN plano_conta.plano_conta_id IS
'Identificador do plano de contas (PK).';

COMMENT ON COLUMN plano_conta.plano_conta_desc IS
'Descrição da conta mãe.';

COMMENT ON COLUMN plano_conta.plano_conta_ativo IS
'Indica se o plano de contas está ativo (true) ou inativo (false).';

COMMENT ON COLUMN plano_conta.plano_conta_datahora_criacao IS
'Data e hora de criação do registro do plano de contas.';

COMMENT ON COLUMN plano_conta.plano_conta_datahora_atualizacao IS
'Data e hora da última atualização do registro do plano de contas.';
```

---

### 6.4.3 Sub Plano de Contas (`sub_plano_conta`)

Conta lançável subordinada ao plano de contas mãe.

**Campos:**
- `sub_plano_conta_id` — PK (IDENTITY)  
- `sub_plano_conta_plano_conta_id` — FK para `plano_conta`  
- `sub_plano_conta_desc` — descrição  
- `sub_plano_conta_ativo` — indica se a subconta está ativa no sistema  
- `sub_plano_conta_datahora_criacao` — data e hora de criação do registro  
- `sub_plano_conta_datahora_atualizacao` — data e hora da última atualização do registro  

**DDL:**
```sql
-- ============================================================
-- Tabela: sub_plano_conta
-- Objetivo: Contas lançáveis vinculadas a um plano de contas mãe
-- ============================================================

CREATE TABLE IF NOT EXISTS sub_plano_conta (
  sub_plano_conta_id                   BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY, -- Identificador da subconta (PK)
  sub_plano_conta_plano_conta_id       BIGINT NOT NULL,                                 -- Plano de contas mae (FK)
  sub_plano_conta_desc                 TEXT NOT NULL,                                   -- Descrição da subconta
  sub_plano_conta_ativo                BOOLEAN NOT NULL DEFAULT TRUE,                   -- Indica se a subconta está ativa

  -- Auditoria mínima
  sub_plano_conta_datahora_criacao     TIMESTAMPTZ NOT NULL DEFAULT now(),               -- Data/hora de criação
  sub_plano_conta_datahora_atualizacao TIMESTAMPTZ NOT NULL DEFAULT now()                -- Data/hora da última atualização
);

ALTER TABLE sub_plano_conta
  ADD CONSTRAINT fk_sub_plano_conta_plano_conta
  FOREIGN KEY (sub_plano_conta_plano_conta_id)
  REFERENCES plano_conta (plano_conta_id);

-- Comentários (metadados do banco)
COMMENT ON TABLE sub_plano_conta IS
'Subplanos de contas (contas lançáveis) vinculados a um plano de contas mae.';

COMMENT ON COLUMN sub_plano_conta.sub_plano_conta_id IS
'Identificador da subconta (PK).';

COMMENT ON COLUMN sub_plano_conta.sub_plano_conta_plano_conta_id IS
'Plano de contas mae ao qual a subconta está vinculada.';

COMMENT ON COLUMN sub_plano_conta.sub_plano_conta_desc IS
'Descrição da subconta lançável.';

COMMENT ON COLUMN sub_plano_conta.sub_plano_conta_ativo IS
'Indica se a subconta está ativa (true) ou inativa (false).';

COMMENT ON COLUMN sub_plano_conta.sub_plano_conta_datahora_criacao IS
'Data e hora de criação do registro da subconta.';

COMMENT ON COLUMN sub_plano_conta.sub_plano_conta_datahora_atualizacao IS
'Data e hora da última atualização do registro da subconta.';

COMMENT ON CONSTRAINT fk_sub_plano_conta_plano_conta ON sub_plano_conta
  IS 'Vincula a subconta ao respectivo plano de contas mae.';
```

---

### 6.4.4 Despesa (`despesa`)

Entidade **macro** do lançamento. A despesa registra o **contexto gerencial** (centro de custo, subconta, competência, pessoa, documento principal etc.).  
O pagamento em si ocorre por **parcelas**, registradas em `parcela_despesa`.

> Regra de consistência: `despesa_valor` representa o **total somado das parcelas** (fonte gerencial).  
> A aplicação deve manter esse total consistente com a soma de `parcela_despesa.parcela_despesa_valor`.

**Campos:**
- `despesa_id` — PK (IDENTITY)  
- `despesa_n_doc` — número do documento (nota, contrato, referência)  
- `despesa_descricao` — descrição  
- `despesa_valor` — valor total (**soma das parcelas**)  
- `despesa_competencia` — competência (YYYY-MM)  
- `despesa_data_emissao` — data de emissão  
- `despesa_centro_custo_id` — FK (centro de custo de origem)  
- `despesa_sub_plano_conta_id` — FK (subconta lançável)  
- `despesa_pessoa_id` — FK (opcional)  
- `despesa_status` — `LANCADA` / `PAGA` / `PAGA_PARCIAL` / `CANCELADA`  
- `despesa_anexo_id` — FK (opcional; documento principal)  
- `despesa_datahora_criacao` — data e hora de criação do registro  
- `despesa_datahora_atualizacao` — data e hora da última atualização do registro  

**Status de despesa**
Os valores válidos de status são controlados pela aplicação, não por ENUM no banco, para permitir evolução sem migração.

**DDL:**
```sql
-- ============================================================
-- Tabela: despesa
-- Objetivo: Entidade macro do lançamento, com contexto gerencial
-- Regra: despesa_valor deve representar a soma das parcelas vinculadas
-- ============================================================

CREATE TABLE IF NOT EXISTS despesa (
  despesa_id                   BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY, -- Identificador da despesa (PK)
  despesa_n_doc                TEXT,                                            -- Número do documento (referência: nota/contrato/etc.)
  despesa_descricao            TEXT NOT NULL,                                   -- Descrição da despesa
  despesa_valor                NUMERIC(14,2) NOT NULL,                          -- Valor total (soma das parcelas)
  despesa_competencia          TEXT NOT NULL,                                   -- Competência no formato YYYY-MM
  despesa_data_emissao         DATE NOT NULL,                                   -- Data de emissão
  despesa_centro_custo_id      BIGINT NOT NULL,                                 -- Centro de custo de origem (FK)
  despesa_sub_plano_conta_id   BIGINT NOT NULL,                                 -- Subplano de contas lançável (FK)
  despesa_pessoa_id            BIGINT,                                          -- Pessoa relacionada (opcional, FK)
  despesa_status               TEXT NOT NULL,                                   -- LANCADA / PAGA / PAGA_PARCIAL / CANCELADA
  despesa_anexo_id             BIGINT,                                          -- Documento principal (opcional, FK)

  -- Auditoria mínima
  despesa_datahora_criacao     TIMESTAMPTZ NOT NULL DEFAULT now(),               -- Data/hora de criação
  despesa_datahora_atualizacao TIMESTAMPTZ NOT NULL DEFAULT now()                -- Data/hora da última atualização
);

ALTER TABLE despesa
  ADD CONSTRAINT fk_despesa_centro_custo
  FOREIGN KEY (despesa_centro_custo_id)
  REFERENCES centro_custo (centro_custo_id);

ALTER TABLE despesa
  ADD CONSTRAINT fk_despesa_sub_plano_conta
  FOREIGN KEY (despesa_sub_plano_conta_id)
  REFERENCES sub_plano_conta (sub_plano_conta_id);

ALTER TABLE despesa
  ADD CONSTRAINT fk_despesa_pessoa
  FOREIGN KEY (despesa_pessoa_id)
  REFERENCES pessoa (pessoa_id);

ALTER TABLE despesa
  ADD CONSTRAINT fk_despesa_anexo
  FOREIGN KEY (despesa_anexo_id)
  REFERENCES anexo (anexo_id);

-- ============================================================
-- CHECKs normativos (sem ENUM)
-- ============================================================

ALTER TABLE despesa
  ADD CONSTRAINT ck_despesa_competencia
  CHECK (despesa_competencia ~ '^[0-9]{4}-(0[1-9]|1[0-2])$');

ALTER TABLE despesa
  ADD CONSTRAINT ck_despesa_status
  CHECK (despesa_status IN ('LANCADA', 'PAGA', 'PAGA_PARCIAL', 'CANCELADA'));

-- Comentários (metadados do banco)
COMMENT ON TABLE despesa IS
'Entidade macro do lançamento de despesas. Registra contexto gerencial (centro de custo, subconta, competência, pessoa, documento principal). Pagamento ocorre por parcelas em parcela_despesa.';

COMMENT ON COLUMN despesa.despesa_id IS
'Identificador da despesa (PK).';

COMMENT ON COLUMN despesa.despesa_n_doc IS
'Número do documento de referência (nota fiscal, contrato, etc.).';

COMMENT ON COLUMN despesa.despesa_descricao IS
'Descrição da despesa.';

COMMENT ON COLUMN despesa.despesa_valor IS
'Valor total da despesa (deve corresponder à soma dos valores das parcelas vinculadas).';

COMMENT ON COLUMN despesa.despesa_competencia IS
'Competência no formato YYYY-MM.';

COMMENT ON COLUMN despesa.despesa_data_emissao IS
'Data de emissão do documento principal.';

COMMENT ON COLUMN despesa.despesa_centro_custo_id IS
'Centro de custo de origem (FK para centro_custo).';

COMMENT ON COLUMN despesa.despesa_sub_plano_conta_id IS
'Subplano de contas lançável (FK para sub_plano_conta).';

COMMENT ON COLUMN despesa.despesa_pessoa_id IS
'Pessoa relacionada à despesa (opcional, FK para pessoa).';

COMMENT ON COLUMN despesa.despesa_status IS
'Status da despesa: LANCADA / PAGA / PAGA_PARCIAL / CANCELADA.';

COMMENT ON COLUMN despesa.despesa_anexo_id IS
'Documento principal vinculado à despesa (opcional, FK para anexo).';

COMMENT ON CONSTRAINT fk_despesa_centro_custo ON despesa IS
'Vincula a despesa ao centro de custo de origem.';

COMMENT ON CONSTRAINT fk_despesa_sub_plano_conta ON despesa IS
'Vincula a despesa à subconta lançável utilizada na classificação.';

COMMENT ON CONSTRAINT fk_despesa_pessoa ON despesa IS
'Vincula a despesa a uma pessoa relacionada (quando aplicável).';

COMMENT ON CONSTRAINT fk_despesa_anexo ON despesa IS
'Vincula a despesa ao documento principal (quando aplicável).';
```

### 6.4.5 Parcela de Despesa (`parcela_despesa`)

Representa a **unidade real de cobrança e pagamento** de uma despesa  
(1ª parcela, 2ª parcela, acordo, renegociação, etc.).

É nesta entidade que ficam registrados **vencimento**, **status de pagamento** e **anexos específicos**, como boleto/promissória e comprovante de pagamento.

---

**Campos:**

- `parcela_despesa_id` — PK (IDENTITY)  
- `parcela_despesa_despesa_id` — FK para `despesa`  
- `parcela_despesa_numero_prestacao` — identificador livre da parcela  
  (ex.: `1`, `2`, `3` ou `ACO1`, `ACO2`; o padrão pode ser definido pelo usuário)  
- `parcela_despesa_valor` — valor da parcela  
- `parcela_despesa_vencimento` — data de vencimento (`YYYY-MM-DD`)  
- `parcela_despesa_status` — `PENDENTE` / `PAGA` / `CANCELADA`  
- `parcela_despesa_anexo_doc_cobranca_id` — FK para `anexo`  
  (boleto, promissória, documento de cobrança)  
- `parcela_despesa_anexo_doc_pgto_id` — FK para `anexo`  
  (comprovante de pagamento)  
- `parcela_despesa_datahora_criacao` — data e hora de criação do registro  
- `parcela_despesa_datahora_atualizacao` — data e hora da última atualização do registro  

---

**DDL:**
```sql
-- ============================================================
-- Tabela: parcela_despesa
-- Objetivo: Unidade real de cobrança e pagamento de uma despesa
-- ============================================================

CREATE TABLE IF NOT EXISTS parcela_despesa (
  parcela_despesa_id                    BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY, -- Identificador da parcela (PK)
  parcela_despesa_despesa_id            BIGINT NOT NULL,                                 -- Despesa vinculada (FK)
  parcela_despesa_numero_prestacao      TEXT NOT NULL,                                   -- Identificador livre da parcela
  parcela_despesa_valor                 NUMERIC(14,2) NOT NULL,                          -- Valor da parcela
  parcela_despesa_vencimento            DATE NOT NULL,                                   -- Data de vencimento
  parcela_despesa_status                TEXT NOT NULL,                                   -- PENDENTE / PAGA / CANCELADA
  parcela_despesa_anexo_doc_cobranca_id BIGINT,                                          -- Documento de cobrança (opcional)
  parcela_despesa_anexo_doc_pgto_id     BIGINT,                                          -- Comprovante de pagamento (opcional)

  -- Auditoria mínima
  parcela_despesa_datahora_criacao     TIMESTAMPTZ NOT NULL DEFAULT now(),               -- Data/hora de criação
  parcela_despesa_datahora_atualizacao TIMESTAMPTZ NOT NULL DEFAULT now()                -- Data/hora da última atualização
);

ALTER TABLE parcela_despesa
  ADD CONSTRAINT fk_parcela_despesa_despesa
  FOREIGN KEY (parcela_despesa_despesa_id)
  REFERENCES despesa (despesa_id);

ALTER TABLE parcela_despesa
  ADD CONSTRAINT fk_parcela_despesa_anexo_cobranca
  FOREIGN KEY (parcela_despesa_anexo_doc_cobranca_id)
  REFERENCES anexo (anexo_id);

ALTER TABLE parcela_despesa
  ADD CONSTRAINT fk_parcela_despesa_anexo_pgto
  FOREIGN KEY (parcela_despesa_anexo_doc_pgto_id)
  REFERENCES anexo (anexo_id);

-- ============================================================
-- CHECKs normativos (sem ENUM)
-- ============================================================

ALTER TABLE parcela_despesa
  ADD CONSTRAINT ck_parcela_despesa_status
  CHECK (parcela_despesa_status IN ('PENDENTE', 'PAGA', 'CANCELADA'));

-- Comentários (metadados do banco)
COMMENT ON TABLE parcela_despesa IS
'Unidade real de cobrança e pagamento de uma despesa. Registra vencimento, status e documentos específicos (cobrança e pagamento).';

COMMENT ON COLUMN parcela_despesa.parcela_despesa_id IS
'Identificador único da parcela (PK).';

COMMENT ON COLUMN parcela_despesa.parcela_despesa_despesa_id IS
'Despesa à qual a parcela pertence (FK para despesa).';

COMMENT ON COLUMN parcela_despesa.parcela_despesa_numero_prestacao IS
'Identificador livre da parcela, definido pelo usuário ou regra operacional (ex.: 1, 2, 3, ACO1, ACO2).';

COMMENT ON COLUMN parcela_despesa.parcela_despesa_valor IS
'Valor financeiro da parcela.';

COMMENT ON COLUMN parcela_despesa.parcela_despesa_vencimento IS
'Data de vencimento da parcela.';

COMMENT ON COLUMN parcela_despesa.parcela_despesa_status IS
'Status da parcela: PENDENTE, PAGA ou CANCELADA.';

COMMENT ON COLUMN parcela_despesa.parcela_despesa_anexo_doc_cobranca_id IS
'Documento de cobrança da parcela (boleto, promissória, etc.).';

COMMENT ON COLUMN parcela_despesa.parcela_despesa_anexo_doc_pgto_id IS
'Comprovante de pagamento da parcela.';

COMMENT ON COLUMN parcela_despesa.parcela_despesa_datahora_criacao IS
'Data e hora de criação do registro da parcela.';

COMMENT ON COLUMN parcela_despesa.parcela_despesa_datahora_atualizacao IS
'Data e hora da última atualização do registro da parcela.';

COMMENT ON CONSTRAINT fk_parcela_despesa_despesa ON parcela_despesa IS
'Vincula a parcela à despesa principal.';

COMMENT ON CONSTRAINT fk_parcela_despesa_anexo_cobranca ON parcela_despesa IS
'Vincula a parcela ao documento de cobrança.';

COMMENT ON CONSTRAINT fk_parcela_despesa_anexo_pgto ON parcela_despesa IS
'Vincula a parcela ao comprovante de pagamento.';
```
---

### 6.4.6 Rateio de Despesa (`despesa_rateio`)

Distribuição **gerencial do custo** entre múltiplos centros de custo.

---

#### Ajuste Estrutural

Como o **pagamento efetivo ocorre por parcelas**, o rateio passa a apontar para  
`parcela_despesa` em vez de `despesa`.

Dessa forma:

- cada **parcela** pode ser rateada de forma independente;
- é possível tratar **parcelas renegociadas, acordos ou valores distintos**;
- o fechamento gerencial permanece consistente, mesmo quando a despesa original sofre alterações.

---

#### Exemplo Técnico — Rateio Proporcional por Peso Relativo (Escritório → Obras)

Este exemplo descreve um **método de rateio proporcional**, aplicável a despesas comuns do **Escritório**, distribuídas entre **centros de custo operacionais (obras)** com base no **peso financeiro relativo** de cada contrato vigente no período.

#### Premissas do Modelo

- O **Escritório** concentra despesas administrativas comuns.
- As **Obras** representam centros de custo que se beneficiam dessas despesas.
- O rateio é apurado **por período (mês/competência)**, no nível de **parcela da despesa**.
- Cada obra possui um **contrato ativo**, com valor financeiro conhecido.

#### Variáveis

- **X** — Valor total das despesas do Escritório no período  
- **Zᵢ** — Valor do contrato da obra *i* vigente no período  
- **Y** — Soma dos valores de todos os contratos vigentes no período, com  
  `Y = Σ Zᵢ`
- **Wᵢ** — Peso relativo da obra *i* no período, com  
  `Wᵢ = Zᵢ / Y`
- **Rᵢ** — Valor do rateio destinado à obra *i*, com  
  `Rᵢ = Wᵢ × X`

#### Procedimento Operacional

1. Registrar a despesa do Escritório em `despesa`, com:
   - `despesa_centro_custo_id` = Escritório
   - classificação contábil adequada (plano/subplano)

2. Criar uma **parcela da despesa** (`parcela_despesa`) representando o período de apuração  
   (ex.: competência mensal).

3. Identificar os **contratos vigentes no período** e seus respectivos valores (`Zᵢ`).

4. Calcular:
   - `Y` = soma dos contratos vigentes
   - `Wᵢ` = peso relativo de cada obra

5. Registrar, em `despesa_rateio`, **uma linha por obra**, contendo:
   - `despesa_rateio_parcela_despesa_id` — parcela do período
   - `despesa_rateio_centro_custo_id` — obra destino
   - `despesa_rateio_valor` — valor `Rᵢ`

#### Observações Importantes

- O sistema **armazena apenas o valor rateado**, não o percentual.
- Percentuais (`Wᵢ`) podem ser calculados dinamicamente em consultas e relatórios.
- O conjunto de obras participantes do rateio pode variar a cada período, sem impacto histórico.
- Alterações contratuais (início, término, renegociação) afetam apenas os períodos subsequentes.

#### Benefícios do Modelo

- Aderente a múltiplas metodologias de rateio
- Compatível com cenários dinâmicos (entrada/saída de obras)
- Auditável e historicamente consistente
- Independente de regras fixas ou amarrações estruturais

Este método atende ao princípio do AxysPro de **flexibilidade operacional com controle gerencial rigoroso**.

---

#### Observação Normativa — Persistência de Rateio e Avaliação de Resultados

No AxysPro, o **rateio de despesas** é tratado como um **resultado gerencial**, e não como um método ou regra fixa armazenada em banco de dados.

#### Princípio Fundamental

O sistema **não armazena critérios, metodologias ou parâmetros de cálculo de rateio**  
(percentual, proporcionalidade, contrato, metragem, quantidade de pessoas, etc.).

Esses critérios pertencem exclusivamente à **camada de aplicação** e podem variar:

- por empresa;
- por período;
- por centro de custo;
- ou por decisão manual do usuário.

O banco de dados registra **apenas o resultado final aprovado pelo usuário**.

---

#### Fluxo Operacional Padrão

A funcionalidade de rateio segue o seguinte fluxo conceitual:

1. Leitura de parâmetros base (período, parcelas, centros de custo, dados auxiliares)
2. Processamento por rotina interna (automática ou manual)
3. Apresentação de uma **distribuição pré-preenchida**
4. Intervenção do usuário:
   - aceitar;
   - ajustar;
   - excluir;
   - complementar manualmente
5. Persistência no banco **somente dos valores finais de rateio**

O sistema **não registra como o valor foi calculado**, apenas **o valor rateado em si**.

---

#### Impacto na Avaliação de Resultados

Essa abordagem garante que:

- a avaliação gerencial seja feita **com base em dados consolidados e efetivos**;
- relatórios reflitam **decisões reais**, não fórmulas abstratas;
- mudanças de critério **não reescrevam o passado**;
- auditorias analisem **valores distribuídos**, e não intenções de cálculo.

O foco do AxysPro é a **leitura de resultado**, não a imposição de metodologia.

---

#### Regra Sistêmica Obrigatória

Para garantir integridade dos dados, o sistema deve validar, no momento do salvamento:

> **A soma dos valores rateados de uma parcela deve ser igual ao valor total da parcela**,  
> respeitando eventual tolerância de arredondamento definida pelo sistema.

Essa diretriz assegura **flexibilidade operacional**, **neutralidade metodológica** e  
**confiabilidade absoluta na análise de resultados gerenciais**.

---

#### Campos e DDL

**Campos:**

- `despesa_rateio_id` — PK (IDENTITY)  
- `despesa_rateio_parcela_despesa_id` — FK para `parcela_despesa`  
- `despesa_rateio_centro_custo_id` — FK para `centro_custo`  
- `despesa_rateio_valor` — valor rateado  
- `despesa_rateio_obs` — observação (opcional)  
- `despesa_rateio_ativo` — indica se o rateio está ativo e deve ser considerado nas leituras gerenciais  
- `despesa_rateio_datahora_criacao` — data e hora de criação do registro  
- `despesa_rateio_datahora_atualizacao` — data e hora da última atualização do registro  

---

**DDL:**
```sql
-- ============================================================
-- Tabela: despesa_rateio
-- Objetivo: Rateio gerencial do custo entre centros de custo
-- Regra: rateio aponta para parcela_despesa (não para despesa)
-- Regra sistêmica: soma(despesa_rateio_valor) por parcela == parcela_despesa_valor
-- Observação: o banco armazena apenas o RESULTADO (valores rateados),
--            não armazena critérios/metodologias/percentuais do cálculo.
-- ============================================================

CREATE TABLE IF NOT EXISTS despesa_rateio (
  despesa_rateio_id                   BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY, -- Identificador do rateio (PK)
  despesa_rateio_parcela_despesa_id   BIGINT NOT NULL,                                 -- Parcela original (FK)
  despesa_rateio_centro_custo_id      BIGINT NOT NULL,                                 -- Centro de custo destino (FK)
  despesa_rateio_valor                NUMERIC(14,2) NOT NULL,                          -- Valor rateado
  despesa_rateio_obs                  TEXT,                                            -- Observação livre (opcional)

  -- Controle de estado
  despesa_rateio_ativo                BOOLEAN NOT NULL DEFAULT TRUE,                   -- Indica se o rateio está ativo

  -- Auditoria mínima
  despesa_rateio_datahora_criacao     TIMESTAMPTZ NOT NULL DEFAULT now(),               -- Data/hora de criação
  despesa_rateio_datahora_atualizacao TIMESTAMPTZ NOT NULL DEFAULT now()                -- Data/hora da última atualização
);

ALTER TABLE despesa_rateio
  ADD CONSTRAINT fk_despesa_rateio_parcela
  FOREIGN KEY (despesa_rateio_parcela_despesa_id)
  REFERENCES parcela_despesa (parcela_despesa_id);

ALTER TABLE despesa_rateio
  ADD CONSTRAINT fk_despesa_rateio_centro_custo
  FOREIGN KEY (despesa_rateio_centro_custo_id)
  REFERENCES centro_custo (centro_custo_id);

-- Comentários (metadados do banco)
COMMENT ON TABLE despesa_rateio IS
'Rateio gerencial do custo entre centros de custo. Aponta para parcela_despesa (pagamento efetivo), armazenando apenas valores finais aprovados (resultado), não critérios/metodologias.';

COMMENT ON COLUMN despesa_rateio.despesa_rateio_id IS
'Identificador único do rateio (PK).';

COMMENT ON COLUMN despesa_rateio.despesa_rateio_parcela_despesa_id IS
'Parcela da despesa que está sendo rateada (FK para parcela_despesa).';

COMMENT ON COLUMN despesa_rateio.despesa_rateio_centro_custo_id IS
'Centro de custo destino do rateio (FK para centro_custo).';

COMMENT ON COLUMN despesa_rateio.despesa_rateio_valor IS
'Valor rateado para o centro de custo destino, referente à parcela informada.';

COMMENT ON COLUMN despesa_rateio.despesa_rateio_obs IS
'Observação livre do rateio (opcional).';

COMMENT ON COLUMN despesa_rateio.despesa_rateio_ativo IS
'Indica se o rateio está ativo e deve ser considerado nas leituras gerenciais.';

COMMENT ON COLUMN despesa_rateio.despesa_rateio_datahora_criacao IS
'Data e hora de criação do registro do rateio.';

COMMENT ON COLUMN despesa_rateio.despesa_rateio_datahora_atualizacao IS
'Data e hora da última atualização do registro do rateio.';

COMMENT ON CONSTRAINT fk_despesa_rateio_parcela ON despesa_rateio IS
'Vincula o rateio à parcela (nível correto de apuração/pagamento).';

COMMENT ON CONSTRAINT fk_despesa_rateio_centro_custo ON despesa_rateio IS
'Vincula o rateio ao centro de custo destino.';

-- Índices recomendados (performance em consultas gerenciais por parcela e por centro de custo)
CREATE INDEX IF NOT EXISTS idx_despesa_rateio_parcela
  ON despesa_rateio (despesa_rateio_parcela_despesa_id);

CREATE INDEX IF NOT EXISTS idx_despesa_rateio_centro_custo
  ON despesa_rateio (despesa_rateio_centro_custo_id);

CREATE INDEX IF NOT EXISTS idx_despesa_rateio_parcela_centro
  ON despesa_rateio (despesa_rateio_parcela_despesa_id, despesa_rateio_centro_custo_id);

-- Observação importante:
-- A validação da soma do rateio == valor da parcela deve ocorrer na aplicação
-- (com tolerância de arredondamento, se definida). Em etapa futura, isso pode
-- ser reforçado via trigger/constraint, caso desejado.
```

---

# 7. Módulos do Sistema AxysPro

O AxysPro é concebido como um **ecossistema modular**, no qual cada módulo possui responsabilidade funcional bem definida, porém todos compartilham **uma base estrutural, conceitual e técnica comum**.

A modularização no AxysPro **não representa sistemas isolados**, mas sim **domínios funcionais integráveis**, construídos sobre contratos explícitos de dados, interface e comportamento.

Antes da apresentação dos módulos funcionais propriamente ditos, é fundamental compreender a existência de uma **camada estrutural básica**, comum a todo o sistema, sem a qual nenhum módulo pode operar.

---

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

## 7.2 Módulo SysCost

### Generalidades

O **SysCost** é o módulo de **Centro de Custos e Controle de Despesas** do AxysPro.

Ele é responsável por estruturar, registrar e consolidar despesas sob uma ótica **gerencial**, permitindo a correta leitura de custos por:

- centro de custo  
- plano e subplano de contas  
- competência  
- parcelas  
- rateios  

O SysCost foi concebido para atender desde cenários simples até estruturas complexas, mantendo como premissas:

- flexibilidade operacional  
- consistência histórica  
- neutralidade metodológica  
- foco em resultado gerencial  

---

### 7.2.1 Sobre o SysCost

O SysCost não se limita ao registro de despesas pagas.  
Ele organiza o **ciclo completo da despesa**, desde sua origem até sua leitura gerencial final.

Entre suas principais responsabilidades estão:

- cadastro e manutenção de centros de custo  
- classificação de despesas por plano e subplano de contas  
- registro de despesas por competência  
- controle de parcelas, vencimentos e status de pagamento  
- vinculação de documentos (nota, boleto, comprovante, contrato)  
- rateio gerencial de custos entre centros de custo  
- consolidação para análises futuras (orçado x realizado, DRE, relatórios gerenciais)

O módulo é **agnóstico quanto à metodologia de rateio**, armazenando exclusivamente os **valores finais aprovados**, conforme diretriz do AxysPro.

---

### 7.2.2 Tabelas Utilizadas pelo Módulo SysCost

O SysCost utiliza tabelas da **Camada Fundamental** (usuário, pessoa, anexos e log), porém possui um conjunto próprio de tabelas funcionais, responsáveis por sua lógica de negócio.

As tabelas **específicas do módulo SysCost** são:

- `centro_custo`  
  Cadastro dos centros de custo utilizados para classificação gerencial.

- `plano_conta`  
  Conta principal (nível macro) para consolidação e leitura gerencial.

- `sub_plano_conta`  
  Conta lançável, vinculada ao plano de contas mãe.

- `despesa`  
  Entidade principal da despesa, responsável pelo contexto gerencial  
  (centro de custo, classificação, competência, pessoa, documento principal).

- `parcela_despesa`  
  Unidade real de cobrança e pagamento da despesa, com controle de vencimento, status e documentos específicos.

- `despesa_rateio`  
  Registro do rateio gerencial de cada parcela de despesa entre centros de custo destino.

> **Observação normativa:**  
> Tabelas como `pessoa`, `usuario`, `anexo`, `tipo_documento` e `log_sistema` pertencem à Camada Fundamental e são utilizadas pelo SysCost, mas **não são consideradas tabelas do módulo**.

---

### 7.2.3 Arquivos e Diretórios Utilizados pelo SysCost

O módulo SysCost segue integralmente os **padrões de organização do AxysPro**, respeitando a separação entre backend, templates, frontend, arquivos estáticos e dados persistentes.

---

#### Backend (Python / Flask)

```text
backend/
  modules/
    syscost/
      __init__.py
      routes_syscost.py
      services_syscost.py
      repository_syscost.py
```

- `routes_syscost.py`  
  Define as rotas HTTP do módulo (listagem, cadastro, edição, rateio, etc.).

- `services_syscost.py`  
  Contém as regras de negócio, validações operacionais e fluxos internos.

- `repository_syscost.py`  
  Responsável pelo acesso, consulta e persistência dos dados do módulo.

---

#### Templates HTML (Jinja)

```text
backend/templates/
  pages/
    syscost/
      despesas_listar.html
      despesas_cadastrar.html
      despesas_editar.html
      parcelas_gerenciar.html
      rateio_parcela.html
```

Todos os templates do SysCost:

- herdam obrigatoriamente de `base.html`
- utilizam componentes reutilizáveis sempre que possível
- não contêm CSS ou JavaScript inline

---

#### Componentes Reutilizáveis

```text
backend/templates/components/
  despesas/
  parcelas/
  rateio/
```

Componentes compartilhados entre as telas do SysCost, tais como:

- tabelas
- formulários
- blocos de resumo
- modais reutilizáveis

---

#### JavaScript

```text
static/js/
  pages/
    syscost/
      despesas.js
      parcelas.js
      rateio.js
```

Cada tela do SysCost carrega **apenas um JavaScript específico**, utilizando funções do **Core** e de **Widgets** quando necessário.

---

#### CSS

```text
static/css/
  modules/
    syscost.css
```

O CSS do SysCost é **complementar** ao CSS global do AxysPro e só existe quando uma customização não pode ser atendida pelo design system principal.

---

#### Documentos e Uploads

```text
instance/
  docs/
    anexos/
    sensiveis/
```

Documentos vinculados a despesas, parcelas e rateios são armazenados conforme as regras da **Camada Fundamental**, com controle sistêmico e rastreabilidade via `log_sistema`.

---

> **Regra Final do Módulo SysCost:**  
> Toda operação relevante realizada no SysCost deve gerar registro no `log_sistema`, garantindo rastreabilidade completa das ações executadas no módulo.

---

 
# 8. Fechamento

O **AxysPro** foi concebido não apenas como um sistema de gestão, mas como um **framework estrutural de organização, rastreabilidade e tomada de decisão**, capaz de acompanhar a evolução natural de empresas, projetos e operações ao longo do tempo.

Desde sua concepção, o AxysPro adota como princípio fundamental a **documentação como parte do sistema**, e não como um artefato posterior.  
Cada decisão arquitetural, cada entidade de dados, cada fluxo operacional e cada módulo nasce **documentado desde a origem**, garantindo clareza, previsibilidade e continuidade.

Este documento não representa um encerramento, mas sim um **marco inicial sólido**.  
O AxysPro é, por definição, um sistema em **constante evolução**, projetado para crescer de forma controlada, sem rupturas estruturais, improvisações ou dependência de conhecimento tácito.

A evolução do sistema ocorre de maneira consciente e rastreável:

- novas funcionalidades são incorporadas por módulos  
- decisões são registradas e contextualizadas  
- dados permanecem íntegros e auditáveis  
- o histórico nunca é reescrito, apenas ampliado  

Ao longo de sua vida útil, o AxysPro manterá como compromisso central:

- documentar o **porquê**, o **como** e o **impacto** de cada funcionalidade  
- preservar a coerência entre arquitetura, código e dados  
- permitir leitura clara desde a origem até a última instância de uso  

Mais do que um produto fechado, o AxysPro se estabelece como um **ecossistema vivo**, preparado para absorver novas demandas, novos módulos e novos contextos, sem perder sua identidade técnica e conceitual.

Este fechamento, portanto, não encerra o sistema.  
Ele formaliza o início de uma base **confiável, extensível e duradoura**, sobre a qual o AxysPro continuará a ser construído, documentado e aprimorado ao longo do tempo.
