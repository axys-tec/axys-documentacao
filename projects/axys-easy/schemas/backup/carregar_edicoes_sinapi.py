#!/usr/bin/env python3
"""
Loader automático de edições SINAPI CONTRA A APP NO AR (valida o pipeline real).

Para cada edição a partir de um mês-base, em ordem cronológica:
  1. resolve o edi_id (edição SINAPI RASCUNHO/EM_REVISAO no banco) e os 4 Excel da pasta da fonte;
  2. faz upload + enfileira o import via POST /api/import/sinapi (docs pulados: disp=0);
  3. espera o worker terminar (poll GET /api/import/{job_id} até 'concluido'|'erro');
  4. roda o GATE DE CONFERÊNCIA: conta cc_status_conferencia por modalidade (SD/CD/SE) e
     reprova se houver DIVERGENTE_RELEVANTE com |calc−fonte| ≥ --tol (default R$ 1,00);
  5. se passar e --publish (default), publica a edição; senão PARA e mostra os ofensores.

Pré-requisitos: app + worker no ar (run_dev.sh, :8788) com EASY_AUTH_BYPASS=true (admin dev),
banco recriado (edições seedadas RASCUNHO). Reusa PG_CONFIG_LOCAL (não hardcoda senha).

Uso:
    python carregar_edicoes_sinapi.py                       # 2024-08 → fim, publica, tol R$1
    python carregar_edicoes_sinapi.py --start 2024-08 --end 2024-11
    python carregar_edicoes_sinapi.py --tol 0.50 --no-publish
    python carregar_edicoes_sinapi.py --dry-run             # só lista edições+arquivos
"""
from __future__ import annotations

import argparse
import sys
import time
import unicodedata
from pathlib import Path

import httpx
import psycopg

sys.path.insert(0, str(Path(__file__).resolve().parent))
from restaurar_local import PG_CONFIG_LOCAL   # reusa a config local (sem hardcode de senha)

BASE_DEFAULT = "http://127.0.0.1:8788"
FONTE_ROOT = Path(__file__).resolve().parents[5] / "z_search_repos/fontes-base/sinapi/SINAPI"
XLSX = "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
STAGE_FINAL = {"concluido", "erro"}


def _norm(s: str) -> str:
    return "".join(c for c in unicodedata.normalize("NFKD", s) if not unicodedata.combining(c)).lower()


def resolve_arquivos(y: int, m: int) -> dict | None:
    """Acha a pasta da edição (SINAPI_YYYY_MM_formato_xlsx ou SINAPI-YYYY-MM-formato-xlsx) e
    casa os 4 Excel por palavra-chave (tolerante a acento/maiúsculas e a mao_de_obra/mao_obra)."""
    ym_u, ym_d = f"{y}_{m:02d}", f"{y}-{m:02d}"
    pasta = next((d for d in FONTE_ROOT.iterdir()
                  if d.is_dir() and (ym_u in d.name or ym_d in d.name)), None)
    if not pasta:
        return None
    xlsx = [p for p in pasta.iterdir() if p.suffix.lower() == ".xlsx" and not p.name.startswith("~$")]
    def achar(*chaves):
        for p in xlsx:
            n = _norm(p.name)
            if all(k in n for k in chaves):
                return p
        return None
    arqs = {
        "referencia":  achar("refer"),
        "mao_obra":    achar("mao", "obra"),
        "manutencoes": achar("manuten"),
        "familias":    achar("familias"),
    }
    if not all(arqs.values()):
        faltando = [k for k, v in arqs.items() if not v]
        print(f"    ⚠ arquivos faltando em {pasta.name}: {faltando}")
        return None
    return arqs


def edicoes_alvo(conn, start_ym: str, end_ym: str | None) -> list[dict]:
    cur = conn.cursor()
    cur.execute("""
        SELECT e.edi_id, to_char(e.edi_mes_ref,'YYYY-MM') AS ym,
               EXTRACT(YEAR FROM e.edi_mes_ref)::int, EXTRACT(MONTH FROM e.edi_mes_ref)::int,
               e.edi_codigo_versao, e.edi_situacao_ciclo
        FROM catalogo.edicoes e JOIN catalogo.fontes f ON f.fte_id = e.edi_fte_id
        WHERE f.fte_codigo = 'SINAPI'
          AND to_char(e.edi_mes_ref,'YYYY-MM') >= %s
          AND (%s::text IS NULL OR to_char(e.edi_mes_ref,'YYYY-MM') <= %s::text)
        ORDER BY e.edi_mes_ref
    """, (start_ym, end_ym, end_ym))
    return [{"edi_id": r[0], "ym": r[1], "y": r[2], "m": r[3], "versao": r[4], "ciclo": r[5]}
            for r in cur.fetchall()]


