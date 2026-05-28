"""
generic_migrate_postgres_to_postgres.py

Clone genérico de um banco PostgreSQL remoto para um banco PostgreSQL local.

Objetivo:
- copiar toda a base lógica da origem para o destino
- limpar todos os schemas de usuário do destino antes do restore
- funcionar para qualquer par origem/destino via argumentos CLI ou variáveis
  de ambiente, sem ficar acoplado ao projeto LunalôSys

Uso:
    python backend/data/migration/generic_migrate_postgres_to_postgres.py \
        --src-host ... --src-db ... --src-user ... --src-password ... \
        --dst-host ... --dst-db ... --dst-user ... --dst-password ...

Variáveis de ambiente aceitas:
    SRC_PGHOST, SRC_PGPORT, SRC_PGDATABASE, SRC_PGUSER, SRC_PGPASSWORD, SRC_PGOPTIONS
    DST_PGHOST, DST_PGPORT, DST_PGDATABASE, DST_PGUSER, DST_PGPASSWORD, DST_PGOPTIONS

Opcional:
    --include-schema public --include-schema mirror
    --exclude-schema analytics

Regra padrão:
- sem filtros explícitos de schema, clona todos os schemas de usuário
  (exclui pg_catalog, information_schema, pg_toast e temporários)

Prioridade de configuração:
1. argumentos CLI
2. dicionários SRC_PG_CONFIG / DST_PG_CONFIG neste arquivo
3. variáveis de ambiente
"""

from __future__ import annotations

import argparse
import os
import re
import shutil
import subprocess
import tempfile
from pathlib import Path

import psycopg


COMMON_PG_BIN_DIRS = (
    Path("/opt/homebrew/bin"),
    Path("/opt/homebrew/opt/postgresql@18/bin"),
    Path("/opt/homebrew/opt/postgresql@17/bin"),
    Path("/opt/homebrew/opt/postgresql@16/bin"),
    Path("/opt/homebrew/opt/postgresql@15/bin"),
    Path("/usr/local/bin"),
    Path("/Applications/Postgres.app/Contents/Versions/latest/bin"),
    Path("/Applications/Postgres.app/Contents/Versions/18/bin"),
    Path("/Applications/Postgres.app/Contents/Versions/17/bin"),
    Path("/Applications/Postgres.app/Contents/Versions/16/bin"),
)

SYSTEM_SCHEMAS = {
    "information_schema",
    "pg_catalog",
    "pg_toast",
}

# Se quiser usar o script de forma rápida, preencha aqui e rode sem argumentos.
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
        description="Clona um banco PostgreSQL remoto para um banco PostgreSQL local."
    )

    for prefix, label in (("src", "origem"), ("dst", "destino")):
        parser.add_argument(f"--{prefix}-host", default=_config_value(prefix, "host", f"{prefix.upper()}_PGHOST"))
        parser.add_argument(f"--{prefix}-port", type=int, default=_config_value(prefix, "port", f"{prefix.upper()}_PGPORT", 5432))
        parser.add_argument(f"--{prefix}-db", default=_config_value(prefix, "dbname", f"{prefix.upper()}_PGDATABASE"))
        parser.add_argument(f"--{prefix}-user", default=_config_value(prefix, "user", f"{prefix.upper()}_PGUSER"))
        parser.add_argument(f"--{prefix}-password", default=_config_value(prefix, "password", f"{prefix.upper()}_PGPASSWORD"))
        parser.add_argument(
            f"--{prefix}-options",
            default=_config_value(prefix, "options", f"{prefix.upper()}_PGOPTIONS", "-c timezone=America/Sao_Paulo"),
        )
        parser.add_argument(
            f"--{prefix}-sslmode",
            default=_config_value(prefix, "sslmode", f"{prefix.upper()}_PGSSLMODE"),
            help=f"sslmode do PostgreSQL para {label}",
        )

    parser.add_argument(
        "--include-schema",
        action="append",
        default=[],
        help="Schema de usuário a incluir. Pode ser repetido.",
    )
    parser.add_argument(
        "--exclude-schema",
        action="append",
        default=[],
        help="Schema de usuário a excluir. Pode ser repetido.",
    )
    parser.add_argument(
        "--keep-destination-extra-schemas",
        action="store_true",
        help="Não remove schemas de usuário extras já existentes no destino.",
    )
    parser.add_argument(
        "--archive-path",
        default="",
        help="Caminho opcional para reaproveitar/salvar o dump custom format.",
    )
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


