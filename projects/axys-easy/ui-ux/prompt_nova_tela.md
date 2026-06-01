# AxysEasy — Prompt Canônico: Construção de Nova Tela

> **Como usar:**
> Cole este arquivo inteiro no início de uma nova sessão de chat.
> Ao final, preencha a seção **"Briefing da Nova Tela"** com as especificações da funcionalidade.
> A IA deve ler os arquivos indicados abaixo antes de escrever qualquer linha de código.

---

## LEITURA OBRIGATÓRIA ANTES DE COMEÇAR

Antes de escrever qualquer código, leia os seguintes arquivos na ordem indicada:

```
1. backend/frontend/templates/base/config_ui_ux_easy.md
2. backend/frontend/templates/base/base.html
3. backend/frontend/templates/base/base_app.html
4. backend/frontend/templates/base/base_sidebar.html
5. backend/frontend/templates/partials/app_header.html
6. backend/frontend/templates/partials/app_footer.html
```

Estes arquivos definem os padrões canônicos de UI, UX, Backend e Auditoria do sistema.
**Nenhum padrão novo deve ser inventado.** Toda decisão de UI/UX/Backend deve estar ancorada nesses arquivos.

Se a nova tela pertence a um módulo existente, leia também:
```
backend/frontend/templates/partials/sidebar_{modulo}.html
backend/modules/{modulo}/routes.py
backend/modules/{modulo}/service.py
```

---

## FLUXOGRAMA 1 — Identificação do Tipo de Tela

```
┌─────────────────────────────────────────────────────────┐
│          Qual é o propósito principal da tela?          │
└─────────────────────────────────────────────────────────┘
                           │
        ┌──────────────────┼──────────────────┐
        ▼                  ▼                  ▼
  Apresentar        Consultar /          Criar ou
  atalhos e         listar registros     alterar um
  resumos do        com filtros          registro
  módulo
        │                  │                  │
        ▼                  ▼                  ▼
    [ MAIN ]           [ LIST ]        [ CREATE/EDIT ]
```

**MAIN** → usa `base_app.html`, sem sidebar, cards de acesso rápido
**LIST** → usa `base_sidebar.html`, tabela com filtros, ações, modais
**CREATE/EDIT** → usa `base_sidebar.html`, formulário distribuído em grid

---

## FLUXOGRAMA 2 — Construção: Tela MAIN

```
INÍCIO
  │
  ├─ 1. Template extends "base/base_app.html"
  │
  ├─ 2. Definir bloco page_css
  │       └── link para easy_main.css ou css do módulo
  │
  ├─ 3. Bloco main_content
  │       └── .ae-launcher > .ae-launcher-grid--N
  │             └── N cards (.ae-launcher-card)
  │                   ├── ícone textual (.ae-launcher-icon) → ex: "FNT", "INS"
  │                   └── label (.ae-launcher-label)
  │
  ├─ 4. Rota backend (routes_pages.py ou routes_{modulo}.py)
  │       GET /modulo/main
  │       Depends(require_auth)
  │       Contexto:
  │         - axys_user = _user_ctx(claims)
  │         - page_module, page_section
  │         - dados de resumo/KPI se houver
  │
  ├─ 5. Controle por perfil (se necessário)
  │       if axys_user.is_staff → exibe tudo
  │       else → filtra por apps_licenciadas
  │
  └─ FIM
```

---

## FLUXOGRAMA 3 — Construção: Tela LIST

