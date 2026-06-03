# Axys Easy — Catálogo Público Colaborativo (v0 — Conceitual)

**Status:** Decisão Arquitetural Aprovada · Documento **Conceitual** (v0) · Insumo para a **FASE 7** do roadmap de import/catálogo
**Data:** 2026-06-03
**Escopo:** módulo `catalogo` — camada conceitual de publicação e curadoria de composições originadas de tenants.
**Natureza:** **somente documental.** Nada aqui é DDL, migration, tabela física, view, índice, endpoint, API ou comportamento implementado. Todos os atributos, estados, fluxos e regras descritos são **conceituais** e **ainda não representam schema** nem contrato implementável. A modelagem física (tabelas de staging, views públicas, índices, máquinas de estado) será decidida na arquitetura definitiva, quando — e somente quando — o roadmap alcançar a fase correspondente.

> Princípio de governança do projeto: **Contrato governa · Schema suporta · Código implementa · Tela opera.**
> Regras de negócio do catálogo: ver [../../contracts/catalogo/CATALOGO_BUSINESS_RULES.md](../../contracts/catalogo/CATALOGO_BUSINESS_RULES.md).
> Modelo de fontes/edições (imutabilidade por edição): ver [../../contracts/catalogo/CATALOGO_FONTES.md](../../contracts/catalogo/CATALOGO_FONTES.md) e [../../contracts/catalogo/CATALOGO_EDICOES.md](../../contracts/catalogo/CATALOGO_EDICOES.md).
> Posicionamento no roadmap: este documento é **insumo da FASE 7** do `PLANO_IMPORT_CATALOGO.md`. Só será **avaliado e detalhado** quando o roadmap chegar lá; antes disso permanece como decisão registrada, não como trabalho ativo.

---

## 1. Contexto

O módulo Catálogo do Axys Easy possui uma **base canônica** mantida pela Axys — **fontes**, **insumos** e **composições** — que é a referência oficial do ecossistema. Essa base é construída a partir de fontes externas reconhecidas (SINAPI, CDHU…) e de composições próprias curadas internamente, e está organizada por **edições imutáveis** (preços e composições congelados por edição).

No uso diário, cada **tenant** produz composições próprias: ajustes, variações regionais, composições inéditas para serviços não cobertos pelas fontes oficiais. Hoje esse conhecimento fica **preso ao tenant**.

Foi aprovada a diretriz de criar uma **camada intermediária de publicação e curadoria** que permita, no futuro, que composições desenvolvidas por tenants sejam **compartilhadas com toda a comunidade** — sem comprometer a base oficial e sem quebrar o isolamento entre tenants. Esta camada é o objeto deste documento.

## 2. Problema atual

- As tabelas canônicas (`catalogo.insumos`, `catalogo.composicoes`) são **oficiais**; **não existe caminho** para uma contribuição de tenant tornar-se pública **sem poluir** essa base ou **quebrar o isolamento** entre tenants.
- Não há **processo de curadoria**, **versionamento de contribuição**, **rastreabilidade de origem** nem **estado de publicação** para conteúdo originado de tenants.
- Sem essa camada, qualquer tentativa de compartilhamento **misturaria** dado oficial com dado de terceiro — sem validação, sem trilha, sem responsabilidade clara sobre a qualidade técnica.
- O conhecimento produzido pelos tenants **não circula**: cada um reconstrói composições que outros já resolveram.
- Não há distinção visível, na busca, entre o que é **referência oficial** e o que seria **contribuição da comunidade**.

## 3. Motivação

- **Efeito de rede:** o catálogo cresce com a comunidade; composições boas circulam e o valor do produto aumenta com a base de usuários.
- **Reaproveitamento:** evita retrabalho entre tenants; quem precisa de uma composição já validada por outro pode adotá-la.
- **Valor agregado** ao produto, **preservando** a confiabilidade e a reputação técnica da base oficial.
- A base oficial **precisa permanecer** íntegra, auditável e de alta qualidade — a colaboração não pode degradá-la.
- **Curadoria como diferencial:** o que distingue o catálogo Axys de um repositório aberto é o filtro de qualidade. A camada colaborativa só faz sentido se a curadoria for parte integrante dela.

