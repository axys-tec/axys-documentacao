# Axys-Gestor / SL — Business Rules / TRD

## 1. Status do documento

Este documento define a regra de negócio, a diretriz técnica e o esqueleto operacional do `Axys-Gestor / SL`.

Ele consolida 3 bases:

1. [`arquitecture.md`](/Users/rdias07/Documents/GitHub/axys-gestor-sl/arquitecture.md:1) e [`schema.sql`](/Users/rdias07/Documents/GitHub/axys-gestor-sl/schema.sql:1)
2. `z_lunalosys_repo` como fonte principal da regra operacional
3. `z_axys-easy_repo` como fonte principal da arquitetura canônica Axys

O objetivo aqui não é descrever uma ideia abstrata. O objetivo é fechar um contrato de produto suficiente para orientar scaffold, modelagem de módulos, política de auditoria e implementação.

---

## 2. Método de revisão — 10 loops

Este TRD foi consolidado após 10 passadas de revisão sobre o mesmo material.

### Loop 1 — Varredura estrutural

- inventário dos diretórios principais
- separação entre fonte de regra e fonte de arquitetura
- alinhamento com [`backend/backend_tree.md`](/Users/rdias07/Documents/GitHub/axys-gestor-sl/z_axys-easy_repo/backend/backend_tree.md:1)

### Loop 2 — Scaffold do Easy

- leitura do boot em [`backend/app.py`](/Users/rdias07/Documents/GitHub/axys-gestor-sl/z_axys-easy_repo/backend/app.py:1)
- leitura da configuração em [`backend/core/runtime_config.py`](/Users/rdias07/Documents/GitHub/axys-gestor-sl/z_axys-easy_repo/backend/core/runtime_config.py:1)
- confirmação do padrão `FastAPI + templates + storage + worker`

### Loop 3 — Auth, perfis e tenancy

- leitura de [`backend/core/security.py`](/Users/rdias07/Documents/GitHub/axys-gestor-sl/z_axys-easy_repo/backend/core/security.py:1)
- leitura de [`backend/core/permissions.py`](/Users/rdias07/Documents/GitHub/axys-gestor-sl/z_axys-easy_repo/backend/core/permissions.py:1)
- leitura de [`backend/modules/auth/service.py`](/Users/rdias07/Documents/GitHub/axys-gestor-sl/z_axys-easy_repo/backend/modules/auth/service.py:1)

### Loop 4 — Front e navegação canônica

- leitura de [`backend/modules/pages/routes.py`](/Users/rdias07/Documents/GitHub/axys-gestor-sl/z_axys-easy_repo/backend/modules/pages/routes.py:1)
- leitura de [`backend/frontend/templates/partials/main_sidebar.html`](/Users/rdias07/Documents/GitHub/axys-gestor-sl/z_axys-easy_repo/backend/frontend/templates/partials/main_sidebar.html:1)
- leitura de [`backend/frontend/templates/app/main_client.html`](/Users/rdias07/Documents/GitHub/axys-gestor-sl/z_axys-easy_repo/backend/frontend/templates/app/main_client.html:1)

### Loop 5 — Infraestrutura operacional

- leitura de [`backend/storage/storage_provider.py`](/Users/rdias07/Documents/GitHub/axys-gestor-sl/z_axys-easy_repo/backend/storage/storage_provider.py:1)
- leitura de [`backend/core/email_client.py`](/Users/rdias07/Documents/GitHub/axys-gestor-sl/z_axys-easy_repo/backend/core/email_client.py:1)
- leitura de [`backend/core/zapi_client.py`](/Users/rdias07/Documents/GitHub/axys-gestor-sl/z_axys-easy_repo/backend/core/zapi_client.py:1)
- leitura de [`backend/core/celery_app.py`](/Users/rdias07/Documents/GitHub/axys-gestor-sl/z_axys-easy_repo/backend/core/celery_app.py:1)

### Loop 6 — Fluxo macro do Lunalô

- leitura de [`routes_lunalo.py`](/Users/rdias07/Documents/GitHub/axys-gestor-sl/z_lunalosys_repo/backend/modules/lunalo/routes_lunalo.py:1)
- leitura de [`service_index_view.py`](/Users/rdias07/Documents/GitHub/axys-gestor-sl/z_lunalosys_repo/backend/modules/lunalo/service_index_view.py:1)
- mapeamento dos módulos operacionais reais

### Loop 7 — Pedidos e compras

