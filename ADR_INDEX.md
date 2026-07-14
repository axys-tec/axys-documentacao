# Índice de ADRs — Ecossistema Axys

**Status:** v1.0 — 01/06/2026  
**Padrão de Nomenclatura:** `{ESCOPO}-ADR-{NÚMERO}`

---

## 🎯 Como Usar Este Índice

| Você quer... | Procure por... | Exemplo |
|---|---|---|
| Uma decisão que **afeta todos os projetos** | **AXYS-ADR-** | AXYS-ADR-006 (Segurança) |
| Uma decisão **específica de AxysHub** | **HUB-ADR-** | HUB-ADR-002 (Control Plane) |
| Uma decisão **específica de AxysEasy** | **EASY-ADR-** | EASY-ADR-003 (UX) |
| Uma decisão **específica de AxysPro** | **PRO-ADR-** | PRO-ADR-001 (Template) |

---

## 📋 Foundation — AXYS-ADR (Global)

**Localização:** `docs/foundation/adrs/`

| ADR | Título | Status | Aplicável a |
|---|---|---|---|
| **AXYS-ADR-001** | [Arquitetura Inicial Executável](foundation/adrs/AXYS-ADR-001-arquitetura-inicial-executavel.md) | ✅ Aceito | Todos |
| **AXYS-ADR-002** | [Tenancy e Isolamento](foundation/adrs/AXYS-ADR-002-tenancy-e-isolamento.md) | ✅ Aceito | Todos |
| **AXYS-ADR-003** | [Licenciamento Centralizado](foundation/adrs/AXYS-ADR-003-licenciamento-centralizado.md) | ✅ Aceito | Todos |
| **AXYS-ADR-004** | [Operação Offline e Modo Degradado](foundation/adrs/AXYS-ADR-004-operacao-offline-e-modo-degradado.md) | ✅ Aceito | Todos |
| **AXYS-ADR-005** | [Versionamento e Compatibilidade](foundation/adrs/AXYS-ADR-005-versionamento-e-compatibilidade.md) | ✅ Aceito | Todos |
| **AXYS-ADR-006** | [Segurança e Gestão de Segredos](foundation/adrs/AXYS-ADR-006-seguranca-e-gestao-de-segredos.md) | ✅ Aceito | Todos |
| **AXYS-ADR-007** | [Auditoria e Logging](foundation/adrs/AXYS-ADR-007-auditoria-e-logging.md) | ✅ Aceito | Todos |
| **AXYS-ADR-008** | [Armazenamento de Arquivos e Anexos](foundation/adrs/AXYS-ADR-008-armazenamento-de-arquivos-e-anexos.md) | ✅ Aceito | Todos |
| **AXYS-ADR-009** | [Backup e Disaster Recovery](foundation/adrs/AXYS-ADR-009-backup-e-disaster-recovery.md) | ✅ Aceito | Todos |
| **AXYS-ADR-010** | [Observabilidade, Métricas e Alertas](foundation/adrs/AXYS-ADR-010-observabilidade-metricas-e-alertas.md) | ✅ Aceito | Todos |
| **AXYS-ADR-011** | [Integração com ERPs Externos](foundation/adrs/AXYS-ADR-011-integracao-com-erps-externos.md) | ✅ Aceito | Pro, Sync |
| **AXYS-ADR-012** | [Extensibilidade e Plugins](foundation/adrs/AXYS-ADR-012-extensibilidade-e-plugins.md) | ✅ Aceito | Pro |
| **AXYS-ADR-013** | [Performance e Estratégia de Cache](foundation/adrs/AXYS-ADR-013-performance-e-estrategia-de-cache.md) | ✅ Aceito | Todos |
| **AXYS-ADR-014** | [Internacionalização (i18n/l10n)](foundation/adrs/AXYS-ADR-014-internacionalizacao-i18n-l10n.md) | ✅ Aceito | Todos |
| **AXYS-ADR-015** | [Suporte e SLA](foundation/adrs/AXYS-ADR-015-suporte-e-sla.md) | ✅ Aceito | Todos |
| **AXYS-ADR-016** | [Política Comercial e Precificação](foundation/adrs/AXYS-ADR-016-politica-comercial-e-precificacao.md) | ✅ Aceito | Todos |
| **AXYS-ADR-017** | [Roadmap e Governança de Produto](foundation/adrs/AXYS-ADR-017-roadmap-e-governanca-de-produto.md) | ✅ Aceito | Todos |
| **AXYS-ADR-018** | [Compliance (LGPD) e Retenção de Dados](foundation/adrs/AXYS-ADR-018-compliance-lgpd-e-retencao-de-dados.md) | ✅ Aceito | Todos |
| **AXYS-ADR-019** | [Atualização e Deploy (Cloud/On-Prem)](foundation/adrs/AXYS-ADR-019-atualizacao-e-deploy-cloud-onprem.md) | ✅ Aceito | Todos |
| **AXYS-ADR-020** | [Ferramentas (Excel, AutoLISP, API)](foundation/adrs/AXYS-ADR-020-ferramentas-excel-autolisp-api.md) | ✅ Aceito | Todos |
| **AXYS-ADR-021** | [SSO via JWT entre Hub e Aplicações](foundation/adrs/AXYS-ADR-021-sso-jwt-hub-easy.md) | ✅ Aceito | Hub, Easy, Pro |
| **AXYS-ADR-022** | [Princípios de Design Minimalista e Sustentável](foundation/adrs/AXYS-ADR-022-principios-de-design-minimalista-e-sustentavel.md) | ✅ Aceito | Todos |

---

## 🏢 Hub — HUB-ADR (Específico)

**Localização:** `docs/projects/axys-hub/adrs/`