```
INÍCIO
  │
  ├─ 1. Template extends "base/base_sidebar.html"
  │       block page_css  → easy_{modulo}.css
  │       block sidebar   → include "partials/sidebar_{modulo}.html"
  │       block panel_content → conteúdo do painel principal
  │
  ├─ 2. Estrutura do panel_content (ORDEM OBRIGATÓRIA):
  │       a. .ae-topbar > .ae-breadcrumb
  │            Início › Módulo
  │       b. #page-alert-container  ← alertas aparecem AQUI (entre breadcrumb e filtros)
  │       c. .cpu-filter-bar        ← filtros (retraído por padrão)
  │            - busca textual por data-nome
  │            - checkbox "Exibir inativos" ← SEM restrição de perfil (leitura livre)
  │       d. .cpu-actions           ← botões de ação
  │       e. .ae-table-wrap > .ae-table
  │       f. #modal-detalhe         ← modal sem fetch, lê data-* da linha
  │       g. #modal-confirmacao     ← substitui confirm() nativo do browser
  │
  ├─ 3. Tabela
  │       thead: colunas relevantes + Status como última coluna (sempre)
  │       tbody: cada <tr> com data-* obrigatórios:
  │         data-id, data-ativa, data-codigo, data-nome
  │         + demais campos necessários para modal de detalhes e ações
  │       Código → .ae-tag-id (monospace, cor var(--ae-text))
  │       Status → .ae-badge:
  │         Ativo   → .ae-badge-success (verde)
  │         Inativo → .ae-badge-neutral (âmbar: bg #fff3cd, color #856404)
  │       Atenção: confirmar o nth-child correto para a coluna Status no JS
  │               (muda conforme quantidade de colunas da tabela)
  │
  ├─ 4. Botões de ação (.cpu-btn, height 28px, font-size 12px, font-weight 700)
  │       Cadastrar  → sempre visível → GET /{recurso}/novo
  │                    (backend redireciona se sem permissão — não esconder no front)
  │       Detalhar   → sempre visível → abre modal de detalhes sem fetch
  │       Editar     → sempre visível → GET /{recurso}/{id}/editar
  │                    (backend abre form congelado se sem permissão de edição)
  │       Desativar  → sempre visível → abre modal de confirmação
  │       Reativar   → OCULTO (ae-hidden) por padrão
  │                    aparece APENAS quando checkbox "Exibir inativos" está marcado
  │
  ├─ 5. Guards obrigatórios em todos os botões de ação:
  │       sem seleção  → showPageAlert("Selecione um registro para prosseguir.", "info")
  │       Desativar + registro já inativo → showPageAlert("Este registro já está inativo.", "info")
  │
  ├─ 6. Modal de confirmação (substitui confirm() nativo)
  │       Título:  "Confirmar {ação}?"
  │       Corpo:   "Deseja {ação} {CODIGO}?"
  │       Botões:  Confirmar (ícone ✓ SVG) · Cancelar (ícone ✗ SVG)
  │       Backdrop clicável → cancela
  │       Animação: slideUp .3s
  │
  ├─ 7. Flash via URL (redirect pós-submit do form)
  │       DOMContentLoaded → ler ?msg= e ?type= → showPageAlert(msg, type)
  │
  ├─ 8. Atualização otimista após inativar/reativar
  │       API retorna { success, message, {recurso}: {...} }
  │       JS atualiza na linha:
  │         rowElement.setAttribute("data-ativa", "true/false")
  │         rowElement.setAttribute("data-atualizado-em", fonte.atualizado_em)
  │         rowElement.setAttribute("data-atualizado-por", fonte.atualizado_por)
  │       JS atualiza badge de status: querySelector("td:nth-child(N)")
  │         ← N deve ser contado manualmente na tabela (começa em 1)
  │       NÃO recarregar a página
  │       Erros (400, 403): result.body.message || result.body.detail → showPageAlert danger
  │
  ├─ 9. Rota backend
  │       GET /{recurso}
  │         Depends(exige_{perfil}_user) ← leitura: qualquer usuário do grupo
  │         Contexto: axys_user, active_section, lista de registros
  │       POST /api/{recurso}/{id}/inativar
  │         Depends(exige_{perfil}_admin) ← escrita: somente admin/owner
  │         Retorna: { success, message, {recurso}: snapshot_atualizado }
  │       POST /api/{recurso}/{id}/reativar
  │         Depends(exige_{perfil}_admin)
  │         Retorna: { success, message, {recurso}: snapshot_atualizado }
  │
  ├─ 10. Service
  │       get_{recursos}()
  │         → SELECT com LEFT JOIN LATERAL para última versão, se aplicável
  │         → retorna lista de dicts com todos os campos + nome_exibicao formatado
  │       inativar_{recurso}(id, usuario)
  │         → _snapshot(cur, id) antes da operação
  │         → verificar dependências ativas (se aplicável) antes de inativar
  │         → UPDATE ativa=false, atualizado_em=NOW(), atualizado_por=usuario
  │         → audit_service.registrar(UPDATE, antes, depois, conn=conn)
  │         → conn.commit()
  │         → retorna snapshot atualizado para o JS atualizar a linha
  │       reativar_{recurso}(id, usuario)
  │         → mesmo padrão, ativa=true
  │
  ├─ 11. Auditoria
  │       inativar → acao="UPDATE", antes=snapshot, depois={...ativa:False}
  │       reativar → acao="UPDATE", antes=snapshot, depois={...ativa:True}
  │
  └─ FIM
```