- leitura de [`service_pedidos_fluxo.py`](/Users/rdias07/Documents/GitHub/axys-gestor-sl/z_lunalosys_repo/backend/modules/lunalo/service_pedidos_fluxo.py:1)
- leitura de [`service_pedidos_importacao.py`](/Users/rdias07/Documents/GitHub/axys-gestor-sl/z_lunalosys_repo/backend/modules/lunalo/service_pedidos_importacao.py:1)
- leitura de [`service_compras.py`](/Users/rdias07/Documents/GitHub/axys-gestor-sl/z_lunalosys_repo/backend/modules/lunalo/service_compras.py:1)

### Loop 8 — Tickets e royalties

- leitura de [`service_tickets.py`](/Users/rdias07/Documents/GitHub/axys-gestor-sl/z_lunalosys_repo/backend/modules/lunalo/service_tickets.py:1)
- leitura de [`service_royalties.py`](/Users/rdias07/Documents/GitHub/axys-gestor-sl/z_lunalosys_repo/backend/modules/lunalo/service_royalties.py:1)

### Loop 9 — Compartilhamento, anexos e utilidades reais

- leitura de [`service_mixes_views.py`](/Users/rdias07/Documents/GitHub/axys-gestor-sl/z_lunalosys_repo/backend/modules/lunalo/service_mixes_views.py:1)
- leitura de [`private_attachment_sharing.py`](/Users/rdias07/Documents/GitHub/axys-gestor-sl/z_lunalosys_repo/backend/services/private_attachment_sharing.py:1)

### Loop 10 — Consolidação com o schema

- cruzamento com [`schema.sql`](/Users/rdias07/Documents/GitHub/axys-gestor-sl/schema.sql:1)
- consolidação com [`arquitecture.md`](/Users/rdias07/Documents/GitHub/axys-gestor-sl/arquitecture.md:1)
- fechamento das decisões de auditoria, tenancy, naming e persistência

Conclusão dos 10 loops:

- `Lunalô` é a fonte principal do comportamento
- `AxysEasy` é a fonte principal da forma de construir
- `Axys-Gestor / SL` não deve ser clone direto de nenhum dos dois

---

## 3. Decisão-mãe do projeto

O `Axys-Gestor / SL` deve ser tratado como:

- uma aplicação nova
- `FastAPI` desde o início
- scaffold canônico Axys
- multitenancy real
- auditoria na aplicação
- regra operacional herdada do `Lunalô`

Desdobramento direto dessa decisão:

- não portar `Flask`
- não portar o backend do `Lunalô` como base estrutural
- não portar SQL legado como contrato final
- não usar triggers de banco como coração da auditoria
- não reinventar boot, storage, auth, worker e operação onde o `Easy` já resolveu bem

---

## 4. Objetivo do produto

O `Axys-Gestor / SL` é um SaaS multitenant para operação de lojas e franquias ligadas à Santa Lolla.

No MVP, ele precisa resolver de forma integrada:

- `organization`
- `catalog`
- `orders`
- `purchases`
- `tickets`
- `royalties`

Em termos de produto:

- `organization` organiza a malha empresarial e operacional
- `catalog` mantém a base mestre de coleções, produtos, grades e anexos utilitários
- `orders` controla a entrada comercial de pedidos
- `purchases` controla a materialização fiscal e operacional das compras
- `tickets` controla contestação, responsabilidade e abatimento
- `royalties` controla consolidação e fechamento financeiro de royalties

O schema `planning` existe, mas está reservado para evolução futura. O MVP não depende de `collection_plan` nem de `collection_plan_item`.

---

## 5. Fontes canônicas

### 5.1 Regra de negócio

Fonte principal: `z_lunalosys_repo`

Arquivos mais relevantes:

- [`routes_lunalo.py`](/Users/rdias07/Documents/GitHub/axys-gestor-sl/z_lunalosys_repo/backend/modules/lunalo/routes_lunalo.py:1)
- [`service_pedidos_fluxo.py`](/Users/rdias07/Documents/GitHub/axys-gestor-sl/z_lunalosys_repo/backend/modules/lunalo/service_pedidos_fluxo.py:1)
- [`service_pedidos_importacao.py`](/Users/rdias07/Documents/GitHub/axys-gestor-sl/z_lunalosys_repo/backend/modules/lunalo/service_pedidos_importacao.py:1)
- [`service_compras.py`](/Users/rdias07/Documents/GitHub/axys-gestor-sl/z_lunalosys_repo/backend/modules/lunalo/service_compras.py:1)
- [`service_tickets.py`](/Users/rdias07/Documents/GitHub/axys-gestor-sl/z_lunalosys_repo/backend/modules/lunalo/service_tickets.py:1)
- [`service_royalties.py`](/Users/rdias07/Documents/GitHub/axys-gestor-sl/z_lunalosys_repo/backend/modules/lunalo/service_royalties.py:1)
- [`service_mixes_views.py`](/Users/rdias07/Documents/GitHub/axys-gestor-sl/z_lunalosys_repo/backend/modules/lunalo/service_mixes_views.py:1)
- [`private_attachment_sharing.py`](/Users/rdias07/Documents/GitHub/axys-gestor-sl/z_lunalosys_repo/backend/services/private_attachment_sharing.py:1)

