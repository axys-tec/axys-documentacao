#!/usr/bin/env python3
"""
Loader FDE — importa as edições HISTÓRICAS (pacotes `dist`) DIRETO no banco (chama o parser_fde
numa transação) + gate de conferência. O histórico da FDE é **só-script** (sem rota in-app); a
edição vigente (n = 04/2026) entra pela rota em PROD.

⚠️ Os `dist` foram STAGED pelo Codex (não são saída crua do pipeline real PDF+curl). Por isso o
**gate é a garantia de fidelidade**: a conferência des-BDInizada (`trunc2(base×(1+BDI)) == fonte`)
tem que fechar; se o staging tiver artefato, marca DIVERGENTE_RELEVANTE e o loader para.

Uso:
    python carregar_edicoes_fde.py                 # todas as históricas com dist, gate tol R$1
    python carregar_edicoes_fde.py --start 2024-10 --end 2025-01
    python carregar_edicoes_fde.py --dry-run
"""
from __future__ import annotations

import argparse
import sys
from pathlib import Path

import psycopg2

sys.path.insert(0, str(Path(__file__).resolve().parents[5]))          # repo root p/ importar backend.*
sys.path.insert(0, str(Path(__file__).resolve().parent))              # p/ restaurar_local
from restaurar_local import PG_CONFIG_LOCAL
from backend.core.import_cpu.base import ImportConfig
from backend.core.import_cpu import parser_fde as P
from backend.core.import_cpu import parser_cdhu   # snapshot_insumos / edicao_anterior / aplicar_diff_edicao

DIST = Path(__file__).resolve().parents[5] / "z_search_repos/find_fde/boletins/dist/_build"
OPERADOR = "seed inicial"   # rótulo-alvo do audit (evita rotação depois)


def _fte_fde(conn) -> int:
    cur = conn.cursor()
    cur.execute("SELECT fte_id FROM catalogo.fontes WHERE fte_codigo='FDE'")
    return cur.fetchone()[0]


def edicoes_alvo(conn, start, end):
    cur = conn.cursor()
    cur.execute("""
        SELECT to_char(e.edi_mes_ref,'YYYY-MM'), e.edi_id, e.edi_situacao_ciclo
        FROM catalogo.edicoes e JOIN catalogo.fontes f ON f.fte_id=e.edi_fte_id
        WHERE f.fte_codigo='FDE' ORDER BY e.edi_mes_ref
    """)
    out = []
    for ym, edi_id, ciclo in cur.fetchall():
        if (start and ym < start) or (end and ym > end):
            continue
        csv_dir = DIST / ym.replace("-", "_") / "csv"
        out.append({"ym": ym, "edi_id": edi_id, "ciclo": ciclo, "csv": csv_dir})
    return out


def importar(conn, edi_id, fte_id, csv_dir):
    cfg = ImportConfig(edi_id=edi_id, fte_id=fte_id, operador=OPERADOR)
    snap = parser_cdhu.snapshot_insumos(cfg, conn)
    prior = parser_cdhu.edicao_anterior(cfg, conn)
    res = []
    res.append(("insumos",     P.parse_insumos(csv_dir, cfg, conn)))
    res.append(("composições", P.parse_composicoes(csv_dir, cfg, conn)))
    res.append(("custo fonte",  P.parse_custos_fonte(csv_dir, cfg, conn)))
    res.append(("bdi",         P.parse_bdi(csv_dir, cfg, conn)))
    res.append(("ls",          P.parse_ls(csv_dir, cfg, conn)))
    res.append(("conferência", P.calcular_custos(cfg, conn)))
    res.append(("diff",        parser_cdhu.aplicar_diff_edicao(cfg, conn, prior, snap)))
    conn.commit()
    return res


# tipo de doc por chave do manifest.originais_alvo
_TIPO_DOC = {
    "sintetica_pdf": "referencia_sintetica", "analitica_pdf": "referencia_analitica",
    "insumos_xlsx": "insumos", "ls_pdf": "leis_sociais", "bdi_pdf": "bdi", "honor_pdf": "honorarios",
}