def _cmd_env(pg_config: dict[str, object]) -> dict[str, str]:
    env = os.environ.copy()
    env["PGPASSWORD"] = str(pg_config["password"])
    if pg_config.get("sslmode"):
        env["PGSSLMODE"] = str(pg_config["sslmode"])
    return env


def _run_cmd(args: list[str], *, env: dict[str, str], label: str) -> None:
    print(f"{label}: {' '.join(args)}")
    subprocess.run(args, env=env, check=True)


def _parse_major(version_text: str) -> int:
    match = re.search(r"(\d+)", version_text)
    if not match:
        raise RuntimeError(f"Não foi possível extrair a major version de: {version_text}")
    return int(match.group(1))


def _get_server_version(conn) -> tuple[int, str]:
    with conn.cursor() as cur:
        cur.execute("SHOW server_version_num")
        version_num = str(cur.fetchone()[0])
        cur.execute("SHOW server_version")
        version_text = str(cur.fetchone()[0])
    return int(version_num[:2]), version_text


def _list_candidate_binaries(cli_name: str) -> list[Path]:
    seen: set[str] = set()
    candidates: list[Path] = []

    which_path = shutil.which(cli_name)
    if which_path:
        resolved = str(Path(which_path).resolve())
        if resolved not in seen:
            candidates.append(Path(resolved))
            seen.add(resolved)

    for bin_dir in COMMON_PG_BIN_DIRS:
        candidate = bin_dir / cli_name
        if candidate.exists():
            resolved = str(candidate.resolve())
            if resolved not in seen:
                candidates.append(Path(resolved))
                seen.add(resolved)

    cellar_root = Path("/opt/homebrew/Cellar")
    if cellar_root.exists():
        for candidate in cellar_root.glob(f"postgresql@*/**/bin/{cli_name}"):
            resolved = str(candidate.resolve())
            if resolved not in seen:
                candidates.append(Path(resolved))
                seen.add(resolved)

    return candidates


def _get_cli_major(cli_path: Path) -> int:
    proc = subprocess.run(
        [str(cli_path), "--version"],
        capture_output=True,
        text=True,
        check=True,
    )
    return _parse_major(proc.stdout.strip())


def _resolve_cli(cli_name: str, *, min_major: int | None = None, env_var: str | None = None) -> Path:
    override = _env_or_default(env_var or "")
    if override:
        cli_path = Path(override).expanduser().resolve()
        if not cli_path.exists():
            raise RuntimeError(f"{env_var} aponta para caminho inexistente: {cli_path}")
        cli_major = _get_cli_major(cli_path)
        if min_major is not None and cli_major < min_major:
            raise RuntimeError(
                f"{env_var}={cli_path} está na major {cli_major}, mas este clone requer ao menos {min_major}"
            )
        return cli_path

    candidates: list[tuple[int, Path]] = []
    for cli_path in _list_candidate_binaries(cli_name):
        try:
            cli_major = _get_cli_major(cli_path)
        except Exception:
            continue
        candidates.append((cli_major, cli_path))

    if not candidates:
        raise RuntimeError(f"Nenhum binário candidato encontrado para {cli_name}")

    candidates.sort(key=lambda item: (item[0], str(item[1])), reverse=True)
    if min_major is None:
        return candidates[0][1]

    for cli_major, cli_path in candidates:
        if cli_major >= min_major:
            return cli_path

    installed = ", ".join(f"{path} (v{major})" for major, path in candidates)
    raise RuntimeError(
        f"Nenhum {cli_name} compatível encontrado. Origem exige major >= {min_major}. "
        f"Instalados: {installed}."
    )


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


def _resolve_schemas_to_clone(
    src_conn,
    *,
    include_schemas: list[str],
    exclude_schemas: list[str],
) -> list[str]:
    available = _list_user_schemas(src_conn)
    if include_schemas:
        selected = [schema for schema in available if schema in set(include_schemas)]
    else:
        selected = list(available)
    excluded = set(exclude_schemas)
    selected = [schema for schema in selected if schema not in excluded]
    if not selected:
        raise RuntimeError("Nenhum schema elegível encontrado para clonar.")
    return selected


def _dump_source_to_archive(
    archive_path: Path,
    pg_dump_bin: Path,
    src_config: dict[str, object],
    schemas: list[str],
) -> None:
    args = [
        str(pg_dump_bin),
        "-h", str(src_config["host"]),
        "-p", str(src_config["port"]),
        "-U", str(src_config["user"]),
        "-d", str(src_config["dbname"]),
        "-Fc",
        "--no-owner",
        "--no-privileges",
    ]
    for schema in schemas:
        args.extend(["--schema", schema])
    args.extend(["-f", str(archive_path)])
    _run_cmd(args, env=_cmd_env(src_config), label="pg_dump origem")


