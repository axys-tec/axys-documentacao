# AxysEasy — Módulo Catálogo: Documentação de Telas e Funcionalidades

> **Validado em:** 30/05/2026
> Este arquivo documenta o que existe, como funciona e por que foi construído assim.
> Use como referência para manutenção, refatoração e entendimento do módulo.

---

## O que é o módulo Catálogo

**Catálogo** = Catálogo de Preços Unitários.

Gerencia as fontes de referência de preços utilizadas em orçamentos de obras — SINAPI, CDHU, FDE, ORSE, EMOP, AXYS e outras. É o módulo de catálogo base do sistema: sem fontes, sem edições, sem insumos, sem composições.

**Acesso:** exclusivo da equipe interna Axys (`is_staff=True`). Usuários clientes não têm acesso a este módulo.

---

## Estrutura de arquivos do módulo

```
backend/api/easy/routes_catalogo.py          ← rotas HTML + API
backend/core/catalogo_service.py             ← lógica de dados, queries, auditoria
backend/easy/templates/catalogo/
  ├── fontes_base.html                  ← listagem de fontes-base
  ├── fonte_base_form.html              ← cadastro / edição / somente leitura
  └── catalogo_work_pages.md                 ← este arquivo
backend/easy/templates/partials/
  └── sidebar_catalogo.html                  ← sidebar de navegação do módulo
backend/easy/static/css/easy_catalogo.css    ← estilos exclusivos do módulo
backend/easy/static/js/easy_catalogo.js     ← comportamentos JS do módulo
```

---

## Tela: Main — Launcher do módulo (`/main`)

**Template:** `app/main.html`
**Perfil:** `is_staff=True` (equipe interna)

### O que aparece

Grid de 4 cards para os submódulos do Catálogo:

| Card | Ícone | Destino | Status |
|---|---|---|---|
| Fontes-Base | `FNT` | `/fontes-base` | ✅ implementado |
| Insumos | `INS` | `#` | 🔲 placeholder |
| Composições de Preço | `Catálogo` | `#` | 🔲 placeholder |
| Caderno de Composições | `CDC` | `#` | 🔲 placeholder |

### Comportamento

- Cards com `href="#"` são placeholders visuais — sem funcionalidade ainda
- Ao implementar cada submódulo, substituir `#` pela URL real e registrar no `sidebar_catalogo.html`

---

## Tela: Listagem de Fontes-Base (`/fontes-base`)

**Template:** `catalogo/fontes_base.html`
**Permissão:** `exige_internal_user` (leitura para qualquer membro interno)
**Service:** `catalogo_service.get_fontes()`

### Conceito: o que é uma Fonte-Base

Uma **fonte** é um catálogo de preços de referência. Cada fonte publica edições periódicas com preços de insumos e composições. O sistema importa essas edições e as vincula à fonte correspondente.

Exemplos de fontes:
- **SINAPI** — Caixa Econômica Federal, publicação mensal, ordenação por DATA
- **CDHU** — Companhia de Desenvolvimento Habitacional e Urbano, ordenação por VERSÃO (código numérico)
- **FDE** — Fundação para o Desenvolvimento da Educação
- **AXYS** — Composições próprias do tenant, sem edição mensal

### Colunas da tabela

| Coluna | Origem | Observação |
|---|---|---|
| Código | `fte_codigo` | Monospace, preto. Sempre em maiúsculas. Único no banco. |
| Nome | `fte_nome` | Descrição completa da fonte. Sempre em maiúsculas. |
| Ordem | `fte_ordem_edicao` | `DATA` ou `VERSÃO` — como determinar a edição mais recente |
| Última Versão | `edi_codigo_versao` + `edi_mes_ref` | Via `LEFT JOIN LATERAL` em `catalogo.edicoes` (última edição da fonte) |
| Status | `fte_ativa` | Badge verde (Ativa) ou âmbar (Inativa) |

### Campo `fte_ordem_edicao` — por que existe

Cada fonte tem uma lógica diferente de publicação:
- **`DATA`** — a edição mais recente é a com `edi_mes_ref` mais alto (ex: SINAPI usa meses)
- **`VERSÃO`** — a edição mais recente é a com `edi_codigo_versao` mais alto (ex: CDHU usa versão "201", "202"...)

Sem esse campo, não é possível saber qual edição usar como referência em um orçamento.

**Constraint no banco:** `CHECK (fte_ordem_edicao IN ('DATA', 'VERSÃO'))` — com til.

### Filtros disponíveis

- **Busca textual** — filtra pelo `data-nome` da linha (código + nome concatenados como `CODIGO — NOME`)
- **Exibir inativos** — checkbox, sem restrição de perfil (leitura livre para qualquer usuário)

### Ações e permissões por botão

| Botão | Rota | Permissão real | Comportamento sem permissão |
|---|---|---|---|
| Cadastrar | GET `/fontes-base/novo` | `internal_user` + redirect se não admin | Redireciona com alert danger |
| Detalhar | — (modal local) | qualquer usuário autenticado | Modal abre sem restrição |
| Editar | GET `/fontes-base/{id}/editar` | `internal_user` | Abre form congelado se user |
| Desativar | POST `/api/fontes-base/{id}/inativar` | `internal_admin` | HTTP 403 → alert danger |
| Reativar | POST `/api/fontes-base/{id}/reativar` | `internal_admin` | HTTP 403 → alert danger |

### Regra de inativação

Antes de inativar, o sistema verifica dependências ativas em `catalogo.fonte_versoes` (se a tabela existir). Se houver dependências, a inativação é bloqueada com mensagem explicativa.