---

## FLUXOGRAMA 4 — Construção: Tela CREATE/EDIT

```
INÍCIO
  │
  ├─ 1. Template extends "base/base_sidebar.html"
  │       block page_css → easy_{modulo}.css
  │       block sidebar  → include "partials/sidebar_{modulo}.html"
  │
  ├─ 2. Estrutura do panel_content (ORDEM OBRIGATÓRIA):
  │       a. .ae-topbar > .ae-breadcrumb
  │            Início › Módulo › Cadastro   (modo novo)
  │            Início › Módulo › Edição     (modo editar)
  │       b. Banner somente leitura (se não pode_editar):
  │            .ae-alert.ae-alert-info com ícone ℹ e texto explicativo
  │            ex: "Visualização somente leitura. Seu perfil não tem permissão para editar."
  │       c. #flash-container  ← erros inline (acima do form)
  │       d. <form id="{recurso}-form" class="fonte-form-grid">
  │               (sem method, sem action — submit interceptado por JS)
  │
  ├─ 3. Layout do formulário (.fonte-form-grid)
  │       .fg-row → linha horizontal (flex, gap 16px, align flex-end)
  │         .fg-col.fg-col-2    → meia largura (duas colunas lado a lado)
  │         .fg-col.fg-col-full → largura total
  │       Labels: 12px, font-weight 700, uppercase, color var(--ae-muted)
  │       Inputs/select: .fg-input
  │       Caixa alta: .fg-upper (força via JS no evento input)
  │       Disabled (somente leitura): atributo HTML disabled em cada campo
  │         → browser aplica visual de desabilitado automaticamente
  │
  ├─ 4. Regras de campos
  │       Campo "Ativa" → APENAS no modo "editar" (nunca no cadastro)
  │       Todo cadastro nasce com ativa=true por padrão (não exibir no form)
  │       Campos de auditoria (criado_em, atualizado_em) → não exibir no form
  │       disabled em TODOS os campos quando pode_editar=False
  │
  ├─ 5. Botões do formulário (.fg-row.fg-actions)
  │       SE pode_editar=True:
  │         Cadastrar / Salvar → .cpu-btn.cpu-btn-neutral (type="submit")
  │         Cancelar           → .cpu-btn.cpu-btn-neutral (link <a> → /{recurso})
  │       SE pode_editar=False:
  │         apenas "Voltar"    → .cpu-btn.cpu-btn-neutral (link <a> → /{recurso})
  │         botão Salvar NÃO aparece
  │
  ├─ 6. JS do formulário (inline no block page_scripts)
  │       INÍCIO DO SCRIPT:
  │         {% if not pode_editar %}return;{% endif %}
  │         ← para todo o JS se somente leitura (nenhum listener registrado)
  │
  │       Se pode_editar=True:
  │       a. Forçar caixa alta: .fg-upper → evento input → toUpperCase()
  │       b. Interceptar submit: e.preventDefault()
  │       c. Validar campos obrigatórios → showFormError() se inválido
  │       d. Montar FormData com todos os campos
  │       e. fetch(url, { method, body: formData })
  │            modo novo   → POST /api/{recurso}
  │            modo editar → PUT  /api/{recurso}/{id}
  │       f. Em sucesso:
  │            result.body.unchanged → redirect com type=info
  │            result.body.success   → redirect com type=success
  │            window.location.href = "/{recurso}?msg=...&type=..."
  │       g. Em erro:
  │            showFormError(result.body.message || result.body.detail)
  │            → injeta .ae-alert.ae-alert-danger em #flash-container
  │            → window.scrollTo(0, 0)
  │
  ├─ 7. Rotas backend
  │       GET  /{recurso}/novo
  │         Depends(exige_{perfil}_user)
  │         Se não pode_editar(claims):
  │           from urllib.parse import quote
  │           msg = quote("Seu perfil não tem permissão para cadastrar registros.")
  │           return RedirectResponse(f"/{recurso}?msg={msg}&type=danger", 303)
  │         Contexto: modo="novo", {recurso}=None, pode_editar=True
  │
  │       GET  /{recurso}/{id}/editar
  │         Depends(exige_{perfil}_user)   ← qualquer usuário do grupo pode abrir
  │         {recurso} = obter_{recurso}_para_edicao(id) → 404 se não encontrado
  │         Contexto: modo="editar", {recurso}=dict, pode_editar=_pode_editar(claims)
  │           ← pode_editar=False → form abre congelado (somente leitura)
  │           ← pode_editar=True  → form editável
  │
  │       POST /api/{recurso}
  │         Depends(exige_{perfil}_admin)  ← escrita bloqueada para user
  │         campos via Form(...)
  │         try/except UniqueViolation → 409
  │
  │       PUT  /api/{recurso}/{id}
  │         Depends(exige_{perfil}_admin)
  │         campos via Form(...)
  │         try/except UniqueViolation → 409
  │
  ├─ 8. Helper na rota: _pode_editar(claims)
  │       from backend.core.permissions import _role, _is_staff, _ADMIN_ROLES
  │       def _pode_editar(claims):
  │           return _is_staff(claims) and _role(claims) in _ADMIN_ROLES
  │       ← adaptar para módulos de cliente: not _is_staff and role in _ADMIN_ROLES
  │
  ├─ 9. Service
  │       criar_ou_atualizar_{recurso}(id, ...campos..., usuario)
  │         INSERT:
  │           cur.execute(INSERT ... RETURNING id)
  │           audit_service.registrar(acao="INSERT", antes=None, depois={...}, conn=conn)
  │           conn.commit()
  │           return { success: True, message: "'{codigo}' criado com sucesso.", id }
  │
  │         UPDATE:
  │           antes = _snapshot(cur, id)
  │           if (antes["campo1"], ...) == (campo1, ...):  ← diff
  │             return { success: True, unchanged: True, message: "Nenhuma alteração a ser aplicada." }
  │           cur.execute(UPDATE ...)
  │           audit_service.registrar(acao="UPDATE", antes=antes, depois={...}, conn=conn)
  │           conn.commit()
  │           return { success: True, message: "'{codigo}' atualizado com sucesso.", id }
  │
  ├─ 10. Auditoria
  │       INSERT → antes=None, depois=snapshot do novo registro
  │       UPDATE com mudança → antes=snapshot_antes, depois=novo_estado
  │       UPDATE sem mudança → NÃO auditar, NÃO persistir, retornar unchanged=True
  │
  └─ FIM
```

