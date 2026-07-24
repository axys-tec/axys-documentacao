# Contrato de Vinculações Intra-Fontes

> **Status:** Contrato aprovado — em implementação por rounds (ringue).
> **Escopo:** Catálogo de Preços — Insumos e Composições.
> **Eixo de referência:** SINAPI (edificações) / SICRO (infraestrutura), como *fontes primárias (header)*.
> **Origem:** consolida `premissas_mdo_fte_to_sinapi.md`, `premissas_mdo_h_to_mes.md`, `premissas_substituicoes.md`
> (arquivos-raiz, agora aposentados). Data de fechamento da direção: 10/07/2026.
> **Relacionados:** [get-or-create p/ ids] (ID estável = base do carry-forward), CATALOGO_STORAGE_LAYOUT,
> IMPORT_ESTAGIOS, edicoes_import_estagios, CADERNO_TECNICO_AXYS (get_md→put_md).

---

## 0. O que é

Camada **assistiva e curada** que liga itens do catálogo entre si, sempre **ancorada numa fonte primária
(header)**. Não executa orçamento; organiza conhecimento previamente validado para acelerar elaboração e
conferência. Cobre **três amarras**:

| Amarra | Origem → Destino | Natureza |
|---|---|---|
| **H↔MÊS** (SINAPI interno) | CPU SINAPI MDO **[H]** → CPU SINAPI MDO **[MÊS]** | intra-SINAPI, **N:1** (pelo insumo MO), + fator · **determinístico, sem IA** (§3.1) |
| **MDO fonte→SINAPI** | insumo MDO **[H]** da fonte → composição SINAPI MDO **[H]** | assimétrica (insumo→composição), 1:1, cross-fonte |
| **Substituições** | item header (SINAPI/SICRO) → alternativa(s) | 1:1 insumo · **1:N** composição, cross-fonte, cross-edição |

Vale para **composições E insumos**. Toda vinculação é **curada** — o sistema **propõe** (match), a **IA valida**,
o **usuário confirma**. Nunca nasce automática e silenciosa.

---

## 1. Princípio que rege o lugar no pipeline

**Conciliação é cauda do estágio 3 (Dados) — NÃO é um novo estágio.** Os 4 estágios
(preparar→precos→dados→documentos) seguem fechados. As amarras são a **família da conciliação**, irmãs da
**Validação de Unidades** e da materialização de **AxysDocs**: processamento curado que roda **dentro do
import**, para a **edição nascer com as amarras**.

Por que dentro do import e não fora: se ficar avulso, **pode acabar não sendo feito**. Dentro da esteira, a
edição **pós-publicação já nasce conciliada**. É viável porque o **ID de CPU/insumo é estável "pra todo o
sempre"** (get-or-create) → a conciliação vira **diff**, não re-curadoria.

### 1.1. Regra de completude (publicar)
Publicar exige a conciliação **REVISADA**, não 100% vinculada. **"Sem equivalente" é estado terminal
válido** (nem todo item SINAPI tem par CDHU). Trava-se a publicação se houver **delta pendente de revisão**,
nunca por "faltar vínculo".

### 1.2. Ordem (produção)
Importa-se **SINAPI 1..n-1 primeiro** (gera o header e o H↔MÊS), depois CDHU/FDE contra o header. Dentro do
não-SINAPI: **H↔MÊS deve existir antes** de MDO fonte→SINAPI (o 2º salto usa `composicoes_mapeamento_mdo`).

### 1.3. Edição-header
Toda vinculação cross-fonte referencia uma **edição SINAPI header**. Default: **última SINAPI publicada**;
override manual permitido. É o **único input novo** que o pipeline ganha.

---

## 2. Fluxo único: match → IA → user

1. **App faz o match** (heurística com ratios — §4) e monta o **universo + vinculações propostas**.
2. **App emite um prompt `.md`** (irmão do descritivo AxysDoc, em `construcao/`) com todo o universo
   disponível e as propostas → **IA valida** (via `get_md→put_md`, **sem API paga**).
3. **Usuário faz a verificação final** na **tela de Conciliação**; pode **incluir/editar vínculos manualmente**.
4. Vínculo confirmado **persiste por ID estável**.

