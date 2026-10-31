# Descartar um import de edição: estudo para decisão

*30/10/2026 · leitura de código + banco de dev (só SELECT). Pendência de origem: `final_associacoes.md` §11 ("import abandonado no meio") e §6/§11 (backfill regride o texto).*

> **ENCERRADO — decisão do Renan, 30/10/2026: não há descarte de import.** Não existe despublicação;
> import começa porque saiu edição nova. No lugar das opções A–D:
> - a edição sobe em **sequência** e só se mexe na última da fonte — cadastro só com a anterior publicada e
>   mês posterior; importar, rodar estágio e reabrir recusam edição superada (`contracts/catalogo/edicoes.md`
>   §2.1). Isso também fecha o backfill do §6;
> - o vazamento da janela (§0) se resolve na leitura: a edição que vai cair continua valendo **pelo
>   histórico** até a nova ser publicada (`contracts/ativo/bancada_orcamento_contrato.md` §9.1). Inativar a
>   composição removida no import (ideia da nota abaixo) não entra: tiraria da busca uma composição ainda
>   vigente pela edição publicada, e as removidas já leem a receita do histórico;
> - a associação aberta já serializa os imports entre fontes (§3.2).
>
> O resto do documento fica como registro do estudo.

---

## 0. Em uma tela

**O problema é maior que a associação.** O rascunho já está dentro do catálogo vigente. Medido na SINAPI 09/26 (edição 63, RASCUNHO):

- **312 composições vigentes** (ativas, da 08/26 publicada) já mostram o **texto e a receita da 09/26**. A receita são os coeficientes, e é ela que a bancada lê e o orçamento captura.
- **6 composições vigentes estão sem nenhum item.** São as que a 09/26 inativou: o import apagou a receita delas, mas elas continuam ativas porque a 08/26 é a vigente.
- **382 CTCs vigentes** já apontam para a versão da 09/26.

Um orçamento que capture uma composição da SINAPI hoje leva a receita de uma edição que ninguém publicou. Descartar o import, então, não é só fechar a associação: é **devolver o catálogo a como estava**.

**Hoje não existe descarte.** Não há rota, função nem script. O único ponto de retorno é a cópia inteira do banco de dev (`axys_easy_db_bkp_0826`), que não serve para prod.

**Recomendação.** Opção **C, a "foto do antes"**: o Preços passa a guardar, na primeira passada, o estado exato das linhas da fonte que o parser vai mudar, e descartar é repor essa foto. As **falhas que valem qualquer que seja a escolha** (§3.2) já foram corrigidas. Para o backfill, **bloquear agora** e usar a mesma foto quando houver backfill de verdade (§6).

R: Olha só. Descatar o import é algo que nao foi pensado porque, simplesmente não existe uma "despublicação". Ao iniciar um impoort, é porque saiu nova edicao. O que nao fazemos (suponho que nao) e talvez, devessemos fazer é verificar no import se é mesmo edicao nova (mais nova que a última publicada) ou se o user está selecionando arquvios que já não foram servidos anteriormente. Isso, deveria acontecer, logo no começo, que é a tomada dos arquivos e ainda não mexe em banco.

Agora, temos um porém, que é o estado de transição. Teoricamente, importar uma edicao, até fechar, vai gerar isso que vc viu, até que se realize o publicar [eu já recomendaria, após o estágio 2, já que tocou no banco, inativar a composicao que foi removida, porque isso assegura que, bancadas com edicao n-1 peguem a receita da época correta e nao morram em silencio]. 

Feito isso, acho que está assegurado. A CTC to pegando erros em prod. Tem coisas que nao estao com arquivos sendo servidos e isso é ruim. Mas, ela deve servir sempre o arquivo daquela edicao. Logo, nao era para mostrar dado errado.

E eu acho que, agora, mesmo com ctc/associacao via IA, nao levaramos mais que meia hora por import, da sinapi sobretudo que é o maior de todos. estou certo? Se sim, é algo inerente ao processo. O que podemos fazer é bloquear a tela de import até que se feche a edicao.

