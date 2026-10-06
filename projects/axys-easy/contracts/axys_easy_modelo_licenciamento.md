# AxysEasy --- Modelo de Licenciamento, Capacidade e Consumo

**Status:** decisão arquitetural e comercial\
**Escopo:** AxysEasy + integração AxysHub

## 1. Princípio central

O AxysEasy não força todos os produtos a uma única métrica de licença.
Cada aplicativo é licenciado segundo a natureza da unidade de trabalho
que entrega.

Existem três modelos:

1.  **capacidade recorrente**: quantidade de ativos disponíveis para
    trabalho simultâneo;
2.  **uso isolado**: unidade consumida em evento específico, declarado e
    auditável;
3.  **Axys Intelligence**: créditos consumidos por operações de IA.

Conclusão, reabertura, revisão, emissão e outros estados internos do
orçamento não são eventos de licenciamento.

> **Você paga pela capacidade que usa, não pelo tamanho da sua equipe.**

> **A assinatura controla capacidade atual, não histórico acumulado.**

> **Nos usos isolados, a rigidez acontece na partida. Depois que a
> unidade de trabalho foi constituída, o usuário tem liberdade para
> trabalhar nela.**

------------------------------------------------------------------------

## 2. Produtos recorrentes

Aplicativos recorrentes trabalham continuamente sobre uma obra/ativo.
Exemplos: Easy Orça, ProjectManager, BuildDiary, FinControl e outros com
a mesma natureza.

A licença responde apenas:

> **Quantos ativos este tenant pode manter disponíveis para trabalho ao
> mesmo tempo?**

Faixas comerciais possíveis:

  Plano         Capacidade
  ----------- ------------
  Starter          1 ativo
  2               2 ativos
  5               5 ativos
  10             10 ativos
  Unlimited      ilimitado

Não existe contador canônico de ativações, arquivamentos, revisões,
conclusões ou reaberturas.

A mensalidade mantém o direito à capacidade contratada. Ela não concede
"N cliques" ou "N trocas" por mês.

------------------------------------------------------------------------

## 3. Empreendimento e ativo

O **empreendimento** é agrupador de negócio e pode possuir um ou mais
ativos.

``` text
Empreendimento
└── 1..N Ativos
```

O **ativo** é a unidade operacional dos apps recorrentes.

Cadastrar empreendimentos, por si só, não deve consumir capacidade. A
capacidade é ocupada por ativos disponíveis para trabalho.

No fluxo padrão, criar um empreendimento cria automaticamente seu
primeiro ativo. Havendo capacidade, esse ativo nasce disponível para
edição.

Exemplo Starter:

``` text
Antes: 0/1
Cria empreendimento + primeiro ativo: 1/1
Nova frente operacional: bloqueada enquanto estiver 1/1
```

------------------------------------------------------------------------

## 4. Disponível para trabalho x arquivado

A nomenclatura de interface ainda pode ser refinada. A semântica é:

### Disponível para trabalho

-   ocupa uma unidade da capacidade;
-   permite edição;
-   permite revisões;
-   opera normalmente nos módulos licenciados.

### Arquivado

-   não ocupa capacidade;
-   preserva dados, histórico e revisões;
-   não permite alterações enquanto arquivado;
-   pode voltar ao trabalho quando houver capacidade.

Arquivar e restaurar não são consumo e não possuem contador comercial.

Nos apps recorrentes, **não consomem capacidade adicional**: concluir,
reabrir, criar R1/R2/R3, corrigir RT, alterar BDI, atualizar preços,
alterar quantitativos, ajustar cronograma, reemitir documentos, arquivar
ou restaurar.

Esses eventos pertencem ao domínio funcional, não ao billing.

------------------------------------------------------------------------

## 5. Produtos de uso isolado

Produtos de uso isolado possuem um evento inequívoco de consumo.

Esse evento deve ser:

-   explícito;
-   deliberado;
-   transacional;
-   auditável;
-   idempotente;
-   definido individualmente por produto.

Depois do consumo, os **dados estruturantes** daquela unidade são
congelados. O usuário pode continuar trabalhando dentro dela, mas não
transformá-la em outra unidade de trabalho.

> **A rigidez fica na constituição da unidade de trabalho, não no
> trabalho posterior.**

Cada produto declara seu contrato:

``` yaml
produto:
  modelo_licenciamento: uso_isolado
  unidade_consumo: <unidade>
  evento_consumo: <evento>
  exige_confirmacao: true
  dados_congelados:
    - <campo_estruturante>
  operacoes_pos_consumo:
    - <operacao_permitida>
```

Não existe um evento universal de consumo para todos os apps.

------------------------------------------------------------------------

## 6. Easy Price

A unidade comercial do Price é uma **geração paramétrica**.

