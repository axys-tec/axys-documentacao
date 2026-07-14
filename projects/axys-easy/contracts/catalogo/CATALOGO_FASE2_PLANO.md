# CATÁLOGO — FASE 2: COMPOSIÇÃO CONTÍNUA (identidade estável) — PLANO DE MIGRAÇÃO

**Objetivo:** eliminar `composicoes.cmp_edi_id`. Composição passa a ser **identidade vigente** (1 linha por `(fonte, código)`, como `insumos`), com custo denso por edição e histórico esparso por mudança. Executa a Regra Canônica `CATALOGO_BUSINESS_RULES.md §9.6` (ALVO já documentado no `schema.sql`), retomando a Fase 2 congelada em 2026-06-14.

**Motivo (redescoberto 2026-07-13):** busca retorna a MESMA CPU ~22× (uma por edição); `composicoes` = 1 GB / 217k linhas p/ 10.626 códigos. É o sintoma que a Fase 2 foi desenhada p/ matar.

---

## Etapa 0 — SEGURANÇA (o JSON não se perde)

**Achado que de-risca:** `cmp_descritivo` = 100% `em_revisao`, **0 fill IA**; `composicoes_historico`/`insumos_historico` = computados no import. **Tudo regenerável** por re-import em sequência (que ainda CORRIGE o histórico 12/13). Mesmo assim:

- [ ] `pg_dump` do schema `catalogo` (+ `audit`) → `_backups/fase2_pre_YYYYMMDD.dump` (fora do git).
- [ ] Export dedicado dos JSON vivos: `composicoes_historico`, `insumos_historico`, e `cmp_descritivo WHERE status<>'em_revisao'` (hoje 0 linhas) → CSV, caso queiramos re-aplicar algo manual.
- [ ] Verificar o dump restaurável (restore num DB temporário + contar linhas).

## Etapa 1 — SCHEMA (`schema.sql`, materializa o ALVO §9.6)

- [ ] **`composicoes`** = identidade vigente: DROP `cmp_edi_id` (+FK/idx); UNIQUE `(cmp_fte_id, cmp_codigo)`; `descricao/unidade/situacao/flags/cmp_descritivo/cmp_external_path` = estado **VIGENTE** (última edição).
- [ ] **`composicoes_itens`** = receita VIGENTE: `ci_cmp_id` → identidade; DROP `ci_codigo/descricao/unidade_fonte_original` (dedup — filho resolvido pela identidade; texto histórico vive no snapshot).
- [ ] **`composicoes_custo`** = série densa: ADD `cc_edi_id` NOT NULL + FK→edicoes; UNIQUE `(cc_cmp_id, cc_edi_id, cc_uf, cc_modalidade)`.
- [ ] **`composicoes_historico`** = snapshot-na-mudança: `ch_cmp_id` → identidade; `ch_dados_novos` = snapshot COMPLETO `{descricao, unidade, receita:[{tipo,id,cod,coef}], req_hash}`; padronizar validade (`edi_id_origem/nova`). **`req_hash` no snapshot** = âncora p/ reconstruir o CTC as-of-E (via `ctc/_old`).

## Etapa 2 — PARSERS / IMPORT (o que escreve o modelo novo)

- [ ] `parse_composicoes` (SINAPI/CDHU/FDE): **get-or-create** composição por `(fte, codigo)` [espelha insumos]; atualiza campos vigentes; receita → `composicoes_itens` **replace por `cmp_id`** (delete-then-insert da receita vigente).
- [ ] `parse_custos`: grava `composicoes_custo` com `cc_edi_id` (resolve `cmp_id` estável por código).
- [ ] `gerar_requests_edicao` / `_materializar_construcao`: `cmp_descritivo` vigente por código (`req_hash`); CTC já é fonte-level (alinhado). Ver [[project_ctc_repasse_ia]].
- [ ] `aplicar_diff_edicao`: comparar receita@atual vs snapshot anterior; ON CHANGE grava snapshot (com `req_hash@E`) em `composicoes_historico`. (Continua exigindo sequência — o rebuild roda em ordem.)
- [ ] **Retroação (leitura)**: `receita@E` = snapshot do historico; `custo@E` = `composicoes_custo@E` (lookup direto); `CTC@E` = `req_hash@E` → `ctc/doc` ou `ctc/_old`.

## Etapa 2b — DIFF SNAPSHOT-BASED (SOURCE-AGNOSTIC — `aplicar_diff_edicao`)

