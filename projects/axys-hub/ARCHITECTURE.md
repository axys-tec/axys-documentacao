# AxysHub — Arquitetura, Escopo e Operação

**Status:** Ativo  
**Data:** 2026-06-16  
**Escopo:** documento canônico do Hub para arquitetura, contexto de produto, governança de acesso, integração com Easy, billing/Asaas e arquivamento por tenant.

---

## 1. Propósito

AxysHub é o núcleo do ecossistema Axys para:

- identidade;
- autenticação;
- autorização macro;
- licenciamento;
- gestão de tenants;
- gestão de usuários;
- billing e contrato;
- integração entre produtos.

O Hub é o sistema que decide:

- quem é o usuário;
- a qual tenant ele pertence naquele contexto;
- qual é o papel daquele vínculo;
- quais apps ele pode acessar;
- o que está contratado;
- quem pode afetar billing;
- quando o Easy deve arquivar ou restaurar dados.

---

## 2. Princípios

### 2.1 Fonte da verdade

O Hub é a fonte da verdade para:

- papéis;
- vínculo usuário ↔ tenant;
- vínculo usuário ↔ app;
- contrato;
- plano;
- licença;
- ações comerciais;
- contexto autenticado entregue às apps.

As apps do ecossistema não recalculam isso.

### 2.2 Tenant como entidade canônica

`tenant` é a unidade canônica de isolamento, governança, assinatura e contexto-alvo do ecossistema Axys.

Regras:

- tenant é o alvo primário resolvido pelo Hub;
- apps operacionais devem receber e respeitar `tenant_id`;
- o Easy continua isolado por `tenant_id`;
- `store` não substitui `tenant`;
- `store` não é obrigatória;
- `store` não entra no caminho crítico global.

Frase conceitual:

> Tenant isola. Store especializa somente quando o domínio exigir.

### 2.3 Store como extensão específica de domínio

`store` é uma entidade opcional para módulos que precisem representar unidades operacionais, lojas, filiais ou unidades de negócio.

Exemplo principal: `AxysGestor`.

Regras:

- um tenant pode existir sem store;
- user-by-tenant é a regra global;
- user-by-store só existe adicionalmente quando o tenant cria stores;
- store pode ser usada para operação local, licença ou unidade de negócio, mas apenas nos módulos que adotarem esse domínio;
- store não deve contaminar módulos que não precisam dela.

### 2.4 Uma porteira, múltiplos contextos

O Hub tem **uma única porteira de login**.

Depois da autenticação, ele desvia o usuário para o contexto correto:

- `client` → `Client Portal`
- `internal` → `Internal Console`

No `Client Portal`, o login inicial é contextual por tenant.

Fluxo canônico:

```text
email + senha + CPF/CNPJ do tenant
↓
Hub resolve user + tenant
↓
entra diretamente naquele contexto
```

Na área logada, deve existir opção de `Trocar conta` ou `Trocar empresa` no header.

Essa ação:

- abre modal com a lista de tenants/empresas vinculadas ao usuário;
- exige escolha explícita da empresa de destino;
- exige confirmação com senha;
- encerra o contexto/sessão atual;
- cria nova sessão/JWT para o novo tenant;
- não mantém duas sessões de tenant abertas ao mesmo tempo no mesmo browser/contexto;
- deve ser auditável.

Texto conceitual:

> Trocar conta não é multi-sessão. É reautenticação contextual assistida.

Isso é natural para usuários vinculados a múltiplas empresas e não invalida o tenant como unidade canônica de isolamento e contexto.

### 2.5 Domínio antes de tela

Antes de crescer UI, o Hub precisa ter claro:

- escopo `client`;
- escopo `internal`;
- papéis;
- billing;
- licenciamento;
- integração com Asaas;
- contrato Hub ↔ Easy;
- política de arquivamento.

### 2.6 O Hub não inventa uma terceira linguagem visual

O padrão visual de referência do ecossistema é o **AxysEasy**.

O Hub pode ter conteúdo e prioridades próprias, mas não deve parecer um produto isolado do restante da plataforma.

---

## 3. Contextos do Produto

### 3.1 `Client Portal`

Portal administrativo do cliente/tenant.

Responsabilidades:

- auto-cadastro inicial;
- gestão dos dados cadastrais do cliente;
- gestão de usuários da conta;
- vínculo de usuários às apps contratadas;
- consulta de produtos/licenças;
- integrações;
- segurança;
- billing;
- histórico comercial/pedidos.

### 3.2 `Internal Console`

Console operacional interno da Axys.

Responsabilidades:

- governança do ecossistema;
- operação comercial;
- suporte operacional;
- gestão de tenants;
- contratos;
- visão administrativa e financeira interna;
- recursos internos.

### 3.3 Regra do contexto interno

O contexto `internal` existe em **um único tenant canônico**:

- `AXYS`

Não existe cenário-alvo com múltiplos tenants internos paralelos.

O seed inicial do Hub deve nascer com:

- tenant `AXYS`;
- usuários internos mínimos;
- vínculos internos mínimos;
- `internal_role` já atribuída no bootstrap.

---

## 4. Modelo de Identidade e Vínculos

### 4.1 User-by-tenant como regra global

O vínculo principal de acesso do Hub é:

- `hub_user`
- `hub_tenant`
- `hub_user_tenant`

Esse é o modelo global para autenticação, governança e acesso macro.

Regras:

- papéis canônicos de cliente no tenant: `owner`, `admin`, `user`;
- `viewer` pode existir no futuro, mas não faz parte do contrato atual;
- um usuário pode estar vinculado a múltiplos tenants;
- um usuário pode existir sem tenant ativo;
- perder vínculo com um tenant nunca apaga o cadastro global em `hub_user`.

### 4.2 User-by-store como regra adicional

Quando o domínio exigir, pode existir uma camada adicional:

- `hub_user_store`

Essa camada não substitui `hub_user_tenant`. Ela apenas restringe ou especializa a atuação do usuário em stores daquele tenant.

Regras:

- `user-store` só existe se `user-tenant` existir;
- store pertence a um tenant;
- role de store nunca concede acesso fora do tenant;
- ausência de `user-store` não bloqueia acesso global ao tenant, salvo no módulo que declarar store como obrigatória;
- `AxysGestor` pode exigir seleção de store;
- Easy não deve exigir store.

### 4.3 JWT, claims e contexto operacional

O claim canônico de contexto operacional é `tenant_id`.

`store_id` pode existir como claim opcional, apenas quando o app ou módulo exigir.

Modelo conceitual:

```json
{
  "user_id": "...",
  "tenant_id": "...",
  "store_id": null,
  "role": "admin",
  "is_staff": false,
  "apps_licenciadas": []
}
```

Regras:

- para módulos sem store, `store_id = null`;
- para módulos com store, `tenant_id` continua obrigatório e `store_id` representa a unidade operacional selecionada;
- o contrato conceitual usa `tenant_id` como nome canônico, ainda que integrações atuais possam expor `tenant_uuid` por compatibilidade de wire format.

---

## 5. Client Portal — Camada de atuação do cliente

### 5.1 Onboarding

No primeiro acesso, o cliente faz auto-cadastro público.

Esse fluxo deve obrigatoriamente:

- criar `hub_user`;
- criar `hub_tenant`;
- criar `hub_user_tenant` com role `owner`.

Regras:

- o cadastro exige dados da pessoa owner e dados do tenant;
- o tenant nasce sem store, salvo fluxo específico de app que a exija;
- stores não fazem parte obrigatória do onboarding global;
- autocadastro nunca cria role interna;
- autocadastro nunca cria acesso `internal`.

Fluxo desejado:

```text
cadastro público
↓
dados do usuário owner
↓
dados do tenant
↓
cria tenant
↓
cria user
↓
cria user_tenant owner
↓
entra no Client Portal
```

No estado atual do contrato, esse acesso já nasce contextualizado no tenant resolvido pelo Hub, sem seletor interno adicional.

### 5.2 Conta e dados cadastrais

O cliente pode editar dados pessoais e dados cadastrais do tenant.

Exemplos de dados pessoais:

- nome;
- telefone;
- WhatsApp;
- senha;
- preferências básicas;
- dados de recuperação.

Exemplos de dados do tenant:

- razão social ou nome;
- nome fantasia;
- documento fiscal, quando permitido;
- endereço;
- contatos;
- e-mails administrativos;
- dados de cobrança não críticos.

Dados sensíveis devem ficar fora do self-service pleno e exigir tratativa interna.