``` text
Parâmetros-base
→ prévia/validação
→ confirmação
→ CONSUMO
→ congelamento dos parâmetros estruturantes
→ trabalho livre dentro da geração
```

Depois da confirmação, parâmetros que caracterizam a geração não podem
ser trocados para transformar aquela unidade em outra obra. Tipo de
empreendimento, área e demais entradas estruturantes do motor devem ser
definidos pelo contrato do Price.

O usuário continua podendo ligar/desligar recursos, personalizar
elementos, recalcular preços e alterar dados não estruturantes.

Nova obra ou novos parâmetros estruturantes significam nova geração e
novo uso.

------------------------------------------------------------------------

## 7. Easy CPU

A unidade comercial do CPU nasce da **importação confirmada de um
orçamento-base**.

``` text
Upload
→ leitura/validação
→ prévia
→ confirmação
→ CONSUMO
→ congelamento do orçamento-base
→ bancada de análise
```

O upload bruto não precisa consumir. O consumo ocorre no ponto
contratualmente declarado, preferencialmente após validação e
confirmação.

Depois disso, o usuário trabalha naquela bancada: analisa itens, preços,
referências, composições próprias e demais recursos permitidos.

O orçamento-base não pode ser substituído integralmente por outro. Outro
orçamento-base = nova importação = novo uso.

------------------------------------------------------------------------

## 8. Axys Intelligence

**Axys Intelligence** constitui uma terceira categoria comercial.

Créditos de IA utilizam a mesma infraestrutura transacional dos usos
isolados:

-   saldo canônico no Hub;
-   evento de consumo declarado;
-   auditoria local no Easy;
-   idempotência;
-   atualização via API;
-   rastreabilidade.

Créditos de IA não são licença de aplicativo.

Um tenant pode possuir simultaneamente:

``` text
Easy Orça: capacidade 2
Easy CPU: 3 usos
Axys Intelligence: 150 créditos
```

Cada recurso de IA declara sua própria regra de consumo. O custo poderá
ser fixo ou variável sem alterar esta arquitetura.

------------------------------------------------------------------------

## 9. AxysHub como autoridade comercial

O Hub é autoridade canônica de:

-   identidade e autenticação;
-   tenant;
-   produtos contratados;
-   licenças vigentes;
-   capacidade contratada;
-   saldo de usos isolados;
-   saldo Axys Intelligence;
-   situação financeira e modo de acesso.

``` text
Usuário
→ AxysHub
→ autenticação + tenant + entitlements
→ AxysEasy
```

O Easy não replica o sistema comercial do Hub. Ele aplica localmente os
direitos recebidos.

### 9.1. Entitlements no JWT

Este não é um segundo token nem uma API paralela de licenciamento. É o
**mesmo JWT do login/SSO Hub → Easy**, definido em
`EASY_HUB_LICENCIAMENTO.md` e emitido com `aud = "easy"`. Esta seção apenas
substitui o formato antigo do claim `licencas`; identidade, assinatura,
issuer, audience, validade e transporte do login continuam os mesmos.

O claim `licencas` usa `app` com slug canônico e não repete labels que o
Easy já conhece. Exemplos:

``` json
{
  "licencas": [
    {
      "app": "easy-orca",
      "model": "capacity",
      "plano": "5",
      "status": "ACTIVE",
      "capacity": 5,
      "periodo_inicio": "2026-10-01",
      "periodo_fim": "2026-11-01"
    },
    {
      "app": "easy-cpu",
      "model": "usage",
      "plano": "10",
      "status": "ACTIVE",
      "remaining": 7,
      "periodo_inicio": "2026-10-01",
      "periodo_fim": "2026-11-01"
    }
  ]
}
```

`model` aceita `capacity` ou `usage`; `status` aceita `ACTIVE`,
`VIEW_ONLY` ou `BLOCKED`. Unlimited é representado por `capacity: null`
ou `remaining: null`. O Hub não envia os aliases antigos `modelo`, `label`
ou `app_labels`.

------------------------------------------------------------------------

## 10. Recorrência: Hub concede, Easy aplica

Para apps recorrentes, o Hub informa a capacidade.

``` json
{
  "app": "easy-orca",
  "model": "capacity",
  "capacity": 5
}
```

O Easy conhece os ativos do seu domínio e verifica a ocupação.

``` text
Hub: capacidade contratada = 5
Easy: ativos em trabalho = 4
Resultado: pode abrir mais 1 frente
```

O Hub não precisa manter contador transacional de arquivamentos ou
restaurações.

A ocupação corrente pertence ao domínio operacional do Easy.

### 10.1. A ocupação é por licença/produto

Empreendimento não ocupa capacidade. O slot nasce no **ativo**, somente
quando esse ativo é colocado em andamento dentro de um produto recorrente.