A APp deve chegar, no auge, com umas 30 fontes-base. Isso dá uma por dia, nao é algo complicado.

Qual sua ideia?

---

## 1. O que um import da edição E da fonte X escreve

A coluna "Volta como?" responde se dá para desfazer só com o que já existe hoje.

### 1.1 Só da edição E (sai apagando por `edi_id`)

| O quê | Estágio | Na 63 | Volta como? |
|---|---|---|---|
| `insumos_preco` | Preços | 131.760 linhas | apaga por `pri_edi_id` |
| `composicoes_custo` | Preços | 858.519 linhas | apaga por `cc_edi_id` |
| `insumos_familia` (SINAPI) | Preços | 4.878 | apaga (cascade) |
| `edicoes_leis_sociais` + `_itens` | Preços, Dados | 54 | apaga |
| `edicoes_bdi` + `_composicao` (FDE) | Preços | 0 | apaga |
| `insumos_historico` / `composicoes_historico` de E | Preços (diff) | 4 + 379 | apaga por edição: é exatamente o que o import já faz na reexecução |
| `documentos` com `doc_edi_id = E` (originais, caderno técnico) | Preparar, Documentos | 5 | apaga a linha e os arquivos de `fontes/{x}/{edicao}/` |
| `edicoes_estagios`, `edi_docs_status`, `edi_paths`, pendências da edição | todos | 14 linhas | apaga/zera (cascade) |
| storage da edição: `originais/`, `_state/`, `precos/`, `processamento/` (H↔Mês), `caderno_tecnico_{ed}.html` | todos | — | apaga o prefixo da edição |

Esta parte é fácil e completa. As FKs de `insumos_preco`, `composicoes_custo`, histórico e LS são `RESTRICT`: a ordem de apagar importa, mas nada fora do catálogo aponta para a 63 (`ativo_orcamento_parametros`: 0).

### 1.2 Da fonte X, sobrescrito (aqui mora o problema)

O parser não escreve "a versão de E". Ele escreve **a identidade da fonte**, uma linha por código:

| O quê | Quem escreve | Fica registrado em algum lugar? |
|---|---|---|
| `ins_descricao`, `ins_unidade` | Preços (3 fontes) | **sim**: `ih_dados_anteriores` no evento `ALTERACAO` |
| `ins_ti_id`, `ins_ti_origem` (classificação; na SINAPI a da fonte vence até a MANUAL) | Preços | **não** |
| `cmp_descricao`, `cmp_unidade` | Preços | **sim**: no snapshot anterior (`ch_dados_novos` da edição anterior) |
| receita: `composicoes_itens` (apagada e regravada; na inativação, só apagada) | Preços | **em parte**: o snapshot guarda insumo/sub-CPU e coeficiente, **sem `ci_ordem` nem `ci_situacao`** (os 56.568 itens da SINAPI têm situação) |
| `cmp_sub_id`, `cmp_grupo_id`, descrição de grupos e subgrupos | Preços | **não** |
| `cmp_situacao`, `cmp_motivo_sem_custo`, `cmp_tem_item_sem_preco/_custo` | Preços | **não** |
| `cmp_primeira_pub`, `cmp_ultima_pub`, `cmp_ultima_alteracao` | Preços (diff) | **não**, mas dá para recalcular pela presença nas edições (na 63: 10.599 / 312 / 58 com 09/26) |
| itens **criados** por E (insumo, composição, órfão, auxiliar SINAPI) | Preços | **sim** (`CRIACAO`); nascem inativos. Na 63: 4 insumos e 58 composições |
| CTC: `cmp_descritivo.versoes` e `cmp_external_path.ctc.versoes` | Documentos | **sim**: versão marcada `desde_edi = E` (382 na 63). O MD em `ctc/doc/{cod}.md` foi sobrescrito, e o anterior está em `ctc/_old/`. O `ctc/_index.json` foi sobrescrito, mas reconstrói-se pelo `req_hash` da versão anterior |
| fichas SINAPI (`ins_external_path.ficha_tecnica`) e caderno por CPU (`cmp_external_path.caderno_tecnico`) | Dados | **sim**: versão `desde_edi = E` (6 e 3 na 63). HTML anterior em `_old/`, `_index.json` e `_versoes.json` sobrescritos |
| livros, notas, cadernos da fonte (`documentos` fonte-level, `doc_vigente`) | Preparar, Dados | anterior arquivado em `_old`/`inativos`. São documentos **do site da fonte**, não do arquivo da edição |
| `catalogo.unidades` (sigla nova) | Dados | global e inofensivo (0 na 63) |

