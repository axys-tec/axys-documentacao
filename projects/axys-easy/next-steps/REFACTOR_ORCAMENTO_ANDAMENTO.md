# Refactor `ativo_orcamento` — diário de execução

> **Para quem retoma (inclusive eu, depois de uma queda):** o plano é a §12 de
> `ativo_orcamento_schema_review.md`. Este arquivo é só o **estado**: o que já rodou, o que validou,
> e onde parei. Não repetir fase marcada como FEITA.

**Autorização (Renan, 11/10, antes de dormir):** avançar até resolver, sem mudar comportamento de
outras partes da app.

**LIMITES que não mudam sem ele acordado:**

| | |
|---|---|
| fases permitidas | **0, 1, 2, 3, 4, 5 e 9** |
| fase 6 (UI), 8 (tabs) | **NÃO** — ele disse que o refactor não altera front |
| fase 7 (remover o antigo) | **NÃO** — irreversível na prática |
| fase 10 (produção) | **NÃO** — `pg_dump` de prod e deploy esperam ele |
| `catalogo` / `tenant_catalogo` | **não tocar**, em nenhuma hipótese |
| formatação (moeda, data, vírgula, ponto-e-vírgula) | **compatibilidade total** — já está feito e aplicado; os checks de PDF/Excel são o que prova |

---

## Estado

| fase | estado | quando |
|---|---|---|
| 0 · ponto de retorno + limpeza | **FEITA** | 11/10 |
| 1 · contrato de migração | **FEITA** | 11/10 |
| 2 · DDL em dev | **FEITA** | 11/10 |
| 3 · escrita dupla | **NÃO FEITA — perdeu o propósito** | decisão do Renan |
| 4 · migrar dados de dev | **FEITA** | 11/10 |
| 5 · trocar a leitura (flag desligado) | **FEITA** | 11/10 |
| 9 · `schema.sql` | **FEITA** (re-fechada 12/10: a foto estava velha em 2 tipos) | 11/10 · 12/10 |

**Fases 6 e 8 foram redefinidas pelo Renan em 12/10** — viraram uma *submain do orçamento*, e só
depois de produção. Ver o fim deste arquivo.

## Linha do tempo


### Fase 0 — FEITA (11/10)

**Duas tags, não uma.** O ponto de retorno do código local e o de produção são commits diferentes:

| tag | commit | o que é |
|---|---|---|
| `pre-refactor-orcamento` | `b0e778d` | o HEAD local |
| `pre-refactor-orcamento-prod` | `6488251` | **o que produção roda** — `origin/main`, 3 commits atrás do HEAD |

A segunda é a que importa num rollback de prod. Ambas **locais, não pushadas** (push espera
autorização).

**As três tabelas lixo foram dropadas** — 35 → 32 tabelas no schema `ativo`:

```
ativo.orcamento_insumos_preco    0 linhas · nenhum dependente
ativo.orcamento_insumos          0 linhas · dependente: a própria filha acima
ativo.ativo_revisoes             0 linhas · nenhum dependente   (era a revisão-em-JSON)
```

A guarda do script recusou o primeiro drop porque `orcamento_insumos` tinha uma FK apontando — era a
da própria filha, que vai junto. Ajustado para ignorar FK interna ao conjunto que está sendo
dropado, e aí passou.

**Sanidade contra a app:** `backend.app` importa · **1.312 serviços fecham** com a bancada ·
**51 de 51** no `documento_pdf` · **4 de 4** no `excel_valores`. Nada sentiu — as três tabelas não
eram referenciadas por código nenhum.

### Fase 1 — decisão de execução: os prefixos de coluna NÃO mudam

O plano (§3.7 do schema_review) propunha prefixo novo em cada tabela que muda de dono: `ati_` →
`aoi_`, `cro_` → `aocr_`, `mc_` → `aom_` e assim por diante. **Medi o impacto antes de aplicar:**

| | trocar os prefixos | manter |
|---|---|---|
| ocorrências em `backend/**/*.py` | **1.740** | ~13 (só a coluna de dono) |
| ocorrências no **front** (`.html`/`.js`) | **44** — `ati_` sozinho tem **32** | **0** |

O Renan foi explícito: *"o plano afeta back/script de servir o front mas **não altera front**"*.
Trocar o prefixo obriga mexer em 32 pontos do front para ganho funcional **zero** — o prefixo atual
já é único no schema e já diz o que a coluna é.

**Então:**

| | prefixo |
|---|---|
| tabelas que **mudam de dono** (`_itens`, `_parametros`, `_bdi*`, `_ls*`, `_cronograma*`, `_memoria*`, `_itens_drivers`) | **mantêm o atual** — `ati_`, `opa_`, `abd_`, `abdc_`, `als_`, `alsi_`, `cro_`, `cri_`, `mc_`, `mci_`, `mcil_`, `mca_`, `aid_` |
| tabelas **novas** (`ativo_orcamento`, `_revisoes`, `_insumos`, `_insumos_preco`, `_composicoes`, `_composicoes_itens`, `_composicoes_custo`) | prefixo novo — `ao_`, `aor_`, `aoz_`, `azp_`, `aoc_`, `aci_`, `acc_` — porque **não há legado** |

**O que muda em cada tabela que migra é UMA coluna: a de dono.** `ati_atv_id` → `ati_aor_id`,
`cro_atv_id` → `cro_aor_id`, `mc_atv_id` → `mc_aor_id`, `cri_ati_id` fica (aponta o item, que
continua `ati_id`). O resto é idêntico, bit a bit.

> Fica estranho ver `ati_num` numa tabela chamada `ativo_orcamento_itens`? Sim. É o preço de não
> encostar no front, e é um preço que se paga uma vez na leitura do schema — contra 1.784 pontos de
> edição e o risco que vem com eles. Se o Renan quiser os prefixos novos, é um `sed` global **depois**
> de o refactor estar verde, com os três scripts como rede.

### Fase 1 — FEITA: o DDL é GERADO, não escrito à mão

`migracao/orcamento/` com cinco arquivos:

| arquivo | o que é | como nasceu |
|---|---|---|
| `01_novas.sql` | 7 tabelas novas + 6 índices + a view do esparso | **extraído** de `ativo_orcamento_schema_review.md` — o doc foi revisado 11× e o DDL dele executa |
| `02_migram.sql` | as 12 que mudam de dono | **gerado** por `gerar_ddl.py` a partir de `pg_dump --schema-only` do dev |
| `03_itens.sql` | `ativo_orcamento_itens` | **à mão** — é a única com transformação de verdade |
| `04_fks_itens.sql` | 3 FKs que apontam a tabela de itens | **gerado** — saem do 02 porque a tabela nasce no 03 |
| `testar.sh` | executa os 4 num banco temporário | — |

**Por que gerar:** são 12 tabelas com ~150 colunas e o que muda em cada uma é **uma** — a de dono.
Escrever à mão são 150 chances de errar uma linha que ninguém releria. O gerador avisa o que não
souber transformar, em vez de adivinhar.

**Por que `ativo_itens` fica à mão:** ela não é cópia. Perde `ati_cmp_origem` (a origem é da
composição), troca duas FKs polimórficas por FK real (`ati_cmp_id` → `_composicoes`, `ati_bdi_id` →
`_bdi` da revisão), ganha `ati_ls_regime`/`ati_ls_percent` e ganha o CHECK `ck_ati_identidade`
(item com composição não tem descrição própria). Cada mudança tem o porquê no comentário.

**Teste:** os 4 arquivos executam na ordem, em banco limpo — **20 tabelas · 65 índices · 213
constraints**, zero erro.

Dois bugs do gerador que o teste pegou: as FKs ficaram apontando a tabela **antiga** (`ativo_itens`,
que saiu do mapa) e os **índices** não recebiam a tradução de coluna renomeada. Os dois corrigidos no
gerador, não no SQL gerado — senão voltam na próxima geração.

### ⚠ INCIDENTE — 19 tabelas criadas no banco de dev por acidente