Exemplos:

- troca de CNPJ principal;
- alteração estrutural de titularidade;
- mudança de owner;
- alteração manual de plano fora do billing.

### 5.3 Usuários e convites

A criação de novo usuário cliente deve ser baseada em convite:

1. owner ou admin informa o e-mail;
2. define a role inicial;
3. o Hub envia o convite;
4. o convidado completa o próprio perfil.

Regras:

- o convidado não cria tenant;
- owner ou admin não preenche cadastro completo de terceiro;
- convite pode expirar, ser reenviado e ser cancelado;
- convite pendente não consome cota;
- o tenant pode enviar convites acima da cota contratada;
- a trava de cota ocorre na ativação ou no aceite do convite, não no envio;
- usuário ativo consome cota;
- usuário bloqueado, removido ou inativado não consome cota;
- usuário pode ser removido do tenant sem ser apagado de `hub_user`;
- usuário removido pode cair em zona neutra se não tiver outro tenant.

Exemplo contratual:

- plano com 5 usuários pode ter 10 convites pendentes;
- os 5 primeiros aceites ativam normalmente;
- o 6º aceite deve ser bloqueado até haver vaga ou upgrade de plano.

Regra antiabuso:

- bloqueio ou inativação libera cota;
- o tenant só pode fazer 1 swap de usuário por mês, por vaga/licença;
- swap adicional no mês exige upgrade, liberação interna ou procedimento comercial.

O critério técnico exato de contagem do swap pode ser implementado depois, mas o princípio de antirodízio já fica contratado.

Permissões canônicas:

- `owner` pode convidar usuários, alterar roles, remover usuários, reenviar convite, bloquear vínculo e ver usuários do tenant;
- `admin` pode convidar usuários se o plano permitir, alterar usuários abaixo do seu nível e remover usuários abaixo do seu nível;
- `admin` não remove owner e não troca owner;
- `user` acessa apps licenciados conforme permissão e edita apenas o próprio perfil.

Troca de `owner` não é self-service direto.

Direção atual:

- não cabe botão simples no Client Portal;
- pode existir, no máximo, uma solicitação formal de suporte;
- cenários como owner indisponível, saída da empresa, perda de acesso, falecimento ou conflito societário exigem procedimento formal assistido pela Axys;
- validação documental, por e-mail e/ou por fluxo assistido conforme política futura;
- registro formal e auditável da troca;
- efetivação pela `Internal Console` ou por intervenção técnica controlada;
- no primeiro momento, pode nem haver tela dedicada para isso;
- se houver tela futura, ela deve ficar em camada alta de privilégio: `internal_admin` ou `internal_owner`.

### 5.4 Assinatura, billing e licenças

O Client Portal deve permitir ao cliente consultar:

- plano atual;
- assinatura;
- status da assinatura;
- apps contratados;
- apps licenciados;
- limite de usuários;
- uso atual de usuários;
- histórico de pedidos;
- faturas;
- pagamentos;
- eventos comerciais relevantes.

Ações comerciais previstas:

- contratar app;
- contratar plano;
- solicitar upgrade;
- solicitar downgrade;
- cancelar assinatura, conforme regra comercial;
- atualizar dados de cobrança;
- acessar faturas;
- consultar status de pagamento.

Regras:

- cliente não altera billing em sentido administrativo pelo `Client Portal`;
- `owner` e `admin` podem visualizar informações de assinatura, plano, faturas, apps licenciados e histórico de pedidos;
- apenas `owner` pode iniciar fluxos comerciais previstos, como contratação, upgrade, downgrade ou cancelamento, conforme regras futuras de billing;
- alteração manual de cobrança, suspensão, renegociação, provisão, exclusão ou modificação de algo em curso não pertence ao `Client Portal`;
- essas ações pertencem à `Internal Console`;
- billing é responsabilidade do Hub;
- apps operacionais não calculam billing;
- apps operacionais apenas recebem contexto resolvido;
- licença pode ser por tenant ou, em módulos específicos, por store;
- Easy opera por tenant;
- `AxysGestor` pode operar por store ou licença por unidade.

### 5.5 Zona neutra

Zona neutra é a área do usuário autenticado sem tenant ativo ou sem contexto resolvido para entrada.

Cenários:

- usuário perdeu vínculo com tenant;
- convite ainda não aceito;
- convite expirado;
- usuário foi removido;
- usuário tem conta global, mas nenhum tenant;
- usuário tem múltiplos tenants e precisa trocar para outro contexto de empresa;
- tenant suspenso ou bloqueado.

Zona neutra deve permitir:

- aceitar convite pendente;
- solicitar reenvio de convite;
- criar novo tenant próprio;
- visualizar status da conta;
- solicitar suporte;
- fazer logout.

Quando o usuário já estiver autenticado e possuir múltiplos vínculos, a troca de empresa deve ocorrer preferencialmente pela ação `Trocar conta` ou `Trocar empresa` na área logada, e não pela zona neutra.

Regras:

- usuário sem tenant não acessa app operacional;
- usuário sem tenant não perde cadastro global;
- esse estado é válido no domínio do Hub, não erro fatal.

---

## 6. Internal Console

O detalhamento do `Internal Console` fica como próxima etapa contratual.

Premissa já decidida:

- acesso `internal` exige `is_staff = true`;
- o usuário precisa de vínculo ativo com o tenant interno `AXYS`;
- esse vínculo deve portar role `internal_*`.

O domínio interno ainda será aprofundado depois, principalmente em recursos, vendas, contratos, suporte operacional e administração do ecossistema.

---

## 7. Papéis Canônicos

### 7.1 Papéis do tenant cliente

| Papel | Descrição | Pode conceder admin? | Pode visualizar billing? | Pode iniciar fluxos comerciais previstos? |
|---|---|---|---|---|
| `owner` | Dono da conta/tenant. Nível máximo do cliente. | Sim | Sim | Sim |
| `admin` | Administrador operacional do tenant. | Não | Sim | Não |
| `user` | Usuário operacional. | Não | Não | Não |

### 7.2 Papéis internos Axys

| Papel | Descrição |
|---|---|
| `internal_user` | Operador interno; executa rotina operacional e inspeções permitidas |
| `internal_financeiro` | Supervisor financeiro/operacional; trata renegociações, provisões, ajustes ordinários de cobrança e rotinas de cobrança |
| `internal_admin` | Gerente; executa ações administrativas sensíveis, reversões, suspensões, correções de estado e procedimentos internos de maior impacto |
| `internal_owner` | Diretor/dono; reservado para decisões acima da alçada gerencial, com impacto em margem, markup, perdão de dívida, perdas relevantes e exceções comerciais máximas |

Cadeia alvo para escala futura de billing/operação interna:

- `internal_user`: operação interna comum; pode inspecionar e executar liberações simples conforme política;
- `internal_financeiro`: supervisor financeiro/operacional; pode tratar renegociações, provisões, ajustes ordinários de cobrança e rotinas de cobrança;
- `internal_admin`: gerente; pode executar ações administrativas sensíveis, reversões, suspensões, correções de estado e procedimentos internos de maior impacto;
- `internal_owner`: diretor/dono; reservado para decisões que impactam markup, perdão de dívida, perdas financeiras relevantes, exceções comerciais máximas e matérias acima da alçada gerencial.

Decisões de negócio já contratadas:

- atividades de gerente pertencem a `internal_admin`;
- atividades acima de gerente/diretoria pertencem a `internal_owner`;
- renegociar cobrança pode ser `internal_financeiro`;
- perdoar dívida, conceder perda relevante ou impactar markup pertence a `internal_owner`;
- suspender, excluir ou modificar algo em curso com impacto operacional relevante pertence a `internal_admin` ou superior;
- a app deve ser preparada para colaboradores executarem o dia a dia sem receber decisões que afetem margem, markup ou exceções comerciais máximas.

No primeiro momento, o projeto pode operar apenas com:

- `internal_user`;
- `internal_financeiro`;
- `internal_owner`.

Para o Easy, por enquanto, `internal_user` e `internal_financeiro` podem cair na mesma regra prática de acesso interno. A distinção já fica documentada para governança futura do Hub/Billing.

### 7.3 Regras sensíveis

- apenas `owner` pode conceder/remover privilégio administrativo no tenant cliente;
- `admin` não promove alguém a `admin` ou `owner`;
- `admin` não executa alteração administrativa de billing em curso;
- `user` não afeta billing;
- regras funcionais finas dentro das apps não pertencem ao Hub;
- o Hub define o papel macro, a app define a matriz funcional interna dela.

