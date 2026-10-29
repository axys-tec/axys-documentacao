# Associações entre fontes — a frente aberta

**Compila `RINGUE_ASSOCIACOES.md` + `REFACTOR_ASSOCIACOES_PLANO.md`** (os dois apagados em
10/10/2026), mais os achados da implementação das negativas. É o documento de TRABALHO da frente:
morre quando as duas últimas tarefas fecharem.

**A doutrina não está aqui — está no contrato.** `docs/projects/axys-easy/contracts/catalogo/vinculacoes.md`:
§1.1 (o que se guarda e o que não), §5.7 (as negativas), §6.2 (1×1 duro), §6.3 (curadoria fechada),
§11 (igualdade, não analogia), §12 (fonte→fonte), §14 (o 1×1 no banco). Contrato governa; este
arquivo só diz onde a obra está.

---

## ARESTAS A APARAR junto com o fechamento do motor de import/associações

Levantadas em 14/10/2026, ao avaliar o `publicar` depois de um restart do Render. **Não são bugs
ativos** — as duas publicações de associação são idempotentes de propósito (upsert por chave
natural; as docstrings dizem "reimport/re-publicar não duplica"), então re-publicar cura. São
defeitos de *transação* e de *ordem*, e o lugar de consertá-los é aqui, quando o esquema do motor
fechar. Fazer antes seria mexer no `publicar` duas vezes.

**O desenho de hoje.** `publicar_edicao` ([service.py](../../../../backend/modules/catalogo/service.py)) é
atômico: um `commit` no fim, com `pg_advisory_xact_lock(fte_id)` segurando a fonte — estado,
vigência, `cmp_ativa`/`ins_ativo` e audit entram juntos. Mas a publicação das associações roda
**antes** do lock e em **conexão própria**: `publicar_hmes` (SINAPI, comita par por par) ou
`aplicar_manifesto_vinculacao` (demais fontes, um commit).

**Aresta 2 — associação publicada com a edição ainda RASCUNHO.** Transação separada: morrer entre
as associações e o `commit` do publish deixa as amarras no banco e a edição não publicada. Nada
corrompe e o retry cura — mas é silencioso, e ninguém sabe que precisa de retry.

**Aresta 3 — elas escrevem FORA do advisory lock.** O comentário do próprio `publicar_edicao`
explica que o lock existe porque "publicar varre insumos/composições da fonte inteira e o import
escreve nas MESMAS linhas". As associações entram antes de ele ser tomado: duas publicações
concorrentes, ou publicar + importar, podem se intercalar ali. Risco baixo (upsert por chave), só
que a ordem é acidental, não projetada.

**O conserto das duas é o mesmo:** mover as duas chamadas para **depois** do advisory lock e passar
o `cur` já aberto para dentro delas, tirando o commit por par. As duas já recebem `conn=conn` na
auditoria, então enfiar o cursor é natural. O publish vira tudo-ou-nada, dentro do lock.

**E isso força UMA DECISÃO que ainda não foi tomada:** hoje um par ruim é pulado e o publish segue.
Em transação única é preciso escolher — par ruim **aborta** a publicação (rigoroso: obriga a curar
antes) ou publica e **mostra** o que ficou de fora. Decidir isso é parte do fechamento.

**Já aparado (14/10/2026):** o retorno de `publicar_hmes`/`aplicar_manifesto_vinculacao` era
descartado, e com ele as falhas par a par (guarda `t_cmm_guarda`, erro de banco, recusa de
curadoria). A edição publicava com amarra faltando e ninguém sabia — sem log, sem mensagem, sem
registro. Agora a conta sai na mensagem do publish, na resposta e no `audit.logs`
(`depois.associacoes`), que é o único lugar que sobrevive à sessão.

---

## O que está fechado — não reabrir

O ringue R0→R6 terminou em 23/09/2026. Cada round está no contrato; aqui fica só o índice:

| round | entrega | |
|---|---|---|
| R0 | vocabulário no banco (as três tabelas, o CHECK de status) | ✅ 22/09 |
| R1 | predicado do matcher — filtra o CANDIDATO, nunca o item | ✅ 22/09 |
| R2 | fonte × fontes (n−1 descendo por `fte_id`, sem ponte) | ✅ 22/09 |
| R3 | hash na identidade + a matriz status × hash | ✅ 23/09 |
| R4 | rejeição como cidadã (apagar a proposta a fazia renascer) | ✅ 23/09 |
| R5 | IA propõe, não cura nem revoga | ✅ 23/09 |
| R6 | o gate do import trava a ETAPA, com a conta saindo do banco | ✅ 23/09 |

