# Axys-Gestor / SL — Fluxo de Telas

## 1. Objetivo

Este documento descreve o fluxo macro de telas do `Axys-Gestor / SL`.

A referência principal de estrutura é o `AxysEasy`, especialmente em:

- login e redirecionamento inicial
- shell autenticado com header e sidebar
- consistência entre módulos
- experiência previsível de consulta, detalhe e retorno

A referência principal de comportamento operacional é o `Lunalô`, especialmente em:

- `Mixes`
- `Books`
- `Pedidos`
- `Compras`
- `Tickets`
- `Royalties`

Referências principais:

- [`z_axys-easy_repo/backend/modules/pages/routes.py`](/Users/rdias07/Documents/GitHub/axys-gestor-sl/z_axys-easy_repo/backend/modules/pages/routes.py:1)
- [`z_axys-easy_repo/backend/frontend/templates/partials/main_sidebar.html`](/Users/rdias07/Documents/GitHub/axys-gestor-sl/z_axys-easy_repo/backend/frontend/templates/partials/main_sidebar.html:1)
- [`z_axys-easy_repo/backend/frontend/templates/app/main_client.html`](/Users/rdias07/Documents/GitHub/axys-gestor-sl/z_axys-easy_repo/backend/frontend/templates/app/main_client.html:1)
- [`z_lunalosys_repo/backend/modules/lunalo/service_index_view.py`](/Users/rdias07/Documents/GitHub/axys-gestor-sl/z_lunalosys_repo/backend/modules/lunalo/service_index_view.py:1)

---

## 2. Princípio de navegação

O `Axys-Gestor / SL` deve seguir esta lógica:

1. entrada
2. autenticação
3. `main`
4. escolha do módulo
5. consulta ou ação principal do módulo
6. detalhe
7. persistência
8. retorno com feedback

Em resumo:

- o `Easy` define a estrada
- o `Lunalô` ajuda a definir os destinos

---

## 3. Estrutura macro da experiência

### 3.1 Fluxo principal

```text
Raiz (/)
  -> Login
  -> Main
  -> Módulo
  -> Lista/Consulta
  -> Detalhe/Ação
  -> Persistência
  -> Feedback
  -> Retorno à consulta ou ao detalhe
```

### 3.2 Estrutura visual macro

Todas as telas autenticadas devem respeitar, em regra, este arranjo:

```text
Header global
  + Sidebar / rail lateral
  + Área principal de conteúdo
    + título da seção
    + filtros
    + conteúdo principal
    + alertas / feedback / ações
```

### 3.3 Princípio de consistência

Cada módulo deve repetir um padrão parecido:

- entrada do módulo
- filtros
- listagem
- detalhe
- ação operacional
- retorno

---

## 4. Fluxo de entrada

### 4.1 Raiz

Fluxo:

1. usuário acessa `/`
2. sistema redireciona para login ou para `main`, conforme sessão/token

### 4.2 Login

Tela:

- formulário de autenticação
- mensagem de erro quando necessário
- redirecionamento após sucesso

Fluxo:

1. usuário informa credenciais
2. sistema autentica via Hub
3. sistema lê claims, tenant, escopo e perfil
4. sistema grava contexto de sessão/cookie
5. sistema redireciona para `main`

### 4.3 Logout

Fluxo:

1. usuário aciona sair
2. sistema registra logout
3. sessão é encerrada
4. usuário volta ao login

---

## 5. Tela Main

### 5.1 Papel da tela

A `main` é a porta oficial do produto.

Ela deve combinar:

- shell e organização estrutural do `AxysEasy`
- linguagem central de entrada com ícones grandes, inspirada no `Lunalô`

Ou seja:

- haverá sidebar no padrão Axys
- o miolo da `main` terá mais cara de portal operacional

### 5.2 Composição esperada

A `main` deve ser composta de:

- linha de boas-vindas com:
  - `Bem-vindo, {name}`
  - `Empresa: {tenant_name}`
  - `Loja(s): {lista de lojas acessíveis}`
- bloco central de `Últimos Pedidos`
- bloco lateral direito de `Últimas Notícias`
- bloco inferior de atalhos com imagem/ícone grande

### 5.3 Blocos funcionais da `main`

- `Últimos Pedidos`
  - listagem resumida
  - limite inicial de 20
  - colunas esperadas:
    - `Coleção`
    - `N. Pedido`
    - `Loja`
    - `N. peças`
    - `Total Pedido`
- `Últimas Notícias`
  - limite inicial de 3
- atalhos principais com imagem:
  - `Mixes`
  - `Books`
  - `Pedidos`
  - `Compras`
  - `Tickets`
  - `Royalties`

### 5.4 Comportamento

Fluxo:

1. usuário entra na `main`
2. enxerga contexto de acesso e lojas disponíveis
3. consulta últimos pedidos, se quiser
4. escolhe um dos atalhos principais
5. vai para o módulo correspondente

### 5.5 Contextos de acesso

O produto deve prever estes contextos:

- `client`
- `partner`
- `internal`
- `group`

Regras gerais:

- `client` é o usuário operacional da ponta
- `partner` é o parceiro representante, com acesso às stores que representa
- `internal` é o acesso da equipe Axys
- `group` é o acesso corporativo Santa Lolla / grupo

---

## 6. Sidebar / Rail

### 6.1 Papel

A sidebar é o eixo fixo de navegação do produto autenticado.

No `Easy`, ela funciona como rail de produtos. No `Gestor`, ela deve funcionar como rail de módulos.

### 6.2 Composição esperada

- botão de recolher/expandir
- lista de módulos principais
- destaque visual do módulo ativo
- possibilidade de itens extras conforme o contexto de acesso

### 6.3 Módulos previstos no rail principal

- `Main`
- `Mixes`
- `Books`
- `Pedidos`
- `Compras`
- `Tickets`
- `Royalties`

### 6.4 Regra de estado

Cada item do rail pode estar:

- ativo
- disponível
- restrito por perfil
- indisponível por fase de entrega

---

## 7. Fluxo por contexto de usuário

### 7.1 Usuário client

Fluxo padrão:

1. login
2. `main`
3. visualiza lojas e módulos do seu escopo
4. entra no módulo permitido
5. consulta, detalha e executa ações autorizadas

### 7.2 Usuário partner

Fluxo padrão:

1. login
2. `main`
3. opera no escopo das stores que representa
4. entra em módulos operacionais
5. realiza alimentações e consultas permitidas

### 7.3 Usuário internal

Fluxo padrão:

1. login
2. `main`
3. navega pelos módulos com visão ampliada de suporte e operação
4. acessa ações internas permitidas

### 7.4 Usuário group

Fluxo padrão:

1. login
2. `main`
3. navega no escopo corporativo da marca ou grupo
4. consulta e atua conforme o perfil habilitado

### 7.5 Consequência prática

O fluxo geral é parecido entre os contextos.

O que muda principalmente é:

- quais lojas aparecem
- quais menus aparecem
- quais ações ficam visíveis
- quais decisões ficam permitidas

---

## 8. Fluxo do módulo Main

### 8.1 Caminho

```text
Login
  -> Main
```

### 8.2 Possíveis saídas

Da `main`, o usuário deve conseguir ir para:

- `Mixes`
- `Books`
- `Pedidos`
- `Compras`
- `Tickets`
- `Royalties`

### 8.3 Regra

A `main` não deve ser uma tela final.

Ela deve sempre funcionar como distribuidor de navegação.

Cadastros e vinculações estruturais entre tenants e stores não pertencem a esta navegação do Gestor; isso é competência do `AxysHub`.

---

## 9. Fluxo do módulo Mixes

### 9.1 Estrutura esperada

