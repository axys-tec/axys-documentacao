# Migrations

**Esta é a única pasta de migrations.** Houve três — `z_scripts_apoio/migrations/` e
`docs/migrations/` —, e foi assim que `cro_travado` ficou seis dias sem migration com o cronograma
fora do ar em produção. As trinta foram reunidas aqui em 20/10/2026.

## Nome

```
AAAA-MM-DD_assunto.sql
```

Não há numeração sequencial nem controle de versão em tabela. A data ordena, e o registro de quem
rodou o quê é o histórico do git mais a conferência no banco.

## Regras

**Nasce no mesmo commit da alteração do `schema.sql`.** Não "depois", não "quando for subir. O
débito não aparece em dev — aparece no deploy, como app quebrada, e ninguém liga uma coisa à outra.

**É idempotente.** `CREATE TABLE IF NOT EXISTS`, `ADD COLUMN IF NOT EXISTS`, constraint dentro de
`DO $$ ... EXCEPTION WHEN duplicate_object THEN NULL; END $$`, `INSERT ... ON CONFLICT DO NOTHING`.

**Valida-se em dev, onde tudo já existe.** Tem de ser no-op completo: contar as linhas antes e
depois e dar o mesmo número.

**Abre com um cabeçalho que diz o quê e o porquê** — o que muda, qual código passa a exigir isso, e
a linha de comando para rodar. Quem lê daqui a um ano não tem o contexto que você tem agora.

## Rodar

```bash
psql "$EASY_DB_URL" -v ON_ERROR_STOP=1 -f docs/projects/axys-easy/schemas/migrations/<arquivo>.sql
```

`EASY_DB_URL` sai de `.env.local` em desenvolvimento e de `.env.prod` em produção. **Não se conecta
em produção sem pedir.**

## Antes de pushar

Conferir se o banco de produção já tem o que o código novo vai ler:

```bash
psql "$PROD" -At -c "SELECT table_schema||'.'||table_name||'.'||column_name
                       FROM information_schema.columns
                      WHERE table_schema IN ('catalogo','ativo','audit','tenant_catalogo')"
```

Comparar com o mesmo comando em dev. A diferença tem de ser vazia nos dois sentidos.
