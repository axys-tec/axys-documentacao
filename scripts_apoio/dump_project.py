from __future__ import annotations

import os
import hashlib
from pathlib import Path
from datetime import datetime

# =========================
# Config
# =========================

OUTPUT_TREE = "all_project_tree.txt"
OUTPUT_PY = "all_project_py.txt"
OUTPUT_MD = "all_project_md.txt"
OUTPUT_HTML = "all_project_html.txt"
OUTPUT_JS = "all_project_js.txt"
OUTPUT_CSS = "all_project_css.txt"
OUTPUT_DIV = "all_project_div.txt"
OUTPUT_SQL = "all_project_sql.txt"

OUTPUT_FILES = {
    OUTPUT_TREE,
    OUTPUT_PY,
    OUTPUT_MD,
    OUTPUT_HTML,
    OUTPUT_JS,
    OUTPUT_CSS,
    OUTPUT_SQL,
    OUTPUT_DIV,
}

# Pastas/padrões que normalmente não vale varrer
DEFAULT_IGNORE_DIRS = {
    ".git",
    ".venv",
    "venv",
    "__pycache__",
    ".pytest_cache",
    ".mypy_cache",
    ".ruff_cache",
    ".idea",
    ".vscode",
    "node_modules",
    "dist",
    "build",
    ".next",
    ".cache",
    ".DS_Store",
}

# Arquivos grandes/binaries a evitar
BINARY_EXTS = {
    ".png", ".jpg", ".jpeg", ".gif", ".webp", ".svg",
    ".pdf",
    ".zip", ".rar", ".7z", ".tar", ".gz", ".bz2",
    ".exe", ".dll", ".so", ".dylib",
    ".mp4", ".mov", ".avi", ".mkv", ".mp3", ".wav",
    ".ttf", ".otf", ".woff", ".woff2",
    ".ico",
}

# Extensões que vamos concatenar em texto "div" (se forem texto)
# Obs: .py e .md vão para seus próprios dumps.
TEXT_LIKE_EXTS = {
    ".txt", ".ini", ".cfg", ".conf", ".toml", ".yaml", ".yml", ".json",
    ".csv", ".tsv", ".xml", ".html", ".css", ".js", ".ts",
    ".sql", ".bat", ".ps1", ".sh", ".env", ".example",
    ".dockerfile", ".make", ".mk",
}

MAX_FILE_SIZE_MB = 20  # proteção: evita travar em arquivos enormes

# =========================
# Helpers
# =========================

def is_probably_binary(path: Path) -> bool:
    ext = path.suffix.lower()
    if ext in BINARY_EXTS:
        return True
    # Heurística: checa bytes nulos nos primeiros bytes
    try:
        with path.open("rb") as f:
            chunk = f.read(4096)
        return b"\x00" in chunk
    except Exception:
        # se não deu pra ler, trate como binário/ignorado
        return True

def safe_read_text(path: Path) -> str | None:
    # Tenta UTF-8, depois fallback Latin-1 (pra não quebrar em arquivo BR antigo)
    try:
        return path.read_text(encoding="utf-8")
    except UnicodeDecodeError:
        try:
            return path.read_text(encoding="latin-1")
        except Exception:
            return None
    except Exception:
        return None

def write_header(out, title: str) -> None:
    out.write(f"{'=' * 80}\n")
    out.write(f"{title}\n")
    out.write(f"Gerado em: {datetime.now().isoformat(timespec='seconds')}\n")
    out.write(f"{'=' * 80}\n\n")

def file_size_mb(path: Path) -> float:
    try:
        return path.stat().st_size / (1024 * 1024)
    except Exception:
        return 0.0

# =========================
# Tree builder
# =========================

def build_tree_lines(root: Path, ignore_dirs: set[str]) -> list[str]:
    """
    Gera uma árvore textual com indentação, estilo 'tree', sem depender de comando externo.
    """
    lines: list[str] = []
    root_name = root.name or str(root)
    lines.append(f"{root_name}/")

    def walk(dir_path: Path, prefix: str = ""):
        try:
            entries = sorted(dir_path.iterdir(), key=lambda x: (not x.is_dir(), x.name.lower()))
        except Exception:
            return

        # filtra ignorados
        entries = [
            e for e in entries
            if not (e.is_dir() and e.name in ignore_dirs)
            and e.name not in OUTPUT_FILES
        ]

        for i, entry in enumerate(entries):
            is_last = (i == len(entries) - 1)
            branch = "└── " if is_last else "├── "
            next_prefix = prefix + ("    " if is_last else "│   ")

            if entry.is_dir():
                lines.append(f"{prefix}{branch}{entry.name}/")
                walk(entry, next_prefix)
            else:
                lines.append(f"{prefix}{branch}{entry.name}")

    walk(root)
    return lines

# =========================
# Dump helper
# =========================