### 1.3 Busca

`search_document` (Postgres) e OpenSearch são **derivados**. O estágio `associacoes` indexa X pela presença em E (D12), e o import dispara `reindex_search`. Volta com um reindex da fonte. O cache Redis volta com um purge da fonte.

### 1.4 Estágio `associacoes` (só se chegou a rodar)

| O quê | Quando | Volta como? |
|---|---|---|
| **pares apagados** do que mudou ou saiu (INS, CPU, MDO) e pares por carimbo recusados pela IA | início do estágio (`_monta`), **commitado** | o índice da fila guarda `removidos`, mas **incompleto**: id, ori, dest, fontes, fator, classe, status, observação. Faltam `score`, `metodo`, `hash_ori/dest`, `criado_em/por`. Na 63: 0 par removido (nenhum item mudado tinha par) |
| fila: `easy/fontes/associacoes/_fila/{E}/` (índice, um JSON por item, `_confirmacao_carimbo.json`) | estágio | apaga o prefixo |
| pares e negadas novos, hashes renovadas por carimbo | **só no fechamento** da 5b | antes do fechamento não há nada a desfazer. **Depois** dele, outras fontes já podem ter importado sobre esses pares |
| `rodadas[]` nos JSON por par de fontes | só no fechamento | a rodada carrega `edicao`; removível, mas é corpo de fine-tuning |
| custo de IA (CTC + associação) | — | não volta |

### 1.5 O que nenhum descarte devolve

- **Orçamento que capturou composição da fonte X durante a janela.** A `captura_estado` copia receita e texto para `ativo.*`, e isso é do tenant.
- Custo recalculado de **edição anterior** durante a janela (`recompute_custo`), porque o cálculo usa a receita vigente, que já é a de E.

---

## 2. O histórico basta para devolver o "antes"? Medido na 63

| | Eventos | "Antes" completo? |
|---|---|---|
| insumos `CRIACAO` | 4 | não há "antes": o item não existia |
| insumos `ALTERACAO` | 0 na 63; **1.709/1.709** completos no banco todo | sim (descrição + unidade) |
| composições `CRIACAO` | 58 | não há "antes" |
| composições `ALTERACAO_*` | 297 cabeçalho+itens, 15 só itens | **312/312** têm snapshot anterior com descrição, unidade e receita; em 297/297 o `de` do diff bate com o snapshot |
| composições `INATIVACAO` | 6 | o snapshot anterior tem a receita apagada |

**Conclusão: para texto, unidade e coeficiente, o histórico basta.** Para o resto, não:

1. **Não registra:** classificação do insumo, subgrupo e grupo da composição, situação, ordem e situação dos itens, flags de sem preço/sem custo.
2. **Desfaz correção manual.** O snapshot é o texto que veio da fonte, não o texto do banco. Na FDE, **78 composições** têm hoje texto diferente do último snapshot porque o `limpa-carimbo-fde` as corrigiu depois do import. Se uma edição mexer numa delas e for descartada pelo histórico, a sujeira corrigida volta.
3. **Não cobre CTC, fichas e cadernos.** Esses têm versão própria (`desde_edi`), então dá para desfazer, mas por outro caminho.

---

## 3. O que existe hoje

### 3.1 Para descartar