## 4. Requisitos funcionais

- Um tenant pode **submeter** uma composição própria para publicação na comunidade (ato **opt-in**, nunca automático).
- A Axys pode **assumir, revisar, aprovar ou rejeitar** a submissão.
- Composição aprovada torna-se **visível à comunidade** com origem `Comunidade`.
- **Rastreabilidade de origem** (tenant autor e registro original) preservada do início ao fim.
- **Versionamento** da contribuição publicada (cada publicação tem uma versão).
- **Deprecação** de versões superadas, mantendo histórico.
- **Rejeição com motivo** registrado e devolução ao tenant para correção/reenvio.
- **Promoção opcional** de uma contribuição para o catálogo **Oficial/Axys** — decisão explícita e exclusiva da Axys, sob critérios reforçados.
- **Consulta/busca** do catálogo público filtrando por origem e qualidade.
- **Reenvio** de uma contribuição rejeitada após correção, gerando nova passagem por curadoria.

## 5. Requisitos não funcionais

- **Isolamento entre tenants** preservado em todas as etapas do fluxo.
- Base canônica **intocada** por contribuição enquanto não for explicitamente promovida.
- Processo **auditável de ponta a ponta** (cada transição registrada).
- Revisão **idempotente e reversível** — reprocessar uma decisão não deve corromper estado.
- **Escalabilidade** para volume crescente de contribuições e de buscas.
- **Busca e indexação públicas** segmentadas por origem e qualidade, sem vazar conteúdo não publicado.
- **Qualidade técnica mensurável** (score) como apoio à curadoria e ao ranking.
- **Performance de leitura** do catálogo público não pode ser prejudicada pela camada de staging.

## 6. Modelo conceitual

A camada colaborativa é uma **camada de publicação/curadoria conceitualmente distinta** das tabelas canônicas. A contribuição **nunca grava direto** em `catalogo.composicoes`: ela vive em uma área intermediária (staging conceitual), portando **estado** (§9) e **metadados** (§10). Somente após aprovação a contribuição passa a ser **pública**; somente após **promoção explícita** ela pode integrar a base canônica.

Com isso, o **catálogo público** passa a ter **três origens** possíveis, expressas conceitualmente pelo metadado `source_type`:

| Origem | `source_type` | Significado | Quem mantém |
|---|---|---|---|
| **Oficial** | `Oficial` | Referências institucionais externas (SINAPI, CDHU…), importadas por edição. | Axys (import) |
| **Axys** | `Axys` | Composições próprias curadas pela Axys (fonte `AXYS`). | Axys (autoria) |
| **Comunidade** | `Comunidade` | Contribuições de tenants **validadas** pela Axys via curadoria. | Tenant (autoria) + Axys (validação) |

Pontos estruturantes do modelo:

- **Oficial** e **Axys** compõem a **base canônica**, que continua **exclusiva da Axys** (ver §11).
- **Comunidade** é a única origem alimentada por terceiros, e **somente** após curadoria.
- A separação entre "publicado para a comunidade" e "promovido a canônico" é deliberada: publicar **não** é promover.

> Conceitual — sem DDL. A separação física (tabelas de staging, views públicas, índices de busca, máquina de estados) será decidida na arquitetura definitiva.

## 7. Fluxo de submissão