```text
Mixes
  -> listagem
  -> detalhe
  -> compartilhar
```

### 9.2 Fluxo típico

1. usuário entra em `Mixes`
2. consulta a listagem
3. abre o detalhe do mix
4. baixa ou compartilha imagem quando necessário
5. retorna à listagem

---

## 10. Fluxo do módulo Books

### 10.1 Estrutura esperada

```text
Books
  -> listagem
  -> consulta
  -> detalhe
```

### 10.2 Fluxo típico

1. usuário entra em `Books`
2. consulta books disponíveis
3. abre detalhe quando necessário
4. retorna à listagem

---

## 11. Fluxo do módulo Orders

### 11.1 Estrutura esperada

```text
Pedidos
  -> listagem
  -> importar
  -> relatórios
  -> consultar pedido
  -> editar linha
  -> associar fornecedor
```

### 11.2 Regras de navegação

O módulo deve espelhar o comportamento operacional de `./lunalo/pedidos`.

No sidebar do módulo:

- `Listagem`
- `Importar`
- `Relatórios`

### 11.3 Fluxo principal

1. usuário entra em `Pedidos`
2. a rota inicial abre a listagem com limite inicial de 20
3. a tela mantém filtros e botões de `Importar Pedido` e `Relatórios`
4. o usuário pode abrir a consulta detalhada do pedido
5. a consulta detalhada deve espelhar `./lunalo/pedidos/consultar?id_loja={id}&id_colecao={id}`
6. dentro da consulta, o usuário pode chamar edição quando autorizado
7. no fluxo de importação, após leitura do arquivo, ocorre a associação de fornecedor quando necessário

### 11.4 Observação

Este módulo deve ser um dos mais fiéis ao `Lunalô` no comportamento, mas usando shell, sidebar e experiência base do `Easy`.

---

## 12. Fluxo do módulo Purchases

### 12.1 Estrutura esperada

```text
Compras
  -> listagem
  -> importar
  -> relatórios
  -> detalhe da compra
  -> vincular item
  -> alterar status
```

### 12.2 Regras de navegação

O módulo deve espelhar `./lunalo/compras`.

No sidebar do módulo:

- `Listagem`
- `Importar`
- `Relatórios`

### 12.3 Fluxo principal

1. usuário entra em `Compras`
2. a rota inicial abre a listagem
3. o usuário pode iniciar `Importar Compra`
4. a tela de importação deve ser um formulário único, sem tabs
5. o formulário de importação deve prever ao menos:
  - marca
  - loja
  - coleção
  - `xml_nota`
  - `pdf_nota`
6. o modelo antigo do `Lunalô` com múltiplos imports separados não deve ser repetido
7. após importar, o usuário revisa vínculo de item, status e detalhe da compra
8. salva e retorna à listagem ou ao detalhe

---

## 13. Fluxo do módulo Tickets

### 13.1 Estrutura esperada

```text
Tickets
  -> listagem
  -> lançar
  -> relatórios
  -> detalhe
  -> decisão / distribuição
  -> anexos
```

### 13.2 Regras de navegação

O módulo deve espelhar completamente `./lunalo/tickets`.

No sidebar do módulo:

- `Listagem`
- `Lançar`
- `Relatórios`

### 13.3 Fluxo principal

1. usuário entra em `Tickets`
2. acessa a listagem ou inicia um lançamento
3. abre ticket existente ou cria novo
4. no cadastro, a seleção de mix deve usar o preço mais recente
5. se o mesmo item existir em mais de uma coleção, o sistema deve permitir ao usuário escolher a coleção correta
6. o usuário entra no detalhe
7. define decisão e distribuição financeira
8. trabalha com anexos quando necessário
9. salva e retorna ao detalhe ou à listagem

### 13.4 Observação

Os anexos fazem parte do fluxo de tickets e não devem ser esquecidos no desenho.

---

