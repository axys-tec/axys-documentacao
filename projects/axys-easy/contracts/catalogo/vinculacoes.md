# Contrato de Vinculações Intra-Fontes

> **Status:** Contrato aprovado. **§5/§6 conferidas contra o banco de PROD em 2026-09-21** — o que
> está lá é o que existe; o resto do documento é direção.

---

## ESTADO — ler antes de qualquer decisão (congelado 2026-09-21)

**1. "Produção" é HOMOLOGAÇÃO.** O ambiente de prod está em homologação de fato: **toda escrita lá é
teste**. Trocar script, reimportar, recarregar — **os resultados não mudam**, porque a entrada é a mesma
fonte oficial e o processamento é determinístico. Não há dado de cliente a preservar nestas tabelas.
Consequência prática: **mexer aqui não é operação de risco**, é iteração. Este parágrafo existe para que
ninguém (humano ou agente) trave uma decisão por medo de "estar em produção".

**2. O que está populado está PROVISORIAMENTE CONGELADO e NÃO CURADO.**

| tabela | linhas | status |
|---|---|---|
| `equivalencias_ins` | 357 | 100% `pendente` |
| `equivalencias_cpu` | 589 | 100% `pendente` |
| `equivalencias_mo` | 71 | 100% `pendente` |

**Zero `confirmado` nas três.** Isso não é proposta parcialmente aprovada — é **saída bruta de matcher,
sem uma única decisão humana**. Não tem valor de verdade: é palpite de máquina esperando curadoria.

Duas consequências que se deduzem disto e valem mais que as tabelas:
- O consumo (`equivalencias.equivalente_ins`, `preco_mo._mo_sinapi_mes`) exige `confirmado`. Logo a
  **conversão inter-fontes da bancada e a rotação MDO mensalista estão desligadas de fato em produção.**
  Não é bug: é curadoria que nunca foi feita.
- **Descartar e repopular essas 1.017 linhas não perde nada.** Isso libera o refactor (§13) de qualquer
  obrigação de migração de dado — o que normalmente é a parte cara, aqui é `TRUNCATE` e rodar de novo.
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
Publicar exige a conciliação **REVISADA**, não 100% vinculada. Trava-se a publicação se houver **delta
pendente de revisão**, nunca por "faltar vínculo".

⚠️ **REVOGADO (2026-09-22):** a redação anterior chamava `sem_equivalente` de "estado terminal válido".
**Não é estado — é ausência de linha.** Se não há equivalente, não se registra nada; não se guarda
ausência. O `DELETE` que a curadoria em tela faz está **CERTO e fica**.
**Consequência assumida:** o matcher exclui do universo apenas quem TEM linha, então um par rejeitado
volta a ser proposto no import seguinte. Retrabalho conhecido e aceito — não é defeito a corrigir.

### 1.2. Ordem (produção)
Importa-se **SINAPI 1..n-1 primeiro** (gera o header e o H↔MÊS), depois CDHU/FDE contra o header. Dentro do
não-SINAPI: **H↔MÊS deve existir antes** de MDO fonte→SINAPI (o 2º salto usa `composicoes_mapeamento_mdo`).

### 1.3. Edição-header — ❌ ABANDONADO
A proposta era toda vinculação cross-fonte referenciar uma **edição SINAPI header** (default: última
publicada, override manual). **Não foi construído e não deve ser**: a equivalência é identity-level
(§5), então não há edição a apontar. O pipeline **não ganhou input novo nenhum**.

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

Estados do vínculo **(reais, conferidos no código)**: `pendente` → `confirmado` · `revisar` (delta
reabriu) · `refutado` (IA/usuário rejeitou — fica com `ativo=FALSE`, **não some**, para não ser
reproposto). `ia_ok` **nunca existiu**. `sem_equivalente` **não é estado** — a curadoria em tela **APAGA a linha**
(`aplicar_manifesto_vinculacao`, `curar_ins`), e isso está **CERTO** (§1.1): ausência não se registra.
**Quem diverge é o caminho da IA** (`importar_associacoes`), que marca `refutado` + `ativo=FALSE` — tem
de passar a apagar também.

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
- **Fator:** a coluna `cmm_qtd_h_mes` **não existe**. O 220 mora em `catalogo.parametros_normativos`,
  código **`JORNADA_H_MES`**, com vigência *as-of* em JSONB — melhor que a proposta: boletim antigo pega
  o fator da época pela data da edição quando a reforma trabalhista mudar a jornada (§5.3).

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
  - ⚠️ **`insumos_equivalencias` (legada)** = feature MANUAL bidirecional any↔any. **0 linhas, mas LIGADA na UI** — ver §5.4 (a `equivalencias_ins_cpu` citada aqui nunca existiu; virou o par `equivalencias_ins`/`_cpu`). **Destino DECIDIDO (2026-09-21): sobra.** As telas param de usá-la e a tabela é removida — o fonte→fonte vive nas três tabelas canônicas (§13).

---

## 4. Ratios (heurística de match)

Padrão: cada amarra combina sinais em `ratio_total ∈ [0,1]` (média ponderada, pesos ajustáveis por round).
Ratio alto = pré-selecionado; **nunca** aceito sem IA + user. Sinais reusáveis:
- **descrição** (normalizada; p/ MDO, só a **função**);
- **preço** (R$/h por UF — validador forte de MDO);
- **grupo/subgrupo**; **itens da composição**; **descritivo-fonte (AxysDoc)** — p/ substituições.

---

## 5. Schema — **CONSTRUÍDO** (conferido contra o banco de PROD em 2026-09-21)

Nomes seguem a convenção (prefixo = conceito). **Seis tabelas.** O que vale é esta seção; o
`schema.sql` é a foto e o código implementa.