Nada. Não há rota, função nem script que apague edição ou desfaça import. `reabrir_edicao` é o recall de uma PUBLICADA (vira EM_REVISAO para reimportar) e não desfaz nada. `remover_preco_edicao` apaga um preço. Em dev, o plano usa a cópia do banco `axys_easy_db_bkp_0826` como ponto de retorno.

### 3.2 Falhas achadas — já corrigidas em 30/10, valem para qualquer opção

1. **A guarda do §6 não via associação em `erro`.** Se o estágio commitasse a remoção de pares e depois
   caísse (IA sem resposta, JSON do fechamento), outro import podia começar com pares já apagados no chão.
   **Corrigido:** `erro` com a fila gravada e não fechada conta como aberta (`ee_detalhe.fila_gravada`);
   erro antes disso (pré-condição, motor fora do ar) não segura ninguém. Provado na simulação: a 62 em
   `erro` pela conta da IA travou a 61 (409), e a recusa da 61 não travou a 62 de volta.
2. **Reimportar E por cima reaproveitava a fila velha.** **Corrigido com trava:** Preços/Dados de E não
   rodam com a associação de E aberta (409 "feche a curadoria dela antes de reimportar"). Derrubar a fila
   repondo os `removidos` — o "cancelar associação" — é parte da decisão abaixo (opções A e C).
3. **Achada na simulação:** a rota "avançar estágio" marcava `associacoes` como `ok` sem curadoria, perdendo
   os pares do início. **Corrigido:** `associacoes` só fecha pela 5b.

---

## 4. Opções

### A. Não descartar: só retomar ou reimportar por cima (+ "cancelar associação")

- **O que faz.** O caminho para uma edição ruim é corrigi-la: subir o arquivo certo e rodar o Preços de novo (o parser é idempotente e o histórico da edição é refeito). Acrescenta-se só um botão **"cancelar associação"**: repõe os `removidos`, apaga a fila e marca o estágio como não concluído.
- **Reverte:** só os pares do início do estágio.
- **Fica:** tudo o mais. O texto e a receita de E continuam no catálogo vigente até a próxima edição. Uma edição abandonada de vez (arquivo errado, desistência) não tem saída: o catálogo carrega o rascunho para sempre.
- **Custo:** ~½ dia.
- **Risco:** baixo de código, **alto de produto**. É o vazamento que medimos (312 + 6 composições vigentes), sem prazo para acabar.
- **Associação e serialização:** resolve a trava. Cancelar libera as outras fontes sem curar 193 itens de uma edição que ninguém quer.

### B. Descartar pelo histórico (sem mudar o import)

- **O que faz.** Apaga tudo do §1.1. Devolve a identidade pelo histórico: composição volta ao snapshot anterior (texto, unidade, receita), insumo volta ao `ih_dados_anteriores`, e item criado por E é apagado se nada o referencia (senão fica inativo). Tira as versões `desde_edi = E` de CTC, ficha e caderno e copia de volta do `_old/` o arquivo anterior. Recalcula as datas de publicação, repõe os pares de `removidos`, apaga a fila e reindexa a fonte.
- **Reverte:** texto, unidade, coeficientes, receita das inativadas, CTC, fichas, cadernos por CPU, pares.
- **Fica errado:** classificação, subgrupo e grupo, situação, ordem e situação dos itens, flags. Correções manuais posteriores ao snapshot são desfeitas (o caso das 78 da FDE). Os pares voltam sem `score`/`metodo`/`criado_*`.
- **Custo:** 2 a 3 dias.
- **Risco:** médio. A restauração é aproximada e o erro é silencioso: a composição volta "quase" como era.
- **Associação e serialização:** igual à C (abaixo).

### C. Descartar pela "foto do antes" (recomendada)

