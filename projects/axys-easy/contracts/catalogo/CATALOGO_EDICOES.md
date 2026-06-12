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
| `edi_situacao_ciclo` | **Estado único** (substitui o antigo par com `edi_ativa`, removido — decisão Renan 2026-06-06, por sobreposição). `RASCUNHO` → `PUBLICADA` → `EM_REVISAO` ⇄ `PUBLICADA` · `ARQUIVADA` (raro). Default `RASCUNHO`. Ver §5. |
| `edi_revisao_nota` | Texto opcional — o que será revisado; exibido ao tenant quando `EM_REVISAO`. |
| `edi_ins_catalogo_ok` | Gate: fichas de insumo no R2 (auto-`TRUE` se fonte sem catálogo de insumos). |
| `edi_comp_catalogo_ok` | Gate: cadernos/critérios no R2 (obrigatório p/ publicar). |

Unicidade: `(edi_fte_id, edi_mes_ref)` (`uq_edicoes_fte_mes`).

---

## 2. Criação
- Por fonte: exige `edi_fte_id` + `edi_mes_ref` (1º do mês). `edi_codigo_versao` conforme `fte_ordem_edicao`.
- Bloqueia duplicidade `(fonte, mês)`.

## 3. Disponibilidade
- **Disponível para novo uso** := `edi_situacao_ciclo IN ('PUBLICADA','EM_REVISAO')`. **Acessível (histórico)** := `IN ('PUBLICADA','EM_REVISAO','ARQUIVADA')`. A "vigente" (mais recente) segue `fontes.fte_ordem_edicao` (DATA ou VERSAO) entre as disponíveis.
- **Não há mais `edi_ativa`** — o estado é único (`edi_situacao_ciclo`). Não existe "inativar/reativar" edição; o que se faz é **publicar**, abrir **revisão** (recall) e, no caso raro, **arquivar** (§5).

## 4. Importação / Reimportação
- A importação roda o parser da fonte (ver [CATALOGO_SINAPI_IMPORT_CONTRACT.md](CATALOGO_SINAPI_IMPORT_CONTRACT.md) / [CATALOGO_CDHU_IMPORT_CONTRACT.md](CATALOGO_CDHU_IMPORT_CONTRACT.md)) **para aquela edição**.
- **Entrada (CDHU):** tela `/edicoes` → seleciona caderno → botão **"importar composições"** → modal com **3 excels obrigatórios** (insumos, composições, serviços). Botão **"importar caderno"** (PDFs/R2) é fase própria. (UI = Fase 5 do `PLANO_IMPORT_CATALOGO.md`.)
- **Leis sociais por edição:** cada edição carrega `catalogo.edicoes_leis_sociais` (LS por UF/modalidade SD/CD; horista/mensalista). Origem: cabeçalhos ISD/ICD (SINAPI) ou cabeçalho de serviços (CDHU). Base da derivação SD/CD ([CATALOGO_BUSINESS_RULES.md §3.2–3.3](CATALOGO_BUSINESS_RULES.md)).
- **Hierarquia de import** (SINAPI): identidade (ISE) → órfãos (Analítico/fuzzy) → preços (ISE + LS de ISD/ICD) → composições + conferência. Não seguir sem insumos materializados.
- **Reimport idempotente**:
  - insumos = identidade vigente (upsert, precedência FONTE>MANUAL>REGRA);
  - preços/composições/custos = **imutáveis por edição** (regravados iguais).
- **Contrato de cobertura**: toda UF da edição tem linha de preço por insumo; ausência de linha = falha/não-processado (não "sem preço").

