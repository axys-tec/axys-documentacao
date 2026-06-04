# Catálogo — Regras de Negócio (Contrato Canônico)

**Status:** Contrato Canônico (v0.1)
**Data:** 2026-06-02
**Escopo:** schema `catalogo` (insumos, preços, composições, custos, situações, tipos).
**Princípio de governança:** Contrato governa · Schema suporta · Código implementa · Tela opera.

> Nenhuma regra de negócio relevante pode existir apenas em parser, schema, controller, service ou tela. Este documento é a fonte canônica. Código e SQL referenciam-no no topo.

Contratos irmãos:
[CATALOGO_SINAPI_IMPORT_CONTRACT.md](CATALOGO_SINAPI_IMPORT_CONTRACT.md) ·
[CATALOGO_CDHU_IMPORT_CONTRACT.md](CATALOGO_CDHU_IMPORT_CONTRACT.md) ·
[CATALOGO_FONTES.md](CATALOGO_FONTES.md) ·
[CATALOGO_EDICOES.md](CATALOGO_EDICOES.md)

---

## 1. Conceitos fundamentais

| Conceito | Definição canônica |
|---|---|
| **Insumo** | Identidade do que o insumo É (código, descrição, unidade, tipo), sem preço. Mutável — "identidade vigente", upsert por reimport. |
| **Preço** | Valor do **insumo** por UF/edição/modalidade. Insumo tem PREÇO (não custo). |
| **Composição (CPU)** | Conjunto de itens (insumos e/ou subcomposições) com coeficientes, p/ 1 unidade de serviço. Composição tem CUSTO. Versionada por edição (imutável). |
| **Item de composição** | Linha filha: tipo `INSUMO` ou `COMPOSICAO` (subcomposição/auxiliar). |
| **Composição auxiliar** | Composição empregada como item de outra (ex.: argamassa). |
| **Edição** | Recorte temporal/versão da fonte. Preços, composições e custos são **imutáveis por edição**; insumos são identidade vigente. |
| **Situação** | Estado declarado pela fonte (auditoria), via lookup `catalogo.situacoes`. Domínios: `INSUMO`, `COMPOSICAO`. |

---

## 2. Classificação de insumos

- **Todo insumo é classificado** — `catalogo.insumos.ins_ti_id` é **NOT NULL**.
- Tipos (`catalogo.insumos_tipo`): `MO`, `ENC_COMP`, `EQUIP_AQ`, `EQUIP_LOC`, `MAT`, `SERV`, `ESP`, `NC`.
  - **`ENC_COMP`** = encargos complementares (EPI, ferramentas, transporte, alimentação, exames, seguro, curso…). É labor-add-on, **mas NÃO recebe leis sociais** no cálculo (só o salário-base `MO` recebe — ver §3.2). Distinto de `MO` justamente por isso.
- Fonte da classificação por origem (`ins_ti_origem`):
  - **`FONTE`** — classificação nativa confiável da fonte-base (ex.: classificação SINAPI);
  - **`REGRA`** — inferida pela app: léxico (CDHU) ou fuzzy (órfão SINAPI);
  - **`MANUAL`** — curadoria humana (tela), nunca por parser.
- **Import bloqueia classificação sem tipo cadastrado:** se a fonte trouxer uma classificação que não mapeia para nenhum `ti_codigo`, o import **aborta** (nada gravado) e devolve ao usuário para cadastrar o tipo antes. **Não inventa `NC`** para classificação-de-fonte desconhecida (`NC` é só para órfão sem classificação após fuzzy).

### 2.1 `NC` — Não Classificado (fallback controlado)
- `NC` **não é categoria técnica real** da fonte. É fallback técnico de curadoria.
- Existe para permitir **import completo sem abortar** quando regra/fuzzy não atinge confiança mínima, preservando `ins_ti_id NOT NULL`.
- Insumo `NC` **entra em fila de curadoria** e **não deve alimentar histogramas gerenciais** como tipo técnico normal.

