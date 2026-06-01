"""
generic_migrate_postgres_to_postgres_check.py

Validação genérica de clone PostgreSQL -> PostgreSQL por contagem de registros.

Uso:
    python backend/data/migration/generic_migrate_postgres_to_postgres_check.py \
        --src-host ... --src-db ... --src-user ... --src-password ... \
        --dst-host ... --dst-db ... --dst-user ... --dst-password ...

Sem include/exclude explícito, compara todos os schemas de usuário em comum entre
origem e destino.

Prioridade de configuração:
1. argumentos CLI
2. dicionários SRC_PG_CONFIG / DST_PG_CONFIG neste arquivo
3. variáveis de ambiente
"""

from __future__ import annotations

import argparse
import os
from datetime import datetime

import psycopg


SYSTEM_SCHEMAS = {
    "information_schema",
    "pg_catalog",
    "pg_toast",
}

SRC_PG_CONFIG = {
    "host": "",
    "port": 5432,
    "dbname": "",
    "user": "",
    "password": "",
    "options": "-c timezone=America/Sao_Paulo",
    "sslmode": "",
}

DST_PG_CONFIG = {
    "host": "",
    "port": 5432,
    "dbname": "",
    "user": "",
    "password": "",
    "options": "-c timezone=America/Sao_Paulo",
    "sslmode": "",
}


def _env_or_default(name: str, default: str = "") -> str:
    return str(os.environ.get(name, default) or "").strip()


def _config_value(prefix: str, field: str, env_name: str, default=""):
    inline_config = SRC_PG_CONFIG if prefix == "src" else DST_PG_CONFIG
    inline_value = inline_config.get(field, default)
    if field == "port":
        raw = inline_value if inline_value not in (None, "") else _env_or_default(env_name, str(default or "5432"))
        return int(raw)
    return str(inline_value or "").strip() or _env_or_default(env_name, str(default))


def _parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Valida por contagem um clone PostgreSQL entre origem e destino."
    )
    for prefix in ("src", "dst"):
        parser.add_argument(f"--{prefix}-host", default=_config_value(prefix, "host", f"{prefix.upper()}_PGHOST"))
        parser.add_argument(f"--{prefix}-port", type=int, default=_config_value(prefix, "port", f"{prefix.upper()}_PGPORT", 5432))
        parser.add_argument(f"--{prefix}-db", default=_config_value(prefix, "dbname", f"{prefix.upper()}_PGDATABASE"))
        parser.add_argument(f"--{prefix}-user", default=_config_value(prefix, "user", f"{prefix.upper()}_PGUSER"))
        parser.add_argument(f"--{prefix}-password", default=_config_value(prefix, "password", f"{prefix.upper()}_PGPASSWORD"))
        parser.add_argument(
            f"--{prefix}-options",
            default=_config_value(prefix, "options", f"{prefix.upper()}_PGOPTIONS", "-c timezone=America/Sao_Paulo"),
        )
        parser.add_argument(f"--{prefix}-sslmode", default=_config_value(prefix, "sslmode", f"{prefix.upper()}_PGSSLMODE"))
    parser.add_argument("--include-schema", action="append", default=[])
    parser.add_argument("--exclude-schema", action="append", default=[])
    return parser.parse_args()


def _build_pg_config(args: argparse.Namespace, prefix: str) -> dict[str, object]:
    config = {
        "host": getattr(args, f"{prefix}_host"),
        "port": getattr(args, f"{prefix}_port"),
        "dbname": getattr(args, f"{prefix}_db"),
        "user": getattr(args, f"{prefix}_user"),
        "password": getattr(args, f"{prefix}_password"),
        "options": getattr(args, f"{prefix}_options"),
    }
    sslmode = str(getattr(args, f"{prefix}_sslmode") or "").strip()
    if sslmode:
        config["sslmode"] = sslmode
    return config


def _validate_pg_config(config: dict[str, object], label: str) -> None:
    missing = [key for key in ("host", "port", "dbname", "user", "password") if not config.get(key)]
    if missing:
        raise RuntimeError(f"Configuração de {label} incompleta. Campos ausentes: {', '.join(missing)}")


def _log(msg: str) -> None:
    now = datetime.now().strftime("%H:%M:%S")
    print(f"[{now}] {msg}")


