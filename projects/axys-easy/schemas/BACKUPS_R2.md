# Dumps do banco — onde ficam e o que cada um guarda

**Bucket:** `axys-private` (R2) · **Prefixo:** `easy/backups/db/`

Este índice existe porque o dump é a única memória que sobrevive a dev e a produção ao mesmo tempo.
Dropar tabela, migrar schema ou rodar recaptura em massa são operações que o banco não desfaz; o
caminho de volta é um arquivo aqui. Sem um índice, ninguém sabe o que cada `.dump` contém — e um
backup que ninguém sabe ler não é backup.

**Quem sobe:** `z_scripts_apoio/manutencao/db_dump_para_r2.py`, rodado no shell do Render (o banco
de produção não aceita conexão de fora, e a credencial não sai do container). O par dele é o
`db_restore_do_r2.sh`, que roda na máquina local.

**Convenção de nome:** `easy_prod_{AAAA-MM-DD_HHMMSS}.dump` para o dump completo de rotina.
Backup pontual, tirado antes de uma operação específica, leva o nome da operação — é o que permite
saber o porquê sem abrir o arquivo.

---

## O que está lá

| arquivo | data | tamanho | o que é |
|---|---|---|---|
| `oregon_catalogo_20260824_0611.dump` | 2026-08-24 06:13 | 311,1 MB | catálogo na região Oregon, antes da mudança de banco |
| `full_2cx5_20260824_0641.dump` | 2026-08-24 06:41 | 0,0 MB | tentativa truncada — **não serve para restaurar** |
| `full_2cx5_20260824_0653.dump` | 2026-08-24 06:55 | 311,6 MB | o completo que substituiu o anterior |
| `pre_refactor_motor_20260910_0045.dump` | 2026-09-10 00:47 | 311,8 MB | antes do refactor do motor de custo |
| `easy_prod_2026-09-24_131431.dump` | 2026-09-24 13:16 | 327,9 MB | rotina |
| `easy_prod_2026-10-12_231834.dump` | 2026-10-12 23:19 | 329,3 MB | **antes da migração do `ativo_orcamento`** — o ponto de retorno do refactor |
| `pre_drop_tabelas_antigas_orcamento_20261013_1051.sql` | 2026-10-13 10:51 | 0,9 MB | as **16 tabelas antigas do orçamento**, estrutura e dados, tiradas minutos antes do `DROP` |

### O último, em detalhe

`pre_drop_tabelas_antigas_orcamento_20261013_1051.sql` · sha256
`6146495dbd3df28860b10d2f17c6014f89936e4a7f5a97813ba19c336241986b`

É `pg_dump` em texto (não `custom`), restaurável com `psql`. Contém as 16 tabelas que o refactor
aposentou e que foram dropadas de dev e de produção em 13/10:

```
ativo_itens · ativo_itens_drivers
ativo_bdi · ativo_bdi_composicao
ativo_ls · ativo_ls_item
cronograma · cronograma_itens
memo_calc · memo_calc_item · memo_calc_arquivo · memo_calc_item_link
orcamento_parametros
ativo_revisoes · orcamento_insumos · orcamento_insumos_preco
```

As três últimas estavam vazias (lixo confirmado). As demais guardam o dado de ORIGEM da migração —
é contra elas que se confere qualquer suspeita de que a migração perdeu algo.

**Para restaurar só uma delas**, num banco de inspeção (nunca em cima do atual):

```bash
# baixar do R2 e restaurar num schema/banco separado
psql "$DSN_DE_INSPECAO" -f pre_drop_tabelas_antigas_orcamento_20261013_1051.sql
```

---

## Regra

Backup pontual antes de operação destrutiva **sobe para cá**, com nome que diz a operação e a data.
O arquivo no disco local, ou no diretório temporário de uma sessão, não conta como backup — ele
some. Só o que está no R2 persiste independentemente de dev e de produção.