### 5.2 Arquitetura técnica

Fonte principal: `z_axys-easy_repo`

Arquivos mais relevantes:

- [`backend/app.py`](/Users/rdias07/Documents/GitHub/axys-gestor-sl/z_axys-easy_repo/backend/app.py:1)
- [`backend/core/runtime_config.py`](/Users/rdias07/Documents/GitHub/axys-gestor-sl/z_axys-easy_repo/backend/core/runtime_config.py:1)
- [`backend/core/security.py`](/Users/rdias07/Documents/GitHub/axys-gestor-sl/z_axys-easy_repo/backend/core/security.py:1)
- [`backend/core/permissions.py`](/Users/rdias07/Documents/GitHub/axys-gestor-sl/z_axys-easy_repo/backend/core/permissions.py:1)
- [`backend/core/audit_service.py`](/Users/rdias07/Documents/GitHub/axys-gestor-sl/z_axys-easy_repo/backend/core/audit_service.py:1)
- [`backend/storage/storage_provider.py`](/Users/rdias07/Documents/GitHub/axys-gestor-sl/z_axys-easy_repo/backend/storage/storage_provider.py:1)
- [`backend/core/email_client.py`](/Users/rdias07/Documents/GitHub/axys-gestor-sl/z_axys-easy_repo/backend/core/email_client.py:1)
- [`backend/core/zapi_client.py`](/Users/rdias07/Documents/GitHub/axys-gestor-sl/z_axys-easy_repo/backend/core/zapi_client.py:1)
- [`backend/core/celery_app.py`](/Users/rdias07/Documents/GitHub/axys-gestor-sl/z_axys-easy_repo/backend/core/celery_app.py:1)
- [`backend/modules/pages/routes.py`](/Users/rdias07/Documents/GitHub/axys-gestor-sl/z_axys-easy_repo/backend/modules/pages/routes.py:1)
- [`backend/frontend/templates/partials/main_sidebar.html`](/Users/rdias07/Documents/GitHub/axys-gestor-sl/z_axys-easy_repo/backend/frontend/templates/partials/main_sidebar.html:1)
- [`backend/frontend/templates/app/main_client.html`](/Users/rdias07/Documents/GitHub/axys-gestor-sl/z_axys-easy_repo/backend/frontend/templates/app/main_client.html:1)
- [`run_dev.sh`](/Users/rdias07/Documents/GitHub/axys-gestor-sl/z_axys-easy_repo/run_dev.sh:1)
- [`z_scripts_apoio/run_worker.sh`](/Users/rdias07/Documents/GitHub/axys-gestor-sl/z_axys-easy_repo/z_scripts_apoio/run_worker.sh:1)
- [`render.yaml`](/Users/rdias07/Documents/GitHub/axys-gestor-sl/z_axys-easy_repo/render.yaml:1)
- [`.env.local`](/Users/rdias07/Documents/GitHub/axys-gestor-sl/z_axys-easy_repo/.env.local:1)

---

## 6. Princípios obrigatórios

### 6.1 Princípios de negócio

- refletir a operação real de loja e franquia
- permitir auditoria clara de toda mutação relevante
- suportar múltiplas lojas, parceiros e tenants
- permitir evolução futura para planejamento e automações

### 6.2 Princípios técnicos

- `FastAPI` como stack
- `PostgreSQL` como banco
- `tenant_uuid` como eixo de isolamento
- `store_uuid` como eixo operacional
- `storage` abstrato com suporte a `local` e `R2`
- `Redis + Celery` para jobs pesados
- auth via Hub
- auditoria em camada de aplicação

### 6.3 Princípios de nomenclatura

- comentários em português-BR
- telas em português-BR
- seeds e checks textuais em português-BR
- tabelas e colunas em inglês

### 6.4 Princípios de UX

- main, header e sidebar no padrão Axys
- módulo com rota inicial, filtros, listagem, detalhe e ação
- mensagens de erro e sucesso claras
- telas separadas entre consulta, processamento, relatório e edição

---

## 7. O que o Easy deve ser replicado

O `AxysEasy` é o padrão canônico de implementação para:

- estrutura de diretórios
- boot da aplicação
- boot de worker
- `runtime_config`
- integração com Hub
- leitura de claims e licenças
- política de perfis
- storage
- envio de e-mail
- sender WhatsApp via Z-API
- deploy
- scripts operacionais

