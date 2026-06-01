**AxysPro — Documentação Oficial do Sistema**

# Visão Geral do Ecossistema Axys

**Nota de Governança Documental**

Este documento constitui um **contrato geral e normativo** do AxysPro. Referências a estruturas técnicas, exemplos de tabelas, fluxos internos ou descrições de implementação aqui presentes têm **caráter ilustrativo ou histórico**, não sendo vinculantes como obrigação técnica.

A definição técnica detalhada (DDL, migrações, engines, bibliotecas e estratégias de implementação) é tratada na documentação técnica específica de cada módulo, ADRs e implementações referenciais mantidas pela Axys Engenharia e Tecnologia Ltda.

O **Axys** é concebido como um **ecossistema de sistemas**, projetado para oferecer organização, padronização e governança de informações **operacionais, gerenciais e estratégicas**de empresas, projetos, obras e unidades de negócio.

O **AxysPro** é o **sistema principal desse ecossistema**, atuando como a plataforma robusta e multifuncional de gestão por empresa.
Além dele, o ecossistema contempla **MicroApps independentes** e um **sistema central de governança e licenciamento**, todos integrados conceitualmente por contratos e diretrizes comuns.

Essa separação é **intencional e estrutural**, permitindo:
- isolamento por empresa;
- escalabilidade técnica e comercial;
- evolução independente de sistemas;
- governança clara de acesso, licenças e funcionalidades.

Este contrato estabelece, portanto, **diretrizes normativas, funcionais e jurídicas** do AxysPro, não se destinando a descrever, impor ou congelar decisões de implementação técnica.

Referências a estruturas internas, exemplos técnicos, fluxos operacionais ou modelos de dados aqui presentes possuem **caráter conceitual e ilustrativo**, podendo evoluir conforme decisões técnicas documentadas, sem necessidade de aditivo contratual.

A documentação técnica específica de módulos, ADRs e implementações referenciais prevalece quanto aos detalhes de implementação, respeitados os limites e princípios definidos neste contrato.

---

## Princípio de Abstração Técnica

O AxysPro é licenciado como uma plataforma de software, cujo funcionamento, arquitetura interna, estruturas técnicas, modelos de dados e mecanismos de execução são definidos e evoluídos pela Axys Engenharia e Tecnologia Ltda.

A documentação contratual descreve **funcionalidades, responsabilidades e limites de uso**, não constituindo compromisso com implementações técnicas específicas, estruturas internas, tecnologias, bibliotecas ou modelos de persistência.

Detalhes técnicos, arquiteturais e de implementação são tratados em documentação própria e podem evoluir sem necessidade de aditivo contratual, desde que não alterem o objeto funcional contratado.

## 0.1 Sistemas que compõem o Ecossistema

### Sistema 1 — AxysPro
Sistema principal, robusto e multifuncional, executado de forma **isolada por empresa**, com banco de dados próprio e controle interno de identidade, permissões e auditoria.

***Modalidades de Execução***

O AxysPro pode ser executado em diferentes modalidades, a critério do cliente, incluindo ambiente local, hospedado, infraestrutura própria ou serviços terceirizados.

A escolha da modalidade de execução não altera os termos de licenciamento, responsabilidades contratuais ou propriedade intelectual, respeitados os requisitos mínimos de operação definidos pela Axys Engenharia e Tecnologia Ltda.

### Sistema 2 — AxysHub
Sistema central hospedado na infraestrutura da **Axys Engenharia e Tecnologia Ltda.**, responsável por **licenciamento, billing e governança externa do ecossistema**.

O AxysHub constitui infraestrutura própria da Axys Engenharia e Tecnologia Ltda, destinada à gestão de licenças, comercialização e serviços associados, não se confundindo com o AxysPro, que é o software licenciado ao cliente.


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
- Licenciamento

> **Execução Local e Conectividade**
>
> O AxysPro pode operar em ambiente local ou hospedado, conforme escolha do cliente.
> A indisponibilidade temporária de conectividade não invalida a operação do sistema,
> desde que respeitadas as políticas de licenciamento, validação periódica e auditoria.

:
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