---

## 8. Billing, Licenciamento e Vínculo Usuário ↔ App

### 8.1 Quem afeta billing

No `Client Portal`, apenas `owner` inicia fluxos comerciais previstos.

Isso inclui:

- contratar;
- renovar;
- trocar plano;
- comprar expansão;
- executar ações com impacto comercial previsto no portal.

`admin` pode visualizar billing, mas não executa alteração administrativa nem inicia fluxo comercial sensível no contrato atual.

Na camada interna, ações fora do fluxo comercial previsto pertencem à `Internal Console`, conforme segregação entre `internal_user`, `internal_financeiro`, `internal_admin` e `internal_owner`.

### 8.2 O que o `user` ainda pode fazer

`user` pode operar o que já foi contratado e consumir usos/saldos, mas não altera contrato.

### 8.3 Vínculo usuário ↔ app

Não basta o tenant possuir a licença.

O Hub também resolve:

- a quais apps cada usuário daquele tenant pode entrar.

O Easy recebe o resultado, não inventa esse acesso.

### 8.4 Cotas de usuários por assinatura

| Assinatura | Limite | Composição base |
|---|---|---|
| `single-use` | 1 | `owner` |
| `starter` | 2 | `owner + 1 user` |
| `advanced` | 4 | `owner + 1 admin + 2 users` ou `owner + 3 users` |
| `unlimited` | 5 base | `owner + 1 admin + 3 users` ou `owner + 4 users` |

Para mais de 5 usuários:

- apenas sobre `unlimited`;
- com billing específico de expansão.

Regra contratual de consumo de cota:

- a cota de usuários do tenant considera apenas usuários ativos;
- convite pendente não consome cota;
- usuário bloqueado, removido ou inativado deixa de consumir cota;
- o tenant pode enviar convites acima da cota contratada;
- a trava ocorre na ativação/aceite do convite, não no envio;
- quando a cota estiver cheia, novos aceites devem ser bloqueados até haver vaga, upgrade de plano ou liberação interna;
- não haverá excedente implícito no `Client Portal`.

Princípio antiabuso:

- bloquear ou inativar um usuário libera cota;
- cada vaga/licença admite apenas 1 swap de usuário por mês;
- swap adicional no mês exige upgrade, liberação interna ou procedimento comercial;
- a fórmula exata de contagem do swap pode ser definida depois, mas o princípio contratual de impedir rodízio artificial já está fixado.

---

## 9. Integração Hub ↔ Easy

### 9.1 Princípio

O Easy não é dono de:

- papéis;
- billing;
- limites de usuários;
- vínculo usuário ↔ app;
- política comercial;
- decisão de arquivamento.

O Easy consome o contexto autenticado resolvido pelo Hub.

### 9.2 Claims e payload

O Hub entrega ao Easy, por usuário/contexto:

- `tenant_id` como contexto canônico;
- `role`
- `tenant_role`
- `is_staff`
- `apps_licenciadas`
- `licencas`
- identidade do usuário
- tenant atual

Quando a integração atual ainda usar `tenant_uuid` no payload, isso deve ser tratado como compatibilidade transitória de wire format, não como mudança do modelo canônico.

### 9.3 Interpretação do Easy

O Easy deve assumir:

- apps ausentes do payload = sem acesso;
- `is_staff` = contexto interno Axys;
- billing e expansão pertencem ao Hub.

Detalhes do handshake SSO:

- [integrations/sso-login-easy.md](integrations/sso-login-easy.md)

---

## 10. Catálogo do Hub e o lugar do Gestor

### 10.1 Produtos vendáveis

No estado atual, o Hub trata como catálogo principal:

- AxysPro
- AxysGestor
- apps Easy

### 10.2 O que não é produto vendável

Não devem aparecer como produto comercial:

- `AxysHub`
- `AxysSystem`
- `API_GESTOR`

### 10.3 Regra do Gestor

`AxysGestor` é o produto.

`API_GESTOR` é apenas capacidade técnica vinculada a ele, não produto/licença separada.

---

## 11. Billing e Asaas

### 11.1 Direção já tomada

O Hub trabalhará com **integração de recebimentos via Asaas**.

O desenho comercial do Hub deve considerar o Asaas como canal principal de cobrança.