### 7.1 Estrutura de diretórios

Padrão-alvo:

- `backend/core`
- `backend/modules`
- `backend/api`
- `backend/frontend/templates`
- `backend/frontend/static`
- `backend/storage`
- `backend/workers`
- `z_scripts_apoio`

### 7.2 Boot da app

O modelo a espelhar é o de [`backend/app.py`](/Users/rdias07/Documents/GitHub/axys-gestor-sl/z_axys-easy_repo/backend/app.py:1):

- carga de `.env.local` fora de produção
- `FastAPI` única
- sessões
- CORS
- templates server-side
- static
- split entre HTML e API
- tratamento centralizado de erro

### 7.3 Auth e tenancy

Regras herdadas do `Easy`:

- o Gestor não emite token próprio em produção
- o token vem do Hub
- o token precisa carregar `tenant_uuid`, `role`, `is_staff` e licenças
- o front monta a navegação a partir das claims

### 7.4 Perfis

Perfis mínimos herdados conceitualmente de [`permissions.py`](/Users/rdias07/Documents/GitHub/axys-gestor-sl/z_axys-easy_repo/backend/core/permissions.py:1):

- `internal owner`
- `internal admin`
- `internal user`
- `client owner`
- `client admin`
- `client user`

### 7.5 Storage

O Gestor deve replicar o modelo de [`storage_provider.py`](/Users/rdias07/Documents/GitHub/axys-gestor-sl/z_axys-easy_repo/backend/storage/storage_provider.py:1):

- provider único
- leitura e escrita abstratas
- suporte a `local`, `r2` e transição híbrida
- bucket público separado de privado
- acesso privado mediado pela aplicação

### 7.6 E-mail

O Gestor deve ter um serviço centralizado de e-mail como em [`email_client.py`](/Users/rdias07/Documents/GitHub/axys-gestor-sl/z_axys-easy_repo/backend/core/email_client.py:1).

Casos de uso esperados:

- envio de imagem de mix
- envio de ficha de royalties
- envio de anexo protegido
- alertas operacionais futuros

### 7.7 Z-API / WhatsApp

O Gestor deve reaproveitar o padrão de [`zapi_client.py`](/Users/rdias07/Documents/GitHub/axys-gestor-sl/z_axys-easy_repo/backend/core/zapi_client.py:1).

Casos de uso esperados:

- compartilhar imagem de mix
- compartilhar PDF
- compartilhar documento privado

### 7.8 Worker

O Gestor deve replicar o modelo de [`celery_app.py`](/Users/rdias07/Documents/GitHub/axys-gestor-sl/z_axys-easy_repo/backend/core/celery_app.py:1).

Jobs com forte candidato a worker:

- importação de pedidos grandes
- processamento de compras
- geração de relatórios pesados
- reconciliações
- geração de PDF
- compactação e download em lote

### 7.9 Operação

Também devem ser espelhados:

- `.env.local`
- `render.yaml`
- `run_dev.sh`
- `run_worker.sh`
- scripts de storage, rebuild e apoio

---

## 8. O que o Lunalô deve fornecer

O `Lunalô` é a melhor base para:

- semântica operacional
- sequência real de tarefas
- cálculos de pedido
- lógica de compras
- recálculo de tickets
- consolidação de royalties
- comportamento esperado de mix, coleção, lojas e relatórios

O `Lunalô` não deve ser copiado como:

- stack
- scaffold
- auth
- tenancy
- padrão de persistência
- contrato final de banco

---

## 9. Jornada macro do usuário

### 9.1 Entrada

Fluxo canônico:

1. usuário acessa a aplicação
2. a aplicação verifica sessão ou token
3. se necessário, redireciona para login
4. o login autentica contra o Hub
5. a app lê claims
6. a app monta contexto de navegação
7. o usuário cai na `main`

### 9.2 Main

A `main` do Gestor deve seguir muito mais o `Easy` do que o `Lunalô`.

Ela deve exibir:

- boas-vindas e contexto do tenant
- módulos habilitados
- atalhos operacionais
- pendências e alertas
- acessos recentes ou úteis no futuro

### 9.3 Navegação

Fluxo típico por módulo:

1. tela inicial do módulo
2. filtros
3. listagem
4. detalhe
5. ação operacional
6. persistência
7. auditoria
8. retorno com feedback

### 9.4 Módulos centrais do MVP

- `main`
- `organization`
- `catalog`
- `orders`
- `purchases`
- `tickets`
- `royalties`
- `reports`
- `settings`

---

## 10. Skeleton funcional da aplicação

### 10.1 Main

Responsável por:

- visão resumida do tenant
- entrada principal da operação
- alertas e pendências
- atalhos

### 10.2 Organization

Responsável por:

- marcas
- receitas de marca
- grupos empresariais
- parceiros
- fornecedores
- vínculos `tenant-store-partner`
- segredos de integração por loja

### 10.3 Catalog

Responsável por:

- coleções
- grupos de produto
- tipos de produto
- grades
- produtos
- tipos de anexo
- material operacional como books e mixes

### 10.4 Orders

Responsável por:

- importar pedido
- associar fornecedor
- consultar pedido
- editar linhas pontuais
- totalizar custos e royalties
- gerar relatórios

### 10.5 Purchases

Responsável por:

- lançar ou processar compra
- vincular item a produto ou mix
- revisar status
- gerar relatório
- alimentar royalties

### 10.6 Tickets

Responsável por:

- cadastrar ticket
- detalhar ticket
- distribuir responsabilidade financeira
- decidir status
- receber, recusar, estornar, abater

### 10.7 Royalties

Responsável por:

- criar ficha
- vincular compras
- vincular abatimentos
- recalcular bruto, abatimento e líquido
- anexar documentos
- compartilhar e fechar ficha

---

## 11. Regras detalhadas por domínio

### 11.1 Lojas

Base principal: `Lunalô`

Regras:

- loja é a unidade operacional concreta
- loja pode estar ativa ou inativa
- loja participa da operação de pedidos, compras, tickets e royalties
- loja se conecta ao tenancy por `organization.tenant_store`
- integrações e segredos por loja ficam fora das tabelas transacionais

### 11.2 Coleções

Base principal: `Lunalô` e `schema.sql`

Regras:

- coleção é eixo central da operação
- pedido, compra e ficha de royalties são filtrados por coleção com frequência
- coleção pode ter bloqueio operacional em fases específicas
- coleção deve ser fácil de listar, detalhar e reportar

### 11.3 Produtos, grades e mixes

Base principal: `Lunalô`

Regras:

- mix continua sendo a unidade operacional forte na experiência do usuário
- produto é a unidade mestra do catálogo
- grade representa tamanhos
- itens sem variação de tamanho usam `PC`
- `PC` é size válido, não exceção
- imagem principal do produto é operacionalmente importante

Consequência de modelagem:

- `catalog.product` guarda o produto mestre
- `catalog.product_grade` guarda a relação produto-grade
- a UI continua exibindo linguagem de mix quando a operação pedir

### 11.4 Books

Base principal: `Lunalô`

Regras:

- books são material operacional
- books ajudam a formar repertório de produtos, mixes e compra
- books podem gerar relatórios e downloads

No MVP:

- books pertencem ao eixo `catalog`
- não precisam nascer como módulo independente separado do catálogo

### 11.5 Pedidos

Base principal: [`service_pedidos_fluxo.py`](/Users/rdias07/Documents/GitHub/axys-gestor-sl/z_lunalosys_repo/backend/modules/lunalo/service_pedidos_fluxo.py:1) e [`service_pedidos_importacao.py`](/Users/rdias07/Documents/GitHub/axys-gestor-sl/z_lunalosys_repo/backend/modules/lunalo/service_pedidos_importacao.py:1)

Regras centrais:

- pedido pode ser importado por PDF antigo
- pedido pode ser importado por CSV + ZIP no fluxo novo
- pedido sempre precisa se vincular a loja, coleção e marca
- após a leitura, há etapa de associação de fornecedor
- o pedido consolida itens por fornecedor e por mix
- a grade do item precisa ser preservada
- a imagem lida ou associada ao mix é operacionalmente útil

Regras de cálculo:

- `sell_in` é a autosoma dos custos do item
- `sell_out` pode ser registrado explicitamente
- `sell_out` tende a ser `2x sell_in`, mas não deve ficar engessado como regra fixa de banco
- royalties são totalizados por linha e consolidados no pedido
- totais por fornecedor e totais gerais devem ser recalculáveis pela app

Regras de persistência:

- cabeçalho em `orders.order`
- itens em `orders.order_product`
- grade em `orders.order_product_grade`
- `order_attachment` é coluna em JSON, não tabela

Regras de UX:

- tela de importação
- etapa de associação
- consulta por loja e coleção
- detalhe por fornecedor e mix
- edição pontual controlada
- relatórios

### 11.6 Compras

Base principal: [`service_compras.py`](/Users/rdias07/Documents/GitHub/axys-gestor-sl/z_lunalosys_repo/backend/modules/lunalo/service_compras.py:1)

Regras centrais:

- compra representa a materialização fiscal e operacional da mercadoria
- compra pode vir de fluxos distintos de processamento
- compra exige vinculação a mix ou produto
- compra pode receber complemento manual
- compra deve produzir relatório operacional

Status-alvo consolidados:

- `LANCADO`
- `RECEBIDO`
- `RECUSADO`
- `NAO_RECEBIDO`

Regras de negócio:

- compra recebida alimenta obrigação de royalties
- compra recusada ou não recebida não deve seguir igual compra recebida
- o vínculo entre compra e mix precisa ser explícito ou rastreável
- `purchase_attachment` é coluna em JSON, não tabela

Regras de persistência:

- cabeçalho em `purchases.purchase`
- item em `purchases.purchase_product`
- grade em `purchases.purchase_product_grade`

### 11.7 Tickets

Base principal: [`service_tickets.py`](/Users/rdias07/Documents/GitHub/axys-gestor-sl/z_lunalosys_repo/backend/modules/lunalo/service_tickets.py:1)

Regras centrais:

- ticket é contestação operacional-financeira
- ticket tem número, tipo, data, loja, marca, observação e mix quando houver
- ticket pode ter múltiplos responsáveis financeiros
- ticket precisa de painel, consulta, detalhe e decisão

Regra herdada importante:

- no legado, o status do ticket é recalculado a partir das linhas de fornecedor
- essa ideia deve ser mantida

Adaptação para o Gestor:

- `ticket` é o cabeçalho
- `ticket_debtor_split` é a decomposição financeira
- um split pode afetar fornecedor, royalties da franqueadora ou marketing/imagem

Status-alvo do ticket:

- `LANCADO`
- `DEVIDO`
- `CONVERTIDO`
- `RECUSADO`
- `PAGO`

Status-alvo do split:

- `LANCADO`
- `DEVIDO`
- `RECUSADO`
- `PAGO_ABATIDO`

Regra de ouro:

- o recálculo do cabeçalho é responsabilidade da aplicação
- o banco não deve usar trigger para isso

### 11.8 Royalties

Base principal: [`service_royalties.py`](/Users/rdias07/Documents/GitHub/axys-gestor-sl/z_lunalosys_repo/backend/modules/lunalo/service_royalties.py:1)

Regras centrais:

- royalties são consolidados em ficha
- ficha agrega compras elegíveis
- ficha agrega abatimentos oriundos de ticket
- ficha calcula bruto, abatimento e líquido
- ficha aceita anexos
- ficha pode ser compartilhada por link, e-mail e WhatsApp

Regras de cálculo:

- valor bruto nasce da soma das compras elegíveis
- abatimento nasce da soma dos splits vinculados
- líquido é `bruto - abatimento`

Regras de persistência:

- `royalties.royalty_statement` é a ficha
- `royalties.royalty_statement_detail` vincula compra à ficha
- `royalties.royalty_statement_attachment` guarda anexos

Regra importante:

- a separação fina entre royalties e marketing não precisa nascer toda no item do pedido no MVP
- ela pode se materializar na consolidação da ficha e nos splits de ticket

### 11.9 Relatórios

O produto precisa de relatórios reais de operação.

Relatórios mínimos esperados:

- pedidos
- crosscheck
- cadastro por coleção
- compras
- tickets
- royalties
- books
- painéis operacionais

Regra técnica:

- relatórios leves podem sair inline
- relatórios pesados devem poder ir para worker

### 11.10 Integrações

Regras:

- integrações devem respeitar o tenant
- segredos ficam em `organization.store_secrets`
- integrações não podem vazar segredo em log comum
- toda integração relevante deve ter rastreabilidade

---

## 12. Front-end — comportamento esperado

### 12.1 Direção geral

O front deve seguir o padrão do `Easy`, não o do `Lunalô`.

Isso significa:

- header Axys
- rail/sidebar Axys
- templates server-side
- diferenciação clara entre contexto staff e contexto cliente

### 12.2 O que reaproveitar conceitualmente do Easy

Com base em [`main_sidebar.html`](/Users/rdias07/Documents/GitHub/axys-gestor-sl/z_axys-easy_repo/backend/frontend/templates/partials/main_sidebar.html:1) e [`main_client.html`](/Users/rdias07/Documents/GitHub/axys-gestor-sl/z_axys-easy_repo/backend/frontend/templates/app/main_client.html:1):

- sidebar orientada a produto ou módulo
- cards de entrada
- badges de status
- experiência de home organizada e limpa
- bloqueio visual para módulo não liberado

### 12.3 Tipos de tela obrigatórios

- `main`
- listagem
- detalhe
- cadastro/edição
- processamento/importação
- relatório
- erro

### 12.4 Fluxo visual por módulo

