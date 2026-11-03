# Contrato de Vinculações — entre fontes e dentro da SINAPI

> **Status:** vigente (consolidado em 03/11/2026). Governa as associações entre fontes (insumo,
> composição e mão de obra), a recusa como fato, o estágio `associacoes` do import, as telas de
> curadoria 5a e 5b e o par H↔MÊS da SINAPI. O schema (`schemas/schema.sql`) suporta; o código
> (`backend/modules/catalogo/associacoes_*`, `equivalencias*.py`) implementa.
> **Relacionados:** `imports/estagios.md` (estágios, falhas), `edicoes.md` §2.1 (edição em
> sequência), `CTC_DESCRITIVO_FILL.md` (o `remunera`), `conversao_mdo_divisor.md`.

---

## 0. O que é

Camada **curada** que liga itens do catálogo entre si. Não executa orçamento: guarda decisões de
engenharia para a bancada converter um orçamento de uma fonte-base para outra.

| amarra | origem → destino | natureza |
|---|---|---|
| **INS / CPU entre fontes** | item da fonte maior → item da fonte menor | 1×1 duro, com fator (§1.3) |
| **MDO fonte → SINAPI** | insumo MO [H] da fonte → composição MDO [H] da SINAPI | N:1, sem fator (§4) |
| **H↔MÊS** | CPU SINAPI MDO [H] → CPU SINAPI MDO [MÊS] | N:1, determinístico (§3) |

Toda vinculação é **decidida por gente**. A máquina propõe (busca + IA); nada nasce automático e
calado. Substituições (1 header → N alternativas) não existem.

---

## 1. Doutrina

### 1.1 Associação é igualdade, não analogia
> Comprar uma Havaiana 351020 verde **=** comprar uma 351020 da Havaiana, cor verde. Com fator quando
> a embalagem difere: `tinta esmalte GL = 3,6 L de tinta esmalte`.

Um item análogo a dez outros não gera associação nenhuma. "Igualdade" é rigor do casamento, não a
propriedade matemática: a relação é reflexiva e simétrica, **não transitiva**.

### 1.2 Sem ponte
`A=B` e `A=C` não afirmam nada sobre `B` e `C`: um serviço pode ser igual ao da SINAPI por um
critério e ao da FDE por outro sem que FDE e SINAPI sejam iguais. Responder `CDHU→FDE` saltando pela
SINAPI inventa uma equivalência que ninguém afirmou. **Ou há linha direta, ou não há equivalente**
(`equivalencias.equivalente_ins` só lê linha direta). Pelo mesmo motivo não existem classes ou grupos
de equivalência: o modelo é de pares. A transitividade entra só como **sinal** na rodada (§5.5).

### 1.3 1×1 duro
A tabela existe para migrar o orçamento sem regressão: a volta tem de ser a ida. Logo **um item tem no
máximo um parceiro por fonte**, e a forma admissível é uma só — *isto equivale àquilo*.

- **Multiplicidade nega, não escolhe.** Dois candidatos admissíveis sem atributo na origem que os
  distinga → negada, com o parecer nomeando as alternativas.
- **N:1 no destino nega todas as origens envolvidas**, não a pior.
- **Duplicata dentro da fonte nega os dois lados** (a fonte se declara polêmica ao criar duas
  composições com a mesma descrição; o parecer devolve o defeito a ela).
- Negar não deixa o usuário sem saída: a bancada converte os **insumos** mantendo os coeficientes da
  origem. A equivalência de composição é atalho quando é indiscutível.