def _list_user_schemas(conn) -> list[str]:
    with conn.cursor() as cur:
        cur.execute(
            """
            SELECT schema_name
              FROM information_schema.schemata
             WHERE schema_name NOT IN ('information_schema', 'pg_catalog', 'pg_toast')
               AND schema_name NOT LIKE 'pg_temp_%'
               AND schema_name NOT LIKE 'pg_toast_temp_%'
             ORDER BY schema_name
            """
        )
        rows = cur.fetchall()
    return [str(row[0]) for row in rows if str(row[0]) not in SYSTEM_SCHEMAS]


def _list_base_tables(conn, schemas: list[str]) -> list[tuple[str, str]]:
    with conn.cursor() as cur:
        cur.execute(
            """
            SELECT table_schema, table_name
              FROM information_schema.tables
             WHERE table_type = 'BASE TABLE'
               AND table_schema = ANY(%s)
             ORDER BY table_schema, table_name
            """,
            (schemas,),
        )
        return [(str(schema), str(table)) for schema, table in cur.fetchall()]


def _table_exists(conn, schema: str, table_name: str) -> bool:
    with conn.cursor() as cur:
        cur.execute("SELECT to_regclass(%s)", (f'"{schema}"."{table_name}"',))
        return cur.fetchone()[0] is not None


def _resolve_schemas(src_conn, dst_conn, include_schemas: list[str], exclude_schemas: list[str]) -> list[str]:
    src_schemas = set(_list_user_schemas(src_conn))
    dst_schemas = set(_list_user_schemas(dst_conn))
    common = src_schemas & dst_schemas
    if include_schemas:
        common &= set(include_schemas)
    if exclude_schemas:
        common -= set(exclude_schemas)
    return sorted(common)


def _compare_counts(src_conn, dst_conn, schemas: list[str]) -> bool:
    _log("=== COUNT POR TABELA ===")
    ok = True
    for schema, table_name in _list_base_tables(src_conn, schemas):
        src_exists = _table_exists(src_conn, schema, table_name)
        dst_exists = _table_exists(dst_conn, schema, table_name)

        if not src_exists and not dst_exists:
            print(f"{schema}.{table_name:<36} origem=N/A      destino=N/A      AUSENTE NOS DOIS")
            continue
        if not src_exists:
            print(f"{schema}.{table_name:<36} origem=N/A      destino=EXISTE   AUSENTE NA ORIGEM")
            ok = False
            continue
        if not dst_exists:
            print(f"{schema}.{table_name:<36} origem=EXISTE   destino=N/A      AUSENTE NO DESTINO")
            ok = False
            continue

        qualified_name = f'"{schema}"."{table_name}"'
        with src_conn.cursor() as src_cur, dst_conn.cursor() as dst_cur:
            src_cur.execute(f"SELECT COUNT(*) FROM {qualified_name}")
            src_count = int(src_cur.fetchone()[0])
            dst_cur.execute(f"SELECT COUNT(*) FROM {qualified_name}")
            dst_count = int(dst_cur.fetchone()[0])

        status = "OK" if src_count == dst_count else "DIVERGENTE"
        print(f"{schema}.{table_name:<36} origem={src_count:<8} destino={dst_count:<8} {status}")
        if src_count != dst_count:
            ok = False
    return ok


def main() -> None:
    args = _parse_args()
    src_config = _build_pg_config(args, "src")
    dst_config = _build_pg_config(args, "dst")
    _validate_pg_config(src_config, "origem")
    _validate_pg_config(dst_config, "destino")

    include_schemas = [str(item).strip() for item in args.include_schema if str(item).strip()]
    exclude_schemas = [str(item).strip() for item in args.exclude_schema if str(item).strip()]

    with psycopg.connect(**src_config) as src_conn, psycopg.connect(**dst_config) as dst_conn:
        schemas = _resolve_schemas(src_conn, dst_conn, include_schemas, exclude_schemas)
        if not schemas:
            print("Nenhum schema em comum encontrado entre origem e destino.")
            return
        _log(f"Schemas comparados: {', '.join(schemas)}")
        ok_counts = _compare_counts(src_conn, dst_conn, schemas)

    print("\n=== RESULTADO FINAL ===")
    print("VALIDAÇÃO OK" if ok_counts else "VALIDAÇÃO COM DIVERGÊNCIAS")


if __name__ == "__main__":
    main()
