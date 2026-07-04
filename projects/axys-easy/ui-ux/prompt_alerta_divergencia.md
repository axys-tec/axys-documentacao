# Prompt Codex — Custo calculado + alerta de divergência relevante nas composições

**Telas alvo**
- `/composicoes` → `backend/frontend/templates/catalogo/composicoes.html` (admin interno)
- `/consulta-composicoes` → `backend/frontend/templates/ativos/consulta_composicoes.html` (consulta do cliente)

Ambas renderizam `dados['items']` vindos de `backend/modules/catalogo/composicoes_service.py::get_composicoes`.
Cada item já traz `custo` e `status_conferencia` (valores de `catalogo.composicoes_custo`).

---

## Tarefa 1 — o custo exibido deve ser o CALCULADO pela AXYS

Em `get_composicoes`, o custo hoje é `COALESCE(cc.cc_custo_fonte, cc.cc_custo_calculado) AS custo`
(fonte primeiro). Trocar para **calculado primeiro, fonte só como fallback**:

```sql
COALESCE(cc.cc_custo_calculado, cc.cc_custo_fonte) AS custo
```

- Não alterar `cc_custo_fonte` (segue guardado para auditoria) nem a rotina de conferência.
- Confirmar que **as duas rotas** usam `get_composicoes` (o fallback cobre `SEM_CUSTO_CALCULADO`, onde `calc` é NULL → mostra o fonte).

## Tarefa 2 — ícone de alerta na LINHA, exclusivo para divergência relevante

Quando `item.status_conferencia == 'DIVERGENTE_RELEVANTE'`, exibir um ícone **"ⓘ" na própria linha**
(na célula de Custo), que mostra em **hover E foco de teclado** um tooltip com o texto abaixo.
Somente esse status — as demais linhas não recebem ícone.

**Texto do tooltip:**

> O custo calculado pela AXYS diverge do custo publicado pela fonte-base. A AXYS aplicou integralmente
> os coeficientes de produtividade e os preços de insumos divulgados pela fonte. Recomendamos conferência
> antes do fechamento de orçamento público ou elaboração de proposta. A AXYS não se responsabiliza por
> valores apurados por terceiros.

## Restrições (obrigatório)

- **Sem CSS/JS inline** (regra do projeto: CSS/JS externos + data-island para dados Jinja).
  - Estilo do ícone/tooltip em `backend/frontend/static/css/easy_catalogo.css` (compartilhado pelas duas telas).
  - Markup do ícone + texto **estático** no template (o texto é fixo, não é dado Jinja).
- **Tooltip CSS-only** (hover + `:focus-within`); **não** usar `title=""` puro.
- **Acessível**: ícone com `tabindex="0"`, `role="img"`/`aria-label`, tooltip legível por leitor de tela.
- **Theme-aware**: funciona no claro e no escuro (usar as variáveis de tema já existentes no CSS).
- Não poluir linhas sem divergência.

## Aceite

- Custo mostra o **calculado** nas duas telas (fonte só quando não há calc).
- Linhas `DIVERGENTE_RELEVANTE` (ex.: CDHU boletim 196 `61.14.015`) mostram o ícone + tooltip; demais sem ícone.
- Zero CSS/JS inline; funciona em claro e escuro; navegável por teclado.