A capacidade não forma um saldo comum entre produtos. Exemplo: Orça 5 e
Docs 5 significam até 5 ativos em andamento no Orça e até 5 ativos em
andamento no Docs. Não significam 10 slots transferíveis livremente entre
os dois produtos.

Essa separação é necessária para que preço, upgrade, downgrade, suspensão
e auditoria continuem objetivos por licença. Um produto não pode consumir
silenciosamente a capacidade ociosa comprada para outro.

#### Tabela proposta: `ativo.ativo_produto_status`

Esta tabela está **aprovada como direção conceitual**, mas permanece
**proposta técnica a ser revisada pelo time do Easy**. Antes da migration,
o time deve validar nomes, tipos, FKs, índices, concorrência e os pontos do
código que ativam ou arquivam um ativo em cada produto. Depois da revisão,
o desenho definitivo deve ser incorporado ao contrato e ao schema canônico
do Easy.

| Coluna proposta | Finalidade |
|---|---|
| `atv_id` | ativo compartilhado do Easy |
| `tenant_uuid` | isolamento e índice por tenant |
| `product_code` | produto operacional: `ORC`, `DOC`, `PM`, `LIC`, `BDR` ou `FIN` |
| `license_product_code` | licença que suporta o slot; normalmente igual a `product_code` |
| `status` | `EM_ANDAMENTO` ou `ARQUIVADO` |
| `activated_at` | primeira ativação no produto |
| `archived_at` | quando deixou de ocupar slot |
| `updated_at` | última transição |
| `updated_by_user_uuid` | ator da transição, quando houver |

A chave natural é `(atv_id, product_code)`. Não deve existir um segundo ID
sem função própria. `tenant_uuid` deve corresponder obrigatoriamente ao
tenant do ativo.

Regras:

- criar empreendimento não cria vínculo nem ocupa slot;
- criar o cadastro-base do ativo, isoladamente, não ocupa slot;
- a primeira operação que colocar o ativo em andamento em um produto cria
  ou reativa o respectivo vínculo;
- arquivar no produto libera apenas o slot daquele produto;
- concluir, revisar, reabrir, recalcular ou emitir documento não gera novo
  consumo enquanto o vínculo continuar `EM_ANDAMENTO`;
- ativação e restauração executam, na mesma transação, lock por
  `(tenant_uuid, license_product_code)`, contagem e alteração do vínculo;
- o Hub nunca escreve nessa tabela e nunca escolhe qual ativo arquivar.

O **Easy One** é a exceção comercial explícita: seus módulos usam
`license_product_code = 'ONE'`. A ocupação de ONE é a quantidade de
`atv_id` distintos em andamento sob essa licença. O mesmo ativo usado em
Orça e Docs dentro do Easy One ocupa um único slot ONE; ativos diferentes
ocupam slots diferentes. Se o tenant também possuir licença avulsa, a
origem do direito fica registrada em `license_product_code`, sem soma ou
transferência implícita de capacidade.

### 10.2. API de ocupação para downgrade

O downgrade nasce no dashboard/processo comercial do Hub. Antes de alterar
uma licença de capacidade, o Hub consulta o Easy:

``` http
GET /api/internal/licensing/occupancy?tenant_uuid=<uuid>&product=<app_slug>
Authorization: Basic base64(EASY_HUB_CLIENT_ID:EASY_HUB_CLIENT_SECRET)
Accept: application/json
```

Exemplo:

``` http
GET /api/internal/licensing/occupancy?tenant_uuid=7847...&product=easy-orca
```

Resposta `200`:

``` json
{
  "tenant_uuid": "7847...",
  "product": "easy-orca",
  "em_andamento": 3
}
```

O parâmetro `product` é obrigatório e deve identificar uma licença de
capacidade. A resposta nunca soma produtos diferentes. Para `easy-one`, a
contagem segue a regra de ativos distintos definida acima.

Erros: `400` para produto inválido, `401` para credencial server-to-server
inválida e `5xx` para indisponibilidade operacional. Se o Easy não responder
ou devolver resposta inválida, o Hub **não efetiva** o downgrade.

As credenciais comunicantes atuais são reutilizadas. No Easy chamam-se
`EASY_HUB_CLIENT_ID` e `EASY_HUB_CLIENT_SECRET`; no Hub correspondem a
`EASY_SSO_CLIENT_ID` e `EASY_SSO_CLIENT_SECRET`. Não existe segredo novo
para licenciamento.

### 10.3. Pedido de alteração de capacidade no Hub

O comando comercial é interno ao Hub e objetivo por licença:

``` http
POST /api/licencas/capacidade
Content-Type: application/json
```

``` json
{
  "tenant_uuid": "7847...",
  "product_code": "ORC",
  "capacity": 5,
  "plan_code": "5"
}
```

