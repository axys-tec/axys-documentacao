# ADR-022 — Princípios de Design Minimalista e Sustentável

- **Status:** Aceito
- **Data:** 2026-07-14
- **Autor:** Renan (AXYS) · registrado no repense doc/path do Catálogo (AxysEasy)
- **Contexto:** Todo o ecossistema Axys (Hub, Easy, Pro, Cad, Rvt, Ifc, Sync)
- **Decisão Relacionada a:** ADR-001 (Arquitetura Executável), ADR-005 (Versionamento), ADR-008 (Armazenamento de arquivos), ADR-013 (Performance/Cache)

---

## 1. Contexto

O Axys modela um domínio inerentemente complexo — engenharia e construção civil: fontes de custo, composições, insumos, edições, ativos, orçamentos, memórias de cálculo. Essa complexidade é **legítima** e não pode ser amputada. O risco não é a complexidade do domínio; é a **complexidade acidental** que se acumula quando cada tabela/script/função tenta ser genérica, guarda o que não precisa, ou duplica responsabilidade "por precaução".

Um caso concreto motivou este ADR (o **repense doc/path** do Catálogo, 2026-07-13): fichas e cadernos de composição estavam catalogados em **três lugares ao mesmo tempo** (`external_path` na entidade + `catalogo.documentos` + `composicao_documento`), sendo o path **determinístico**; além disso, o prompt do CTC (~6 KB × 10k linhas = ~56 MB) vivia **duplicado** no banco e no storage. Nada disso resolvia um problema novo — só sobretensionava o banco e espalhava a governança. A correção foi **remover**, não adicionar: a identidade voltou a ser a fonte única; o registro central encolheu para o que não tem dono 1:1; o prompt ficou só no storage.

Era necessário elevar essa lição a **princípio de foundation**, aplicável a **qualquer** tabela, schema, script, storage, função ou módulo do ecossistema.

---

## 2. Forças e Restrições

- Domínio real e complexo (engenharia/construção civil) — a solução **não** pode simplificar o problema, só a forma de resolvê-lo.
- Ambientes com recursos limitados (workers de 512 MB, execução no navegador, on-premises) — cada byte e cada consulta contam (ver ADR-013).
- Multi-tenant, grandes volumes, séries por edição — o que escala mal em pequeno vira dívida em grande.
- Times pequenos — código que "sofre" (contorna, duplica, generaliza sem uso) custa manutenção desproporcional.

---

## 3. Decisão

**Toda e qualquer tabela, schema, script, storage e função no Axys DEVE, SEMPRE, satisfazer os cinco atributos:**

1. **Minimalista** — guarda/faz **só** o necessário para resolver o problema. Se um dado é derivável (path determinístico, valor calculável, união de outras tabelas), não se persiste "por conveniência".
2. **Não generalista** — resolve **o** problema concreto, não uma família hipotética de problemas. Nada de abstração especulativa, colunas "para o futuro", frameworks internos sem segundo usuário real.
3. **Não superficialista** — resolve o problema **inteiro e de verdade**, com integridade (invariantes, constraints, fronteiras claras). Minimalismo **não** é gambiarra: é resolver o essencial **por completo**.
4. **Diferenciado** — cada peça tem **um** papel nítido e distinto; sem duplicação de responsabilidade, sem "três lugares para a mesma verdade". Uma fonte única por conceito.
5. **Sustentável e ecológico** — reduz consumo (CPU, memória, I/O, banco, rede, storage) e é mantível ao longo do tempo. O barato de rodar e o barato de manter andam juntos.

### 3.1 "Simples sem sofrimento"

Simplicidade aqui significa **não fazer nada com sofrimento**: a peça resolve o problema, **preserva integridade** e ainda assim **acomoda** a complexidade real do ecossistema — sem forçar, sem contorcer, sem duplicar. O oposto de "sofrimento" não é "menos capaz"; é **fluência**: a solução parece óbvia depois de pronta.

- **Simples ≠ simplista.** Reduzir o acidental, preservar o essencial.
- **Menos, porém íntegro.** Cortar duplicação nunca pode custar uma invariante.

### 3.2 Heurísticas operacionais (como o princípio vira prática)