**O que aconteceu:** a primeira versão do `testar.sh` reescrevia o SQL com
`sed "s/\bativo\./_mig_teste./g"` para rodar num schema temporário. **O `\b` não existe no sed do
macOS** (é GNU), então a substituição não aconteceu e o `01_novas.sql` rodou no **banco de dev**,
criando as 19 tabelas no schema `ativo` de verdade.

**Dano: zero.** As 19 nasceram vazias, nenhuma tabela existente foi tocada, nenhum código as lê.
Conferi que estavam vazias e sem dependente de fora antes de dropar as 19 — voltou aos 32 que a
fase 0 deixou, com 0 resíduo.

**A correção não foi "arrumar o sed":** `testar.sh` passou a criar um **banco temporário com o
schema `ativo` de verdade**, e o SQL roda **literal**. Reescrever SQL para testá-lo é o erro de
raiz — o que se testa deixa de ser o que se aplica.

**Para a fase 2 isso não muda nada** (ela cria as mesmas tabelas, agora de propósito e completas),
mas fica registrado porque foi escrita não autorizada no banco de dev.

### Fase 2 — FEITA (11/10)

`migracao/orcamento/aplicar.sh`: ensaia em banco temporário, confere que o destino está limpo, e
aplica **numa transação só**. Resultado: **20 tabelas · 63 índices** no schema `ativo`, todas vazias.

**O que a aplicação pegou, e o teste em banco limpo não pegava:** `ERROR: relation "ix_abd_atv"
already exists`. **Nome de índice é único POR SCHEMA**, e as tabelas novas convivem com as antigas
até a fase 7 — copiar o nome do índice colide com o que já existe. Em banco limpo não havia com o
que colidir, e por isso o ensaio passava.

Todo nome de índice e constraint da família ganhou o infixo `ao_`: `ix_abd_atv` → `ix_ao_abd_atv`,
`uq_ati_num` → `uq_ao_ati_num`. Sistemático, único, e diz a que família pertence. Conferido: dos
**103 nomes** do DDL, zero colidem com o banco (os 3 que o detector apontou são CHECK auto-gerados,
e CHECK é único por tabela, não por schema).

**Sanidade:** app importa · bancada do atv 24 com **390 itens e R$ 2.029.540,21**, idêntico ao de
antes · 1.312 serviços fecham · 51/51 PDF · 4/4 Excel · as 20 tabelas com **0 linhas**.

### Mudança de ordem: a 4 vem antes da 3

O plano põe a **escrita dupla antes da migração**, e o argumento era bom: gravar dado vivo é mais
difícil que migrar dado parado, então teste o difícil primeiro.

**Mas há um pré-requisito que eu não tinha considerado:** o migrador e a escrita dupla escrevem
*o mesmo código* — capturar insumo, capturar composição, resolver custo, gravar item. Escrevendo o
migrador primeiro, esse código nasce **testado contra 9 orçamentos reais** (1.998 itens, 2.179
linhas de composição) em vez de contra um orçamento criado à mão na tela.

Então: migrador primeiro, e a escrita dupla **reusa** as funções dele. O risco que o plano queria
evitar — descobrir que a escrita não funciona com os dados já migrados — fica coberto, porque é o
mesmo código nos dois caminhos: se ele erra na migração, erra ali, com 9 orçamentos para comparar.

### Fase 4 — FEITA: 11 orçamentos migrados, validados 10 de 10

`migracao/orcamento/migrar.py` — dry-run por padrão, `--aplicar` grava, aceita id de ativo.
`z_scripts_apoio/sanidade/migracao_orcamento.py` — o validador, que é o portão da fase 5.

**O que entrou no banco** (e cada contagem bate com a tabela de origem):

| tabela | linhas | origem |
|---|---|---|
| `_orcamento` · `_revisoes` | 11 · 11 | 11 ativos com itens |
| `_itens` | **1.998** | = `ativo_itens` |
| `_composicoes` · `_composicoes_custo` | 1.261 · 1.261 | do catálogo (topo + sub-CPUs) |
| `_composicoes_itens` | 5.223 | a relação |
| `_insumos` · `_insumos_preco` | 1.424 · 1.424 | com preço **pelado** (`SE`) |
| `_bdi` · `_bdi_composicao` | 16 · 128 | = origem |
| `_ls` · `_ls_item` | 7 · 168 | = origem |
| `_cronograma` · `_cronograma_itens` | 5 · 549 | = origem |
| `_memoria` · `_item` · `_item_link` · `_arquivo` | 111 · 356 · 379 · 20 | = origem |
| `_parametros` | 28 | = origem |

**Validação — 10 de 10:** 1.998 itens pareados com **zero** diferença em unitário, quantidade, tipo
e path · **Σ(qtd × unit) idêntico por ativo** · a árvore manteve a forma · toda R00 EMITIDA, vigente
e datada · toda linha de composição aponta insumo XOR sub-CPU · nenhum serviço perdeu a composição ·
os 11 overrides de descrição viraram 7 composições marcadas (7 e não 11 porque composição repetida
na EAP é uma linha só).

**Sanidade da app, inalterada:** 1.312 serviços fecham · 51/51 PDF · 4/4 Excel · o plano converge.

#### Quatro bugs que a migração pegou, e os quatro eram do meu código

1. **JSONB** — `psycopg2` não adapta `dict`; faltava o wrapper `Json`.
2. **IDENTITY das PKs** — o `pg_dump` emite `ALTER TABLE … ADD GENERATED … AS IDENTITY` **separado**
   do `CREATE TABLE`, e o gerador ignorava. Sem isso, todo INSERT exigia informar o id
   (`NotNullViolation` em `abd_id`). As 20 tabelas foram recriadas com a correção.
3. **Tradução de id por coluna** — `cronograma_itens.cri_ati_id` guarda o id ANTIGO do item; eu
   indexava o mapa por tabela e comparava com nome de coluna. A `CASCATA` passou a declarar
   `{coluna: tabela}` explicitamente.
4. **`tenant_catalogo.composicoes_itens` tem forma PRÓPRIA** — `ci_ref_origem`/`ci_ref_tipo`/
   `ci_ref_id`/`ci_coeficiente`, não `ci_ins_id`/`ci_coef`. E **não é descuido**: a CPU própria pode
   referenciar insumo do catálogo GLOBAL, então ela precisa guardar a origem de cada linha. Virou
   `linhas_da_cpu()`, que normaliza as duas formas.

**Nota sobre o preço pelado:** `aoz_preco` vem de `catalogo.insumos_preco` com `pri_modalidade='SE'`
— o catálogo só tem SE, e SD/CD saem da L.S. aplicada em cima. Para insumo de fonte própria o preço
fica NULL nesta migração (a CPU própria resolve o custo por outro caminho, e o custo **resolvido**
está em `_composicoes_custo`, que é o que a leitura usa).

### Fase 5 — FEITA: a leitura nova entrega o mesmo, campo a campo

`EASY_ORC_LEITURA_NOVA=1` faz a app ler de `ativo_orcamento_*`. **Desligado é o padrão**, e é o que
roda em produção.

| | flag OFF | flag ON |
|---|---|---|
| `leitura_orcamento` (novo) | — | **zero diferença** nos 11 ativos |
| `analitico_bancada` | 1.312 fecham | 1.312 fecham |
| `documento_pdf` | 51 de 51 | **51 de 51** |
| `excel_valores` | 4 de 4 | 4 de 4 |
| `migracao_orcamento` | 10 de 10 | 10 de 10 |

`z_scripts_apoio/sanidade/leitura_orcamento.py` é o portão novo: chama `get_bancada` nas duas
configurações e compara **26 campos de cada item** mais o total. Compara o que a bancada ENTREGA, não
o SQL — são 19 pontos de chamada em 9 módulos que consomem esse dicionário.

#### O que a troca ensinou, em três decisões

**1. Envolver `execute` por `execute` com regex não serve.** Eram 85 citações das tabelas de
orçamento em 2 módulos, muitas em strings concatenadas ao longo de várias linhas ou em constantes de
módulo. O regex pegou 75 e deixou 10 — e o resultado foi um bug **silencioso**: `listar_memorias`
devolvia ids da tabela ANTIGA e `get_memoria` não os achava na nova, então o PDF da memória saía
vazio sem erro nenhum. A tradução passou para o **cursor** (`_CursorOrcamento` em `core/db.py`): um
ponto único, que cobre as 85 e as que forem escritas amanhã.