`capacity: null` e `plan_code: "unlimited"` representam Unlimited. Essa
rota deve exigir sessão/alçada administrativa ou fluxo comercial interno
do Hub; a credencial do Easy não concede licença nem altera capacidade.
Ao receber o comando, o Hub resolve `product_code` para o `app_slug`, chama
a API de ocupação, recusa com `409` se a ocupação exceder o novo limite e
só então atualiza aquela licença. Upgrade pode ser imediato, mas continua
objetivado pelo mesmo `product_code`.

### 10.4. Invalidação imediata no Easy

Depois de efetivar capacidade ou modo de acesso, o Hub avisa o Easy para
que uma sessão já aberta não espere o JWT expirar.

``` http
POST /api/internal/licensing/capacity
Authorization: Basic base64(EASY_HUB_CLIENT_ID:EASY_HUB_CLIENT_SECRET)
Content-Type: application/json
```

``` json
{
  "tenant_uuid": "7847...",
  "app": "easy-orca",
  "capacity": 5
}
```

Para Unlimited, `capacity` é `null`.

``` http
POST /api/internal/licensing/access-mode
Authorization: Basic base64(EASY_HUB_CLIENT_ID:EASY_HUB_CLIENT_SECRET)
Content-Type: application/json
```

``` json
{
  "tenant_uuid": "7847...",
  "app": "easy-orca",
  "access_mode": "VIEW_ONLY"
}
```

`access_mode` aceita `ACTIVE`, `VIEW_ONLY` ou `BLOCKED`. `app` identifica
a licença alterada; somente uma transição comercial deliberadamente global
pode enviá-lo nulo. O Easy responde `200` com `ok: true` e mantém a
sobrescrita até a emissão de um JWT atualizado ou até o TTL máximo do token.
Falha na notificação não desfaz silenciosamente a alteração comercial: o
Hub registra a falha e mantém uma operação reexecutável com o mesmo estado.

------------------------------------------------------------------------

## 11. Uso isolado: Hub mantém o saldo

Nos usos isolados, o saldo é comercial e canônico no Hub.

``` text
Saldo antes: 3
Consumo confirmado: 1
Saldo depois: 2
```

O Easy registra auditoria própria do evento e comunica o Hub.

A auditoria deve conter, no mínimo:

-   tenant;
-   usuário;
-   produto/recurso;
-   unidade de trabalho;
-   data/hora;
-   evento de consumo;
-   quantidade;
-   saldo conhecido antes;
-   saldo confirmado depois;
-   identificador idempotente;
-   status da sincronização;
-   confirmação realizada por;
-   erro, quando houver;
-   metadados necessários à investigação.

Fluxo:

``` text
Easy identifica evento
→ valida
→ registra evento auditável
→ envia ao Hub via API
→ Hub valida idempotência e saldo
→ Hub efetiva consumo
→ Hub devolve saldo atualizado
→ Easy registra confirmação
```

Retries, timeouts, duplo clique ou repetição de request jamais podem
gerar consumo duplicado.

### 11.1. API canônica de consumo

O Easy comunica o evento confirmado ao Hub por:

``` http
POST /api/licencas/consumos
Authorization: Basic base64(EASY_HUB_CLIENT_ID:EASY_HUB_CLIENT_SECRET)
Idempotency-Key: <chave única e estável do evento>
Content-Type: application/json
Accept: application/json
```

As credenciais são o mesmo par server-to-server já usado entre Easy e Hub,
com os nomes correspondentes definidos na seção 10.2.

Payload:

``` json
{
  "tenant_uuid": "7847...",
  "user_uuid": "a40b...",
  "product_code": "PRI",
  "resource_id": "geracao-uuid-ou-id-estavel",
  "event_type": "generation_confirmed",
  "quantity": 1,
  "metadata": {}
}
```

Contratos iniciais por produto:

- Easy Price: `product_code = "PRI"` e
  `event_type = "generation_confirmed"`;
- Easy CPU: `product_code = "CPU"` e
  `event_type = "base_budget_import_confirmed"`.

`user_uuid` pode ser nulo em processamento técnico, mas `tenant_uuid`,
`product_code`, `resource_id`, `event_type`, `quantity` e
`Idempotency-Key` são obrigatórios. A mesma chave repetida com os mesmos
dados devolve o resultado anterior; reutilizá-la com dados diferentes é
erro. Upload, prévia e validação não são eventos de consumo.

Resposta `200`:

``` json
{
  "remaining": 4,
  "idempotent": false
}
```

Em plano Unlimited, `remaining` é `null`. Em retry já confirmado,
`idempotent` é `true` e o saldo não sofre novo débito.

Erros: `400` para contrato inválido ou conflito de idempotência, `401` para
credencial inválida e `402` para saldo insuficiente. Timeout ou `5xx`
mantém o evento pendente no Easy e exige retry com a mesma chave.

------------------------------------------------------------------------

## 12. Auditoria não é saldo