def enfileirar_import(base: str, edi_id: int, arqs: dict) -> str:
    data = {"edi_id": str(edi_id),
            "disp_metodologia": "0", "disp_calculos": "0", "disp_notas": "0", "disp_caderno_ls": "0"}
    fhs = {k: open(p, "rb") for k, p in arqs.items()}
    try:
        files = {k: (Path(arqs[k]).name, fh, XLSX) for k, fh in fhs.items()}
        r = httpx.post(f"{base}/api/import/sinapi", data=data, files=files, timeout=600)
    finally:
        for fh in fhs.values():
            fh.close()
    if r.status_code != 200:
        raise RuntimeError(f"POST import falhou [{r.status_code}]: {r.text[:300]}")
    j = r.json()
    if not j.get("success"):
        raise RuntimeError(f"import recusado: {j.get('message')}")
    return j["job_id"]


def esperar_job(base: str, job_id: str, timeout_s: int = 1800) -> dict:
    t0 = time.time()
    ultimo = ""
    while time.time() - t0 < timeout_s:
        r = httpx.get(f"{base}/api/import/{job_id}", timeout=30)
        j = r.json()
        st = j.get("status")
        etapa = next((s for s in reversed(j.get("stages", [])) if s.get("status") == "rodando"), None)
        marca = f"{st}:{etapa['nome']}·{etapa.get('detalhe','')}" if etapa else str(st)
        if marca != ultimo:
            print(f"    … {marca}")
            ultimo = marca
        if st in STAGE_FINAL:
            return j
        time.sleep(3)
    raise TimeoutError(f"job {job_id} não terminou em {timeout_s}s")


def conferencia(conn, edi_id: int, tol: float) -> dict:
    cur = conn.cursor()
    cur.execute("""
        SELECT cc.cc_modalidade, cc.cc_status_conferencia, count(*)
        FROM catalogo.composicoes_custo cc JOIN catalogo.composicoes c ON c.cmp_id = cc.cc_cmp_id
        WHERE c.cmp_edi_id = %s GROUP BY 1,2 ORDER BY 1,2
    """, (edi_id,))
    breakdown = cur.fetchall()
    # MAIOR divergência por modalidade (entre TODAS as divergentes: relevante+arredondamento).
    # % = dif/fonte*100 (o cc_diferenca_percentual do SINAPI vem 0 → calculo aqui, do ABS).
    cur.execute("""
        SELECT DISTINCT ON (cc.cc_modalidade)
               cc.cc_modalidade, cc.cc_uf, c.cmp_codigo,
               cc.cc_custo_fonte, cc.cc_custo_calculado,
               abs(coalesce(cc.cc_custo_calculado,0) - coalesce(cc.cc_custo_fonte,0)) AS dif
        FROM catalogo.composicoes_custo cc JOIN catalogo.composicoes c ON c.cmp_id = cc.cc_cmp_id
        WHERE c.cmp_edi_id = %s AND cc.cc_status_conferencia LIKE 'DIVERGENTE%%'
        ORDER BY cc.cc_modalidade, dif DESC
    """, (edi_id,))
    maior = cur.fetchall()
    # ofensores: DIVERGENTE_RELEVANTE com |calc−fonte| ≥ tol (% do SINAPI é 0 → uso o ABS)
    cur.execute("""
        SELECT cc.cc_modalidade, cc.cc_uf, c.cmp_codigo,
               cc.cc_custo_fonte, cc.cc_custo_calculado,
               abs(coalesce(cc.cc_custo_calculado,0) - coalesce(cc.cc_custo_fonte,0)) AS dif
        FROM catalogo.composicoes_custo cc JOIN catalogo.composicoes c ON c.cmp_id = cc.cc_cmp_id
        WHERE c.cmp_edi_id = %s AND cc.cc_status_conferencia = 'DIVERGENTE_RELEVANTE'
          AND abs(coalesce(cc.cc_custo_calculado,0) - coalesce(cc.cc_custo_fonte,0)) >= %s
        ORDER BY dif DESC LIMIT 30
    """, (edi_id, tol))
    ofensores = cur.fetchall()
    return {"breakdown": breakdown, "maior": maior, "ofensores": ofensores}


def esperar_publicada(edi_id: int, timeout_s: int = 120) -> str:
    """Confirma a transição para PUBLICADA no banco (publicar_edicao é síncrono; isto é a
    prova). Devolve o ciclo final. Não espera a montagem async do caderno (irrelevante ao dado)."""
    t0 = time.time()
    while time.time() - t0 < timeout_s:
        with psycopg.connect(**PG_CONFIG_LOCAL) as c:
            cur = c.cursor()
            cur.execute("SELECT edi_situacao_ciclo FROM catalogo.edicoes WHERE edi_id=%s", (edi_id,))
            ciclo = cur.fetchone()[0]
        if ciclo == "PUBLICADA":
            return ciclo
        time.sleep(1)
    return ciclo


