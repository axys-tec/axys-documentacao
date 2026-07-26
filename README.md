# Documentação — Ecossistema Axys

Bem-vindo ao repositório centralizado de documentação do **ecossistema Axys** — decisões arquiteturais, contratos técnicos, schemas de banco de dados e procedimentos operacionais.

---

## 🔄 Fluxo de trabalho (repo é submodule)

Este `docs/` é um **repo isolado** (`axys-tec/axys-documentacao`) embutido em **cada projeto Axys** como **git submodule**. Todos escrevem na **mesma `main`**, cada um na sua pasta (`projects/{seu-projeto}/`). Regras que mantêm o repo organizado sem dor:

- **`pull` antes de editar.** Sempre parta da `main` fresca — `git pull` dentro de `docs/` (ou `git submodule update --remote docs` a partir do projeto).
- **Nunca `git push --force`.** Push normal. Se o git recusar (você está atrás), dê `pull` e siga — ele **não** perde nada.
- **Conflito é por LINHA, não por arquivo.** Editar o **mesmo arquivo** em **linhas diferentes** → o git **auto-merge**. Só a **mesma linha** conflita, e aí ele mostra o diff pra você escolher — nada some.
- **Editar doc = commit no `docs/`**, não no projeto pai. O projeto pai só guarda um **ponteiro** (o SHA do submodule); dar bump nele é **opcional** e cosmético para knowledge base — pode ficar no SHA antigo que nada quebra.
- **Doc específico mora no projeto.** Nada de arquivo de um projeto na raiz do repo — vai em `projects/{project}/`.

> Rede de segurança: antes de um sync grande, uma branch `backup/docs-before-sync-{data}` guarda o snapshot para diffar/voltar.

---

## 🗂️ Estrutura

Este repositório está organizado em **três camadas**:

### 1️⃣ **Foundation** — Conhecimento Compartilhado
Decisões, padrões e contratos que valem para **todo o ecossistema**.

- **[adrs/](foundation/adrs/)** — Decisões arquiteturais globais (22 `AXYS-ADR-*`)
- **[contracts/](foundation/contracts/)** — Contratos técnicos reutilizáveis
- **[governance/](foundation/governance/)** — Padrões e convenções
- **[domain-models/](foundation/domain-models/)** — Conceitos de negócio
- **[patterns/](foundation/patterns/)** — Padrões técnicos

### 2️⃣ **Projects** — Projetos Específicos
Cada projeto Axys em seu próprio espaço.

| Projeto | Status | Propósito |
|---------|--------|----------|
| **[AxysHub](projects/axys-hub/)** | 🟢 Ativo | Sistema central de autenticação, usuários e tenants (core do ecossistema) |
| **[AxysEasy](projects/axys-easy/)** | 🟢 Ativo | Plataforma de orçamentação para construção civil |
| **[AxysSync](projects/axys-sync/)** | 🟢 Produção | Bridge de Contabilidade (consumo de dados + Hub) |
| **[AxysSyncLoccitane](projects/axys-sync-loccitane/)** | 🟢 Produção | Especializado — operações L'Occitane |
| **[AxysGestor](projects/axys-gestor/)** | 🟡 Concepção | Ecossistema de micro-apps de gestão de varejo (verticais + plugáveis) |
| **[AxysPro](projects/axys-pro/)** | 🟡 Planejado | Sistema ERP para projetos e obras |
| **[AxysCad](projects/axys-cad/)** | 🟡 Planejado | Integração CAD/BIM com levantamentos |
| **[AxysRvt](projects/axys-rvt/)** | 🟡 Planejado | Plugin Revit para BIM |
| **[AxysIFC](projects/axys-ifc/)** | 🟡 Planejado | Processamento de arquivos IFC |

Cada projeto contém:
- **ARCHITECTURE.md** — Visão geral e decisões
- **schemas/** — Banco de dados (schema.sql, seed.sql, migrations)
- **adrs/** — Decisões específicas do projeto
- **contracts/** — Contratos de API e domínio
- **modules/** — Documentação por módulo (se aplicável)

### 3️⃣ **Infrastructure** — Infraestrutura Compartilhada
Elementos que suportam toda a plataforma.

- **[databases/](infrastructure/databases/)** — Schemas compartilhados (audit, hub)
- **[deployment/](infrastructure/deployment/)** — Deploy, CI/CD, Render
- **[security/](infrastructure/security/)** — Autenticação, secrets, TLS
- **[monitoring/](infrastructure/monitoring/)** — Logging, métricas, alertas

### 4️⃣ **Runbooks & Integrations**
- **[runbooks/](runbooks/)** — Procedimentos operacionais
- **[integrations/](integrations/)** — Mapas de fluxo entre projetos

---

## 🚀 Como Navegar

### Você quer entender...

**...o que rege todo o ecossistema?**  
→ Leia [foundation/adrs/](foundation/adrs/) (decisões globais)

**...como funciona um projeto específico?**  
→ Abra [projects/{project}/ARCHITECTURE.md](projects/)

**...a estrutura do banco de dados do Easy?**  
→ Veja [projects/axys-easy/schemas/](projects/axys-easy/schemas/)

**...como integrar dois projetos?**  
→ Consulte [integrations/ecosystem-overview.md](integrations/) e o projeto específico

**...padrões de código e convenções?**  
→ Leia [foundation/governance/](foundation/governance/)

---

## 📋 Padrão: Schemas e Migrations

Cada projeto que tem banco de dados segue este padrão:

```
projects/{project}/schemas/
├── schema.sql           # DDL completo (idempotente)
├── seed.sql             # dados iniciais essenciais
└── migrations/
    ├── README.md        # instruções
    ├── 001-initial-schema.sql
    ├── 002-add-feature.sql
    └── ...              # aplicadas em ordem
```

**Regra:**
- `schema.sql` = estado atual completo (recrear do zero)
- `migrations/` = histórico incremental (para evolução)
- `seed.sql` = dados essenciais (fontes de referência, usuários base)

---

## 🔗 Referências Cruzadas

Documentação é um sistema vivo. Use markdown links com caminho relativo:

```markdown
@see [ADR-029 — Autenticação](../../foundation/adrs/ADR-029-SSO-JWT-hub-easy.md)
Para integração, consulte [AxysHub > API](../axys-hub/api/endpoints.md)
```

---

## 📅 Histórico

- **31/05/2026** — Estrutura aprovada e skeleton criado
- **01/06/2026** — Limpeza de resíduos, READMEs por projeto
- **26/07/2026** — Fluxo de trabalho do submodule documentado; tabela de projetos reconciliada (+Gestor/Sync/Cad); `STORAGE_TREE.md` movido p/ `projects/axys-easy/`; links mortos corrigidos

---

## ❓ Dúvidas?

- **Um ADR não existe?** — Verifique [foundation/adrs/ADR-XXX-template.md](foundation/adrs/ADR-XXX-template.md)
- **Preciso adicionar documentação?** — Siga o padrão da pasta e crie um PR
- **Estrutura antiga?** — Veja [archive/retired-code/](archive/retired-code/) (referência histórica)