- **O que faz.** Na **primeira** passada do Preços de E, dentro da mesma transação do parser: tira uma foto da identidade da fonte (insumos, composições, receita, grupos e subgrupos) numa tabela temporária, roda o parser e o diff e, antes do commit, grava **só as linhas que mudaram**, com a linha inteira de antes. A gravação vai para `_state/antes.json` da edição ou uma tabela por edição; isso fica para decidir. A reexecução **não sobrescreve** linha já guardada (a mesma lição do F2), só acrescenta as que mudam pela primeira vez. O `removidos` da associação passa a guardar a linha inteira do par.
- **Descartar** = apagar o §1.1, repor a foto linha a linha, tirar as versões `desde_edi = E` e copiar de volta o `_old/` do CTC, apagar os itens criados por E que nada referencia, repor os pares inteiros, apagar a fila, reindexar e purgar o cache. A edição volta a RASCUNHO vazia (preparar = pronto); excluir a linha da edição, se quiser, é outro botão, trivial.
- **Reverte:** tudo o que o parser escreve, exatamente, inclusive classificação, subgrupo, situação, ordem e correções manuais. A foto é do banco, não da fonte.
- **Fica:** orçamentos capturados na janela (§1.5) e o custo de IA. Os documentos do site da fonte (livros, cadernos-fonte) ficam, porque são verdade independentemente da edição.
- **Tamanho:** na 63 são 376 composições, 2.061 itens de receita e 4 insumos. Coisa de kilobytes. A foto inteira da fonte só vive na tabela temporária (SINAPI: ~27 MB, quase tudo descritivo; sem descritivo, ~9 MB). Nada sobe para a memória do worker.
- **Conflito:** se alguém mexeu numa linha da fonte depois do import (5a, curadoria manual), o descarte não a sobrescreve às cegas. Repõe só a linha cujo estado atual é o que E escreveu e lista as outras para decisão.
- **Custo:** 3 a 4 dias, com teste na própria 63: descartar e conferir linha a linha contra `axys_easy_db_bkp_0826`, que é a prova perfeita.
- **Risco:** baixo de fidelidade. O ponto de atenção é a foto valer só a partir da primeira passada: edição já importada antes da mudança cai na opção B.
- **Associação e serialização:**
  - pode descartar com a associação aberta (`rodando`, `pendente_user`, `erro`): repõe `removidos` (pares, MDO, carimbo recusado) e apaga a fila; negadas não foram tocadas;
  - **não pode descartar depois do fechamento da 5b**: os pares e negadas gravados já são o chão de outros imports. Daí em diante, a edição segue para publicar ou é corrigida por reimport;
  - o descarte roda sob o lock da fonte e o lock global da associação, e termina com a associação de E fora de "aberta", o que libera os outros imports;
  - só para RASCUNHO. PUBLICADA e EM_REVISAO ficam fora (a foto até permitiria, mas é outro escopo).

### D. Estrutural: o rascunho não toca o catálogo vigente

- **O que faz.** O parser grava identidade e receita de E numa área da edição, e o **publicar** promove para a fonte. Descartar vira apagar a área. Backfill nunca promove.
- **Reverte:** tudo, por construção, e acaba com o vazamento da janela.
- **Custo:** semanas. Busca (D12), CTC, associação, diff e o cálculo de custo das três fontes leem a identidade da fonte e passariam a ler "fonte ou área de E".
- **Risco:** alto agora, com o estágio de associação recém-plugado.
- **Associação:** natural. Mas é refazer o chão em que F1–F6 foram provadas.

### Comparação

| | Reverte texto/receita | Reverte o resto | Fidelidade | Custo | Encerra o vazamento da janela |
|---|---|---|---|---|---|
| A | não | não | — | ½ dia | não |
| B | sim | em parte | aproximada | 2–3 dias | só ao descartar |
| **C** | **sim** | **sim** | **exata** | **3–4 dias** | só ao descartar |
| D | sim | sim | exata | semanas | **sim** |

---

## 5. Recomendação

**C** (as correções do §3.2 já estão feitas).

