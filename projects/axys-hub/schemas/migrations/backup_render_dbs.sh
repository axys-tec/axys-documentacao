#!/usr/bin/env bash
# backup_render_dbs.sh — Faz backup dos dois bancos Render para db/backups/
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
ENV_FILE="$ROOT_DIR/.env"
OUTPUT_DIR="$ROOT_DIR/db/backups"
BACKUP_PY="$SCRIPT_DIR/generic_generate_postgres_backup.py"

if [ ! -f "$ENV_FILE" ]; then
  echo "ERRO: arquivo .env não encontrado em $ENV_FILE"
  exit 1
fi

# Carrega .env
set -o allexport
# shellcheck source=/dev/null
source "$ENV_FILE"
set +o allexport

mkdir -p "$OUTPUT_DIR"

# ── Helper: extrai partes de uma URL postgresql://user:pass@host[:port]/db ──
parse_pg_url() {
  local url="${1#postgresql://}"
  local userinfo="${url%%@*}"
  local rest="${url#*@}"
  PG_USER="${userinfo%%:*}"
  PG_PASS="${userinfo#*:}"
  local hostport="${rest%%/*}"
  PG_DB="${rest##*/}"
  if [[ "$hostport" == *:* ]]; then
    PG_HOST="${hostport%%:*}"
    PG_PORT="${hostport##*:}"
  else
    PG_HOST="$hostport"
    PG_PORT="5432"
  fi
}

run_backup() {
  local label="$1"
  local url="$2"
  local prefix="$3"

  echo ""
  echo "════════════════════════════════════"
  echo " Backup: $label"
  echo "════════════════════════════════════"
  parse_pg_url "$url"

  python3 "$BACKUP_PY" \
    --src-host     "$PG_HOST" \
    --src-port     "$PG_PORT" \
    --src-db       "$PG_DB" \
    --src-user     "$PG_USER" \
    --src-password "$PG_PASS" \
    --src-sslmode  "require" \
    --output-dir   "$OUTPUT_DIR" \
    --prefix       "$prefix"
}

run_backup "axys_hub_db"  "$HUB_DB_URL"  "hub_backup"
run_backup "axys_dash_db" "$DASH_DB_URL" "dash_backup"

echo ""
echo "✓ Backups salvos em: $OUTPUT_DIR"
