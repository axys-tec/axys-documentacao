# AxysHub — Contrato de Acesso, Papéis e Governança Comercial

**Status:** Ativo  
**Data:** 2026-06-15  
**Escopo:** papéis do tenant, papéis internos Axys, governança de billing, vínculo usuário ↔ app e o que o AxysEasy pode assumir a partir disso.

---

## 1. Princípio

> **O Hub é o dono da identidade, do contrato comercial e da autorização macro.**  
> O Easy **não decide** papéis, cotas de usuários, billing, upgrades nem a que apps um usuário pode entrar.  
> O Easy **recebe do Hub** o contexto já resolvido do tenant e do usuário atual.

Isso vale para:
- papéis (`owner`, `admin`, `user`, `internal_*`);
- licença por tenant;
- acesso do usuário a cada app;
- cotas de usuários por assinatura;
- compra de expansão, upgrade e billing.

---

## 2. Papéis Canônicos

### 2.1 Papéis do tenant cliente

| Papel | Descrição | Pode conceder admin? | Pode afetar billing? |
|---|---|---|---|
| `owner` | Dono da conta/tenant. Nível máximo do cliente. | **Sim** | **Sim** |
| `admin` | Administrador operacional do tenant. | **Não** | **Sim** |
| `user` | Usuário operacional do tenant. | Não | Não |

### 2.2 Papéis internos Axys

| Papel | Descrição | Observação |
|---|---|---|
| `internal_owner` | Nível máximo interno Axys | Papel interno máximo emitido pelo Hub |
| `internal_admin` | Operação interna avançada | Papel interno administrativo emitido pelo Hub |
| `internal_user` | Uso interno comum | Sem poderes administrativos sensíveis |

### 2.3 Regras sensíveis

- Apenas `owner` pode conceder ou remover privilégio administrativo no tenant cliente.
- `admin` pode operar usuários e configurações do tenant **dentro do que já foi delegado**, mas **não pode promover alguém a `admin` ou `owner`**.
- `user` é o nível mais baixo da pirâmide e não afeta billing nem administração de acesso.
- O Hub define e emite os papéis canônicos (`internal_*`, `owner`, `admin`, `user`), mas **não dita a matriz funcional interna de cada app**.
- Regras como "quem publica", "quem reabre edição" ou qualquer outra permissão operacional fina pertencem ao **contrato/documentação da própria app**.

---

## 3. Billing e Ações Comerciais

### 3.1 Quem pode afetar billing

Somente perfis `owner` e `admin` podem afetar billing.

Isso inclui:
- contratar app;
- trocar plano;
- renovar;
- comprar expansão;
- executar ações de desarquivamento com impacto comercial;
- acessar área de comercial/contratação do Hub.

`user` não compra, não amplia plano e não altera contrato.

### 3.2 O que o `user` ainda pode fazer

`user` pode, conforme sua função e os apps liberados para ele:
- usar as apps às quais foi vinculado;
- produzir dados operacionais;
- consumir usos/saldos;
- abrir/fechar entidades operacionais que afetem o saldo funcional da app.

Ou seja: `user` pode impactar o **uso do que já foi contratado**, mas não o **contrato em si**.

### 3.3 Posição do `user` no portal Hub

No Hub, o `user` não tem uma camada administrativa robusta.

A experiência esperada para `user` é:
- um dashboard de acesso/teletransporte;
- visão dos próprios dados;
- entrada apenas nas apps às quais ele foi vinculado.

Ele não gerencia billing, não gerencia catálogo contratado e não governa permissões de outros usuários.

---

## 4. Vínculo Usuário ↔ App

### 4.1 Regra-mãe

Não basta o tenant ter a licença.  
O Hub também resolve **a quais apps cada usuário daquele tenant pode entrar**.

Exemplos válidos:
- usuário X pode entrar só no `Price`;
- usuário Y pode entrar em `Price` e `LicitPlan`;
- usuário Z pode entrar em `Orça`, mas não em `Docs`.

