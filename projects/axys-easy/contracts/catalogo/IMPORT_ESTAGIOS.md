# CONTRATO — Import desmembrado em estágios (`edi_estagios`)

> Governa o pipeline de import de uma edição em 4 estágios independentes com lock/unlock em cascata.
> Implementa: `backend/modules/catalogo/estagios.py`. Coluna: `catalogo.edicoes.edi_estagios` (JSONB).
> Plano-mãe: `next-steps/PLANO_REIMPORT_E_DOCUMENTOS.md` (R0). Relacionado: CONTRATO IMPORT §8.

## 1. Estágios (ordem fixa)

`preparar` → `precos` → `dados` → `documentos`

| Estágio | Faz | Fecha quando |
|---|---|---|
| **preparar** | Sobe originais ao storage (privado) + mapeia links externos (SINAPI/CDHU → JSON) | upload + mapa ok |
| **precos** | Constrói os preços | docs suficientes → auto; senão `pendente_user` (modal) |
| **dados** | Parse pesado + markdowns preliminares + IA (Codex-local: get_md/put_md) | retornos gravados |
| **documentos** | Gera AxysDocs/CTCs no privado | caderno + CTCs prontos |

## 2. Estados

`locked` · `pronto` · `rodando` · `ok` · `erro` · `pendente_user`

- **locked** — travado (anterior não concluído). Botão desabilitado.
- **pronto** — destravado, pode rodar (todos os anteriores == `ok`).
- **rodando** — job em execução.
- **ok** — concluído com sucesso.
- **erro** — falhou; user re-dispara.
- **pendente_user** — SÓ `precos`: aguarda decisão no modal (Informar dado / Publicar sem preço).

## 3. Shape (JSONB em `edi_estagios`)

```json
{
  "preparar":   { "estado": "ok", "job_id": "…", "em": "2026-07-06T14:00:00+00:00",
                  "detalhe": { "n_originais": 8432, "mapa_links": "easy/fontes/sinapi/05-26/_state/links.json" } },
  "precos":     { "estado": "pendente_user", "job_id": "…", "em": "…",
                  "detalhe": { "faltantes": 12, "decisao": null } },
  "dados":      { "estado": "locked" },
  "documentos": { "estado": "locked" }
}
```

`NULL` no banco = ainda não iniciado → o back materializa o **default** (`preparar=pronto`, resto `locked`).

## 4. Regra de cascata (invariante)

Um estágio fica **disponível** (`pronto`) sse, e só se, **todos os anteriores == `ok`**. Este é o
único bit **derivado**:
- `preparar` (entrada) nunca fica `locked`.
- `locked`/`pronto` são **recalculados** a cada escrita (`_aplicar_cascata`).
- `rodando`/`ok`/`erro`/`pendente_user` são **explícitos** — a cascata nunca os sobrescreve.
- Se um estágio anterior regride (ex.: re-`preparar`), os posteriores voltam a `locked` (a menos que
  estejam num estado explícito de execução).

**`documentos == ok` ⇒ edição disponível para publicação.**

## 5. API (`estagios.py`)

- `get_estagios(edi_id) -> dict` — estado dos 4 (cascata aplicada). NULL → default.
- `set_estagio(edi_id, nome, estado, detalhe=None, job_id=None) -> dict` — grava um estágio + carimbo
  `em` (UTC ISO-8601), reaplica a cascata, persiste. Valida `nome`/`estado`.
- `disponivel_para_publicar(edi_id) -> bool` — `documentos == ok`.

## 6. Fora de escopo deste contrato (rounds seguintes)

Botões locked na tela de import (R4+), o que cada task Celery grava/lê, o modal de preços (R5), os
scripts get_md/put_md (R6). Aqui só o **modelo de estado** e a **cascata** (R0).
