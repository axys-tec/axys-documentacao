"""
generic_generate_postgres_backup.py

Gera um backup genérico de um banco PostgreSQL e salva em arquivo local.

Objetivo:
- conectar em qualquer banco PostgreSQL de origem
- executar um pg_dump em formato custom (-Fc)
- salvar o arquivo em um diretório ou caminho local definido pelo usuário

Uso:
    python backend/data/backup/generic_generate_postgres_backup.py \
        --src-host ... --src-db ... --src-user ... --src-password ... \
        --output-dir ./backups

Ou:
    python backend/data/backup/generic_generate_postgres_backup.py \
        --src-host ... --src-db ... --src-user ... --src-password ... \
        --output-file ./backups/meu_backup.dump

Variáveis de ambiente aceitas:
    SRC_PGHOST, SRC_PGPORT, SRC_PGDATABASE, SRC_PGUSER, SRC_PGPASSWORD, SRC_PGOPTIONS, SRC_PGSSLMODE

Opcional:
    --include-schema public --include-schema mirror
    --exclude-schema analytics

Prioridade de configuração:
1. argumentos CLI
2. dicionário SRC_PG_CONFIG neste arquivo
3. variáveis de ambiente
"""

from __future__ import annotations

import argparse
import os
import re
import shutil
import subprocess
from datetime import datetime
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
    Path(r"C:\Program Files\PostgreSQL\18\bin"),
    Path(r"C:\Program Files\PostgreSQL\17\bin"),
    Path(r"C:\Program Files\PostgreSQL\16\bin"),
    Path(r"C:\Program Files\PostgreSQL\15\bin"),
)

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


def _env_or_default(name: str, default: str = "") -> str:
    return str(os.environ.get(name, default) or "").strip()


def _config_value(field: str, env_name: str, default=""):
    inline_value = SRC_PG_CONFIG.get(field, default)
    if field == "port":
        raw = inline_value if inline_value not in (None, "") else _env_or_default(env_name, str(default or "5432"))
        return int(raw)
    return str(inline_value or "").strip() or _env_or_default(env_name, str(default))


def _parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Gera um backup PostgreSQL em arquivo local."
    )
    parser.add_argument("--src-host", default=_config_value("host", "SRC_PGHOST"))
    parser.add_argument("--src-port", type=int, default=_config_value("port", "SRC_PGPORT", 5432))
    parser.add_argument("--src-db", default=_config_value("dbname", "SRC_PGDATABASE"))
    parser.add_argument("--src-user", default=_config_value("user", "SRC_PGUSER"))
    parser.add_argument("--src-password", default=_config_value("password", "SRC_PGPASSWORD"))
    parser.add_argument(
        "--src-options",
        default=_config_value("options", "SRC_PGOPTIONS", "-c timezone=America/Sao_Paulo"),
    )
    parser.add_argument("--src-sslmode", default=_config_value("sslmode", "SRC_PGSSLMODE"))
    parser.add_argument("--output-dir", default="")
    parser.add_argument("--output-file", default="")
    parser.add_argument("--prefix", default="postgres_backup")
    parser.add_argument("--include-schema", action="append", default=[])
    parser.add_argument("--exclude-schema", action="append", default=[])
    return parser.parse_args()


def _build_pg_config(args: argparse.Namespace) -> dict[str, object]:
    config = {
        "host": args.src_host,
        "port": args.src_port,
        "dbname": args.src_db,
        "user": args.src_user,
        "password": args.src_password,
        "options": args.src_options,
    }
    sslmode = str(args.src_sslmode or "").strip()
    if sslmode:
        config["sslmode"] = sslmode
    return config


def _validate_pg_config(config: dict[str, object]) -> None:
    missing = [key for key in ("host", "port", "dbname", "user", "password") if not config.get(key)]
    if missing:
        raise RuntimeError(f"Configuração de origem incompleta. Campos ausentes: {', '.join(missing)}")


def _parse_major(version_text: str) -> int:
    match = re.search(r"(\d+)", version_text)
    if not match:
        raise RuntimeError(f"Não foi possível extrair a major version de: {version_text}")
    return int(match.group(1))


def _get_server_version(pg_config: dict[str, object]) -> tuple[int, str]:
    with psycopg.connect(**pg_config) as conn:
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

    if os.name == "nt":
        for ext in (".exe", ".bat", ".cmd"):
            which_path_ext = shutil.which(f"{cli_name}{ext}")
            if which_path_ext:
                resolved = str(Path(which_path_ext).resolve())
                if resolved not in seen:
                    candidates.append(Path(resolved))
                    seen.add(resolved)

    for bin_dir in COMMON_PG_BIN_DIRS:
        for suffix in ("", ".exe"):
            candidate = bin_dir / f"{cli_name}{suffix}"
            if candidate.exists():
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
    return _parse_major(proc.stdout.strip() or proc.stderr.strip())