**Como o banco garante.** Ordem canônica (`ck_ei_canonico`/`ck_ec_canonico`): a fonte de maior
`fte_id` fica em `ori`, a menor em `dest` — posição de armazenamento, não sentido de conversão. O
CHECK **recusa** a ordem invertida (e o par da mesma fonte); quem ordena é o back (`_grava_par`), e a
fonte de cada lado vem por FK composta (id, fte_id). Dois índices únicos, um por direção:
`uq_ei_ori (ei_ori_ins_id, ei_dest_fte_id)` e `uq_ei_dest (ei_dest_ins_id, ei_ori_fte_id)` (idem `ec_`).
`_grava_par` recusa a colisão com o motivo — curadoria em conflito é assunto de gente. **Trigger pode
recusar, nunca reescrever**: a que normalizava os lados trocava ids e hashes mas não invertia o fator
(erro de 16× calado, 28/09).

**Exceção: MDO é N:1** (§4). As fontes subdividem ofícios mais fino que a SINAPI (esgoteiro e poceiro
caem em encanador); a unicidade lá é `(origem, fonte de destino)`.

### 1.4 Direção e participantes
- A análise olha **da fonte maior para a menor, parando na SINAPI**: FDE(4) → CDHU(3) → SINAPI(2). O
  item da fonte maior é a origem do prompt e o lado `ori` do par; a conversão vale nos dois sentidos.
- **AXYS (1) fica fora.**
- Todas as fontes entram no import, SINAPI inclusive: importar uma fonte a avalia como **origem** contra
  as menores e como **alvo** das maiores (§5.3).

### 1.5 Recusa é fato e mora no banco
Não se guarda "A não é B" — par negado não existe. Guarda-se "**este item foi examinado contra esta
fonte, contra estes candidatos, nesta data, e a resposta foi não**", em tabela própria (§2.3). O reuso
decide pelo banco; o JSON do storage é registro e corpo de fine-tuning (§6.3).

**Reabertura.** A negada reabre quando o texto do item muda (hash) **ou** quando aparece candidato que
não estava na lista examinada — com a confirmação do §5.3. Candidato que desapareceu não reabre. A lista
de examinados **soma**, nunca substitui.

### 1.6 Nenhuma decisão sem justificativa
Todo ato de curadoria tem motivo. Quando o curador **concorda** com a IA, o motivo é o parecer dela
(o geral, ou o da proposta MDO) e ninguém o redigita. Quando **diverge** — recusa um par que a IA
propôs, ou associa um candidato que ela recusou — o motivo é obrigatório e é dele.

### 1.7 Determinístico antes de IA
Busca-se primeiro o sinal que já está no dado (estrutura, insumo, preço, unidade). A IA fica com o
resíduo ambíguo e nunca decide sozinha: ela propõe, a pessoa decide.

### 1.8 Fonte → fonte direto; quem é favoritável
`TODAS → SINAPI` é lei (14.133); idem SICRO na infraestrutura. Pares entre outras fontes existem onde o
destino é **favoritável** (`catalogo.fontes.fte_favoritavel`; SINAPI e SICRO por lei). Cobertura é
maturidade, não pré-requisito: não há gate de completude. `fte_favoritavel` (pode ser escolhida) não
se confunde com a favorita do orçamento (`ativo.orcamento_parametros.opa_default`).

---

## 2. Schema

O que está aqui é o que existe. Toda tabela é **identity-level**: a equivalência é fato sobre o
ITEM (id estável, get-or-create), não sobre a edição.

### 2.1 `catalogo.equivalencias_ins` / `equivalencias_cpu`
Gêmeas (`ei_`/`ec_`): `ori/dest` (item e fonte, ordem canônica §1.3), `classe`
(`direta`|`calculada`|`especial`), `fator_conversao NUMERIC(12,6) NOT NULL > 0`, `status`
(`pendente`|`confirmado`|`rejeitado`), `metodo`, `hash_ori`/`hash_dest` (identidade de cada lado no
momento da decisão), `observacao`, `ativo`, auditoria. Só `confirmado AND ativo` é consumido. A trigger
`t_e*_guarda` só recusa: mão de obra não entra aqui (vai para `equivalencias_mo`).

