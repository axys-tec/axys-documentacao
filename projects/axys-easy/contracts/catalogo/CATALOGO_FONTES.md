# Catálogo — Contrato Funcional: Tela Fontes

**Status:** Contrato Funcional (v0.2)
**Data:** 2026-06-03
**Tabela:** `catalogo.fontes`
**Regras globais:** ver [CATALOGO_BUSINESS_RULES.md](CATALOGO_BUSINESS_RULES.md).
**Comportamento/UX da tela:** `backend/frontend/templates/catalogo/catalogo_work_pages.md`.

> Fonte = origem de preços/composições (SINAPI, CDHU, FDE, ORSE, EMOP, AXYS). É dado **estrutural** — raramente criado por usuário final; majoritariamente seedado.
> **Acesso ao módulo Catálogo:** exclusivo da equipe interna Axys (`is_staff=True`); clientes não acessam.

---

## 1. Modelo

| Campo | Regra |
|---|---|
| `fte_codigo` | Único, não vazio, **maiúsculas**. **Imutável após criação** — chave operacional usada por parser/import/integrações. Troca de código = operação administrativa controlada, não edição comum. |
| `fte_nome` | Não vazio, **maiúsculas**. Editável. |
| `fte_ordem_edicao` | `DATA` (recente = maior `edi_mes_ref`) ou `VERSAO` (recente = maior `edi_codigo_versao`, ex.: CDHU `'201'`). |
| `fte_ativa` | Liga/desliga a fonte na operação. Default `TRUE`. |

`AXYS` = composições próprias do tenant — sem edição mensal, preço informado direto (sem linha em `precos_insumo`).

---

## 2. Comportamento

- **Listagem**: todas as fontes; ordenar por `fte_codigo`; indicar ativa/inativa e contagem de edições.
- **Criação**: restrita (estrutural). Exige `fte_codigo` + `fte_nome` + `fte_ordem_edicao`.
- **Edição**: `fte_nome`, `fte_ordem_edicao`, `fte_ativa`. **`fte_codigo` não muda** (chave referenciada por código).
- **Ativar/Inativar**: alterna `fte_ativa`. Inativar **não** apaga dados — apenas oculta da operação corrente.

## 3. Filtros
- Por status (ativa/inativa); busca por `fte_codigo`/`fte_nome`.

## 4. Validações
- `fte_codigo` único e não vazio (`uq_fontes_codigo`, `ck_fontes_codigo_vazio`).
- `fte_nome` não vazio.
- `fte_ordem_edicao` ∈ {`DATA`,`VERSAO`} (`ck_fontes_ordem_edicao`).

## 5. Exclusão
- **Não há exclusão dura** de fonte com edições/insumos/composições vinculados — FK `ON DELETE RESTRICT`. Operação suportada = **inativar** (`fte_ativa=false`).

## 6. Permissões
| Ação | Permissão |
|---|---|
| Acessar o módulo | interno (`is_staff=True`) |
| Abrir listagem / form (GET) | `internal_user` |
| **Salvar** (criar/editar — POST/PUT) | `internal_admin` |
| Detalhar (modal) | qualquer autenticado |
| Inativar / Reativar | `internal_admin` |

Sem permissão de salvar, o form abre **congelado** (read-only); ações restritas retornam 403/redirect com alerta.

## 7. Integrações
- Dirige `catalogo.edicoes` (ver [CATALOGO_EDICOES.md](CATALOGO_EDICOES.md)), `insumos`, `composicoes`.
- `fte_ordem_edicao` define qual edição é a "vigente" nas consultas do catálogo.

## 8. Auditoria
- Toda escrita registrada em `audit.logs` (`log_schema='catalogo'`, `log_tabela='fontes'`), com snapshot antes/depois.
- **Sem mudança = sem gravação e sem auditoria**: o service compara o estado antes×depois; se igual, retorna `unchanged=true`, não grava, não audita (alerta âmbar na UI).
- Retenção de `catalogo.fontes` = **Permanente** (`audit.criterio_retencao`).

## 9. Pontos abertos (a revisar)
- Se a UI permite **criar fonte nova** ou só gerencia o conjunto seedado.
- Mecanismo administrativo controlado para eventual troca de `fte_codigo`.
