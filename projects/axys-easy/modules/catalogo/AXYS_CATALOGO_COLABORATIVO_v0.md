# Axys Easy — Catálogo Público Colaborativo (v0 — Conceitual)

**Status:** Decisão Arquitetural Aprovada · Documento **Conceitual** (v0)
**Data:** 2026-06-03
**Escopo:** módulo `catalogo` — camada de publicação/curadoria de composições de tenants.
**Natureza:** **somente documental.** Nada aqui é DDL, migration, tabela física, endpoint ou comportamento. Os atributos e estados descritos são **conceituais** e ainda **não** representam schema.

> Regras de negócio do catálogo: ver [../../contracts/catalogo/CATALOGO_BUSINESS_RULES.md](../../contracts/catalogo/CATALOGO_BUSINESS_RULES.md).
> Governança: Contrato governa · Schema suporta · Código implementa · Tela opera.

---

## 1. Contexto

O módulo Catálogo do Axys Easy possui uma **base canônica e pública** mantida pela Axys — fontes, **insumos** e **composições** — que é a referência oficial do ecossistema. Tenants produzem composições próprias no uso diário. Foi aprovada a diretriz de criar uma **camada intermediária de publicação e curadoria** que permita, no futuro, que composições desenvolvidas por tenants sejam **compartilhadas com toda a comunidade** — sem comprometer a base oficial.

## 2. Problema atual

- As tabelas canônicas (`catalogo.insumos`, `catalogo.composicoes`) são **oficiais e públicas**; não há caminho para uma contribuição de tenant tornar-se pública **sem poluir** essa base ou **quebrar o isolamento** entre tenants.
- Não existe **curadoria**, **versionamento de contribuição**, **rastreabilidade de origem** nem **estado de publicação** para conteúdo originado de tenants.
- Sem essa camada, qualquer compartilhamento misturaria dado oficial com dado de terceiro, sem validação e sem trilha.

## 3. Motivação

- **Efeito de rede:** o catálogo cresce com a comunidade; composições boas circulam.
- **Reaproveitamento:** evita retrabalho entre tenants.
- **Valor agregado** ao produto, **preservando** a confiabilidade da base oficial.
- A base oficial **precisa permanecer** íntegra, auditável e de alta qualidade técnica.

## 4. Requisitos funcionais

- Um tenant pode **submeter** uma composição própria para publicação na comunidade.
- A Axys pode **revisar, aprovar ou rejeitar** a submissão.
- Composição aprovada torna-se **visível à comunidade** com origem `Comunidade`.
- **Rastreabilidade de origem** (tenant e registro original) preservada.
- **Versionamento** da contribuição publicada.
- **Deprecação** de versões superadas.
- **Rejeição com motivo** registrado.
- **Promoção opcional** de uma contribuição para o catálogo **oficial** (decisão da Axys, sob critérios).

## 5. Requisitos não funcionais

- **Isolamento entre tenants** preservado em todas as etapas.
- Base canônica **intocada** por contribuição não promovida.
- Processo **auditável** de ponta a ponta.
- Revisão **idempotente** e reversível.
- **Escalabilidade** (volume de contribuições e de busca).
- **Busca/indexação públicas** por origem e qualidade.
- **Qualidade técnica** mensurável (score).

## 6. Modelo conceitual

Uma **camada de publicação/curadoria** distinta das tabelas canônicas. A contribuição **nunca** grava direto em `catalogo.composicoes`; vive na camada intermediária com **estado** (§8) e **metadados** (§9). Somente após aprovação a contribuição torna-se pública.

O **catálogo público** passa a ter três **origens** possíveis (`source_type`):

| Origem | Significado |
|---|---|
| **Oficial** | Referências institucionais externas (SINAPI, CDHU, FDE, ORSE, EMOP…). |
| **Axys** | Composições próprias curadas pela Axys (fonte `AXYS`). |
| **Comunidade** | Contribuições de tenants **validadas** pela Axys. |

> Conceitual — sem DDL. A separação física (tabelas de staging, views públicas, etc.) será decidida na arquitetura definitiva.

## 7. Fluxo de submissão

1. Tenant desenvolve a composição no seu espaço privado → estado `private`.
2. Tenant **submete** para publicação → estado `submitted` (entra na fila de curadoria).
3. A submissão carrega a **origem rastreável** (`origin_tenant_id`, `origin_record_id`).

## 8. Fluxo de aprovação

