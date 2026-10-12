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
| 3 · escrita dupla | — | **depois da 4** (ver abaixo) |
| 4 · migrar dados de dev | **FEITA** | 11/10 |
| 5 · trocar a leitura (flag desligado) | — | |
| 9 · `schema.sql` | — | |

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
