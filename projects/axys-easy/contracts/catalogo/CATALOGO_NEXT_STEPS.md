# Catálogo — Próximos passos (orientação)

Estado em **2026-06-05**: o **import p/ o banco** (CDHU + SINAPI: parse → normalização →
armazenamento → conferência) e a **publicação dos documentos no R2** (fichas, cadernos +
apresentação, critérios + metodologia, livros) estão **completos e validados** (pipeline +
amostras, ao rigor metodológico). Ver `CATALOGO_BUSINESS_RULES.md` §10 (ciclo de vida) e §11
(publicação no R2, estrutura de diretórios, livros, metodologia).

## Devolutiva (o que de fato valida o trabalho)
As eventuais falhas pontuais no R2 (ex.: ~6 CPUs de caderno sem match na edição, contagens
3562/3560) são **pouco expressivas**. O que importa é que houve **convergência extrema dos
dados de preço** e que **tudo foi construído sobre a versão SE** (Sem Encargos sociais
destacados / "pelado + LS") — que é como o catálogo se orienta (ver §3.1 e
`project-import-sinapi-doctrine`). Essa é a validação real.

## Orientação para a evolução — CAMADA DE SERVIÇO

O princípio: **os parsers/geradores já existentes são a fonte da verdade super-validada —
IMPORTAR, não duplicar/reescrever.**

1. **Biblioteca (já pronta, modular, validada)** — `backend/core/import_cpu/`:
   - `parser_cdhu.py`, `parser_sinapi.py` (import p/ banco)
   - `fichas_sinapi.py`, `criterios_cdhu.py` (+ `parse_metodologia_cdhu`), `cadernos_sinapi.py`
     (PDF → HTML normalizado)
   Estes **não** são scripts de teste — são a camada de parsing. Reaproveitar como está.

2. **Orquestração — promover de script → serviço.** Hoje vive em `z_scripts_apoio/`
   (`import_*`, `gera_livros`, `restamp_css`, `migra_*`, `fix_audit_*`): download → parse →
   R2 → banco → skip-por-data → audit → livros. Extrair essa lógica para **serviços**
   (ex.: `ImportService`, `PublicacaoService`/`CatalogoDocsService`) que **importam os parsers**
   acima e expõem funções de alto nível (importar edição, publicar docs, gerar livros).

3. **Um service, dois consumidores.** As **rotas/telas** e os **runners CLI** chamam os
   **mesmos serviços** — uma lógica só. Os runners CLI permanecem como *thin wrappers*
   (útil p/ batch, cron, operação manual); as rotas plugam nas telas.

4. **Telas + ciclo de vida** (frente de app pendente, já suportada no schema/contrato §10):
   - import de fonte/edição (upload p/ `audit/`, disparo do import);
   - botão **Publicar** + validação dos gates (`edi_ins_catalogo_ok`, `edi_comp_catalogo_ok`),
     badge `RASCUNHO`/`PUBLICADA`, **lock** da edição publicada (camada app);
   - render responsivo (calibrar mobile/desktop na app, sobre o conteúdo puro do R2).

## Registro central de documentos (FEITO fase 1 — 2026-06-05)
Adotado o **Caminho 2**: `catalogo.documentos` + `documentos_origem` (ver BUSINESS_RULES §11.9).
Fronteira de governança: import escreve, app/livros lêem. Backfill do estado atual feito
(`backfill_documentos.py`: ~21.978 docs + 177 origens) e **livros já lêem do registro**.
- **Fase 2 (a fazer):** reescrever os runners (`import_fichas`, `import_cadernos`, `import_criterios`)
  p/ gravar direto em `documentos`/`documentos_origem` (em vez dos JSONB). Depois **deprecar/dropar**
  `ins_external_path`/`cmp_external_path`/`edi_capa_path` (hoje cache).
- **Equipamento por-insumo:** ajustar `parse_caderno` p/ detectar CPU pelo cabeçalho de metadados
  (árvore opcional) e gerar per-CPU dos 2 cadernos de equipamento, linkando ao insumo — hoje estão
  como `referencia` (PDF) no registro.

## Rollout de produção (obs Rodrigo)
- Importar da edição SINAPI **mais antiga → mais nova**; se faltar item, a app **skipa** (casos de
  skip: sem links etc.) — sem ficar vaga em excesso.
- Sobe pra produção nos imports, mas **só libera p/ tenants** quando TODAS as tabelas do modelo
  recente (os 4 excels) estiverem no banco. Mapear esses docs também (já no registro como `referencia`).

## Pendências menores (não bloqueiam)
- **skip-por-data**: implementado, exercitado só na 1ª subida; validar numa virada de edição real.
- ~~6 CPUs de caderno órfãs~~ **RESOLVIDO**: CPU documentada no caderno mas fora da edição atual
  (descontinuada) → o runner linka na edição mais recente que tem o código (inativa) marcando
  `orfao=True` → aparece em **Cadernos descontinuados**. Códigos nunca importados ficam p/ a UI
  (criar inativo + auditar histórico) — ver sugestão Rodrigo.
- **2 cadernos de EQUIPAMENTO** (*Custos Horários… dos Equipamentos*, *Depreciação… Operação dos
  Equipamentos*): têm apresentação mas **0 composição** (custo horário de equipamento não é
  `composicao` no modelo). Hoje a apresentação fica órfã (não listada). **Decisão pendente**:
  listar como caderno-referência (só apresentação) ou modelar o custo de equipamento.
- **descontinuados**: cadernos = 6 (pipe-PVC ed. antiga); fichas = 874 (insumos inativos com ficha).