- **Fonte única por conceito.** O dado vive num lugar; os demais **derivam** ou **referenciam**. Se aparecer o mesmo path/valor em ≥2 tabelas, é sinal de dívida (revisar).
- **Storage > banco para o que acontece 1× na vida.** Manifestos, status de processamento de uma edição, prompts, HTMLs derivados → storage (JSON/arquivo). Banco é para **estado consultável e relacional**, não para blobs/one-offs. (Coerente com ADR-008.)
- **Path determinístico não se guarda como dado** — computa-se. Se `storage_paths.x(fonte, cod)` já dá o caminho, não crie coluna/linha para reconfirmá-lo.
- **Registro central só para o que não tem dono 1:1.** O que pertence a uma identidade vive **na** identidade; o catálogo central é para o que é de edição/fonte (sem dono único).
- **Batch, não linha-a-linha, em volume.** Séries por edição/UF escalam a milhões — escrever/ler em lote (ver ADR-013 e import_prod_perf).
- **Nome = conceito.** Prefixo/coluna nomeiam o conceito, não a tabela; caixa e convenção consistentes (governança de nomes do projeto).
- **Aditivo com intenção.** Schema cresce por necessidade provada, não por antecipação; o que deixou de ter uso é **removido**, não "mantido por segurança".
- **Reserva só com gatilho nomeado.** Estrutura de expansão futura (tabela/coluna ainda não populada) é aceitável **apenas** quando carrega um **gatilho concreto e documentado** — uma lei a promulgar, um contrato firmado, uma integração acordada com data. Reserva com gatilho ≠ especulação (§3 #2): é pendência planejada. O comentário DEVE citar o gatilho; sem gatilho nomeado, é antecipação e não entra. Ex.: `insumos_nfe_itens_precos` (gatilho: Lei 14.133, pesquisa de preço por NF-e).
- **Não-progressão inapropriada de IDs.** É **proibido** qualquer padrão que faça o PostgreSQL **pular IDs indiscriminadamente**. O caso típico é `ON CONFLICT`/UPSERT em tabela `IDENTITY`/`SERIAL`: a `sequence` é consumida **mesmo quando não há INSERT** (a linha já existe), furando os IDs. Em **identidade estável** (chave natural + surrogate), usar **get-or-create** — `SELECT` pela chave natural e `INSERT` só se ausente — nunca UPSERT que avança a sequence à toa. Isso evita estourar milhares/milhões de IDs sem registro correspondente, sobretudo em tabelas de **alto volume e reimport frequente** (orçamentos, composições, insumos, preços de insumo/composição e afins). Onde o get-or-create não cabe (dados por-edição, volumosos e reemitidos), preferir **delete + insert em lote** à colisão UPSERT. Regra: a sequence deve refletir **quantos registros existem**, não quantas tentativas houve.

### 3.3 Gatilho de revisão (quando parar e repensar)

Se, ao ler um schema/script, você sente que "está estranho", "é exercício grande para problema pequeno", ou "isto está em três lugares" — **pare e repense antes de refatorar**. Sobretensionar o banco/código é o anti-sinal. Preferir **remover** a adicionar.

---

## 4. Consequências

**Positivas**
- Banco/código enxutos, íntegros e baratos de rodar e manter.
- Menos regressão: menos lugares para a mesma verdade divergir.
- Escala previsível (o que é minimalista em pequeno raramente estoura em grande).

**Custos / Trade-offs**
- Exige **disciplina de recusa**: dizer não a generalizações "que um dia servem".
- Derivar (em vez de guardar) às vezes troca storage por CPU no acesso — decidir caso a caso (ADR-013), sempre pelo menor consumo total e maior integridade.
- Remover dívida existente custa um refactor pontual — pago porque evita o custo composto de mantê-la.

---

## 5. Aplicação e verificação

Ao criar/alterar **qualquer** tabela, coluna, script, função ou layout de storage, responder às **cinco perguntas** — os cinco atributos do §3 (Decisão) em forma de checklist. Um "não" em qualquer uma é gatilho de redesenho, não de exceção:

1. **Minimalista?** — guarda/faz só o necessário; nada derivável (path determinístico, valor calculável) é persistido.
2. **Não generalista?** — resolve *este* problema concreto, sem abstração especulativa ou coluna "para o futuro".
3. **Não superficialista?** — resolve o problema *inteiro*, com integridade (invariantes, constraints, fronteiras claras).
4. **Diferenciado?** — papel único e nítido; sem duplicar responsabilidade; fonte única por conceito.
5. **Sustentável/ecológico?** — reduz consumo (CPU, memória, I/O, banco, storage) e é mantível ao longo do tempo.

**Precedente canônico:** o repense doc/path do Catálogo — `docs/projects/axys-easy/contracts/catalogo/CATALOGO_BUSINESS_RULES.md §11.9/§11.10/§11.11` (v0.2, 2026-07-13). É o exemplo de referência de aplicação deste ADR (remoção de tripla-escrita, prompt fora do banco, fonte única na identidade).
