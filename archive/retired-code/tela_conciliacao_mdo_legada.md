# Tela de conciliação H→Mês legada (2026-07-23)

Removidos (existem no histórico do Git, HEAD anterior a este commit):

| Arquivo | O que era |
|---|---|
| `backend/frontend/templates/catalogo/conciliacao_mdo.html` | Tela antiga de conciliação H→Mês (batch confirmar/sem-par) |
| `backend/frontend/static/js/easy_conciliacao_mdo.js` | JS dessa tela — chamava `POST /api/edicoes/{id}/conciliacao/mdo/salvar` |
| `backend/frontend/static/css/easy_conciliacao_mdo.css` | Estilo dessa tela |

**Por que saiu:** a conciliação H→Mês passou a renderizar `curar_equiv.html` (via `_render_conciliacao_mdo`), e a
curadoria virou **JSON-até-publicar** (`mdo_h_mes.json`; commit na `composicoes_mapeamento_mdo` só no publicar via
`conciliacao_mdo.publicar_hmes`). Com isso caíram juntos o endpoint `/conciliacao/mdo/salvar` e as funções
`confirmar_pares` / `marcar_sem_par` / `estado_conciliacao` (escreviam na cmm antes da hora). Nenhuma rota
renderizava mais estes 3 arquivos — órfãos sem consumidor.

Ver `project_vinculacoes_intra_fontes` (memória) e o contrato `CATALOGO_VINCULACOES_INTRA_FONTES.md`.