> **Correção de rumo que o texto antigo escondia:** a proposta original amarrava tudo a **vigência por
> edição** (FKs compostas com fonte/edição). O que se construiu é **identity-level**: a equivalência é
> um fato sobre o ITEM, não sobre a edição — o id é estável "pra todo o sempre" (get-or-create), a
> revalidação é por **hash da descrição**, e um item inativado **mantém** o vínculo (auditoria e
> regressão). Vigência-por-edição foi abandonada, não adiada.

| tabela | linhas (prod) | amarra | direção |
|---|---|---|---|
| `catalogo.equivalencias_ins` | 357 | insumo-fonte ↔ insumo-header (não-MDO) | fonte → SINAPI |
| `catalogo.equivalencias_cpu` | 589 | composição-fonte ↔ composição-header (não-MDO) | fonte → SINAPI |
| `catalogo.equivalencias_mo` | 71 | insumo-MO da fonte → **composição** MDO do header `[H]` | fonte → SINAPI |
| `catalogo.composicoes_mapeamento_mdo` | 94 | CPU MDO **[H] ↔ [MÊS]**, N:1 | intra-SINAPI |
| `catalogo.equivalencias_subgrupos` | 679 | subgrupo-fonte → subgrupo SINAPI — **funil** do match de CPU, não associação de item | fonte → SINAPI |
| `catalogo.insumos_equivalencias` | 0 | legada manual `any↔any` — **viva e ligada na UI** (§5.4) | bidirecional |

### 5.1. `catalogo.equivalencias_ins` + `catalogo.equivalencias_cpu` (não-MDO)
Gêmeas (mesmas colunas, trocando `ins`/`cmp`; prefixos `ei_`/`ec_`):
```
{ei|ec}_id  IDENTITY PK
{ei|ec}_ref_fonte  TEXT  CHECK IN ('SINAPI','SICRO')   -- âncora (Lei 14.133)
{ei|ec}_ref_{ins|cmp}_id  BIGINT  FK REAL              -- item do header
{ei|ec}_fte_codigo  TEXT                               -- 'CDHU' | 'FDE' | ...
{ei|ec}_fte_{ins|cmp}_id  BIGINT  FK REAL              -- item da fonte
{ei|ec}_classe  TEXT  CHECK IN ('direta','calculada','especial')
{ei|ec}_fator_conversao  NUMERIC(12,6)                 -- 1=direta · k=calculada · NULL=especial
{ei|ec}_status  TEXT DEFAULT 'pendente'                -- pendente|confirmado|revisar|refutado|sem_equivalente
{ei|ec}_score  NUMERIC(4,3) · {ei|ec}_metodo TEXT      -- 'TOKEN'|'TOKEN/ti'|'TOKEN/grupo'|'IA'|'MANUAL'
{ei|ec}_hash_origem, {ei|ec}_hash_equivalente  TEXT    -- revalidação §9 (sha1[:16] da desc normalizada)
{ei|ec}_observacao TEXT · {ei|ec}_ativo BOOLEAN DEFAULT TRUE
{ei|ec}_criado_em/por, {ei|ec}_atualizado_em/por
UNIQUE (ref_fonte, ref_id, fte_codigo, fte_id)         -- o PAR é único; N:N nativo
```
**Só `status='confirmado' AND ativo` é consumido** pela bancada (`equivalencias.equivalente_ins`).

### 5.2. `catalogo.equivalencias_mo` (MDO fonte→SINAPI)
Rename de `conversao_mo_fte_to_sinapi`. **Isolada e determinística: sem edição, sem hash, sem coef, sem IA.**
```
mo_id IDENTITY PK · mo_ref_fonte ('SINAPI'|'SICRO') · mo_ref_tipo CHAR(3) DEFAULT 'CPU'
mo_ref_item_id BIGINT  FK FÍSICA -> composicoes(cmp_id)   -- alvo: CPU '...COM ENCARGOS COMPLEMENTARES' [H]
mo_fte_codigo TEXT · mo_fte_tipo CHAR(3) DEFAULT 'INS' · mo_fte_item_id BIGINT  -- FK via app (fonte variável)
mo_status ('confirmado'|'sem_equivalente'|'pendente') · mo_score NUMERIC(4,3) · mo_obs
UNIQUE (mo_ref_fonte, mo_fte_codigo, mo_fte_item_id)      -- 1 alvo por função da fonte
```

### 5.3. `catalogo.composicoes_mapeamento_mdo` (H↔MÊS, intra-SINAPI)
**Ficou MUITO mais magra que a proposta — e melhor.** A proposta previa `cmm_edi_id`, `cmm_fte_id`,
`cmm_fator`, `cmm_status`, `cmm_score`, `cmm_ia_nota`. Nada disso existe: o H↔MÊS virou **100%
determinístico** (§3.1), então não há status nem score a guardar, e não é por edição.
```
cmm_id IDENTITY PK · cmm_cmp_id_h · cmm_cmp_id_mes · cmm_criado_em/por, cmm_atualizado_em/por
```
**O fator saiu da tabela** para `catalogo.parametros_normativos`, código **`JORNADA_H_MES`**, com
vigência *as-of* em JSONB (`[{"valor":220,"inicio":"1900-01-01"}]`). Quando a reforma trabalhista
reduzir a jornada, acrescenta-se `{inicio, 200}` e **boletim antigo continua pegando o fator da época
pela data da edição** — que era exatamente a intenção do "fator explícito/editável", resolvida melhor.