### 2.2 Precedência no reimport — **FONTE > MANUAL > REGRA**
Regra operacional ao reencontrar um insumo:
1. Se a fonte trouxer classificação nativa confiável → prevalece e grava `ins_ti_id` + `ins_ti_origem='FONTE'`, **mesmo que antes estivesse `MANUAL`**.
2. Se a fonte **não** classificar:
   - registro `MANUAL` → **mantém** a classificação manual (regra não sobrescreve);
   - registro `REGRA` ou `NC` → **reaplica** regra/fuzzy (descrição/unidade podem ter mudado);
   - fuzzy sem confiança → mantém ou aplica `NC`.

`MANUAL` **não é absoluto** — só prevalece quando não há classificação de fonte. A prevalência é **garantida pelo parser** (no `ON CONFLICT`), não pelo banco. Campos cadastrais (descrição/unidade) são **sempre** atualizados no reimport.

---

## 3. Preço (insumo)

- `pri_valor` recebe o valor publicado **exatamente, inclusive `0`**. Zero **nunca** é inferido como "sem preço".
- Se a fonte **não** publicou preço para a UF → `pri_valor = NULL`; o **motivo** fica na situação (FK), nunca solto.
- **Toda UF da edição tem linha** para cada insumo (SINAPI = 27 UFs; CDHU = UF SP). **Ausência de linha = falha de processamento / não importado — NUNCA "sem preço".**
- Situação do preço (`pri_sit_id` → `situacoes` domínio `INSUMO`): `COM_PRECO` | `SEM_PRECO`.
- Coerência **valor × situação** é contrato do parser — **não há trigger**.

### 3.1 Armazenamento "pelado + LS" — `insumos_preco` é **SE-only**
Encargos sociais incidem **só sobre mão de obra**, e o preço "com encargos" publicado pelas fontes **É** `pelado × (1 + LS%)` truncado. Logo, **não se armazena SD/CD** como preço de insumo — armazena-se só o **pelado (SE)** e derivam-se SD/CD no cálculo.

- `insumos_preco` grava **apenas modalidade `SE`** para **todo** insumo (MO e não-MO), por UF/edição. (`pri_modalidade` é mantida = `'SE'`; SD/CD permanecem como modalidades **válidas no cadastro/lookup** para visualização e processamento dinâmico, mas **não** como linhas de preço de insumo.)
- **Não-MO**: não tem encargo → SE = SD = CD; 1 linha (SE).
- **MO**: grava o pelado (SE); SD/CD são **derivados** (§3.2).
- Fonte que não distingue modalidade no insumo (ex.: **CDHU**) → também SE.

### 3.2 Derivação SD/CD e arredondamento (ESPECÍFICO DA FONTE)
Para insumo de **mão de obra**: `preco = ARRED( pelado × (1 + LS%/100), 2 )`, com `LS%` de `edicoes_leis_sociais` por **(edição, UF, modalidade)** e pela **unidade** do insumo (`H` → horista; `MES` → mensalista). O método de arredondamento `ARRED` é **o da fonte** — escolhido para casar **ao centavo** com o publicado:

- **SINAPI — preço de insumo SD/CD: `trunc(2)`.** Prova (SP 08/2024): 6114 SE=10,45 → SD `trunc(10,45×2,1554)=22,52`, CD `19,41`; 40912 SE=2.300,88 → SD `trunc(2300,88×1,7146)=3.945,08` (round daria 3.945,09 → seria errado).
- **CDHU — custo de composição: `round half-up (2)` em DUAS passagens** (decisão 2026-06-03):
  `unit_mo = round( (1 + LS%/100) × pelado, 2 )` e `custo_cpu = Σ round( unit × coef, 2 )`.
  Converge **100% ao centavo** com a fonte (CDHU 201: 3560/3560). Truncar dava viés sistemático negativo (até −R$12,91 em CPUs grandes); a CDHU arredonda.
- **SINAPI — custo de composição: `trunc(2)`** em todas as etapas (unit MO carregado, por linha, soma). Validado: **445.074 células IGUAL ao centavo, ZERO divergência** (10378 composições × 27 UF × SD/CD). Consistente com o preço de insumo SD que também trunca.

**A LS (encargos sociais) incide SÓ no salário-base (`ti=MO`).** `ENC_COMP` (encargos complementares), `MAT`, `EQUIP_*`, `SERV`, `ESP` entram a **valor de face** (sem LS). Prova SINAPI: SERVENTE COM ENCARGOS (88316, SP/SD) = base 6111 `trunc(9,95×2,1501)=21,39` + complementares (face 9,20) + curso (0,45) = **31,04 = fonte**.

