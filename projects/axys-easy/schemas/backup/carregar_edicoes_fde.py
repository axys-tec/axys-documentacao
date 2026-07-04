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
