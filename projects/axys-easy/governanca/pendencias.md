# Axys Easy — Pendências de Governança

**Status:** Vivo
**Data:** 2026-06-03
**Escopo:** decisões de governança/arquitetura ainda não fechadas.

> Lista de pendências. Itens marcados `[ ]` estão abertos; `[x]` concluídos.

---

## Catálogo Colaborativo

Referência: [../modules/catalogo/AXYS_CATALOGO_COLABORATIVO_v0.md](../modules/catalogo/AXYS_CATALOGO_COLABORATIVO_v0.md) · [roadmap.md](roadmap.md)

- [ ] Definir arquitetura definitiva do Catálogo Colaborativo
  - [ ] Definir modelo de curadoria
  - [ ] Definir workflow de aprovação
  - [ ] Definir mecanismo de reputação
  - [ ] Definir política de versionamento
  - [ ] Definir política de licenciamento de contribuições
  - [ ] Definir critérios de promoção para catálogo oficial
  - [ ] Avaliar indexação e busca pública
  - [ ] Avaliar impactos de armazenamento

---

## Bancada — pontos de revisão

> Contêiner dos pontos de revisão da bancada (Renan tem ~13 a acrescentar). Trabalhar
> quando a frente da bancada for aberta; por ora só registrados.

- [ ] **Caderno de Encargos reflete a composição ADAPTADA da bancada.** A CTA/CTC (descritivo)
  em si não muda, mas a **composição dela** muda quando o item, na bancada, sofreu **rotação de
  regime** (mensalista↔horista, badge REG) ou **conversão de MDO/insumo** (`converter_mdo`/
  `converter_ins`). Nesses casos o Caderno deve refletir **o que está na BANCADA** (composição
  adaptada), não a CTC crua do R2. **Escopo (rigor):** aplica-se SÓ ao caderno sobre o que está
  na bancada — **NÃO** afeta os cadernos técnicos das EDIÇÕES do catálogo (esses seguem a fonte).
- [ ] **Composição própria sem descritivo bloqueia o Caderno de Encargos.** Composições próprias,
  ao serem criadas, não carregam descritivo (CTC) → não entram no caderno. Resolver: ou o
  descritivo passa a fazer parte da composição própria na criação, ou abre-se um campo para o
  usuário digitar antes da geração. (Provável item da revisão geral da bancada.)

---

## Vinculação entre fontes — redesenho (pensar no próximo ajuste)

Hoje: MDO-fonte→SINAPI (estrela com hub SINAPI) + pares curados. **Problema:** ligar todas as
fontes par-a-par é O(n²) (`n(n-1)/2` pares; cada fonte nova nasce com n-1) — inviável de curar à
mão; e a estrela-SINAPI **perde caminho** quando o conceito não existe no SINAPI (ex.: quer CDHU
primária e só há CDHU↔FDE direto, não CDHU↔SINAPI↔FDE).

**Direção decidida (2026-09-14, execução adiada):** HUB CANÔNICO **neutro** (não precisa ser AXYS,
nem SINAPI). Tabelas tipo `agrupador_insumos`+itens e `agrupador_composicoes`+itens (cabeçalho
canônico; itens entram como **fonte/código**). Cada fonte mapeia **1×** ao canônico → **O(n)**, e o
canônico é a **união** (mata o "não tem no SINAPI").
- **Insumo = coisa** → dicionário de *coisas* (equivalência exata; substituição via canônico).
- **Composição = texto/serviço** → dicionário de *serviços*; a **receita fica por-fonte** (mesmo
  serviço, receitas diferentes é OK). **Favoritar fonte** vira "qual fonte realiza o serviço" +
  fallback pelo nó canônico — **não** converter receita. Encolhe `converter_mdo`/`converter_ins`.
- Eixo separado: substituição fina de insumo/MDO dentro da receita (H↔MÊS) segue via *coisa*.

**Ressalva (por que adiar):** mesmo O(n) é MUITA curadoria (múltiplas fontes/composições,
re-curadas **a cada edição**). Precisa de estratégia de curadoria viável (IA-assistida com confiança
alta, que hoje não há) antes de valer a pena. Adiado junto com a revisão geral da bancada.
Ver: `../modules/catalogo/CATALOGO_VINCULACOES_INTRA_FONTES.md`, favoritar-fonte na bancada.