def subir_r2_fde(conn, edi_id, fte_id, dist_dir: Path) -> int:
    """Passo-extra da FDE: sobe os `originais/` pro storage público (R2 em prod / local em dev,
    via STORAGE_DRIVER) sob {fonte}/{edicao}/originais/, e registra em catalogo.documentos
    (edição-level). Idempotente (mesma key sobrescreve; upsert por doc_path). Commita."""
    import json, mimetypes
    from backend.modules.catalogo import storage_paths as sp
    from backend.storage import get_storage

    store = get_storage()
    cur = conn.cursor()
    manifest = json.loads((dist_dir.parent / "manifest.json").read_text(encoding="utf-8"))
    edicao = manifest["edicao"]
    orig_dir = dist_dir.parent / "originais"
    alvo = manifest.get("originais_alvo", {}) or {}

    itens: list[tuple[str, str]] = []   # (tipo_doc, nome_arquivo)
    for chave, val in alvo.items():
        if not val:
            continue
        tipo = _TIPO_DOC.get(chave, chave)
        if isinstance(val, list):
            for it in val:
                nome = Path(it["arquivo"] if isinstance(it, dict) else it).name
                itens.append((tipo, nome))
        else:
            itens.append((tipo, Path(val).name))

    n = 0
    for tipo, nome in itens:
        f = orig_dir / nome
        if not f.exists():
            cand = next((p for p in orig_dir.iterdir() if p.name == nome), None)
            if cand is None:
                continue
            f = cand
        key = sp.originais("fde", edicao, nome)
        mime = mimetypes.guess_type(nome)[0] or "application/octet-stream"
        with open(f, "rb") as fh:
            store.save_public_file(key, fh, mime)
        url = store.get_public_url(key)
        cur.execute(
            """
            INSERT INTO catalogo.documentos
                (doc_fte_id, doc_tipo, doc_edi_id, doc_path, doc_url, doc_titulo, doc_mime, doc_vigente)
            VALUES (%s, %s, %s, %s, %s, %s, %s, true)
            ON CONFLICT (doc_path) DO UPDATE SET
                doc_url=EXCLUDED.doc_url, doc_titulo=EXCLUDED.doc_titulo,
                doc_mime=EXCLUDED.doc_mime, doc_vigente=true
            """,
            (fte_id, tipo, edi_id, key, url, nome, mime),
        )
        n += 1
    conn.commit()
    return n


def conferencia(conn, edi_id, tol):
    cur = conn.cursor()
    cur.execute("""
        SELECT cc.cc_modalidade, cc.cc_status_conferencia, count(*)
        FROM catalogo.composicoes_custo cc JOIN catalogo.composicoes c ON c.cmp_id=cc.cc_cmp_id
        WHERE c.cmp_edi_id=%s GROUP BY 1,2 ORDER BY 1,2
    """, (edi_id,))
    breakdown = cur.fetchall()
    cur.execute("""
        SELECT DISTINCT ON (cc.cc_modalidade) cc.cc_modalidade, cc.cc_uf, c.cmp_codigo,
               cc.cc_custo_fonte, cc.cc_custo_calculado,
               abs(coalesce(cc.cc_diferenca_valor,0)) dif
        FROM catalogo.composicoes_custo cc JOIN catalogo.composicoes c ON c.cmp_id=cc.cc_cmp_id
        WHERE c.cmp_edi_id=%s AND cc.cc_status_conferencia LIKE 'DIVERGENTE%%'
        ORDER BY cc.cc_modalidade, dif DESC
    """, (edi_id,))
    maior = cur.fetchall()
    cur.execute("""
        SELECT cc.cc_modalidade, cc.cc_uf, c.cmp_codigo, cc.cc_custo_fonte, cc.cc_custo_calculado,
               abs(coalesce(cc.cc_diferenca_valor,0)) dif
        FROM catalogo.composicoes_custo cc JOIN catalogo.composicoes c ON c.cmp_id=cc.cc_cmp_id
        WHERE c.cmp_edi_id=%s AND cc.cc_status_conferencia='DIVERGENTE_RELEVANTE'
          AND abs(coalesce(cc.cc_diferenca_valor,0)) >= %s
        ORDER BY dif DESC LIMIT 30
    """, (edi_id, tol))
    return {"breakdown": breakdown, "maior": maior, "ofensores": cur.fetchall()}