| ADR | Título | Status | Razão |
|---|---|---|---|
| **HUB-ADR-001** | [Seed Mínimo Inicial](projects/axys-hub/adrs/HUB-ADR-001-seed-minimo-inicial.md) | ✅ Aceito | Dados iniciais necessários para Hub operar |
| **HUB-ADR-002** | [Hub como Control Plane](projects/axys-hub/adrs/HUB-ADR-002-control-plane.md) | ✅ Aceito | Papel central do Hub no ecossistema |
| **HUB-ADR-003** | [Licenciamento Lease Token](projects/axys-hub/adrs/HUB-ADR-003-licenciamento-lease-token.md) | ✅ Aceito | Mecanismo específico de emissão de licenças |
| **HUB-ADR-004** | [Arquitetura Push-Only para ERP](projects/axys-hub/adrs/HUB-ADR-004-push-only-erp.md) | ✅ Aceito | Hub não lê de Pro, apenas Pro lê de Hub |
| **HUB-ADR-005** | [Template para ADRs](projects/axys-hub/adrs/HUB-ADR-005-template.md) | 📋 Referência | Padrão para futuras decisões |

---

## 💰 Easy — EASY-ADR (Específico)

**Localização:** `docs/projects/axys-easy/adrs/`

| ADR | Título | Status | Razão |
|---|---|---|---|
| **EASY-ADR-001** | [Separação Core/Módulos/MicroApps](projects/axys-easy/adrs/EASY-ADR-001-separacao-core-modulos-microapps.md) | ✅ Aceito | Arquitetura modular de Easy |
| **EASY-ADR-002** | [Seed Mínimo Inicial](projects/axys-easy/adrs/EASY-ADR-002-seed-minimo-inicial.md) | ✅ Aceito | Dados iniciais para operar |
| **EASY-ADR-003** | [UX e Consistência de Interface](projects/axys-easy/adrs/EASY-ADR-003-ux-e-consistencia-de-interface.md) | ✅ Aceito | Padrões de design sistema Easy |
| **EASY-ADR-004** | [Licenciamento e Validação Local](projects/axys-easy/adrs/EASY-ADR-004-licenciamento-e-validacao-local.md) | ✅ Aceito | Easy valida offline com grace period |
| **EASY-ADR-005** | [Ferramentas (Excel, AutoLISP, API)](projects/axys-easy/adrs/EASY-ADR-005-ferramentas-excel-autolisp-api.md) | ✅ Aceito | Integração com ferramentas externas |

---

## 🏗️ Pro — PRO-ADR (Específico)

**Localização:** `docs/projects/axys-pro/adrs/`

| ADR | Título | Status | Razão |
|---|---|---|---|
| **PRO-ADR-001** | [Template para ADRs](projects/axys-pro/adrs/PRO-ADR-001-template.md) | 📋 Template | Padrão para futuras decisões de Pro |

---

## 🔄 Sync — SYNC-ADR (Futuro)

**Localização:** `docs/projects/axys-sync/adrs/`

*(Não há ADRs específicas ainda — Sync usa AXYS-ADRs)*

---

## 🔍 Pesquisa por Tema

### Autenticação & Autorização
- **AXYS-ADR-021** — SSO via JWT
- **AXYS-ADR-002** — Tenancy
- **HUB-ADR-002** — Control Plane

### Segurança & Compliance
- **AXYS-ADR-006** — Gestão de Segredos
- **AXYS-ADR-018** — LGPD
- **AXYS-ADR-008** — Armazenamento seguro

### Performance & Escalabilidade
- **AXYS-ADR-013** — Cache e Performance
- **AXYS-ADR-002** — Tenancy (isolamento)
- **AXYS-ADR-003** — Licenciamento escalável

### Confiabilidade & Operações
- **AXYS-ADR-004** — Offline-first
- **AXYS-ADR-009** — Backup/DR
- **AXYS-ADR-019** — Deploy

### Produto & Negócio
- **AXYS-ADR-016** — Precificação
- **AXYS-ADR-017** — Roadmap
- **AXYS-ADR-015** — Suporte/SLA

---

## 📊 Estatísticas

| Escopo | Total | Status |
|---|---|---|
| **AXYS-ADR (Foundation)** | 21 | ✅ Completo |
| **HUB-ADR** | 5 | ✅ Completo |
| **EASY-ADR** | 5 | ✅ Completo |
| **PRO-ADR** | 1 | 📋 Template |
| **SYNC-ADR** | — | — |
| **Total** | **32** | — |

---

## 🔗 Referências Cruzadas

### Decisões Relacionadas
```
AXYS-ADR-002 (Tenancy)
  ├─ AXYS-ADR-003 (Licenciamento centralizado)
  ├─ HUB-ADR-002 (Control Plane)
  └─ EASY-ADR-004 (Validação local)

AXYS-ADR-021 (SSO/JWT)
  ├─ AXYS-ADR-006 (Segurança)
  ├─ HUB-ADR-003 (Lease Token)
  └─ EASY-ADR-004 (Validação offline)
```

---

## 💡 Como Criar Uma Nova ADR

1. **Determine o escopo:** Global (AXYS-ADR) ou Projeto-específico (XX-ADR)?
2. **Pegue o próximo número** disponível na sequência
3. **Use o template:** `docs/projects/{project}/adrs/XX-ADR-00X-template.md`
4. **Atualize este INDEX**

**Exemplo para Pro:**
```
PRO-ADR-002-nome-da-decisao.md
```

---

## 📝 Histórico de Mudanças

| Data | Ação |
|---|---|
| 01/06/2026 | Renumeração com prefixos (ADR-xxx → ESCOPO-ADR-xxx) |
| 01/06/2026 | Criada AXYS-ADR-021 (SSO/JWT) |
| 01/06/2026 | Criado PRO-ADR-001 (template) |