1. O tenant desenvolve a composição no seu espaço privado → estado `private`.
2. O tenant decide **submeter** para publicação (opt-in) → estado `submitted`; a contribuição entra na **fila de curadoria**.
3. A submissão carrega a **origem rastreável**: `origin_tenant_id` (autor) e `origin_record_id` (registro original no espaço do tenant).
4. A submissão passa por **verificações conceituais de elegibilidade** (completude técnica mínima) antes de ser oferecida à curadoria; falhas podem manter o item como `submitted` com pendências sinalizadas.
5. Enquanto não aprovada, a contribuição **não é visível** à comunidade e **não afeta** a base canônica.

## 8. Fluxo de aprovação

1. A curadoria da Axys **assume** uma submissão da fila → `under_review`.
2. Análise da contribuição contra os **critérios de publicação** (§12) e as regras de negócio do catálogo.
3. Desfecho:
   - **Aprovação** → `approved`: marca `is_public` e `is_validated_by_axys`, atribui `public_version`, registra `validated_by`/`validated_at`, define `validation_status` aprovado e (opcionalmente) `quality_score`.
   - **Rejeição** → `rejected`: registra `rejection_reason`; a contribuição volta ao tenant para correção/reenvio.
4. **Reenvio** de item rejeitado: gera nova passagem (`submitted` → `under_review` → desfecho).
5. **Deprecação** → `deprecated`: versão pública superada por uma versão mais nova, preservada para histórico.
6. **Promoção a Oficial/Axys** (opcional): decisão **explícita** da Axys, sob os critérios reforçados da §12 — só então o conteúdo migra para a base canônica.

```
private ──submeter──▶ submitted ──assumir──▶ under_review ──▶ approved ──supersedida──▶ deprecated
                          ▲                         │
                          └──────reenviar───────────┴──▶ rejected (com rejection_reason)
                                                                  │
                                                  approved ──promoção explícita──▶ base canônica (Oficial/Axys)
```
*Diagrama conceitual; não representa máquina de estados implementada.*

## 9. Estados conceituais

Cada estado abaixo é **conceitual** e **não** representa, ainda, uma coluna, enum ou máquina de estados física.

| Estado | Significado | Visível à comunidade? | Afeta base canônica? |
|---|---|---|---|
| `private` | Em desenvolvimento no tenant; não submetido. É o estado natural de qualquer composição de tenant. | Não | Não |
| `submitted` | Submetido pelo tenant; aguardando que a curadoria o assuma. | Não | Não |
| `under_review` | Em análise ativa pela curadoria da Axys. | Não | Não |
| `approved` | Aprovado e publicado para a comunidade com origem `Comunidade`. | Sim | Não (até promoção) |
| `rejected` | Recusado pela curadoria; sempre com `rejection_reason`; reenviável após correção. | Não | Não |
| `deprecated` | Versão pública superada/descontinuada; mantida para histórico e auditoria. | Sim (marcada como obsoleta) | Não |

Observações:
- `private` é a porta de entrada e o destino implícito de tudo que nunca foi submetido.
- `approved` e `deprecated` são os únicos estados expostos publicamente; `deprecated` aparece sinalizado como superado.
- Nenhum estado, por si só, coloca conteúdo na base canônica — isso exige **promoção** (§8.6).

## 10. Metadados conceituais previstos

Atributos **conceituais** que deverão existir na arquitetura definitiva. **Ainda não são DDL**, colunas, enums nem tipos — são intenções de modelagem a serem formalizadas na FASE 7.

| Atributo | Propósito |
|---|---|
| `source_type` | Origem do registro no catálogo público: `Oficial` \| `Axys` \| `Comunidade`. |
| `origin_tenant_id` | Tenant autor da contribuição — sustenta rastreabilidade e isolamento. |
| `origin_record_id` | Registro original no espaço privado do tenant (vínculo com a fonte da contribuição). |
| `is_public` | Indica visibilidade à comunidade (verdadeiro apenas para `approved`/`deprecated`). |
| `is_validated_by_axys` | Indica que a contribuição passou pela curadoria oficial da Axys. |
| `validated_by` | Identidade do curador/responsável que validou. |
| `validated_at` | Momento da validação. |
| `validation_status` | Situação da validação, alinhada aos estados da §9 (ex.: pendente, aprovado, rejeitado). |
| `quality_score` | Nota de qualidade técnica, apoio à curadoria e ao ranking de busca. |
| `public_version` | Versão pública atribuída à contribuição publicada (imutável por versão). |
| `rejection_reason` | Motivo registrado quando a contribuição é rejeitada. |