## 5. Ciclo de vida / Bloqueios (BUSINESS_RULES §10)
Estado **único** em `edi_situacao_ciclo` (não há mais `edi_ativa`):
- **`RASCUNHO`** (default) = em construção/import; **indisponível** (nada usa ainda); **editável**.
- **`PUBLICADA`** = liberada (gates ok); **disponível p/ uso novo E histórico**; **travada/imutável**.
- **`EM_REVISAO`** = só **pós-PUBLICADA**, se houver recall/correção (ex.: a SINAPI solta um recall). A edição é **reaberta** (volta a ser **mutável** p/ o staff aplicar a correção), mas **segue disponível ao tenant** como a `PUBLICADA` — com **aviso** de que está em revisão e o que será revisado (`edi_revisao_nota`, se houver). Concluída a revisão, **volta a `PUBLICADA`**.
- **`ARQUIVADA`** = descontinuada p/ **novos** usos, mas **histórico e usos existentes permanecem acessíveis**; imutável. **Não é "indisponível"** — só não inicia coisas novas. Estado **raro** (na prática quase não acontece).
- **Botão "Publicar edição"** (`RASCUNHO`→`PUBLICADA`, front) → o back valida: import "grande" feito **+** `edi_ins_catalogo_ok` (auto-`TRUE` se `fte_tem_catalogo_insumos=false`) **+** `edi_comp_catalogo_ok` (cadernos/critérios obrigatórios). Passando → `PUBLICADA` + **lock**.
- **Botão "Revisão"** (`PUBLICADA`→`EM_REVISAO`) → destrava a edição p/ correção, grava `edi_revisao_nota`, mantém disponível com aviso. **"Concluir revisão"** (`EM_REVISAO`→`PUBLICADA`) volta a travar.
- **Botão "Arquivar"** (`PUBLICADA`→`ARQUIVADA`) → tira de novos usos, mantém histórico. Raro; acesso restrito.
- **Travadas/imutáveis:** `PUBLICADA` e `ARQUIVADA`. **Mutáveis:** `RASCUNHO` e `EM_REVISAO`. Lock na camada app/parser, sem trigger. Manutenção pós-publicação só por **usuário de acesso máximo**, em tela específica.
- Correção = **reprocessar** a edição (não editar registro a registro).
- **Badge na listagem**: `RASCUNHO` (cinza) × `PUBLICADA` (verde) × `EM_REVISAO` (azul) × `ARQUIVADA` (âmbar) — ver `catalogo_work_pages.md`.
- **Status atual:** modelo/estado implementado (front + schema); as **transições** Publicar/Revisão/Arquivar serão ligadas junto das telas de import.

## 6. Auditoria
- `edi_criado_por`/`edi_criado_em` + `*_atualizado_*`.
- Changelog da fonte (SINAPI) via `catalogo.sinapi_manutencoes` — rastreia o que mudou entre edições.
- Resultado do import (inseridos/atualizados/ignorados/avisos) deve ser registrado/auditável.

## 7. Permissões
| Ação | Permissão |
|---|---|
| Abrir listagem / form (GET) | `internal_user` |
| **Salvar** edição (POST/PUT) | `internal_admin` |
| Publicar / Revisão / Arquivar (transições do ciclo) | `internal_admin` *(virá com as telas de import)* |
| Disparar import/reimport | `internal_admin` *(quando a ação existir — hoje a tela é só CRUD)* |

Auditoria: escrita em `audit.logs` (`log_tabela='edicoes'`), snapshot antes/depois (`_snapshot_edicao`); sem mudança = sem gravação/auditoria.

## 7.1 Leis Sociais e Preços manuais na tela de edição (2026-06-12)
A tela `/edicoes/{id}/editar` ganhou dois grids editáveis abaixo do form (só modo Edição, `internal_admin`, auditados):
- **Leis Sociais** → `edicoes_leis_sociais`. Grid **UF | Horista(SD%/CD%) | Mensalista(SD%/CD%)**; cada UF = 2 linhas no banco (SD e CD); `(UF,modalidade)` só grava com horista OU mensalista (CHECK). **Salvar** = replace do conjunto. `salvar_leis_sociais()`/`get_leis_sociais_grid()`.
- **Preços (SE)** → `insumos_preco`. Grid dos insumos **da fonte-base** na UF-padrão; modal de busca **elástica isolada na fonte** + input de preço por item; `pri_modalidade='SE'`, `pri_origem='C'`, `pri_sit_id=1` (COM_PRECO), upsert por `(ins,edi,uf,SE)`. SD/CD permanecem derivados das LS. `salvar_precos_edicao()`/`remover_preco_edicao()`/`get_precos_edicao()`.
- Isto **inicia a entrada manual de preço** (antes só import) — fontes próprias (AXYS) preenchem aqui; o resto vem por import.

## 8. Pontos abertos (a revisar)
- ~~Estado de "edição fechada/publicada" e política de reprocesso.~~ **Resolvido (§5):** `edi_situacao_ciclo` RASCUNHO→PUBLICADA + lock.
- Onde persistir o relatório de import (avisos/erros) para auditoria.
- UX do disparo de import (upload do arquivo × caminho fixo).
- Preço manual hoje é **SE na UF-padrão**; multi-UF/cotação (`insumos_cotacoes`) = Fase 2.
