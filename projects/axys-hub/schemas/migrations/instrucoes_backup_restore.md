# Opção 1 - Via Python

## HUB: Render → local
python db/migration/generic_migrate_postgres_to_postgres.py \
  --src-host dpg-d60b55npm1nc73d6n9a0-a.ohio-postgres.render.com \
  --src-db   axys_hub_db --src-user axys_tec \
  --src-password A7Xu12yaVn7SVV96iPoD2cTEkfY5enYf \
  --src-sslmode require \
  --dst-host localhost --dst-db axys_hub_db \
  --dst-user axys_tec --dst-password 'Decswxaqz1607@'

## DASH: Render → local
python db/migration/generic_migrate_postgres_to_postgres.py \
  --src-host dpg-d60b5pogjchc7398lq40-a.ohio-postgres.render.com \
  --src-db   axys_dash_db --src-user axys_tec \
  --src-password wDnON7G1RWm2kkdqZut6fG2J1L9puCjo \
  --src-sslmode require \
  --dst-host localhost --dst-db axys_dash_db \
  --dst-user axys_tec --dst-password 'Decswxaqz1607@'

## Check

### HUB: Render → local
python db/migration/generic_migrate_postgres_to_postgres_check.py \
  --src-host dpg-d60b55npm1nc73d6n9a0-a.ohio-postgres.render.com \
  --src-db axys_hub_db --src-user axys_tec \
  --src-password A7Xu12yaVn7SVV96iPoD2cTEkfY5enYf --src-sslmode require \
  --dst-host localhost --dst-db axys_hub_db \
  --dst-user axys_tec --dst-password 'Decswxaqz1607@'

  ### DASH: Render → local
python db/migration/generic_migrate_postgres_to_postgres_check.py \
  --src-host dpg-d60b5pogjchc7398lq40-a.ohio-postgres.render.com \
  --src-db   axys_dash_db --src-user axys_tec \
  --src-password wDnON7G1RWm2kkdqZut6fG2J1L9puCjo \
  --src-sslmode require \
  --dst-host localhost --dst-db axys_dash_db \
  --dst-user axys_tec --dst-password 'Decswxaqz1607@'



# Opção 2 - Via Psql

## Gerar backup 

bash db/migration/backup_render_dbs.sh

## Criar bancos locais

psql -d postgres -c "CREATE DATABASE axys_hub_db OWNER axys_tec ENCODING 'UTF8' LC_COLLATE 'pt_BR.UTF-8' LC_CTYPE 'pt_BR.UTF-8' TEMPLATE template0;"

psql -d postgres -c "CREATE DATABASE axys_dash_db OWNER axys_tec ENCODING 'UTF8' LC_COLLATE 'pt_BR.UTF-8' LC_CTYPE 'pt_BR.UTF-8' TEMPLATE template0;"


## restaurar os dumps
pg_restore -d axys_hub_db \
  --no-owner --no-privileges --role=axys_tec \
  db/backups/hub_backup_axys_hub_db_20260527_172650.dump

pg_restore -d axys_dash_db \
  --no-owner --no-privileges --role=axys_tec \
  db/backups/dash_backup_axys_dash_db_20260527_172710.dump


## Verificar

psql -d axys_hub_db  -c "\dt *.*" 2>&1 | head -40
psql -d axys_dash_db -c "\dt *.*" 2>&1 | head -40