> Reforço: estes metadados são **conceituais**. Nomes, tipos, obrigatoriedade, defaults e relacionamentos serão definidos no contrato/schema na fase de implementação.

## 11. Regras de governança

- A **base canônica continua exclusiva da Axys**. Origens `Oficial` e `Axys` só são alimentadas pela Axys.
- Contribuições de tenants **não entram diretamente** no catálogo oficial — nem por aprovação, nem por publicação. Só por **promoção explícita**.
- **Toda contribuição passa por curadoria** da Axys antes de qualquer exposição pública.
- **Origem sempre rastreável** (`source_type`, `origin_tenant_id`, `origin_record_id`) em todas as etapas.
- Validação **registrada e auditável** (`validated_by`/`validated_at`/`validation_status`).
- Rejeição **sempre motivada** (`rejection_reason`).
- **Isolamento entre tenants preservado** em todas as etapas; nenhum tenant vê o conteúdo `private`/`submitted`/`under_review` de outro.
- **Publicar não é promover:** aprovação dá visibilidade à comunidade; promoção a canônico é decisão adicional e restrita.
- **Licenciamento das contribuições:** termos de uso/licença sob os quais um tenant cede a composição para a comunidade — **a definir** (ver pendências).
- **Responsabilidade técnica:** ao validar, a Axys assume a curadoria, mas a autoria permanece atribuída ao tenant de origem.

## 12. Critérios de publicação

Para passar de `under_review` a `approved`:

- **Completude técnica:** itens e coeficientes resolvidos; sem dependências quebradas (insumo ou subcomposição inexistente).
- **Classificação válida** dos insumos referenciados.
- **Qualidade mínima:** `quality_score` acima de limiar a definir.
- **Conformidade** com as regras de negócio do catálogo ([CATALOGO_BUSINESS_RULES.md](../../contracts/catalogo/CATALOGO_BUSINESS_RULES.md)).
- **Origem íntegra:** `origin_tenant_id`/`origin_record_id` consistentes.
- **Validação explícita** da Axys (`is_validated_by_axys`, `validated_by`/`validated_at`).

Para **promoção a Oficial/Axys** (critério reforçado, além dos acima):

- **Relevância e recorrência:** demanda repetida/ampla pela composição na comunidade.
- **Revisão reforçada:** segunda checagem técnica e enquadramento na curadoria oficial.
- **Estabilidade:** versão pública madura, sem pendências abertas.
- **Decisão explícita** e documentada da Axys.

## 13. Estratégia de versionamento

- Cada contribuição publicada recebe `public_version`.
- A versão publicada é **imutável**; correções geram **nova versão**, nunca edição in-place.
- Versões antigas vão a `deprecated`, **preservadas** para histórico e auditoria.
- Alinhamento com o versionamento **por edição** do catálogo (preços/composições imutáveis por edição) — ver [CATALOGO_EDICOES.md](../../contracts/catalogo/CATALOGO_EDICOES.md).
- A relação entre `public_version` da contribuição e a edição vigente do catálogo será detalhada na FASE 7.

## 14. Impactos sobre tenancy

- `origin_tenant_id` preserva a origem e **sustenta o isolamento** ao longo de todo o ciclo.
- A contribuição **não vaza** dados do tenant além do que foi **explicitamente publicado** — conteúdo privado e dados sensíveis do orçamento de origem não acompanham a publicação.
- A base oficial é **cross-tenant, somente leitura** para a comunidade.
- A submissão é um ato **opt-in** do tenant; nada é publicado por padrão.
- Estados `private`/`submitted`/`under_review` permanecem **invisíveis a outros tenants**.