---

## REGRAS TRANSVERSAIS (valem para qualquer tela)

### Sempre fazer

- `_user_ctx(claims)` em toda rota que renderiza template
- `_audit_label(claims)` em toda operação de escrita
- Declarar permissão explícita em **toda** rota (nunca usar `require_auth` direto em rotas de negócio)
- `audit_service.registrar()` dentro da mesma transação do serviço
- `conn.commit()` apenas no serviço, nunca na rota
- Tratar `psycopg2.errors.UniqueViolation` → HTTP 409 com mensagem amigável

### Permissões — modelo de referência

```python
from backend.core.permissions import (
    exige_internal_user,   # equipe interna Axys (qualquer role)
    exige_internal_admin,  # equipe interna — role admin ou owner
    exige_internal_owner,  # equipe interna — role owner
    exige_client_user,     # usuário cliente de tenant (qualquer role)
    exige_client_admin,    # usuário cliente — role admin ou owner
    exige_client_owner,    # usuário cliente — role owner
    exige_admin,           # admin ou owner — qualquer time
)
```

**Padrão para módulos administrativos (equipe interna) — referência: fontes-base:**
```
GET  listagem / form edição → Depends(exige_internal_user)
                              + _pode_editar(claims) → form congelado se user
GET  form cadastro          → Depends(exige_internal_user)
                              + redirect se não _pode_editar(claims)
POST criar / PUT editar     → Depends(exige_internal_admin)
POST inativar / reativar    → Depends(exige_internal_admin)
Operações críticas          → Depends(exige_internal_owner)
```