Nesta etapa, o documento não entra no desenho detalhado do Asaas.

Billing/Asaas deve ser tratado como frente própria posterior, pois conecta:

- `Client Portal`;
- `Internal Console`;
- cobrança;
- webhooks;
- assinaturas;
- licenças;
- liberações.

### 11.2 Pontos ainda em aberto

- checkout direto, proposta ou ambos;
- ciclo canônico de ativação;
- expansão de usuários e apps;
- inadimplência;
- webhooks;
- reflexo em assinatura/licença;
- visão interna de recebíveis, falhas e conciliações.

Sem essas respostas, o Hub não deve congelar telas profundas de billing.

---

## 12. Arquivamento por Tenant — fronteira Hub ↔ Easy

### 12.1 Princípio

O Hub manda; o Easy executa.

O Easy não decide:

- quando arquivar;
- quando restaurar;
- quando purgar;
- qual é a política de inatividade;
- qual é a cobrança para reconstrução.

### 12.2 O que o Hub precisa definir

- política de inatividade;
- cadência da varredura;
- gatilho de arquivamento;
- gatilho de reconstrução;
- gatilho de purga;
- cobrança na reconstrução;
- contrato de chamada Hub → Easy.

### 12.3 O que o Easy executa

- `desconstruir(tenant_uuid)`
- `reconstruir(tenant_uuid)`

O Easy guarda o payload frio e executa a limpeza/reidratação do banco quente quando o Hub mandar.

---

## 13. Estado Atual no Código

Hoje o código do Hub está assim:

- `/app/*` funciona como portal autenticado principal com foco `client`;
- `/console` existe como camada `internal` mínima;
- `is_staff` já é contextual por tenant;
- o contrato Hub → Easy já sai no molde novo;
- o catálogo do portal já respeita a separação entre produto vendável e estrutura interna;
- o Gestor já foi consolidado tecnicamente no Hub.

Isso é suficiente para seguir evoluindo sem travar operação, mas ainda não representa o desenho final completo do domínio interno e comercial.

---

## 14. Banco de Dados

Estrutura principal do Hub:

- `hub_user`
- `hub_tenant`
- `hub_user_tenant`
- `hub_store`
- `hub_user_store`
- `hub_plano`
- `hub_assinatura`
- `hub_licenca`
- `hub_user_app`
- `hub_api_registry`
- `hub_api_client`
- `hub_api_key`
- `hub_microapp_instance`
- `hub_microapp_config`
- `hub_auth_token`
- `hub_login_log`

Referências:

- [schemas/schema.sql](schemas/schema.sql)
- [schemas/seed.sql](schemas/seed.sql)
- [adrs/HUB-ADR-001-seed-minimo-inicial.md](adrs/HUB-ADR-001-seed-minimo-inicial.md)

---

## 15. Estado da Documentação

### 15.1 Documento canônico

Este arquivo é a referência principal do Hub para:

- escopo;
- arquitetura;
- contexto `client`/`internal`;
- governança de acesso;
- billing;
- integração com Easy;
- arquivamento por tenant.

### 15.2 Organização recomendada do diretório

Papel dos diretórios do projeto:

- `adrs/` → decisões pontuais e imutáveis
- `integrations/` → handshake técnico entre sistemas
- `schemas/` → banco, seed e migração
- `operations/` → deploy, restore, runbooks
- `api/` → endpoints do Hub
- `ARCHITECTURE.md` → visão canônica consolidada do produto Hub

Enquanto o Hub mantiver contrato consolidado, `ARCHITECTURE.md` permanece como ponto canônico e arquivos avulsos de contrato devem ser evitados.

---

## 16. Próximos Passos

1. revisar o seed final para o banco novo pós-drop;
2. modelar o domínio `Internal`;
3. definir billing/Asaas;
4. fechar regra de produtos por obra ativa (`BuildDiary` e `FinControl`);
5. só então aprofundar evolução de telas.

---

## 17. Referências

- [README.md](README.md)
- [integrations/sso-login-easy.md](integrations/sso-login-easy.md)
- [integrations/with-easy.md](integrations/with-easy.md)
- [adrs/](adrs/)
- [schemas/schema.sql](schemas/schema.sql)
- [schemas/seed.sql](schemas/seed.sql)