**2. Trocar o nome da tabela não basta quando a coluna de DONO muda.** `mc_atv_id` virou
`mc_aor_id`: não é só o nome, o VALOR também mudaria (de `atv_id` para `aor_id`). Reescrever as 85
queries para resolver a revisão antes seria reescrever a app na fase de leitura — o oposto do que o
plano quer. Entraram **6 views de compatibilidade** (`05_views_compat.sql`) que expõem a coluna
antiga derivada da revisão vigente. A query da app não muda; o dado vem do schema novo. Elas saem na
fase 7.

**3. A view de itens é a que mais trabalha.** `ativo_itens` perdeu `ati_cmp_origem` (a origem é da
composição) e `ati_cmp_id` passou a ser FK interna. A view **reconstrói as duas** a partir da
composição, listando as colunas uma a uma — `i.*` não serviria, porque `ati_cmp_id` tem de ser
substituída. Conferido: das 24 colunas da tabela antiga, a view tem **todas**, e acrescenta 5 do
schema novo.

#### Três bugs reais que os testes pegaram

| | o que era |
|---|---|
| `ati_bdi_id` não migrava | o INSERT dos itens não incluía a coluna. 13 itens perderam o BDI e **os totais bateram por sorte** — todos apontavam o BDI default, que o `get_bancada` aplica quando o id é nulo. Corrigido com UPDATE depois de o BDI existir (os itens migram antes, porque precisam da composição) |
| `desc_fixada` divergia | são **dois** casos, e eu cobri um: serviço de fonte com descrição trocada (a marca mora na composição) **e serviço digitado à mão**, que tem descrição própria e nenhuma composição. O schema antigo marcava os dois |
| `aci_ins_id`/`aci_cmp_filho_id` sem CASCADE | o `DELETE` de uma revisão travava. É o **mesmo defeito que o playground achou ontem** e que ficou corrigido só no texto da §2.8, não no DDL da §2.5 |

#### Uma edição de código fora do padrão, e por quê

`listar_memorias` agrupava por `m.mc_id` e selecionava `m.mc_titulo`. Em TABELA o Postgres deduz
pela PK (dependência funcional); em **VIEW ele não deduz**, e exige tudo no `GROUP BY`. Acrescentei
as colunas de identidade ao `GROUP BY` — **não muda resultado nenhum**, porque todas são
funcionalmente dependentes de `mc_id`, e é uma linha contra reescrever a consulta.

### Fase 9 — FEITA: o `schema.sql` voltou a ser a foto, e achou divergência que não é nossa

O arquivo recebeu as **20 tabelas** da família e as **7 views**, com o DDL vindo do `pg_dump` do
banco (a verdade depois da fase 2, não o que eu escrevi à mão), mais o bloco de comentário que
explica a estrutura, a regra "esparsar o que muda sozinho / copiar o que o usuário muda", a decisão
dos prefixos e o infixo `ao_` nos índices. As 3 tabelas lixo saíram do arquivo.

`z_scripts_apoio/sanidade/schema_fiel.py` é a guarda permanente: compara tabela e coluna **nos dois
sentidos** (o que o banco tem e o arquivo não declara, e o contrário), e aceita `--prod`.

#### ⚠ Achado que NÃO é do refactor, e precisa de quem é da frente de associações

O `schema.sql` **já estava divergente antes deste trabalho**, em três tabelas de equivalências:

| tabela | colunas no banco e **não** no `schema.sql` |
|---|---|
| `catalogo.equivalencias_cpu` | `ec_atualizado_em`, `ec_atualizado_por`, `ec_fator_conversao`, `ec_hash_dest`, `ec_metodo`, `ec_observacao`, `ec_score` |
| `catalogo.equivalencias_ins` | `ei_atualizado_em`, `ei_atualizado_por`, `ei_hash_dest` |
| `catalogo.equivalencias_mo` | `mo_atualizado_em`, `mo_atualizado_por` |

São 12 colunas que existem em dev e o arquivo não declara. **Não toquei** — é a frente de
associações entre fontes, que o Renan toca por fora desta (e há trabalho não commitado dela no
working tree). O `schema_fiel.py` vai acusar até alguém dessa frente atualizar o arquivo.

**Isso valida o medo do Renan** (*"tenho medo de esse arquivo já não representar o estado atual"*):
estava certo, só não era onde parecia. Em 11/10 eu havia conferido **tabelas** e dito que estava
fiel; a conferência de **colunas** é que encontrou.

### Fase 3 — PAREI, e a razão é que ela perdeu o propósito

**Não fiz, e não é por falta de tempo.** A escrita dupla existia para **provar que o schema novo
aguenta o que a app produz** antes de confiar nele. Esse propósito foi cumprido por outro caminho:

| o que a fase 3 ia provar | como já foi provado |
|---|---|
| o schema aguenta os dados reais | fase 4: **1.998 itens, 1.261 CPUs, 5.223 linhas** migrados |
| os números não mudam | `migracao_orcamento` **10 de 10** — Σ(qtd×unit) idêntico por ativo |
| a app funciona lendo de lá | fase 5: **zero diferença** em 26 campos × 11 ativos; 51/51 PDF; 4/4 Excel |

**E fazê-la agora seria trabalho que a fase 7 joga fora.** São **83 pontos de escrita** (29 em
`ativo_itens`, 21 nas memórias, 9 em parâmetros, 10 em BDI/L.S., 6 em cronograma). Duplicar cada um
significa escrever 83 gravações a mais, mantê-las sincronizadas, e **apagar as 83 na fase 7** —
quando o schema antigo sai.

**O que falta de verdade é TROCAR a escrita, não duplicá-la.** E essa é a decisão que eu não tomo
dormindo você:

> Trocar a escrita é o ponto em que o schema antigo **para de receber dados** e os dois divergem.
> A partir dali, voltar atrás não é desligar um flag — é remigrar. É efetivamente o começo da fase
> 7, que você reservou para quando estivesse acordado.

**A alternativa segura, se você quiser avançar sem decidir isso:** escrita dupla **só em
`ativo_itens`** (os 29 pontos, que é onde a bancada grava de verdade), deixando memória, cronograma,
BDI e L.S. para depois. Cobre o caminho mais usado e ainda é reversível por flag. Mas são 29
gravações que a fase 7 descarta — e por isso eu prefiro que você escolha.

**Minha recomendação:** pular a 3 e ir da 5 para a **6** (a UI de Fontes/BDI/LS editando a revisão),
que é onde a escrita *precisa* mudar de qualquer forma. A 6 é front, que você proibiu nesta rodada —
então é aí que o trabalho autônomo acaba, e é o que estou reportando.

---

## 12/10 — três correções, as três levantadas pelo Renan

### 1 · `converter_ls` desmarcado: o preço traz a L.S. da FONTE

> *"Se isso estiver desmarcado os preços que caem na bancada repetem o do catálogo e podem divergir
> da ls destacada na bancada. Eu acredito que o schema não suportou isso, ou suportou?"*

**O schema suportou** — `ati_ls_regime` e `ati_ls_percent` existem exatamente para isso, e a §3.4 do
desenho já dizia: *"o % aplicado pode não ser o da obra; quando a fonte não é rotacionada, vale a
L.S. da própria fonte"*. **O migrador é que não preenchia: 0 de 1.998.**

A regra, lida de `_capturar_custo_unit` e agora em `ls_aplicada()`:

| situação | L.S. que entra no preço |
|---|---|
| regime MENSALISTA | a **mensalista do ativo** |
| HORISTA + `converter_ls` ligado | a **horista do ativo** |
| HORISTA + `converter_ls` **desligado** | **a da FONTE** (`edicoes_leis_sociais` da edição×UF×modalidade) |

E o caso não é exceção: **18 pares ativo×fonte com `converter_ls` desligado contra 10 ligados**.
Depois da correção, 1.338 itens têm a L.S. registrada, e **42 deles usam a L.S. da fonte, não a da
obra** — exatamente a divergência que o Renan previu. O atv 20 mostra o detalhe fino: **4 itens com
a da obra e 6 com a da fonte no mesmo orçamento**, porque `converter_ls` é por **fonte**.