Vale p/ **toda fonte** (SINAPI/CDHU/FDE — a função é compartilhada). No diff da edição E (roda após o parse escrever a receita vigente=E):
- **presente@E** = `composicoes_custo.cc_edi_id=E` (substitui `_cabecalhos(edi)`); **presente@E_prior** = `cc_edi_id=E_prior`.
- **estado atual** = vigente (`composicoes` + `composicoes_itens`); **último estado** = `composicoes_historico` com maior `ch_edi_id_nova`.

| Caso (presente@E) | Evento | Ação |
|---|---|---|
| sem snapshot anterior | `CRIACAO` | snapshot receita@E |
| ausente@E_prior (voltou) | `REATIVACAO` | snapshot receita@E (parse já reescreveu itens + custo) |
| desc/unid ou receita ≠ último snapshot | `ALTERACAO_CABECALHO/ITENS/AMBOS` | snapshot receita@E + `ch_diff` (incluídos/excluídos/alterados) |
| igual | — | nada |
| **ausente@E, presente@E_prior** | `INATIVACAO` | **DELETE `composicoes_itens` do cmp** (vigente-only) — receita fica só no último snapshot |

- **Snapshot** `ch_dados_novos` = `{descricao, unidade, req_hash, receita:[{tipo, cod, id, coef}]}`. Regressão `receita@X` = snapshot com maior `ch_edi_id_nova ≤ X` (custo@X = lookup direto em `composicoes_custo`).
- **Só cadastral/estrutural** — mudança de PREÇO/CUSTO **não** gera evento (é esperado; vive em `composicoes_custo`/`insumos_preco`).
- Mesma regra p/ **insumos** (já é identidade+histórico): eventos CRIACAO/ALTERACAO(desc,unid)/INATIVACAO/REATIVACAO.

## Etapa 2c-UI — HISTÓRICO nas rotas (/composicoes, /consulta-composicoes, /insumos, /consulta-insumos)

O detalhe do histórico conta EXATAMENTE a história, em ordem cronológica por edição (`edi_codigo_versao` = número padrão da fonte):
```
edição {N}: primeiro registro
edição {N}: alterada {composição(itens), descrição, unidade} | inativada | reativada
```
Preço **não** aparece aqui (esperado). Lê de `composicoes_historico`/`insumos_historico` (ch_tipo_evento + ch_diff), ordenado por `ch_edi_id_nova`.

## CHECKLIST DE MIGRAÇÃO (todas as refs `cmp_edi_id` — 2026-07-13)

**FEITO (write-side):** `schema.sql` (identidade + `cc_edi_id`) · `parser_sinapi` (parse_composicoes/parse_custos/conferência) · `parser_cdhu.aplicar_diff_edicao` (snapshot-based, shared) · `descritivo_request`/`import_service`/`conciliacao_mdo`/`caderno_service`/`edicao_anterior` (rota crítica migrada) · `valida_amostra` (cc_edi_id).

**FIXES incidentais (expostos pelo rebuild):** conciliação MDO `max` comparava dicts no empate → `key=lambda t:t[0]`; `except` usava `log` indefinido → `stage`. **Ficha de insumo era PER-EDIÇÃO** (6038×22 duplicadas) → **FONTE-LEVEL** `sp.ficha(fonte,cod)` + dedup sha1 (mesma doutrina do CTC; aplica no próximo rebuild). FDE fichas (serviço/componente N:N) = conceito diferente, revisar à parte.

**ROTA CRÍTICA p/ rebuild+validação SINAPI (fazer ANTES do rebuild):**
- [ ] `descritivo_request.py` (2d): l.201-207 (`prior` DELTA + SELECT por edi → identidade fonte-level; cmp_descritivo já persiste na identidade, carry-forward vira trivial) · l.323 · l.366 (`WHERE cmp_edi_id` → `cmp_fte_id`).
- [ ] `import_service.py` (2d): l.153/192 (unidades a descrever) · l.525 (`_materializar_construcao` — já lê `cmp_edi_id`; virar identidade) · l.1371/1460/1674/1683.
- [ ] `conciliacao_mdo.py` (2d): l.111/254/309 (MDO H↔MÊS por edição → identidade + custo@edi).
- [ ] `caderno_service.py` (2c-render): l.142/148/160/285 ("foto da edição E" = identidade + `composicoes_custo@E` + receita vigente/snapshot).
- [ ] `z_scripts_apoio/valida_amostra.py`: query `composicoes_custo cc JOIN composicoes c WHERE c.cmp_edi_id` → `WHERE cc.cc_edi_id`.

