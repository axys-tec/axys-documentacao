# CATÁLOGO — Fechamento do módulo (dev validado)

> **Status:** módulo **FECHADO em dev** (2026-06-14). Versionamento de ponta a ponta validado
> (CDHU 184→201, SINAPI 08-24→04-26) com **check de sanidade verde**. Próximo: módulo **Ativos**.
> Este doc registra o estado final + as decisões desta fase. Contratos de regra continuam em
> `docs/projects/axys-easy/contracts/catalogo/` (este complementa, não substitui).

---

## 1. O que está pronto

| Frente | Estado |
|---|---|
| **Import via tela** (SINAPI + CDHU), async (Celery+Redis), por stages | ✅ |
| **Custos** SD/CD/**SE** por UF/modalidade (conferência fonte×calculado) | ✅ |
| **Leis Sociais** — parse do serviço + manual; **PDF(s) inteiros** (multi) | ✅ |
| **Documentos** no registro `catalogo.documentos` (ficha/caderno/critério/livros/notas/originais/LS) | ✅ |
| **Viewer** `/doc/{id}` — realces montados pelo back (não no parser) | ✅ |
| **Caderno técnico** (botão Fontes-Base) — índice estático no R2, async+cache | ✅ |
| **Índices** econômicos (BCB SGS) — tela + rodada noturna | ✅ |
| **Layout de storage** padronizado (`easy/…`, por edição) | ✅ (`CATALOGO_STORAGE_LAYOUT.md`) |
| **Vigência** = edição PUBLICADA mais recente (flip no publicar) | ✅ |

---

## 2. Decisões-chave desta fase (não-óbvias)

1. **Vigência segue a PUBLICAÇÃO, não o import.** Importar uma edição NÃO mexe em `cmp_ativa`/
   `ins_ativo`; o flip acontece em `publicar_edicao` (vigente = PUBLICADA mais recente por data).
   Importar rascunho não rebaixa a vigente.

2. **Custo nunca zera — SE (pelado, LS=0) é sempre calculado.** `calcular_custos` sempre emite
   a modalidade **SE** (não é o regime de orçamento; é a base de de/recomposição). SD/CD entram
   quando há LS (arquivo de serviço **ou** LS manual). Edição só-SD → SD (conferido) + SE (derivado).

3. **Diff/ciclo de vida por PRESENÇA na edição anterior (`edi_prior`), não pelo flag de vigência.**
   Como `ins_ativo`/`cmp_ativa` só viram TRUE no publicar, a diff usa presença em `edi_prior` para
   CRIACAO/ALTERACAO/REATIVACAO/INATIVACAO. (Antes dava reativação espúria em massa.)

4. **Realces da exibição vêm do BACK na hora de servir, não do parser nem baked.**
   `/doc/{id}/conteudo` injeta no topo do `<body>` a hierarquia **grupo/subgrupo** (CDHU, do banco)
   e o HTML do CPU traz `{código} - {descrição}`. SINAPI usa o rótulo canônico. O parser do PDF
   **não** lê grupo/subgrupo (nem toda página tem) → robusto, sem reimport pra ajustar.

5. **Caderno técnico = índice estático (não conteúdo corrido).** A app **gera um HTML estático**
   (header tarja+logo + Originais Ver/Baixar + índice organizado grupo›subgrupo) e sobe pro R2.
   Links **hardcoded** `{EASY_BASE_URL}/doc/{id}` → abrem no viewer **com os realces** (ficha/caderno
   na MESMA página; livros/originais em nova aba). Async + **cache** (1 por edição); o cache só vale
   se o arquivo existe (excluir do R2 = regenera).

6. **Storage `easy/fontes/{fonte}/{edicao}/…`** (originais + derivados + caderno) e
   `easy/fontes/{fonte}/livros/{livro}_{ed_livro}` (livros com edição PRÓPRIA, via `doc_versao`).
   Ver `CATALOGO_STORAGE_LAYOUT.md`. Centralizado em `backend/modules/catalogo/storage_paths.py`.

7. **Parser de critérios CDHU por LINHA** (não por span): número de 2 dígitos no meio da descrição
   (ex.: "até 40 cm") não é mais confundido com código de grupo → fim do corte de descrição.

---

## 3. Check de sanidade (2026-06-14) — verde

- Vigência: **1 edição vigente por fonte** (CDHU 201, SINAPI 04-26).
- Custos: CDHU 184 ×3 (SD+CD+SE), 201 ×2 (SD+SE); SINAPI ×81 (27 UF × 3). IGUAL + arredondamento.
- Histórico: **zero REATIVAÇÃO espúria** no salto de versão (só CRIACAO/ALTERACAO/INATIVACAO).
- `SEM CUSTO` (1798 CPUs SINAPI) = legítimo (`cmp_situacao='SEM CUSTO'`). Zero FK órfã.

---

## 4. Pendências conhecidas (não bloqueiam o fechamento)

- **Scripts-apoio** (`gera_livros.py`, `import_*_sinapi.py`, etc.) ainda escrevem nos paths antigos
  (sem `easy/`, `livros/{fonte}.html` em vez de `catalogos/`). Alinhar quando forem reusados — o
  **app** (import via tela) já está no layout novo.
- **"Regerar" explícito** no botão do caderno (hoje: excluir o arquivo do R2 → clicar regera).
- **Disponibilidade de docs** (flag tri-estado OBTIDO/HERDADO/AUSENTE por edição×doc) — desenhada,
  não implementada (ver memória `project_doc_disponibilidade`).
- **Catálogo global** das Leis Sociais (a "ligeira diferença" p/ subir no catálogo geral) — a alinhar.

---

## 5. Handoff → módulo Ativos

Catálogo entrega: fontes/edições publicadas com insumos, composições e **custos por UF/modalidade**
(SD/CD/SE) prontos pra uso, documentos navegáveis e o registro `catalogo.documentos` como fronteira.
O módulo Ativos parte daqui (consumir custos/CPUs vigentes do catálogo).