**Padrão para módulos de tenant (usuários clientes):**
```
GET  listagem / form edição → Depends(exige_client_user)
GET  form cadastro          → Depends(exige_client_user) + redirect se não pode editar
POST criar / PUT editar     → Depends(exige_client_admin)
POST inativar / reativar    → Depends(exige_client_admin)
Configurações críticas      → Depends(exige_client_owner)
```

**Nota:** `_pode_editar(claims)` é um helper local na rota:
```python
def _pode_editar(claims):
    from backend.core.permissions import _role, _is_staff, _ADMIN_ROLES
    return _is_staff(claims) and _role(claims) in _ADMIN_ROLES
```
Para módulos de cliente: `return not _is_staff(claims) and _role(claims) in _ADMIN_ROLES`

### Nunca fazer

- Usar `alert()`, `confirm()` ou `prompt()` do browser
- Chamar `conn.commit()` na rota
- Auditar operações sem mudança real
- Exibir alertas fora de `#page-alert-container`
- Usar `text-transform: uppercase` no CSS (usar `.fg-upper` via JS)
- Criar padrões visuais novos sem justificativa e sem atualizar `config_ui_ux_easy.md`
- Campo "Ativa" em tela de cadastro
- Mostrar campos de auditoria (criado_em, atualizado_em) em formulários

### SVG de ícones (padrão header/botões)

```
width="N" height="N" viewBox="0 0 24 24"
fill="none" stroke="currentColor"
stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"
aria-hidden="true"
```
Botões de ação: 13×13 | Header: 20×20 | Alertas: 16×16

---

## BRIEFING DA NOVA TELA

> Preencha esta seção ao usar este prompt em uma nova sessão.

