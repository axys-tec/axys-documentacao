# AxysEasy — Guia Canônico de UI/UX, Backend e Auditoria

> **Versão validada:** 30/05/2026
> **Status:** CANÔNICO — telas aprovadas e congeladas como referência.
> Qualquer nova tela do sistema DEVE seguir este guia sem desvios.
> Mudanças no padrão só mediante revisão explícita deste documento.

---

## Índice

1. [Hierarquia de Templates](#1-hierarquia-de-templates)
2. [Padrões de Layout](#2-padrões-de-layout)
3. [Header e Footer](#3-header-e-footer)
4. [Tela: Login / Auth](#4-tela-login--auth)
5. [Tela: Main (Pós-Login)](#5-tela-main-pós-login)
6. [Tela: Listagem (List)](#6-tela-listagem-list)
7. [Tela: Cadastro / Edição (Create/Edit)](#7-tela-cadastro--edição-createedit)
8. [Sistema de Alertas / Flash Messages](#8-sistema-de-alertas--flash-messages)
9. [Padrões de Backend](#9-padrões-de-backend)
10. [Auditoria](#10-auditoria)
11. [Segurança](#11-segurança)
12. [Checklist de Reutilização](#12-checklist-de-reutilização)
13. [Documentação de Módulo — Work Pages](#13-documentação-de-módulo--work-pages)

---

## 1. Hierarquia de Templates

```
base/base.html                  ← raiz absoluta (HTML, head, body)
  └── base/base_app.html        ← área autenticada SEM sidebar (ex: main)
  └── base/base_sidebar.html    ← área autenticada COM sidebar (ex: módulos)

auth/login.html                 ← standalone (não extends base/)
auth/sem_contrato.html          ← standalone
auth/reset_request.html         ← standalone
auth/reset_form.html            ← standalone
auth/reset_confirm.html         ← standalone

app/main.html                   ← extends base/base_app.html
catalogo/fontes_base.html       ← extends base/base_sidebar.html
catalogo/fonte_base_form.html   ← extends base/base_sidebar.html
```

### Blocos disponíveis em base.html

| Bloco | Propósito |
|---|---|
| `{% block title %}` | `<title>` da página |
| `{% block head %}` | CSS e meta extras no `<head>` |
| `{% block body_class %}` | classe do `<body>` |
| `{% block content %}` | corpo inteiro da página |
| `{% block scripts %}` | JS ao final do body |

### Blocos adicionais em base_app.html / base_sidebar.html

| Bloco | Propósito |
|---|---|
| `{% block page_css %}` | CSS específico do módulo (dentro de head) |
| `{% block main_content %}` | conteúdo principal (base_app) |
| `{% block sidebar %}` | include do sidebar do módulo (base_sidebar) |
| `{% block panel_content %}` | conteúdo do painel direito (base_sidebar) |
| `{% block page_scripts %}` | JS específico do módulo (ao final) |

### Quando usar qual base

- **`base_app.html`** → telas sem navegação lateral: main, dashboards gerais, páginas de módulo que não têm sub-rotas.
- **`base_sidebar.html`** → telas com sidebar de navegação: listagens, cadastros, edições dentro de um módulo (cpu, orca, etc.).
- **Standalone** → telas pré-autenticação: login, reset, sem-contrato. Não herdam nada; têm CSS próprio.

---

## 2. Padrões de Layout

### CSS Base

| Arquivo | Escopo |
|---|---|
| `easy_geral.css` | Reset, variáveis CSS globais (`--ae-*`), tipografia base |
| `easy_partials.css` | Header, footer, sidebar, breadcrumb, ae-table, ae-badge |
| `easy_cpu.css` | Componentes exclusivos do módulo CPU |
| `easy_login.css` | Tela de login (standalone) |
| `easy_main.css` | Tela main / launcher |

### Variáveis CSS principais (`--ae-*`)

```css
--ae-text          /* cor principal de texto */
--ae-text-muted    /* texto secundário / muted */
--ae-border        /* cor padrão de bordas */
--ae-bg-soft       /* fundo levemente destacado */
--ae-muted         /* texto desabilitado */
```

### Tipografia

- **Fonte principal:** Exo 2 (Google Fonts), pesos 400 / 700 / 800 / 900
- **Fonte monospace:** system monospace (códigos, versões, IDs)
- **Inputs e labels:** `font-family: inherit`
- **Textos em caixa alta:** aplicados via JS (`.fg-upper`) — nunca via CSS `text-transform`

### Classe de corpo

- `ae-tela-fixa` → telas autenticadas (base_app, base_sidebar) — impede scroll do body, layout fixo

---

## 3. Header e Footer

### Header (`partials/app_header.html`)

**Estrutura:**
```
.site-header > .topbar
  ├── .ae-header-brand
  │     ├── logo (img) → link /main
  │     ├── .ae-header-divider (separador visual)
  │     └── .ae-header-tenant
  │           ├── tenant_code | tenant_name
  │           └── axys_user.name
  └── .ae-header-nav
        ├── .ae-header-clock (hora + data, atualizadas por JS)
        └── ícones: Academy · Notificações · Favoritos · Contato · Sair
```

**Contexto obrigatório:** `axys_user` (dict com `name`, `tenant_code`, `tenant_name`)

**Ícones do header:**
- SVG inline, 20×20, `viewBox="0 0 24 24"`, `fill="none"`, `stroke="currentColor"`, `stroke-width="1.8"`, `stroke-linecap="round"`, `stroke-linejoin="round"`
- Todos com `aria-hidden="true"` e `aria-label` no `<a>`
- Sair (`ae-header-icon--power`) → `href="/login/logout"`

**Relógio:** atualizado via JS em `easy_partials.js`. Formato: `HH:MM` / `DD/MM/YYYY`.

### Footer (`partials/app_footer.html`)

```
.ae-footer
  ├── .ae-footer-apps → "AxysEasy • CPU • Price • ..."
  │     (para staff: "Módulo Administrativo")
  └── "powered by Axys Tecnologia YYYY ©"
```

**Contexto obrigatório:** `axys_user`, `current_year` (injetado globalmente em `routes_pages.py`)

---

## 4. Tela: Login / Auth

**Arquivos:** `auth/login.html`, `easy_login.css`, `easy_login.js`
**URL:** `/login`
**Base:** standalone (não herda base/)

### Layout

- Split dois painéis: esquerdo (`login-left`) 60% + direito (`login-right`) 40%
- Painel esquerdo: formulário centrado verticalmente + rodapé de links
- Painel direito: tagline decorativa, sem interação

### Formulário de Login

| Campo | Tipo | Validação |
|---|---|---|
| E-mail | `email` | `required`, autocomplete |
| Senha | `password` | `required`, toggle show/hide via JS |
| Num. Doc. Cliente | `text` | `required`, máscara CPF/CNPJ via JS (`data-doc-mask`) |

**Submit:** `POST /login` (form nativo, sem fetch)

### Alertas inline no login

Aparecem dentro do `<form>`, antes do botão:

| Condição | Classe | Mensagem |
|---|---|---|
| `msg == 'logout'` | `.login-alert-info` | "Você saiu do sistema." |
| `msg == 'senha_redefinida'` | `.login-alert-success` | "Senha redefinida com sucesso. Faça login." |
| `error` | `.login-alert-error` | conteúdo do `error` passado pelo backend |

### Rodapé da tela de login

- Links: Manuais, Contato comercial (futuros)
- Ícones sociais: GitHub, Android, iOS, Facebook, Instagram, WhatsApp

### Fluxo de redefinição de senha

```
GET  /recuperar-senha              → formulário de solicitação (email)
POST /recuperar-senha              → envia link JWT por e-mail (15 min)
GET  /recuperar-senha/{token}      → formulário de nova senha
POST /recuperar-senha/{token}      → valida token, grava senha pendente, envia código SMS
GET  /recuperar-senha/confirmar?sid= → formulário de código de confirmação
POST /recuperar-senha/confirmar    → aplica mudança no Hub DB
```

Auditado em `audit.logs` (schema `hub`, tabela `users`, acao `UPDATE`) — **não** em `audit.login_logs`.

### Sem contrato (`/sem-contrato`)

Exibida quando usuário autenticado não possui licença Easy ativa.

---

## 5. Tela: Main (Pós-Login)

**Arquivo:** `app/main.html`
**URL:** `/main`
**Base:** `base/base_app.html`
**Rota:** `GET /main` em `routes_pages.py`

### Contexto obrigatório

```python
{
  "axys_user": _user_ctx(claims),  # name, email, tenant_*, role, is_staff, apps_*
  "page_module": "Início",
  "page_section": "Início",
}
```

### Layout

- `.ae-launcher` → container grid de atalhos
- `.ae-launcher-grid--4` → grid de 4 colunas
- Cada card: `.ae-launcher-card` com ícone textual (ex: `FNT`, `INS`, `CPU`) + label

### Comportamento por perfil

- `is_staff = true` → exibe todos os módulos do catálogo interno
- `is_staff = false` → exibe apenas módulos com licença ativa (a implementar)

---

## 6. Tela: Listagem (List)

**Referência:** `catalogo/fontes_base.html`
**URL:** `/fontes-base`
**Base:** `base/base_sidebar.html`
**Rota:** `GET /fontes-base` em `modules/catalogo/routes.py`

### Contexto obrigatório

```python
{
  "axys_user":      _user_ctx(claims),
  "page_module":    "CPU",
  "page_section":   "Fontes-Base",
  "active_section": "fontes-base",
  "fontes":         cpu_service.get_fontes(),
}
```

### Estrutura da página

```
.ae-topbar > .ae-breadcrumb          ← Início › Módulo
#page-alert-container                ← alertas de feedback (entre breadcrumb e filtros)
.cpu-filter-bar                      ← barra de filtros (retraída por padrão)
.cpu-actions                         ← botões de ação
.ae-table-wrap > .ae-table           ← tabela de dados
#cpu-modal                           ← modal de detalhamento
#cpu-confirm-modal                   ← modal de confirmação de ações
```

### Breadcrumb

```html
Início › Módulo
```
- `Início` → link `/main`
- `Módulo` → texto (não clicável, página atual)
- Para sub-nível: `Início › Módulo › Cadastro`

### Barra de Filtros (`.cpu-filter-bar`)

- Retraída por padrão; expande ao clicar no toggle
- Chevron rotaciona 180° quando aberto (CSS transition)
- Filtros disponíveis:
  - **Busca textual** → filtra por `data-nome` da linha (`input[type=text]`)
  - **Exibir inativos** → `input[type=checkbox]`, oculto por padrão; revela linhas com `data-ativa="false"`

### Botões de Ação (`.cpu-actions`)

| Botão | ID | Visibilidade | Comportamento |
|---|---|---|---|
| Cadastrar | `btn-novo` | sempre visível | navega para `/fontes-base/novo` |
| Detalhar | `btn-detalhar` | sempre visível | abre `#cpu-modal` com dados da linha selecionada |
| Editar | `btn-editar` | sempre visível | navega para `/fontes-base/{id}/editar` |
| Desativar | `btn-inativar` | sempre visível | abre modal de confirmação → `POST /api/fontes-base/{id}/inativar` |
| Reativar | `btn-reativar` | oculto por padrão | visível APENAS quando "Exibir inativos" está marcado |

**Regra sem seleção:** clicar em qualquer botão sem linha selecionada exibe:
```
showPageAlert("Selecione um registro para prosseguir.", "info")
```

**Regra Desativar com registro já inativo:** exibe:
```
showPageAlert("Este registro já está inativo.", "info")
```
— impede abertura do modal de confirmação.

### Estilo dos Botões (`.cpu-btn`)

```css
height: 28px
padding: 0 10px
border-radius: 5px
font-size: 12px
font-weight: 700
background: #eef0f4
color: var(--ae-text)
border: 1px solid #a8b0be
```

Com ícone SVG 13×13 à esquerda do texto.

### Tabela (`.ae-table`)

| Coluna | Fonte | Tipo |
|---|---|---|
| Código | `f.codigo` | `.ae-tag-id` (monospace, preto) |
| Nome | `f.nome` | texto simples |
| Ordem | `f.ordem_edicao` | texto |
| Última Versão | `f.ultima_versao` + `f.ultima_versao_mes` | `.ae-tag-versao` + `.ae-versao-mes` |
| Status | `f.ativa` | badge `.ae-badge` — `<td class="js-status-cell">` (JS atualiza por classe, não nth-child) |

> **Padrões de tabela (ordenação clicável, cabeçalho congelado/scroll na própria tabela, densidade) — canônico:** `catalogo/catalogo_work_pages.md` → "Padrões de tabela de listagem". Colunas ordenáveis = `<th class="ae-sortable">` (+ `data-sort`); a tabela rola (não o painel) via CSS `:has(.ae-table-wrap)`; card chapado (sem box-shadow). Não duplicar aqui.

**Badges de status:**

| Estado | Classe | Aparência |
|---|---|---|
| Ativo | `.ae-badge.ae-badge-success` | verde |
| Inativo | `.ae-badge.ae-badge-neutral` | âmbar/laranja — `background: #fff3cd; color: #856404` |

**Seleção de linha:**
- Clique → `.is-selected` na `<tr>` → `background: rgba(22,140,255,.10)`, `outline` azul, texto azul (`#0b4fa8`)
- Segundo clique → deseleciona
- Apenas uma linha selecionada por vez

**`data-*` obrigatórios em cada `<tr>`:**
```html
data-id, data-ativa, data-codigo, data-nome,
data-ordem-edicao, data-criado-em, data-criado-por,
data-atualizado-em, data-atualizado-por
```

### Modal de Detalhamento (`#cpu-modal`)

- Overlay `.cpu-modal-overlay` com `.ae-hidden`
- Abrir: `.ae-hidden` removido
- Fechar: botão `×` (`.cpu-modal-close`) ou botão "Fechar" no footer
- Campos: Código + badge Status · Descrição · Ordem de edição · Última atualização · Criado em
- Dados lidos dos `data-*` da linha selecionada (sem nova requisição ao backend)

### Modal de Confirmação (`#cpu-confirm-modal`)

- Substitui o `confirm()` nativo do browser
- Estrutura: `.cpu-confirm-modal` > `.cpu-confirm-backdrop` + `.cpu-confirm-container`
- Backdrop clicável fecha o modal (cancela)
- Botões:
  - **Confirmar** → ícone `✓` (check SVG) + texto
  - **Cancelar** → ícone `✗` (X SVG) + texto
  - Mesmo estilo dos `.cpu-btn` da listagem (height 28px, padding 0 10px)
- Animação de entrada: `slideUp` (translateY 20px → 0, opacity 0 → 1, 0.3s)

---

## 7. Tela: Cadastro / Edição (Create/Edit)

**Referência:** `catalogo/fonte_base_form.html`
**URLs:** `/fontes-base/novo` · `/fontes-base/{id}/editar`
**Base:** `base/base_sidebar.html`
**Rotas:** `GET /fontes-base/novo`, `GET /fontes-base/{id}/editar` em `modules/catalogo/routes.py`

### Contexto obrigatório

```python
{
  "axys_user":      _user_ctx(claims),
  "page_module":    "CPU",
  "page_section":   "Cadastro" | "Edição",
  "active_section": "fontes-base",
  "modo":           "novo" | "editar",
  "fonte":          None | dict(id, codigo, nome, ativa, ordem_edicao, ...),
  "pode_editar":    _pode_editar(claims),  # bool — controla modo somente leitura
}
```

### Controle de acesso no formulário (`pode_editar`)

O campo `pode_editar` vem da rota e determina se o formulário é editável ou somente leitura.

| Situação | Comportamento |
|---|---|
| `/novo` + `pode_editar=False` | Rota redireciona para `/fontes-base?msg=...&type=danger` (não abre form) |
| `/editar` + `pode_editar=True` | Form editável, botão Salvar visível |
| `/editar` + `pode_editar=False` | Form congelado (todos os campos `disabled`), banner âmbar, apenas botão "Voltar" |

**Banner somente leitura** (aparece quando `not pode_editar`):
```html
<div class="ae-alert ae-alert-info">
  ℹ Visualização somente leitura. Seu perfil não tem permissão para editar este registro.
</div>
```

**JS desabilitado** quando somente leitura:
```javascript
{% if not pode_editar %}return;{% endif %}  // nenhum listener registrado
```

### Layout do Formulário (`.fonte-form-grid`)

Grid de linhas (`.fg-row`) com colunas (`.fg-col`):

```
Linha 1: [ Código (fg-col-2) ]  [ Ordenação (fg-col-2) ]  [ Status: BADGE read-only (só editar) ]
Linha 2: [ Descrição (fg-col-full) ]
...      [ campos específicos do recurso ]
Última:  [ Salvar (se pode_editar) ]  [ Cancelar/Voltar ]  ← fg-actions
```

**Regra (atualizada 2026-06-06):** o **Status (ativa) NÃO é campo editável** do form. Em modo
`editar` aparece como **badge read-only** na 1ª linha; em `novo` não aparece (nasce ativo).
**Ativar/inativar é ação da LISTAGEM** (botões Desativar/Reativar), não do formulário — o service
de criar/atualizar **preserva** o status no UPDATE. (O form atual de Fontes tem ainda os grupos
"Catálogos técnicos" e "Publicação" — ver `catalogo/catalogo_work_pages.md`, não duplicar aqui.)

### Classes CSS do formulário

| Classe | Propósito |
|---|---|
| `.fonte-form-grid` | container flex coluna, gap 16px |
| `.fg-row` | linha horizontal, flex, gap 16px, align flex-end |
| `.fg-col` | coluna flex column, gap 5px |
| `.fg-col-full` | flex: 1 (ocupa toda a largura disponível) |
| `.fg-col-2` | flex: 1 (metade quando ao lado de outro fg-col-2) |
| `.fg-input` | estilo padrão de input/select |
| `.fg-upper` | força caixa alta via JS no evento `input` |
| `.fg-check-label` | label + checkbox inline, cursor pointer |
| `.fg-actions` | linha de botões, justify flex-start |

### Campos e Regras

| Campo | Tipo | Obrigatório | Caixa Alta | Máx |
|---|---|---|---|---|
| Código | `text` | sim | sim (`.fg-upper`) | 50 |
| Descrição | `text` | sim | sim (`.fg-upper`) | 255 |
| Ordenação | `select` | sim | — | — |
| Status (ativa) | **badge read-only** | — (só editar; não editável) | — | — |

**Valores do select Ordenação:** `DATA` · `VERSÃO` (com til — constraint no banco)

### Submit do Formulário

- `<form>` **sem** `method` e `action` — submit interceptado por JS
- JS só é registrado quando `pode_editar=True`
- Envia via `fetch` com `FormData`:
  - Modo `novo`: `POST /api/fontes-base`
  - Modo `editar`: `PUT /api/fontes-base/{id}`
- **Em sucesso:** redireciona para `/fontes-base?msg=...&type=success|info`
- **Em erro:** `result.body.message || result.body.detail` → `.ae-alert-danger` em `#flash-container`

### Botões do Formulário

| Situação | Botões exibidos |
|---|---|
| `pode_editar=True` | Cadastrar/Salvar (`.cpu-btn`) + Cancelar (`.cpu-btn`) |
| `pode_editar=False` | apenas Voltar (`.cpu-btn`) — Salvar não aparece |

---

## 8. Sistema de Alertas / Flash Messages

### Regra de posicionamento

- **Único local:** `#page-alert-container` — entre o breadcrumb e a barra de filtros
- Não usar `alert()`, `confirm()`, toasts flutuantes no canto, ou `#flash-container` para mensagens pós-ação

### Função JavaScript

```javascript
showPageAlert(message, type)
// type: "success" | "info" | "danger"
```

Auto-remove após 5 segundos.

### Tipos e aparência

| Tipo | Cor fundo | Cor texto | Borda | Uso |
|---|---|---|---|---|
| `success` | `rgba(212,237,218,.3)` | `#155724` | `rgba(195,230,203,.5)` | operação realizada com sucesso |
| `info` | `rgba(255,237,213,.3)` | `#92400e` | `rgba(253,186,116,.5)` | neutro / sem alteração / aviso |
| `danger` | `rgba(248,215,218,.3)` | `#721c24` | `rgba(245,198,203,.5)` | erro / falha |

**Nota:** transparência de 30% no fundo é intencional e canônica.

### Ícones dos alertas

| Tipo | Ícone |
|---|---|
| `success` | SVG polyline check `20 6 9 17 4 12` |
| `info` | SVG ℹ — círculo + ponto preenchido + linha vertical |
| `danger` | SVG triângulo de alerta |

### Flash via URL (redirect pós-submit)

Após operações de criação/edição bem-sucedidas, o formulário redireciona com parâmetros:

```
/fontes-base?msg=Fonte+criada+com+sucesso.&type=success
/fontes-base?msg=Nenhuma+alteração+a+ser+aplicada.&type=info
```

O JS da listagem lê os params no `DOMContentLoaded` e chama `showPageAlert`.

### Mensagens canônicas

| Situação | Tipo | Mensagem |
|---|---|---|
| Cadastro criado | `success` | `"Fonte-base 'CODIGO' criada com sucesso."` |
| Edição com mudança | `success` | `"Fonte-base 'CODIGO' atualizada com sucesso."` |
| Edição sem mudança | `info` | `"Nenhuma alteração a ser aplicada."` |
| Inativação | `success` | `"Fonte-base 'CODIGO' inativada com sucesso."` |
| Reativação | `success` | `"Fonte-base 'CODIGO' reativada com sucesso."` |
| Sem seleção | `info` | `"Selecione um registro para prosseguir."` |
| Inativar já inativo | `info` | `"Este registro já está inativo."` |
| Código duplicado | `danger` | `"Já existe uma fonte com o código 'CODIGO'."` |
| Dependências ativas | `danger` | `"Essa fonte-base não pode ser inativada em razão de haver dependências ativas. ..."` |

### Feedback OTIMISTA de ações assíncronas (CANÔNICO)

**Regra:** toda ação que dispara trabalho assíncrono (import, geração de PDF/caderno, upload longo, job de fila) DEVE dar feedback **no instante do clique** — **antes** da resposta do servidor. Nunca esperar o POST/job confirmar para só então acender o indicador.

No clique, e nesta ordem:

1. **Trava o gatilho** — `btn.disabled = true` + rótulo de transição (`"Enviando…"` / `"Processando…"`).
2. **Acende o indicador JÁ** — torna visível o painel/badge de progresso com um estágio otimista (ex.: `"subindo arquivos…"`, dot piscando) **antes** do `fetch` resolver.
3. **Guarda contra double-submit** — `if (btn.disabled) return;` no início do handler de `submit` (cobre Enter e clique rápido), porque botão desabilitado não impede submit por teclado.
4. **No retorno:** sucesso → o poll real assume o indicador; erro/rede → esconde o indicador otimista, reabilita o gatilho, alerta `danger`.

**Por quê:** sem isso, ações com POST demorado (ex.: upload de vários MB no import) deixam a tela "muda" entre o clique e a resposta — o usuário acha que não pegou e **clica de novo**, enfileirando trabalho **duplicado** (ex.: imports repetidos na fila Celery). O indicador otimista + a trava matam o double-submit.

Referência de implementação: `enviarImport()` em `easy_import.js` (acende `#imp-status` no clique). Padrão complementar ao [anti-zumbi de jobs](#) (status preso quando o worker morre) e ao micro-feedback inline de ações pequenas.

---

## 9. Padrões de Backend

### Estrutura de arquivos por funcionalidade

```
backend/modules/catalogo/routes.py  ← rotas HTML e API do módulo Catálogo
backend/modules/pages/routes.py     ← rotas de autenticação e main
backend/modules/catalogo/service.py ← toda lógica de dados e regras de negócio
backend/core/audit_service.py       ← escrita em audit.logs e audit.login_logs
backend/core/security.py            ← require_auth, decode_token, bypass dev
backend/core/permissions.py         ← controle de acesso por perfil
```

### Helper `_pode_editar(claims)` — formulário somente leitura

Definido localmente em cada arquivo de rotas. Determina se o usuário pode gravar dados.

```python
def _pode_editar(claims: dict) -> bool:
    from backend.core.permissions import _role, _is_staff, _ADMIN_ROLES
    return _is_staff(claims) and _role(claims) in _ADMIN_ROLES
    # Para módulos de cliente: return not _is_staff(claims) and _role(claims) in _ADMIN_ROLES
```

### Padrão de Rota HTML — Listagem

```python
@router.get("/fontes-base", response_class=HTMLResponse)
def fontes_base(request: Request, claims: dict = Depends(exige_internal_user)):
    from backend.modules.pages.routes import _user_ctx
    return templates.TemplateResponse(request, "catalogo/fontes_base.html", {
        "axys_user":      _user_ctx(claims),
        "page_module":    "Fontes-Base",
        "page_section":   "Fontes-Base",
        "active_section": "fontes-base",
        "fontes":         get_fontes(),
    })
```

### Padrão de Rota HTML — Formulário Cadastro/Edição

```python
# Cadastro: redireciona se sem permissão de escrita
@router.get("/fontes-base/novo", response_class=HTMLResponse)
def fonte_base_novo(request: Request, claims: dict = Depends(exige_internal_user)):
    from urllib.parse import quote
    if not _pode_editar(claims):
        msg = quote("Seu perfil não tem permissão para cadastrar registros.")
        return RedirectResponse(url=f"/fontes-base?msg={msg}&type=danger", status_code=303)
    return templates.TemplateResponse(request, "catalogo/fonte_base_form.html", {
        ..., "modo": "novo", "fonte": None, "pode_editar": True,
    })

# Edição: abre congelado se sem permissão
@router.get("/fontes-base/{id}/editar", response_class=HTMLResponse)
def fonte_base_editar(fonte_id: int, request: Request, claims: dict = Depends(exige_internal_user)):
    fonte = obter_fonte_para_edicao(fonte_id)
    return templates.TemplateResponse(request, "catalogo/fonte_base_form.html", {
        ..., "modo": "editar", "fonte": fonte, "pode_editar": _pode_editar(claims),
    })
```

### Padrão de Rota API (form data)

```python
@router.post("/api/fontes-base")
async def criar_fonte(
    codigo: str = Form(...),
    nome:   str = Form(...),
    ordem:  str = Form("DATA"),
    claims: dict = Depends(exige_internal_admin),  # escrita = admin/owner
):
    import psycopg2
    try:
        result = criar_ou_atualizar_fonte(None, codigo, nome, True, ordem, _audit_label(claims))
    except psycopg2.errors.UniqueViolation:
        return JSONResponse({"success": False, "message": "..."}, status_code=409)
    return JSONResponse(result, status_code=200 if result["success"] else 400)
```

**Dados recebidos via `Form(...)` — não JSON body.**
**Erros de permissão (403) retornam `{"detail": "..."}` — JS deve ler `message || detail`.**

### Padrão de Serviço

```python
def criar_ou_atualizar_fonte(fonte_id, codigo, nome, ordem, usuario) -> dict:  # sem 'ativa' (não editável no form)
    with easy_conn() as conn:
        cur = conn.cursor()

        if fonte_id is None:         # INSERT
            ...
            audit_service.registrar(..., conn=conn)
            conn.commit()
            return {"success": True, "message": "...", "id": new_id}

        else:                        # UPDATE
            antes = _snapshot(cur, fonte_id)
            if _sem_mudanca(antes, codigo, nome, ordem):  # 'ativa' preservado, fora do diff
                return {"success": True, "unchanged": True, "message": "Nenhuma alteração a ser aplicada.", "id": fonte_id}
            ...
            audit_service.registrar(..., conn=conn)
            conn.commit()
            return {"success": True, "message": "...", "id": fonte_id}
```

**Regras:**
- `conn` passado para `audit_service.registrar()` → audit na mesma transação
- `conn.commit()` apenas no serviço, nunca na rota
- `_snapshot()` lê estado anterior antes de qualquer mutation
- Retorno sempre `dict` com `success: bool` e `message: str`

### Detecção de alterações (diff)

```python
antes = _snapshot(cur, fonte_id)
# 'ativa' NÃO entra no diff do form (status não é editável aqui; é preservado no UPDATE).
if (antes["codigo"], antes["nome"], antes["ordem_edicao"], ...) == (codigo, nome, ordem, ...):
    return {"success": True, "unchanged": True, "message": "Nenhuma alteração a ser aplicada."}
```

- Se igual: retorna `unchanged=True` sem gravar nem auditar
- O frontend usa `result.body.unchanged` para determinar `type=info` vs `type=success`

### `_audit_label(claims)` — identificador do usuário

```python
def _audit_label(claims: dict) -> str:
    name  = claims.get("name") or claims.get("email", "sistema")
    email = claims.get("email", "")
    return f"{name} — {email}" if email and name != email else name
```

Formato nos logs: `"Renan Dias — rdias07@live.com"`

### Respostas da API

| Situação | `success` | `unchanged` | HTTP |
|---|---|---|---|
| Operação realizada | `true` | — | 200 |
| Sem mudança | `true` | `true` | 200 |
| Erro de negócio | `false` | — | 400 |
| Código duplicado | `false` | — | 409 |
| Erro interno | — | — | 500 |

---

## 10. Auditoria

### Tabelas

| Tabela | Propósito |
|---|---|
| `audit.logs` | alterações em dados (INSERT/UPDATE/DELETE) |
| `audit.login_logs` | eventos de autenticação (LOGIN/LOGOUT/LOGIN_FALHA) |
| `audit.api_logs` | chamadas externas à API (writes only — futuro) |
| `audit.logs_retencao` | políticas de retenção (lookup) |
| `audit.criterio_retencao` | mapeamento (schema, tabela) → política |

### `audit.logs` — o que registrar

| Campo | Valor |
|---|---|
| `log_schema` | schema do banco (ex: `"cpu"`) |
| `log_tabela` | tabela (ex: `"fontes"`) |
| `log_registro_id` | PK do registro como texto |
| `log_acao` | `"INSERT"` · `"UPDATE"` · `"DELETE"` |
| `log_usuario` | `_audit_label(claims)` — `"Nome — email"` |
| `log_ip` | IP da requisição (opcional) |
| `log_dados_antes` | JSONB do estado anterior (None em INSERT) |
| `log_dados_depois` | JSONB do estado posterior (None em DELETE) |

**Regra:** `audit_service.registrar()` é chamado dentro da transação do serviço (mesmo `conn`). Se o commit falhar, o log não é gravado — consistência garantida.

**Não auditar** operações sem mudança real (`unchanged=True`).

### `audit.login_logs` — eventos de autenticação

| Evento | `log_acao` | Registrado quando |
|---|---|---|
| Login bem-sucedido | `LOGIN` | POST /login retorna token válido |
| Login com falha | `LOGIN_FALHA` | credenciais inválidas ou sem contrato |
| Logout | `LOGOUT` | GET /login/logout |

Inclui: `log_ip`, `log_user_agent`, `log_detalhes` (motivo em caso de falha).

**Redefinição de senha** → `audit.logs` (schema `hub`, tabela `users`, acao `UPDATE`) — não vai para `login_logs`.

### Retenção

- Determinada no cleanup job — **não** gravada por linha em `audit.logs`
- Schema `cpu.*` → todos permanentes
- Cleanup: dias 5/10/15/20/25 de cada mês, 02h00 (`backend/core/audit_cleanup.py`)
- Tabelas sem critério → não deletadas (seguro por omissão)

---

## 11. Segurança

### Autenticação

- JWT em cookie `easy_token` (HttpOnly, Secure em produção, SameSite=Lax)
- `require_auth` como `Depends` em toda rota protegida
- `decode_token()` valida assinatura e expiração
- Expiração: 8 horas (`max_age=8*3600`)

### Modelo de Perfis e Permissões

**Arquivo:** `backend/core/permissions.py`

Dois eixos definem o acesso:

| Claim JWT | Valores | Significado |
|---|---|---|
| `is_staff` | `true` / `false` | `true` = equipe interna Axys · `false` = usuário cliente (tenant) |
| `role` | `user` / `admin` / `owner` | nível de permissão dentro do grupo |

**Hierarquia:** `owner` > `admin` > `user`

#### Funções disponíveis (usar como `Depends`)

| Função | Condição | Uso típico |
|---|---|---|
| `exige_internal_user` | `is_staff=True` (qualquer role) | leitura e cadastro em módulos administrativos |
| `exige_internal_admin` | `is_staff=True` + role `admin` ou `owner` | inativar, reativar, operações destrutivas internas |
| `exige_internal_owner` | `is_staff=True` + role `owner` | configurações críticas do sistema |
| `exige_client_user` | `is_staff=False` (qualquer role) | funcionalidades do tenant |
| `exige_client_admin` | `is_staff=False` + role `admin` ou `owner` | gestão de dados do tenant |
| `exige_client_owner` | `is_staff=False` + role `owner` | configurações críticas do tenant |
| `exige_admin` | role `admin` ou `owner` (qualquer time) | operações que qualquer admin pode fazer |

#### Aplicação nas rotas de fontes-base (referência canônica)

```python
# Leitura → qualquer membro interno
GET  /fontes-base                   → Depends(exige_internal_user)

# Cadastro → user: redireciona · admin/owner: abre form
GET  /fontes-base/novo              → Depends(exige_internal_user) + redirect se não _pode_editar

# Edição → user: form congelado · admin/owner: form editável
GET  /fontes-base/{id}/editar       → Depends(exige_internal_user) + pode_editar=_pode_editar(claims)

# Escrita → somente admin ou owner
POST /api/fontes-base               → Depends(exige_internal_admin)
PUT  /api/fontes-base/{id}          → Depends(exige_internal_admin)
POST /api/fontes-base/{id}/inativar → Depends(exige_internal_admin)
POST /api/fontes-base/{id}/reativar → Depends(exige_internal_admin)
```

#### Regra para novas telas

Ao definir uma nova tela, declarar explicitamente:
1. **Quem pode acessar a listagem/form** → qual função de permissão
2. **Quem pode escrever (criar/editar)** → pode ser diferente da leitura
3. **Quem pode inativar/reativar/excluir** → geralmente `_admin` ou `_owner`

#### `_DEV_CLAIMS` (bypass local)

```python
{
    "is_staff": True,
    "role": "owner",       # passa por todas as verificações de permissão
    "tenant_code": "DEV",
    "tenant_name": "Desenvolvimento Local",
    ...
}
```

### Bypass de desenvolvimento

```python
EASY_AUTH_BYPASS=true   # em .env.local
```

- Em bypass: usa cookie real se existir; cai em `_DEV_CLAIMS` se não houver cookie
- `_DEV_CLAIMS` tem `is_staff=True`, `role="owner"` — passa qualquer permissão
- **Nunca ativar em produção** (`.env` base tem `EASY_AUTH_BYPASS=false`)

### Redirect automático

HTTP 401 em request HTML → redirect 303 para `/login`.
HTTP 403 em request HTML → retorna JSON `{"detail": "..."}` (sem redirect — intencional).

### Sanitização de inputs

- Campos de texto: `maxlength` no HTML + validação no serviço
- Caixa alta: via JS (`.fg-upper`) — armazenado já em maiúsculas
- Código único: constraint `UNIQUE` no banco + tratamento de `UniqueViolation` na rota

### CORS e CSRF

- CORS configurado via `EASY_CORS_ORIGINS` no `.env`
- Formulários JS usam `fetch` com `FormData` (sem token CSRF no modelo atual)
- Cookie `SameSite=Lax` mitiga CSRF para requisições cross-site

---

## Retroanálise com modificações impactantes (transversal)

Padrão de UX para **qualquer fluxo que retroage no tempo** (orçamento retroagido, composição isolada retroagida, gráfico de série histórica). Regra de negócio: `CATALOGO_BUSINESS_RULES.md §9.5`.

- A app **lê o passado pela trinca atômica** `(preço@E, unidade@E, descrição@E)` — nunca pareia preço histórico com a **unidade vigente** (enganaria: ex. vergalhão `barra→kg`, "barateou" sendo que subiu).
- A app **NÃO converte unidade automaticamente** (domínio aberto). Ao detectar **divergência de unidade** entre a época E e a vigente (ou mudança dentro do intervalo), exibe **aviso ao usuário** pedindo o **fator de conversão**, e **registra como observação** no artefato (orçamento/composição/série).
  - Componente: alerta/modal não-bloqueante (padrão `#page-alert-container` / modal), **um aviso por insumo divergente** (ou agrupado, com a lista). Nunca `confirm()` nativo.
  - O fator informado fica **persistido como observação** no artefato retroagido (rastreável).
- Mudança só de **descrição** (texto) = aviso **informativo** (não bloqueia, não pede fator). O gatilho de conversão é **unidade**.
- Sem fator definido: a série/gráfico **não cruza** unidades diferentes (não plota número enganoso); o orçamento retroagido marca o item como "pendente de conversão".

> Resumo: storage entrega a unidade correta de cada época (§9.5); a **decisão de conversão é do usuário**, sempre visível e registrada — a app só **detecta e avisa**.

---

## 12. Checklist de Reutilização

### Ao criar nova tela de Listagem

- [ ] `extends "base/base_sidebar.html"`
- [ ] Include do sidebar do módulo em `{% block sidebar %}`
- [ ] Breadcrumb com links corretos
- [ ] `#page-alert-container` entre breadcrumb e filtros
- [ ] Leitura de `?msg=` e `?type=` no `DOMContentLoaded` → `showPageAlert`
- [ ] Botões em `.cpu-actions` com IDs padronizados
- [ ] Botão Reativar oculto por padrão (`ae-hidden`)
- [ ] Tabela com `data-*` em cada `<tr>`; `<td>` de status com `class="js-status-cell"`
- [ ] Colunas ordenáveis (`<th class="ae-sortable">` + `AXYS.makeSortable`); linha vazia `ae-no-select` (ver "Padrões de tabela")
- [ ] Modal de detalhamento lendo `data-*` (sem fetch)
- [ ] Modal de confirmação substituindo `confirm()` nativo
- [ ] Guards em todos os botões (sem seleção → `showPageAlert info`)
- [ ] CSS do módulo em `{% block page_css %}`
- [ ] JS do módulo em `{% block page_scripts %}`

### Ao criar nova tela de Cadastro/Edição

- [ ] `extends "base/base_sidebar.html"`
- [ ] Breadcrumb de 3 níveis: `Início › Módulo › Cadastro|Edição`
- [ ] `pode_editar` passado pela rota (`_pode_editar(claims)`)
- [ ] Rota `/novo` redireciona com `type=danger` se `not pode_editar`
- [ ] `RedirectResponse` importado em `routes_{modulo}.py`
- [ ] Banner `.ae-alert-info` somente leitura quando `not pode_editar`
- [ ] `#flash-container` para erros inline
- [ ] `<form>` sem `method`/`action` — submit interceptado por JS
- [ ] `disabled` em todos os campos quando `not pode_editar`
- [ ] `.fg-upper` em campos que devem ser caixa alta
- [ ] Campos obrigatórios com `required` + validação JS antes do fetch
- [ ] Status NÃO editável no form (badge read-only na 1ª linha em modo editar; ativar/inativar é ação da listagem)
- [ ] Botão Salvar ausente quando `not pode_editar` (apenas "Voltar")
- [ ] JS com `{% if not pode_editar %}return;{% endif %}` no início do script
- [ ] Redirecionamento com `?msg=&type=` após sucesso
- [ ] `showFormError(result.body.message || result.body.detail)` para erros

### Componentes de Backend obrigatórios

- [ ] `_user_ctx(claims)` em todas as rotas HTML
- [ ] `_audit_label(claims)` em todas as operações de escrita
- [ ] `_snapshot()` antes de qualquer UPDATE
- [ ] Diff check antes de auditar/persistir UPDATE
- [ ] `audit_service.registrar()` dentro da mesma transação
- [ ] `conn.commit()` apenas no serviço
- [ ] Captura de `psycopg2.errors.UniqueViolation` nas rotas
- [ ] Retorno `{"success": bool, "message": str}` padronizado

### Componentes de Auditoria obrigatórios

- [ ] INSERT → `acao="INSERT"`, `antes=None`, `depois={snapshot}`
- [ ] UPDATE → `acao="UPDATE"`, `antes={snapshot}`, `depois={novo_estado}`
- [ ] UPDATE sem mudança → não auditar, retornar `unchanged=True`
- [ ] Soft delete (inativar) → `acao="UPDATE"` (não DELETE)
- [ ] Novo schema/tabela → adicionar em `audit.criterio_retencao` com política adequada

### Padrão de novos módulos (sidebar)

1. Criar `modules/{modulo}/routes.py` com _audit_label e _pode_editar locais
2. Criar `modules/{modulo}/service.py` com _snapshot próprio
3. Criar `modules/{modulo}/__init__.py`
4. Criar `partials/sidebar_{modulo}.html` seguindo o padrão de `sidebar_catalogo.html`
5. Adicionar `active_section` ao contexto da rota
6. Importar router em `app.py` como `app.include_router()`
7. Adicionar CSS específico em `easy_{modulo}.css`
8. Após validação das telas: criar `templates/{modulo}/{modulo}_work_pages.md` (ver seção 13)

---

## 13. Documentação de Módulo — Work Pages

### Propósito

Após a validação das telas de um módulo, criar um arquivo `{modulo}_work_pages.md` dentro de `templates/{modulo}/`. Este arquivo é a documentação **viva** do módulo — não de padrões (isso fica no `config_ui_ux_easy.md`), mas do **que existe, por que existe e o que ainda falta**.

**Distingue-se do `config_ui_ux_easy.md` da seguinte forma:**

| `config_ui_ux_easy.md` | `{modulo}_work_pages.md` |
|---|---|
| Como construir qualquer tela | O que este módulo faz |
| Padrões de UI/UX/Backend | Conceitos de negócio |
| Sistema inteiro | Módulo específico |
| Referência para construção | Referência para manutenção |

### Quando criar

Ao final da sessão de validação de um módulo — quando as telas estiverem aprovadas e funcionando. Criar enquanto o contexto está fresco.

### O que deve conter

```
1. O que é o módulo (conceito de negócio, não técnico)
2. Estrutura de arquivos do módulo
3. Para cada tela:
   - URL, template, permissões
   - O que aparece (colunas, campos, cards)
   - Conceitos de negócio dos campos (por que existem, o que significam)
   - Regras de negócio específicas
   - Comportamento por perfil de usuário
4. Sidebar: grupos, links ativos e placeholders
5. Auditoria: o que é registrado e como
6. Seed: dados iniciais e sua origem
7. O que está pendente / placeholder (links #, funcionalidades futuras)
```

### Módulos com work pages criadas

| Módulo | Arquivo | Status |
|---|---|---|
| Catálogo | `templates/catalogo/catalogo_work_pages.md` | ✅ criado em 31/05/2026 |

### Quando atualizar

- Ao implementar novas telas no módulo
- Ao alterar regras de negócio
- Ao resolver um placeholder (substituir `#` por URL real)
- Ao mudar permissões de uma rota

---

## 14. Checklist para Validação de Nova Tela

Use este checklist **antes de considerar uma tela "pronta"**. Cada item deve estar ✅.

### Templates & Hierarquia

- [ ] Tela extends `base/base_app.html` ou `base/base_sidebar.html` (correto para tipo)?
- [ ] Bloco `{% block title %}` definido com título curto
- [ ] Bloco `{% block page_css %}` aponta para CSS correto
- [ ] Blocos adicionais (`sidebar`, `main_content`, `panel_content`, `page_scripts`) preenchidos
- [ ] Nenhum CSS inline (`style="..."`) — todo em arquivo `.css`

### Layout & Componentes

- [ ] Respeita grid system do design (2/3/4 colunas)
- [ ] Cards usam classe `.ae-card` (ou `.ae-launcher-card` se MAIN)
- [ ] Tabelas usam classe `.ae-table` com hover e cabeçalho destacado
- [ ] Inputs herdam `font-family: inherit`
- [ ] Rótulos (labels) seguem padrão de caixa alta (via JS `.fg-upper`)
- [ ] Cores usam variáveis CSS (`--ae-*`), nunca valores hardcoded

### Backend & Rota

- [ ] Rota decorada com `@router.get()` ou `@router.post()`
- [ ] Função com `Depends(require_auth)` para extrair `claims`
- [ ] Contexto inclui `axys_user = _user_ctx(claims)`
- [ ] Contexto inclui `page_module` e `page_section`
- [ ] Permissões verificadas (staff? apps_licenciadas? roles?)
- [ ] TemplateResponse passa contexto correto

### Auditoria & Segurança

- [ ] Se formulário POST, chamou `audit_service.registrar_acao(...)`
- [ ] Campos sensíveis não aparecem em logs/auditoria
- [ ] Acesso a dados filtra por `tenant_uuid` (multitenancy)
- [ ] CSRF token no formulário (gerado automaticamente por Jinja2 + middleware)

### Header & Footer

- [ ] Header exibe logo, tenant_code, tenant_name, user.name
- [ ] Footer exibe apps_licenciadas (ou "Módulo Administrativo" se staff)
- [ ] Relógio atualiza via JS (hora + data)
- [ ] Ícone "Sair" leva a `/login/logout`

### JavaScript (se houver)

- [ ] Nenhum JS inline em template — todo em arquivo separado em `static/js/pages/{modulo}/`
- [ ] Arquivo incluído **ao final do body** (não no head)
- [ ] JS reutilizável (2+ telas) está em `static/js/widgets/`
- [ ] Função global necessária está em `static/js/core/axyspro.core.js`
- [ ] Modal usa `axyspro.modal()` (Universal Modal)

### Responsividade (se aplicável)

- [ ] Tela funciona em viewport >= 1024px (desktop)
- [ ] Não assume tela menor (mobile não é prioridade em AxysEasy)

### Teste Manual

- [ ] Tela carrega sem erros (browser console limpo)
- [ ] Dados aparecem corretamente
- [ ] Interações (cliques, submissões) funcionam
- [ ] Redirecionamentos corretos após ação
- [ ] Sem "console.log" ou `print()` deixados no código