def _resolve_cli(cli_name: str, *, min_major: int | None = None, env_var: str | None = None) -> Path:
    override = _env_or_default(env_var or "")
    if override:
        cli_path = Path(override).expanduser().resolve()
        if not cli_path.exists():
            raise RuntimeError(f"{env_var} aponta para caminho inexistente: {cli_path}")
        cli_major = _get_cli_major(cli_path)
        if min_major is not None and cli_major < min_major:
            raise RuntimeError(
                f"{env_var}={cli_path} está na major {cli_major}, mas a origem requer ao menos {min_major}"
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
        raise RuntimeError(f"Nenhum binário encontrado para {cli_name}")

    candidates.sort(key=lambda item: (item[0], str(item[1])), reverse=True)
    if min_major is None:
        return candidates[0][1]

    for cli_major, cli_path in candidates:
        if cli_major >= min_major:
            return cli_path

    installed = ", ".join(f"{path} (v{major})" for major, path in candidates)
    raise RuntimeError(
        f"Nenhum {cli_name} compatível encontrado. Origem exige major >= {min_major}. Instalados: {installed}"
    )


def _cmd_env(pg_config: dict[str, object]) -> dict[str, str]:
    env = os.environ.copy()
    env["PGPASSWORD"] = str(pg_config["password"])
    if pg_config.get("sslmode"):
        env["PGSSLMODE"] = str(pg_config["sslmode"])
    return env


def _run_cmd(args: list[str], *, env: dict[str, str], label: str) -> None:
    print(f"{label}: {' '.join(args)}")
    subprocess.run(args, env=env, check=True)


def _list_user_schemas(pg_config: dict[str, object]) -> list[str]:
    with psycopg.connect(**pg_config) as conn:
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


def _resolve_schemas(pg_config: dict[str, object], include_schemas: list[str], exclude_schemas: list[str]) -> list[str]:
    available = _list_user_schemas(pg_config)
    if include_schemas:
        selected = [schema for schema in available if schema in set(include_schemas)]
    else:
        selected = available
    excluded = set(exclude_schemas)
    selected = [schema for schema in selected if schema not in excluded]
    if not selected:
        raise RuntimeError("Nenhum schema elegível encontrado para o backup.")
    return selected


def _build_output_path(args: argparse.Namespace, dbname: str) -> Path:
    output_file = str(args.output_file or "").strip()
    if output_file:
        path = Path(output_file).expanduser().resolve()
        path.parent.mkdir(parents=True, exist_ok=True)
        return path

    output_dir = Path(str(args.output_dir or "").strip() or ".").expanduser().resolve()
    output_dir.mkdir(parents=True, exist_ok=True)
    stamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    safe_dbname = re.sub(r"[^A-Za-z0-9_.-]+", "_", str(dbname or "database"))
    prefix = re.sub(r"[^A-Za-z0-9_.-]+", "_", str(args.prefix or "postgres_backup"))
    return output_dir / f"{prefix}_{safe_dbname}_{stamp}.dump"


def _dump_source(archive_path: Path, pg_dump_bin: Path, pg_config: dict[str, object], schemas: list[str]) -> None:
    args = [
        str(pg_dump_bin),
        "-h", str(pg_config["host"]),
        "-p", str(pg_config["port"]),
        "-U", str(pg_config["user"]),
        "-d", str(pg_config["dbname"]),
        "-Fc",
        "--no-owner",
        "--no-privileges",
    ]
    for schema in schemas:
        args.extend(["--schema", schema])
    args.extend(["-f", str(archive_path)])
    _run_cmd(args, env=_cmd_env(pg_config), label="pg_dump origem")


def main() -> None:
    args = _parse_args()
    pg_config = _build_pg_config(args)
    _validate_pg_config(pg_config)

    remote_major, remote_version = _get_server_version(pg_config)
    pg_dump_bin = _resolve_cli("pg_dump", min_major=remote_major, env_var="PG_DUMP_BIN")
    schemas = _resolve_schemas(
        pg_config,
        include_schemas=[str(item).strip() for item in args.include_schema if str(item).strip()],
        exclude_schemas=[str(item).strip() for item in args.exclude_schema if str(item).strip()],
    )
    archive_path = _build_output_path(args, str(pg_config["dbname"]))

    print(f"Servidor origem: {remote_version}")
    print(f"Cliente pg_dump: {pg_dump_bin}")
    print(f"Schemas do backup: {', '.join(schemas)}")
    print(f"Arquivo de saída: {archive_path}")

    _dump_source(archive_path, pg_dump_bin, pg_config, schemas)

    print("")
    print("Backup concluído com sucesso.")
    print(f"Arquivo salvo em: {archive_path}")


if __name__ == "__main__":
    main()