**Encadeamento (`ativo/preco_mo.py::_mo_sinapi_mes`):** insumo-MO da fonte → `equivalencias_mo`
(exige `mo_status='confirmado'`) → CPU SINAPI `[H]` → `composicoes_mapeamento_mdo` → CPU SINAPI `[MÊS]`.

### 5.4. `catalogo.insumos_equivalencias` (legada) — VIVA, não órfã
0 linhas, mas **não é código morto**: `insumos_service.get_equivalencias / criar_equivalencia /
remover_equivalencia`, rotas POST/DELETE, a lista na tela de edição do insumo e a coluna **"Equiv."**
nas listagens de insumo do catálogo E da consulta do ativo. Fora do alcance da credencial do Easy Mobile.
```
ie_id · ie_ins_id_origem · ie_ins_id_equivalente · ie_tipo_equivalencia · ie_score
ie_metodo · ie_observacao · ie_ativo · auditoria
```
É `any↔any` bidirecional — **duplica conceito** com `equivalencias_ins`.

**DECIDIDO (2026-09-21): a tabela SOBRA.** Só devem existir `equivalencias_ins`, `_cpu` e `_mo` (§13.1).
Ordem obrigatória: **primeiro as telas param de usá-la**, depois o `DROP`. Enquanto a UI referenciar,
ela fica — derrubar antes quebra a tela de edição do insumo e a coluna "Equiv." das duas listagens.

### 5.5. Alvo do refactor
Ver **§13 — Contrato de refactor (CONGELADO)**. O esboço anterior (`pk · ins_ref · ins_equiv · coef`)
ficou superado: não resolvia o par espelhado nem o caso polimórfico do MDO.

### 5.6. Substituições — **NÃO CONSTRUÍDO**
`insumos_substituicoes` e `composicoes_substituicoes(+_itens)` **não existem no banco**. O R3 nunca saiu
do papel. Mantido como direção, não como schema vigente.

---

## 6. Plano de ringue — estado real

| Round | Entrega | Estado |
|---|---|---|
| **R0** | Fundação: schemas · máquina de estado · carry-forward-por-ID + diff · normalizador de funções | ✅ feito (sem edição-header: virou identity-level) |
| **R1** | **H↔MÊS**: pareamento determinístico + tela de Conciliação | ✅ feito — 94/94, sem IA (§3.1) |
| **R2** | **MDO fonte→SINAPI**: matcher por função + dicionário de sinônimos + nível | ✅ feito — `propor_mo`, 71 linhas |
| **R3** | **Substituições**: 4 frentes de ratio · 1:1 insumo / 1:N comp | ❌ não construído |
| **R4** | Costura no Dados (3): gate no import · publicar exige *revisado* | 🟡 parcial — gate roda (`gate_equivalencias`), mas o reimport **só revalida o lado da FONTE** (§9.1) |
| **R5** | Refino: vinculação manual · pesos · conector IA · cobertura | 🟡 parcial — telas `/grupos`, `/associar-mdo`, `/associar-ins-cpu` existem; conector IA = `get_md/put_md` |

### 6.1. Pendências abertas (2026-09-21)
- **Tabs por status.** `confirmado` / `pendente` / `revisar` têm de ser **telas/abas separadas**. Não existe.
- **`revalidar_hashes` só olha `confirmado`.** Proposta: estender a `pendente` — proposta não-curada não
  tem valor a preservar, então apaga e deixa o matcher repropor (o Desvio 1 **não** se aplica a ela).
- **Matcher propõe item morto.** ⚠️ O predicado correto **NÃO é `ins_ativo`**: esse flag é decidido no
  **PUBLICAR**, e o matcher roda no estágio Dados com a edição ainda RASCUNHO — filtrar por ele
  **excluiria o item reativado** e **não pegaria o inativado**. O certo é **presença na edição sendo
  importada** (`insumos_preco.pri_edi_id` / `composicoes_custo.cc_edi_id`), como faz `aplicar_diff_edicao`.
- **Cobertura da fonte favorita na bancada:** hoje converte pela metade em silêncio quando a ponte não
  cobre. A favorita precisa **declarar cobertura** antes da escolha.

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
  desativados por edição) — sinal **mais rico e barato** que o diff de hash. **NÃO IMPLEMENTADO:** o arquivo
  é feito upload no import e não é lido por ninguém. Na prática o hash é o único gatilho.
- **O diff já está no banco e ninguém usa para isto.** `aplicar_diff_edicao` popula `insumos_historico` /
  `composicoes_historico` em TODO import, com `CRIACAO|ALTERACAO|INATIVACAO|REATIVACAO` e, nas composições,
  distinguindo **`ALTERACAO_CABECALHO`** (texto) de **`ALTERACAO_ITENS`** (coeficiente). É a fonte pronta
  para dimensionar e dirigir a curadoria — ver §10.

### 9.1. ⚠️ Só o lado da FONTE revalida (buraco conhecido)
`rodar_vinculacao` devolve `{"skip": "ancora"}` quando a fonte é SINAPI, e o gate do import pula a âncora.
Consequência: **mudou a descrição de um item SINAPI, nenhum vínculo é revalidado** — o CDHU só reavalia
quando o CDHU for reimportado. A §9 pede os dois lados. Pesa porque a SINAPI é a fonte que mais muda
(§10) e é a âncora de todas — cada descrição dela que muda deveria reabrir vínculo em `n−1` fontes.

### 9.2. Revalidação só alcança `confirmado`
`revalidar_hashes` filtra `status='confirmado'`. Como em PROD não há nenhum, hoje ela roda no vazio.
Vínculo em `pendente` envelhece em silêncio.

## 10. Volatilidade das fontes — medido em PROD (2026-09-21)