### 2 · A composição tinha de entrar ROTACIONADA — e não entrava

> *"E a conversão de insumo, ela já foi aplicada? Porque a composição tem que entrar já rotacionada,
> se for o caso."*

**Não estava.** O migrador lia `catalogo.composicoes_itens` — a relação CRUA. Com
`converter_mdo`/`converter_ins`/`converter_reg` ligados, a composição do orçamento é **outra**.
Medido antes da correção:

| ativo | conversão | CPUs | iguais | coef diferente | código diferente |
|---|---|---|---|---|---|
| 22 | CDHU/FDE mdo | 121 | 106 | 11 | 4 |
| 23 | SINAPI reg | 10 | 1 | 6 | 3 |
| 24 | SINAPI/FDE mdo+ins | 291 | 206 | 85 | 0 |
| 26 | CDHU/FDE mdo | 157 | 134 | 15 | 8 |
| **21** | **nenhuma (controle)** | 14 | **14** | **0** | **0** |

**132 de 579 composições estavam erradas** — e o controle sem conversão dando 14/14 é o que valida a
medição. Exemplo concreto: insumo 122 com coeficiente `0,0035` no catálogo e `0,002975` na bancada
(fator 0,85 da conversão).

**A correção:** a fonte passou a ser `get_composicao_detalhe(...)["atual"]["itens"]` — a árvore
resolvida, com `filhos` trazendo a sub-CPU também resolvida e `estado` marcando o que foi convertido
(`reg`, `ins`). O migrador ganhou `garantir_insumo`/`garantir_composicao`/`gravar_arvore`, porque a
captura passou a ser **por linha da árvore**: a conversão traz insumo que não está na composição do
catálogo, e varrer o catálogo nunca o encontraria.

`z_scripts_apoio/sanidade/composicao_migrada.py` é o teste: **654 CPUs com a composição da bancada,
0 divergem** (3 sem árvore resolvível — são composições **descontinuadas** `cmp_ativa=false` com 0
itens no catálogo, o caso conhecido de `project_composicao_descontinuada`).

**E um achado de precisão:** sobravam 5 divergências na 6ª casa decimal. `aci_coef` era
`NUMERIC(18,6)` e `catalogo.composicoes_itens.ci_coef` é `NUMERIC(14,10)` — o coeficiente
**convertido** tem mais casas que o da fonte (é produto por fator), e 6 casas arredondavam. Virou
`NUMERIC(18,10)`: espelhar o catálogo, não inventar.

### 3 · `aoc_origem`/`aoz_origem` passam a ser C/T

> *"Precisamos mesmo guardar aoc_origem e aoz_origem com os nomes CATALOGO/TENANT? Isso é um lixo no
> longo prazo."*

Medido: `'CATALOGO'` custa **9,0 bytes por linha**; `CHAR(1)` custa 2. São **7 bytes por linha**, que
em 10 mil orçamentos dão **53 MB**. Mas o argumento que decide não é o disco: **o schema já usa
CHAR(1) para enum pequeno** — `alsi_grupo` (o grupo da L.S.) e o próprio `ati_ls_regime` (H/M). C/T
é consistência, não exceção.

`C` = CATÁLOGO global · `T` = TENANT (fonte própria), com o CHECK no banco e o comentário no schema.
A app continua falando `CATALOGO`/`TENANT`: a tradução mora em **dois lugares só** — a view de
compatibilidade e o `linhas_bancada`. Esquecer o segundo custou 1.338 diferenças na validação, que é
o tipo de erro que o `leitura_orcamento.py` existe para pegar.

### 4 · `aoz_fonte`/`aoc_fonte` FICAM como texto — e a razão é técnica

> *"Poderíamos guardar o nome ou criar uma fk p/ opa_fonte, todavia acho que não vale o custo por
> conta das rotações."*

Concordo, e a razão é mais forte que o custo: **a fonte na linha é um snapshot por LINHA, não por
orçamento**. Com rotação de MDO, um insumo SINAPI entra numa composição CDHU — então a mesma
composição tem linhas de fontes diferentes. Uma FK para `opa_fonte` amarraria a linha ao
**parâmetro** do orçamento, quando ela precisa dizer **de onde aquele dado veio**. São duas coisas, e
confundi-las quebraria justamente o caso da conversão.

Custa 6,3 bytes por linha, há 6 fontes distintas em dev (CDHU, EMOP, FDE, PRÓPRIA, SBC, SINAPI), e
fica legível na planilha sem join.

### Estado depois das correções

| | |
|---|---|
| migração | 1.280 CPUs · 1.433 insumos · 5.250 linhas · 1.998 itens |
| `composicao_migrada` | **654 CPUs == bancada · 0 divergem** |
| `migracao_orcamento` | 10 de 10 |
| `analitico_bancada` | 1.312 serviços fecham |
| `documento_pdf` (OFF e ON) | **51 de 51** nos dois |
| `excel_valores` | 4 de 4 |
| `leitura_orcamento` (ON) | **zero diferença** |

---

## 12/10 (tarde) — o fix de schema encerrado, e `aci_conv_json`

### 1 · A foto estava velha em dois pontos — e o guardião era cego a isso

`schema_fiel.py` comparava **presença** de coluna, não **tipo**. As duas correções da manhã foram
aplicadas ao banco e **não** foram refotografadas, e o guardião passou verde nas duas:

| | banco | `schema.sql` |
|---|---|---|
| `aci_coef` | `numeric(18,10)` | `numeric(18,6)` ← as 6 casas que arredondavam 5 composições |
| `aoc_origem` · `aoz_origem` | `character(1)` | `text` ← o C/T da decisão nº 3 |

Os dois corrigidos na foto, e o guardião ensinado a comparar tipo: `format_type` devolve a mesma
string que o `pg_dump` escreve, então a comparação é direta, com normalização de apelido
(`int`→`integer`, `timestamptz`→`timestamp with time zone`) e corte que **respeita parênteses** —
`numeric(14,2)` é um tipo, `TEXT, outra_col TEXT` são dois. Sem isso o próprio check dava 68 falsos
positivos.

Sobra `coluna divergente ACHOU 3` em `catalogo.equivalencias_cpu`/`_ins`/`_mo`: é a frente de
**associações**, outra aba, e não se toca aqui.

### 2 · `aci_conv_json` — a procedência da conversão

Coluna `JSONB` em `_composicoes_itens`, com `ck_aci_conv_json`, aplicada no banco de dev, no
`01_novas.sql`, no `schema.sql` e documentada na **§2.5.1** do `schema_review`. Decisão do Renan:
JSONB e não cinco colunas, porque **serve só para auditar** (e auditoria na app mora em snapshot) e
porque a leitura é **isolada** — uma tela de diff, nunca N+1.

Mata `aci_estado` e `aci_sub_codigo`, as duas ideias que eu havia levantado. A edição **não** entra:
o id na origem é perene (get-or-create), e a data-base é parâmetro da consulta. Isso também descartou
`azp_edi_id`/`acc_edi_id`, que eu havia proposto.

**Gravar o vetor é fase 6** — a coluna nasceu vazia, e as 132 linhas convertidas já migradas não têm
procedência registrada. Nada quebra: `NULL` = linha nativa é o mesmo que a app entende hoje.

### 3 · Sanidade

| | OFF | ON |
|---|---|---|
| `analitico_bancada` | todos fecham | todos fecham |
| `documento_pdf` | 51 de 51 | 51 de 51 |
| `excel_valores` | 4 de 4 | 4 de 4 |
| `migracao_orcamento` | 10 de 10 | 10 de 10 |
| `composicao_migrada` | 654 · 0 divergem | 654 · 0 divergem |
| `leitura_orcamento` | zero diferença | zero diferença |

`plano_orcamento.py`: **convergiu, nenhum achado** nos 15 checks — inclusive o 15, que executa o DDL
do doc no Postgres, já com a coluna nova.

### 4 · As fases que sobram, na redação do Renan (12/10)