**Sem fator não é associação.** Associação responde "tanto faz": trocar um pelo outro não muda a obra.
Item que depende de quantificar (limpeza por m² × por un) não se associa, nem com aviso.

### 2.2 `catalogo.equivalencias_mo`
Origem e destino como insumo **ou** composição (`mo_ori_ins|cpu`, `mo_dest_ins|cpu`, exatamente um de
cada), `mo_dest_fte_id`, `status`, `score`, `obs`. `uq_mo_par` (o par não entra invertido) e
`uq_mo_alvo (mo_a, mo_dest_fte_id)` (um alvo por fonte de destino). **Sem fator**: os dois lados são
`[H]`; o único fator de MDO é o H→MÊS (§3).

### 2.3 `catalogo.equivalencias_ins_negadas` / `equivalencias_cpu_negadas`
`ein_`/`ecn_`: o item, a fonte onde **não** há equivalente, `hash_item`, `candidatos BIGINT[]` (a
lista examinada, não uma hash dela), `motivo`, `por`, `em`; `UNIQUE (item, fonte)`. Não cabe nas
tabelas de par: o unique do 1×1 não é parcial, e recusa não tem dois lados. Confirmado e negado são
mutuamente exclusivos para o mesmo (item, fonte) — a trigger recusa, e recusa também negativa contra a
fonte do próprio item. Sem coluna de caminho: o path do JSON é determinístico. MDO não tem negada.

### 2.4 `catalogo.composicoes_mapeamento_mdo`
`cmm_cmp_id_h` → `cmm_cmp_id_mes`, `uq` no H (N:1). O fator mora em `catalogo.parametros_normativos`,
código `JORNADA_H_MES`, com vigência *as-of*.

### 2.5 `catalogo.equivalencias_subgrupos`
Mapa subgrupo-fonte → subgrupo SINAPI do matcher antigo. Fica no banco como dado curado, **sem
consumidor**: o motor não usa funil de subgrupo.

---

## 3. H↔MÊS (intra-SINAPI) — determinístico, sem IA

- **Pareamento pelo insumo MO**, nunca pela descrição da CPU (engana: TELHADISTA↔TELHADOR). A CPU
  `{FUNÇÃO} COM ENCARGOS COMPLEMENTARES` contém um insumo MO; H-CPU → insumo-H → mesma função →
  insumo-MÊS → MÊS-CPU. Nome divergente → override por código de insumo
  (`backend/modules/catalogo/data/mdo_insumo_override.json`).
- **N:1**: um MÊS serve dois ofícios-H (calceteiro + rasteleiro).
- **Validador = preço pelado** (SE): `TRUNC(preço_mês/220, 2) = preço_hora`. Confiável → confirma sem
  IA. Horista-only (sem MÊS) → sem par.
- O 220 **identifica** o par. O divisor aplicado ao coeficiente na conversão é outro assunto:
  `conversao_mdo_divisor.md`.
- Guarda do import: MDO nunca entra como NC — o parser reclassifica o órfão `(HORISTA)/(MENSALISTA)`
  para MO.

---

## 4. MDO fonte → SINAPI

- Origem: **insumo** MO [H] da fonte (`ti = MO`); destino: **composição** SINAPI MDO [H]
  ("…COM ENCARGOS COMPLEMENTARES").
- Proposta **sem IA**, pelo léxico de `conciliacao_mdo` (ofício e nível; o nível tem de bater:
  auxiliar ≠ oficial), dicionário `data/mdo_sinonimos.json`. Categoria importa (engenheiro jr/pleno/
  sênior não colapsam).
- Completude na **fonte**: não há dois pedreiros com preço diferente, então toda função da fonte tem
  par; sem par é exceção rara (função sem análogo na SINAPI).
- N:1 por natureza (§1.3, exceção). No import, o rito é o do §5.7.

---

## 5. O estágio `associacoes` do import

Estágio próprio, **depois do `documentos`** e último antes do publicar (estados e falhas em
`imports/estagios.md`):