Separação obrigatória:

-   **Hub:** saldo canônico;
-   **Easy:** evidência operacional do evento;
-   **Hub:** trilha comercial correspondente;
-   **ambos:** mesmo identificador de correlação/idempotência.

A auditoria do Easy não substitui o saldo do Hub. O saldo do Hub não
substitui a evidência operacional do Easy.

------------------------------------------------------------------------

## 13. Política comercial de renovação, inadimplência e suspensão (responsabilidade do HUB, aqui, nos cabe respeitar e seguir)

A inadimplência não apaga dados, não arquiva ativos e não altera o histórico. Ela modifica progressivamente o **modo de acesso** concedido pelo Hub.

O ciclo canônico é:

```text
RENOVAÇÃO NÃO PROCESSADA
        ↓
D+1 até D+7 — período de regularização
        ↓
D+7 — suspensão das funcionalidades
        ↓
até 30 dias — acesso congelado / somente visualização
        ↓
fim do 30º dia — bloqueio de acesso à plataforma
        ↓
180+ dias — sujeito à futura política de retenção e sanitização
```

### 13.1. D+1 a D+7 — período de regularização

Do primeiro ao sétimo dia após a falha de renovação, o tenant permanece operacional.

Durante esse período:

- o Hub envia **uma comunicação por dia** informando que houve problema na renovação;
- a mensagem informa que as funcionalidades poderão ser suspensas caso a situação não seja regularizada;
- o Easy continua operando normalmente enquanto o Hub mantiver o entitlement ativo durante a tolerância;
- a regularização interrompe o fluxo de suspensão.

A comunicação deve ser clara e progressiva, sem tratar a primeira falha de cobrança como cancelamento imediato.

### 13.2. Final do sétimo dia — suspensão operacional

Não havendo regularização até o encerramento do período de tolerância:

1. o Hub altera o modo de acesso do tenant;
2. o Hub envia comunicação informando a suspensão das funcionalidades;
3. o Hub comunica o Easy para invalidar o contexto operacional vigente;
4. sessões ativas devem ser encerradas ou forçadas a renovar autenticação/autorização;
5. no próximo acesso, o usuário entra diretamente no modo de consulta congelada.

O objetivo do encerramento das sessões não é apagar autenticação ou dados, mas impedir que uma sessão previamente autorizada continue editando após a mudança de entitlement.

O estado conceitual passa de:

```text
ACTIVE
```

para:

```text
VIEW_ONLY
```

### 13.3. VIEW_ONLY — até 30 dias após a suspensão

Durante o período de consulta, o tenant continua podendo entrar no Easy e visualizar aquilo que já produziu.

Pode:

- autenticar;
- acessar o tenant;
- navegar pelos empreendimentos;
- abrir ativos;
- visualizar dados;
- visualizar histórico;
- visualizar revisões e resultados existentes.

Não pode:

- editar qualquer dado;
- criar empreendimento operacional;
- criar ativo;
- restaurar ativo para trabalho;
- criar revisão;
- executar cálculos;
- gerar novos resultados;
- consumir usos isolados;
- consumir Axys Intelligence;
- exportar;
- baixar documentos;
- baixar arquivos;
- utilizar qualquer operação que produza nova saída persistente.

A experiência deve deixar evidente que o ambiente está **congelado por suspensão da licença**, sem transmitir a ideia de perda dos dados.

O prazo máximo desse estado é de **30 dias**.

### 13.4. Após 30 dias — bloqueio de acesso

Encerrado o período de consulta sem regularização, o tenant deixa de ter acesso ao AxysEasy.

O estado conceitual passa para:

```text
BLOCKED
```

Nesse estágio:

- o login no ecossistema pode continuar existindo no Hub, conforme os demais produtos do tenant;
- o entitlement do Easy não permite entrada na aplicação;
- os dados permanecem armazenados conforme a política de retenção vigente;
- a regularização futura poderá restabelecer o acesso conforme a política comercial aplicável.

O bloqueio de acesso não equivale à exclusão dos dados.

### 13.5. Hub resolve; Easy executa

A situação financeira não deve ser interpretada independentemente por cada microapp.

Evitar:

```text
Easy consulta pagamento → Easy decide bloquear
```

Preferir:

```text
Hub processa situação comercial
→ Hub resolve entitlement/access_mode
→ Easy recebe o estado
→ Easy aplica as permissões
```

Estados mínimos:

```text
ACTIVE
VIEW_ONLY
BLOCKED
```

O Hub é responsável pela transição comercial. O Easy é responsável por garantir tecnicamente que as permissões daquele estado sejam respeitadas.

---

## 14. Política futura de retenção e sanitização

A suspensão de licença e o bloqueio de acesso **não autorizam, por si só, exclusão de dados**.

Deve existir documento próprio de **Política de Retenção e Sanitização de Dados**, a ser definido posteriormente.