**1ª importação:** IA valida **tudo**. **Demais:** só o **delta** (item novo/alterado/inativado). **Nada mudou
→ vazio**, tudo já casado, nada a passar. Reimport que mexe num item-base **marca o vínculo p/ revisão**
(não corrige sozinho).

Estados do vínculo: `pendente` → `ia_ok` → `confirmado` | `sem_equivalente` | `revisar` (delta reabriu).

---

## 3. Especificidade de cada amarra

> **PRINCÍPIO — determinístico antes de IA (aula do H↔MÊS, 2026-07-12).** Buscar SEMPRE o sinal
> *ground-truth* no dado (estrutura / insumo / preço físico) antes de recorrer à IA. O H↔MÊS parecia
> caso-de-IA e virou **100% determinístico** (insumo + preço pelado). A IA fica reservada ao **resíduo
> genuinamente ambíguo**, nunca ao que já tem verdade no dado. **Aplicar análogo às outras 2 amarras**
> (MDO fonte→SINAPI já tem função+preço/h; substituições tem estrutura+descritivo-fonte).

### 3.1. H↔MÊS — RESOLVIDA DETERMINISTICAMENTE (2026-07-12, sem IA · commits 41f5dad+)
O que o desenho mandava pra IA, o **insumo + preço** resolvem com precisão total. **NÃO é fuzzy na descrição
da CPU** (engana: TELHADISTA↔TELHADOR, ASSENTADOR DE TUBOS↔MANILHAS, OPERADOR DE MÁQUINAS≈TRATORISTA).
- **Pareamento pelo INSUMO MO (a verdade):** a CPU `{FUNÇÃO} COM ENCARGOS COMPLEMENTARES` contém 1 insumo MO
  (`ti_codigo='MO'`) = a função horista/mensalista. H-CPU→insumo-H→(mesmo nome de função)→insumo-MÊS→MÊS-CPU.
  Nome do insumo bate exato na quase totalidade; nome divergente → **override curado por código de insumo**
  (`backend/modules/catalogo/data/mdo_insumo_override.json`, ex.: 4243↔41031, 1213↔40914). 94/94 na edi 5/22.
- **N:1** (não 1:1): 1 insumo/CPU-MÊS serve 2 ofícios-H (calceteiro+rasteleiro→1 MÊS; tratorista+operador→1
  MÊS, mesmo preço). Schema **sem** `uq_cmm_mes`; cada H tem 1 MÊS (`uq_cmm_h`).
- **Validador = preço PELADO** (modalidade SE; **não** o custo-CPU com encargos — encargos H≠MÊS não
  convergem): `TRUNC(preço_mês/220, 2) = preço_hora` → **ratio EXATO 1,0** (94/94). "Preço de barata → é barata."
- **Auto-confirma** os confiáveis (insumo/override + preço bate) → **sem IA, sem pausa**. Horista-only (sem
  CPU-MÊS: instalador de piso elevado, montador de fôrmas de parede) → **`sem_par`** (terminal válido). Só
  resíduo fuzzy fraco → pendência (IA/user). MDO é **estático** (códigos idênticos entre edições).
- **Guarda de import (CATALOGO_SINAPI_IMPORT_CONTRACT):** MDO NUNCA entra como **NC** — o parser do Analítico
  reclassifica insumo órfão MDO (`(HORISTA)/(MENSALISTA)`) p/ **MO** (`_classificar_orfao_mdo`), senão vira
  invisível pro matcher/preço/LS.
- **Fator** explícito/editável (`1/220`, `cmm_qtd_h_mes`=220 exato), não hard-coded (reforma trabalhista muda).

### 3.2. MDO fonte→SINAPI
- Origem: **insumo** MDO [H]; destino: **composição** SINAPI MDO [H]. Match pela **função** (não a descrição
  inteira) — **reusar o dicionário de termos do buscador MDO CDHU/FDE**. **Categoria-aware**
  (engenheiro jr/pleno/sênior não podem colapsar).
- **Validador de preço:** na mesma UF, o **R$/h** do insumo CDHU/FDE **bate** com o insumo principal dentro da
  CPU SINAPI (preço norteado por sindicato). → `ratio_desc(X)` + `ratio_preço(Y)` → `ratio_total = média(X,Y)`
  (enriquecível). Quando faltar preço p/ a UF, degrada p/ só `ratio_desc`.