```
preparar → precos → dados → documentos (cadernos + CTC) → associacoes → (publicar)
```

Depois do CTC porque a CPU decide pelo `remunera` do descritivo de cada lado ("quando vier o campo
`remunera`, ele decide"). Por isso o `remunera` é **só da fonte** — nunca recebe texto emprestado de
análogo, ou a IA confirmaria o par por eco.

### 5.1 Pré-condições
- A edição é a **mais nova** da fonte X; edição antiga → `skip`.
- **Nenhuma outra associação aberta no sistema** (`rodando`, `pendente_user`, ou `erro` com a fila
  gravada). Conferido antes do parser (Preços/Dados recusam com 409): o parser sobrescreve o texto de
  X e mudaria o chão de uma associação aberta.
- CPU: **descritivo vigente preenchido** nos itens do delta (`versoes->-1`).
- A busca enxerga a edição: o estágio indexa X pela **presença na edição** (inativa para a busca da
  app até o publicar).

### 5.2 O delta de X
Lido do histórico do catálogo (`insumos_historico`/`composicoes_historico`) da edição, que o import já
escreve:

| conjunto | evento |
|---|---|
| **novo** | `CRIACAO`, `REATIVACAO` |
| **mudou** | `ALTERACAO`/`ALTERACAO_CABECALHO*` com descrição ou unidade no diff. Na SINAPI a troca do carimbo `AF_mm/aaaa` é texto e conta: é reaferição, com receita nova |
| **saiu** | `INATIVACAO` (presença por edição) |
| igual | o resto. `ALTERACAO_ITENS` sem mudança de cabeçalho não reabre; mudança só do `remunera` também não |

No início do estágio, numa transação:
- **saiu como destino** de um par → o par cai e a origem viva volta à análise. **Saiu como origem** →
  par e negada ficam (o item não entra em orçamento novo);
- **mudou além do carimbo**, com par → o par cai e vai ao prompt como `par_anterior`; o item volta à
  análise e o parceiro fica livre. Não há tabela de desassociados: o par anterior fica na rodada do JSON;
- **mudou só o carimbo**, com par → o par fica (§5.3).

### 5.3 Quem é analisado
| papel de X | origens analisadas | candidatos |
|---|---|---|
| **origem** (contra as fontes menores) | itens **novo/mudou** de X | do alvo |
| **alvo** (das fontes maiores) | origens que **podem ganhar candidato novo** em X | de X |

| import | X como origem contra | X como alvo de |
|---|---|---|
| SINAPI | — | CDHU, FDE |
| CDHU | SINAPI | FDE |
| FDE | CDHU, SINAPI | — |

**X como alvo — quem reabre.** A origem O volta à análise se (a) tinha **par** com item de X que mudou
ou saiu; ou (b) tem negada contra X (ou nunca foi decidida) **e** um item **novo ou mudado além do
carimbo** de X entra na lista dela. (b) se apura por **busca reversa** (o item que chegou como consulta
no índice da fonte maior → lista curta de origens) e **confirmação direta** por **concordância**: o item
que chegou tem de estar entre os **5 primeiros dos dois motores** na busca direta de O
(`associacoes_service.concordam`). Um motor só, pela palavra rara, traz parecido que não é ("PEDRISCO"
põe pavimento contra chapisco). Motor que falhou manda a origem à fila. Item com par nunca é tocado.

**Carimbo `AF_`.** Item de X que trocou **só** o carimbo e tem par **não vai à IA nem perde o par**: o
par nasce aceito e aparece na 5b para conferência (§7.1). Passou batido, fica associado; o fechamento
renova a hash. Sem par, o carimbo não reabre nada.

### 5.4 Candidatos
Dois motores (Postgres + OpenSearch), profundidade 100 cada, intercalados com dedup; à IA vão os
primeiros **30 (INS) / 15 (CPU)**. Universo dos dois lados: INS sem `MO` e `ENC_COMP`; CPU sem a
MDO-como-composição da SINAPI. Depois, nesta ordem:
1. **fora** o destino ocupado por par que não mudou (1×1 — nem aparece);
2. **separado como recusado** o candidato já examinado na negada daquele item×fonte e que não mudou:
   vai ao prompt como "já recusado", não é escolhível. Se a origem mudou, tudo volta a ser escolhível e
   a recusa anterior vai só como contexto;
3. **fora** item com homônimo na própria fonte;
4. sobrou candidato novo? Não → a negada absorve a lista, sem IA. Sim → IA.

### 5.5 IA
- Prompt dos scripts de curadoria, sem mudança de doutrina; bloco SINAPI quando um lado é ela. CPU leva
  o `remunera` vigente de cada lado, cortado em 420 caracteres **só no prompt** (fila e tela levam
  inteiro).
- Recebe os candidatos novos, os já recusados com o motivo, o `par_anterior` do item que mudou e a
  `recusa_anterior` (julgou o texto antigo). CPU: o **insumo principal** da origem (raríssimo/raro), com
  a marca dos candidatos que o usam; conflito com a resposta → uma repergunta. O candidato apontado pela
  **transitividade** vai marcado. Os dois são sinal, nunca decisão.
- Validador: escolhido entre os oferecidos, `aceito` só nele, escolha exige fator, parecer para todo
  candidato; resposta incoerente é repetida com a correção apontada.
- Cadeia `EASY_IA_MODELO_ASSOCIACOES` (+ fallbacks). Falha de conta para a rodada inteira na primeira
  ocorrência; a retomada pergunta só o que faltou.
- **Não há repergunta na tela.** O curador decide com o que a rodada respondeu.

### 5.6 Pré-curadoria
Depois de todas as respostas: `destino_disputado` e `duplicata_na_fonte` (§1.3). Colisão chega à 5b
marcada, nunca como duas propostas soltas.

### 5.7 MDO no estágio
Sem IA, pelo léxico do §4; destino não exclusivo. Só MDO nova ou mudada passa; a que saiu perde o
vínculo. Na 5b o motivo vem do casamento léxico que gerou a proposta.

### 5.8 Fechamento
O estágio fica `pendente_user` até a 5b zerar a fila. Fecha em dois tempos:
1. **banco**, numa transação sob `pg_advisory_xact_lock` global: pares aceitos (`_grava_par`, que
   recusa colisão), depois as negadas (`grava_negadas_lote`, somando os examinados); carimbo
   desassociado = par apagado por id + negada com o ex-parceiro;
2. **JSONs** (§6.3), depois do commit. O estágio só vira `ok` quando o último arquivo foi gravado; o
   que falhar é regravado na retentativa.

O banco é a verdade operacional: JSON que falha não esconde nem reabre item. O publicar não toca em
associação. Publicar exige `documentos = ok` e `associacoes ∈ {ok, skip}`.

### 5.9 Coordenação
Uma associação aberta por vez, no sistema inteiro: o "um contra todos" só vale com as outras fontes
fechadas. Quanto mais curado, menos trabalho: par que não mudou sai do universo, negada igual não volta.

---

## 6. Hash e registro

### 6.1 Uma hash só
`associacoes_service.hash_item` (descrição + unidade normalizadas), a mesma dos pares e negadas do
banco. JSONs antigos guardam a hash anterior na rodada antiga, marcada `sha1_40`; nada decide por ela.

### 6.2 O que mudou mora no histórico do catálogo
`aplicar_diff_edicao` grava por edição `CRIACAO`/`ALTERACAO`/`INATIVACAO`/`REATIVACAO` com `de`/`para`.
Na reexecução de um estágio, o "antes" de quem já tem evento na edição vem do evento, não do banco
(senão a segunda passada apagaria o histórico).

### 6.3 O JSON de curadoria
Um arquivo por item **por par de fontes**, no storage privado:

```
easy/fontes/associacoes/{fte_ori}_{fte_dest}/{ins|cpu|mo}/{id}.json      ← histórico do item
easy/fontes/associacoes/_fila/{edi_id}/…                                 ← fila do estágio
```

O arquivo tem `rodadas[]`, que **acrescenta**, nunca substitui: `origem` (`5b`|`5a`), `edicao`,
`item_como_estava` (texto, unidade, hash, `remunera`), `par_anterior`, `candidatos` com parecer,
`recusados_enviados`, `ia` (com `prompt_versao`), `pre_curadoria`, `curadoria` (`decisao`, `id_final`,
`fator`, `motivo`, `por`, `em`, `divergiu_da_ia`). `estado`: `vivo` | `saiu`. O conteúdo antigo vira
`rodadas[0]` na primeira rodada nova. O caminho quente lê só o banco. `easy/fontes/associacoes/` é
curadoria interna: não se serve pelo `/doc-file` (`storage/acesso.py`).

---

## 7. Telas

Reusam as classes `.cpu-`/`.ae-`; sem texto explicativo; modal fecha no Esc.

### 7.1 5b — curadoria do import (`/edicoes/{id}/associacoes`)
- Abas **Insumos · Composições · MDO · Alteração Carimbo AF_**, um item por vez, setas no topo. A
  posição conta sobre a aba inteira; as setas percorrem também o que já foi curado.
- Por item: a origem (código, descrição, `remunera` inteiro), o diff, a recusa ou o par anterior, os
  sinais, a recomendação da IA e **só os candidatos que a IA julgou nesta rodada**, com
  Candidato · Un · Fator (o da IA para o escolhido; `–` nos demais) · IA · Parecer. Não há `+` na 5b.
- Atos: **Aceitar selecionado** (abre marcado o escolhido; marcar outro = informar outro candidato) e
  **Recusar todos** (nega o item contra a fonte). O aceite pede o fator em modal; a justificativa
  segue o §1.6. Item curado trava os atos e mostra **Reabrir**, que o devolve ao estado de antes da cura
  (só com a associação aberta — até o fechamento nada foi ao banco).
- **Alteração Carimbo AF_**: "descrição antiga → nova" (AF em negrito), o par e os atos **manter** /
  **desassociar** com justificativa. Não bloqueia o fechamento.
- **Fechar associação**: com a fila zerada; a tela acompanha a gravação e, quando a edição fica
  publicável, oferece publicar.

### 7.2 5a — curadoria geral (`/catalogo/associacoes`), fora do import
- Seleção: tipo (INS, CPU, MDO) × par de fontes do §1.4 × lista da origem (com par, negados, sem decisão;
  em CPU, resíduo do principal), com busca por código/descrição.
- Item: o estado (par ou negada com motivo e examinados), os sinais e os candidatos da **mesma busca do
  motor**, inteiros, com `+` de 15 em 15; o parceiro atual fica marcado. MDO: o ranking léxico.
- Atos, todos com justificativa: **associar** (destino + fator; troca o par quando há — o anterior sai
  por id e vai como `par_anterior`) e **desassociar** (apaga o par por id e a origem fica negada com o
  ex-parceiro nos examinados; MDO só apaga o vínculo). Destino ocupado, gêmea, item inativo, fator
  ausente e estado mudado desde que a tela leu são recusados. A 5a aceita destino fora da busca; a 5b não.
- Gravação: banco sob o lock global, com auditoria (`audit.logs`) de cada par, negada e vínculo; depois
  a rodada no arquivo da origem (`origem: "5a"`). Com associação aberta numa edição da fonte X, todo
  ato que envolve X é recusado (409).

---

## 8. Consumo e conversão

A bancada converte **insumo** (`equivalencias.equivalente_ins`, só linha direta, fator invertido quando
o item está no lado `dest`) e **MDO** (`preco_mo._mo_sinapi_mes`: insumo MO → `equivalencias_mo` → CPU
[H] → `composicoes_mapeamento_mdo` → CPU [MÊS]). **Composição não se converte** — os pares de CPU são
registro curado, não motor de conversão. Equivalente sem preço na edição×UF → `destino_sem_preco`.
Regime mensalista trava MDO, não trava INS.

| classe | fator |
|---|---|
| `direta` | 1 — as unidades oficiais coincidem e entregam o mesmo |
| `calculada` | ≠ 1, **lido** das unidades oficiais (1 kg → 4 embalagens de 250 g) |
| `especial` | ≠ 1, **inferido** por descrição + preço porque a unidade oficial mente (a UN da bucha FDE é o cento) — merece revalidação quando a fonte republicar |

Equipamento: a SINAPI guarda a aquisição como insumo UN e o custo-hora como composição CHP/CHI [H];
locação [H] da fonte casa com CHP/CHI, nunca com a aquisição. Nunca associar: parte-de (eletroduto ×
luva), locação × aquisição sem CHP, naturezas distintas, equipamentos diferentes de descrição parecida.

---

## 9. Limites

Não substitui curadoria humana · não recalcula estrutura oficial das fontes · não cria equivalência
geral entre todas as fontes · não recria vínculo sozinho no import (reabre e pergunta) · H↔MÊS não mexe
em custo oficial.

---

## 10. Disclaimer canônico (módulo ativo)

Texto **literal** na tela de conversão entre fontes do Ativo:

> A conversão entre-fontes é algo que é persistido sobre o estado atual do banco de dados e representa
> vínculos com as edições mais vigentes disponíveis da fonte-base para com a SINAPI da mesma época.
> Recomendamos revisão cautelosa sobre as associações diretas e rigorosa sobre as associações com
> necessidade de conversão. A Axys Engenharia e Tecnologia LTDA não se responsabiliza pelas planilhas
> elaboradas, sendo que, atua pura e simplesmente como software/ferramenta de suporte.

---

## 11. Índice das regras e decisões citadas no código

As decisões foram tomadas pelo Renan entre 29/10 e 03/11/2026; o código as cita pelo número.

| no código | o que é | onde |
|---|---|---|
| regra 1 | direção maior → menor, parando na SINAPI | §1.4 |
| regra 2 | AXYS fora | §1.4 |
| regra 7 | o import cura novidade; revisar estado é a 5a | §5, §7.2 |
| regra 8 | nenhuma decisão sem justificativa | §1.6 |
| D1 | estado dos estágios em `catalogo.edicoes_estagios` | `imports/estagios.md` |
| D2 | `associacoes` depois do `documentos` | §5 |
| D3 | o "visto" é o banco; o que mudou é o histórico do catálogo | §6.2 |
| D4 | grava no fechamento da 5b, não no publicar | §5.8 |
| D5 | saiu como origem mantém par e negada; saiu como destino solta a origem | §5.2 |
| D6 | mudou perde o par na hora; o par anterior vai ao prompt | §5.2, §5.5 |
| D7 | X como alvo: busca reversa + confirmação por concordância dos dois motores | §5.3 |
| D8 | à IA vão os candidatos novos e os já recusados livres, com o motivo | §5.4, §5.5 |
| D9 | MDO no estágio, sem IA, só novidade | §4, §5.7 |
| D10 | sem gate de subgrupo | §2.5 |
| D11 | JSON por par de fontes, com `rodadas[]` | §6.3 |
| D12 | a busca enxerga a edição em curso (indexada inativa) | §5.1 |
| D13 | reabre só descrição/unidade; carimbo `AF_` sem IA, par mantido | §5.2, §5.3 |
| D14 | insumo principal como sinal (CPU) | §5.5 |
| D15 | transitividade como sinal, nunca decisão | §1.2, §5.5 |
