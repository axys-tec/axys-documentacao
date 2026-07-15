# Catálogo — Contrato Funcional: Tela Fontes

**Status:** Contrato Funcional (v0.2)
**Data:** 2026-06-03
**Tabela:** `catalogo.fontes`
**Índice das capabilities:** [README.md](README.md).
**Comportamento/UX da tela:** `backend/frontend/templates/catalogo/catalogo_work_pages.md`.

> Fonte = origem de preços/composições (SINAPI, CDHU, AXYS). É dado **estrutural** — raramente criado por usuário final; majoritariamente seedado. A forma de importação de **outras fontes** será doutrinada via template (fora do escopo atual).
> **Acesso ao módulo Catálogo:** exclusivo da equipe interna Axys (`is_staff=True`); clientes não acessam.

---

## 1. Modelo

| Campo | Regra |
|---|---|
| `fte_codigo` | Único, não vazio, **maiúsculas**. **Imutável após criação** — chave operacional usada por parser/import/integrações. Troca de código = operação administrativa controlada, não edição comum. |
| `fte_nome` | Não vazio, **maiúsculas**. Editável. |
| `fte_ordem_edicao` | `DATA` (recente = maior `edi_mes_ref`) ou `VERSAO` (recente = maior `edi_codigo_versao`, ex.: CDHU `'201'`). |
| `fte_ativa` | Liga/desliga a fonte na operação. Default `TRUE`. |
| `fte_tem_catalogo_insumos` | Bool, default `FALSE`. A fonte tem **catálogo de fichas de insumo** extraível (SINAPI: planilha + links de referência; CDHU: anexo)? Se `TRUE`, a edição **exige** publicar/registrar essas fichas no R2 p/ liberar o gate `edi_ins_catalogo_ok`; se `FALSE` → gate **"Não se aplica"** (regras: edicoes §5§11). Hoje AXYS=`TRUE`, SINAPI=`TRUE`, CDHU=`FALSE` — **valores a rever no reseed** ([edicoes.md §8.1](edicoes.md)): o gate é **binário "bundle publicado"**, nunca cobertura por insumo. |
| `fte_tem_caderno_metodologia` | Bool, default `FALSE`. A fonte publica **livro/caderno de metodologia** (conceitos, instruções)? SINAPI=`TRUE`; CDHU=`TRUE`; AXYS=`FALSE`. |
| `fte_catalogos_continuos` | Bool, default `FALSE`. Documentos (fichas/cadernos/critérios) **contínuos** (não mudam por edição → skip por data)? SINAPI=`TRUE`; CDHU=`FALSE` (reemite por edição); AXYS=`TRUE` (app-own). (regras: publicacao) |
| `fte_permite_manipular_dados` | Bool, default `FALSE`. **Gate de segurança** (regras: listagem §5): permite criar/editar insumos/composições/ajustes manuais nesta fonte? Só fontes **próprias** (AXYS)=`TRUE`; terceiros (SINAPI/CDHU)=`FALSE` (imutáveis — risco alto). Edição da flag **restrita a admin**. |

`AXYS` = composições/insumos próprios do tenant — sem edição mensal de fonte. **Atualizado 2026-06-07:** insumos próprios **têm preço** via **cotação de mercado** (`pri_origem='CT'`; lastro em `catalogo.insumos_cotacoes`, mediana → `insumos_preco`; ver regras: listagem §2.1). É a fonte que permite **manipulação manual** (`fte_permite_manipular_dados=TRUE`, §8.1). (Supera a nota antiga "sem linha em insumos_preco".)

---

## 2. Comportamento

- **Listagem**: todas as fontes; ordenar por `fte_codigo`; indicar ativa/inativa e contagem de edições.
- **Criação**: restrita (estrutural). Exige `fte_codigo` + `fte_nome` + `fte_ordem_edicao`; opcionais: flags `fte_tem_catalogo_insumos`, `fte_tem_caderno_metodologia`, `fte_catalogos_continuos`, `fte_permite_manipular_dados`.
- **Edição**: `fte_nome`, `fte_ordem_edicao` e as flags acima. **`fte_codigo` não muda** (chave referenciada por código). **`fte_ativa` NÃO é editável no form** (badge read-only) — muda só pela ação inativar/reativar da listagem. `fte_permite_manipular_dados` só por **admin**.
- **Ativar/Inativar**: alterna `fte_ativa` (ação da listagem). Inativar **não** apaga dados — apenas oculta da operação corrente.

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
- Dirige `catalogo.edicoes` (ver [edicoes.md](edicoes.md)), `insumos`, `composicoes`.
- `fte_ordem_edicao` define qual edição é a "vigente" nas consultas do catálogo.

## 8. Auditoria
- Toda escrita registrada em `audit.logs` (`log_schema='catalogo'`, `log_tabela='fontes'`), com snapshot antes/depois.
- **Sem mudança = sem gravação e sem auditoria**: o service compara o estado antes×depois; se igual, retorna `unchanged=true`, não grava, não audita (alerta âmbar na UI).
- Retenção de `catalogo.fontes` = **Permanente** (`audit.criterio_retencao`).

## 9. Pontos abertos (a revisar)
- Se a UI permite **criar fonte nova** ou só gerencia o conjunto seedado.
- Mecanismo administrativo controlado para eventual troca de `fte_codigo`.
