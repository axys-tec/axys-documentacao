# AxysEasy — Arquitetura

**Status:** 🟢 Confiável & Fresco  
**Versão:** 0.1  
**Data:** 01/06/2026

---

## Visão Geral

AxysEasy é a **plataforma de orçamentação para construção civil** com foco em **liberdade operacional** e **flexibilidade tipo Excel**.

**Objetivo:** Permitir profissionais montarem orçamentos com rastreabilidade, precisão e integração com catálogos, levantamentos CAD/BIM e cronogramas.

---

## 🏗️ Arquitetura Modular

Easy é organizado em **módulos independentes**, cada um com suas rotas, serviços e lógica:

```
backend/modules/
├── auth/               # SSO com Hub, JWT validation
├── catalogo/           # Fontes de preço (SINAPI, CDHU)
├── ativo/              # Orçamentos, estruturas hierárquicas
├── price/              # (futuro) Análise de preços
└── orca/               # (futuro) Orçamento sintético
```

---

## 📊 Banco de Dados

### Schemas

```sql
Easy Database
├── catalogo.*          # Referência (SINAPI, CDHU, insumos, composições)
├── ativo.*             # Orçamentos, estruturas, itens
├── audit.logs          # Auditoria de mudanças
└── audit.login_logs    # Login/logout
```

### Estrutura

- **[schema.sql](schemas/schema.sql)** — DDL completo + TODOS os seeds inline (insumos_tipo, situacoes, fontes, edicoes, audit). Não há seed.sql separado.
- **[migrations/](schemas/migrations/)** — Histórico incremental

**Status:** ✅ Confiável (fresco, bem estruturado)

---

## 🎨 Padrões de UI/UX

Easy segue um **design system canônico** documentado:

- **[config_ui_ux_easy.md](ui-ux/config_ui_ux_easy.md)** — Padrões de UI (listagens, formulários)
- **[prompt_nova_tela.md](ui-ux/prompt_nova_tela.md)** — Template para construir novas telas

**Princípio:** Montagem com **liberdade operacional** (copy/paste/indent como Excel)

---

## 📚 Módulos Documentados

| Módulo | Propósito | Ref |
|--------|-----------|-----|
| **auth** | SSO com Hub via JWT | [EASY-ADR-005](adrs/) |
| **catalogo** | Fontes de preço, edições, insumos | [work pages](modules/) |
| **ativo** | Orçamentos, estruturas hierárquicas | [contrato](contracts/) |

---

## 🔗 Integrações

### Com Hub

- Autentica via SSO (JWT)
- Valida licenças
- Obtém dados de tenant/user

### Com Sync (futuro)

- Envia dados financeiros para contabilidade

### Com CAD/BIM

- Recebe levantamentos de AxysLisp
- Processa estruturas de Revit

---

## 🚀 Roadmap (Next Steps)

### Layer 1 — Insumos (próxima sessão)
- [ ] Parser SINAPI/CDHU
- [ ] Importação de insumos
- Veja: [PROMPT_PROXIMA_SESSAO_INSUMOS.md](next-steps/)

### Layer 2 — Composições
- [ ] Importação de grupos/composições
- [ ] Vínculo insumo ↔ composição

### Layer 3 — Módulo Ativo
- [ ] Árvore de orçamentos (hierarquia ilimitada)
- [ ] Liberdade operacional (reordenar, identar, copiar)
- Veja: [MODULO_ATIVO_ARCHITECTURE_CONTRACT](contracts/)

---

## 📞 Referências

- @see [EASY-ADR-005 — Ferramentas Excel/AutoLISP](../../foundation/adrs/EASY-ADR-005-ferramentas-excel-autolisp-api.md)
- @see [Módulo Ativo — Contrato Completo](contracts/easy_modulo_ativo_architecture_contract.md)
- @see [Hub Integration](integrations/with-hub.md)