- **A** deixa sem saída a edição que se quer abandonar, e o catálogo carrega o rascunho para sempre.
- **B** devolve "quase": a classificação, o subgrupo e a correção manual voltam errados sem ninguém ver. É o tipo de defeito que já custou caro (16/10, 14→20/10).
- **D** resolve a raiz, mas é refazer o chão das F1–F6. Vale como frente própria se o vazamento da janela incomodar mais que o descarte. A medida de hoje sugere que pode incomodar: 318 composições vigentes alteradas por um rascunho.
- **C** é exata, pequena em dado (kilobytes por edição) e serve também ao backfill (§6). A prova é barata: descartar a 63 e comparar com a cópia `bkp_0826`.

**Para decidir:**
1. A, B, C ou D.
2. Na C: foto no storage (`_state/antes.json`) ou numa tabela por edição. Com a doutrina storage > banco para coisa pontual, o storage. Mas o descarte precisa dela inteira e confiável, e o storage é best-effort.
3. Descartar apaga a linha da edição ou a deixa como RASCUNHO vazia (sugiro vazia).

---

## 6. À parte: importar edição antiga (backfill) regride o catálogo

**O que acontece hoje.** O import de uma edição mais antiga que a vigente:

- sobrescreve texto, unidade, classificação, subgrupo e **receita vigente** com os da edição velha;
- tira do item o que a edição velha não tinha: na "inativação" contra a edição anterior a ela, **apaga a receita de composições que hoje estão vivas**;
- grava o histórico com o sentido trocado (o diff da edição velha compara com o snapshot mais recente);
- só a associação está protegida (`skip`).

A vigência (`ativo`) não sofre, porque o publicar recalcula pela mais nova. O resto fica errado até o próximo import da edição mais nova.

**Medido:** em dev as 63 edições estão em ordem cronológica de id e não há nenhum sinal de backfill no histórico (0 evento fora de ordem). O risco é latente, não ocorrido.

| Opção | O que faz | Custo |
|---|---|---|
| 1. Bloquear | Preparar/Preços recusa edição com mês anterior ao da vigente publicada da fonte, com mensagem | horas |
| 2. Backfill em "caixa de areia" | mesma mecânica da foto (C): na mesma transação, foto → parser → custos e preços da edição velha (que precisam da receita velha) → **repõe a foto** antes do commit. A identidade não muda; o histórico de backfill é gravado à parte ou pulado | ~1–2 dias, depois da C |
| 3. Reimportar a mais nova depois | conserta por cima | depende dos originais da vigente, que nem sempre existem: FDE 07-26 em dev não tem os CSV, só PDF/aspx |

**Recomendação:** **1 agora** (barato, fecha a porta). **2 quando houver backfill real**, aproveitando a foto da opção C.

---

## Apêndice: como foi medido

- **Código lido:** `import_service.py` (SINAPI, CDHU, FDE novo, Documentos/CTC), `parser_cdhu.py` (`snapshot_insumos`, `aplicar_diff_edicao`), `parser_sinapi.py`, `parser_fde.py`, `service.py` (`publicar_edicao`, `reabrir_edicao`), `estagios.py`, `associacoes_estagio_service.py`, `associacoes_service.py` (`desfaz_pelo_delta`, `associacao_aberta`), `jobs_async.py`, `routes.py` (guarda do §6), `storage_paths.py`, `schema.sql` (FKs, `equivalencias_ins`).
- **Banco de dev** (`EASY_DB_URL` do `.env.local`), só SELECT, em 30/10 entre 12:20 e 12:35. **O dev estava em movimento:** uma simulação rodava o estágio `associacoes` da 63 no mesmo momento (linha 450 `rodando`, 3 eventos `simulacao`). As contagens de histórico excluem esses 3.
- **Ressalva:** `.env.local` aponta o R2 de **produção** (`final_associacoes.md` §10.1). Para procurar a fila da 63, fiz leituras de listagem nesse bucket (prefixo `_fila/`, `sinapi/08-26/originais/`, `cdhu/203/originais/`, `fde/07-26/`). Nada foi escrito. A fila real da 63 não está lá: a bancada grava no storage local.