## 14. Fluxo do módulo Royalties

### 14.1 Estrutura esperada

```text
Royalties
  -> listagem
  -> lançar
  -> relatórios
  -> detalhe da ficha
  -> vincular compras
  -> vincular abatimentos
  -> anexos
```

### 14.2 Regras de navegação

O módulo deve espelhar `./lunalo/royalties`.

No sidebar do módulo:

- `Listagem`
- `Lançar`
- `Relatórios`

### 14.3 Fluxo principal

1. usuário entra em `Royalties`
2. consulta fichas ou lança nova
3. abre o detalhe da ficha
4. vincula compras
5. vincula abatimentos
6. revisa valores
7. trabalha com anexos
8. fecha ou atualiza a ficha

### 14.4 Observação

Neste módulo existe uma diferença importante em relação ao `Lunalô`:

- os tickets não carregarão preço desmembrado desde a origem
- no momento da dedução, o sistema deverá fazer o desmembramento necessário entre os componentes da taxa

---

## 15. Tipos de tela padrão

Cada módulo deve reutilizar um pequeno conjunto de padrões.

### 15.1 Tela inicial de módulo

Função:

- apresentar rapidamente o módulo
- exibir atalhos de entrada
- oferecer caminho para consulta e ação

### 15.2 Tela de consulta

Função:

- listar registros
- aplicar filtros
- permitir abrir detalhe

### 15.3 Tela de detalhe

Função:

- mostrar um registro com contexto suficiente
- permitir ações autorizadas

### 15.4 Tela de cadastro/edição

Função:

- criar ou alterar registro
- devolver feedback

### 15.5 Tela de processamento

Função:

- suportar importações e rotinas operacionais

### 15.6 Tela de relatório

Função:

- receber filtros
- gerar artefato
- permitir download ou visualização

Observação:

- não existe módulo global de relatórios
- relatórios ficam dentro de cada módulo

---

## 16. Fluxos transversais importantes

### 16.1 Fluxo de busca

Regra:

- módulos transacionais devem ter entrada por consulta
- a consulta costuma ser o ponto de retorno após qualquer ação

### 16.2 Fluxo de feedback

Regra:

- toda ação relevante deve retornar com feedback visível
- sucesso, erro e processamento precisam ficar claros

### 16.3 Fluxo de compartilhamento

Aplicável principalmente a:

- mixes
- anexos
- fichas de royalties
- relatórios dos próprios módulos

Fluxo genérico:

1. abrir detalhe
2. escolher compartilhar
3. selecionar canal
4. confirmar
5. retornar com feedback

### 16.4 Fluxo de erro

As telas de erro devem existir no padrão do `Easy`:

- não autenticado
- sem permissão
- não encontrado
- erro interno

Regra de experiência:

- a aplicação nunca deve quebrar a experiência do usuário final
- toda falha precisa degradar com segurança e mensagem clara

---

## 17. Ordem sugerida de desenho das telas

Para construção da aplicação, a ordem mais segura é:

1. Login
2. Main
3. Shell autenticado com header + sidebar
4. `Mixes`
5. `Books`
6. `Pedidos`
7. `Compras`
8. `Tickets`
9. `Royalties`

Justificativa:

- o esqueleto de navegação precisa nascer antes, no padrão do `Easy`
- a `main` precisa nascer cedo porque organiza a entrada do produto
- os módulos centrais continuam sendo `Pedidos`, `Compras`, `Tickets` e `Royalties`

---

## 18. Conclusão

O fluxo de telas do `Axys-Gestor / SL` deve seguir esta lógica:

- entrar como `Easy`
- navegar como `Easy`
- operar como `Gestor`

Em termos práticos:

- o `Easy` fornece a estrada pavimentada
- o `Lunalô` ajuda a decidir para onde essa estrada precisa levar

O próximo passo natural é detalhar a árvore real de rotas e telas por módulo.
