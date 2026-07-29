# Contrato Geral — Axys-Gestor

## 1. Contexto do projeto

O projeto começou sendo desenvolvido como um serviço específico para atendimento às operações de lojistas vinculados à marca Santa Lolla.

Esse primeiro produto, provisoriamente denominado **GestorSL**, possui escopo relativamente delimitado:

* planejamento e gerenciamento de coleções;
* realização e acompanhamento de pedidos;
* controle de recebimentos;
* conferência e controle de royalties;
* abertura e acompanhamento de tickets;
* futuras integrações com os sistemas utilizados pela rede Santa Lolla.

Embora o GestorSL seja uma aplicação de pequeno ou médio porte, o problema atendido não é isolado. Existem outras operações com necessidades semelhantes, mas com regras, integrações e processos próprios.

Entre os produtos previstos estão:

* **GestorSL**, destinado às operações relacionadas à Santa Lolla;
* **GestorLoccitane**, destinado às operações relacionadas à L’Occitane;
* **Gestor**, produto de apoio gerencial aplicável a diferentes segmentos, redes e sistemas de origem.

O Gestor poderá atender empresas que utilizem diferentes ERPs e plataformas, como Seta, Ascont, Multisystem e outros sistemas que venham a ser integrados futuramente.

Portanto, o projeto deve ser pensado desde o início como uma família de produtos relacionados, e não como uma única aplicação genérica na qual todas as particularidades sejam misturadas.

---

## 2. Premissa de produto

GestorSL, GestorLoccitane e Gestor são três produtos distintos.

Eles podem compartilhar:

* tecnologias;
* infraestrutura;
* autenticação;
* componentes técnicos;
* rotinas de integração;
* bibliotecas;
* funcionalidades reutilizáveis;
* padrões de interface;
* modelos operacionais semelhantes.

Entretanto, cada produto possui:

* finalidade própria;
* regras de negócio próprias;
* conjunto próprio de funcionalidades;
* integrações específicas;
* ciclo próprio de evolução;
* possíveis condições comerciais e de licenciamento diferentes.

Consequentemente, uma funcionalidade existente em um produto não deve ser automaticamente considerada parte dos demais.

Por exemplo, o controle de royalties da Santa Lolla não deve ser tratado como uma regra genérica de royalties da plataforma. Ele pertence ao domínio do GestorSL, ainda que futuramente possam existir estruturas reutilizáveis para cálculos, documentos ou conferências de royalties.

Da mesma forma, uma funcionalidade específica da L’Occitane deve permanecer isolada no produto GestorLoccitane.

---

## 3. Decisão arquitetural orientadora

O projeto será desenvolvido em uma base tecnológica coordenada, mas com separação explícita entre:

1. funcionalidades compartilhadas;
2. funcionalidades específicas do GestorSL;
3. funcionalidades específicas do GestorLoccitane;
4. funcionalidades específicas do Gestor.

A estrutura do backend deverá refletir essa separação.

Exemplo conceitual:

```text
app/
├── shared/
├── sl/
├── loccitane/
└── gestor/
```

Cada diretório representa uma fronteira arquitetural.

```text
shared
```

Contém funcionalidades tecnicamente reutilizáveis por dois ou mais produtos.

```text
sl
```

Contém tudo que pertence exclusivamente ao GestorSL.

```text
loccitane
```

Contém tudo que pertence exclusivamente ao GestorLoccitane.

```text
gestor
```

Contém tudo que pertence exclusivamente ao produto Gestor.

A existência de uma única base de código não significa que os três produtos formem um único domínio de negócio. A organização interna deve impedir que as regras específicas sejam misturadas ou compartilhadas de maneira acidental.

---

## 4. Nome do diretório compartilhado

Entre nomes como:

```text
linear
common
mutual
shared
```

o termo tecnicamente mais adequado, neste momento, é:

```text
shared
```

A palavra `shared` comunica diretamente que o diretório contém recursos compartilhados entre produtos.

`common` também seria possível, mas tende a se transformar em um diretório genérico no qual são colocados arquivos sem domínio bem definido.

`mutual` não é uma nomenclatura comum para organização de código.

`linear` transmite a ideia de transversalidade concebida para o projeto, mas não é um termo arquitetural imediatamente compreensível para novos desenvolvedores.

Portanto, a recomendação inicial é:

```text
app/shared/
```

Entretanto, o diretório `shared` não deve funcionar como depósito de código genérico. Cada funcionalidade compartilhada deve possuir domínio, responsabilidade e contrato próprios.

Exemplo:

```text
app/
├── shared/
│   ├── card_reconciliation/
│   ├── notifications/
│   ├── integrations/
│   ├── files/
│   └── audit/
├── sl/
├── loccitane/
└── gestor/
```

Outra possibilidade, caso se queira enfatizar que se trata de funcionalidades de negócio reutilizáveis, seria:

```text
app/capabilities/
```

Nesse caso, cada pasta representaria uma capacidade oferecida a diferentes produtos:

```text
app/
├── capabilities/
│   ├── card_reconciliation/
│   ├── sales_notifications/
│   └── purchase_planning/
├── products/
│   ├── sl/
│   ├── loccitane/
│   └── gestor/
```

Essa nomenclatura é arquiteturalmente forte, mas também mais abstrata. Para o estágio atual, `shared` é mais simples e imediatamente compreensível.

---

## 5. Exemplo: conciliador de cartões

O conciliador de cartões não pertence necessariamente ao Gestor, ao GestorSL ou ao GestorLoccitane.

Ele é uma capacidade independente que pode ser habilitada em qualquer produto.

Sua estrutura poderia ser:

```text
app/
└── shared/
    └── card_reconciliation/
        ├── domain/
        ├── application/
        ├── infrastructure/
        ├── providers/
        │   ├── getnet/
        │   ├── interpag/
        │   ├── c6/
        │   └── stone/
        └── api/
```

Em uma organização inicialmente mais simples:

```text
app/
└── shared/
    └── card_reconciliation/
        ├── models.py
        ├── schemas.py
        ├── repository.py
        ├── service.py
        ├── routes.py
        └── providers/
            ├── getnet.py
            ├── interpag.py
            ├── c6.py
            └── stone.py
```

A conciliação deve possuir um contrato interno comum.

Exemplo conceitual:

```python
class CardReconciliationProvider:
    def import_transactions(self): ...
    def import_receivables(self): ...
    def import_settlements(self): ...
    def reconcile(self): ...
```

Cada operadora implementará esse contrato:

```text
GetnetProvider
InterpagProvider
C6Provider
StoneProvider
```

Os produtos consumidores não devem conhecer os detalhes internos de cada operadora.

O GestorSL, por exemplo, apenas solicita:

```text
executar conciliação da loja
```

A camada compartilhada identifica:

* qual é a operadora configurada;
* quais credenciais devem ser utilizadas;
* qual adaptador deve ser acionado;
* como os dados serão normalizados;
* como o resultado será devolvido.

---

## 6. Forma de consumo pelos produtos

As telas e serviços de cada produto poderão utilizar capacidades compartilhadas.

Exemplo:

```text
GestorSL
└── utiliza shared.card_reconciliation

GestorLoccitane
└── utiliza shared.card_reconciliation

Gestor
└── utiliza shared.card_reconciliation
```

A dependência deve ocorrer sempre nesta direção:

```text
produto → funcionalidade compartilhada
```

Não deve ocorrer:

```text
funcionalidade compartilhada → produto específico
```

Consequentemente, o conciliador compartilhado não pode importar regras internas de:

```text
sl
loccitane
gestor
```

Quando houver uma necessidade específica de determinado produto, ela deve ser implementada dentro do próprio produto, utilizando mecanismos de extensão, configuração ou eventos.

Exemplo:

```text
shared.card_reconciliation
    ↓ resultado da conciliação
sl.reconciliation_rules
    ↓ tratamento específico da Santa Lolla
```

Dessa forma, o núcleo compartilhado permanece reutilizável sem incorporar particularidades de uma marca.

---

## 7. Isolamento dos produtos no código

A separação deve alcançar mais do que os diretórios.

Cada produto deve possuir seus próprios:

* modelos de domínio;
* casos de uso;
* endpoints;
* permissões;
* regras de negócio;
* configurações;
* tarefas assíncronas;
* integrações específicas;
* testes;
* migrations, quando aplicável;
* feature flags;
* licenciamento.

Exemplo:

```text
app/
├── shared/
│   └── card_reconciliation/
│
├── sl/
│   ├── collections/
│   ├── orders/
│   ├── receiving/
│   ├── royalties/
│   ├── tickets/
│   └── integrations/
│       └── teceo/
│
├── loccitane/
│   ├── royalties/
│   ├── franchise_management/
│   └── integrations/
│
└── gestor/
    ├── sales_analysis/
    ├── inventory_turnover/
    ├── purchase_planning/
    ├── management_alerts/
    └── integrations/
        ├── seta/
        ├── ascont/
        └── multisystem/
```

Essa estrutura não é definitiva, mas demonstra a fronteira esperada entre os produtos.

---

## 8. Integrações não são necessariamente funcionalidades compartilhadas

É necessário distinguir:

* uma capacidade compartilhada;
* uma integração específica;
* uma implementação de fornecedor.

O conciliador de cartões é uma capacidade compartilhada.

Seus adaptadores Getnet, Interpag e C6 fazem parte dessa capacidade porque representam diferentes implementações do mesmo contrato.

Por outro lado, uma integração com a TECEO, caso seja utilizada exclusivamente pelo GestorSL, deve permanecer dentro de:

```text
sl/integrations/teceo
```

Uma integração com o Seta, destinada inicialmente ao Gestor, pode permanecer em:

```text
gestor/integrations/seta
```

Somente deverá ser promovida para `shared` quando houver reutilização concreta por mais de um produto.

Portanto, não se deve tornar algo compartilhado apenas porque existe a possibilidade futura de reaproveitamento.

A regra deve ser:

> Uma funcionalidade nasce no domínio que efetivamente a utiliza e somente é movida para a camada compartilhada quando o reaproveitamento for real, estável e conceitualmente correto.

Isso evita generalizações prematuras.

---

## 9. Serviço único não significa produto único

Inicialmente, os produtos podem ser executados em um único serviço FastAPI:

```text
gestor.axys-tec.com.br
```

Esse serviço pode expor rotas separadas:

```text
/api/shared/...
/api/sl/...
/api/loccitane/...
/api/gestor/...
```

Ou, preferencialmente, APIs versionadas e organizadas por produto:

```text
/api/v1/sl/...
/api/v1/loccitane/...
/api/v1/gestor/...
```

As capacidades compartilhadas não precisam necessariamente possuir endpoints públicos próprios. Em muitos casos, elas poderão ser utilizadas internamente pelos serviços de aplicação dos produtos.

Exemplo:

```text
POST /api/v1/sl/reconciliation/run
```

O endpoint pertence ao GestorSL, mas internamente chama:

```text
shared.card_reconciliation.run(...)
```

Isso preserva a identidade do produto na interface pública e a reutilização na implementação.

No futuro, caso determinado produto exija:

* escala independente;
* disponibilidade independente;
* equipe independente;
* banco independente;
* deploy independente;
* requisitos contratuais específicos;

seu backend poderá ser extraído para outro serviço com menor impacto, desde que as fronteiras internas tenham sido respeitadas desde o início.

---

## 10. Seleção do produto após o login

O acesso poderá ocorrer por um endereço comum:

```text
gestor.axys-tec.com.br
```

Após a autenticação, o sistema deverá identificar:

* tenants acessíveis;
* stores acessíveis;
* produtos licenciados;
* permissões do usuário em cada produto.

Um usuário com acesso a apenas um produto poderá ser direcionado diretamente para ele.

Um usuário com acesso a mais de um produto poderá visualizar uma porteira de seleção:

```text
Selecione o produto

[ GestorSL ]
[ GestorLoccitane ]
[ Gestor ]
```

Essa seleção representa produtos efetivamente diferentes, e não apenas módulos de um mesmo produto.

O contexto selecionado deverá acompanhar a sessão:

```text
tenant
store
product
```

Exemplo:

```text
tenant: Lunalô
store: Jales
product: sl
```

O produto selecionado determinará:

* menu;
* rotas disponíveis;
* permissões;
* funcionalidades;
* identidade visual complementar;
* regras de negócio;
* integrações disponíveis.

---

## 11. Banco de dados

A definição sobre um único banco ou bancos separados não precisa ser fechada exclusivamente com base na divisão comercial dos produtos.

É possível manter:

```text
um serviço
+
mais de um banco
```

Também é possível manter:

```text
um serviço
+
um banco
+
schemas separados
```

A decisão deverá considerar:

* isolamento necessário;
* compartilhamento de tenant e store;
* necessidade de consultas cruzadas;
* política de backup;
* migrations;
* custo operacional;
* possibilidade de extração futura;
* volume de dados;
* segurança;
* disponibilidade.

Caso seja utilizado um único banco, os produtos devem permanecer separados por schemas ou fronteiras equivalentes:

```text
shared
sl
loccitane
gestor
audit
integration
```

Exemplo:

```text
shared.card_transaction
shared.card_receivable
shared.reconciliation_run

sl.collection
sl.order
sl.royalty_statement
sl.ticket

loccitane.royalty_statement
loccitane.franchise_control

gestor.sales_fact
gestor.inventory_snapshot
gestor.purchase_plan
```

Dados organizacionais podem permanecer canônicos:

```text
organization.tenant
organization.store
identity.user
identity.user_tenant
identity.user_store
licensing.tenant_product
```

Ainda que sejam utilizados bancos separados, não se deve duplicar de maneira descontrolada a identidade de tenants, stores e usuários.

---

## 12. Premissa multisystem

O produto Gestor deverá ser multisystem.

Isso significa que suas funcionalidades não poderão depender diretamente da estrutura de um ERP específico.

Exemplo:

```text
Seta
Ascont
Multisystem
Outro ERP
```

Cada sistema poderá apresentar estruturas diferentes para:

* venda;
* produto;
* estoque;
* cliente;
* vendedor;
* contas a receber;
* formas de pagamento.

O Gestor deverá trabalhar sobre contratos internos padronizados.

Exemplo conceitual:

```text
Sistema externo
      ↓
Adaptador do sistema
      ↓
Modelo normalizado
      ↓
Funcionalidade do Gestor
```

Estrutura possível:

```text
gestor/
├── sales_analysis/
├── inventory_turnover/
├── purchase_planning/
└── integrations/
    ├── contracts/
    ├── seta/
    ├── ascont/
    └── multisystem/
```

O analisador de giro não deve conter regras espalhadas como:

```python
if source_system == "seta":
    ...
elif source_system == "ascont":
    ...
elif source_system == "multisystem":
    ...
```

Cada conector deve entregar os dados no formato esperado pelo domínio do Gestor.

---

## 13. Critério para classificação do código

Ao criar uma nova funcionalidade, deve-se responder às seguintes perguntas:

### A funcionalidade pertence a qual produto?

Caso pertença apenas à Santa Lolla:

```text
sl/
```

Caso pertença apenas à L’Occitane:

```text
loccitane/
```

Caso pertença apenas ao produto gerencial:

```text
gestor/
```

### A funcionalidade é utilizada por mais de um produto?

Caso exista reutilização concreta e a regra seja realmente comum:

```text
shared/
```

### A funcionalidade apenas parece parecida?

Nesse caso, não deve ser compartilhada automaticamente.

Duas rotinas podem possuir nomes semelhantes e regras diferentes.

Exemplo:

```text
sl.royalties
loccitane.royalties
```

Ambas tratam royalties, mas isso não significa que devam compartilhar o mesmo domínio.

Poderão compartilhar componentes menores, como:

```text
shared.document_import
shared.money_calculation
shared.statement_matching
```

desde que esses componentes sejam realmente neutros em relação ao produto.

---

## 14. Orientação final

A arquitetura deverá combinar:

* unidade tecnológica;
* separação de produto;
* reutilização controlada;
* integração multisystem;
* possibilidade de evolução independente.

A diretriz central é:

> GestorSL, GestorLoccitane e Gestor são produtos distintos, desenvolvidos sobre uma base tecnológica coordenada. As regras específicas permanecem isoladas por produto, enquanto funcionalidades efetivamente reutilizáveis são implementadas em uma camada compartilhada, independente e sem dependência dos produtos consumidores.

A estrutura inicial recomendada é:

```text
app/
├── shared/
├── sl/
├── loccitane/
└── gestor/
```

Com a seguinte regra de dependência:

```text
sl ──────────┐
loccitane ───┼──► shared
gestor ──────┘
```

Nunca:

```text
shared ──► sl
shared ──► loccitane
shared ──► gestor
```

Esse desenho permite iniciar o projeto com um serviço coordenado e operacionalmente simples, sem transformar os três produtos em um único domínio e sem impedir que qualquer um deles seja separado tecnicamente no futuro.
