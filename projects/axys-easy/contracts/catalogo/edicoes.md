# Catálogo — Contrato Funcional: Tela Edições

**Status:** Contrato Funcional (v0.2)
**Data:** 2026-06-03
**Tabela:** `catalogo.edicoes`
**Índice das capabilities:** [README.md](README.md).
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
| `edi_ins_catalogo_ok` | Gate **binário**: o catálogo de fichas de insumo da fonte foi **publicado no R2 + registrado** (`catalogo.documentos`). **Não é cobertura por insumo** — a ficha é *extraída* do material da própria fonte (SINAPI: planilha + links de referência; CDHU: anexo), não redigida insumo-a-insumo; 100% de cobertura é impossível (não controlamos a fonte). Auto-`TRUE` / "Não se aplica" quando `fte_tem_catalogo_insumos = false`. |
| `edi_comp_catalogo_ok` | Gate **binário**: cadernos/critérios da fonte **publicados no R2 + registrados** (obrigatório p/ publicar). É o entregável que realmente controlamos ("nosso import se resume aos cadernos"). |

Unicidade: `(edi_fte_id, edi_mes_ref)` (`uq_edicoes_fte_mes`).

---

## 2. Criação
- Por fonte: exige `edi_fte_id` + `edi_mes_ref` (1º do mês). `edi_codigo_versao` conforme `fte_ordem_edicao`.
- Bloqueia duplicidade `(fonte, mês)`.

## 3. Disponibilidade
- **Disponível para novo uso** := `edi_situacao_ciclo IN ('PUBLICADA','EM_REVISAO')`. **Acessível (histórico)** := `IN ('PUBLICADA','EM_REVISAO','ARQUIVADA')`. A "vigente" (mais recente) segue `fontes.fte_ordem_edicao` (DATA ou VERSAO) entre as disponíveis.
- **Não há mais `edi_ativa`** — o estado é único (`edi_situacao_ciclo`). Não existe "inativar/reativar" edição; o que se faz é **publicar**, abrir **revisão** (recall) e, no caso raro, **arquivar** (§5).

## 4. Importação / Reimportação
- A importação roda o parser da fonte (ver [imports/sinapi.md](imports/sinapi.md) / [imports/cdhu.md](imports/cdhu.md)) **para aquela edição**.
- **Entrada (CDHU):** tela `/edicoes` → seleciona caderno → botão **"importar composições"** → modal com **3 excels obrigatórios** (insumos, composições, serviços). Botão **"importar caderno"** (PDFs/R2) é fase própria. (UI = Fase 5 do `o pipeline de import (imports/estagios.md)`.)
- **Leis sociais por edição:** cada edição carrega `catalogo.edicoes_leis_sociais` (LS por UF/modalidade SD/CD; horista/mensalista). Origem: cabeçalhos ISD/ICD (SINAPI) ou cabeçalho de serviços (CDHU). Base da derivação SD/CD ([imports/estagios.md §A.2–A.3](imports/estagios.md)).
- **Hierarquia de import** (SINAPI): identidade (ISE) → órfãos (Analítico/fuzzy) → preços (ISE + LS de ISD/ICD) → composições + conferência. Não seguir sem insumos materializados.
- **Reimport idempotente**:
  - insumos = identidade vigente (upsert, precedência FONTE>MANUAL>REGRA);
  - preços/composições/custos = **imutáveis por edição** (regravados iguais).
- **Contrato de cobertura**: toda UF da edição tem linha de preço por insumo; ausência de linha = falha/não-processado (não "sem preço").

## 5. Ciclo de vida / Bloqueios (regras: edicoes §5)
Estado **único** em `edi_situacao_ciclo` (não há mais `edi_ativa`):
- **`RASCUNHO`** (default) = em construção/import; **indisponível** (nada usa ainda); **editável**.
- **`PUBLICADA`** = liberada (gates ok); **disponível p/ uso novo E histórico**; **travada/imutável**.
- **`EM_REVISAO`** = só **pós-PUBLICADA**, se houver recall/correção (ex.: a SINAPI solta um recall). A edição é **reaberta** (volta a ser **mutável** p/ o staff aplicar a correção), mas **segue disponível ao tenant** como a `PUBLICADA` — com **aviso** de que está em revisão e o que será revisado (`edi_revisao_nota`, se houver). Concluída a revisão, **volta a `PUBLICADA`**.
- **`ARQUIVADA`** = descontinuada p/ **novos** usos, mas **histórico e usos existentes permanecem acessíveis**; imutável. **Não é "indisponível"** — só não inicia coisas novas. Estado **raro** (na prática quase não acontece).
- **Botão "Publicar edição"** (`RASCUNHO`→`PUBLICADA`, front) → o back valida: import "grande" feito **+** `edi_ins_catalogo_ok` (auto-`TRUE` se `fte_tem_catalogo_insumos=false`) **+** `edi_comp_catalogo_ok` (cadernos/critérios obrigatórios). Passando → `PUBLICADA` + **lock**.
- **Botão "Reabrir edição"** (`PUBLICADA`→`EM_REVISAO`, **implementado 2026-06-13**) → **SÓ owner** (`exige_internal_owner`); pede a **própria senha** num modal, revalidada igual ao login (`authenticate` via Hub, usando o documento guardado na sessão no ingresso) — **renova a sessão** no sucesso. **NÃO mexe na vigência** (itens seguem ativos; edição continua disponível ao tenant), só destrava p/ reimport e grava `edi_revisao_nota`. Reimport e Publicar passam a aceitar `EM_REVISAO`; ao re-publicar, a vigência é **recomputada** (publicada mais recente por data). Auditado.
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

