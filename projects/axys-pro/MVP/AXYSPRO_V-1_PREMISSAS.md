# AXYSPRO — Premissas de Arquitetura e Planejamento V-1 / V0

**Objetivo:** colocar rapidamente em operação um núcleo funcional do AxysPro, preservando desde o início as decisões estruturais difíceis de alterar depois.

## 1. Princípio da V-1

A V-1 será deliberadamente pequena. A prioridade é **arquitetura correta, domínio pequeno e interface simples**. Telas e workflows podem ser substituídos depois; modelagem, tenancy, identidade dos registros e histórico de produtividade devem nascer corretamente.

Escopo inicial:
- autenticação;
- identificação do tenant;
- validação da licença junto ao Axys Hub;
- usuários, roles, permissions e rules locais;
- trabalhos/projetos;
- tarefas e checklists;
- START / PAUSE / STOP;
- tempo acumulado por tarefa, projeto e usuário.

## 2. Stack

- Django;
- PostgreSQL;
- Django Admin para administração;
- Django Auth para usuários locais;
- Django REST Framework somente quando houver necessidade de API;
- servidor local inicialmente;
- integração com Axys Hub;
- leitura/importação do banco PROD Dias & Cardozo.

Não introduzir inicialmente Celery, Redis, microservices, event bus ou multi-database sofisticado sem necessidade real.

## 3. Separação Hub x Pro

### Axys Hub
Responsável pela relação institucional/comercial com o tenant:
- `tenant_uuid` global;
- tenant e conta Axys;
- licença ativa/inativa;
- produtos contratados;
- módulos habilitados por produto;
- limites comerciais/seats, quando existirem;
- Hub Members: owner, billing, administradores da conta.

O Hub **não será o diretório de todos os funcionários operacionais dos clientes**.

### AxysPro
Responsável pela operação do ERP:
- usuários locais;
- autenticação local;
- groups/roles;
- permissions;
- rules contextuais;
- projetos;
- tarefas;
- checklists;
- timers e produtividade;
- demais módulos futuros.

> **Hub controla entitlement/licença do tenant. Pro controla authorization dos usuários do produto.**

## 4. Hub Members != Product Users

```text
Tenant
├── Hub Members
│   ├── Owner
│   ├── Billing
│   └── Administrator
└── Products
    ├── AxysPro → Product Users
    └── Easy    → Product Users
```

Um tenant pode, por exemplo, ter 2 Hub Members e 30 usuários do Pro. Os 30 funcionários não precisam existir no Hub.

## 5. Multi-tenancy

Desde a primeira migration, tabelas de negócio pertencentes a uma organização deverão carregar `tenant_uuid`.

Estratégia inicial:

```text
Shared database
Shared schema
Tenant discriminator por tenant_uuid
```

Não haverá inicialmente schema ou banco separado por tenant. Todas as consultas de negócio deverão respeitar o tenant.

Para login, usar um identificador humano como `tenant_code`; o UUID permanece interno.

```text
Organização: DIASCARDOZO
E-mail: usuario@empresa.com
Senha: ********
```

## 6. Autenticação

O AxysPro terá autenticação própria.

Credenciais:

```text
tenant_code + email + password
```

Fluxo:

```text
Usuário
  ↓
AxysPro
  ├─ resolve tenant_code → tenant_uuid
  ├─ consulta Hub: licença/produto/módulos
  └─ autentica usuário LOCAL: tenant_uuid + email + password
```

Login autorizado somente quando:

```text
Tenant autorizado pelo Hub
+
Usuário local autorizado pelo Pro
```

**A senha do usuário nunca será enviada ao Hub.**

A consulta Pro → Hub será server-to-server, autenticada por credencial/token exclusivo da aplicação.

## 7. Endpoint de entitlement do Hub

Exemplo conceitual:

```text
POST /internal/v1/entitlements/check
```

Request:

```json
{
  "tenant_uuid": "abc-123",
  "product": "axys-pro"
}
```

Resposta:

```json
{
  "active": true,
  "tenant_uuid": "abc-123",
  "product": "axys-pro",
  "modules": {
    "productivity": true,
    "projects": true,
    "finance": false
  },
  "limits": {
    "users": 50
  }
}
```

O Hub responde sobre **direitos comerciais do tenant**, nunca sobre permissions internas de funcionários.