**DEPOIS do marco SINAPI:**
- [ ] `composicoes_service.py` (~15 refs: busca/CRUD/detalhe/edit/publicar) — a busca sob identidade não retorna N× por edição; detalhe monta histórico (§2c-UI); publicar decide vigência.
- [ ] `service.py` l.497 (`cmp_ativa = (cmp_edi_id = %s)` no publicar → vigência por identidade).
- [ ] `parser_fde.py` (7 refs) + `fichas_fde.py` (2) — 2a do FDE (get-or-create como SINAPI).
- [ ] `parser_cdhu.py` parse_composicoes/parse_custos — 2a do CDHU.
- [ ] UI histórico nas 4 rotas (§2c-UI) · docs `prompt_tela_composicoes.md` (defasado).

## Etapa 3 — REBUILD EM SEQUÊNCIA

- [ ] `rebuild_db` (6 schemas) + `schema.sql` novo + wipe storage.
- [ ] Re-import **SINAPI 22 em ordem cronológica** (parsers novos) → histórico correto em-sequência (corrige 12/13).
- [ ] Depois **CDHU** (já nasce Fase 2) e **FDE**.

## Etapa 4 — VALIDAÇÃO (gate)

- [ ] `valida_amostra` (banco × Excel): manter **0 divergência** (custo agora por `cc_edi_id`).
- [ ] Sanidade: `composicoes` = **1×/código** (não 22×); busca subgrupo 99 retorna 1× por CPU.
- [ ] Histórico: reconstruir "CPU@E" em **1 lookup** (snapshot) e conferir contra o estado Fase 1 (backup).
- [ ] CTC: `ctc/doc|prompt|_old` intactos; descritivo as-of-E resolvível por `req_hash@E`.
- [ ] `e2e` (checks reais) verde nas 22.

---

## PRESERVAÇÃO DO HISTÓRICO (`composicoes_historico` / `insumos_historico`)

Os snapshots de mudança intra-edição — `CRIACAO`/`ALTERACAO_*`/`INATIVACAO`/`REATIVACAO` + `ch_dados_novos`/`ch_diff` (JSON) — são o que **não se pode perder**. Estratégia dupla:
- **Backup verbatim (Etapa 0):** `pg_dump` + export CSV dos dois `*_historico` → congela o estado atual como rede/auditoria.
- **Regeneração CORRETA (Etapa 3):** o rebuild **em sequência** recomputa o histórico — melhor que o atual, que tem as **edi 12/13 ZERADAS** (out-of-sequence) + artefatos da retomada. Sob Fase 2 o histórico é **load-bearing** (receita@E vem só do snapshot, pois `composicoes_itens` fica vigente-only) → tem de estar completo/correto, o que só a sequência garante.
- **Conferência pós-rebuild:** histórico regenerado vs backup (contagem por tipo de evento + amostra de `ch_dados_novos`) — o novo deve COBRIR o antigo (menos o ruído 12/13) e preencher os buracos.

> "Não perder" = **backup + regenerar correto**, não congelar o imperfeito.

## DECISÕES (TRAVADAS 2026-07-13)

1. **`req_hash@E` → DENTRO do snapshot `composicoes_historico.ch_dados_novos`** ✅. Ressalva: snapshot só existe QUANDO muda → reconstrução as-of-E = "último snapshot ≤ E" (consistente: o CTC só muda quando a fonte muda, então o hash do último snapshot ≤ E É o vigente em E). Sem tabela-elo nova.
2. **SE em composição: MANTER** (CSE→SE, validado 0 divergência; pelado consultável) ✅. Corrigir o texto de `§9.3` p/ bater com `§4.1` + implementação.
3. **Escopo/ordem: SINAPI primeiro → validar exaustivo → depois CDHU + FDE** ✅ (Fase 2 antes do CDHU; CDHU/FDE já nascem no modelo novo).

**Nota de storage:** a Fase 2 encolhe `composicoes` (1 GB→~50 MB) e deduplica `composicoes_itens` (412 MB→muito menos). **`composicoes_custo` (6,9 GB) NÃO encolhe** — custo é por (código×edição×UF×modalidade) nos dois modelos. O ganho é **semântica de busca/identidade**, não storage do custo.
