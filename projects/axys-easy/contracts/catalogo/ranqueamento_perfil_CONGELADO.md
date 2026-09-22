# Ranqueamento de busca por PERFIL de uso — contrato CONGELADO

> **STATUS: CONGELADO / NÃO IMPLEMENTAR AGORA.** Decisão 2026-09-22 (Renan).
> Design fechado e viável, mas **payoff marginal** frente à busca-base já entregue. **Não nasce com a
> app.** Reativação só sob HOMOLOGAÇÃO CONTROLADA (ver §7): liga em A/B, pergunta "melhorou?" — se não,
> cancela definitivo. Documentado para não reperder a discussão.
> Irmão de [listagem.md](listagem.md) e [cognatos_glossario.md](cognatos_glossario.md).

## 1. Motivação
Um orçamentista tem um PERFIL (segmento): estradas, edificações, saneamento, urbanismo... Ao buscar um
**termo ambíguo cross-segmento** (ex.: "concreto"), o ideal seria o perfil dele ordenar primeiro a
variante do seu mundo:
- **cara de estradas:** concreto → **concreto betuminoso/asfáltico** primeiro
- **cara de edificações:** concreto → **concreto usinado** primeiro

## 2. Regra INEGOCIÁVEL: velocidade
Ranqueamento **não pode** deixar a busca mais lenta. Portanto o desenho obriga:
- **Pós-read**, sobre os candidatos BASE já cacheados (user-agnósticos, compartilhados) — nunca re-query.
- **Nunca** cache por-usuário (explode) nem boost dentro do OpenSearch com params do user (mataria o cache
  compartilhado). O boost mora **na app**, depois do read.
- Custo no caminho da busca: **~0** (reordenar ~50 candidatos + 1 leitura de afinidade).

## 3. Propostas levantadas (e por que caíram)
| Proposta | Veredicto |
|---|---|
| Afinidade **por item** (insumo/composição) | ❌ Caro: 1000+ linhas/orçamento × 50 users × 5/mês → não paga. |
| Afinidade **por grupo** (`cmp_grupo_id`, 77 grupos) | ❌ Muitos grupos **e** a SINAPI (maior fonte) **não tem grupo** (só CDHU=61, FDE=16) → fura. |
| Afinidade **por SEGMENTO (~6)** | ✅ Modelo final viável (§4). |

## 4. Modelo final viável (o que se implementaria, SE reativado)
Dimensão = **~6 SEGMENTOS** (o modelo mental do orçamentista): `estradas, edificações, saneamento,
urbanismo, terraplenagem/fundação, instalações`.

- **Só COMPOSIÇÕES.** A bancada quase não busca insumo → insumo fica no ranking base.
- **Classificação NA HORA (sem coluna, sem mudar o import):**
  - só os **~50 candidatos da busca atual** (≈ regex, microssegundos) e os comps de **um orçamento no
    save** — nunca "cada item o tempo todo".
  - **multi-segmento é natural:** o item cai em 1+ segmento e ganha boost do(s) segmento(s) do user. (O
    problema do "1+ segmento" só existiria se fixássemos uma coluna `_segmento` — por isso NÃO se fixa.)
  - fonte do rótulo: mapa curado **grupo→segmento** (77 linhas, 1×) onde há grupo (CDHU/FDE) + **regra por
    palavra-chave** onde não há (SINAPI). Curável com IA + crivo humano, como os cognatos.
- **Afinidade = ~6 números por user** (`{estradas:40, edificacoes:12, ...}`), da contagem por segmento do
  uso na bancada. Custo desprezível (50 users ≈ 300 números no total).
  - Verdade + re-warm: tabela `catalogo.user_afinidade(user_id PK, segmentos JSONB, atualizado_em)` — 1
    linha/user. Espelho em Redis `rank:{user}`. Redis morreu → recomputa do orçamento (durável).
  - Write: hook no salvar da bancada → comps → segmento → +contagem (~3-4 por orçamento).
- **Boost pós-read** no ponto único: `final = score_base + Σ (%-uso_segmento × TETO_limitado)`.
  - **Cold-start:** sem afinidade = ranking base de hoje.

## 5. Evidência empírica (por que NÃO sequestra query específica)
Testado com dados reais (busca CPU, boost forte +200 no grupo de estradas):
- **"concreto usinado"** (específico) → base **6901** (match exato de 2 palavras). Boost +200 **não move**
  → usinado fica no topo. **Sem hijack.**
- **"concreto"** (ambíguo, 1 palavra) → todos empatam ~1100-1280 → boost +200 **reordena** → cara de
  estradas vê "CONCRETO ASFÁLTICO" em 1º.

Conclusão: **a afinidade só age em EMPATE de relevância.** Query específica tem gap enorme (match exato
= milhares) → intocável. Garantia de design: manter o TETO do boost << scores de match exato (dezenas/
centenas, nunca milhares).

## 6. Por que CONGELAR (não nascer assim)
- **Payoff estreito:** só mexe em termo ambíguo cross-segmento; a busca-base (elástica + cognatos +
  fallback) já resolve a esmagadora maioria.
- **Custo de manutenção real:** classificador de segmento + mapa grupo→segmento + afinidade + hooks — sem
  viabilidade COMPROVADA por uso.
- Decisão: **deixar a app rodar, usuários se acostumarem.** Não gastar mais tempo discutindo no vazio.

## 7. Condição de REATIVAÇÃO (homologação controlada)
1. Sinal de demanda real: orçamentistas reclamando que o termo ambíguo mostra a variante errada pro perfil
   deles (não achismo).
2. **Instrumentar busca→seleção** (qual candidato foi escolhido, em que posição) — vira métrica E sinal.
3. Ligar em **A/B numa homologação controlada** e perguntar: **"melhorou?"**
   - **Sim** → promove.
   - **Não** → **cancela definitivo** e este contrato vira histórico.

## 8. Referências
- Busca: [listagem.md](listagem.md) · [cognatos_glossario.md](cognatos_glossario.md)
- Memória: `project_busca_elastic_tuning`, `project_busca_ranking`
- Plug pós-read: já existe a costura (candidatos BASE → boost → reidrata) em `buscar_filhos`/`buscar_insumos`.
