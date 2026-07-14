# Catálogo — Regras de Negócio (Contrato Canônico)

**Status:** Contrato Canônico (v0.2)
**Data:** 2026-06-02 · **Revisto:** 2026-07-13
**Escopo:** schema `catalogo` (insumos, preços, composições, custos, situações, tipos).
**Princípio de governança:** Contrato governa · Schema suporta · Código implementa · Tela opera.

> **Changelog** — v0.2 (2026-07-13): **repense doc/path** (§11.9/§11.10/§11.11). A identidade (`external_path`) volta a ser a **fonte única** de ficha/caderno_cpu/CTC e passa a guardar a **vigência por versão**; `catalogo.documentos` encolhe p/ docs de edição/fonte sem dono 1:1; `composicao_documento` dropada; `cmp_descritivo` perde o prompt (fica só no storage). Reverte o rumo de v0.1 (documentos unificado / external_path deprecado).

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

**SE é SEMPRE gravado em `composicoes_custo` (custo nunca zera).** ⚠️ ATUALIZADO 2026-06. `SE` (Sem Encargos = pelado, LS=0) **não é** o regime de orçamento — é a **base de de/recomposição** com qualquer LS. Como o pelado está 100% em `insumos_preco`, o custo SE é sempre calculável: `calcular_custos` **sempre emite SE** (LS=0 → MO sem carga); **SD/CD** entram quando há LS (arquivo de serviço **ou** LS manual). Assim uma edição só-SD ainda tem custo (ex.: CDHU 201 = SD conferido + **SE DERIVADO**); SINAPI emite SD/CD/SE por UF (CSD/CCD/**CSE**, todos com fonte → conferidos). **A leitura na app EXIBE `cc_custo_calculado`** (o valor processado pela app): `COALESCE(cc_custo_calculado, cc_custo_fonte)` (calculado; fonte só como fallback). ⚠️ ATUALIZADO 2026-07 (INVERSÃO): antes exibia o fonte — passou a exibir o **processado pela app** (converge melhor sob rotação de preço; uniformiza fontes com/sem BDI publicado). Semântica completa em **§4.3**.

### 3.3 Leis sociais (`edicoes_leis_sociais`)
- LS por **(edição, UF, modalidade ∈ {SD, CD})** — **não** se grava `SE` (SE = 0% implícito). Guarda `els_mensalista` e `els_horista` como percentual (`14,2`), dividido por 100 no cálculo.
- **Fonte das LS:** SINAPI = cabeçalhos dos arquivos SD e CD (LS por UF, horista/mensalista); CDHU = cabeçalho **de cada arquivo de serviços (SD e CD — ambos importados por edição)**, um % horista por regime (mensalista NULL).
- **Sanidade no import:** LS real é alta (>100% típico); valor que chegue como fração (~1,28) deve ser normalizado/abortado.

### 3.4 Fronteira catálogo × orçamento
- No **catálogo**, LS é a **oficial da edição** (imutável); `composicoes_custo.cc_custo_calculado` é computado 1× no import.
- No **orçamento** (módulo ativo), o usuário pode usar LS customizada / base mensalista → computado **ao vivo** sobre o SE. Nada a "reprocessar" no catálogo; cache de orçamento invalida ao mudar LS.
- **Horista ↔ mensalista** não é linear (a CPU mensalista tem itens diferentes, não é `horista × 220`) → resolve-se por **mapeamento de CPUs** (`composicoes_mapeamento_mdo`, por edição), consumido no orçamento.

### 3.5 Preço por COTAÇÃO de mercado (`pri_origem='CT'` + `insumos_cotacoes`) *(decisão Renan 2026-06-07)*
- Para insumos **próprios** (AXYS) ou **sem preço de fonte**, o preço vem de **cotação de mercado** (fornecedores). `pri_origem` ganha **`'CT'`** (além de `C`=coletado, `CR`=coef. representativo).
- **Lastro/detalhe em `catalogo.insumos_cotacoes`** (mínima): `ic_ins_id`, `ic_edi_id`, `ic_uf` (preço de insumo é **SE-only** §3.1 → sem modalidade), `ic_preco_mediano`, `ic_certidao_path` (JSONB — certidão de pesquisa de preço, 1 por cotação), `ic_cotacoes` (JSONB **array** de fornecedores: `{fornecedor:{nome,razao_social,cnpj,nome_fantasia,telefone,contato}, data_cotacao, ambiente(online|link|presencial), valor, proposta_path}`).
- **Fluxo:** junta cotações → **mediana** (robusta a outlier) → grava em **`insumos_preco`** (`pri_valor = ic_preco_mediano`, `pri_origem='CT'`, modalidade `SE`, na UF). **A verdade do preço continua sendo `insumos_preco`** (§3.4); `insumos_cotacoes` é o **detalhe/auditoria** que justifica aquele CT. `ic_preco_mediano` é derivado (recalcula quando o array muda).
- **Docs (proposta por fornecedor; certidão)** = justificativa do **usuário** → **R2 privado** (NÃO o registro público de documentos da fonte, §11.9).
- **Fornecedor**: hoje **snapshot no JSONB** (mínimo, fiel ao momento da cotação). Se o reuso de fornecedor doer (mesmo CNPJ recorrente), extrair `catalogo.fornecedores` (CNPJ = PK natural, padrão `unidades`) — **futuro**, não agora.
- **Estado:** tabela criada (schema + dev) + `'CT'` no CHECK. **Wiring** (mediana→`insumos_preco`, UI de cotação, upload dos docs) entra com a tela de insumos próprios (AXYS) — gate `fte_permite_manipular_dados` (§8.1).

---

## 4. Composição e custo

- **Custo da composição é montado pela app** a partir dos preços de insumo na UF/modalidade — não é "lido cru" da fonte como verdade de cálculo (a fonte é referência/conferência).
- **SEM CUSTO** ⟺ a composição contém **algum insumo SEM PREÇO** ou **alguma subcomposição SEM CUSTO**. A indisponibilidade **propaga pela árvore**.
- **Aferição** (`AF_MM/AAAA`) é atividade técnica (dimensionar coeficientes) **ortogonal** a ter custo. Composição pode ser aferida e sem custo.
- Situação da composição (domínio `COMPOSICAO`): `COM_CUSTO` | `SEM_CUSTO` | `SUSPENSO` | `EM_ESTUDO`.
- Custo de referência da fonte é guardado lado a lado com o calculado (`composicoes_custo.cc_custo_fonte` × `cc_custo_calculado`) — divergência é **conferência/alerta**, nunca mascarada e **sem trigger**. Semântica de exibição/auditoria e o caso de fonte com BDI publicado (FDE): **§4.3**.
- **Fidelidade canônica dos itens:** a composição é gravada **exatamente como a fonte apresenta** — os mesmos N itens (código, descrição, unidade, coeficiente, ordem; colunas `ci_*_fonte_original`). A fonte pode publicar **coeficiente 0** (item presente, quantidade não atribuída / CPU incompleta) — **não cabe à app julgar, só repetir**: `CHECK ci_coef >= 0` (negativo é barrado = lixo). Insumo SEM PREÇO com coef 0 **ainda propaga SEM CUSTO** (basta a presença na árvore, não o coeficiente). Descartar coef-0 mutilava a árvore e gerava custo falso (ex.: CPU 104871 — materiais de protensão sem preço, custo real = sem custo).

### 4.1 Motor de conferência (calculado × fonte)
- **Modalidades:** `SD` e `CD` (com leis sociais) **e `SE`** (PELADO, sem LS). SINAPI: fonte de cada uma nas abas **CSD/CCD/CSE**; CDHU: **SD** (e CD quando publicado) + **SE derivado**; FDE: **SD** (com BDI publicado) + **SE derivado** (não emite CD). `composicoes_custo` guarda as três para **consulta direta** (telas não recomputam o pelado). O `SE` valida a doutrina SE-only no nível de composição (Σ pelado×coef = CSE).
- **INVARIANTE CANÔNICO (todas as fontes): TODA EDIÇÃO TEM `SE` em `composicoes_custo` — publicado (SINAPI: aba CSE, conferido) ou `DERIVADO` (CDHU, FDE e qualquer fonte só-SD/CD).** O `SE` é a **base pelada obrigatória** (LS=0): é o que permite o orçamento **rotacionar a LS** (aplicar o regime/percentual da obra sobre o custo sem encargos — §3.2). Como o pelado está 100% em `insumos_preco` (SE-only, §3.1), `calcular_custos` **sempre emite `SE`** (LS=0 → MO sem carga) mesmo quando a fonte não publica pelado. **Nunca existe edição sem `SE`.** (2026-07-04.)
- Logo após o import, para cada (composição, UF, modalidade) calcula-se `cc_custo_calculado` (montagem §3.2/§3.4 com a LS **oficial** da edição) e compara-se com `cc_custo_fonte` (publicado). **Se a edição tem BDI publicado (`edicoes_bdi`), compara-se contra `cc_custo_fonte ÷ (1 + ebd_percent/100)`** (fonte des-BDInizado — ver §4.3); senão, contra o fonte cru.
- **Limiar:** `|diferença|` ≤ **0,5%** (ou ≤ R$0,01) → `cc_status_conferencia = DIVERGENTE_ARREDONDAMENTO`; acima → `DIVERGENTE_RELEVANTE`. **Validado (2026-06-03): AMBOS convergem 100% ao centavo** com o método da fonte — CDHU 3560/3560 (round) e SINAPI 445.074 células (trunc), ZERO divergência relevante.

### 4.1-bis Validação em DUAS camadas (interna + externa independente)
A conferência de §4.1 é **interna** (compara `cc_custo_fonte` × `cc_custo_calculado`, ambos vindos do MESMO parse). Ela não pega um bug de **parse do próprio Excel** (se o fonte foi lido errado, bate errado com errado). Por isso a carga é validada também por **fora**:
- **Externa/independente — `z_scripts_apoio/valida_amostra.py`:** relê o Excel-fonte com openpyxl **próprio** (não o parser do app) e compara com o banco: insumo `ISE → insumos_preco` (SE); composição `CSD/CCD/CSE → cc_custo_fonte` (SD/CD/SE), casando por ORDEM do Analítico (o código na aba de custo é 0). Tolerância ±R$0,01. Amostral (rápido) ou exaustivo (`N_*=999999`, `N_UF=27`). **SINAPI 2026-07-13: 22 edições × 27 UF × SD/CD/SE = ~7,9 mi comparações, ZERO divergência** + alinhamento Analítico↔CSD exato → transcrição certificada. (CDHU: variante a construir — layout de Excel diferente.)
- **Trava do e2e (`e2e_sinapi.py`/`e2e_cdhu.py`):** o e2e reprova (rc=1) se qualquer estágio ficar em `erro` **ou** se o caderno vier com `n_itens < MIN_ITENS` (mata o falso-verde de edição vazia). Só imprime `✅ E2E APROVADO` com dado real.
- **Doutrina:** toda carga nova (qualquer fonte) deve passar pela validação independente antes de avançar; como dev e prod rodam a MESMA pipeline sobre o MESMO Excel, passar em dev certifica o prod.

### 4.2 Custo × alerta — `composicoes_custo` é a casa única dos números
- Os **números** (`cc_custo_fonte`, `cc_custo_calculado`, diferença, `cc_status_conferencia`, `cc_pct_sp`) vivem **só** em `composicoes_custo` (1 linha por cmp/uf/modalidade). É o "headline" do alerta.
- `composicoes_custo_alerta` guarda **apenas a CAUSA** (tipo do alerta + referência do item culpado + observação), **sem repetir custo**, e **só para casos relevantes** (divergência relevante / sem custo). A causa item-a-item é derivável; persiste-se o que merece fila de revisão.

### 4.3 `cc_custo_fonte` = publicado CRU · exibição = calculado · fontes com BDI publicado *(decisão Renan 2026-07-03)*

- **`cc_custo_fonte` guarda SEMPRE o que a fonte publicou, cru** — a app **nunca** "limpa" essa coluna. SINAPI/CDHU publicam **sem** BDI → guardam limpo; **FDE publica COM BDI → guarda com BDI** (único caso; ver [CATALOGO_FDE_IMPORT_CONTRACT.md](CATALOGO_FDE_IMPORT_CONTRACT.md) §2). Princípio uniforme e sem perda: a coluna é a **auditoria ao centavo** do que a fonte disse. O âncora de auditoria definitivo é o **original arquivado no R2** (PDF/xlsx da edição).
- **A app EXIBE `cc_custo_calculado`** (processado pela app), não o fonte (§3.2/§4.2). O fonte vira **referência/auditoria**, visível na tela de diff. Motivo da inversão: o calculado acompanha a matemática da app (recomputa sob rotação de preço) e uniformiza fontes com/sem BDI.
- **"O publicado tem BDI?" NÃO se lê na coluna de custo** — lê-se na **presença de linha em `catalogo.edicoes_bdi`** para a edição. Essa é a chave que dispara a des-BDInização. `edicoes_bdi.ebd_percent` = o BDI% publicado (uniforme p/ a família; pode haver NORMAL/REDUZIDO).
- **Conferência des-BDInizada quando há BDI publicado:** compara `cc_custo_calculado` contra `cc_custo_fonte ÷ (1 + ebd_percent/100)` se a edição tem BDI; senão contra o fonte cru. **Sem isso, TODA linha da FDE gravaria DIVERGENTE pelo BDI** (alarme falso). **Mesma regra em DOIS lugares:** no **import** (grava `cc_diferenca_valor`/`cc_status_conferencia`) e na **exibição** (tela de diff). A tolerância §4.1 (≤0,5% ou ≤R$0,01) absorve o epsilon de arredondamento do limpo **derivado**.
- **Tela de diff** — `/edicoes/{edi_id}/diff-fonte-app` (por edição×UF): lista Código · Descrição · Unid · **Custo Easy** (`cc_custo_calculado`) · **Custo Fonte** (limpo: `fonte ÷ fator` quando há BDI, senão `fonte`) · **Custo Fte c/ BDI** (`cc_custo_fonte` cru — coluna só aparece quando há BDI) · **Diferença** (Easy − Fonte-limpo). **Conciliação por linha:** células Easy e Fonte-limpo recebem fill **verde** (alta transparência) se batem, **vermelho** se divergem (tolerância §4.1). O BDI fica isolado na 3ª coluna, fora da cor. **Duas contas, uma query** (`LEFT JOIN edicoes_bdi`). É a **casa** (que faltava) do endpoint órfão `GET /api/composicoes/{id}/custo` — hoje sem UI. Serviço novo: `get_diff_fonte_app(edi_id, uf)`.

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

## 6. Situação

> ⚠️ **DECISÃO 2026-06-07 (alvo Fase 2): situação vira CHECK-text, a tabela `catalogo.situacoes` SAI.**
> Motivo: a lookup só era usada por `insumos_preco`; as composições já guardam situação como **CHECK-text** (`cmp_situacao`/`ci_situacao`), e as linhas de domínio `COMPOSICAO` da lookup eram **peso morto**. Situação é **enum pequeno e fixo** → `CHECK` é suficiente; tabela + FK composta + discriminador era complexidade desnecessária (e até com grafia divergente: lookup `'COM_PRECO'` × texto `'COM PREÇO'`). **Princípio:** enum pequeno/fixo → `CHECK`; vocabulário grande/extensível → tabela (ex.: `unidades`, §8.2).
> **Alvo:** `insumos_preco` troca `(pri_sit_id, pri_sit_dominio + FK composta)` por `pri_situacao TEXT CHECK (… IN ('COM PREÇO','SEM PREÇO'))` (null = sem preço). Aplicar no recreate + parser (Fase 2 — NEXT_STEPS). Até lá, schema/parser vivos seguem com `situacoes`.

- A situação guardada é a **declarada pela fonte** (auditoria). A **situação efetiva** (para cálculo) é **derivada em runtime** pela app — não persistida, não confiada cegamente.
- Não há domínio `PRECO` (situação de preço É do insumo) nem `ITEM` (item é só insumo ou composição dentro de composição).
- Domínios de valores: INSUMO → `COM PREÇO`/`SEM PREÇO`; COMPOSICAO → `COM CUSTO`/`SEM CUSTO`/`SUSPENSO`/`EM ESTUDO`. Cada CHECK só admite os do seu lado (a guarda de domínio que a FK composta dava passa a ser o próprio CHECK).

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

**8.1 Manipulação de dados por fonte — `fontes.fte_permite_manipular_dados` (gate de segurança).**
- **Catálogos de terceiros são IMUTÁVEIS** na app: ninguém cria/edita/ajusta insumos, composições ou itens de uma fonte de terceiro (SINAPI, CDHU). Alterar dado de catálogo oficial é **risco alto** (descaracteriza a fonte, quebra auditoria/convergência). Esses dados entram **só por import**.
- Só **fontes próprias** (AXYS — composições/insumos do tenant) permitem manipulação manual. Flag booleana **`fte_permite_manipular_dados`** (default `FALSE`; seed: AXYS=`TRUE`, SINAPI/CDHU=`FALSE`).
- **É o GATE** que as telas/serviços de insumos e composições consultam: criar/editar/excluir/ajustar só é oferecido (e aceito no back) quando a fonte do registro tem `fte_permite_manipular_dados = TRUE`. Import **não** passa por esse gate (escreve sempre).
- **Edição da própria flag:** atributo restrito a **administrador** (gating padrão `_pode_editar`); na criação o admin a define livremente; em modo edição fica travada para perfil sem role adequada. Toda mudança é auditada (`fontes` UPDATE).

**8.2 Unidades de grandeza — vocabulário controlado (`catalogo.unidades`).** *(decisão Renan 2026-06-07; alvo Fase 2 p/ as FKs)*
- **Tabela `unidades`** = vocabulário único (uma só; unidade é universal — metro é metro p/ insumo ou composição). **PK natural = o código** (`un_codigo` TEXT: `'M3'`,`'KG'`,`'UN'`,`'M3XKM'`). O valor gravado em `insumos.ins_unidade`/`composicoes.cmp_unidade` é esse **código legível** (FK), **sem id surrogate** → banco continua legível **e** íntegro.
- **Por quê:** import vem (quase) normalizado, mas a **criação manual** (fontes próprias, AXYS) geraria typos/variantes (`m4`, `M2/MES`×`M2XMES`). A tabela barra isso. **Enum pequeno fixo → CHECK (situação); vocabulário grande/extensível → tabela (unidade).**
- **Tipo:** `TEXT`/`VARCHAR` — unidades **compostas** existem (`M3XKM`,`TXKM`,`M2XMES`); `char(3/4)` não serve.
- **Import = VERBATIM (fidelidade §9.5):** faz **UPSERT** da unidade **exatamente como a fonte publica** (cria em `unidades` se não existir). **NÃO normalizar dado de fonte** — transformar `M2/MES→M2XMES` em dado importado abre uma caixa infinita ("a gnt fica maluco") e quebra a fidelidade. Variantes de fonte ficam no registro **como publicadas**.
- **Criação manual:** só **seleciona** da lista; **"Outra"** = nova unidade, restrita a **admin** + confirmação (senão reabre o vetor de typo). A **convenção canônica** (maiúsculas, `X` p/ composta, sem acento `MES`) é **guia para o que o humano cria** — não um transform sobre dado de fonte.
- **Hook:** `un_categoria` (comprimento/área/volume/massa/tempo/composta) prepara o **fator de conversão** da retroanálise (§9.5).
- **Estado:** tabela `unidades` **criada** (schema + dev, semeada com o vocabulário atual). **FK** em insumos/composições = **Fase 2** (quebra parser atual; ver NEXT_STEPS).

---

## 9. Época / Diff (evolução entre edições)

- **No import**, após parsear e **antes de gravar**: "este registro já existe?" → se **sim**, computa **diff** e grava em `*_historico`; se **não**, grava `CRIACAO` e pula auditoria.
- **Preço nunca vai para histórico** — a série temporal vive em `insumos_preco` por edição; composições são versionadas por edição (`cmp_edi_id`).

**9.1 Diff por PRESENÇA na edição imediatamente anterior (`edi_prior`).** ⚠️ ATUALIZADO 2026-06 (antes: "contra o estado vigente / ativo = mais recente" — incorreto após a vigência migrar p/ o publicar).
- Como a **vigência** (`cmp_ativa`/`ins_ativo`) só é decidida no **PUBLICAR**, não no import (§EDICOES), a diff **NÃO** usa o flag de ativo como proxy de "estava no banco" (no import tudo está inativo → daria reativação espúria em massa). Usa-se a **PRESENÇA** do código em **`edi_prior`** (edição imediatamente anterior COM DADOS):
  - **ausente** em `edi_prior` + presente agora → `REATIVACAO` (cobre reativação após salto: a ocorrência anterior do código não está em `edi_prior`);
  - **presente** em `edi_prior` + ausente agora → `INATIVACAO`;
  - presente em ambas → compara conteúdo (`ALTERACAO_*`, §9.2);
  - código nunca existiu na fonte → `CRIACAO`.
- Implementação: `aplicar_diff_edicao` em `parser_cdhu.py` (compartilhado SINAPI+CDHU); idempotente por edição. `edicao_anterior()` resolve o `edi_prior`. Validado no salto CDHU 184→201 e SINAPI 08-24→04-26: **zero reativação espúria**.

**9.2 O que conta como ALTERAÇÃO ("alteração verdadeira").**
- **Só** os campos de **conteúdo**: **descrição (texto)**, **unidade**, e **coeficiente/itens** (inclusão, exclusão, mudança de coef).
- **`null` ≠ alteração:** `null`/ausente → valor **não** é alteração — é **dado que faltava naquela época** da fonte (ex.: a coluna `Situação` do Analítico SINAPI, inexistente em 08/2024 e publicada em 04/2026). Tratar `null→valor` como mudança gera falso positivo em massa (na virada 08-24→04-26 seriam ~9,3k composições "alteradas"; reais = ~3,3k).
- **Situação NÃO é gatilho de alteração** — em direção alguma (`null↔valor` nem `valor→outro`). É **metadado de presença**, gravado por época em `cmp_situacao`/`ci_situacao` para consulta, mas não emite evento. (Se a situação mudar por causa real — insumo sem preço entrando na árvore — o gatilho real é a mudança de **itens**, que já registra.) Implementação: helper `_alteracao(de, para)` em `parser_cdhu.py`, **não** chamado para situação.
- **Risco-espelho coberto:** como situação nunca é gatilho, uma futura edição que **deixe** de publicar a coluna (`valor→null` em massa) também **não** gera ruído.

**9.3 Snapshot por época (consulta ponto-no-tempo).** — ⚠️ **MODELO FASE 1 (atual)**; o **alvo** é o modelo **contínuo** de §9.6 (composição vigente + custo denso + histórico esparso). §9.3 descreve o banco vivo de hoje (per-edição) até a migração da Fase 2.
- Cada import grava o **snapshot completo** da edição: 1 linha por composição com `cmp_edi_id` daquela edição. "Quantas composições ativas na época X" = `COUNT(*) WHERE cmp_fte_id=F AND cmp_edi_id=<época>` — **1× por CPU** (identidade), não multiplicado.
- **Não usar `cmp_ativa` para ponto-no-tempo:** `cmp_ativa=TRUE` marca só a versão **vigente (hoje)**; para a época X filtre por `cmp_edi_id`.
- Só é consultável para épocas **efetivamente importadas** (imports esparsos não reconstroem o miolo).
- **Cardinalidade:** custo multiplica, identidade não. `composicoes` = 1×/CPU; `composicoes_custo` = CPU × 27 UF × **2 modalidades (SD, CD)**. **SE não existe para composição** (é nível de insumo, pelado); são **2** modalidades de custo, não 3.

**9.4 Reconciliação e sequenciamento.**
- **Dois diffs no SINAPI:** **SINAPI-Diff** (`catalogo.sinapi_manutencoes`, changelog publicado) e **Axys-DIFF** (série histórica computada pela Axys, agora contra o banco vigente). A app apresenta ambos e **reconcilia** ("a manutenção cobre tudo que o Axys-DIFF achou?"). CDHU não publica changelog → só Axys-DIFF.
- **Reimport sem rebuild ainda não é idempotente** quanto ao *supersede* (a linha superada por uma edição segue inativa → no reimport apareceria como `REATIVACAO`). Para reimportar a **mesma** edição, `rebuild` antes. Imports novos / fora de ordem estão corretos.
- **Sequenciamento:** o diff é estágio **posterior** ao import "puro" funcionar (ver `PLANO_IMPORT_CATALOGO.md`, Fases 2.2 e 3.4).

**9.5 Retroação — leitura ponto-no-tempo de insumo (trinca atômica + conversão app-dependente).**
Complementa o lado da escrita (9.1–9.4): aqui é como a app **lê** o passado.
- **Modelo (insumo):** `insumos` = **vigente** (1 linha/código → a busca não multiplica por época); `insumos_preco` = **denso por edição** (preço exato@E); `insumos_historico` = **esparso**, faixa de validade `edi_id_inicio/edi_id_fim`, eventos `CRIACAO`/`ALTERACAO_*`/`INATIVACAO`/`REATIVACAO`. Atributos que entram em `ALTERACAO_*`: **descrição** e **unidade** (a "alteração verdadeira" de 9.2). Grava só quando difere; 1º aparecimento = `CRIACAO` (`dados_anteriores=null`).
- **Leitura histórica é a TRINCA ATÔMICA `(preço@E, unidade@E, descrição@E)`** — nunca o preço sozinho, nunca pareado com a unidade **vigente**. Uma função única (`obter_insumo_em_edicao(ins, E)`) devolve a trinca: preço de `insumos_preco@E` (lookup direto); unidade/descrição reconstruídas de `insumos_historico` (`E ENTRE [edi_inicio, edi_fim)`) com **fallback ao vigente**. Custo: ~2 lookups indexados — retroação O(1), sem varredura.
- **Por que atômica:** preço histórico sem a unidade da época **engana**. Ex.: vergalhão muda `barra→kg` e `R$74,04/br → R$15/kg`; lido com a unidade vigente diria "barateou" quando **encareceu**.
- **Conversão NÃO é automática — é app-dependente.** O domínio é aberto (br↔kg via peso, etc.; infinitas possibilidades) — automatizar quebra. Quando a app retroage e detecta **divergência de unidade** (unidade@E ≠ vigente, ou muda dentro do intervalo), ela **não converte**: **notifica o usuário** a definir o **fator de conversão** e **registra como observação** no artefato. Casos:
  - **Retroagir orçamento:** varre insumo a insumo; em cada divergência de unidade → aviso + observação no orçamento.
  - **Retroagir composição isolada:** idem.
  - **Série histórica / gráfico:** idem (sem fator, não plota cruzando unidades).
  - Mudança só de **descrição** (texto, não quantidade) = aviso **informativo**, não bloqueia. O gatilho de conversão é **unidade**.
- **De onde vem o fator:** decisão do usuário (registrada no artefato); fonte auxiliar possível = `insumos_equivalencias`/peso — **feature de análise futura**, não buraco de storage (o storage já entrega a unidade correta de cada ponta).
- UX do aviso: ver `config_ui_ux_easy.md` → "Retroanálise com modificações impactantes".

**9.6 Modelo contínuo de composição (ALVO Fase 2) — substitui o snapshot-por-edição de §9.3.**
Espelha insumos (§9.5): **identidade vigente + custo denso por edição + histórico esparso por mudança**. Mata a duplicação da `composicoes_itens` por edição (a busca deixa de retornar "a mesma CPU N vezes por época").
- **`composicoes` = identidade vigente** (1 linha por `(fonte, código)`; **sem `cmp_edi_id`**; UNIQUE `(cmp_fte_id, cmp_codigo)`). descrição/unidade/situação/flags/external_path = estado **vigente**.
- **`composicoes_itens` = receita VIGENTE apenas** (`ci_cmp_id` → identidade). **Sem** `ci_*_fonte_original` — o filho (insumo/CPU) é resolvido pela **identidade**; o texto histórico vive no snapshot do histórico. **Dedup**: descrição de filho não se repete.
- **`composicoes_custo` = série densa por edição** (`+ cc_edi_id`; UNIQUE `(cc_cmp_id, cc_edi_id, cc_uf, cc_modalidade)`), simétrico a `insumos_preco`. Guarda `custo_fonte`/`custo_calculado`/conferência por edição. Retroanálise de custo = **lê, não recalcula**; só explode a árvore sob demanda.
- **`composicoes_historico` = snapshot-na-mudança** (esparso): `ch_dados_novos` = snapshot **completo** `{descricao, unidade, receita:[{tipo, id(+cod), coef}]}` → "como era na edição E" = **1 lookup**; `ch_diff` = só o que mudou. Evento **só quando muda** descrição/unidade/receita; **custo nunca** entra no histórico.
- **Nomenclatura — preço × custo é distinção de DOMÍNIO, não despadronização:** insumo tem **preço** (`insumos_preco`, valor unitário publicado); composição tem **custo** (`composicoes_custo`, derivado = Σ filhos×coef + LS, com conferência fonte×calculado). Manter os dois nomes (SINAPI/ABNT publicam "preços de insumos" × "custos de composições"; §3 × §4). **Não** renomear.
- **Retroação (leitura ponto-no-tempo de composição):**
  - **Custo@E** = lookup direto em `composicoes_custo@E` (sem recalcular).
  - **Receita@E** = `ch_dados_novos` do evento cuja validade cobre E (ou a vigente em `composicoes_itens` se E é o período atual).
  - **Analítico (explosão da árvore)@E** = recursivo: cada filho resolvido **as-of-E** — insumo via trinca §9.5; CPU-filha via receita@E + custo@E. Mais memória, mas limitado; análise sem explosão usa `composicoes_custo@E` direto.
  - Conversão de unidade segue §9.5 (app detecta divergência, usuário define o fator, vira observação — nunca auto-converte).
- **Status/implementação:** modelo **documentado**; aplicar no **schema.sql** (CREATE TABLE) e **parsers** na **Fase 2** (drop+recriar + re-import do audit) — ver `CATALOGO_NEXT_STEPS.md`. Banco vivo e parsers seguem no modelo §9.3 até lá.

---

## 10. Ciclo de vida da fonte/edição (upload em fases · liberação · lock)

Catálogo de preço só fica **disponível ao tenant** quando **completo e validado**; depois **congela**.

**10.1 Flags.**
- **Fonte:** `fte_tem_catalogo_insumos` (bool, default `false`) — o usuário declara no cadastro se a fonte publica catálogo/relatório de insumos (na prática hoje só a SINAPI tem fichas; CDHU não).
- **Fonte:** `fte_catalogos_continuos` (bool, default `false`) — os documentos (fichas/cadernos/critérios) **podem não mudar por edição**? `true` = contínuos (SINAPI: trazem data de atualização → publica com **skip por data**, §11.3); `false` = reemitidos/mudam por edição (CDHU: **sobe tudo por edição**, §11.2). Default `false` é conservador (re-sobe sempre) — fonte que o usuário sobe declara isso.
- **Edição:** estado **único** em enum `edi_situacao_ciclo` ∈ {`RASCUNHO`, `PUBLICADA`, `EM_REVISAO`, `ARQUIVADA`} (+ gates abaixo). `RASCUNHO` é o default. **Não há `edi_ativa`** (removido 2026-06-06 — sobreposição com o ciclo). Semântica: `RASCUNHO` = em construção, indisponível, mutável; `PUBLICADA` = disponível p/ novo uso E histórico, travada; `EM_REVISAO` = só pós-PUBLICADA (recall): reaberta/mutável p/ correção mas **segue disponível** ao tenant com aviso (`edi_revisao_nota`) — volta a `PUBLICADA` ao concluir; `ARQUIVADA` = descontinuada p/ **novos** usos mas histórico/usos existentes permanecem (não é "indisponível"; raro). "Disponível p/ novo uso" := `PUBLICADA`∪`EM_REVISAO`; "acessível (histórico)" := `PUBLICADA`∪`EM_REVISAO`∪`ARQUIVADA`. Travadas: `PUBLICADA`/`ARQUIVADA`; mutáveis: `RASCUNHO`/`EM_REVISAO`.
  - `edi_ins_catalogo_ok` (bool): se `fte_tem_catalogo_insumos` → exige upload das fichas de insumo; **senão o back seta `true` automático** (não há o que subir).
  - `edi_comp_catalogo_ok` (bool): exige upload dos **cadernos/critérios** (composições) — **obrigatório para toda fonte**.

**10.2 Fases do upload da edição.**
1. **3.1 — import "grande"** (insumos/preços/composições/custos/conferência/diff) — o pipeline já validado.
2. **3.2 — fichas de insumo → R2** — **opcional**, só para fonte com `fte_tem_catalogo_insumos=true`.
3. **3.3 — cadernos de encargos / critério de medição e remuneração → R2** — **obrigatório**.

**10.3 Publicar, travar e arquivar.**
- `RASCUNHO` → itens da edição **indisponíveis** a **qualquer** tenant.
- Botão **Publicar** (`RASCUNHO`→`PUBLICADA`, front) → o back valida: import grande feito **+** `edi_ins_catalogo_ok` **+** `edi_comp_catalogo_ok`. Passando → `PUBLICADA`: itens **disponíveis** (novo uso + histórico) e edição **travada (imutável)**.
- Botão **Revisão** (`PUBLICADA`→`EM_REVISAO`) → caso de **recall/correção** (ex.: a SINAPI solta um recall): destrava a edição p/ atualizar, grava o que será revisado em `edi_revisao_nota`, e **mantém disponível** ao tenant com **aviso**. **Concluir revisão** (`EM_REVISAO`→`PUBLICADA`) re-trava.
- Botão **Arquivar** (`PUBLICADA`→`ARQUIVADA`) → a edição **sai de novos usos**, mas **histórico e usos existentes permanecem acessíveis** (não apaga, não bloqueia consulta). Estado **raro**; acesso restrito.
- **Lock é de camada app/parser** (rejeita mutação em edição `PUBLICADA`/`ARQUIVADA`; `EM_REVISAO` é mutável), **sem trigger** — casa com "imutável por edição" (§7). Manutenção pós-lock só por **usuário de acesso máximo**, em tela específica.
- **Sem `edi_ativa`** (removido 2026-06-06): "disponível p/ novo uso" = `situacao_ciclo IN ('PUBLICADA','EM_REVISAO')`; não há inativar/reativar — só Publicar/Revisão/Arquivar.

**10.4 Impacto.** Colunas/flags são **aditivas** (default conservador) — **não** alteram o import, os parses nem os uploads ao R2 já validados. É governança de camada app, plugada na refatoração de fontes/edições e nas telas de import.

---

## 11. Publicação do catálogo de DOCUMENTOS no R2 (fichas/critérios/cadernos)

Camada **documental** (especificação de insumo, critério de medição, caderno técnico) — distinta do preço.

> ⚠️ **ATUALIZADO 2026-06 — `CATALOGO_STORAGE_LAYOUT.md` é a referência de paths.** Os caminhos
> citados nos itens abaixo (`fontes/sinapi/fichas/`, `audit/…`, etc.) foram **padronizados**: tudo
> sob `easy/fontes/{fonte}/{edicao}/{originais|fichas|cadernos}` + livros em `…/livros/`. Acabou o
> `audit/` (vira `{edicao}/originais/`); o critério CDHU unifica em `cadernos/`. Centralizado em
> `backend/modules/catalogo/storage_paths.py`. Novos `doc_tipo`: **`original`** (xlsx do import +
> critério-fonte), **`leis_sociais`** (PDFs CDHU inteiros), **`caderno_tecnico`** (índice gerado).
>
> **Realces da exibição vêm do BACK ao servir** (`/doc/{id}/conteudo`): injeta no topo do `<body>`
> a **hierarquia grupo/subgrupo** (CDHU, do banco) — o parser do PDF **não** lê isso (nem toda
> página tem). SINAPI usa o **rótulo** canônico. O HTML do CPU traz `{código} - {descrição}`.
>
> **Caderno técnico** (botão Fontes-Base): a app gera um **HTML estático** (header + originais
> Ver/Baixar + índice grupo›subgrupo com links hardcoded `/doc/{id}`), sobe ao R2, async + cache
> (1 por edição). Ver `CATALOGO_STORAGE_LAYOUT.md §4` e `CATALOGO_FECHAMENTO.md`.

**11.1 Conteúdo puro + identidade.**
- O HTML no R2 é **conteúdo puro** (semântico, editável): a ficha/critério **sem** o chrome da app. O **header** (tarja, logo, tenant) é montado **no render da app**, não gravado no R2.
- Todo HTML carrega o **favicon** oficial (`assets/favicon.png`, 64px — gerado por downscale Lanczos do app icon; o PNG grande original dava halo no tab) via URL pública do R2.
- O documento vive na **IDENTIDADE** e ela é a **FONTE ÚNICA** (não cache): insumo → `insumos.ins_external_path`; composição → `composicoes.cmp_external_path` (JSONB). Guarda a **vigência por versão** (§11.10); a app resolve ficha/caderno_cpu/CTC **daqui**, sem passar por `catalogo.documentos`. A **edição** apenas **exige a existência** do doc (gate §10), não é dona do arquivo.
- **Responsivo obrigatório:** todo HTML publicado é mobile-friendly **E** desktop — sem overflow horizontal. O CSS embutido é responsivo por si (não depende da render da app): tabelas largas rolam na horizontal (wrapper `overflow-x:auto`), só colunas de descrição quebram, demais ficam `nowrap`.

**11.2 Organização de diretórios no R2 (bucket público `axys-public`).** O layout **reflete a natureza da fonte** (contínua × por edição):

```
fontes/
  sinapi/                     ← CONTÍNUA: o doc vive na identidade, SEM nível de edição
    fichas/<ins_codigo>.html
    cadernos/<cmp_codigo>.html
    cadernos/_apresentacao/<subgrupo_slug>.html   → edicoes.edi_capa_path
    metodologia/<Livro>.pdf   ← livros de referência (PDF original; §11.8)
    audit/                    ← arquivos-fonte do import, em 3 subpastas:
      ficha/fichas_insumos.pdf        (PDF das fichas — hyperlink do xlsx)
      cadernos/SINAPI-CT-*.pdf        (PDFs dos cadernos — hyperlink das composições)
      <ano>-<versão>/SINAPI_*.xlsx    (os 4 excels da edição; ex.: 2026-04/)
  cdhu/                       ← NÃO-CONTÍNUA: reemite por versão → nível da VERSÃO
    <edi_codigo_versao>/
      criterios/<cmp_codigo>.html
      audit/                  ← criterio.pdf + excels da versão
assets/                       ← favicon.png (e estáticos)
livros/                       ← índices ("guia de bolso"): <fonte>.html + sinapi_descontinuados.html
```

Regra estrutural: **fonte contínua** (`fte_catalogos_continuos=true`, SINAPI) **NÃO** aninha o doc na edição (seria snapshot por edição — modelo errado p/ contínua, onde o doc é o vigente na identidade); **fonte por edição** (`false`, CDHU) aninha em `<versão>` (versões antigas SÃO o histórico). Tudo que o usuário "sobe para import" é guardado em `…/audit/` (rastreabilidade). **Estado final do bucket = só `fontes/` + `assets/` + `livros/`.**

**11.3 Fonte `fte_catalogos_continuos=false` (ex.: CDHU) — sobe tudo a cada versão.** A CDHU reemite o catálogo de critérios a cada edição (repete textos, sem controle de mudança). Como é leve (texto), **sobe tudo por versão**:
- `fontes/cdhu/<versão>/criterios/<cmp_codigo>.html` + originais em `fontes/cdhu/<versão>/audit/`.
- `cmp_external_path` mantém a **vigência por versão** (`versoes:[{desde_edi, path}]`, §11.10) — a última aponta pro path atual da versão, as anteriores pro `_old/`.

**11.4 Fonte `fte_catalogos_continuos=true` (ex.: SINAPI) — skip por data de atualização.** Fichas (`Atualizado em:`) e cadernos (`Atualização`) trazem a data da última revisão. Path **sem edição** (`fontes/sinapi/fichas/`, `fontes/sinapi/cadernos/`). Regra **idempotente**: se a data do doc **≤** a edição **E** o item **já existe no R2** → **não sobe (skip)**. Evita re-subir docs idênticos a cada boletim (o conteúdo é contínuo na identidade).

**11.5 Livros (índices / "guia de bolso").** Sumários navegáveis por fonte; cada item é link → abre o HTML no R2. São consulta rápida — na prática **a app consome os dados conforme as funcionalidades**.
- **SINAPI** (contínua): no topo, `Versão atual: <edi>` + link **descontinuados** (`sinapi_descontinuados.html` — insumos/composições **inativos** que têm doc; lista contínua que **cresce com os imports**; vazia por ora). Cadernos agrupados por subgrupo; fichas em lista.
- **CDHU** (por versão): lista **todas as versões** (`<details>`, mais recente **aberta** no topo, ordenado desc). **Sem** descontinuados — versões antigas são o histórico.

**11.6 Estado (2026-06-05).**
- **SINAPI:** 170 cadernos (8664 CPUs + 170 apresentações) + 6010 fichas em `fontes/sinapi/` (path contínuo, sem edição); responsivo + favicon novo. `audit/` **reorganizado** nas 3 subpastas (`ficha/`, `cadernos/`, `<ano>-<mês>/`) — antes os xlsx/PDF ficavam soltos em `audit/` (errado); corrigido. Livro com versão atual + descontinuados.
- **CDHU:** 184+201 re-emitidos em `fontes/cdhu/<v>/criterios` + `audit/` + `metodologia.html` (§11.7); banco 100% no path novo; path antigo `criterios/cdhu/` removido.
- **Limpeza concluída:** órfãos do esquema anterior removidos — `fichas/` e `criterios/` de topo + o nível `fontes/sinapi/04-26/`. Bucket = `fontes/` + `assets/` + `livros/`.

**11.8 Livros de metodologia (SINAPI) — PDF original, não convertido.** Livros de
referência (ex.: *SINAPI — Cálculos e Parâmetros*) têm **autores registrados** (direito
autoral) e a conversão p/ HTML degrada (caracteres/figuras). Regra: **mantém o documento
ORIGINAL** (link do PDF), no R2 sempre a **versão mais recente**, em `fontes/sinapi/metodologia/`.
- **Descoberta:** o link vem da aba CCD do SINAPI_Referência (URL de `sinapi-metodologia`).
  No import de cada edição há **pesquisa** pelo livro (`import_cadernos_sinapi.publica_livros_metodologia`);
  **se a CCD não trouxer**, a **UI EXIGE** arquivo/link (obrigatório — regra de tela).
- **Change-check + histórico:** a cada edição compara o **sha1**; se mudou, re-sobe e empilha
  a versão anterior. Banco: `edicoes.edi_capa_path._livros` `{slug:{titulo,url,path,sha1,atualizado_em,historico[]}}`.
- **Parser HTML** (`backend/core/import_cpu/livro_sinapi.py`) existe **só p/ auditoria** — NÃO publica.
- No livro/índice (§11.5) aparece em "Livros SINAPI (referência)".

**11.7 Metodologia do boletim (CDHU).** Algumas versões trazem `metodologia_boletim_<v>.pdf` (METODOLOGIA DE CONSULTA + tabela UNIDADES PADRÃO) — é a **"apresentação" do CDHU** (análoga à do caderno SINAPI). Vai pro `audit/` **e** vira `fontes/cdhu/<v>/metodologia.html` (gravado em `edicoes.edi_capa_path.metodologia`); no livro CDHU aparece **antes das composições** da versão.

**11.9 REGISTRO central de documentos (`catalogo.documentos` + `documentos_origem`) — só docs SEM dono 1:1.** ⚠️ **REVISTO 2026-07-13 (repense doc/path).** O registro central **NÃO** cataloga **ficha / caderno_cpu / CTC** — esses vivem **só na identidade** (§11.1, `external_path`, que é a fonte única e guarda a vigência §11.10). `documentos` fica com os docs de **edição/fonte que não têm dono 1:1** e por isso precisam de um catálogo central p/ governança R2 / órfãos / livros:
- **Tipos que ficam** (~140 linhas, não ~12 mil): `livro` · `metodologia` · `nota` · `caderno` (PDF-fonte) · `original` (xlsx do import + critério-fonte) · `leis_sociais` · `apresentacao` (sub,edi) · `criterio` (CDHU, edi-level) · `caderno_tecnico` (índice gerado) · `referencia`.
- **Motivo da revisão:** catalogar ficha (6k) + caderno_cpu (6k) aqui era **tripla escrita** (`external_path` + `documentos` + `composicao_documento`) de um path **determinístico** (`storage_paths.py`) que a identidade já guarda — sobretensiona o banco sem ganho. A fronteira de governança segue válida **só** p/ o que não tem dono na identidade. (Reverte o "unifica os JSONB / external_path deprecado" de v0.1.)
- **`composicao_documento` (N:N cmp↔doc) — DEPRECADA / DROPADA:** existia só p/ religar `caderno_cpu`→composição, que já está em `cmp_external_path`. Volta apenas se surgir **cross-ref real** (uma composição citando doc de **outra** identidade).
- **`documentos_origem`** = proveniência (arquivo da **matriz Caixa** — pode sumir — + cópia no R2/audit). Dedup por arquivo. Mantida p/ os docs que restam.
- **`documentos`** = 1 linha por doc de edição/fonte: FK `doc_edi_id`/`doc_fte_id` (+ `doc_sub_id` p/ apresentação), `doc_org_id`, `doc_tipo`, `doc_path`/`url`, `doc_titulo`, `doc_sha1`, `doc_data`, `doc_versao`, **`doc_vigente`**, **`doc_orfao`**. `doc_ins_id`/`doc_cmp_id` deixam de ser populados (a identidade não passa mais por aqui).
- **Leitura:** livros (§11.5), seção "Originais" do caderno, árvore `/documentos`. A app **não** usa `documentos` p/ abrir ficha/CTC — usa `external_path` (§11.1/§11.10).
- **Governança de links:** livros e registro referenciam **sempre o R2**, nunca a matriz. **Admissível:** doc no R2 sem item no banco (`doc_orfao=true`); o inverso (item sem doc) é tela de verificação.

**11.10 Vigência por versão — vive no `external_path` (não em tabela, não no `_index.json`).** ⚠️ **REVISTO 2026-07-13.** O que vincula um insumo/composição à sua ficha/caderno_cpu/CTC **atual ou `_old`** é o próprio `external_path`, que passa a guardar a **linha do tempo de versões**. Sem ledger de banco; o `_index.json` de `ctc/`/`fichas/` é **só manifesto de import** (`{cod:sha}` p/ decidir "mudou?") — **não** é vigência.
- **Forma:** cada doc vira `{fonte, versoes:[{desde_edi, path}]}`. A **última** versão aponta pro path canônico (`{cod}.html`); as anteriores pro `_old/{cod}_<sha>.html`. `url` = `/doc-file/` + `path` (derivado).
  ```jsonc
  ins_external_path = { "ficha_tecnica": { "fonte":"SINAPI", "versoes":[
      {"desde_edi": 1,  "path": ".../fichas/_old/1_<shaA>.html"},
      {"desde_edi": 10, "path": ".../fichas/1.html"} ]}}          // última = vigente
  cmp_external_path = { "caderno_tecnico": {"fonte":"SINAPI","versoes":[…]},
                        "ctc":            {"fonte":"SINAPI","versoes":[…]} }
  ```
- **Import (quando o `sha` muda na edição E):** (1) arquiva `{cod}.html` → `_old/{cod}_<shaAntigo>.html`; (2) **reescreve o `path` da última versão** de `{cod}.html` p/ esse `_old`; (3) **anexa** `{desde_edi:E, path:{cod}.html}`. Primeira vez → 1 versão `{desde_edi:E, path:{cod}.html}`. Sem mudança → não toca. Requer import **sequencial por `edi_mes_ref`** (o rebuild já é) p/ a linha do tempo nascer certa.
- **Resolução (viewer/listagem) as-of edição-alvo E:** escolhe a `versoes` de **maior `desde_edi`** cujo `edi_mes_ref` ≤ o de E (ordena por `edi_mes_ref`, robusto a `edi_id` fora de ordem). **Sem** filtro de edição → **última** (vigente). Ex.: código 1010 com entrada@1 e revisão@10 → ver edição 1–9 abre `_old`, 10+ abre atual.
- **Storage:** nada some — `_old/` é o histórico auditável. **Publicar NUNCA trava** por doc: vigente presente ⇒ ok; ausente ⇒ publica com **aviso/confirmação** (suaviza o gate §10).

**11.11 CTC / descritivo (`cmp_descritivo`) — prompt NÃO fica no banco.** ⚠️ **REVISTO 2026-07-13.** `composicoes.cmp_descritivo` guarda **só estado leve** `{modo, status, req_hash}`. O **prompt/documento** do CTC (o `request`, ~6 KB/CPU) vive **só no storage** (`ctc/prompt/{cod}.md` + `ctc/doc/{cod}.md`); mantê-lo em `cmp_descritivo` eram **~56 MB duplicados** no banco. `req_hash` versiona (delta:hash); o path do CTC entra em `cmp_external_path.ctc` (§11.10).