## 7.1 Leis Sociais e listagem de insumos na tela de edição (2026-06-12)
A tela `/edicoes/{id}/editar` traz, abaixo do form (só modo Edição), **27 abas de UF** (todas as UFs, estáticas). A aba alterna **apenas as Leis Sociais**; a listagem de insumos é estática.

- **Leis Sociais por UF** → `edicoes_leis_sociais` (`internal_admin`, auditado). A aba ativa mostra **uma linha** de LS (texto corrido: Horista SD/CD · Mensalista SD/CD) com **Editar/Salvar/×** por linha. Cada `(edi, uf, modalidade SD/CD)` = registro próprio; CHECK exige horista OU mensalista. **Salvar por linha**, audita só se mudou (`registro_id = f"{edi}/{uf}"`). `get_leis_sociais_all()` (carrega as 27 UFs de uma vez) · `salvar_ls_uf()`/`remover_ls_uf()`.
- **Listagem de insumos** = **estática / somente leitura** — deduplicada (insumos com preço na edição, qualquer UF), **paginada**, com filtro elástico por descrição. **Sem preço e sem CRUD aqui**; o código é **link → `/insumos/{ins_id}/editar`**. `get_insumos_edicao()`.
- **O registro manual de preço migrou para a tela de Insumos** (preço SE por UF/edição) — ver [listagem.md §7](listagem.md). Os scripts de preço em lote no backend (`salvar_precos_edicao`/`get_precos_edicao`/`get_leis_sociais_grid`) ficam **preservados** para o caminho de import/migração.

## 8. Pontos abertos (a revisar)
- ~~Estado de "edição fechada/publicada" e política de reprocesso.~~ **Resolvido (§5):** `edi_situacao_ciclo` RASCUNHO→PUBLICADA + lock.

### 8.1 Pipeline `import → passar status → publicar` (PENDENTE — prioridade)
Hoje o ciclo (§5) e os gates (`edi_ins_catalogo_ok` / `edi_comp_catalogo_ok`) existem no **schema e no front**, mas **nada os vira**: toda edição nasce e permanece `RASCUNHO` com os dois gates `false` — por isso a tela mostra "Pendente" (ou "Não se aplica") em **todas** as edições. **Não há análise por trás do "Pendente"**: é leitura direta do booleano (`true`→OK, `false`→Pendente); nada varre insumo-a-insumo nem caderno-a-caderno. O "Pendente" universal é esperado, não defeito — falta o fluxo que **publica os documentos no R2, registra em `catalogo.documentos`, vira o gate e promove a edição**.

Evoluir para a cadeia explícita:
1. **Import principal** — identidade (ISE + órfãos/fuzzy → `NC`) + preços com **cobertura total de UF** + composições/custos + **conferência**.
2. **Publicação dos documentos no R2** — fichas de insumo *extraídas do material da fonte* (SINAPI: planilha + links de referência; CDHU: anexo) e cadernos/critérios → registra em `catalogo.documentos` → **vira `edi_ins_catalogo_ok` / `edi_comp_catalogo_ok`**.
3. **Botão "Publicar"** (`RASCUNHO→PUBLICADA`) — back valida o gate (import grande + os dois `*_catalogo_ok`, respeitando `fte_tem_catalogo_insumos`) e **trava** (lock).

**Seed a revisar no drop+reseed:** o valor de `fte_tem_catalogo_insumos` por fonte define se o gate de insumos se aplica. Hoje: AXYS=`true`, SINAPI=`true`, CDHU=`false`. Rever à luz da proveniência real das fichas (SINAPI por planilha/links; CDHU por anexo) para que o gate nasça coerente — fonte sem material de ficha extraível → `false` ("Não se aplica").

### 8.2-bis `edi_docs_status` + badge "Disponível para publicação" (2026-06-13 — implementado)
Primeiro passo da cadeia: o import grava **`edi_docs_status`** (JSONB) com a resolução por tipo
de doc (`metodologia|calculos|notas|cadernos|fichas: ok|indisponivel`), só no **fim de um import
concluído**. A disponibilidade dos docs do form vem de **checkboxes "Disponível"** (marcados por
padrão; desmarcar = indisponível/skip consciente). A listagem de Edições exibe **"Disponível para
publicação"** quando a edição é `RASCUNHO` **e** tem `edi_docs_status` preenchido (⇒ dados
importados E todos os docs resolvidos). Docs `indisponivel` viram aviso (⚠) — **publicar avisa e
permite**. Ver `imports/sinapi.md §8`.

**Botão Publicar (implementado 2026-06-13):** `service.publicar_edicao` + `POST /api/edicoes/{id}/publicar`
(`internal_admin`). Gate = RASCUNHO + `edi_docs_status` preenchido (consome o JSONB, não os booleanos
legados — que são setados `true` por consistência). RASCUNHO→**PUBLICADA** + lock; audita. O front
(botão no modal de detalhe da listagem) **confirma** antes, avisando se há indisponíveis. Os documentos
já foram publicados no R2/registro pelo **import** — Publicar é a **promoção de estado** que libera a
edição. **Edições já importadas (publicáveis) saem da aba de import** (`/api/edicoes/rascunho` filtra
`edi_docs_status IS NULL`). Falta só **→ARQUIVADA** e **EM_REVISAO** (recall).

### 8.2 Outros
- Onde persistir o relatório de import (avisos/erros) para auditoria.
- UX do disparo de import (upload do arquivo × caminho fixo).
- Preço manual: **multi-UF por edição já implementado** na tela de Insumos (registro SE por UF/edição); cotação (`insumos_cotacoes`) segue Fase 2. *(Atualizar §4/§7.1 e o contrato de Insumos na revisão.)*