### Modal de detalhes — campos exibidos

Lidos dos `data-*` da linha selecionada, sem fetch ao backend:
- Código + badge de status
- Descrição
- Ordem de edição
- Última atualização (data + responsável)
- Criado em (data + responsável)

---

## Tela: Cadastro / Edição de Fonte-Base

**Template:** `catalogo/fonte_base_form.html`
**URLs:** `/fontes-base/novo` · `/fontes-base/{id}/editar`
**Permissão GET:** `exige_internal_user` (todos podem abrir)
**Permissão POST/PUT:** `exige_internal_admin` (somente admin/owner podem salvar)

### Modos de operação

| URL | `modo` | `pode_editar` | Comportamento |
|---|---|---|---|
| `/fontes-base/novo` | `"novo"` | `True` (se admin) | Form em branco editável |
| `/fontes-base/novo` | — | `False` (se user) | Redirect para listagem com alerta |
| `/fontes-base/{id}/editar` | `"editar"` | `True` (se admin) | Form preenchido editável |
| `/fontes-base/{id}/editar` | `"editar"` | `False` (se user) | Form preenchido congelado |

### Campos do formulário

| Campo | DB | Regra | Visível em |
|---|---|---|---|
| Código | `fte_codigo` | Obrigatório, maiúsculas, único | Cadastro + Edição |
| Descrição | `fte_nome` | Obrigatório, maiúsculas | Cadastro + Edição |
| Ordenação | `fte_ordem_edicao` | Select: `DATA` \| `VERSÃO` | Cadastro + Edição |
| Ativa | `fte_ativa` | Checkbox, default `true` | **Edição apenas** |

**Nunca exibir no form:** `fte_criado_em`, `fte_criado_por`, `fte_atualizado_em`, `fte_atualizado_por` — esses campos são preenchidos automaticamente.

### Validações

- **Frontend:** campos obrigatórios verificados antes do fetch
- **Backend:** `UniqueViolation` em `fte_codigo` → HTTP 409 com mensagem amigável
- **Banco:** constraint `ck_fontes_codigo_vazio`, `ck_fontes_nome_vazio`, `ck_fontes_ordem_edicao`

### Detecção de alterações (diff)

Antes de gravar um UPDATE, o service compara:
```python
(antes["codigo"], antes["nome"], antes["ativa"], antes["ordem_edicao"]) == (codigo, nome, ativa, ordem)
```
Se igual → retorna `unchanged=True`, não grava, não audita, exibe alerta âmbar.

---

## Sidebar do módulo (`sidebar_catalogo.html`)

Grupos de navegação com `active_section` controlando o highlight:

| Grupo | `data-group` | Itens | Status |
|---|---|---|---|
| Fontes-Base | `fontes-base` | Listagem ✅ · Cadastrar → `/fontes-base/novo` | ✅ funcional |
| Insumos | `insumos` | Listagem # · Cadastrar # | 🔲 placeholder |
| Composições de Preço | `composicoes` | Listagem # · Cadastrar # · Por Fonte # · Próprias # | 🔲 placeholder |
| Caderno de Composições | `caderno` | Listagem # · Cadastrar # · Encargos # · Leis # | 🔲 placeholder |

> **Nota:** O link "Cadastrar" em Fontes-Base no sidebar ainda aponta para `#`. Ao implementar o form de cadastro como fluxo direto (sem passar pela listagem), atualizar para `/fontes-base/novo`.

---

## Auditoria do módulo

Todas as operações de escrita são registradas em `audit.logs` com `log_schema="catalogo"` e `log_tabela="fontes"`.

| Operação | `log_acao` | `log_dados_antes` | `log_dados_depois` |
|---|---|---|---|
| Cadastrar | `INSERT` | `null` | snapshot completo |
| Editar (com mudança) | `UPDATE` | snapshot anterior | novo estado |
| Editar (sem mudança) | — | — | — (não registrado) |
| Inativar | `UPDATE` | snapshot anterior | snapshot com `ativa: false` |
| Reativar | `UPDATE` | snapshot anterior | snapshot com `ativa: true` |

**Retenção:** `catalogo.fontes` está configurada como **Permanente** em `audit.criterio_retencao` — registros nunca expiram.

---

## Seed inicial das fontes

As fontes padrão do sistema são inseridas via `easy_seed.sql`:

| Código | Nome | Ordem |
|---|---|---|
| SINAPI | SINAPI — Caixa Econômica Federal | DATA |
| CDHU | CDHU — Companhia de Desenvolvimento Habitacional e Urbano | VERSÃO |
| FDE | FDE — Fundação para o Desenvolvimento da Educação | DATA |
| ORSE | ORSE — Orçamento de Obras de Sergipe | DATA |
| EMOP | EMOP — Empresa de Obras Públicas do Rio de Janeiro | DATA |
| AXYS | AXYS — Composições Próprias | DATA |

---

## O que está pendente / placeholder

| Item | Descrição | Impacto |
|---|---|---|
| Link "Cadastrar" no sidebar | Aponta para `#` | UX: usuário precisa ir pela listagem |
| Submódulo Insumos | Tela não implementada | Sidebar e launcher são placeholders |
| Submódulo Composições | Tela não implementada | Idem |
| Caderno de Composições | Tela não implementada | Idem |
| Verificação de dependências em `catalogo.fonte_versoes` | Tabela pode não existir (try/except com rollback) | Inativação não verifica dependências reais ainda |
| Modal de detalhes sem "Última Versão" | O modal lê `data-*` mas não exibe `ultima_versao` | Completar quando implementar edições |