Essa política deverá avaliar especialmente tenants com assinatura vencida há mais de **180 dias**, incluindo:

- quais dados permanecem preservados;
- quais dados podem ser congelados ou movidos para armazenamento de retenção;
- quais dados podem ser eliminados;
- quais registros devem permanecer por auditoria, obrigação legal, fiscal, contratual ou segurança;
- anonimização quando aplicável;
- tratamento de arquivos em object storage;
- backups e prazo de expurgo;
- possibilidade e condições de recuperação;
- comunicação prévia ao cliente;
- efeitos de uma eventual reativação posterior.

**O marco de 180 dias é, neste documento, um gatilho para avaliação pela futura política de retenção. Não constitui autorização automática de exclusão.**

---

## 15. Regra de criação automática

Nos apps recorrentes, a experiência inicial deve ser direta:

``` text
Criar empreendimento
→ criar primeiro ativo automaticamente
→ verificar capacidade
→ disponibilizar para trabalho
```

O bloqueio acontece antes da constituição de uma nova frente operacional
sem capacidade.

Empreendimentos puramente cadastrais podem existir sem ocupar
capacidade, desde que não constituam unidade operacional disfarçada.

------------------------------------------------------------------------

## 16. Princípio comercial

O modelo deve ser comunicado como flexibilidade, não restrição.

O cliente não paga pelo número de funcionários nem precisa contratar uma
estrutura maior que sua operação.

> **Escolha a capacidade que acompanha o seu volume de obras.**

> **Seu plano acompanha suas obras, não o tamanho da sua equipe.**

> **Pague pela capacidade que sua operação realmente utiliza.**

> **Uma obra por vez ou várias ao mesmo tempo: o Easy acompanha o seu
> ritmo.**

Para produtos isolados:

> **Use quando precisar. Pague pelo uso que fizer.**

Essa é a unidade filosófica do portfólio: modelos diferentes, mas todos
orientados ao uso real do cliente.

------------------------------------------------------------------------

## 17. Matriz canônica

  --------------------------------------------------------------------------
  Categoria         Unidade comercial    Canônico          Evento/regra
  ----------------- -------------------- ----------------- -----------------
  Apps recorrentes  capacidade de ativos Hub concede; Easy ativo disponível
                                         mede ocupação     para trabalho

  Easy Price        geração paramétrica  Hub mantém saldo  confirmação da
                                                           geração

  Easy CPU          importação/bancada   Hub mantém saldo  confirmação da
                                                           importação

  Axys Intelligence créditos IA          Hub mantém saldo  evento declarado
                                                           por recurso
  --------------------------------------------------------------------------

------------------------------------------------------------------------

## 18. O que não deve existir

Evitar:

-   contador canônico para apps recorrentes;
-   cobrança por conclusão;
-   cobrança por reabertura;
-   cobrança por revisão;
-   cobrança por emissão;
-   reset artificial de "usos" mensais em apps de capacidade;
-   saldo comercial autoritativo duplicado no Easy;
-   regras financeiras hardcoded nos microapps;
-   evento genérico de consumo aplicado indistintamente a todos os
    produtos;
-   alteração de dados estruturantes após consumo isolado;
-   consumo não idempotente.

------------------------------------------------------------------------

## 19. Decisões e nomenclatura de estado

O modelo central está fechado, mas alguns parâmetros devem permanecer
configuráveis:

1. **Nome de interface do estado operacional do ativo.**  
 - Status: Em andamento
 - Status: Arquivado

2. **Contrato estruturante de cada produto isolado:** exatamente quais campos congelam no Price, CPU e futuros apps.
 - Price: Será apartado do Orça (atual bancada). faremos um acesso isolado com comportamento isolado, mas usando as mesmas tabelas e premissas. As permissões de uso é o que determina o comportamento do front. Como é um orçamento estimativo com base em parâmetros onde, o momento da contagem vai ser, após preencher os dados que são usados no motor paramétrico, abre uma simulacao resumida e aviso duro: "Deseja avançar no orçamento paramétrico? Ao avançar, será computado o uso não será possível alterar mais os dados básicos de área e infraestrutura do ativo, podendo apenas ser manipulado itens e/ou etapas.
 - CPU:  Mesma premissa do Price. A diferença é que, ele nasce importado de uma planilha xls/xlsx. Ao importar, deve ser exibido um diff em tela, registrando os dados que vem do sintético. O user consegue subir a planilha e baixar no mesmo modal (ou local específico) para conferencia. Mesma mensagem rígida. Deseja avançar para o detlahamento das composições? Ao avançar será computado o uso e não será possível excluir ou adicionar itens, limitando-se a manipular preços de insumos e/ou composicoes de serviços.

