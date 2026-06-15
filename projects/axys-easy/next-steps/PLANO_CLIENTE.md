# Plano — Porteira Cliente (Easy client-side)

> Até aqui o Easy é **internal Axys** (catálogo, import, fontes). A **porteira cliente** começa
> agora. Este plano cresce por **ciclos**; cada ciclo é discutido e registrado antes de codar.
> Contexto do domínio: `contracts/ativo/EASY_ATIVO_v0.3.md`.

---

## Ciclo 1 — Porteira e Navegação (premissas, 2026-06-14)

**Origem:** premissas do Renan + considerações alinhadas. **Status:** aprovado como direção;
detalhes finos a confirmar (ver Abertos).

### Modelo de navegação — 3 níveis

```
main-client  (home do TENANT)
   • boas-vindas · histórico · últimas versões · preferências
   • CARDS dos módulos liberados (vindos da licença do HUB)
   • lista de empreendimentos + ativos avulsos
        ↓ (abre um projeto)
sub-main do PROJETO  (= o ATIVO — objeto técnico; tudo conecta a ele)
   • hub curto de direcionamento do ativo: o que existe, atalhos p/ os módulos
        ↓ (entra num módulo)
workspace do MÓDULO
   • sidebar PRÓPRIA do módulo (estende o padrão atual sidebar_catalogo.html)
   • o ATIVO permanece em contexto (eixo); o módulo é a lente
```

### Mapeamento ao schema/contrato

- **Projeto = ATIVO** (`ativo.ativos`); **empreendimento** (`ativo.empreendimentos`) = agrupador
  opcional acima. Recomendado: sub-main por ativo. *(a confirmar)*
- **Módulos operam SOBRE o ativo** (não são entidades isoladas — contrato v0.2 §12 / v0.3):
  - **Price** → ficha (`ativo_ficha_tecnica` / `ficha_parametros` / `ficha_atributos`)
  - **CPU** → `tenant_catalogo` (insumos/composições próprias)
  - **Orça** → a grade (`ativo_itens` + `ativo_bdi`/`ativo_ls` + `cronograma`)
  - **Docs** → `ativo_diversidades_catalog` (+ slot `ativo_docs`)
  - **Project Manager / Build Diary / Fin Control / LicitPlan** → slots reservados
    (`ativo_pm` / `ativo_diario` / `ativo_fin` / `ativo_licit`)
- **Módulos liberados = licença no HUB** (mesma fronteira do arquivamento: Hub manda, Easy
  renderiza). O main-client monta os cards a partir do que o Hub libera.

### Decisões/recomendações deste ciclo

1. **main-client** novo, paralelo ao `main.html` (que permanece internal). Reusa
   `base/base_app.html` + `base/base_sidebar.html`. Catálogo continua **internal-only**.
2. **Sidebar por módulo** — estende o padrão `partials/sidebar_catalogo.html`
   (→ `sidebar_price.html`, `sidebar_orca.html`…).
3. **Registro de módulos** — cada módulo declara rótulo/ícone/rotas/sidebar; o main-client e o
   roteamento leem desse registro (sem hardcode), e a licença do Hub liga/desliga cada card.
4. **Eixo = ativo selecionado** — persiste no contexto ao trocar de módulo.

### Abertos (a confirmar antes de codar)

- [ ] "Projeto" = **ativo** (recomendado) ou empreendimento?
- [x] **Price vs Price 2** — RESOLVIDO (`products/EASY_PRODUTOS.md`): Price = modelos prontos da Axys (5 tipologias); **Price 2 = o tenant cria/sobe o próprio modelo parametrizado**. Ambos = gerador por drivers.
- [ ] Ordem de liberação dos módulos — sugestão: começar pelo core já modelado **Price → CPU → Orça**.
- [ ] Papéis/permissões dentro do tenant (quem vê o quê) — provável ciclo futuro.

### Próximo (combinado)

> Montar **UMA tela** + abrir discussão, antes do plano de ataque. Candidata natural à 1ª tela:
> o **sub-main do projeto** (porta de entrada do ativo) **ou** a **grade do Orça** (`ativo_itens`,
> o coração). A definir com Renan.