```
## Nome da funcionalidade:
[ex: Cadastro de Insumos]

## Módulo:
[ex: CPU]

## Tipo de tela:
[ ] MAIN   [ ] LIST   [ ] CREATE/EDIT (escolha um ou mais se for par list+form)

## URL(s):
[ex: /insumos | /insumos/novo | /insumos/{id}/editar]

## Tabela(s) do banco envolvida(s):
[ex: cpu.insumos]

## Campos da tela (para LIST — colunas da tabela):
[ex: Código | Descrição | Unidade | Tipo | Status]

## Campos da tela (para CREATE/EDIT — campos do formulário):
[ex: Código (obrigatório, caixa alta) | Descrição (obrigatório, caixa alta) | Unidade | Tipo (select)]

## Ações disponíveis na listagem:
[ex: Cadastrar · Detalhar · Editar · Desativar · Reativar]

## Regras de negócio específicas:
[ex: Código deve ser único por fonte. Não inativar se houver preços ativos associados.]

## Dependências para inativação (se aplicável):
[ex: Verificar cpu.precos_insumo ativos antes de inativar]

## Campos extras no modal de detalhamento:
[ex: além do padrão: Tipo SINAPI, Tipo Interno]

## Permissões da tela:
# Quem pode acessar a listagem/form?
[ex: exige_internal_user — apenas equipe interna Axys]
# Quem pode criar/editar?
[ex: exige_internal_user]
# Quem pode inativar/reativar?
[ex: exige_internal_admin — apenas admin ou owner interno]

## Observações / comportamentos especiais:
[campo livre]
```

---

## CHECKLIST FINAL ANTES DE DECLARAR A TELA PRONTA

### Template

- [ ] Herança correta de base template
- [ ] `axys_user` disponível e passado pela rota
- [ ] `active_section` correto para highlight do sidebar
- [ ] Breadcrumb com links corretos e profundidade correta
- [ ] `#page-alert-container` posicionado entre breadcrumb e conteúdo
- [ ] Leitura de `?msg=` e `?type=` no DOMContentLoaded

### Listagem

- [ ] `data-*` completos em todas as `<tr>`
- [ ] Badge de status usando `.ae-badge-neutral` para inativo (âmbar)
- [ ] Botão Reativar com `ae-hidden` por padrão
- [ ] Guards em todos os botões de ação
- [ ] Modal de confirmação personalizado (sem `confirm()` nativo)
- [ ] Atualização otimista da linha após inativar/reativar
- [ ] `nth-child` correto para badge de status após operação

### Formulário

- [ ] `<form>` sem `method`/`action`
- [ ] `.fg-upper` nos campos de caixa alta
- [ ] Campo "Ativa" ausente no modo cadastro
- [ ] `pode_editar` passado pela rota ao contexto do template
- [ ] Banner somente leitura quando `not pode_editar`
- [ ] `disabled` em todos os campos quando `not pode_editar`
- [ ] Botão Salvar ausente quando `not pode_editar` (apenas "Voltar")
- [ ] JS com `{% if not pode_editar %}return;{% endif %}` no início
- [ ] Validação JS antes do fetch
- [ ] Redirect com `?msg=&type=` após sucesso
- [ ] `showFormError(result.body.message || result.body.detail)` em `#flash-container`

### Backend

- [ ] Rota com `Depends(exige_*)` — nunca `require_auth` direto em rota de negócio
- [ ] Permissão correta para cada operação (leitura ≠ escrita ≠ inativar/reativar)
- [ ] `_pode_editar(claims)` definido na rota e passado ao template
- [ ] Rota `/novo`: redirect com `type=danger` se não `_pode_editar`
- [ ] `RedirectResponse` importado em `routes_{modulo}.py`
- [ ] `_user_ctx(claims)` no contexto do template
- [ ] `_audit_label(claims)` passado ao service
- [ ] `_snapshot()` antes de UPDATE
- [ ] Diff check antes de persistir/auditar UPDATE
- [ ] `audit_service.registrar()` na mesma transação
- [ ] `conn.commit()` no service, não na rota
- [ ] `UniqueViolation` tratada na rota → HTTP 409
- [ ] Retorno padronizado `{ success, message, [unchanged] }`

### Auditoria

- [ ] INSERT auditado com `antes=None`
- [ ] UPDATE com mudança auditado com antes/depois
- [ ] UPDATE sem mudança NÃO auditado
- [ ] Inativar/reativar auditados como UPDATE
- [ ] Nova tabela adicionada em `audit.criterio_retencao` com política adequada