| fase | o que é agora | quando |
|---|---|---|
| **9 · `schema.sql`** | **FECHADA de novo** hoje, com o guardião reforçado | feita |
| **10 · produção** | levar o estado novo para prod | **a próxima decisão dele** |
| **7 · remover o antigo** | só depois de 10 estável | depois de prod |
| **6 + 8 · a UI** | **viraram uma coisa só**, e não a que o plano dizia | **só depois de prod** |

> *"o 6 fala sobre uma UI e ficou estipulado que não mexeríamos em UI durante isso e que todo o
> comportamento de UI permaneceria o atual. Apenas, e somente após colocar novo estado em prod, é que
> mexeríamos nisso. Basicamente será uma unificação das tabs, alocando-a para dentro de orçamento e
> gerando o histórico mas, como orçamento tem virado uma coisa de múltiplos botões, minha ideia será
> uma submain do orçamento, dando uma otimizada em tabs. Inclusive, é o que vai fazer mais sentido
> até para os outros produtos da app. Porque essa estrutura de tabs pode sobretensionar no
> carregamento, posteriormente."* — Renan, 12/10

Então a fase 6 **não** é "UI mínima para editar Fontes/BDI/LS na revisão": é uma **submain do
orçamento** que absorve as tabs, gera o histórico e tira a tensão do carregamento — desenho que serve
os outros produtos também. Ringue próprio, depois de prod. **Nada de UI até lá.**

---

## 13/10 — rotação para o schema novo (trabalho autônomo, DEV)

**Autorização (Renan, 12/10, antes de dormir):** migrar [feito], **dropar o antigo**, rotacionar
função por função e ação por ação da bancada testando cada uma, validar os entregáveis, check de
sanidade, não finalizar até acabar. **APENAS EM DEV.** Sem prod, sem push, sem UI.

### Por que a ordem dele foi invertida (2 depois de 3)

Ele pediu dropar (2) antes de rotacionar as funções (3). Dropar primeiro deixa a app **morta**
durante todo o trabalho e, pior, destrói a única **referência de comparação** — o flag OFF é o que
prova que o novo entrega o mesmo. Então: rotaciona tudo com os dois lados vivos, prova, e **só então**
dropa. O destino é idêntico.

### O diagnóstico que motivou a rotação (medido em 12/10)

`fluxo_orcamento.py` (novo) exerce o fluxo do Renan, passo a passo, chamando os serviços reais:

| | flag OFF | flag ON |
|---|---|---|
| OK | 10 | 4 |
| NÃO EXISTE (fase futura) | 5 | 4 |
| **QUEBRA** | **0** | **7** |

As 7 quebras com ON são **todas escrita em view de compatibilidade** (`cannot insert into view`):
60 pontos de escrita caem nas 6 views, 23 caem em tabela nova. Mais dois buracos que não são
quebra, são **ausência**: nada na app cria `ativo_orcamento`/`_revisoes` (só o migrador), e nada
captura `_composicoes`/`_insumos`/`_preco` quando um item entra na bancada.

Corrigido já: `orcamento_service.py:705` usava `ativo_itens.ati_id` (nome da tabela) em vez de alias
— com o flag ON o `FROM` virava a view e a referência ficava órfã (`missing FROM-clause`). Só
aparecia em **ativo não migrado**, o caminho que nenhuma sanidade exercia. Varri as 13 tabelas
traduzidas: era a única ocorrência em SQL.

### Etapas

| | etapa | estado |
|---|---|---|
| A1 | `orcamento_fonte` deixa de traduzir e passa a RESOLVER (`aor_de`/`ao_de`) | **FEITA** |
| A2 | `criar_ativo` nasce com `ativo_orcamento` + revisão 00 · backfill dos sem `ao_` | **FEITA** — 18 backfill, 29/29 com revisão |
| A3 | **captura de estado**: item entra → grava `_composicoes`/`_itens`/`_insumos`/`_preco`/`_custo` | **FEITA** |
| B1 | itens (`criar/editar/deletar/mover/duplicar/colar/set_codigo/alo/converter/importar`) | **FEITA** — 47 queries |
| B2 | parâmetros (`opa_`): fontes, busca padrão, flags de regime | **FEITA** — 18 queries |
| B3 | BDI | **FEITA** |
| B4 | L.S. | **FEITA** |
| B5 | cronograma | **FEITA** |
| B6 | memória | **FEITA** — 79 queries |
| C | um caminho de leitura só; o `_CursorOrcamento` e o flag saíram | **FEITA** |
| D | **drop** das 13 antigas | **FEITA** — 0 sobraram |
| E | fluxo · ações · bateria · entregáveis · ver-conversão | **FEITA** |

> `migracao_orcamento.py` e `leitura_orcamento.py` **perdem sentido depois do D**: os dois comparam
> antigo × novo, e o antigo não existirá. Aposentá-los é parte da etapa D, não defeito.

### A rede de segurança (13/10)

Dois scripts novos, porque os que existiam não bastavam:

| | o que faz |
|---|---|
| `baseline_totais.py` | **congela os números que a app entrega** (bancada, analítico, sintético, as duas curvas, cronograma, L.S., BDI) e exige que continuem idênticos. Sobrevive ao drop, que é o que `leitura_orcamento` não faz. Assinatura da linha = `numero\|codigo\|unit\|qtd\|bdi` — **nunca o `id`**, porque os dois schemas dão ids diferentes ao mesmo item (0 coincidem) |
| `param_revisao.py` | pega o erro silencioso do refactor: query que passou a filtrar por `*_aor_id` mas **continuou recebendo `atv_id`**. Não dá erro de sintaxe — dá FK violation com sorte, ou grava na revisão errada se o número coincidir (e coincide: orçamento e revisão começam os dois em 1). **Pegou dois casos reais**, nos INSERT de L.S. e de cronograma |

Com a assinatura por `numero`, o schema novo (flag ON) deu **idêntico ao antigo nos 29 ativos** — a
prova mais forte de que a leitura nova está certa.

### Como a rotação foi feita, e o que ela custou

**Por serviço, com os testes entre cada um.** BDI (10 queries) → L.S. (12) → cronograma (8) →
parâmetros (18) → itens (47) → memória (79). Depois de cada bloco: `param_revisao`, `fluxo_orcamento`
e `baseline_totais`. O baseline deu **idêntico** em todos os passos — e é por isso que se sabe que a
rotação não mexeu em número nenhum.

**O erro que apareceu três vezes** foi sempre o mesmo: trocar a coluna na query e esquecer o valor
na lista de parâmetros (`als_aor_id = %s` recebendo `atv_id`). Não dá erro de sintaxe. Deu FK
violation nos INSERT de L.S. e cronograma, e no de parâmetros passou pela primeira versão do
`param_revisao.py` — que procurava o fim da query **contando aspas** e caiu no meio dos parâmetros
por causa de um `"SP"`. Refeito com **AST**, achou os dois que a regex tinha deixado passar, e
depois uma quarta variante: `m.mc_aor_id = a.atv_id` num JOIN, sem parâmetro nenhum.

**O que mudou de semântica, não de nome:** `ati_cmp_origem` deixou de existir (a origem é da
composição) e `ati_cmp_id` passou a ser FK interna para `_composicoes`. As **leituras** que precisavam
das duas passaram pela view de compatibilidade, que as reconstrói; as **escritas** passaram a capturar
o estado e gravar o `aoc_id` — `set_codigo_item`, `criar_item`, `editar_item` (com sentinela, porque
ela monta os parâmetros antes de abrir a transação), `colar_bloco` e `duplicar_item`.

**O N+1 morreu de verdade.** `get_bancada` tinha dois caminhos; agora tem um, o que traz a identidade
no mesmo SELECT. O `unit_fonte` (preço atual da fonte, para comparar drift) sai como `None` — foi
conferido que **ninguém o consome**, nem front nem back, e recalculá-lo traria o N+1 de volta.

### O drop (etapa D)