A ausência temporária de conectividade não invalida o uso do AxysPro, desde que respeitadas as políticas de licenciamento, validação e auditoria estabelecidas contratualmente.

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
├── docs/                                 # DOCUMENTAÇÃO OFICIAL (VERSIONADA)
│   ├── core/
│   │   ├── axyspro_core.md
│   │   └── axys_modules_core.md
│   ├── systems/
│   │   ├── axys_system.md                # EPR Axys Tecnologia (vendável para outras empresas)
│   │   ├── axys_hub.md                   # HUB conexões e autosserviço para microapp >> comunica com ERP Axys
│   │   ├── axys_hub.md                   # HUB conexões e autosserviço para microapp >> comunica com ERP Axys
│   │   └── axys_*.md                     # Demais sistemas ou projetos importantes, vendáveis, se houver
│   ├── apps/
│   │   ├── axys_easy-price.md            # MicroApp gerador de orçamentos paramétricos
│   │   ├── axys_easy-cpu.md              # MicroApp gerador de Composições de Preço Unitário
│   │   ├── axys_easy-orca.md             # Engloba easy-price, easy-cpu e tráz mais funcionalidades (caderno de encargos, critérios, etc)
│   │   ├── axys_build-daily.md           # MicroApp diário de obras
│   │   ├── axys_project_asbea.md         # MicroApp Gerador automatizado de nomenclatura de documentos
│   │   ├── axys_project_memo-desc.md     # MicroApp Gerador automatizado de memorial descritivo
│   │   └── axys_*.md                     # Demais MicroApps, vendáveis, conforme demanda ou ideias
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

# 6. Estrutura de Dados — Governança e Princípios de Persistência

Esta seção estabelece, de forma **normativa**, os **princípios de governança** do modelo de dados do AxysPro, aplicáveis a **todos os módulos e domínios funcionais** do sistema.

O AxysPro adota **contratos explícitos de persistência**, nos quais a semântica dos dados, a rastreabilidade das informações e a previsibilidade estrutural são consideradas elementos essenciais de qualidade e confiabilidade.

> **Caráter normativo**  
> As diretrizes aqui descritas são obrigatórias e vinculantes.  
> Em caso de divergência, prevalece a modelagem vigente definida pela Axys
> Engenharia e Tecnologia Ltda, conforme documentação técnica e implementações
> referenciais distribuídas oficialmente.

---

## 6.1 Organização por Domínios Funcionais

A persistência de dados no AxysPro é organizada por **domínios funcionais**, refletindo a separação lógica e estrutural do sistema.

Cada módulo do AxysPro é responsável por seu próprio domínio de dados, respeitando uma **camada estrutural comum**, compartilhada entre os módulos, que sustenta os mecanismos transversais do ecossistema, tais como:

- identidade e controle de acesso  
- classificação e sensibilidade da informação  
- gestão documental e versionamento  
- auditoria e rastreabilidade  
- leitura gerencial e consolidação de dados  

A definição detalhada das entidades, campos e relacionamentos de cada domínio é tratada **na documentação específica de cada módulo**, não fazendo parte desta seção normativa geral.

---

## 6.2 Regras Gerais de Modelagem (Obrigatórias)

As seguintes diretrizes aplicam-se a toda e qualquer estrutura de dados persistida no AxysPro:

### 6.2.1 Identidade e Integridade
- Toda entidade persistida deve possuir identificador estável e imutável.
- Identificadores técnicos não possuem significado de negócio isoladamente.

### 6.2.2 Relacionamentos
- Relacionamentos relevantes devem ser explicitamente modelados.
- Relações compostas devem preservar integridade e rastreabilidade.

### 6.2.3 Auditoria e Rastreabilidade
- Toda informação relevante deve ser rastreável ao longo do tempo.
- A responsabilidade pela atualização correta de dados e registros de auditoria
  pertence à aplicação.

### 6.2.4 Semântica dos Dados
- Campos com significado normativo devem preservar semântica clara e consistente.
- Regras dependentes de contexto operacional ou temporal são tratadas na lógica da aplicação, e não na estrutura estática de dados.

### 6.2.5 Evolução Controlada
- A evolução do modelo de dados ocorre de forma controlada e versionada.
- Alterações estruturais devem preservar compatibilidade sempre que possível.
- Remoções ou mudanças disruptivas exigem estratégia formal de transição.

---

## 6.3 Documentação Técnica e Implementação

A definição técnica detalhada da persistência de dados, incluindo estruturas, migrações e particularidades de engine, é tratada na **documentação técnica do projeto** e nos **artefatos de migração**, não sendo parte deste documento normativo de alto nível.

 
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