def publicar(base: str, edi_id: int) -> tuple[bool, str]:
    r = httpx.post(f"{base}/api/edicoes/{edi_id}/publicar", timeout=300)
    try:
        j = r.json()
    except Exception:
        return (r.status_code == 200, r.text[:200])
    return (bool(j.get("success", r.status_code == 200)), j.get("message", ""))


def main():
    ap = argparse.ArgumentParser(description="Carga automática de edições SINAPI contra a app no ar.")
    ap.add_argument("--start", default="2024-08", help="mês-base YYYY-MM (default 2024-08)")
    ap.add_argument("--end", default=None, help="mês-fim YYYY-MM (opcional)")
    ap.add_argument("--base", default=BASE_DEFAULT, help=f"URL da app (default {BASE_DEFAULT})")
    ap.add_argument("--tol", type=float, default=1.00, help="tolerância R$ p/ DIVERGENTE_RELEVANTE (default 1.00)")
    ap.add_argument("--no-publish", action="store_true", help="não publica ao passar")
    ap.add_argument("--dry-run", action="store_true", help="só lista edições e arquivos")
    args = ap.parse_args()

    with psycopg.connect(**PG_CONFIG_LOCAL) as conn:
        eds = edicoes_alvo(conn, args.start, args.end)
    if not eds:
        print("Nenhuma edição SINAPI no intervalo."); return 1
    print(f"Edições alvo: {', '.join(e['ym'] for e in eds)}  (base={args.base}, tol=R${args.tol:.2f}, "
          f"publish={not args.no_publish})\n")

    for e in eds:
        arqs = resolve_arquivos(e["y"], e["m"])
        tag = f"[{e['ym']} · edi {e['edi_id']} · {e['ciclo']}]"
        if not arqs:
            print(f"{tag} ✗ arquivos não resolvidos — PARANDO."); return 1
        if args.dry_run:
            print(f"{tag} OK → " + " · ".join(f"{k}={Path(v).name}" for k, v in arqs.items()))
            continue
        if e["ciclo"] not in ("RASCUNHO", "EM_REVISAO"):
            print(f"{tag} já {e['ciclo']} — pulando import (só confere).")
        else:
            print(f"{tag} importando…")
            try:
                job = enfileirar_import(args.base, e["edi_id"], arqs)
                res = esperar_job(args.base, job)
            except Exception as ex:
                print(f"{tag} ✗ ERRO no import: {ex} — PARANDO."); return 1
            if res.get("status") != "concluido":
                print(f"{tag} ✗ import terminou em '{res.get('status')}': {res.get('erro')} — PARANDO."); return 1
            print(f"{tag} import concluído.")

        # ── gate de conferência ──
        with psycopg.connect(**PG_CONFIG_LOCAL) as conn:
            cf = conferencia(conn, e["edi_id"], args.tol)
        print(f"{tag} conferência (por modalidade × status):")
        for mod, st, n in cf["breakdown"]:
            print(f"      {mod} {st:<26} {n}")
        if cf["maior"]:
            print(f"{tag} maior divergência por modalidade:")
            for mod, uf, cod, fonte, calc, dif in cf["maior"]:
                pct = (float(dif) / float(fonte) * 100) if fonte and float(fonte) != 0 else None
                pcts = f"{pct:.2f}%" if pct is not None else "—%"
                print(f"      {mod} MAIOR_DIVERGENCIA=R${dif} ({pcts})  cmp {cod}/{uf} (fonte={fonte} calc={calc})")
        else:
            print(f"{tag} maior divergência: — (nenhuma divergência em nenhuma modalidade)")
        if cf["ofensores"]:
            print(f"{tag} ✗ {len(cf['ofensores'])}+ DIVERGENTE_RELEVANTE ≥ R${args.tol:.2f} — PARANDO. Top:")
            for mod, uf, cod, fonte, calc, dif in cf["ofensores"][:15]:
                print(f"      {mod} {uf} {cod}: fonte={fonte} calc={calc} Δ={dif}")
            return 1
        print(f"{tag} ✓ passou (nenhum DIVERGENTE_RELEVANTE ≥ R${args.tol:.2f}).")

        # ── publicar + ESPERAR confirmar PUBLICADA antes de avançar ──
        if not args.no_publish and e["ciclo"] in ("RASCUNHO", "EM_REVISAO"):
            ok, msg = publicar(args.base, e["edi_id"])
            if not ok:
                print(f"{tag} ⚠ publicar falhou: {msg} — PARANDO."); return 1
            ciclo = esperar_publicada(e["edi_id"])
            if ciclo != "PUBLICADA":
                print(f"{tag} ✗ não confirmou PUBLICADA (ficou '{ciclo}') — PARANDO."); return 1
            print(f"{tag} ✓ publicada e confirmada (ciclo={ciclo})")
        print()

    print("✅ Todas as edições passaram.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
