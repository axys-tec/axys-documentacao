# AxysEasy

**Status:** 🟢 Ativo  
**Versão:** 0.1  
**Repositório:** axys-easy  

---

## O que é?

AxysEasy é a **plataforma de orçamentação para construção civil**.

**Propósito:** Permitir que profissionais de obras montassem orçamentos **com liberdade operacional** (flexibilidade tipo Excel) mantendo rastreabilidade, precisão e integração com:
- Catálogos de referência (SINAPI, CDHU, etc)
- Composições próprias do tenant
- Levantamentos via CAD/BIM
- Cronogramas e medições

**Filosofia:** O módulo Ativo não é um "cadastro". É uma **camada estrutural** que organiza dados executivos da obra.

---

## 📊 Banco de Dados

```
Easy Database
├── catalogo.*                 # referência (SINAPI, CDHU, preços)
│   ├── fontes, edicoes
│   ├── insumos, insumos_preco
│   ├── composicoes_grupos, composicoes
│   └── ...
├── ativo.*                    # estrutura de orçamentos
│   ├── ativos (projects)
│   ├── estrutura_ativa (hierarchy)
│   ├── itens_ativos (line items)
│   └── ...
└── audit.logs, audit.login_logs
```

**Acessar schema:**
- [schema.sql](schemas/schema.sql) — DDL completo + todos os seeds inline (sem seed.sql separado)
- [migrations/](schemas/migrations/) — histórico

---

## 🏗️ Arquitetura Modular

O Easy é organizado em **módulos independentes**:

| Módulo | Propósito |
|--------|----------|
| **[auth](modules/auth.md)** | Autenticação SSO via AxysHub |
| **[catalogo](modules/catalogo.md)** | Fontes de preço, edições, insumos |
| **[ativo](modules/ativo.md)** | Orçamentos, estruturas hierárquicas |
| **price** | (futuro) Análise de preços |
| **orca** | (futuro) Orçamento sintético |

Cada módulo tem sua própria documentação em [modules/](modules/).

---

## 🎨 UI/UX

O Easy segue um **design system canônico**:

- [config_ui_ux_easy.md](ui-ux/config_ui_ux_easy.md) — Padrões de UI, formulários, listagens
- [prompt_nova_tela.md](ui-ux/prompt_nova_tela.md) — Template para construir novas telas

**Princípio:** Montagem com **liberdade operacional** (copy/paste/indent como Excel).

---

## 🔗 Integração com Outros Projetos

| Projeto | Como integra |
|---------|-------------|
| **AxysHub** | Autentica via SSO [AXYS-ADR-021](../../foundation/adrs/AXYS-ADR-021-SSO-JWT-hub-easy.md) |
| **AxysLisp** | Recebe levantamentos (JSON) de CAD |
| **AxysRvt** | Recebe estruturas de BIM |
| **AxysIFC** | Processa arquivos IFC |

---

## 📚 Documentação

| Arquivo | Propósito |
|---------|----------|
| [ARCHITECTURE.md](ARCHITECTURE.md) | Visão geral |
| [modules/](modules/) | Documentação por módulo |
| [contracts/](contracts/) | Contratos de domínio (Ativo, Insumo, etc) |
| [schemas/](schemas/) | Banco de dados |
| [adrs/](adrs/) | Decisões específicas do Easy |
| [ui-ux/](ui-ux/) | Padrões de interface |
| [next-steps/](next-steps/) | Roadmap de implementação |

---

## 🚀 Próximos Passos (Roadmap)

**Layer 1 — Insumos**
- Parsear SINAPI e CDHU
- Importar para `catalogo.insumos`
- Veja [next-steps/PROMPT_PROXIMA_SESSAO_INSUMOS.md](next-steps/PROMPT_PROXIMA_SESSAO_INSUMOS.md)

**Layer 2 — Composições**
- Importar grupos e composições
- Vincular itens a insumos

**Layer 3 — Módulo Ativo**
- Implementar árvore de orçamentos
- Liberdade operacional (reordenar, identar, copiar)

Veja [next-steps/](next-steps/) para mais detalhes.

---

## 📞 Referências

- @see [EASY-ADR-001 — Modular Architecture](adrs/)
- @see [Contrato — Módulo Ativo](contracts/MODULO_ATIVO_ARCHITECTURE_CONTRACT_v0.md)
- @see [AXYS-ADR-021 — SSO](../../foundation/adrs/AXYS-ADR-021-SSO-JWT-hub-easy.md)
- @see [Tenant Model](../../foundation/contracts/tenant-model.md)