Antes: dump CSV das 13 tabelas no scratchpad e a conferência que importa — **contagem idêntica e
nenhum ativo com dado só na antiga** (1998/1998 itens, 16/16 BDI, 7/7 L.S., 5/5 cronograma, 111/111
memórias, 28/28 parâmetros). Drop **sem CASCADE**, de propósito: `ativo_bdi` recusou e mostrou que a
FK que a segurava era de `ativo_itens`, que na minha ordem vinha depois.

**As views de compatibilidade sobreviveram ao drop** — elas leem das tabelas NOVAS, não das antigas.
Isso derrubou a estimativa de reescrever 85 leituras: o trabalho real era só a escrita.

`migracao_orcamento.py` e `leitura_orcamento.py` foram **aposentados**: comparavam antigo × novo, e o
antigo não existe mais. `baseline_totais.py` é o sucessor, e não depende de haver dois schemas.

### Três defeitos do `schema.sql` que ninguém tinha visto

A foto agora é testada de verdade: **aplicada num banco novo**, do zero. Ela não executava, e por
razões que vinham de antes do refactor:

| | |
|---|---|
| vírgula pendurada antes do `)` | em `catalogo.conselhos_classe` e `catalogo.doc_resp_tecnica` |
| 3 `CREATE INDEX` órfãos | de `orcamento_insumos`, `_preco` e `ativo_revisoes` — tabelas dropadas em 11/10; a tabela saiu, o índice ficou |
| um `;` no fim de um comentário | fechava a view `v_orcamento_insumo_preco`, e sem ele o `CREATE VIEW` seguinte era erro de sintaxe |

`schema_fiel.py` comparava tabela, coluna e (desde hoje) tipo — nunca se o arquivo **roda**. Agora
roda: aplicado em banco limpo, dá as **mesmas tabelas do banco de dev, sem uma diferença**.

### Os dois testes novos

| | |
|---|---|
| `fluxo_orcamento.py` | o caminho do usuário, na ordem do Renan: **13 OK · 2 NÃO EXISTE · 0 QUEBRA** |
| `acoes_bancada.py` | o outro eixo — cada ação e cada entregável, um por um: **27 OK · 0 FALHA** |

As 2 "NÃO EXISTE" são as revisões (R00→R01 e alterar composição só na R01): o schema suporta
(`aor_num`, `aoc_aor_desde`), a app ainda não tem a função. Não é defeito da rotação; é a
funcionalidade que vem depois.

Os entregáveis foram exercidos de ponta a ponta: PDF por peças (capa, ofício, sintético, analítico,
curvas, cronograma, histograma, BDI, L.S., memória, composições próprias), XLSX, e a **tela de diff
(ver conversão) junto com ver composição** nos itens com badge de conversão — 8 de 8 no ativo 22 e
12 de 12 no 24.

### FECHADO em 13/10 — e os vigias desarmados

A rotação acabou: o orçamento vive inteiro em `ativo_orcamento_*`, as 13 tabelas antigas não
existem mais em dev, e a última bateria fechou verde:

| | |
|---|---|
| `fluxo_orcamento` | 13 OK · 2 NÃO EXISTE · **0 QUEBRA** |
| `acoes_bancada` | 27 OK · **0 FALHA** |
| `analitico_bancada` | todos os analíticos fecham com a bancada |
| `documento_pdf` · `excel_valores` | 51 de 51 · 4 de 4 |
| `composicao_migrada` | 654 CPUs · 0 divergem |
| `baseline_totais` | **idêntico** — 29 ativos |
| `param_revisao` | nenhuma query de revisão recebendo o ativo |

**Vigias desarmados**, os três (o do trabalho autônomo e os dois de monitoramento). Regra do Renan,
12/10: *"os vigias são apenas para quando você iniciar uma tarefa e eu pedir, e ficarem armados
apenas enquanto não acabar. Não precisa deixá-los full time."*

**O que espera decisão dele:**

| | |
|---|---|
| teste de FRONT | o que ele reservou para depois do drop — é agora. Reiniciar o serviço em 8788 antes, para não testar código velho em memória |
| commit | não feito: a aba de **associações** tem 6 arquivos modificados misturados, e `docs` é submódulo |
| revisões (R00→R01) | as 2 "NÃO EXISTE": o schema suporta, a app não tem a função |
| views de compat | **ficaram** — leem das tabelas novas e sobreviveram ao drop. Sair delas só faz sentido junto com as revisões |
| produção (fase 10) | intocada, como ele mandou |

### Achado depois de fechar: `aoz_ao_id` não tinha FK (13/10)

O inventário do banco mostrou **8.858 insumos contra 1.433 preços** — e a migração tinha criado
1.433 de cada. A diferença eram **7.425 insumos órfãos**, de orçamentos que já não existem: os
ativos de teste criados e excluídos durante a rotação.

Causa: `ativo_orcamento_insumos.aoz_ao_id` era `INTEGER NOT NULL` **sem `REFERENCES`** — a única
filha de `ativo_orcamento` sem FK no dono (`_composicoes` e `_revisoes` sempre tiveram, e as duas
estavam com zero órfãos). Vinha do DDL da fase 2 e só apareceu agora, porque só agora um ativo com
insumos CAPTURADOS foi excluído. Em produção não quebraria nada — o lixo não dá erro, só cresce.

Corrigido nos quatro lugares: órfãos removidos (critério exato — insumo cujo orçamento não existe),
FK `fk_aoz_ao_id` com `ON DELETE CASCADE` criada no banco, e o DDL ajustado em `01_novas.sql`,
`schema.sql` e na §2.3 do `schema_review`. Fechou **1.433 insumos · 1.433 preços**.

**Provado em seguida:** criar ativo → fonte → L.S. → serviço com código grava 13 insumos, 13 preços,
5 composições, 23 linhas, 5 custos, 1 item e 1 revisão; excluir o ativo **não deixa nada** — e zero
órfãos no banco.

### 13/10 (tarde) — o que a rotação de regime em SC revelou

O Renan trocou o regime do ativo 26 (obra **em Santa Catarina**) para mensalista e 17 serviços
ficaram sem custo. Três defeitos distintos saíram daí, e nenhum era do refactor:

**1 · `preco_mo._pelado` era uma segunda implementação da regra de preço — e cega.** Buscava
`pri_uf = uf` e devolvia None sem coleta na UF. A regra da SINAPI é outra, e o
`custo_composicao._pelado` sempre a teve: sem coleta na UF, o preço vem de **SP ajustado pelo
coeficiente de família (%AS)** — `SP × coef[uf] / coef[SP]` —, e sem família é SP plano. O motor
canônico precificava as composições (0,75 · 2,13 · 504,08); o caminho da rotação de regime, que
passa por `preco_mo`, devolvia `incompleto=True` e a captura descartava o total.

A regra agora é **uma**: `custo_composicao.pelado_insumos()` foi exposta e os dois gravadores — a
captura de estado e a reconciliação da migração — passaram a chamá-la. **17 sem custo → 1**, e o
que resta é o `ERR` legítimo (MO sem par mensalista). As outras 28 obras não mudaram um centavo:
estão em SP, onde há coleta, e o fallback não toca em preço coletado.

**2 · O migrador só buscava preço de insumo do catálogo GLOBAL.** `if iid and org == "CATALOGO"` —
para insumo de fonte própria (PRÓPRIA, EMOP, SBC) gravava NULL **sem procurar**, e o preço estava em
`tenant_catalogo.insumos_preco` o tempo todo. Eram 26 dos 35 nulos. `reconciliar_precos.py` lê de
onde o preço está. Resultado: **1.434 preços, zero nulos**.

**3 · A guarda que faltava.** Recálculo que não fecha **não apaga** preço já gravado — mesma razão
da guarda da composição descontinuada, e o incidente de lá foi de R$ 21,5 mil. Marca
`custo_nao_recalculado` e mantém o valor.

**O que NÃO é defeito:** os 2 itens que explodiram 172× (ENGENHEIRO CIVIL, 352 h, e MESTRE DE
OBRAS, 704 h). A MO *é* o item: no mensalista o unitário vira custo do mês e a quantidade continua
em horas. A app já marca `REG` + `mo_qtd_alerta` (⚠) — é curadoria do usuário, combinada.

### `soltar()` fazia um passe só

Pergunta do Renan: excluir o item leva as auxiliares e os insumos? Testado em clone — três
serviços, dois com o mesmo código:

| | composições | insumos | órfãos |
|---|---|---|---|
| 3 itens capturados | 28 | 21 | 0 |
| excluo 1 dos 2 repetidos | 28 | 21 | 0 ← certo, o irmão ainda usa |
| excluo o último que usava | 21 | 20 | 0 |
| excluo o outro serviço | 0 | 0 | 0 |

A primeira versão deixava **2 órfãs** nesse caso: um passe só não basta, porque quando a composição
de topo cai as auxiliares ainda estão presas às linhas que vão cair no mesmo comando. Agora
**itera até o fecho** (um nível por volta, para quando uma volta não apaga nada). Havia lixo disso:
o ativo 26 tinha 32 composições e 22 insumos órfãos, limpos.

### A busca por código estava certa e o cache mentia

O fix de `get_insumos` (código, não só descrição) não apareceu na tela: a consulta é cacheada por
hash dos kwargs com **TTL de 24h**, e a resposta vazia de antes do fix estava guardada. Purgado
(`ins:*`, `cpus:*`, `pel:*`). O docstring do cache já avisava: *"Purge easy:ins:* no
reindex/publicar (pendente)"* — e isso vale para mudança de CÓDIGO da busca também, não só de dado.

### Ver composição ficou análoga a ver conversão

`get_composicao_detalhe` **reusa** `get_conversao_detalhe`, então `auxiliares` e `dados_basicos` já
chegavam na template — ela só não os desenhava. Agora desenha, no mesmo markup: o item 14546 passou
de 3 linhas para 3 + **8 auxiliares abertas**; o 14555, 16. Mais os dados básicos (fonte, edição,
L.S.) e uma legenda enxuta — só o que esta tela usa, sem os badges de conversão que não aparecem
aqui.

### 13/10 (noite) — o detalhamento passou a ler o ESTADO

A cobrança do Renan foi justa: a grade lia `ativo_orcamento_*`, mas o **detalhamento** continuava
resolvendo ao vivo contra o catálogo. O preço disso apareceu em dois sintomas no mesmo dia: editar
uma CPU própria mudava o que a tela do orçamento mostrava (C-000037), e o analítico divergia da
bancada em **67 de 714 serviços** do ativo 22 (pior caso R$ 389,40).

**O que faltava no estado.** Três coisas, e as três eram colunas que existiam e ninguém preenchia:

| | |
|---|---|
| `aci_conv_json` | a procedência da conversão. Criada em 12/10, preenchida só em 13/10 — um dia gravando composição convertida sem dizer de onde o preço veio. **1.676 linhas** de 5.186 agora a têm |
| `ati_ls_regime` · `ati_ls_percent` | congeladas na migração e **mentindo**: o ativo 26 em mensalista (71,03%) com 176 itens dizendo `H / 114,47` |
| `aci_valor` | **nova**. O pelado sozinho não reconstrói a linha de MO — a L.S. aplicada não é derivável dele, e em CPU própria não há edição congelada a que recorrer |

Mais o **swap de raiz** (CPU-H → CPU-MÊS), onde a conversão não está em linha nenhuma: a
procedência vai no item (`ati_meta_json.conv`), com o mesmo shape do vetor.

**A leitura.** `captura_estado.arvore_do_estado()` monta a árvore a partir de
`_composicoes_itens` + `_insumos` + `_composicoes_custo`, na mesma forma que `_arvore_resolvida`
devolve — trocar a origem não obrigou a reescrever quem lê. Comparadas linha a linha: **idênticas
nos 1.338 serviços** de dev.

| superfície | antes | agora |
|---|---|---|
| Bancada · Sintético · Curva de serviços · Cronograma | estado | estado |
| **Curva ABC de insumos** · **Histograma** | ao vivo | **estado** (`_arvore_para_leitura`) |
| **Ver composição** · **Analítico** | ao vivo | **estado** (`_do_estado`) |
| Captura | catálogo | catálogo — é o único lugar que deve ir lá |

O que continua vindo do motor nas telas de detalhe são os **badges e o DE→PARA**: explicar a
conversão exige comparar com a fonte. O que não vem mais de lá é o que o orçamento já decidiu —
as linhas e o custo.

**TRUNC, não ROUND.** A primeira versão fechava o total da linha com `round` e quebrou o analítico
em 8 ativos por um ou dois centavos. A bancada é TRUNC em tudo; a leitura do estado usa o mesmo
`tmul` do motor.

**A prova que vale** não é estática (o rastreador vê a chamada mesmo quando o resultado é
substituído depois): num ativo descartável, alterei **só o `aci_valor` gravado** — 91,72 → 999,99 —
e a tela obedeceu. Ela lê do orçamento.

### Para a migração de produção

O Renan: *"em dev ok, em prod isso nao vai poder acontecer"*. A recaptura em massa que fiz aqui
mexeu R$ 107 mil no ativo 22 (ele dispensou a restauração). Em prod a migração tem de ser
**granular** e provar, antes de gravar, que cada diferença é uma destas:

1. convergência do motor único (TRUNC/TRUNC para todas as fontes), ou
2. item que não entrava por **inativação** na data-base anterior.

Qualquer outra diferença é defeito, não ajuste — e aí não se grava. Isso ainda não está escrito
como script; é a próxima peça antes da fase 10.

### O caderno (CTC) mostrava a receita CRUA da fonte