- Encadeia o 2º salto via H↔MÊS quando precisar do regime mensalista.
- **MDO na ORIGEM (fonte) = `ins_ti_id = 1` (MO).** ENC_COMP (`ti=2`) é tipo do **lado SINAPI**, não existe nas
  fontes-origem (CDHU/FDE) — por isso o filtro do não-MDO na origem (§3.4) `NOT IN (1,2)` = `<> 1` na prática.
  O **destino** MDO no SINAPI são as composições "…COM ENCARGOS COMPLEMENTARES" [H].
- **⚠️ EXCEÇÃO à âncora-SINAPI (2026-07-18):** no MDO a direção é **origem=FONTE → destino=SINAPI** (não
  SINAPI-âncora). **Completude na FONTE:** toda função da fonte (45 CDHU / 36 FDE) **tem de resolver** (match
  ou `sem_equivalente`); o SINAPI (192 [H]) **pode ter funções sem associação** — é muito maior. Lógica de
  obra: **não há 2 pedreiros/serventes com preço diferente** → a função da fonte é única, tem par. Por isso o
  manifesto MDO é **dirigido pela fonte** (lista completa da fonte à esquerda; SINAPI casado/‹a resolver› à
  direita). **`mo_ref_item_id` NOT NULL — toda MDO TEM de equivaler** (senão encargos diferentes). O estado
  `match | sem_equivalente` é **obrigatório p/ toda função da fonte** (nenhuma fica pendente); `sem_equivalente`
  é **exceção rara** (função sem par real no SINAPI, ex.: engenheiro mecânica/elétrica) — representada pela
  **ausência de linha** (fila vermelha do manifesto), não por linha de alvo nulo. Meta = **100% equivalido**.
- **Matcher determinístico (implementado `equivalencias_service.propor_mo`):** strip "COM ENCARGOS
  COMPLEMENTARES" → **nível** (auxiliar/ajudante→AUXILIAR ⟷ oficial) **tem de bater** + **containment do
  ofício** fonte→SINAPI (≥0,67) + tie-break Jaccard. Dicionário `data/mdo_sinonimos.json`
  (ajudante↔auxiliar, ferreiro↔armador, esgoteiro↔poceiro). Iterei overlap-min→Jaccard→containment→
  **nível+containment** (overlap-min deixa o oficial ganhar; Jaccard puro derruba o genérico).
- **Sequência de curadoria:** **MDO primeiro** (ti 1,2 — pequeno, determinístico), depois o não-MDO
  (ti≠1,2 — o grosso). Tabelas separadas, passadas separadas.

### 3.3. Substituições (a cara — IA-pesada na 1ª)
- Olha descrição **e a composição** (a **estrutura**, não os coeficientes — esses mudam). Header 1 → N subs
  (ex.: concretagem de pilar CDHU = concreto + lançamento). **4 frentes de ratio:**
  1. **descrição**
  2. **grupo/subgrupo**
  3. **descritivo da fonte-base** (critério de medição/remuneração — **o AxysDoc já padronizou isso**; se duas
     fontes remuneram a mesma coisa → convergiu — sinal mais forte)
  4. **itens da composição**
- **Ratio 1 em quase nada.** 1ª vinculação cara (majoritariamente IA); carry-forward barateia as próximas.
- Vale p/ **composições e insumos**.

### 3.4. Equivalências fonte↔SINAPI — com conversão (F insumos / G composições) — 2026-07-18
Direção travada sobre dado real (missmatch elástico das 3 fontes + manual SINAPI de metodologia). Origem: insumo/composição CDHU/FDE; destino: item SINAPI header. **1:1** (insumo) e **1:N** (composição — concretagem).