**%AS** (montagem por UF): insumo sem preço na UF → preço atribuído via **coeficiente de família** `trunc(preço_SP × coef_UF/coef_SP, 2)` (SP plano se não houver coef); SP nulo → SEM CUSTO. Detalhe e prova em **§5**. Validado nas 27 UFs.

> O método é **declarado por fonte** (CDHU=round · SINAPI=trunc). Política conservadora de orçamento (se houver) é da camada **ativo** (§3.4), não do catálogo.

### 3.3 Leis sociais (`edicoes_leis_sociais`)
- LS por **(edição, UF, modalidade ∈ {SD, CD})** — **não** se grava `SE` (SE = 0% implícito). Guarda `els_mensalista` e `els_horista` como percentual (`14,2`), dividido por 100 no cálculo.
- **Fonte das LS:** SINAPI = cabeçalhos dos arquivos SD e CD (LS por UF, horista/mensalista); CDHU = cabeçalho **de cada arquivo de serviços (SD e CD — ambos importados por edição)**, um % horista por regime (mensalista NULL).
- **Sanidade no import:** LS real é alta (>100% típico); valor que chegue como fração (~1,28) deve ser normalizado/abortado.

### 3.4 Fronteira catálogo × orçamento
- No **catálogo**, LS é a **oficial da edição** (imutável); `composicoes_custo.cc_custo_calculado` é computado 1× no import.
- No **orçamento** (módulo ativo), o usuário pode usar LS customizada / base mensalista → computado **ao vivo** sobre o SE. Nada a "reprocessar" no catálogo; cache de orçamento invalida ao mudar LS.
- **Horista ↔ mensalista** não é linear (a CPU mensalista tem itens diferentes, não é `horista × 220`) → resolve-se por **mapeamento de CPUs** (`composicoes_mapeamento_mdo`, por edição), consumido no orçamento.

---

## 4. Composição e custo

- **Custo da composição é montado pela app** a partir dos preços de insumo na UF/modalidade — não é "lido cru" da fonte como verdade de cálculo (a fonte é referência/conferência).
- **SEM CUSTO** ⟺ a composição contém **algum insumo SEM PREÇO** ou **alguma subcomposição SEM CUSTO**. A indisponibilidade **propaga pela árvore**.
- **Aferição** (`AF_MM/AAAA`) é atividade técnica (dimensionar coeficientes) **ortogonal** a ter custo. Composição pode ser aferida e sem custo.
- Situação da composição (domínio `COMPOSICAO`): `COM_CUSTO` | `SEM_CUSTO` | `SUSPENSO` | `EM_ESTUDO`.
- Custo de referência da fonte é guardado lado a lado com o calculado (`composicoes_custo.cc_custo_fonte` × `cc_custo_calculado`) — divergência é **conferência/alerta**, nunca mascarada e **sem trigger**.
- **Fidelidade canônica dos itens:** a composição é gravada **exatamente como a fonte apresenta** — os mesmos N itens (código, descrição, unidade, coeficiente, ordem; colunas `ci_*_fonte_original`). A fonte pode publicar **coeficiente 0** (item presente, quantidade não atribuída / CPU incompleta) — **não cabe à app julgar, só repetir**: `CHECK ci_coef >= 0` (negativo é barrado = lixo). Insumo SEM PREÇO com coef 0 **ainda propaga SEM CUSTO** (basta a presença na árvore, não o coeficiente). Descartar coef-0 mutilava a árvore e gerava custo falso (ex.: CPU 104871 — materiais de protensão sem preço, custo real = sem custo).

