# Plano — Rebuild Limpo do Catálogo (construir em DEV → migrar p/ PROD)

**Status:** RASCUNHO p/ revisão do Renan (2026-07-03). Não executar antes de aprovar.
**Motivação:** prod contaminada — órfãos de item (reimport sem delete, já corrigido), **ids queimados**
(9623 insumos → `ins_id` 194.715), fonte 2025-10 inconsistente (+56 de mismatch de preço). Produto
**sem cliente / app não pronta** → rebuild do zero é seguro e dá slate limpo.

## 1. Estratégia macro
- **Construir tudo em DEV** (storage = pasta local via `storage_provider`), validando com a **tela de diff**.
- **Migrar o banco DEV → PROD** (`pg_dump` do que importa), **sem importar em prod**.
- Assim: sequences resetados (ids limpos), zero risco de import em prod, e a fonte inconsistente
  nunca entra.

## 2. Decisões travadas
- **Reset = schemas `catalogo` + `audit`.** Audit depende do que entra na app → também refaz. Demais
  schemas (ativo/orçamento/…) foram criados no `CREATE DATABASE` mas estão **vazios** em prod. SSO/Hub
  = ENV + banco separado do Hub → **intactos**.
- **Fonte:** Renan TEM os Excel completos e consistentes de todas as edições. É o insumo do rebuild.
- **get-or-create canônico** p/ tabelas de **identidade estável** (ver §4). Ver [[feedback_get_or_create_ids]].
- **Reusar cadernos/fichas** já parseados (o caro) — não reparsear (ver §5).

## 3. Pipeline por edição (dev)
`Excel (fonte) → CSV canônico → carga no banco → DIFF da tabela inteira (revisão) → aceita`
- **Diff por import (tela de rolagem):** a cada carga, subir o diff da tabela toda (fonte × app) pra
  revisão humana ANTES de aceitar. Estende a tela `/edicoes/{id}/diff-fonte-app` p/ rodar no import.
- **Convergidos pulam o pesado:** o que já bate (diff≈0) não passa pelo processamento maior (reparse etc.).
- Ordem cronológica das edições (o histórico `*_historico` depende de `edi_prior`).

## 4. get-or-create — escopo (da auditoria 2026-07-03)
**🔴 Identidade estável → GET-OR-CREATE (SELECT natural key → UPDATE mutáveis se achou; senão INSERT):**
- `catalogo.insumos` — (fte, codigo) [sinapi:172,432 · cdhu:293] ← o caso principal
- `catalogo.composicoes` — (fte, codigo, edi) [sinapi:376 · cdhu:486]
- `catalogo.unidades` — (un_codigo) [insumos_service:482] (DO NOTHING também queima)
- `catalogo.indices` — (idc_codigo) [indices_service:100,172]
- ⚠️ o UPDATE do insumo tem precedência `ins_ti_origem` (FONTE>MANUAL>NC) → preservar no branch de update.

**🟡 Por-edição / alto volume → DELETE escopo + BATCH INSERT (não get-or-create; id interno descartável):**
- `insumos_preco`, `composicoes_custo`, `composicoes_itens` (delete já feito no fix), `insumos_familia`,
  `edicoes_leis_sociais`, `search_document`, `documentos`. get-or-create linha-a-linha aqui = lento demais.

## 5. Reuso de cadernos/fichas (o "seed controlado") — PONTO DE DESIGN ABERTO
O caro é o parse de PDF (fichas/cadernos/textos) → gera **HTML "patheado" no R2**. Já está construído no
**R2 de prod**. Precisamos **preservar esses artefatos e seus paths**, e o DB rebuildado deve **apontar
pros mesmos paths** (sem reparsear). `parse_caderno`/`parse_fichas` **não escrevem `composicoes_itens`**
(só publicam doc) → pular o parse **não afeta o dado**, só a publicação do doc.
- **Desafio:** dev = storage local, prod = R2 (separados). O rebuild em dev geraria paths locais.
- **Opções (a decidir):**
  - (a) A trava `EASY_SKIP_CADERNOS_PDF` pula o parse MAS ainda registra a referência do doc apontando
    pro path R2 canônico já existente (determinístico via `storage_paths`/`sp.derivado`).
  - (b) Rebuild em dev sem cadernos; após migrar o DB p/ prod, um passo re-registra os docs a partir do
    que já está no bucket R2 de prod (varre o bucket / usa os paths determinísticos).
  - Como os paths são **determinísticos** (`sp.derivado(fonte, versao, tipo, cod)`), o DB consegue
    reconstruir a referência sem ter o arquivo em mãos. **Preferência: (a).**

## 6. Migração DEV → PROD
- `pg_dump` dos schemas `catalogo` + `audit` do dev → restore em prod (substitui). Sequences vão limpos.
- **Preservar em prod:** nada de cliente (vazio). Conferir que ativo/orçamento seguem vazios; SSO/Hub são
  externos. Fazer **backup do prod antes** (o worker/`gerar_backup_render.py`).
- Validar pós-migração: contagens, distribuição de `cc_status_conferencia`, e a tela de diff limpa.

## 7. Fases de execução
1. **Parsers → get-or-create** (insumos/composições/unidades/indices) + reset de sequence no rebuild. Testar em dev.
2. **Reuso de caderno** (decidir 5a/5b) — registrar doc sem reparsear.
3. **Diff-por-import** (estender a tela) + **skip de convergidos**.
4. **Rebuild completo em dev** (todas as edições, ordem cronológica, com os Excel completos).
5. **Migração dev → prod** (`pg_dump` catalogo+audit) + validação.

## 8. Pendências correlatas (já mapeadas)
- CDHU sarrafo (drop 2024-08) — ver se some no rebuild com fonte completa. [[project_conferencia_divergencia]]
- Follow-up `calc=0` de composição vazia → tratar como SEM_CUSTO (fallback p/ fonte na exibição). BUSINESS_RULES §4.3.
- FDE entra DEPOIS do rebuild estabilizar. [[project_fde_catalogo]]