Dimensiona o custo real da curadoria-no-import. Medido com
`z_scripts_apoio/analise_associacoes/churn_edicao.py` (3 edições × 3 fontes = 6 transições) sobre
`insumos_historico`/`composicoes_historico`. **Só texto conta** — preço e `ALTERACAO_ITENS` não reabrem
vínculo (§10.1).

| | NOVOS (curar) | TROCA_REAL | a curar | dispensado |
|---|---|---|---|---|
| INS/SINAPI | 82 | 0 | 82 | 108 |
| INS/CDHU | 14 | 54 | 68 | 26 |
| INS/FDE | 52 | 30 | 82 | 17 |
| CPU/SINAPI | 230 | 41 | 271 | 137 |
| CPU/CDHU | 14 | 7 | 21 | 25 |
| CPU/FDE | 103 | 1 | 104 | 36 |
| **TOTAL** | **495** | **133** | **628** | 349 |

**~105 itens por transição.** ⚠️ **Janela de 3 edições — não é constante.** Na série completa as medianas
são CDHU 0,42% · FDE 0,54% · SINAPI 1,13%, com picos reais (SINAPI 04-25 = 7,6%, 736 CPUs tocadas). Usar
como ordem de grandeza, nunca como previsão.

É isto que torna "curadoria dentro do import" sustentável: a bronca é o
**primeiro** import de cada fonte (3.562 CDHU · 3.170 FDE · 9.474 SINAPI); dali em diante é remendo.
A SINAPI gera 312 dos 495 novos — é o motor do volume em qualquer desenho.

### 10.1. Os 4 baldes da reimportação (regra de decisão)
| evento | ação | por quê |
|---|---|---|
| INATIVADO / REATIVADO | **dispensado** | o vínculo permanece — auditoria e regressão de orçamento |
| NOVO | **CURAR** | item sem par: o único trabalho estrutural |
| descrição mudou | **triagem** (§10.2) | nomenclatura dispensa; produto trocado, não |
| **unidade** mudou | **AJUSTAR FATOR** | o coeficiente de conversão tem de acompanhar |

Troca de unidade é **raríssima e real**: 15 casos em todo o histórico (8 ins + 7 cpu) — `KG→L`,
`M2→UN`, `ROLO→M`, `UN→CJ`. Zero nas últimas 3 edições. O balde existe por causa desses 15.

### 10.2. Triagem do balde de texto — 81% é ruído (`classifica_churn.py`)
De 704 mudanças de descrição, só **133 (19%)** são troca real:

| classe | n | |
|---|---|---|
| `CARIMBO_SINAPI` — `AF_MM/AAAA`, variante `_PE`/`_PS` | 290 | dispensado |
| `TIMESTAMP_FDE` — rodapé do PDF colado na descrição | 173 | dispensado — **era BUG, corrigido** |
| `ESPEC_ADICIONAL` — a nova contém a antiga | 101 | dispensado |
| `MARCAS` / `FORMATACAO` | 7 | dispensado |
| **`TROCA_REAL`** | **133** | **CURAR** |

**Não dá para dispensar o balde de texto em bloco.** Exemplos reais de troca de produto sob o mesmo
código: `LUMINÁRIA FLUORESCENTE COMPACTA 18/26W → LED` (12×, CDHU) · `CHAPA Nº 20 GALVANIZADO → Nº 24
SEM PINTURA` (6×) · `BLOCO 14X19X39, PALHETA E ARGAMASSA COM PREPARO EM BETONEIRA → 14X19X39 FBK = 6
MPA, PALHETA` (SINAPI) · `...(EXCETO PERFIL) OU LAJE SOBRE SOLO` → escopo removido. Se passassem como
dispensados, o vínculo apontaria o produto errado e o preço sairia errado na bancada, em silêncio.

### 10.3. Ruído que se conserta na origem
O `TIMESTAMP_FDE` era o rodapé `dd/mm/aaaa hh:mm:ss Página: N de M` da Tabela Sintética entrando na
descrição do último serviço de cada página (78 CPUs em prod). Escapava dos dois filtros do parser:
`is_header_or_footer` casa por `startswith` e o carimbo está no **início** da linha (o `Página:` no
meio), e o corte de `x0 >= 450` não pega o carimbo, que fica em x0≈58. Como a hora muda a cada
captura, **reabria o vínculo desses itens em toda edição, para sempre**.
Corrigido em `fde_novo/fde_sintetica_pdf_parser.py` (guard por `search`) + dado curado por
`z_scripts_apoio/manutencao/limpa_carimbo_fde.py`. **Lição de contrato: ruído periódico da fonte é
gerador perpétuo de falso-delta — conserta-se na origem, nunca no matcher.**

---

## 11. Associação é IGUALDADE, não analogia (2026-09-21)

> Comprar uma Havaiana 351020 verde **=** comprar uma 351020 da Havaiana, cor verde. Com um coeficiente
> quando a embalagem difere: `tinta esmalte GL = 3,6 L de tinta esmalte`.

Um item SINAPI **análogo** a 10 itens CDHU **não gera associação nenhuma**. Analogia não é igualdade.

### 11.1. ⚠️ Simétrica, mas NÃO transitiva — e por isso NÃO HÁ PONTE
"Igualdade" aqui é **rigor do match** (item igual, não parecido), **não** a propriedade matemática.
A relação é reflexiva e simétrica mas **não transitiva** — em matemática, uma *relação de tolerância*,
não uma relação de equivalência.

**Por quê:** um serviço CDHU pode ser igual ao SINAPI por um critério e igual ao FDE por outro, **sem
que FDE e SINAPI sejam iguais entre si**. Os critérios são avaliados **par a par**. A maior parte
converge; a exceção existe e é real.