O Hub é responsável por esse vínculo e por entregá-lo ao Easy no contexto autenticado.

### 4.2 Responsabilidade

- `owner`/`admin` do tenant usam o portal Hub para vincular usuários às apps contratadas.
- O Easy não inventa nem amplia esse acesso.
- O Easy apenas respeita a lista de apps liberadas para o usuário atual.

---

## 5. Cotas de Usuários por Assinatura

As cotas de usuários são regra do Hub e devem ser aplicadas no portal administrativo.

### 5.1 Limites canônicos

| Assinatura | Limite | Composição permitida |
|---|---|---|
| `single-use` | **1 usuário** | `owner` apenas |
| `starter` | **2 usuários** | `owner + 1 user` |
| `advanced` | **4 usuários** | `owner + 1 admin + 2 users` **ou** `owner + 3 users` |
| `unlimited` | **5 usuários base** | `owner + 1 admin + 3 users` **ou** `owner + 4 users` |

### 5.2 Regras operacionais

- Em `single-use`, o Hub **não permite edição de perfis**.
- Em `starter`, o Hub **não permite edição de perfis administrativos**.
- Em `advanced`, passa a existir possibilidade de **1 admin**.
- Em `unlimited`, o pacote base permite até **5 usuários**.
- Para **mais de 5 usuários**, só é permitido sobre `unlimited` e com **billing específico de expansão**.

> O Easy não conhece nem calcula essas cotas.  
> Ele recebe apenas o resultado: quem é o usuário atual e em quais apps ele pode entrar.

---

## 6. Separação entre Hub e Easy

### 6.1 O que o Easy NÃO sabe

O Easy não sabe:
- quantos usuários o plano permite;
- se o tenant pode comprar mais;
- quem pode alterar billing;
- qual a regra de promoção para `admin`;
- qual é a política de expansão de assentos;
- como o Hub fez a conta comercial.

### 6.2 O que o Easy DEVE receber

Para o usuário autenticado, o Easy deve receber do Hub:
- identidade do usuário;
- tenant atual;
- `role` do contexto atual;
- `is_staff` do contexto atual;
- lista de apps às quais o usuário pode entrar;
- snapshot de licença/app quando aplicável.

### 6.3 Regra de interpretação no Easy

O Easy deve assumir:
- `role` e `tenant_role` compõem o contexto autenticado daquele acesso;
- `is_staff` indica contexto interno Axys, não poder comercial universal sobre qualquer tenant;
- apps ausentes do payload = usuário não entra;
- billing, upgrades e expansão de acesso pertencem ao Hub.

---

## 7. Instrução para o time Easy

Mensagem operacional resumida para compatibilização:

> O Hub é a fonte da verdade para papéis, billing, vínculo usuário↔app e licenciamento macro.  
> O Easy não gerencia usuários nem permissões comerciais.  
> O Easy deve apenas consumir o contexto autenticado resolvido pelo Hub: `role`, `tenant_role`, `is_staff`, `apps_licenciadas`/payload de apps e snapshot de licença.  
> Se o usuário não recebeu um app no payload, ele não entra.  
> O que cada papel pode fazer **dentro do Easy** pertence ao contrato do próprio Easy.

---

## 8. Consequências no Hub

O portal Hub deve:
- restringir telas de billing a `owner`/`admin`;
- tratar `user` como perfil operacional;
- centralizar a vinculação usuário ↔ app;
- aplicar cotas de usuários por assinatura;
- bloquear combinações inválidas de papéis conforme o plano;
- expor ao Easy apenas o resultado autorizado do contexto.

---

## 9. Referências

- [ARCHITECTURE.md](../ARCHITECTURE.md)
- [README.md](../README.md)
- [integrations/sso-login-easy.md](../integrations/sso-login-easy.md)
- [EASY_HUB_ARQUIVAMENTO.md](../EASY_HUB_ARQUIVAMENTO.md)
- [../../../foundation/contracts/axys_ecossistema_contrato_arquitetural.md](../../../foundation/contracts/axys_ecossistema_contrato_arquitetural.md)
