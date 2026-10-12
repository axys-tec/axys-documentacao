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
| 9 · `schema.sql` | **FEITA** | 11/10 |

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