Três consequências que governam o desenho:
1. **`A=B` e `A=C` não afirmam NADA sobre `B` e `C`.** O "triângulo inconsistente" não é contradição —
   é estado legítimo. Não há o que o banco deva impedir.
2. **PROIBIDA a ponte/pivô.** Responder `CDHU→FDE` saltando pelo SINAPI **inventa** uma equivalência que
   ninguém afirmou. Ou existe linha direta, ou a resposta é "não há equivalente". (Dívida: o salto duplo
   está vivo em `equivalencias.py` — §13.5.)
3. **Classes/grupos de equivalência estariam ERRADOS.** Agrupar forçaria transitividade, juntando FDE e
   SINAPI só porque ambos batem com CDHU — o modelo afirmando o que o engenheiro não afirmou. Modelo de
   **pares**, portanto, não por limitação: por correção.

Consequência prática (curadoria Maicon, 1.218 pares): **474 (39%)** estavam num leque 1→N — um genérico
da fonte apontando N específicos do header (`CHAPA DE AÇO ASTM A-36 DE 1/4"` → 17 chapas SINAPI de
espessuras diferentes). Pela regra, **não entram**; no máximo sobrevive o **um** que é de fato igual
(a chapa de 1/4" é o código 1330). Isto também dispensa qualquer heurística de desempate: o consumo
(`equivalencias.equivalente_ins`) faz `LIMIT 1` **sem `ORDER BY`**, e com leque no banco escolheria uma
espessura arbitrária. Sem leque, não há o que desempatar.

## 12. Fonte→fonte direto — DECIDIDO, para o refactor (2026-09-21)

A ponte via SINAPI **não basta**: a bancada permite favoritar uma fonte com conversão de
insumos/composições, e não pode oferecer favorita cuja conversão dependa do salto pelo header — o que
não tem representante no SINAPI se perde no caminho.

**Decisão: vínculo fonte→fonte direto**, rodado por matcher + IA curada, **endurecido**, partindo sempre
de: **NOVOS / não-associados anteriores × remanescentes de associação / não-associados anteriores,
fonte × fonte.**

### 12.1. O custo `n(n−1)/2` NÃO é obrigatório — quem é favoritável se escolhe

Sem transitividade nenhum par pode ser **derivado** — mas daí não segue que todos tenham de **existir**.
**Quantos pares existem é decisão de produto.**

- **`TODAS → SINAPI` é LEI** (14.133). Não se escolhe. Idem SICRO para infraestrutura.
- **`TODAS → TODAS` é cosmético de valor.** Só se paga onde vale.

O eixo é o **destino**, não o par: marca-se a fonte que pode ser alvo, e todas as outras apontam para
ela. O enunciado ao usuário é **"{todas} → CDHU habilitado"**, nunca "CDHU→FDE não habilitado".

**`catalogo.fontes.fte_favoritavel BOOLEAN NOT NULL DEFAULT FALSE`** — próximo membro da família de
governança que já existe ali (`fte_ativa`, `fte_tem_catalogo_insumos`, `fte_catalogos_continuos`,
`fte_permite_manipular_dados`). **Zero objeto novo:** o par está habilitado **se e só se** uma das pontas
é favoritável — logo a "tabela de pares habilitados" é derivável e **não deve existir**.

- **SINAPI e SICRO são `TRUE` por lei**, não por escolha. Não se desmarca.
- **NÃO existe gate de cobertura. A flag não obriga a popular nada.** Se não há associação, é
  `sem equivalente` — ponto. Cobertura é **maturidade, não pré-requisito**: nascer com 10 associações e
  chegar a 99% com o tempo, fine-tuning e modelos melhores é o caminho genuíno, não uma falha a corrigir
  antes de ligar. O que foi curado por engenheiro, para engenheiro, já fica disponível desde a primeira
  linha. Qualquer trava de completude aqui só serviria para impedir que a coisa comece.
- **Não confundir as duas metades:** `fte_favoritavel` (catálogo) = *pode* ser escolhida; **favorita**
  (orçamento) = a que *foi* escolhida, e já existe como `ativo.orcamento_parametros.opa_default`.

**O que favoritar significa:** tudo que está na bancada — composições **e seus insumos** — deve
convergir ao máximo para aquela fonte-base. Não é filtro de exibição; é destino de conversão.

**Custo real = |favoritáveis| × (n−1)**, linear em `n`, não quadrático:

| | n=3 | n=5 (SBC + ORSE) | n=10 |
|---|---|---|---|
| só âncora (lei) | 2 | 4 | 9 |
| âncora + 1 favoritável extra | 4 | 8 | 18 |
| `TODAS→TODAS` (não se fará) | 3 | 10 | 45 |

### 12.2. O que a flag acrescenta (e o que já funciona)
**Rotacionar para outra fonte JÁ funciona e foi testado.** O caminho é dinâmico: a favorita sai do que
estiver marcado no Fontes tab (`orcamento_service.py:592` e `:1214` — `next(... if p.get("favorita"))`).

O `favorita="SINAPI"` de `:569`/`:1127`/`:1212` **não é resquício a remover**: está confinado ao ramo
**MENSALISTA**, e ali o SINAPI é obrigatório por construção — o par H↔MÊS
(`composicoes_mapeamento_mdo`) só existe no SINAPI. Rotação de regime passa pelo SINAPI por natureza,
não por descuido.

Logo `fte_favoritavel` **não destrava** a rotação. O que ela acrescenta é o que hoje não existe:
**declarar quais fontes são alvo legítimo**. Hoje qualquer fonte pode ser marcada favorita no Fontes
tab sem que ninguém tenha se comprometido a manter equivalências contra ela — e a conversão sai pela
metade, em silêncio, sem a tela saber distinguir "não habilitado" de "sem equivalente".

---

## 13. Contrato de refactor — **CONGELADO, NÃO EXECUTÁVEL** (2026-09-21)

> **Natureza deste capítulo.** Não é plano de execução. É o **alvo congelado**: o desenho acordado, com as
> premissas que o sustentam e os fatos que o justificam. **Nada aqui se aplica** enquanto não houver
> (a) check de sanidade completo e (b) objetivo/alvo completo — incluindo a arquitetura de import, que
> ainda não foi discutida. O refactor de verdade nasce depois disso; isto é o que ele terá de honrar.

### 13.1. Premissas (assumidas como verdade)

1. **Associação é IGUALDADE, não analogia** (§11). Um item análogo a N outros não gera associação.
2. **Igualdade é simétrica.** `A = B` e `B = A` são **o mesmo fato** — logo, uma linha, nunca duas.
3. **Vínculo fonte→fonte direto existe** (§12), sem depender do pulo pelo header.
4. **Só três tabelas**: `equivalencias_ins`, `equivalencias_cpu`, `equivalencias_mo`. Elas suportam
   SINAPI→fonte, SICRO→fonte e fonte→fonte. Sendo fonte→fonte, o resto é caso particular.
5. **Cada tabela é dona de UM tipo de coisa.** Sem sobreposição — ver 13.4.
6. **MDO do SINAPI é composição; MDO das fontes é insumo.** Essa assimetria é a razão de `mo` existir
   separada, e é o que o refactor tem de destravar.
7. **MO não tem fator de conversão.** Os dois lados são sempre `[H]`. O único fator do MDO é o H→MÊS, e
   mora em `parametros_normativos.JORNADA_H_MES` (§5.3).
8. **O dado atual é descartável** (ver ESTADO, topo). Sem migração a preservar.

### 13.2. Considerandos (fatos medidos, não opinião)

- **`ck_*_ref_fonte CHECK IN ('SINAPI','SICRO')` existe nas TRÊS tabelas.** Enquanto existir, `CDHU` não
  pode ocupar o lado `ref`: fonte→fonte é **proibido pelo banco**, não só ausente do código.
- **`fk_equivalencias_mo_ref` aponta fisicamente para `composicoes`.** Contradiz o próprio `mo_ref_tipo`:
  obriga o lado ref a ser CPU. MO fonte→fonte (insumo↔insumo) viola a FK na hora. É o bloqueio duro.
- **12.216 ids existem ao mesmo tempo em `insumos` e `composicoes`** (faixas 1–12.347 e 1–18.224). Um
  `item_id` polimórfico sem FK não falha alto — aponta em silêncio para a linha errada do tipo errado.
- **O `UNIQUE` atual é sobre a tupla ORDENADA.** `(CDHU→FDE)` e `(FDE→CDHU)` são linhas distintas para o
  banco. Com âncora isso nunca apareceu (a direção era fixa); com fonte→fonte é duplicação garantida.
- **As colunas de fonte em `ins`/`cpu` são redundância pura:** `ei_fte_codigo` diverge do `ins_fte_id` em
  **0 de 357** linhas, e nenhuma constraint as usa. Em `mo` **não são** — lá a coluna carrega a regra de
  cardinalidade (um alvo por fonte).
- **MDO-SINAPI é identificável com segurança pelo SUBGRUPO** `CÁLCULOS E PARÂMETROS`: 377 CPUs, contra
  376 por `ENCARGOS COMPLEMENTARES` (376 nos dois). O subgrupo é o superset — é o predicado.
- **Hoje 0 linhas violam a separação de tipos** — mas por sorte do matcher (`_carrega_cmp` filtra em
  código). Tela manual e IA gravam direto, **sem guarda nenhuma**.
- **A proteção ins×mo é ACIDENTAL e o refactor a destrói.** Hoje MO sempre tem composição de um lado, o
  que não cabe em `equivalencias_ins`. Quando MO aceitar insumo↔insumo, **a mesma linha passa a caber nas
  duas tabelas** — e um dia elas discordam. É o efeito colateral menos óbvio de todo este refactor.

### 13.3. Schema pensado

Três mudanças repetidas nas três tabelas, e o conserto estrutural do `mo` por cima.

**(a0) Em `catalogo.fontes` — quem pode ser destino** (§12.1)
```sql
fte_favoritavel BOOLEAN NOT NULL DEFAULT FALSE   -- SINAPI/SICRO = TRUE por lei
```

**(a) Nas três — destravar a âncora**
```sql
ALTER TABLE catalogo.equivalencias_ins DROP CONSTRAINT ck_ei_ref_fonte;
ALTER TABLE catalogo.equivalencias_cpu DROP CONSTRAINT ck_ec_ref_fonte;
ALTER TABLE catalogo.equivalencias_mo  DROP CONSTRAINT ck_mo_ref_fonte;
```

**(b) Nas três — um par, uma linha** (o banco recusa a espelhada; à prova de corrida, ao contrário de
qualquer checagem em trigger ou aplicação)
```sql
CREATE UNIQUE INDEX uq_ei_par ON catalogo.equivalencias_ins
  (LEAST(ei_a_ins_id, ei_b_ins_id), GREATEST(ei_a_ins_id, ei_b_ins_id));
-- idem cpu
```

**(c) Em `ins`/`cpu` — cair `*_ref_fonte` e `*_fte_codigo`** (redundância provada). A fonte deriva do
`ins_fte_id`/`cmp_fte_id` do próprio id. Direção nas colunas **permanece** — o fator precisa dela
(`GL → 3,6 L` ≠ o inverso); o índice (b) é que impede a linha gêmea.

**(d) Em `mo` — o conserto estrutural**
```sql
mo_ori_ins   BIGINT NULL REFERENCES catalogo.insumos(ins_id)
mo_ori_cpu   BIGINT NULL REFERENCES catalogo.composicoes(cmp_id)
mo_dest_ins  BIGINT NULL REFERENCES catalogo.insumos(ins_id)
mo_dest_cpu  BIGINT NULL REFERENCES catalogo.composicoes(cmp_id)
CHECK (num_nonnulls(mo_ori_ins,  mo_ori_cpu)  = 1)
CHECK (num_nonnulls(mo_dest_ins, mo_dest_cpu) = 1)

mo_dest_fte_id INTEGER NOT NULL REFERENCES catalogo.fontes(fte_id)   -- 13.4(d)

-- etiqueta canônica p/ o índice do par (o I/C impede insumo 500 ≡ composição 500)
mo_a TEXT GENERATED ALWAYS AS (COALESCE('I'||mo_ori_ins,  'C'||mo_ori_cpu))  STORED
mo_b TEXT GENERATED ALWAYS AS (COALESCE('I'||mo_dest_ins, 'C'||mo_dest_cpu)) STORED
CREATE UNIQUE INDEX uq_mo_par ON catalogo.equivalencias_mo (LEAST(mo_a,mo_b), GREATEST(mo_a,mo_b));

-- uma função, um alvo por fonte-destino (não existem dois pedreiros com preço diferente)
CREATE UNIQUE INDEX uq_mo_alvo_por_fonte ON catalogo.equivalencias_mo (mo_a, mo_dest_fte_id);
```
Ganhos: as 4 combinações passam a caber · **FK real nos dois lados** (hoje o lado da fonte não tem
nenhuma) · a colisão dos 12.216 ids desaparece (o id passa a morar na coluna que sabe sua tabela) ·
**`mo_ref_tipo`/`mo_fte_tipo` caem** (o tipo é derivável da coluna preenchida) · **sem coluna de fator**.

Combinações que o desenho passa a suportar:

| origem | destino | caso | hoje |
|---|---|---|---|
| insumo | composição | CDHU → SINAPI | ✅ |
| insumo | insumo | **CDHU → FDE** | ❌ |
| composição | composição | SINAPI → SICRO | ❌ |
| composição | insumo | SICRO → fonte | ❌ |

### 13.4. Triggers pensadas

**Por que trigger e não `CHECK`:** o tipo do item não está na linha gravada — está em `insumos` /
`composicoes_subgrupos`. `CHECK` só enxerga a própria linha; trigger enxerga o banco.
**Custo:** uma leitura por chave primária, microssegundos. Um import grava alguns milhares de linhas —
some no ruído. **Ganho:** não existe caminho que escape (import, tela, IA, script, psql).

| trigger | tabela | recusa |
|---|---|---|
| **(a)** | `equivalencias_ins` | insumo com `ti_codigo = 'MO'` — mão de obra é de `mo` |
| **(b)** | `equivalencias_cpu` | composição SINAPI do subgrupo `CÁLCULOS E PARÂMETROS` — MDO jamais cai aqui |
| **(c)** | `equivalencias_mo` | o que **não** for mão de obra (insumo `ti='MO'` ou composição MDO do SINAPI) |
| **(c2)** | `equivalencias_mo` | **item cuja unidade não seja `[H]`, dos DOIS lados** |
| **(d)** | `equivalencias_mo` | mantém `mo_dest_fte_id` honesto (deriva do item de destino; não confia no que o chamador mandou) |

(a)+(c) são o par que fecha a sobreposição criada pelo próprio refactor (13.2, último considerando).
(b) é a regra declarada como absoluta. (d) existe porque `mo_dest_fte_id` é desnormalização — e
desnormalização sem guarda é o começo de uma coluna que mente.

**(c2) é o que transforma a premissa 7 em invariante.** "MO não tem fator porque os dois lados são
sempre `[H]`" é verdade **hoje só por sorte**:

| | mão de obra | |
|---|---|---|
| CDHU | 45 insumos | 100% `[H]` |
| FDE | 36 insumos | 100% `[H]` |
| SINAPI | 94 insumos `[H]` | **+ 92 `[MÊS]`** |
| SINAPI | 193 CPUs `[H]` | **+ 184 `[MÊS]`** |

Nada impede uma das **184 composições `[MÊS]`** entrar em `equivalencias_mo`. E aí a ausência de fator
não dá erro: dá resultado **220× errado, calado**. A trigger (c) sozinha só pergunta "é mão de obra?" —
tem de perguntar também "é `[H]`?". Mesma trigger, uma condição a mais, custo zero.

### 13.5. Dívidas que entram no mesmo pacote (não são schema)

- **A PONTE está viva e tem de morrer.** `equivalencias.equivalente_ins:60-64` resolve `CDHU→FDE`
  saltando pelo SINAPI e **multiplicando os dois fatores**. É exatamente o que a §11.1 proíbe: inventa
  uma equivalência que ninguém afirmou, porque o par intermediário pode não ser válido. Ou há linha
  direta, ou a resposta é "não há equivalente".
- **A tela precisa distinguir "fonte não favoritável" de "item sem equivalente"** (§12.2). Hoje os dois
  chegam como ausência de linha e a conversão sai pela metade, calada. Não é dívida de schema: é de UI
  sobre um dado que `fte_favoritavel` passa a fornecer.
- **`NULL` → `1.0` em `equivalencias.py:52,59`.** Fator `NULL` é a classe `especial` — "a app **não
  assume** a conversão". Hoje assume **1**, calado. **Corrigir junto, não depois.**
- **Alinhar `importar_associacoes` à tela:** a tela apaga (correto, §1.1); o caminho da IA marca
  `refutado` + `ativo=FALSE`. Os dois têm de apagar.
- **`insumos_equivalencias` sobra** (§5.4). Decisão tomada: **as telas param de usá-la**. A tabela é
  removida quando a UI não a referenciar mais.
- **Revalidação só de um lado** (§9.1) e **só de `confirmado`** (§9.2).
- **Matcher propõe item morto** — predicado certo é presença na edição importada, **nunca `ins_ativo`**
  (§6.1).

### 13.6. Condição de saída do congelamento

Este contrato só vira execução quando existirem, nesta ordem:
1. **Arquitetura/arranjo de import** discutida e fechada (pendente — é a próxima conversa).
2. **Check de sanidade completo** sobre o estado atual.
3. **Objetivo/alvo completo** escrito — o que fica verdadeiro ao fim, não a lista de passos.

Antes disso, nada de `ALTER TABLE`.

---

## 14. Disclaimer canônico (módulo ativo)

Texto **literal** na tela de conversão entre-fontes do Ativo:

> A conversão entre-fontes é algo que é persistido sobre o estado atual do banco de dados e representa
> vínculos com as edições mais vigentes disponíveis da fonte-base para com a SINAPI da mesma época.
> Recomendamos revisão cautelosa sobre as associações diretas e rigorosa sobre as associações com
> necessidade de conversão. A Axys Engenharia e Tecnologia LTDA não se responsabiliza pelas planilhas
> elaboradas, sendo que, atua pura e simplesmente como software/ferramenta de suporte.

---

## §14 · 1×1 DURO — a regra que a tabela existe para servir (2026-09-23)

**Premissa que estava faltando, e que o Renan nomeou:** `equivalencias_ins` / `equivalencias_cpu`
existem para UMA coisa — **converter um orçamento de uma fonte-base para outra**. Estou na bancada
com um orçamento CDHU e quero o mesmo em SINAPI: a conversão tem de ser determinística.

Disso decorre tudo: **se um item tivesse dois equivalentes na mesma fonte, o back teria de
ESCOLHER** — uma decisão de máquina em cima de uma decisão humana, que é exatamente o que o motor
inteiro proíbe. Logo: **um item tem NO MÁXIMO UM parceiro por fonte**.

Exemplo real que fechou a discussão (CDHU `B.02.000.020508` CIMENTO CPII-E-32):

```
ACEITO   CIMENTO × SINAPI 1379            ← a vaga do SINAPI
NEGADO   1379 × CIMENTO                   ← o par não entra duas vezes, nem invertido
NEGADO   CIMENTO × SINAPI 34753           ← a vaga do SINAPI já está ocupada
ACEITO   CIMENTO × FDE 2.05.08            ← a vaga do FDE é outra
NEGADO   CIMENTO × FDE 2.05.09            ← e já foi ocupada
ACEITO   SINAPI 1379 × FDE 2.05.08        ← outro par de fontes, outra vaga
```

### Como o banco garante

**Ordem canônica** (`ck_ei_canonico` / `ck_ec_canonico`): o lado da fonte de MAIOR `fte_id` fica em
`ori`, o da menor em `dest`. `ori`/`dest` é **posição de armazenamento, não sentido de conversão** —
a conversão vale nos dois sentidos. A trigger NORMALIZA antes de gravar (troca os lados sozinha) e
DERIVA `*_fte_id` dos próprios itens: quem escreve não precisa saber da regra, e o que o chamador
mandar nessas colunas é ignorado.

**Dois índices únicos**, um por direção de conversão:

```sql
UNIQUE (ei_ori_ins_id,  ei_dest_fte_id)   -- daqui para lá: um destino só
UNIQUE (ei_dest_ins_id, ei_ori_fte_id)    -- de lá para cá: um destino só
```

**Por que dois, e por que largando um item em cada:** o que se proíbe é "o cimento ter dois
parceiros no SINAPI". Pôr o parceiro na chave não proíbe nada — cada parceiro diferente vira uma
chave diferente. Medido: um único índice sobre a tupla inteira `(fte_ori, fte_dest, ins_ori,
ins_dest)` aceitou 5 linhas onde deviam entrar 3.

**E por que a ordem canônica é obrigatória:** sem ela o item cairia ora num lado ora no outro e se
esconderia ENTRE os dois índices (medido no dado antigo: 1.149 linhas com a fonte menor à esquerda
e 552 com a maior). Uma `EXCLUDE ... USING gist` resolveria sem canonizar, mas exige `btree_gist` +
`intarray` e troca B-tree por GiST na escrita — descartada por peso.

### Escopo e consequências

Vale **só para `equivalencias_ins` e `equivalencias_cpu`**. `equivalencias_mo` tem rito próprio, é
menor e **já estava resolvida** — `uq_mo_alvo (mo_a, mo_dest_fte_id)` é esta mesma regra, e foi ela
que serviu de modelo.

- morre o `uq_ei_par`/`uq_ec_par` sobre `LEAST/GREATEST`: com a ordem canônica, o par invertido não
  tem como ser gravado, e os dois índices já cobrem o resto;
- **o matcher passa a ter de escolher UM candidato por item por fonte**, não emitir todos;
- **a tela deixa de ser "sim/não" por linha e vira "escolha um entre N"** — a mesma informação da
  coluna `disputa`, com outra semântica;
- o dado anterior (dev e prod) foi **descartado**: 88 grupos confirmados violavam a regra, e
  escolher sobrevivente em cada um seria curadoria retroativa sem critério.