def dump_text_group(root: Path, out_name: str, title: str, files: list[Path]) -> None:
    with (root / out_name).open("w", encoding="utf-8") as out:
        write_header(out, title)

        for p in files:
            full_path = str(p.resolve())
            out.write(f"\n\n# FILE: {full_path}\n")
            out.write("#" + "-" * 79 + "\n")

            size_mb = file_size_mb(p)
            if size_mb > MAX_FILE_SIZE_MB:
                out.write(f"[SKIPPED: arquivo muito grande ({size_mb:.2f} MB) > {MAX_FILE_SIZE_MB} MB]\n")
                continue

            txt = safe_read_text(p)
            if txt is None:
                out.write("[SKIPPED: não foi possível ler como texto]\n")
                continue

            out.write(txt)
            if not txt.endswith("\n"):
                out.write("\n")

# =========================
# Main dump
# =========================

def dump_project(root: Path) -> None:
    ignore_dirs = set(DEFAULT_IGNORE_DIRS)

    # Coleta arquivos
    py_files: list[Path] = []
    md_files: list[Path] = []
    html_files: list[Path] = []
    js_files: list[Path] = []
    css_files: list[Path] = []
    sql_files: list[Path] = []
    div_files: list[Path] = []

    for dirpath, dirnames, filenames in os.walk(root):
        d = Path(dirpath)

        # remove ignorados do walk (in-place)
        dirnames[:] = [dn for dn in dirnames if dn not in ignore_dirs]

        for fn in filenames:
            p = d / fn

            # não reprocessa os outputs
            if p.name in OUTPUT_FILES:
                continue

            ext = p.suffix.lower()

            if ext == ".py":
                py_files.append(p)
            elif ext == ".md":
                md_files.append(p)
            elif ext == ".html":
                html_files.append(p)
            elif ext == ".js":
                js_files.append(p)
            elif ext == ".css":
                css_files.append(p)
            elif ext == ".sql":
                sql_files.append(p)
            else:
                div_files.append(p)

    # ordena
    py_files.sort(key=lambda x: x.as_posix().lower())
    md_files.sort(key=lambda x: x.as_posix().lower())
    html_files.sort(key=lambda x: x.as_posix().lower())
    js_files.sort(key=lambda x: x.as_posix().lower())
    css_files.sort(key=lambda x: x.as_posix().lower())
    sql_files.sort(key=lambda x: x.as_posix().lower())
    div_files.sort(key=lambda x: x.as_posix().lower())

    # 1) TREE
    tree_lines = build_tree_lines(root, ignore_dirs)
    with (root / OUTPUT_TREE).open("w", encoding="utf-8") as out:
        write_header(out, "ALL PROJECT TREE")
        out.write("\n".join(tree_lines))
        out.write("\n")

    # 2) PY / MD / HTML / JS / CSS / SQL
    dump_text_group(root, OUTPUT_PY, "ALL PROJECT PY FILES", py_files)
    dump_text_group(root, OUTPUT_MD, "ALL PROJECT MD FILES", md_files)
    dump_text_group(root, OUTPUT_HTML, "ALL PROJECT HTML FILES", html_files)
    dump_text_group(root, OUTPUT_JS, "ALL PROJECT JS FILES", js_files)
    dump_text_group(root, OUTPUT_CSS, "ALL PROJECT CSS FILES", css_files)
    dump_text_group(root, OUTPUT_SQL, "ALL PROJECT SQL FILES", sql_files)

    # 3) DIV (outros arquivos texto-like)
    with (root / OUTPUT_DIV).open("w", encoding="utf-8") as out:
        write_header(out, "ALL PROJECT OTHER FILES (TEXT-LIKE)")

        for p in div_files:
            ext = p.suffix.lower()
            full_path = str(p.resolve())

            size_mb = file_size_mb(p)
            if size_mb > MAX_FILE_SIZE_MB:
                out.write(f"\n\n# FILE: {full_path}\n")
                out.write("#" + "-" * 79 + "\n")
                out.write(f"[SKIPPED: arquivo muito grande ({size_mb:.2f} MB) > {MAX_FILE_SIZE_MB} MB]\n")
                continue

            # pula binários
            if is_probably_binary(p):
                continue

            # tenta ler como texto
            txt = safe_read_text(p)
            if txt is None:
                continue

            # heurística simples pra evitar lixo
            printable = sum(ch.isprintable() for ch in txt)
            if len(txt) > 0 and (printable / max(len(txt), 1)) < 0.85:
                continue

            out.write(f"\n\n# FILE: {full_path}\n")
            out.write("#" + "-" * 79 + "\n")
            out.write(txt)
            if not txt.endswith("\n"):
                out.write("\n")

    print("OK! Gerados:")
    print(f" - {OUTPUT_TREE}")
    print(f" - {OUTPUT_PY}")
    print(f" - {OUTPUT_MD}")
    print(f" - {OUTPUT_HTML}")
    print(f" - {OUTPUT_JS}")
    print(f" - {OUTPUT_CSS}")
    print(f" - {OUTPUT_SQL}")
    print(f" - {OUTPUT_DIV}")

def main() -> int:
    root = Path.cwd()
    dump_project(root)
    return 0

if __name__ == "__main__":
    raise SystemExit(main())
