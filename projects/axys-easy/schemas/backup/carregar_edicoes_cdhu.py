#!/usr/bin/env python3
"""
Loader automático de edições CDHU CONTRA A APP NO AR (irmão do carregar_edicoes_sinapi).

Por boletim, em ordem cronológica: resolve os arquivos da pasta "Boletim CDHU NNN" →
upload+enfileira via POST /api/import/cdhu → espera o worker → GATE de conferência
(DIVERGENTE_RELEVANTE ≥ --tol) → publica + confirma PUBLICADA → próxima. Para no 1º que reprovar.

Particularidades CDHU (vs SINAPI): SP-only, arquivos SEPARADOS (insumos/composição/serviço SD/CD/
critério PDF), identidade por Nº DE BOLETIM (edi_codigo_versao), LS lida do cabeçalho do serviço
(sem manual), e nomes de arquivo que VARIAM por boletim (insumos.196 vs insumos_184; servico.201-sd
vs servicos_sd_184; CRITERIO.196.pdf vs criterio 201.pdf) → casamento por palavra-chave normalizada.
A trava de boletim (import_service._versao_cdhu, lê 'Versão NNN' de A5) barra arquivo trocado.

Reusa os helpers fonte-agnósticos do loader SINAPI (esperar_job/conferencia/publicar/esperar_publicada).

Uso:
    python carregar_edicoes_cdhu.py                 # todos os boletins RASCUNHO, publica, tol R$1
    python carregar_edicoes_cdhu.py --start 184 --end 190
    python carregar_edicoes_cdhu.py --dry-run       # só lista boletins+arquivos
"""
from __future__ import annotations

import argparse
import sys
from pathlib import Path

import httpx
import psycopg

sys.path.insert(0, str(Path(__file__).resolve().parent))
from restaurar_local import PG_CONFIG_LOCAL
# helpers estáveis (fonte-agnósticos) do loader SINAPI:
from carregar_edicoes_sinapi import (BASE_DEFAULT, XLSX, _norm,
                                     esperar_job, conferencia, esperar_publicada, publicar)

FONTE_ROOT = Path(__file__).resolve().parents[5] / "z_search_repos/fontes-base/cdhu"
PDF = "application/pdf"


class Reprovado(Exception):
    """Falha de uma edição (erro de import ou gate reprovado). Com --skip-on-fail vira PULAR+segue."""


def resolve_arquivos(versao: int) -> dict | None:
    """Acha a pasta 'Boletim CDHU NNN' e casa os arquivos por palavra-chave (tolerante às
    variações de nome entre boletins)."""
    pasta = FONTE_ROOT / f"Boletim CDHU {versao}"
    if not pasta.is_dir():
        print(f"    ⚠ pasta não encontrada: {pasta.name}")
        return None
    itens = [p for p in pasta.iterdir() if not p.name.startswith("~$")]
    xlsx = [p for p in itens if p.suffix.lower() == ".xlsx"]
    pdf = [p for p in itens if p.suffix.lower() == ".pdf"]
    sv = str(versao)

    def achar(cands, *req, veto=()):
        # entre vários matches, pega o NOME MAIS CURTO (canônico 'insumos.199.xlsx',
        # não 'insumos.199 - CLASSIFICADO.xlsx'); determinístico (iterdir não é ordenado).
        matches = [p for p in cands
                   if sv in _norm(p.name) and all(k in _norm(p.name) for k in req)
                   and not any(v in _norm(p.name) for v in veto)]
        return min(matches, key=lambda p: len(p.name)) if matches else None

    r = {
        "insumos":     achar(xlsx, "insumo",  veto=("servic", "composic", "subgrupo", "tabela")),
        "composicoes": achar(xlsx, "composic", veto=("tabela", "servic")),
        "servico_sd":  achar(xlsx, "servic", "sd", veto=("tabela",)),
        "servico_cd":  achar(xlsx, "servic", "cd", veto=("tabela",)),
        "criterio":    achar(pdf,  "criterio"),
    }
    faltam = [k for k in ("insumos", "composicoes", "criterio") if not r[k]]
    if faltam or not (r["servico_sd"] or r["servico_cd"]):
        det = (f"obrigatórios {faltam}" if faltam else "") + \
              ("" if (r["servico_sd"] or r["servico_cd"]) else " + nenhum serviço SD/CD")
        print(f"    ⚠ {pasta.name}: faltando {det}")
        return None
    return r


def edicoes_alvo(conn, start: int | None, end: int | None) -> list[dict]:
    # filtra por boletim no PYTHON: cast ::int no SQL tropeçava em versões de OUTRAS fontes
    # (FDE '07-22') avaliadas antes do filtro de fonte. São 18 edições — trivial em memória.
    cur = conn.cursor()
    cur.execute("""
        SELECT e.edi_id, to_char(e.edi_mes_ref,'YYYY-MM'), e.edi_codigo_versao, e.edi_situacao_ciclo
        FROM catalogo.edicoes e JOIN catalogo.fontes f ON f.fte_id = e.edi_fte_id
        WHERE f.fte_codigo = 'CDHU'
        ORDER BY e.edi_mes_ref
    """)
    out = []
    for r in cur.fetchall():
        v = int(r[2])
        if (start is not None and v < start) or (end is not None and v > end):
            continue
        out.append({"edi_id": r[0], "ym": r[1], "versao": v, "ciclo": r[3]})
    return out


