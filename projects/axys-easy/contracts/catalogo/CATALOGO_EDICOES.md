# Catálogo — Contrato Funcional: Tela Edições

**Status:** Contrato Funcional (v0.2)
**Data:** 2026-06-03
**Tabela:** `catalogo.edicoes`
**Regras globais:** ver [CATALOGO_BUSINESS_RULES.md](CATALOGO_BUSINESS_RULES.md).
**Comportamento/UX da tela:** `backend/frontend/templates/catalogo/catalogo_work_pages.md` (seção "Tela: Listagem de Edições").
**Acesso:** módulo interno (`is_staff=True`).

> Edição = uma publicação de uma fonte. É o **ponto de entrada do import**: cria-se a edição, depois importa-se o arquivo da fonte para ela.

---

## 1. Modelo

| Campo | Regra |
|---|---|
| `edi_fte_id` | FK p/ `fontes`. |
| `edi_mes_ref` | 1º dia do mês de referência (`ck_edicoes_primeiro_do_mes`). |
| `edi_codigo_versao` | Versão p/ fontes `VERSAO` (ex.: CDHU `'201'`; SINAPI = `MM-YY`, ex.: Abr/2026 → `'04-26'`). Não vazio quando presente. |
| `edi_uf_padrao` | UF default na consulta. SINAPI: `'SP'` (todas as 27 importadas). CDHU: `'SP'` (estadual). |
| `edi_ativa` | Edição vigente/visível na operação. |

Unicidade: `(edi_fte_id, edi_mes_ref)` (`uq_edicoes_fte_mes`).

---

## 2. Criação
- Por fonte: exige `edi_fte_id` + `edi_mes_ref` (1º do mês). `edi_codigo_versao` conforme `fte_ordem_edicao`.
- Bloqueia duplicidade `(fonte, mês)`.

## 3. Ativação
- `edi_ativa` controla qual edição entra nas consultas/orçamentos. A "vigente" segue `fontes.fte_ordem_edicao` (DATA ou VERSAO).

## 4. Importação / Reimportação
- A importação roda o parser da fonte (ver [CATALOGO_SINAPI_IMPORT_CONTRACT.md](CATALOGO_SINAPI_IMPORT_CONTRACT.md) / [CATALOGO_CDHU_IMPORT_CONTRACT.md](CATALOGO_CDHU_IMPORT_CONTRACT.md)) **para aquela edição**.
- **Entrada (CDHU):** tela `/edicoes` → seleciona caderno → botão **"importar composições"** → modal com **3 excels obrigatórios** (insumos, composições, serviços). Botão **"importar caderno"** (PDFs/R2) é fase própria. (UI = Fase 5 do `PLANO_IMPORT_CATALOGO.md`.)
- **Leis sociais por edição:** cada edição carrega `catalogo.edicoes_leis_sociais` (LS por UF/modalidade SD/CD; horista/mensalista). Origem: cabeçalhos ISD/ICD (SINAPI) ou cabeçalho de serviços (CDHU). Base da derivação SD/CD ([CATALOGO_BUSINESS_RULES.md §3.2–3.3](CATALOGO_BUSINESS_RULES.md)).
- **Hierarquia de import** (SINAPI): identidade (ISE) → órfãos (Analítico/fuzzy) → preços (ISE + LS de ISD/ICD) → composições + conferência. Não seguir sem insumos materializados.
- **Reimport idempotente**:
  - insumos = identidade vigente (upsert, precedência FONTE>MANUAL>REGRA);
  - preços/composições/custos = **imutáveis por edição** (regravados iguais).
- **Contrato de cobertura**: toda UF da edição tem linha de preço por insumo; ausência de linha = falha/não-processado (não "sem preço").

## 5. Bloqueios
- Dados de uma edição importada são **imutáveis** (preços/composições/itens/custos). Correção = reprocessar a edição, não editar registro a registro.
- *(A confirmar)* travar reimport sobre edição "fechada"/publicada vs. permitir reprocesso controlado.

## 6. Auditoria
- `edi_criado_por`/`edi_criado_em` + `*_atualizado_*`.
- Changelog da fonte (SINAPI) via `catalogo.sinapi_manutencoes` — rastreia o que mudou entre edições.
- Resultado do import (inseridos/atualizados/ignorados/avisos) deve ser registrado/auditável.

## 7. Permissões
| Ação | Permissão |
|---|---|
| Abrir listagem / form (GET) | `internal_user` |
| **Salvar** edição (POST/PUT) | `internal_admin` |
| Inativar / Reativar | `internal_admin` |
| Disparar import/reimport | `internal_admin` *(quando a ação existir — hoje a tela é só CRUD)* |

Auditoria: escrita em `audit.logs` (`log_tabela='edicoes'`), snapshot antes/depois (`_snapshot_edicao`); sem mudança = sem gravação/auditoria.

## 8. Pontos abertos (a revisar)
- Estado de "edição fechada/publicada" e política de reprocesso.
- Onde persistir o relatório de import (avisos/erros) para auditoria.
- UX do disparo de import (upload do arquivo × caminho fixo).