def _reset_destination_schemas(
    dst_conn,
    *,
    schemas_from_source: list[str],
    drop_extra_schemas: bool,
) -> None:
    destination_schemas = _list_user_schemas(dst_conn)
    schemas_to_drop = set(schemas_from_source)
    if drop_extra_schemas:
        schemas_to_drop.update(destination_schemas)

    with dst_conn.cursor() as cur:
        for schema in sorted(schemas_to_drop):
            cur.execute(f'DROP SCHEMA IF EXISTS "{schema}" CASCADE')
    dst_conn.commit()


def _restore_archive_to_destination(
    archive_path: Path,
    pg_restore_bin: Path,
    dst_config: dict[str, object],
) -> None:
    args = [
        str(pg_restore_bin),
        "-h", str(dst_config["host"]),
        "-p", str(dst_config["port"]),
        "-U", str(dst_config["user"]),
        "-d", str(dst_config["dbname"]),
        "--no-owner",
        "--no-privileges",
        "--exit-on-error",
        str(archive_path),
    ]
    _run_cmd(args, env=_cmd_env(dst_config), label="pg_restore destino")


def _qualified_table_name(schema: str, table_name: str) -> str:
    return f'"{schema}"."{table_name}"'


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


def _compare_counts(src_conn, dst_conn, schemas: list[str]) -> bool:
    print("\n=== VALIDAÇÃO DE CONTAGEM ===")
    ok = True
    for schema, table_name in _list_base_tables(src_conn, schemas):
        qualified_name = _qualified_table_name(schema, table_name)
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

    with psycopg.connect(**src_config) as src_conn:
        remote_major, remote_version = _get_server_version(src_conn)
        schemas = _resolve_schemas_to_clone(
            src_conn,
            include_schemas=[str(item).strip() for item in args.include_schema if str(item).strip()],
            exclude_schemas=[str(item).strip() for item in args.exclude_schema if str(item).strip()],
        )

    with psycopg.connect(**dst_config) as dst_conn:
        local_major, local_version = _get_server_version(dst_conn)

    pg_dump_bin = _resolve_cli("pg_dump", min_major=remote_major, env_var="PG_DUMP_BIN")
    pg_restore_bin = _resolve_cli("pg_restore", min_major=remote_major, env_var="PG_RESTORE_BIN")

    print(f"Servidor origem: {remote_version}")
    print(f"Servidor destino: {local_version}")
    print(f"Schemas clonados: {', '.join(schemas)}")
    print(f"Cliente pg_dump: {pg_dump_bin}")
    print(f"Cliente pg_restore: {pg_restore_bin}")
    if local_major < remote_major:
        print(
            "Aviso: o servidor destino está em major inferior à origem. "
            "O restore pode falhar se houver DDL incompatível."
        )

    archive_override = str(args.archive_path or "").strip()
    if archive_override:
        archive_path = Path(archive_override).expanduser().resolve()
        archive_path.parent.mkdir(parents=True, exist_ok=True)
        temp_dir_ctx = None
    else:
        temp_dir_ctx = tempfile.TemporaryDirectory(prefix="generic_pg_clone_")
        archive_path = Path(temp_dir_ctx.name) / "source_clone.dump"

    try:
        _dump_source_to_archive(archive_path, pg_dump_bin, src_config, schemas)
        with psycopg.connect(**dst_config) as dst_conn:
            _reset_destination_schemas(
                dst_conn,
                schemas_from_source=schemas,
                drop_extra_schemas=not bool(args.keep_destination_extra_schemas),
            )
        _restore_archive_to_destination(archive_path, pg_restore_bin, dst_config)

        with psycopg.connect(**src_config) as src_conn, psycopg.connect(**dst_config) as dst_conn:
            counts_ok = _compare_counts(src_conn, dst_conn, schemas)

        print("\n=== RESULTADO FINAL ===")
        print("CLONE CONCLUÍDO COM VALIDAÇÃO OK" if counts_ok else "CLONE CONCLUÍDO COM DIVERGÊNCIAS")
    finally:
        if temp_dir_ctx is not None:
            temp_dir_ctx.cleanup()


if __name__ == "__main__":
    main()