def enfileirar_import(base: str, edi_id: int, arqs: dict) -> str:
    data = {"edi_id": str(edi_id), "ls_sd": "", "ls_cd": "",
            "disp_sd": "1" if arqs.get("servico_sd") else "0",
            "disp_cd": "1" if arqs.get("servico_cd") else "0"}
    fhs, files = {}, {}
    try:
        for slot, mime in (("insumos", XLSX), ("composicoes", XLSX), ("criterio", PDF),
                           ("servico_sd", XLSX), ("servico_cd", XLSX)):
            p = arqs.get(slot)
            if not p:
                continue
            fh = open(p, "rb"); fhs[slot] = fh
            files[slot] = (Path(p).name, fh, mime)
        r = httpx.post(f"{base}/api/import/cdhu", data=data, files=files, timeout=600)
    finally:
        for fh in fhs.values():
            fh.close()
    if r.status_code != 200:
        raise RuntimeError(f"POST import cdhu falhou [{r.status_code}]: {r.text[:300]}")
    j = r.json()
    if not j.get("success"):
        raise RuntimeError(f"import recusado: {j.get('message')}")
    return j["job_id"]


def main():
    ap = argparse.ArgumentParser(description="Carga automática de edições CDHU contra a app no ar.")
    ap.add_argument("--start", type=int, default=None, help="boletim inicial (ex.: 184)")
    ap.add_argument("--end", type=int, default=None, help="boletim final (ex.: 201)")
    ap.add_argument("--base", default=BASE_DEFAULT, help=f"URL da app (default {BASE_DEFAULT})")
    ap.add_argument("--tol", type=float, default=1.00, help="tolerância R$ p/ DIVERGENTE_RELEVANTE (default 1.00)")
    ap.add_argument("--no-publish", action="store_true")
    ap.add_argument("--skip-on-fail", action="store_true",
                    help="não trava numa edição reprovada/erro; loga, deixa RASCUNHO e segue")
    ap.add_argument("--dry-run", action="store_true")
    args = ap.parse_args()

    with psycopg.connect(**PG_CONFIG_LOCAL) as conn:
        eds = edicoes_alvo(conn, args.start, args.end)
    if not eds:
        print("Nenhuma edição CDHU no intervalo."); return 1
    print(f"Boletins alvo: {', '.join(str(e['versao']) for e in eds)}  (base={args.base}, "
          f"tol=R${args.tol:.2f}, publish={not args.no_publish})\n")

    pulados, reprovados = [], []   # sem-fonte-split · reprovados no gate/erro (com --skip-on-fail não travam)
    for e in eds:
        tag = f"[bol {e['versao']} · {e['ym']} · edi {e['edi_id']} · {e['ciclo']}]"
        arqs = resolve_arquivos(e["versao"])
        if not arqs:
            print(f"{tag} ⏭ PULANDO (sem arquivos-fonte split — só a Tabela consolidada).\n")
            pulados.append(e["versao"])
            continue
        if args.dry_run:
            print(f"{tag} OK → " + " · ".join(f"{k}={Path(v).name}" for k, v in arqs.items() if v))
            continue
        try:
            if e["ciclo"] not in ("RASCUNHO", "EM_REVISAO"):
                print(f"{tag} já {e['ciclo']} — pulando import (só confere).")
            else:
                print(f"{tag} importando…")
                try:
                    job = enfileirar_import(args.base, e["edi_id"], arqs)
                    res = esperar_job(args.base, job)
                except Exception as ex:
                    raise Reprovado(f"erro no import: {ex}")
                if res.get("status") != "concluido":
                    raise Reprovado(f"import terminou em '{res.get('status')}': {res.get('erro')}")
                print(f"{tag} import concluído.")

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
                top = "\n".join(f"      {mod} {uf} {cod}: fonte={fonte} calc={calc} Δ={dif}"
                                for mod, uf, cod, fonte, calc, dif in cf["ofensores"][:15])
                raise Reprovado(f"{len(cf['ofensores'])}+ DIVERGENTE_RELEVANTE ≥ R${args.tol:.2f}. Top:\n{top}")
            print(f"{tag} ✓ passou (nenhum DIVERGENTE_RELEVANTE ≥ R${args.tol:.2f}).")

            if not args.no_publish and e["ciclo"] in ("RASCUNHO", "EM_REVISAO"):
                ok, msg = publicar(args.base, e["edi_id"])
                if not ok:
                    raise Reprovado(f"publicar falhou: {msg}")
                ciclo = esperar_publicada(e["edi_id"])
                if ciclo != "PUBLICADA":
                    raise Reprovado(f"não confirmou PUBLICADA (ficou '{ciclo}')")
                print(f"{tag} ✓ publicada e confirmada (ciclo={ciclo})")
        except Reprovado as rp:
            if not args.skip_on_fail:
                print(f"{tag} ✗ {rp} — PARANDO."); return 1
            print(f"{tag} ⏭ PULANDO por falha: {rp}\n")
            reprovados.append((e["versao"], str(rp).split(chr(10))[0]))
            continue
        print()

    print("── resumo ──")
    if pulados:
        print(f"⏭ SEM FONTE SPLIT (só Tabela): {', '.join(map(str, pulados))}")
    if reprovados:
        print(f"✗ REPROVADOS (fonte inconsistente / erro):")
        for v, m in reprovados:
            print(f"    bol {v}: {m}")
    if not reprovados and not pulados:
        print("✅ Todos os boletins passaram e publicaram.")
    return 0 if not reprovados else 2


if __name__ == "__main__":
    sys.exit(main())