3. **Tabela de consumo do Axys Intelligence:** quais ações custam créditos e em qual quantidade.
 - O Axys Intelligence utilizará como unidade de consumo o AxysCoin (AXC). Sua referência econômica será fixa: 1.000 AXC equivalem a US$ 1,00 de custo computacional de inteligência artificial.
 - O consumo de cada operação será apurado pelo custo efetivo da requisição ao provedor, considerando entrada, saída e demais recursos cobrados pela API. A equivalência é direta: uma operação com custo de US$ 0,10 consome 100 AXC; US$ 0,50 consome 500 AXC; US$ 1,00 consome 1.000 AXC.
 - A Axys controlará internamente os limites de entrada e saída de cada operação, inclusive limitando a resposta dos modelos quando necessário. A composição entre tokens de entrada, saída, modelos ou provedores não precisa ser exposta ao usuário, pois o AXC representa o custo computacional consolidado.
 - O AXC será comercializado exclusivamente em reais. Sua cotação será definida periodicamente, inicialmente uma vez por semana, e permanecerá válida para as recargas realizadas durante sua vigência.
 - A formação do preço considera o custo efetivo do dólar para a Axys, incluindo câmbio, IOF e spread aplicável. Sobre ele incidem três componentes: AX1 = 10%, destinado à cobertura de risco cambial e variações de custo; LUCR = 10%, margem inicial do Axys Intelligence; e TRIB = 10%, provisão inicial para tributos incidentes sobre o faturamento.
 - Fórmula de formação: CUSTDIR = custo efetivo do dólar × (1 + AX1) e preço de venda de 1.000 AXC = [CUSTDIR × (1 + LUCR)] / (1 - TRIB). A cotação será arredondada para cima em três casas decimais.
 - Exemplo: com custo efetivo do dólar de R$ 5,10, o CUSTDIR será R$ 5,610 e 1.000 AXC serão comercializados por R$ 6,857.
 - A recarga mínima será de R$ 10,00. No momento da compra, a cotação vigente determina definitivamente a quantidade de AXC creditada. Alterações posteriores da cotação não modificam o saldo já adquirido.
 - Toda operação que consumir AXC será precedida de confirmação em tela, apresentando consumo estimado, saldo atual e saldo previsto após a operação, com aviso de que o consumo final poderá variar ligeiramente conforme o processamento efetivamente realizado.
 - Finalizada a operação, será debitado o consumo efetivo. Será admitido pequeno saldo negativo exclusivamente quando decorrente da diferença entre estimativa e consumo real, limitado por tolerância técnica a ser definida. Saldo negativo impede o início de nova operação até nova recarga.
 - O Hub mantém o saldo canônico de AXC. O Easy registra a estimativa, confirmação, consumo efetivo e demais dados de auditoria e comunica o consumo ao Hub de forma transacional e idempotente.
 - A compra de AXC constitui aquisição de créditos pelo cliente e deve seguir o fluxo comercial e fiscal aplicável. A política financeira deverá buscar correspondência entre a venda dos créditos e o provisionamento/aquisição do respectivo custo computacional, reduzindo a exposição da Axys à variação cambial entre a recarga e o consumo futuro.
 - A cotação vigente do AxysCoin será pública e apresentada de forma simples, por exemplo: “Cotação da semana: 1.000 AXC = R$ 6,857”.
 - Ressalva: No login, o HUB informa o saldo. Mas como é multi-tenancy e multi-app, pode haver redução. Portanto, toda vez que, em tela, for requisitar algo, tem que bater no HUB e atualizar o saldo antes de rodar. Rodou, enfileira comunicacao via api com idempotencia e fallback de falha. O hub precisa registrar de qualquer jeito o usp.

4. **Liberdade e uso da IA fora do ambiente Axys Inteligence**
 - O uso do **Axys Intelligence não será obrigatório** para funcionalidades que possam ser executadas externamente por meio de modelos de inteligência artificial.
 - Sempre que tecnicamente aplicável, o Easy poderá oferecer ao usuário a opção de **gerar e baixar/copiar um prompt de requisição**, permitindo que ele utilize uma ferramenta de IA de sua preferência sem consumir AxysCoins.
 - O prompt disponibilizado para uso externo será funcional e deverá conter informações suficientes para produzir resultado útil, mas poderá ser **simplificado em relação à inteligência proprietária utilizada pelo Axys Intelligence** (prompt empobrecido, mas não ruim e inútil), não incluindo necessariamente toda a engenharia de prompt, contexto, processamento, validações, agentes, tratamentos ou rotinas internas da Axys.
 - O resultado obtido externamente será de responsabilidade do usuário, inclusive quanto à escolha do modelo, ajustes realizados no prompt, custos do provedor externo e qualidade da resposta.
 - O **Axys Intelligence** agrega valor pela conveniência e integração: prepara o contexto, executa a requisição, utiliza a inteligência proprietária da Axys, recebe e trata a resposta e, quando aplicável, concilia os resultados diretamente com os dados do Easy.
 - Dessa forma, a cobrança adicional está associada ao **serviço integrado de inteligência**, e não à restrição artificial do acesso do usuário às suas próprias informações ou à possibilidade de utilizar outras ferramentas.
 - Frases comerciais de efeito: 
    a. Use a inteligência do Easy ou leve o contexto com você. A escolha é sua. 
    b. A Axys facilita o caminho. Não limita suas escolhas.