Pendência que o Renan mandou congelar em 12/10 (*"depende do refactor do orçamento e será muito,
muito mais simples"*) — e era mesmo. No item 92759 do ativo 26 o documento imprimia os coeficientes
do catálogo (`0,10690` · `0,01750`) enquanto a bancada usava os convertidos (`0,00049` · `0,00008`):
quem conferisse acharia coeficientes que não explicam o preço.

A seção **"4) Composição"** passa a vir da composição GRAVADA. O texto (forma de medição,
remuneração) continua vindo do CTC: ele descreve o SERVIÇO, e isso a conversão não muda. O
coeficiente sai formatado em pt-BR com 5 casas, como o do catálogo — é documento de entrega, e
misturar `0.0005` com `0,10690` na mesma tabela seria ruído de origem.

### O analítico pagava o motor para jogar fora: 4,37 s → 0,31 s

Plugar o estado DEPOIS de `get_conversao_detalhe` resolveu a correção mas não o custo: o motor
rodava inteiro (badges, DE→PARA, composição da fonte) e o resultado era substituído. `get_bancada`
levava 0,02 s e o analítico 4,37 s no mesmo orçamento de 241 itens.

`detalhe_do_estado()` entrega o que o analítico usa — linhas, total e auxiliares — lendo só o
estado. **14× mais rápido**, e sem perder nada: badge e DE→PARA o analítico não mostra. Quem não
tem estado capturado ainda cai no motor, como antes.

### Composição descontinuada: a captura passou a ler o histórico

Ordem do Renan: *"AO GERAR UM ORÇAMENTO, NÃO DEVE EXISTIR ALGO SEM COMPOSIÇÃO NA BANCADA"* — e
*"o motor do caderno não tem que ter fallback, ele tem que ler do banco e pronto; se não tiver no
banco, será erro de migration"*.

Eram **26 serviços** em 3 CPUs (`103353`, `103361`, `103363`) que a SINAPI descontinuou: o catálogo
não tem mais os itens, o motor não tinha o que resolver, e o orçamento ficava com preço gravado e
composição VAZIA. A receita está no histórico — `composicoes_historico.ch_dados_novos.receita` —, e
é a que o orçamento precisa: a composição que existia quando o serviço entrou.

Duas coisas bloqueavam, e as duas saíram:

1. `_do_historico()` na captura: receita do histórico + preço pelo motor com `com_historico=True`.
2. A guarda da composição descontinuada em `_capturar_custo_unit` fazia **`return` antes** de
   capturar — era por ali que os 26 escapavam.

**Resultado: 1.338 serviços com composição, ZERO sem estado.** `composicao_migrada` foi de 654 com
3 sem árvore resolvível para **657 com zero**.

**Fallbacks removidos**, como mandado: o caderno e o analítico leem o estado e pronto. Sem estado, a
composição sai vazia e isso aparece — é erro de migração, não caso a tratar.

### O que isso descobriu: R$ 5,3 milhões fora do orçamento

Com a composição histórica disponível, o `analitico_bancada` passou a acusar o ativo 22: 25
serviços com **custo gravado 0,00** cuja composição soma valor de verdade.

| CPU | itens | quantidade | composição soma | não contado |
|---|---|---|---|---|
| 103353 | 20 | 40.067,66 | R$ 130,91 | **R$ 5.245.141,90** |
| 103361 | 5 | 557,29 | R$ 100,40 | R$ 55.954,02 |

Os R$ 130,91 batem com os R$ 130,88 que o próprio Renan provou em 12/10 ao perguntar por que a
composição havia sumido da busca. O orçamento gravou zero porque, na captura, a CPU já estava
descontinuada e o motor devolveu nada — antes de a guarda existir.

**Isso NÃO foi corrigido:** mexer em R$ 5,3 milhões de um orçamento é decisão dele. O caminho é a
captura usar o custo da composição histórica quando o gravado for zero — a mesma regra da guarda,
um passo adiante.

### A regra do custo, dita pelo Renan (13/10)

> *"o que o motor de detalhamento indica em catálogo não tem correlação alguma com o estado da
> bancada. A bancada só tem que responder: user quer edição x. Tem preço? Se sim, entra na bancada.
> Não tem, entra none e fica sem custo. Não é nossa obrigação falar pra engenheiro se ele pode ou
> não usar composição velha, até porque ele pode estar fazendo uma análise de edições anteriores.
> (…) o custo é o cálculo dos preços dos insumos resolvidos e, portanto, o que entram são os preços
> e o custo o motor da bancada calcula e grava, o qual pode divergir sem qualquer problema do
> catálogo."*

Eu havia proposto copiar o `cc_custo_calculado` publicado. Errado. **O que entra do catálogo são os
PREÇOS DOS INSUMOS; o custo é calculado pelo motor da bancada e gravado.** Divergir do publicado é
esperado — TRUNC/TRUNC, L.S. do ativo, regime.

**O fix:** quando o motor não devolve custo mas a árvore está INTEIRA (caso da descontinuada, cuja
receita vem do histórico), o custo é a soma das linhas. Faltando preço em qualquer linha, fica
`None` e o serviço entra sem custo — que é o comportamento certo.

**Zero não é preço.** A mesma lição em três lugares, e os três mantinham o serviço valendo nada:
a guarda da composição descontinuada, a guarda do recálculo e a própria captura testavam
`is not None`, e `0.00` passava como preço a preservar. Agora é `> 0`.

**Ativo 22, autorizado pelo Renan:** os 25 serviços passaram a valer **R$ 130,88** e **R$ 100,38**
— os números que ele mesmo provou em 12/10 — e o orçamento subiu **R$ 6.512.010,84**.

### Check de sanidade do cenário real (orçamento novo, edição de um ano atrás)

| pergunta | resposta |
|---|---|
| a busca da bancada acha composição desativada? | **sim** |
| o snapshot da inativa entra em `ativo_orcamento_*`? | **sim** — receita do histórico, e agora com custo calculado (112,22 e 91,09 contra 111,76 e 90,75 publicados: divergência legítima) |
| a migração considera a data-base da bancada? | **não considerava** — corrigido |
| a migração valida preços/custos? | **não validava** — `custo_vs_publicado.py` escrito |

### O bug de data-base no migrador

```sql
WHERE cc_cmp_id=%s AND cc_uf='SP' AND cc_modalidade='SD'
ORDER BY cc_edi_id DESC LIMIT 1
```

O custo das sub-CPUs vinha com **UF e modalidade fixas em SP/SD e a edição mais recente**. Obra em
SC com data-base de um ano atrás recebia custo de SP na edição corrente. Em dev não aparecia porque
quase tudo é SP na edição atual; em produção seria o caso normal. Agora usa a edição/UF/modalidade
que o ativo configurou, e cai na edição anterior mais próxima quando a data-base não publicou.

### `custo_vs_publicado.py` — o que ele valida, e o que NÃO valida

Não julga o orçamento pelo custo publicado: isso daria alarme todo dia, porque divergir é legítimo.
Valida o que a migração precisa provar:

1. **o custo fecha** — `acc_valor` == Σ(TRUNC de cada linha). Truncar cada linha antes de somar é o
   que a bancada faz; somar os produtos crus dava 2 a 5 centavos a mais e acusava 303 falsos.
2. **o preço veio da data-base** — `azp_valor` == preço na edição/UF/modalidade do orçamento.
   **0 de 1.415 fora.**
3. **toda composição DE ITEM tem linhas** — sub-CPU sem linhas é folha (a MO), e isso é normal.

### A linha convertida saía com o rótulo do original

No item 14570 (ADAPTADOR CPVC), "Ver composição" mostrava `88267 · H · R$ 6.605,61`: o código e a
**unidade do original (horista)** carregando o preço do **substituto (mensalista)**. Número certo,
rótulo errado — pior que número errado, porque não se desconfia dele. "Ver conversão" mostrava o
par corretamente (SUB `101402 · MES` / ORI `88267 · H`), porque aquela tela ainda monta o DE→PARA
pelo motor.

Causa: `arvore_do_estado` guardava o `sub_cmp_id` do vetor mas **não preenchia `sub_codigo`,
`sub_descricao`, `sub_unidade` e `sub_fonte`** — e a template prefere `sub_*` quando existe. Agora
preenche, a partir do vetor gravado, com cache por (origem, tipo, id): a mesma MO substituta
aparece em dezenas de composições e a identidade dela não muda dentro da requisição.

### Caderno: 3,09 s → 2,56 s, e o que sobra é ReportLab

O perfil achou o culpado: **`montar_desc_tenant` consumia 0,55 s de 1,0 s** chamando `get_analitico`
→ `_preco_na_cmp` → `resolver_ls` (170 vezes) para montar itens **que o caderno descarta** — a
composição dele vem do estado. Agora pede o descritivo com `com_itens=False` e usa só o texto
(forma de medição, remuneração), que é o que o CTC tem a dizer.

| | antes | agora |
|---|---|---|
| montar | 0,95 s | **0,46 s** |
| PDF (263 páginas, 923 KB) | 2,15 s | 2,10 s |
| **total** | 3,09 s | **2,56 s** |

Os ~10 s observados na tela incluem transferir 923 KB e o navegador renderizar 263 páginas — o
back entrega em 2,5 s. Cortar mais exige mexer no documento (menos páginas, menos âncoras), que é
outra conversa.

### Caderno: 3,09 s → ~2,0 s, e o gargalo era o LOGO

Perfilado em vez de adivinhado. Três achados, todos fora do que se esperaria (ninguém olharia para
o cabeçalho procurando lentidão num documento de 263 páginas):

| | |
|---|---|
| `montar_desc_tenant` recalculava preço | 0,55 s de 1,0 s, para montar itens que o caderno descarta — a composição vem do estado. Agora `com_itens=False` |
| `ImageReader` criado a CADA página | o PNG do logo decodificado 263 vezes. Cacheado por hash do conteúdo: **2,10 → 1,62 s** |
| **MD5 do logo a cada `drawImage`** | o ReportLab hasheia os dados CRUS da imagem por página. O logo chega com 1263×302 RGBA — **1,5 MB crus** — e aparece com 18 mm de altura. Reamostrado para 240 px (18 mm a 300 dpi, qualidade gráfica preservada): **1,62 → 1,02 s** |

| | antes | agora |
|---|---|---|
| montar | 0,95 s | **0,44 s** |
| PDF | 2,15 s | **1,0–1,5 s** |
| **total** | **3,09 s** | **~2,0 s** |
| arquivo | 923 KB | 902 KB |

O que sobra é ReportLab compondo 263 páginas, e isso não se otimiza sem mexer no documento. Os ~10 s
na tela incluem baixar 900 KB e o navegador renderizar as 263 páginas.

**O ganho do logo vale para TODOS os documentos da app**, não só o caderno: `service_report.desenhar`
é o timbrado de qualquer PDF.