- **PREMISSA 1 — UNIDADE = UNIDADE.** Só há equivalência entre itens de **mesma natureza física**. O dado prova: **88% (insumo) / 75% (composição)** dos matches fortes já têm unidade igual. Gate do auto-matcher: **mesmo `ti_codigo` + mesma unidade** → candidato; o resto vai a manifesto/curadoria manual, nunca auto.
- **Elástico por TOKEN** (overlap de palavras), **não trigram de string-cheia** — SINAPI é verboso ("...CPVC, *75* G") e o trigram-cheio **subconta** (universo de 87 ins + 32 comp = artefato do método). Matcher devolve **top-N** candidatos; a curadoria **prefere o de mesma unidade** (colapsa divergências artificiais). Auto **nunca** commita cego — app propõe, IA valida, user confirma ou rejeita.
- **COEFICIENTE — 3 estados (campo `classe` elimina a ambiguidade do NULL):**
  - `1` — unidade igual → **direta**.
  - `k > 0` — unidade diferente, **conversão CALCULADA** por **motor determinístico** (não a IA) com memória de cálculo: aço 7850 kg/m³ × área da bitola (cabo 3/8"≈9,5 mm), bisnaga "75 G" = 0,075 kg/un, rendimento tinta (m²/L). A IA **reconhece** a necessidade; o backend **calcula**.
  - `NULL` — unidade diferente, **conversão ESPECIAL** dependente de **quantitativo da obra** que o catálogo não tem (ex.: serviço por **m²** × item por **un** — limpeza de pia). **Associa porque é o mesmo item**, mas coef `NULL`; o user **repassa o quantitativo na bancada** — a app **não assume** a conversão. `NULL`-especial ≠ `NULL`-erro (a `classe` distingue).
- **EQUIPAMENTO (do `Livro_SINAPI_Metodologias_Conceitos.pdf`):** SINAPI guarda o equipamento como **insumo UN (aquisição)** e o custo-hora como **composição CHP/CHI (H)** — `CHP = D+J+M+CMAT+CMOB`, `CHI = D+J+CMOB`, derivados de aquisição×vida-útil×HTA×juros. **Não existe escalar UN→H.** Logo a locação **[H]** da fonte associa **H↔CHP** (mesma unidade, coef 1, **insumo-fonte → composição SINAPI**), **nunca** o insumo-UN de aquisição. O matcher acha o CHP por **descrição + unidade [H↔CHP]**. ⚠️ **Hipótese de código embutido REFUTADA (2026-07-18):** o número no código CDHU (`S.03.000.085678`) é **código interno do CDHU**, não SINAPI — testado em escala, 307 substrings coincidem com códigos SINAPI mas **0% concorda na descrição**. Não há atalho determinístico por código; o casamento é por descrição/unidade.
- **EXCLUSÕES (nunca associar):** **parte-de** (eletroduto × luva de eletroduto — a luva compõe o eletroduto instalado); **locação × aquisição** sem base CHP/CHI; **naturezas distintas** (serviço × material, ex.: sinalização m² × tinta L) salvo substituição explícita de insumo dentro da composição; **equipamentos diferentes** com desc parecida (guindaste × martelete). Exclusão é tratada pelo **script** (regra) ou **removida pela IA**.
- **Schema — 3 tabelas (isolamento + FK real + filtros limpos), sobre o item VIGENTE (identity), NÃO por edição:**
  - **`catalogo.equivalencias_ins`** (INS↔INS) + **`catalogo.equivalencias_cpu`** (CPU↔CPU) — não-MDO, split (o `ins_cpu` unificado foi descartado). **FK real** dos dois lados (acabou o polimórfico). **A malandragem INS→CPU foi DESCARTADA** — é idempotente com CPU↔CPU quando a CPU-fonte espelha o insumo (a decomposição da CPU aglomera outros itens → associar insumo→CPU ocuparia uma CPU muito próxima da própria). `ei_/ec_fator_conversao NUMERIC(12,6)` NULLABLE + `classe` (direta|calculada|especial) + `hash_origem/equivalente` (§9) + `metodo` (TOKEN/ti|IA|MANUAL). N:N nativo (par único, âncora ref indexada).
  - **`catalogo.equivalencias_mo`** (rename de `conversao_mo_fte_to_sinapi`) — só MDO (insumo-fonte→CPU header), **isolada**, determinística: **sem coef, sem hash, sem IA** (back resolve 100% via função+dicionário de sinônimos+preço).

### 3.4.1. Ringue do matcher (restrito → IA → user) — REVISADO 2026-07-22 (prova empírica; substitui 2026-07-19)
Estratégia validada sobre dado. **Léxico curável em JSON:** `data/discriminadores.json` (grupos de tokens mutuamente EXCLUDENTES — ex.: material_base CONCRETO×CERÂMICO×PVC×AÇO — vetam o par mesmo com overlap alto: bloco de concreto ⊄ bloco cerâmico) · `_STOP` (preposições fora — "DE" não pesa). Overlap coefficient + índice invertido.

**DOUTRINA (2026-07-19) + PROVA (2026-07-22): script restrito e burro; IA dignifica o resíduo; homem cura. NADA de passe relaxado** (baixo threshold / 1×1 no universo todo) — o relaxado gera associação que a IA teria que desfazer (trabalho negativo). A cadeia `rodar_vinculacao` roda 4 passes: MDO (`propor_mo`) · atributo/fine-tuning (`propor_atributo`, deferido) · INS (`propor_ins`) · CPU (`propor_cpu`). Removidos da cadeia: `propor_ins_sanitizado` (floor 0,40) e `propor_cpu_1x1` (1×1 universo todo) — marcados DEPRECADO no código.

- **INSUMOS = token puro, SEM funil de tipo** (`propor_ins`, `ti_gate=False`, over≥0,75/shared≥4 + `_vetado`). **REVERTE a posição de 2026-07-19** ("`ti=ti` PONTO"): medido no CDHU, o funil `ti=ti` **bloqueia match legítimo** (o alvo SINAPI está só como `NC`/`EQUIP_AQ↔LOC`, mas é o MESMO item — ex.: `DETECTOR DE FUMAÇA [MAT]→[NC]`, `RÉGUA VIBRADORA [LOC]→[AQ]`) e protege pouco (o token 0,75 + `_vetado` já barra o cross ruim tipo `FURO serviço→TAMPA material`). Dado: S2(sem funil)=213 assoc; dos 48 extras sobre S0(ti) 37 são bons (NC/EQUIP) e só 11 erro provável → o resíduo de erro é da IA+humano.
- **CPUs = SÓ subgrupo análogo, RESTRITO** (`propor_cpu`), sem passe no universo todo. O **mapa de subgrupo é a TABELA `catalogo.equivalencias_subgrupos`** (id×id: `es_fonte_sub_id`→`es_sinapi_sub_id`, FK a `composicoes_subgrupos.sub_id`), **CURADA** (final 2026-07-22: CDHU 448/25 NULL, FDE 198/8; `LIMPEZA` 192→0). **Threshold afrouxado DENTRO do subgrupo = `over≥0,55/shared≥3`** (passe único; o funil garante 0% cross em qualquer overlap, então afrouxar só sobe recall): **434 CDHU / 133 FDE, 0% cross** (era 82/21 a 0,75/4). Prova (mod1×mod2, 2026-07-22): abrir o universo no resíduo = **100% cross** → é só IA. `un-igual`→classe `direta` (auto, ~86%); `un-dif`→`conversão` (IA, onde o ruído do 0,55 se concentra). Subgrupo novo/renomeado no import → `subgrupos_nao_mapeados` **trava (GATE)** → user cura em *Fontes › Associar subgrupos*.
- **Prompt de IA das CPUs (2.4):** vai **a composição origem/alvo**, deixando explícito que **quantidade e composição NÃO são determinantes** (engenharia não é ciência exata, difere por metodologia) mas **evidenciam** que é o mesmo serviço-alvo.
  - **Âncora generalizada `*_ref_fonte` ∈ {SINAPI, SICRO}** (headers da Lei 14.133) — uma tabela serve os dois, sem `_sicro_*` duplicado; bridge SINAPI↔SICRO = só uma linha (`ref=SICRO, fte_codigo=SINAPI`).
  - `item_id` **polimórfico** (INS ou CPU por `*_tipo`) → integridade via app (o lado ref do MDO tem FK física a `composicoes`).
  - **Sem tabela de conversores** — o "quadro" (tempo/densidade/CHP) é **sugestão no código**, o valor mora na linha.
  - ⚠️ **`insumos_equivalencias` (legada)** = feature MANUAL bidirecional any↔any (viva, 0 linhas). **Será absorvida/redesenhada** na `equivalencias_ins_cpu` (`metodo=MANUAL`, ancorada no header — o any↔any cai, pelo 14.133 tudo passa pelo header) na fase da tela.

---

## 4. Ratios (heurística de match)

Padrão: cada amarra combina sinais em `ratio_total ∈ [0,1]` (média ponderada, pesos ajustáveis por round).
Ratio alto = pré-selecionado; **nunca** aceito sem IA + user. Sinais reusáveis:
- **descrição** (normalizada; p/ MDO, só a **função**);
- **preço** (R$/h por UF — validador forte de MDO);
- **grupo/subgrupo**; **itens da composição**; **descritivo-fonte (AxysDoc)** — p/ substituições.

---

## 5. Schema (proposta)

Nomes seguem a convenção (prefixo = conceito). Vigência **por edição**. Integridade rígida no banco (FKs
compostas com a fonte/edição — dependem de `uq_edicoes_id_fte`, `uq_insumos_id_fte`,
`uq_composicoes_id_fte_edi`).

### 5.1. `catalogo.composicoes_mapeamento_mdo` (H↔MÊS) — **R1**
```
cmm_id            IDENTITY PK
cmm_edi_id        NOT NULL   -- edição SINAPI onde o par vale
cmm_fte_id        NOT NULL   -- SINAPI (p/ FK composta)
cmm_cmp_horista_id    NOT NULL   -- CPU [H]
cmm_cmp_mensalista_id NOT NULL   -- CPU [MÊS]
cmm_fator         NUMERIC(14,10) NOT NULL   -- H→MÊS (ex.: 1/220); explícito/editável
cmm_status        TEXT NOT NULL DEFAULT 'pendente'  -- pendente|ia_ok|confirmado|sem_par|revisar
cmm_score         NUMERIC(5,4)              -- ratio do match (0..1), p/ exibição
cmm_ia_nota       TEXT                      -- retorno/observação da IA
cmm_obs           TEXT
cmm_criado_em/por, cmm_atualizado_em/por
FK (cmm_edi_id,cmm_fte_id)->edicoes ; FK (cmp_horista_id,fte,edi)->composicoes ; idem mensalista
CHECK horista <> mensalista ; UNIQUE (cmm_edi_id, cmm_cmp_horista_id)
```

### 5.2. `catalogo.conversao_mo_fte_to_sinapi` (MDO fonte→SINAPI) — **R2**
```
origem: insumo MDO da fonte (ins_id,fte,edi) ; alvo: composição SINAPI MDO (cmp_id,SINAPI,edi_header)
+ status/score(ratio_desc,ratio_preco,ratio_total)/ia_nota ; vigência por edição ; 1:1 curado
```

### 5.3. Substituições — **R3** (schema completo já validado)
`catalogo.insumos_substituicoes` (1:1) · `catalogo.composicoes_substituicoes` (+`_itens`, 1:N).
Header (fte+edi+item) → sub (fte+edi+item/combinação). Ver §11 do doc de origem (integridade rígida,
FKs compostas, `csi_coef NUMERIC(14,10)`).

---

## 6. Plano de ringue

| Round | Entrega | Depende |
|---|---|---|
| **R0** | Fundação: schemas · edição-header · máquina de estado (pendente/ia_ok/confirmado/sem_equivalente/revisar) · carry-forward-por-ID + diff · normalizador de funções (extraído do buscador MDO CDHU/FDE) | — |
| **R1** | **H↔MÊS**: matcher · prompt IA (CPUs MDO + pares) · **tela de Conciliação** + modal (edição·nº·fator) · delta no reimport | R0 |
| **R2** | **MDO fonte→SINAPI**: matcher por função (dicionário) + categoria-aware · validador `ratio_desc+ratio_preço` · encadeia H→MÊS | R1 |
| **R3** | **Substituições**: 4-frentes de ratio (desc·grupo/subgrupo·descritivo-AxysDoc·itens) · 1:1 insumo / 1:N comp · comp+insumos | R2 |
| **R4** | Costura no **Dados (3)**: surface do diff combinado · publicar exige *revisado* (não 100% vinculado) · reimport marca impactados · ordem SINAPI→demais | R1-R3 |
| **R5** | Refino: vinculação manual · pesos de ratio · conector IA (auto vs get_md→put_md) · relatórios de cobertura | R4 |

**Decisões abertas (anotadas p/ os rounds):** default da edição-header (última publicada + override);
degradação graciosa do ratio_preço quando falta UF; pesos iniciais dos ratios.

---

## 7. Limites (o que NÃO faz)
Não substitui curadoria humana · não recalcula estrutura oficial das fontes · não cria equivalência geral
entre todas as fontes · não elimina revisão quando a edição muda · não recria vínculos automaticamente no
import (só **marca** impactados) · H↔MÊS não cria/mexe custo oficial (só registra o par + fator).

---

## 8. Arquitetura de IA — conector agnóstico + auto on/off (2026-07-18)

Discussão fechada (ChatGPT propôs agente OpenAI pesado; adotamos o núcleo agêntico, recusamos a escala e a
obrigatoriedade de API paga).

- **Um conector `AIProvider`/gateway** serve **CTC descritivo E vinculações**. Provider por env
  (Anthropic/OpenAI/Gemini/Ollama) — troca sem tocar o domínio. Centraliza key/timeout/retry/custo/redaction/
  versão. **Nunca** key em log ou banco em texto puro. É a **materialização do `AXYS_CPU_DESC_MODO`**
  (`CADERNO_TECNICO_AXYS §6b`), hoje `_ia_auto_preencher = NotImplementedError`.
- **Toggle `auto on/off`:** **OFF (default)** = o request **para na borda**, o `.md` fica no **storage** →
  **get_md/put_md, SEM API paga** (honra [[feedback_sem_apis_pagas]] como default, não como proibição).
  **ON** = o conector chama o provider por token.
- **DETERMINÍSTICO-PRIMEIRO (aula do H↔MÊS):** resolve o máximo no **dado** (tipo+unidade, código SINAPI
  embutido, motor de conversão); a IA fica no **resíduo ambíguo**. O **loop agêntico multi-turn** (só útil
  p/ investigação 1:N, tipo concretagem) **não é obrigatório** e só entra **se provar necessário**. API paga
  = **upgrade opcional de conveniência**, jamais requisito. A IA **não** recebe SQL livre nem conexão —
  **ferramentas estreitas e tipadas**; o backend controla dado/cálculo/integridade/autorização.
- **Dataset de treino (parte do treinamento já começa na curadoria):** cada revisão humana
  (proposta → decisão → correção → motivo, + prompt/modelo/versão) é **coletada desde o 1º ciclo** — barato,
  é auditoria. **Fine-tuning fica EM ABERTO (provável descarte):** no volume real (curado 1×/edição +
  carry-forward por ID estável), **prompt bom + guardas determinísticas + revisão humana** já entregam
  consistência. Não treinar p/ memorizar catálogo/preço/edição.

## 9. Revalidação na reimportação — hash + manutenções SINAPI

A equivalência é **persistida sobre a foto atual** do banco. Importar nova edição (fonte X **ou** SINAPI
header) **revalida** os vínculos afetados (não corrige sozinho — marca `revisar`).

- **Gatilho universal = HASH da descrição** do item-base: mudou o hash → o vínculo que o referencia vai a
  `revisar`.
- **SINAPI vai ALÉM do hash:** a Caixa publica o **relatório de manutenções** (itens incluídos/alterados/
  desativados por edição) — sinal **mais rico e barato** que o diff de hash, aponta exatamente os CPUs/insumos
  tocados. Usar **manutenções quando existir + hash como fallback universal** (demais fontes).

## 10. Disclaimer canônico (módulo ativo)

Texto **literal** na tela de conversão entre-fontes do Ativo:

> A conversão entre-fontes é algo que é persistido sobre o estado atual do banco de dados e representa
> vínculos com as edições mais vigentes disponíveis da fonte-base para com a SINAPI da mesma época.
> Recomendamos revisão cautelosa sobre as associações diretas e rigorosa sobre as associações com
> necessidade de conversão. A Axys Engenharia e Tecnologia LTDA não se responsabiliza pelas planilhas
> elaboradas, sendo que, atua pura e simplesmente como software/ferramenta de suporte.