## 8. Entitlement != Permission

**Entitlement (Hub):** este tenant contratou o módulo Financeiro?

**Permission (Pro):** este usuário pode visualizar/aprovar pagamentos?

```text
HUB: finance = ENABLED
        ↓
PRO:
Renan → Finance Admin
Maria → Finance Operator
João  → sem acesso
```

## 9. Usuários locais

Usar Django Auth, preferencialmente já com `CustomUser` desde o início.

Identidade lógica:

```text
tenant_uuid + email
```

Modelo conceitual:

```text
ProUser
- id
- tenant_uuid
- email
- name
- password_hash
- is_active
- is_staff
- created_at
- updated_at
```

Usar hashing e autenticação nativos do Django. Nunca armazenar senha em texto puro.

## 10. Roles, Groups, Permissions e Rules

Os `Groups` do Django podem representar roles:

```text
PROJETOS
COMPRAS
FINANCEIRO
DIRETORIA
ADMINISTRADOR
```

Permissions padrão por model:

```text
view
add
change
delete
```

Permissions específicas poderão ser criadas:

```text
use_timer
complete_checklist
approve_task
approve_project
view_financial
approve_payment
```

Rules contextuais ficam no Pro e serão implementadas apenas quando necessárias.

## 11. Django Admin

O Admin será infraestrutura administrativa, não a interface diária do funcionário.

Usos:
- usuários;
- groups e permissions;
- projetos;
- tarefas;
- checklists;
- time entries;
- dados auxiliares e correções administrativas.

O usuário operacional fará essencialmente checklists e apontamento de tempo em interface própria.

## 12. Escopo funcional V0

1. Login;
2. Trabalhos/Projetos;
3. Tarefas;
4. Checklists;
5. Timer;
6. consulta básica de produtividade.

Evitar expansão prematura.

## 13. Trabalhos / Projetos

O cadastro existente da Dias & Cardozo será fonte inicial.

```text
Project / Work
- id
- tenant_uuid
- external_id
- source_system
- code
- name
- client
- status
- created_at
- updated_at
```

`external_id` preserva a identidade no sistema de origem.

## 14. Integração Dias & Cardozo

Fluxo unidirecional:

```text
D&C PROD
   │ READ ONLY
   ↓
AxysPro Importer
   ↓
AxysPro DB
```

Somente:

```text
D&C → AxysPro
```

Não implementar escrita de volta no legado nesta versão.

Importação por upsert usando algo como:

```text
tenant_uuid + source_system + external_id
```

```text
não existe → INSERT
existe     → UPDATE
```

Pode começar com:

```bash
python manage.py sync_diasecardozo
```

Depois, cron periódico. Pelo baixo volume, não há necessidade inicial de Celery.

## 15. Tarefas

```text
Task
- id
- tenant_uuid
- project_id
- title
- description
- assigned_to
- status
- estimated_hours
- created_at
- completed_at
```

Manter simples e não antecipar workflow complexo.

## 16. Checklists

```text
ChecklistItem
- id
- tenant_uuid
- task_id
- description
- is_done
- order
- completed_by
- completed_at
- created_at
```

O usuário poderá visualizar e marcar/desmarcar conforme permissions/rules.

## 17. Timer e produtividade

Não guardar somente `tempo_acumulado` na tarefa. Cada período trabalhado deve gerar registro próprio:

```text
TaskTimeEntry
- id
- tenant_uuid
- task_id
- user_id
- started_at
- ended_at
- duration_seconds
- created_at
```

### START
Cria sessão com `started_at = now()` e `ended_at = NULL`.

### PAUSE
Fecha sessão atual e calcula duração. A tarefa permanece disponível para retomada.

### Novo START
Cria novo `TaskTimeEntry`.

### STOP
Fecha a sessão corrente e poderá futuramente possuir semântica adicional de workflow.

Exemplo:

```text
09:00 START
10:12 PAUSE → 01:12
10:37 START
11:50 PAUSE → 01:13
13:20 START
15:00 STOP  → 01:40
TOTAL       → 04:05
```

O total será derivado da soma dos registros. Isso preserva dados para tempo por usuário, tarefa, projeto, tipo de serviço, período, estimado x realizado e indicadores futuros.

## 18. Interface V-1

Pode ser deliberadamente simples:

```text
AXYSPRO

Projeto
Hospital Municipal

Tarefa
Projeto Estrutural — Fundação

Checklist
[x] Receber sondagem
[x] Modelar fundações
[ ] Dimensionamento
[ ] Detalhamento
[ ] Revisão

Tempo acumulado
03:42:17

[ START ] [ PAUSE ] [ STOP ]
```

Design sofisticado não é prioridade nesta fase.

## 19. Auditabilidade

`django.contrib.admin.models.LogEntry` serve como log operacional do Admin, não como audit trail definitivo.

Preservar estruturalmente os eventos importantes, especialmente:
- `TaskTimeEntry`;
- conclusão de checklist;
- mudanças relevantes de status.

Audit log completo poderá ser incorporado depois (`django-simple-history`, `django-auditlog` ou solução própria).

## 20. API

Django Admin não é API. Quando APIs forem necessárias, utilizar Django REST Framework.

```text
Django Models
   ├── Django Admin
   └── DRF / API
```

Não criar endpoints sem consumidor ou necessidade concreta.

## 21. Premissas de segurança

- nenhuma senha em texto puro;
- senha do Pro nunca trafega para o Hub;
- comunicação Pro → Hub autenticada server-to-server;
- banco D&C acessado inicialmente em modo somente leitura;
- `tenant_uuid` obrigatório no domínio multi-tenant;
- queries e operações sempre tenant-scoped;
- permissions/rules do Pro não dependem do Hub;
- módulos comerciais retornados pelo Hub não substituem permissions locais;
- secrets exclusivamente em configuração segura/environment variables.

## 22. O que NÃO construir agora

Não antecipar:
- ERP completo;
- financeiro completo;
- compras;
- RH;
- CRM;
- SSO universal;
- IAM centralizado de todos os funcionários;
- microservices;
- filas distribuídas;
- dashboards sofisticados;
- aplicação mobile;
- sincronização bidirecional com D&C;
- arquitetura de plugins;
- rules hipotéticas sem demanda real.

## 23. Estrutura inicial sugerida

```text
axys-pro/
├── config/
├── apps/
│   ├── accounts/
│   ├── tenants/
│   ├── projects/
│   ├── tasks/
│   ├── productivity/
│   └── integrations/
│       ├── hub/
│       └── diasecardozo/
├── templates/
├── static/
├── manage.py
└── requirements.txt / pyproject.toml
```

Não transformar essa estrutura em dogma; manter separação clara de domínio e integrações.

## 24. Ordem sugerida de implementação

```text
FASE 1 — Fundação
Django + PostgreSQL
CustomUser
Tenant reference
Admin

FASE 2 — Hub
cliente server-to-server
validação de licença
entitlements/módulos

FASE 3 — Auth
login tenant_code + email + password
sessão Django
permissions básicas

FASE 4 — Domínio
Project
Task
ChecklistItem
TaskTimeEntry

FASE 5 — Integração D&C
leitura PROD
upsert de projetos/trabalhos
management command

FASE 6 — UI operacional
lista de projetos/tarefas
checklist
START / PAUSE / STOP
contador

FASE 7 — Indicadores mínimos
tempo por tarefa
por projeto
por usuário
por período
```

## 25. Princípio de evolução

A V-1 deve ser pequena sem ser estruturalmente descartável.

> **Ser provisório na interface é aceitável. Ser provisório na identidade dos dados, tenancy e histórico operacional deve ser evitado.**

O AxysPro nasce como produto independente, conectado ao Hub para licenciamento e entitlement, mas dono de sua operação, usuários, autorização e dados de ERP.

---

## Decisão arquitetural resumida

```text
                    AXYS HUB
             ┌────────────────────┐
             │ Tenant             │
             │ Licença            │
             │ Produtos/Módulos   │
             │ Limites            │
             │ Hub Members        │
             └─────────┬──────────┘
                       │
                 server-to-server
                       │
                       ▼
                   AXYS PRO
             ┌────────────────────┐
             │ Tenant reference   │
             │ Pro Users          │
             │ Groups             │
             │ Permissions/Rules  │
             │ Projects           │
             │ Tasks              │
             │ Checklists         │
             │ Time Entries       │
             └────────────────────┘
```

**Hub:** quem é o tenant e o que ele contratou.  
**Pro:** quem trabalha, no que trabalha e o que cada pessoa pode fazer.