**A curadoria fechou e está carregada**, em dev e em produção: **2.336 pares** (1.278 INS · 949 CPU ·
109 MDO) e **15.998 negativas** (6.638 INS · 9.360 CPU). Zero pendente, zero colisão de 1×1, zero
violação da exclusão mútua, sequence sem desperdício. Detalhe e validação no §6.3 do contrato.

---

## Achados da implementação das negativas (06/10/2026)

Cinco coisas que só apareceram ao executar, e que o desenho no papel não pegaria. Ficam aqui porque
são lição de implementação, não regra de negócio:

**1 · A hash do JSON não serve, e falharia calada em 75% das linhas.** O `hash_na_curadoria` dos
arquivos de curadoria é sha1 **cheio (40 chars)**; o `_hash` do serviço trunca em **16**. E truncar
não resolve: a normalização difere em **15%** dos casos (medido em 2.000 linhas). Guardar o do JSON
faria o matcher reabrir TODAS as negativas na primeira rodada — a tabela existiria sem servir.
**Regra:** a hash sai da mesma função que faz a pergunta. Confere hoje em 15.998 de 15.998.

**2 · Impressão de conjunto responde a pergunta errada.** Hash de conjunto só diz "idêntico?", e o
universo que a curadoria examinou veio de OUTRO produtor (os scripts, com funil e teto próprios) —
nunca bateria com o que o matcher monta. A pergunta certa é *"apareceu candidato que ninguém
examinou?"*, e ela exige a **lista** (`BIGINT[]`), não a impressão.

**3 · A lista soma, não substitui.** Substituir faria a negativa ENFRAQUECER quando o universo de
hoje fosse mais estreito que o de ontem, e deixaria os dois produtores oscilando: cada rodada
reabrindo o que a outra silenciou. Somando, a memória só cresce.

**4 · O seed não terminava contra produção.** Uma ida ao banco por item: 16 mil × latência até Ohio.
Virou lote (uma regra, dois motoristas — `_grava_negada` para a tela, `grava_negadas_lote` para o
seed) e o `--so-negadas` deixou de conferir pares. **De mais de meia hora para 3 s em ensaio e 21 s
gravando.** É a mesma lição do import: o gargalo não é o banco, é a ida e volta até ele.

**5 · Negar o item não é rejeitar o par.** `decidir(..., 'rejeitado')` mata a DUPLA e o item segue
recebendo outros candidatos — "é o que separa memória de cemitério". Negar o item é outro ato, e
virou `negar_item` / `reabrir_item`. O `decidir` ficou intocado.

**A costura da primeira passada.** Com as negativas carregadas, 1.778 itens silenciaram e 2.837
reabriram — **nenhum por hash**, todos porque o universo examinado veio de ferramenta diferente
(mediana de 30 examinados contra 15 que o matcher mostra, 4 deles novos). Custa UMA passada: quando
o matcher julgar esses itens e a recusa for registrada por `negar_item`, a união guarda os dois
universos e eles silenciam para sempre.

---

## O que falta — as duas últimas

### 1 · As telas de curadoria

Hoje a curadoria da vizinhança acontece em **script de terminal**
(`z_scripts_apoio/analise_associacoes/cura_terminal.py` + `cura_ui.py`). Não há rota nem tela: o
`montar_vizinhancas` só é alcançável por `roda_vizinhanca_ia.py`. As telas que existem
(`/catalogo/equivalencias/{ins,cpu,mdo}`) são do manifesto ANTIGO e curam par-a-par.

A tela nova tem de mostrar a **vizinhança** (família na origem × família espelho no destino, a IA
ordenando e justificando) e oferecer os três atos: confirmar um, **negar o item** (com a lista de
candidatos que estava na tela — é ela que vai para `ein_candidatos`), ou devolver ao gate.

### 2 · O plugue no ato do import

**Bloqueio conhecido, e é de escopo, não de fiação.** O import roda
`rodar_vinculacao` → `propor_ins` (token) + `propor_cpu` (funil de subgrupo), que é o matcher
REPROVADO. Trocar pelo novo não é possível hoje: **`montar_vizinhancas` cobre só insumos** — não
existe matcher de vizinhança de COMPOSIÇÃO no backend. A curadoria de CPU foi feita pelos scripts,
com insumo principal + analítico (`define_principal.py`, `contexto_composicoes.py`). Trocar agora
perderia composições inteiras.

**Portanto a ordem é:** portar o principal/analítico para o backend (matcher de vizinhança de CPU) →
só então trocar o `rodar_vinculacao`.