1. Curadoria da Axys assume a submissão → `under_review`.
2. Desfecho:
   - **Aprovação** → `approved`: marca `is_public`, `is_validated_by_axys`, atribui `public_version`, registra `validated_by`/`validated_at`.
   - **Rejeição** → `rejected`: registra `rejection_reason`; volta ao tenant para correção/reenvio.
3. Versão superada → `deprecated`.
4. **Promoção a Oficial** (opcional): decisão explícita da Axys, sob os critérios da §12 — só então o conteúdo migra para a base canônica.

## 9. Estados conceituais

| Estado | Significado |
|---|---|
| `private` | Em desenvolvimento no tenant; não submetido; invisível à comunidade. |
| `submitted` | Submetido pelo tenant; aguardando curadoria. |
| `under_review` | Em análise pela curadoria da Axys. |
| `approved` | Aprovado e publicado para a comunidade. |
| `rejected` | Recusado; com `rejection_reason`; reenviável. |
| `deprecated` | Versão pública superada/descontinuada. |

## 10. Metadados conceituais previstos

Atributos **conceituais** (ainda **não** DDL) que deverão existir na arquitetura definitiva:

| Atributo | Propósito |
|---|---|
| `source_type` | Origem: `Oficial` \| `Axys` \| `Comunidade`. |
| `origin_tenant_id` | Tenant autor da contribuição (rastreabilidade/isolamento). |
| `origin_record_id` | Registro original no espaço do tenant. |
| `is_public` | Visível à comunidade. |
| `is_validated_by_axys` | Passou pela curadoria oficial. |
| `validated_by` | Quem validou. |
| `validated_at` | Quando validou. |
| `validation_status` | Situação da validação (alinhada aos estados da §9). |
| `quality_score` | Nota de qualidade técnica. |
| `public_version` | Versão pública da contribuição. |
| `rejection_reason` | Motivo da rejeição. |

## 11. Regras de governança

- A **base canônica continua exclusiva da Axys**.
- Contribuições de tenants **não entram diretamente** no catálogo oficial.
- **Toda contribuição passa por curadoria** da Axys.
- **Origem sempre rastreável** (`source_type`, `origin_tenant_id`, `origin_record_id`).
- Validação **registrada e auditável** (`validated_by`/`validated_at`).
- Rejeição **sempre motivada** (`rejection_reason`).
- Isolamento entre tenants **preservado** em todas as etapas.
- Licenciamento das contribuições: **a definir** (ver pendências).

## 12. Critérios de publicação

- **Completude técnica**: itens/coeficientes resolvidos; sem dependências quebradas (insumo/subcomposição inexistente).
- **Classificação válida** dos insumos referenciados.
- **Qualidade mínima** (`quality_score` acima de limiar).
- **Conformidade** com as regras de negócio do catálogo.
- **Validação explícita** da Axys.
- Promoção a **Oficial** exige critério adicional (relevância, recorrência, revisão reforçada).

## 13. Estratégia de versionamento

- Cada contribuição publicada recebe `public_version`.
- Versão publicada é **imutável**; correção gera **nova versão**.
- Versões antigas vão a `deprecated`, preservadas para histórico/auditoria.
- Alinhar com o versionamento **por edição** do catálogo (preços/composições imutáveis por edição).

## 14. Impactos sobre tenancy

- `origin_tenant_id` preserva a origem e sustenta o **isolamento**.
- A contribuição **não vaza** dados do tenant além do que foi explicitamente publicado.
- A base oficial é **cross-tenant, somente leitura** para a comunidade.
- Submissão é ato **opt-in** do tenant.

## 15. Impactos sobre auditoria

- Cada **transição de estado** é auditável (quem submeteu, revisou, aprovou/rejeitou e quando).
- `validated_by`/`validated_at` e `rejection_reason` compõem a trilha.
- Trilha completa no schema `audit`, retenção conforme política.

## 16. Impactos sobre busca e indexação

- Catálogo público indexável por **origem** (`Oficial`/`Axys`/`Comunidade`), `is_public` e `quality_score`.
- Busca **não** deve expor conteúdo `private`/`submitted`/`under_review`.
- Ranking pode ponderar **qualidade** e **validação**.
- Avaliar custo de **armazenamento e indexação** do conteúdo público (ver pendências).

---

## Itens em aberto

Listados em [../../governanca/pendencias.md](../../governanca/pendencias.md). Planejamento em [../../governanca/roadmap.md](../../governanca/roadmap.md).