## 15. Impactos sobre auditoria

- Cada **transição de estado** é auditável: quem submeteu, quem assumiu, quem aprovou/rejeitou e quando.
- `validated_by`/`validated_at`/`validation_status` e `rejection_reason` compõem a trilha de curadoria.
- **Promoção a canônico** é evento auditável de primeira classe, dada sua sensibilidade.
- Trilha completa esperada no schema `audit`, com retenção conforme política vigente.
- A imutabilidade das versões (`public_version`) reforça a auditabilidade: o que foi publicado fica preservado mesmo após `deprecated`.

## 16. Impactos sobre busca e indexação

- Catálogo público indexável por **origem** (`Oficial`/`Axys`/`Comunidade`), por `is_public` e por `quality_score`.
- A busca **não deve expor** conteúdo `private`/`submitted`/`under_review`.
- Conteúdo `deprecated` aparece **sinalizado como obsoleto**, não como resultado padrão.
- O **ranking** pode ponderar qualidade (`quality_score`) e validação (`is_validated_by_axys`), favorecendo conteúdo curado.
- Avaliar custo de **armazenamento e indexação** do conteúdo público crescente (ver pendências).
- A filtragem por origem deve ser explícita ao usuário, para que ele saiba se consome referência **Oficial/Axys** ou contribuição da **Comunidade**.

---

## 17. Riscos

Conceituais — mitigação será detalhada na FASE 7.

| Risco | Impacto | Mitigação conceitual |
|---|---|---|
| **Contaminação da base canônica** por contribuição não curada | Perda de confiabilidade/reputação do catálogo oficial | Staging isolado; contribuição nunca grava direto em `catalogo.composicoes`; promoção só por decisão explícita da Axys |
| **Vazamento entre tenants** (conteúdo `private`/`submitted` exposto) | Quebra de isolamento e de confiança | Visibilidade pública só a partir de `approved`; busca filtra estados não públicos |
| **Qualidade técnica baixa** circulando como "comunidade" | Erros de orçamento herdados por terceiros | Curadoria obrigatória + `quality_score` + sinalização de origem na busca |
| **Gargalo de curadoria** (fila cresce mais que a capacidade Axys) | Contribuições paradas, frustração do tenant | Critérios de elegibilidade automáticos antes da fila; priorização por `quality_score` |
| **Disputa de autoria/licenciamento** das contribuições | Risco jurídico | Termos de cessão/licenciamento definidos antes de abrir submissão (pendência) |
| **Custo de armazenamento/indexação** do público crescente | Degradação de performance/custo | Avaliar particionamento e política de retenção de `deprecated` (pendência) |
| **Divergência origem×realidade** (registro original do tenant muda após publicar) | Conteúdo público desatualizado | `public_version` desacoplada do registro de origem; versionamento explícito |

---

## Posicionamento no roadmap

Este documento é **insumo da FASE 7** do `PLANO_IMPORT_CATALOGO.md`. Ele **não** autoriza implementação: registra a decisão arquitetural e o modelo conceitual aprovados. O detalhamento de contrato, schema, código e tela só ocorrerá quando o roadmap alcançar a FASE 7, respeitando o princípio **Contrato governa · Schema suporta · Código implementa · Tela opera.**

## Itens em aberto

- Licenciamento/termos de cessão das contribuições da comunidade.
- Limiar e fórmula do `quality_score`.
- Relação entre `public_version` e edições do catálogo.
- Política de custo de armazenamento/indexação do conteúdo público.
- Modelagem física da camada de staging e das views públicas (FASE 7).

Lista consolidada em [../../governanca/pendencias.md](../../governanca/pendencias.md). Planejamento em [../../governanca/roadmap.md](../../governanca/roadmap.md).