### 4.1 Motor de conferência (calculado × fonte)
- **Modalidades:** `SD` e `CD` (com leis sociais) **e `SE`** (PELADO, sem LS). SINAPI: fonte de cada uma nas abas **CSD/CCD/CSE**; CDHU: **SD e CD** (dois arquivos de serviço; sem pelado publicado). `composicoes_custo` guarda as três para **consulta direta** (telas não recomputam o pelado). O `SE` valida a doutrina SE-only no nível de composição (Σ pelado×coef = CSE).
- Logo após o import, para cada (composição, UF, modalidade) calcula-se `cc_custo_calculado` (montagem §3.2/§3.4 com a LS **oficial** da edição) e compara-se com `cc_custo_fonte` (publicado).
- **Limiar:** `|diferença|` ≤ **0,5%** (ou ≤ R$0,01) → `cc_status_conferencia = DIVERGENTE_ARREDONDAMENTO`; acima → `DIVERGENTE_RELEVANTE`. **Validado (2026-06-03): AMBOS convergem 100% ao centavo** com o método da fonte — CDHU 3560/3560 (round) e SINAPI 445.074 células (trunc), ZERO divergência relevante.

### 4.2 Custo × alerta — `composicoes_custo` é a casa única dos números
- Os **números** (`cc_custo_fonte`, `cc_custo_calculado`, diferença, `cc_status_conferencia`, `cc_pct_sp`) vivem **só** em `composicoes_custo` (1 linha por cmp/uf/modalidade). É o "headline" do alerta.
- `composicoes_custo_alerta` guarda **apenas a CAUSA** (tipo do alerta + referência do item culpado + observação), **sem repetir custo**, e **só para casos relevantes** (divergência relevante / sem custo). A causa item-a-item é derivável; persiste-se o que merece fila de revisão.

---

## 5. %AS (Atribuído São Paulo)

`%AS` é **artefato da composição**, não origem de preço de insumo (origens seguem só `C`/`CR`). Na montagem por UF, quando o insumo **não tem preço `SE` na UF**:

1. **Representado (`CR`) com coeficiente de família** → preço atribuído = `trunc( preço_SP × (coef_UF / coef_SP), 2 )` (≡ `representativo_SP × coef_UF`). O coeficiente é **por UF** (tabela `catalogo.insumos_familia`, do arquivo `SINAPI_familias_e_coeficientes`). MAT/EQUIP/SERV têm coef **igual entre UFs** (ratio 1 → SP plano); o efeito real recai sobre **MO**. O atribuído **é preço** → vive a **2 casas, truncado** (doutrina TRUNC da fonte).
2. **Sem coeficiente de família** → adota o preço de **SP** plano.
3. Se SP também é `NULL` → item sem preço → composição **SEM CUSTO** (propaga na árvore).
4. **%AS do item** = 100% quando substituído; **%AS da CPU** = Σ(valor dos itens AS) / total. Persistido em `composicoes_custo.cc_pct_sp`.

> **Por que coef, não SP plano (correção 2026-06-04):** a fonte deriva o preço do representado por UF via `representativo × coef_UF`; usar SP plano ignora o coeficiente da UF-alvo e **subconta** sistematicamente (−1% a −4% em MO de UFs com buraco). Provado: motorista em MA ≈ R$2.400 (= 12,62 × 190,25) bate a CPU **ao centavo**; SP plano (2.312,67) dava −3,7%. A premissa antiga "%AS = SP plano" estava errada.
> **Truncar o atribuído a 2 casas** elimina falsos de arredondamento (08/2024, MT: 160 → 2). O resíduo (~2 células de 1 centavo em 560k) é **irredutível** — reconstrução a partir de preço publicado já arredondado; conferência segue **0 divergência relevante**.

---

## 6. Situação como lookup

- `catalogo.situacoes` — lookup por **domínio** (`INSUMO`, `COMPOSICAO`); situações são **FK**, não texto repetido.
- Não há domínio `PRECO` (situação de preço É do insumo) nem `ITEM` (item é só insumo ou composição dentro de composição).
- A situação guardada é a **declarada pela fonte** (auditoria). A **situação efetiva** (para cálculo) é **derivada em runtime** pela app — não persistida, não confiada cegamente.
- Integridade de domínio garantida por **FK composta** `(sit_id, dominio)` — sem trigger.

### 6.1 Procedência da situação — DECLARADA (fonte) × DERIVADA (nós), por fonte
O que vem da fonte e o que é nosso depende do que cada fonte publica:

| Campo | CDHU | SINAPI |
|---|---|---|
| **Situação do PREÇO** por UF (`insumos_preco.pri_sit_id` COM/SEM_PRECO) | **Derivada por nós** (presença do custo). CDHU **só publica COM PREÇO** — não tem coluna de situação; todo insumo tem preço. | **Derivada por nós** por UF (a aba ISE não rotula cada UF; presença da célula → COM/SEM_PRECO). |
| **Situação do ITEM/COMPOSIÇÃO** (com/sem custo, com/sem preço) | **Computada por nós** — CDHU **não declara**; vem do cálculo (`calcular_custos` grava a efetiva em `cmp_situacao`). | **Declarada pela fonte** — a coluna **"Situação"** do Analítico publica COM PREÇO/SEM PREÇO/COM CUSTO/SEM CUSTO/EM ESTUDO; gravamos **verbatim** em `ci_situacao`/`cmp_situacao`. |
| **Custo de referência** (`cc_custo_fonte`, `cc_pct_sp`) | Da fonte (serviços). | Da fonte (CSD/CCD). |
| **Custo calculado + status de conferência** (`cc_custo_calculado`, `cc_status_conferencia`) | **Nosso** (cálculo/conferência). | **Nosso**. |

> Consequência: o campo `cmp_situacao` hoje carrega naturezas diferentes — **declarada** (SINAPI, do Analítico) e **computada** (CDHU, do cálculo). Funciona, mas mistura. A separação limpa (situação **declarada** por FK `ci_sit_id`/`cmp_sit_id` + situação **efetiva** derivada em runtime) está **DEFERIDA** (ver nota de estado abaixo) e deve ser endereçada na frente de tela/uso.

> **Estado de implementação (schema atual, 2026-06-03):** apenas **`insumos_preco.pri_sit_id`** (domínio `INSUMO`) está implementado. As situações **declaradas do lado composição** (`composicoes_itens.ci_sit_id` e `composicoes.cmp_sit_id`) estão **conceitualmente previstas, porém DEFERIDAS** — a natureza do item (INSUMO vs COMPOSICAO) e a forma de guardar a situação declarada serão decididas **antes do parser de composição**. Hoje `composicoes`/`composicoes_itens` ainda usam o campo de situação textual herdado, a ser refatorado nessa frente.

---

## 7. Política de reimport

- **Insumos**: upsert (identidade vigente). Classificação segue a precedência da §2.2; cadastrais sempre atualizam.
- **Preços / composições / itens / custos**: **imutáveis por edição** — reimport da mesma (chave, edição) é idempotente.
- Situação declarada pela fonte é regravada; situação efetiva é recomputada.

---

## 8. Fronteira Banco × App

| Banco garante | App/importador garante |
|---|---|
| FK válida; domínio válido da situação (FK composta) | Coerência valor × situação |
| `ins_ti_id NOT NULL` | Aplicação da regra de fonte e do fuzzy |
| Unicidade e integridade relacional | Precedência FONTE > MANUAL > REGRA |
| Domínio de `ins_ti_origem`, modalidade, origem | 27 UFs preenchidas por insumo/edição |
| — | Custo e situação **efetiva** das composições |

**Sem triggers.** Regra de coerência é responsabilidade do parser/importador.

---

## 9. Época / Diff (evolução entre edições)

- **No import**, após parsear e **antes de gravar**: "este registro já existe?" → se **sim**, computa **diff** e grava em `*_historico`; se **não**, grava `CRIACAO` e pula auditoria.
- **Preço nunca vai para histórico** — a série temporal vive em `insumos_preco` por edição; composições são versionadas por edição (`cmp_edi_id`).

**9.1 Diff é contra o ESTADO VIGENTE DO BANCO (não contra a edição anterior).**
- Para **cada item** (insumo ou composição) da edição entrando, compara-se contra o **estado vigente** do banco **filtrando pela fonte** — a linha ativa mais recente daquele código em **qualquer** edição anterior. **Não** contra a edição N-1.
- Por quê: um item nascido há N edições pode ser ajustado hoje; um item inativado que **pulou versões** pode voltar (`REATIVACAO`). Comparar só com a N-1 perde os dois casos e exige import estritamente sequencial. Contra o banco vigente, o diff é correto mesmo com import esparso/fora de ordem.
- Eventos: `CRIACAO` (código nunca existiu na fonte) · `ALTERACAO_*` (mudou vs a vigente) · `INATIVACAO` (estava ativo, ausente nesta edição) · `REATIVACAO` (estava inativo, reapareceu). Vigente/ativo = versão mais recente.