5. **Comportamento de downgrade:** 
 - O downgrade é solicitado pelo usuário no dashboard do AxysHub e sempre identifica uma licença/produto. Antes de efetivá-lo, o Hub consulta a API do Easy para verificar a quantidade atual de ativos em andamento especificamente naquele produto, conforme seção 10.2.
 - O downgrade somente poderá ser concluído quando a quantidade de ativos em andamento for igual ou inferior à capacidade do novo plano.
 - Caso a capacidade pretendida seja inferior à ocupação atual, o downgrade não será realizado e o usuário será orientado a arquivar os ativos que não deseja mais manter em andamento.
 - Mensagem sugerida: “Existem atualmente XX ativos em andamento. Para alterar seu plano para XX ativos, arquive os ativos concluídos ou que não precisam permanecer em andamento e tente novamente.”
 - A escolha dos ativos que permanecerão em andamento é sempre responsabilidade do usuário. O Hub e o Easy nunca arquivam ativos automaticamente para viabilizar um downgrade.
 - Após a adequação, uma nova solicitação consulta novamente o Easy e, estando a ocupação dentro do limite pretendido, o Hub pode prosseguir com a alteração do plano.


6. **Política de Retenção e Sanitização de Dados:** 
 - Encerrado o período de acesso decorrente da assinatura, os dados do tenant permanecerão armazenados pelo período de retenção contratual correspondente ao plano: 30 dias para uso único, 60 dias para planos de até 10 ativos e 120 dias para planos Unlimited.
 - Além da retenção divulgada e contratada, a Axys manterá uma margem interna de recuperação, atualmente definida em +30 dias para uso único, +60 dias para planos de até 10 ativos e +60 dias para Unlimited. Essa margem constitui política interna de segurança e recuperação, não integra o prazo garantido ao cliente e poderá ser alterada.
 - Os períodos de retenção e margem de recuperação deverão ser parametrizados, evitando regras fixas no código.
 - Encerrada também a margem de recuperação, os dados poderão ser removidos do banco operacional e convertidos em arquivo histórico estruturado e versionado, armazenado em ambiente próprio de arquivamento. O arquivo deverá preservar informações suficientes para permitir eventual restauração no schema vigente por processo controlado da Axys.
 - A sanitização do banco operacional somente poderá ocorrer após confirmação da geração, integridade e persistência segura do arquivo histórico.
 - Os arquivos históricos seguirão classes progressivas de retenção, conceitualmente archive_y1, archive_y2 e archive_y3. Ao final da última classe, os dados tornam-se elegíveis para expurgo, observadas as obrigações legais, fiscais, contratuais, de auditoria e proteção de dados aplicáveis. O vencimento de uma classe de retenção não implica exclusão automática.
 - Enquanto existir arquivo histórico recuperável, a Axys poderá oferecer serviço técnico de restauração de dados, executado internamente e sujeito a cobrança. A restauração não será realizada diretamente pelo usuário e poderá integrar políticas comerciais de reativação, inclusive com condições ou descontos vinculados à retomada da assinatura
 - Não será mantido banco operacional paralelo para tenants inativos. O arquivamento histórico será independente da estrutura física corrente do banco, permitindo sua posterior interpretação e reimportação controlada mesmo após evoluções do schema.
 - Os períodos indicados deverão ser variáveis de banco e serem movimentadas, ao critério da Axys. Inicialmente, vamos persistir isso em tabelas seedads, sem registros em front.
 - Os workers de sanitização precisam ser desenvolvidos após primeiras vendas e ficam registrados como pendência.

------------------------------------------------------------------------

## 20. Regra mental final

``` text
RECORRENTE
Quantas frentes posso manter trabalhando?
→ capacidade

USO ISOLADO
Quantas novas unidades posso constituir?
→ saldo + evento de consumo + congelamento

AXYS INTELLIGENCE
Quanto processamento inteligente posso consumir?
→ créditos + evento auditável

HUB
O que o cliente comprou e ainda possui?
→ autoridade comercial

EASY
O que está acontecendo dentro da unidade de trabalho?
→ autoridade operacional
```

**Síntese:**

> **O Hub concede direitos. O Easy aplica capacidade. Eventos isolados
> consomem saldo. A IA consome créditos. O histórico nunca é confundido
> com consumo.**
