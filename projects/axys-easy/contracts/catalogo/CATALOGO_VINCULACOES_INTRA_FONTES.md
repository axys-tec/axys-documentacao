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
| **H↔MÊS** (SINAPI interno) | CPU SINAPI MDO **[H]** → CPU SINAPI MDO **[MÊS]** | intra-SINAPI, 1:1, + fator de conversão |
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

### 3.1. H↔MÊS (a mais fácil — prova o trilho)
- Universo pequeno: **só CPUs MDO**, unidade origem **H**, destino **MÊS**. Descrições quase batem → match ≈1.
  Ex.: `88316 SERVENTE COM ENCARGOS COMPLEMENTARES [H]` ↔ `101452 SERVENTE DE OBRAS ... [MÊS]`.
- **Fator** de conversão explícito e **editável** (ex.: `1/220`), **não** embutido em código (reforma
  trabalhista muda). Modal de confirmação informa edição · nº de pares · fator · caráter provisório.
- Prompt p/ IA enriquecido com: **lista de todas as CPUs de MDO + matches prováveis**.

### 3.2. MDO fonte→SINAPI
- Origem: **insumo** MDO [H]; destino: **composição** SINAPI MDO [H]. Match pela **função** (não a descrição
  inteira) — **reusar o dicionário de termos do buscador MDO CDHU/FDE**. **Categoria-aware**
  (engenheiro jr/pleno/sênior não podem colapsar).
- **Validador de preço:** na mesma UF, o **R$/h** do insumo CDHU/FDE **bate** com o insumo principal dentro da
  CPU SINAPI (preço norteado por sindicato). → `ratio_desc(X)` + `ratio_preço(Y)` → `ratio_total = média(X,Y)`
  (enriquecível). Quando faltar preço p/ a UF, degrada p/ só `ratio_desc`.
- Encadeia o 2º salto via H↔MÊS quando precisar do regime mensalista.

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