**9.2 O que conta como ALTERAÇÃO ("alteração verdadeira").**
- **Só** os campos de **conteúdo**: **descrição (texto)**, **unidade**, e **coeficiente/itens** (inclusão, exclusão, mudança de coef).
- **`null` ≠ alteração:** `null`/ausente → valor **não** é alteração — é **dado que faltava naquela época** da fonte (ex.: a coluna `Situação` do Analítico SINAPI, inexistente em 08/2024 e publicada em 04/2026). Tratar `null→valor` como mudança gera falso positivo em massa (na virada 08-24→04-26 seriam ~9,3k composições "alteradas"; reais = ~3,3k).
- **Situação NÃO é gatilho de alteração** — em direção alguma (`null↔valor` nem `valor→outro`). É **metadado de presença**, gravado por época em `cmp_situacao`/`ci_situacao` para consulta, mas não emite evento. (Se a situação mudar por causa real — insumo sem preço entrando na árvore — o gatilho real é a mudança de **itens**, que já registra.) Implementação: helper `_alteracao(de, para)` em `parser_cdhu.py`, **não** chamado para situação.
- **Risco-espelho coberto:** como situação nunca é gatilho, uma futura edição que **deixe** de publicar a coluna (`valor→null` em massa) também **não** gera ruído.

**9.3 Snapshot por época (consulta ponto-no-tempo).**
- Cada import grava o **snapshot completo** da edição: 1 linha por composição com `cmp_edi_id` daquela edição. "Quantas composições ativas na época X" = `COUNT(*) WHERE cmp_fte_id=F AND cmp_edi_id=<época>` — **1× por CPU** (identidade), não multiplicado.
- **Não usar `cmp_ativa` para ponto-no-tempo:** `cmp_ativa=TRUE` marca só a versão **vigente (hoje)**; para a época X filtre por `cmp_edi_id`.
- Só é consultável para épocas **efetivamente importadas** (imports esparsos não reconstroem o miolo).
- **Cardinalidade:** custo multiplica, identidade não. `composicoes` = 1×/CPU; `composicoes_custo` = CPU × 27 UF × **2 modalidades (SD, CD)**. **SE não existe para composição** (é nível de insumo, pelado); são **2** modalidades de custo, não 3.

**9.4 Reconciliação e sequenciamento.**
- **Dois diffs no SINAPI:** **SINAPI-Diff** (`catalogo.sinapi_manutencoes`, changelog publicado) e **Axys-DIFF** (série histórica computada pela Axys, agora contra o banco vigente). A app apresenta ambos e **reconcilia** ("a manutenção cobre tudo que o Axys-DIFF achou?"). CDHU não publica changelog → só Axys-DIFF.
- **Reimport sem rebuild ainda não é idempotente** quanto ao *supersede* (a linha superada por uma edição segue inativa → no reimport apareceria como `REATIVACAO`). Para reimportar a **mesma** edição, `rebuild` antes. Imports novos / fora de ordem estão corretos.
- **Sequenciamento:** o diff é estágio **posterior** ao import "puro" funcionar (ver `PLANO_IMPORT_CATALOGO.md`, Fases 2.2 e 3.4).

---

## 10. Ciclo de vida da fonte/edição (upload em fases · liberação · lock)

Catálogo de preço só fica **disponível ao tenant** quando **completo e validado**; depois **congela**.

