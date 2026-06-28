# Easy CPU™ — MVP

## Objetivo

Transformar um orçamento existente em orçamento referenciado e precificado utilizando bases oficiais.

## Fluxo

### 1. Cadastro

Usuário:

* cria empreendimento;
* cria ativo;
* define UF;
* define BDI.

Leis sociais permanecem vinculadas à fonte oficial.

### 2. Importação

Usuário acessa:

Orçamento → Importar Orçamento

Formatos:

* Excel;
* CSV.

### 3. Processamento

Sistema:

* interpreta estrutura do orçamento;
* identifica serviços;
* associa itens à base oficial;
* apresenta estrutura encontrada.

Usuário aprova a interpretação.
* ao aprovar, conta o uso.

### 4. Precificação

Sistema:

* rotaciona preços;
* aplica composição correspondente;
* gera orçamento precificado.

### 5. Itens não encontrados

Quando inexistentes:

* usuário pode cadastrar composição própria;
* composição passa a integrar catálogo próprio do tenant.

Não é permitido:

* alterar composições oficiais;
* alterar itens oficiais;
* alterar insumos oficiais.

### 6. Planejamento

Sistema habilita:

* cronograma físico-financeiro;
* distribuição mensal.

### 7. Finalização

Sistema gera:

* orçamento analítico;
* orçamento sintético;
* histograma de mão de obra;
* histograma de equipamentos;
* cronograma.

### Integrações

Caso possua Easy Docs ativo:

* gerar memorial do orçamento;
* gerar descrição dos serviços.

### Branding

Relatórios personalizados disponíveis através do Easy Branding.

### Consumo

Cada importação processada e aceita contabiliza um uso do plano contratado.

Trava: se user não acessar, ele apenas ve o modal e isso não tem valor. comercial.