def main():
    ap = argparse.ArgumentParser(description="Loader FDE (histórico, direto no banco + gate).")
    ap.add_argument("--start", default=None, help="mês-base YYYY-MM")
    ap.add_argument("--end", default=None, help="mês-fim YYYY-MM")
    ap.add_argument("--tol", type=float, default=1.00, help="tolerância R$ p/ DIVERGENTE_RELEVANTE")
    ap.add_argument("--skip-on-fail", action="store_true")
    ap.add_argument("--r2", action="store_true", help="após o gate, sobe os originais/ pro storage (STORAGE_DRIVER) + documentos")
    ap.add_argument("--dry-run", action="store_true")
    args = ap.parse_args()

    conn = psycopg2.connect(**PG_CONFIG_LOCAL)
    fte_id = _fte_fde(conn)
    eds = edicoes_alvo(conn, args.start, args.end)
    if not eds:
        print("Nenhuma edição FDE no intervalo."); return 1
    print(f"Edições FDE alvo: {', '.join(e['ym'] for e in eds)}  (tol=R${args.tol:.2f})\n")

    reprovados, sem_dist = [], []
    for e in eds:
        tag = f"[FDE {e['ym']} · edi {e['edi_id']} · {e['ciclo']}]"
        if not e["csv"].is_dir():
            print(f"{tag} ⏭ sem dist ({e['csv'].parent.name}) — PULANDO (é a vigente/prod?).\n")
            sem_dist.append(e["ym"]); continue
        if args.dry_run:
            print(f"{tag} OK → dist {e['csv'].parent.name}"); continue
        try:
            print(f"{tag} importando…")
            res = importar(conn, e["edi_id"], fte_id, e["csv"])
            resumo = " · ".join(f"{n}:+{r.inseridos}/~{r.atualizados}" for n, r in res)
            print(f"{tag} {resumo}")
            cf = conferencia(conn, e["edi_id"], args.tol)
            for mod, st, n in cf["breakdown"]:
                print(f"      {mod} {str(st):<26} {n}")
            if cf["maior"]:
                for mod, uf, cod, fonte, calc, dif in cf["maior"]:
                    print(f"      {mod} MAIOR_DIVERGENCIA=R${dif}  cmp {cod}")
            if cf["ofensores"]:
                raise RuntimeError(f"{len(cf['ofensores'])}+ DIVERGENTE_RELEVANTE ≥ R${args.tol:.2f} (top {cf['ofensores'][0][2]} Δ={cf['ofensores'][0][5]})")
            if args.r2:
                nd = subir_r2_fde(conn, e["edi_id"], fte_id, e["csv"])
                print(f"      R2: {nd} originais subidos ({e['csv'].parent.name}/originais/) + registrados em documentos")
            print(f"{tag} ✓ passou\n")
        except Exception as ex:
            conn.rollback()
            if not args.skip_on_fail:
                print(f"{tag} ✗ {ex} — PARANDO."); conn.close(); return 1
            print(f"{tag} ⏭ PULANDO por falha: {ex}\n"); reprovados.append((e["ym"], str(ex)[:80]))

    conn.close()
    print("── resumo ──")
    if sem_dist: print(f"⏭ SEM DIST (vigente/prod): {', '.join(sem_dist)}")
    if reprovados:
        print("✗ REPROVADOS:")
        for ym, m in reprovados: print(f"    {ym}: {m}")
    else:
        print("✅ Todas as edições FDE com dist passaram (import + gate).")
    return 0 if not reprovados else 2


if __name__ == "__main__":
    sys.exit(main())