**10.1 Flags.**
- **Fonte:** `fte_tem_catalogo_insumos` (bool, default `false`) — o usuário declara no cadastro se a fonte publica catálogo/relatório de insumos (na prática hoje só a SINAPI tem fichas; CDHU não).
- **Fonte:** `fte_catalogos_continuos` (bool, default `false`) — os documentos (fichas/cadernos/critérios) **podem não mudar por edição**? `true` = contínuos (SINAPI: trazem data de atualização → publica com **skip por data**, §11.3); `false` = reemitidos/mudam por edição (CDHU: **sobe tudo por edição**, §11.2). Default `false` é conservador (re-sobe sempre) — fonte que o usuário sobe declara isso.
- **Edição:** ciclo de vida em enum `edi_situacao_ciclo` ∈ {`RASCUNHO`, `PUBLICADA`} (+ gates abaixo). `RASCUNHO` é o default.
  - `edi_ins_catalogo_ok` (bool): se `fte_tem_catalogo_insumos` → exige upload das fichas de insumo; **senão o back seta `true` automático** (não há o que subir).
  - `edi_comp_catalogo_ok` (bool): exige upload dos **cadernos/critérios** (composições) — **obrigatório para toda fonte**.

**10.2 Fases do upload da edição.**
1. **3.1 — import "grande"** (insumos/preços/composições/custos/conferência/diff) — o pipeline já validado.
2. **3.2 — fichas de insumo → R2** — **opcional**, só para fonte com `fte_tem_catalogo_insumos=true`.
3. **3.3 — cadernos de encargos / critério de medição e remuneração → R2** — **obrigatório**.

**10.3 Publicar e travar.**
- `RASCUNHO` → itens da edição **indisponíveis** a **qualquer** tenant.
- Botão **Publicar** (front) → o back valida: import grande feito **+** `edi_ins_catalogo_ok` **+** `edi_comp_catalogo_ok`. Passando → `PUBLICADA`: itens **disponíveis** e edição **travada (imutável)**.
- **Lock é de camada app/parser** (rejeita mutação em edição `PUBLICADA`), **sem trigger** — casa com "imutável por edição" (§7). Manutenção pós-lock só por **usuário de acesso máximo**, em tela específica.

**10.4 Impacto.** Colunas/flags são **aditivas** (default conservador) — **não** alteram o import, os parses nem os uploads ao R2 já validados. É governança de camada app, plugada na refatoração de fontes/edições e nas telas de import.

---

## 11. Publicação do catálogo de DOCUMENTOS no R2 (fichas/critérios/cadernos)

Camada **documental** (especificação de insumo, critério de medição, caderno técnico) — distinta do preço.

**11.1 Conteúdo puro + identidade.**
- O HTML no R2 é **conteúdo puro** (semântico, editável): a ficha/critério **sem** o chrome da app. O **header** (tarja, logo, tenant) é montado **no render da app**, não gravado no R2.
- Todo HTML carrega o **favicon** oficial (`appicon_logo.png`) via URL pública do R2.
- O documento vive na **IDENTIDADE**: insumo → `insumos.ins_external_path`; composição → `composicoes.cmp_external_path` (JSONB). A **edição** apenas **exige a existência** do doc (gate §10), não é dona do arquivo.

**11.2 Fonte `fte_catalogos_continuos=false` (ex.: CDHU) — sobe tudo a cada edição.** A CDHU reemite o catálogo de critérios a cada edição (repete textos, sem controle de mudança). Como é leve (texto), **sobe tudo por edição**:
- Arquivo nomeado com a edição: `criterios/cdhu/<edi>/<cmp_codigo>.html` (≡ `{codigo}_{edicao}`).
- `cmp_external_path` mantém o **path mais atual** + um **histórico** dos paths anteriores (auditoria; redundante com o nome `{codigo}_{edicao}`, mas guardado).

**11.3 Fonte `fte_catalogos_continuos=true` (ex.: SINAPI) — skip por data de atualização.** Fichas (`Atualizado em:`) e cadernos (`Atualização`) trazem a data da última revisão. Regra **idempotente**: se a data do doc **≤** a edição **E** o item **já existe no R2** → **não sobe (skip)**. Evita re-subir docs idênticos a cada boletim (o conteúdo é contínuo na identidade).

**11.4 Estado (2026-06-04).**
- **CDHU critérios:** parser OK (font-style), publicado 184+201. ⚠️ Pendente: rodapé `Página X de Y` vazou no 184 (filtrar) + favicon.
- **SINAPI fichas:** parser OK (tabela+bordas+imagem, 7 campos fixos), publicando 6010. ⚠️ Pendente: favicon + regra skip-por-data.
- **SINAPI cadernos (por subgrupo → por CPU, com diagramas):** **a fazer**.