**Mitigação já aplicada (06/10), para o import não doer enquanto isso:** `propor_ins` e `propor_cpu`
passaram a respeitar as negativas. No matcher antigo só a hash do item governa (o universo DELE não
é registrado em lugar nenhum), e isso basta:

| par | INS no universo → silenciados | CPU no universo → silenciados |
|---|---|---|
| CDHU → SINAPI | 3.328 → 2.674 (−80%) | 3.673 → 3.259 (−88%) |
| FDE → SINAPI | 2.473 → 2.065 (−83%) | 3.490 → 3.212 (−92%) |
| FDE → CDHU | 2.473 → 1.899 (−76%) | 3.490 → 2.889 (−82%) |

Rodado ponta a ponta em dev com rollback: CDHU→SINAPI proporia **3 pares** em vez de milhares.

---

## Dívidas vivas — conferidas em 10/10/2026

| dívida | estado |
|---|---|
| matcher do import é o reprovado | **viva** — ver o bloqueio acima; mitigada pelas negativas |
| gate do import não cobre o SINAPI (o manifesto é "só de fonte") | **viva** — desde o R2 o SINAPI também propõe |
| `insumos_equivalencias` (legada) ainda de pé | **viva, mas encurralada** — sobrou `insumos_service.py` (3 pontos) + 3 templates (`insumos.html`, `insumo_form.html`, `ativos/consulta_insumos.html`) |
| só o lado da FONTE revalida; reimport de SINAPI não reabre vínculo | **viva** — `revalidar_hashes` foi removida, mas a sucessora `divergencia_por_hash` também só olha par CONFIRMADO |
| matcher propõe item morto (predicado certo é presença na edição, não `ins_ativo`) | **a conferir** |
| `M2XME` no CDHU (unidade truncada na origem) tratado no matcher, não na fonte | **viva** — cosmética, mas é remendo em lugar errado |
| 90 descrições do FDE com dois itens colados | **viva** — mora em `governanca/pendencias.md` ("FDE — descrições com DOIS itens colados") |

---

## O que morreu — não procure

- **`insumos_equivalencias` como funil de CPU**: o funil de subgrupo morreu com o sinal novo (a
  família estreita, o analítico decide). A TABELA `equivalencias_subgrupos` segue viva em outro
  papel: gate do import (estágio 1→2).
- **A ponte pelo SINAPI**: `CDHU→FDE` não salta mais por terceiro. A relação é simétrica e **não
  transitiva** — está escrito no topo de `equivalencias.py`.
- **`LIMIT 1` sem `ORDER BY`** nos 66 grupos N:1: resolvido pelo 1×1 duro (um item tem no máximo um
  parceiro por fonte, então o `LIMIT 1` é determinístico).
- **"Composições sem curadoria humana"**: 949 pares curados.
- **"CDHU×FDE limitado a insumos"**: 491 pares de composição existem.
- **`'refutado'` como sexto status** e o **`NULL`→`1.0` calado**: removidos.
- **O §8.1 do plano** ("ausência não se guarda, e o retrabalho é aceito"): revogado pelo §1.1 do
  contrato em 06/10. O que se guarda não é ausência — é decisão humana datada, com o universo que
  ela examinou.
- **`MATCHER_VIZINHANCA.md`**: aplicado; o desenho vive no docstring de
  `backend/modules/catalogo/matcher_vizinhanca.py` e no contrato.

---

## PENDENTE — limpeza de sobras versionadas

`z_scripts_apoio/_out_associacoes/` tem três CSV de backup (`backup_carimbo_fde_local`,
`backup_carimbo_fde_prod`, `backup_equivalencias_mo_prod`, de set/2026) **versionados**, somando
323 MB na pasta em disco. **É conteúdo de teste e jamais deveria ter entrado no repositório.**

Investigar, e depois remover:

1. Esses três CSV ainda servem a alguma conferência, ou o que eles guardam já está no banco?
2. Varrer o repositório atrás de outras sobras do mesmo tipo — saída de script, dump, planilha de
   apuração — que tenham sido versionadas sem querer.
3. Quem sair, sai com a entrada correspondente no `.gitignore`, senão volta na próxima rodada.

Já saíram nesta frente (20/10/2026): `_claude_memory/`, `z_scripts_apoio/_out_mdo/` e os derivados
de `cognatos_saida/`. **Não** saiu `_out_cad/_cadernos_urls.json`, que parecia sobra e é entrada de
`publicacao/regera_apresentacoes.py`.