Cada módulo deve, sempre que couber:

1. abrir em tela principal de módulo
2. oferecer filtros
3. listar resultados
4. abrir detalhe
5. permitir ação
6. confirmar persistência
7. devolver feedback

### 12.5 Recursos de UX obrigatórios

- filtros persistentes quando útil
- tabela com ordenação e paginação onde fizer sentido
- badges de status
- feedback claro de processamento
- caminho visível para download, compartilhamento e relatório

---

## 13. Back-end — comportamento esperado

### 13.1 Organização

O backend deve seguir o arranjo:

- `core` para infraestrutura
- `modules` para domínio
- `api` para REST
- `frontend` para HTML e assets
- `workers` para jobs longos

### 13.2 Onde a regra deve viver

A regra deve viver prioritariamente em serviços de aplicação.

Ela não deve viver como regra principal:

- em template
- em JavaScript solto
- em trigger de banco

### 13.3 Pipeline mínimo de mutação

Toda escrita relevante deve:

1. validar autenticação
2. validar permissão
3. validar tenant e store
4. validar payload
5. carregar estado anterior quando preciso
6. persistir
7. atualizar `created_at`, `updated_at`, `created_by`, `updated_by`
8. registrar auditoria
9. devolver resposta consistente

### 13.4 Isolamento

Toda leitura e escrita deve considerar:

- `tenant_uuid`
- `store_uuid`
- `partner_uuid` quando aplicável
- perfil do usuário
- licença ou escopo habilitado

### 13.5 Jobs

Devem ir para worker:

- tarefas acima de alguns segundos
- importações pesadas
- relatórios pesados
- geração de PDF ou ZIP em lote

---

## 14. Auditoria e proteção

### 14.1 Princípio

A auditoria é responsabilidade da aplicação.

Não haverá trigger de banco como mecanismo primário de:

- `updated_at`
- soma de totalizadores
- log de auditoria

### 14.2 Perguntas que toda mutação deve responder

- quem fez
- quando fez
- o que fez
- em qual tenant fez
- em qual contexto operacional fez
- qual era o estado antes
- qual ficou o estado depois

### 14.3 Colunas nativas obrigatórias

As tabelas de negócio devem usar, quando couber:

- `created_at`
- `updated_at`
- `created_by`
- `updated_by`

### 14.4 Tabelas de auditoria

O banco prevê:

- `audit.logs`
- `audit.login_logs`
- `audit.api_logs`
- `audit.retention_policy`
- `audit.retention_rule`

### 14.5 Política de gravação em `audit.logs`

Registrar ao menos:

- schema
- tabela
- registro
- ação
- usuário
- IP quando disponível
- snapshot antes
- snapshot depois

Eventos mínimos:

- criação, edição e exclusão de cadastro mestre sensível
- importação de pedido
- associação de fornecedor
- alteração de status de compra
- decisão de ticket
- criação ou edição de ficha de royalties
- vínculo ou desvínculo que altere valor de negócio

### 14.6 Política de gravação em `audit.login_logs`

Registrar:

- login bem-sucedido
- logout
- falha de autenticação

### 14.7 Política de gravação em `audit.api_logs`

Registrar em escrita via API:

- método
- endpoint
- usuário
- tenant
- status
- IP
- payload sanitizado
- duração

### 14.8 Proteção de anexos

Com base no padrão observado em [`private_attachment_sharing.py`](/Users/rdias07/Documents/GitHub/axys-gestor-sl/z_lunalosys_repo/backend/services/private_attachment_sharing.py:1):

- anexo privado não deve ser exposto por path livre
- compartilhamento temporário deve usar token ou URL assinada
- compartilhamento por e-mail e WhatsApp deve ser controlado pela app

---

## 15. População do banco

### 15.1 Princípio

O banco deve ser povoado por:

- telas
- importações controladas
- integrações
- seeds iniciais

Não por edição manual ad hoc em banco como fluxo oficial.

### 15.2 Cadastro mestre

Podem nascer por tela administrativa, importação controlada ou seed:

- `brand`
- `brand_revenue`
- `group_enterprise`
- `partner`
- `supplier`
- `collection`
- `product_group`
- `product_type`
- `product_grade`
- `attachment_type`

### 15.3 Operação transacional

Os domínios `orders`, `purchases`, `tickets` e `royalties` devem ser povoados por:

- ação de usuário
- importação
- conciliação
- integração

### 15.4 Seeds

Seeds e valores de negócio permanecem em português-BR.

Exemplos:

- tipos de produto
- grupos de produto
- grades
- tipos de anexo
- estações

### 15.5 Totalizadores

Campos totalizadores devem ser recalculados pela aplicação.

Neste momento:

- sem trigger de soma
- sem trigger de `updated_at`
- sem trigger de auditoria

---

## 16. Modelo operacional por módulo

### 16.1 Orders

Fluxo-alvo:

1. entrar em `orders`
2. consultar pedidos
3. importar novo pedido quando necessário
4. associar fornecedor
5. revisar itens, grades e totais
6. ajustar linha quando autorizado
7. emitir relatório

### 16.2 Purchases

Fluxo-alvo:

1. entrar em `purchases`
2. lançar ou processar compra
3. vincular mix ou produto
4. revisar nota e item
5. mudar status
6. emitir relatório
7. refletir em royalties

### 16.3 Tickets

Fluxo-alvo:

1. entrar em `tickets`
2. consultar ou cadastrar
3. abrir detalhe
4. definir decisão
5. distribuir responsabilidade financeira
6. receber, recusar ou abater
7. refletir no cabeçalho e nos relatórios

### 16.4 Royalties

Fluxo-alvo:

1. entrar em `royalties`
2. criar ou abrir ficha
3. vincular compras
4. vincular abatimentos
5. revisar bruto, abatimento e líquido
6. anexar e compartilhar documentos
7. fechar a ficha

---

## 17. Reaproveitamento explícito

### 17.1 Reaproveitar do Lunalô

- fluxo de importação de pedidos
- etapa de associação de fornecedor
- visão operacional de loja, coleção, mix e book
- lógica de compra e revisão
- lógica de painel e detalhe de tickets
- cálculo e fechamento de ficha de royalties
- necessidade de compartilhamento de imagens e anexos

### 17.2 Não reaproveitar do Lunalô como padrão estrutural

- `Flask`
- organização de backend legado
- SQL legado como contrato final
- acoplamentos de tenant único
- convenções caseiras de runtime

### 17.3 Reaproveitar do AxysEasy

- estrutura de pastas
- `FastAPI`
- `core`
- `storage`
- `email`
- `zapi sender`
- `worker`
- `render.yaml`
- `.env.local`
- `run_dev.sh`
- `run_worker.sh`
- auth do Hub
- tenancy
- permissions
- audit service
- padrão de templates e navegação

### 17.4 Não reaproveitar do AxysEasy como regra de negócio

- domínio de construção civil
- catálogo de obras
- semântica dos módulos de engenharia

---

## 18. Diretriz de implementação

### 18.1 Fase 1

Consolidar documentos-base:

- `arquitecture.md`
- `schema.sql`
- `business_rules.md`

### 18.2 Fase 2

Trazer a documentação canônica para `docs` e manter este projeto documentado no submodule de documentação Axys.

### 18.3 Fase 3

Clonar o arranjo do `Easy`:

- boot web
- boot worker
- core
- auth
- pages
- storage
- email
- zapi

### 18.4 Fase 4

Modelar os módulos do Gestor:

- `organization`
- `catalog`
- `orders`
- `purchases`
- `tickets`
- `royalties`

### 18.5 Fase 5

Portar cuidadosamente a regra do `Lunalô` para a nova arquitetura, sem portar o legado arquitetural.

---

## 19. Decisões já fechadas

- a app será `FastAPI`
- o scaffold será baseado no `AxysEasy`
- o `Lunalô` é fonte de regra, não de arquitetura
- a auditoria será feita pela aplicação
- não haverá trigger de `updated_at`
- não haverá trigger de soma de totalizadores neste momento
- tabelas e colunas ficam em inglês
- comentários, telas, valores de negócio e checks textuais ficam em português-BR
- `order_attachment` e `purchase_attachment` são colunas, não tabelas
- `planning` fica reservado para evolução futura
- `sell_in` e `sell_out` entram no desenho do pedido
- `PC` é size válido para item sem variação

---

## 20. Pendências conscientes

Estas pendências não invalidam o TRD:

- desenho fino de cada tela do novo Gestor
- detalhamento final de cada integração externa
- árvore definitiva de sidebar do produto
- priorização de jobs por worker na primeira entrega
- modelagem detalhada do futuro `planning`

---

## 21. Conclusão executiva

O `Axys-Gestor / SL` deve nascer como síntese deliberada de duas forças:

- a força operacional do `Lunalô`
- a força arquitetural do `AxysEasy`

Traduzindo isso para execução:

- a regra do `Lunalô` entra
- a arquitetura do `Easy` entra
- o projeto novo não pode ser um `Lunalô` reempacotado
- o projeto novo não pode ser um `Easy` com tema trocado

Ele precisa ser a versão Axys, multitenant, auditável, escalável e canônica da operação já validada em `pedidos`, `compras`, `tickets` e `royalties`.
