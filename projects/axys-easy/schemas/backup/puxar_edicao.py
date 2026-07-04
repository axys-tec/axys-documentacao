#!/usr/bin/env python3
"""Puxa UMA edição do catálogo de PROD → DEV, para reproduzir estado REAL e testar
imports/fixes com dado de verdade (ex.: o item órfão da SINAPI 2025-10).

Copia (escopo = 1 edição), remapeando IDs surrogate por CHAVE NATURAL (prod≠dev):
  fontes · insumos_tipo(map) · edicoes · composicoes_subgrupos · insumos ·
  composicoes · composicoes_itens · composicoes_custo · insumos_preco ·
  edicoes_leis_sociais(+itens)

- Parents (fonte/edição/subgrupo/insumo/composição) = GET-OR-CREATE por chave natural
  (não apaga nada que já exista em dev).
- Folhas da edição (itens/custo/preços/LS) = DELETE do escopo + INSERT limpo (cópia fiel,
  incl. o item órfão que a gente quer reproduzir).
- Idempotente. Transacional (commit único no fim; erro → rollback total).
- Reaproveita as conexões dos scripts de backup → NÃO hardcoda credencial.

LIMITAÇÃO: GRUPOS (cmp_grupo_id / sub_grp_id) são zerados (NULL) na cópia — SINAPI não
usa grupo; p/ CDHU o vínculo de grupo se perde (irrelevante p/ o teste de item/custo).

Uso:  cd docs/projects/axys-easy/schemas/backup
      python puxar_edicao.py --fonte SINAPI --mes 2025-10
      python puxar_edicao.py --fonte CDHU   --mes 2024-08
"""
from __future__ import annotations

import argparse
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

import psycopg
from psycopg.types.json import Json  # colunas JSONB são lidas como dict → precisam de Json() na escrita
from gerar_backup_render import PG_CONFIG_REMOTE  # PROD (origem)
from restaurar_local import PG_CONFIG_LOCAL        # DEV  (destino)


def dicts(cur):
    cols = [d.name for d in cur.description]
    return [dict(zip(cols, r)) for r in cur.fetchall()]


def remap(row, drop_pk, fkmap, null_cols=()):
    """Copia a linha, tira o PK (auto-gera), remapeia FKs e zera null_cols."""
    r = {k: v for k, v in row.items() if k != drop_pk}
    for col in null_cols:
        if r.get(col) is not None:
            r[col] = None
    for col, m in fkmap.items():
        if r.get(col) is not None:
            r[col] = m[r[col]]  # KeyError = referência fora do escopo (proposital)
    return r


def insert(cur, table, row, returning=None):
    cols = list(row)
    # JSONB volta do prod como dict → embrulha em Json() (listas ficam como estão: arrays PG).
    vals = [Json(row[c]) if isinstance(row[c], dict) else row[c] for c in cols]
    q = (f"INSERT INTO {table} ({','.join(cols)}) "
         f"VALUES ({','.join(['%s'] * len(cols))})")
    if returning:
        q += f" RETURNING {returning}"
    cur.execute(q, vals)
    return cur.fetchone()[0] if returning else None


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--fonte", required=True, help="fte_codigo, ex.: SINAPI")
    ap.add_argument("--mes", required=True, help="mês-ref YYYY-MM, ex.: 2025-10")
    args = ap.parse_args()
    mes = args.mes if len(args.mes) > 7 else args.mes + "-01"  # YYYY-MM → 1º dia

    with psycopg.connect(**PG_CONFIG_REMOTE) as src, \
         psycopg.connect(**PG_CONFIG_LOCAL) as dst:
        sc, dc = src.cursor(), dst.cursor()

        # 1) FONTE
        sc.execute("SELECT * FROM catalogo.fontes WHERE fte_codigo=%s", (args.fonte,))
        pf = dicts(sc)
        if not pf:
            sys.exit(f"fonte {args.fonte} não existe em PROD")
        pf = pf[0]
        dc.execute("SELECT fte_id FROM catalogo.fontes WHERE fte_codigo=%s", (args.fonte,))
        r = dc.fetchone()
        dev_fte = r[0] if r else insert(dc, "catalogo.fontes", remap(pf, "fte_id", {}), "fte_id")
        print(f"fonte {args.fonte}: prod {pf['fte_id']} → dev {dev_fte}")

        # 2) insumos_tipo  (prod ti_id → dev ti_id por ti_codigo)
        sc.execute("SELECT ti_id, ti_codigo FROM catalogo.insumos_tipo")
        prod_ti = {a: b for a, b in sc.fetchall()}
        dc.execute("SELECT ti_codigo, ti_id FROM catalogo.insumos_tipo")
        dev_ti = {a: b for a, b in dc.fetchall()}
        ti_map = {pid: dev_ti[code] for pid, code in prod_ti.items() if code in dev_ti}
        faltando_ti = {code for pid, code in prod_ti.items() if code not in dev_ti}
        if faltando_ti:
            print(f"  ⚠ tipos de insumo ausentes em dev (insumos desses tipos falharão): {faltando_ti}")

        # 3) EDIÇÃO
        sc.execute("SELECT * FROM catalogo.edicoes WHERE edi_fte_id=%s AND edi_mes_ref=%s",
                   (pf["fte_id"], mes))
        pe = dicts(sc)
        if not pe:
            sys.exit(f"edição {args.fonte} {args.mes} não existe em PROD")
        pe = pe[0]
        prod_edi = pe["edi_id"]
        dc.execute("SELECT edi_id FROM catalogo.edicoes WHERE edi_fte_id=%s AND edi_mes_ref=%s",
                   (dev_fte, mes))
        r = dc.fetchone()
        dev_edi = r[0] if r else insert(
            dc, "catalogo.edicoes",
            remap(pe, "edi_id", {"edi_fte_id": {pf["fte_id"]: dev_fte}}), "edi_id")
        print(f"edição {args.mes}: prod {prod_edi} → dev {dev_edi}")

        # 4) COMPOSIÇÕES da edição
        sc.execute("SELECT * FROM catalogo.composicoes WHERE cmp_fte_id=%s AND cmp_edi_id=%s",
                   (pf["fte_id"], prod_edi))
        pcomps = dicts(sc)
        prod_cmp_ids = [c["cmp_id"] for c in pcomps]
        print(f"composições na edição: {len(pcomps)}")
        if any(c.get("cmp_grupo_id") for c in pcomps):
            print("  ⚠ cmp_grupo_id será ZERADO na cópia (vínculo de grupo perdido — ok p/ teste)")

        # 4a) SUBGRUPOS  (get-or-create por descrição; sub_grp_id zerado)
        sub_ids = {c["cmp_sub_id"] for c in pcomps if c.get("cmp_sub_id")}
        sub_map = {}
        if sub_ids:
            sc.execute("SELECT * FROM catalogo.composicoes_subgrupos WHERE sub_id = ANY(%s)",
                       (list(sub_ids),))
            for ps in dicts(sc):
                dc.execute("SELECT sub_id FROM catalogo.composicoes_subgrupos "
                           "WHERE sub_fte_id=%s AND sub_descricao=%s",
                           (dev_fte, ps["sub_descricao"]))
                r = dc.fetchone()
                sub_map[ps["sub_id"]] = r[0] if r else insert(
                    dc, "catalogo.composicoes_subgrupos",
                    remap(ps, "sub_id", {"sub_fte_id": {pf["fte_id"]: dev_fte}},
                          null_cols=("sub_grp_id",)), "sub_id")
        print(f"subgrupos: {len(sub_map)}")

        # 5) INSUMOS referenciados (itens da edição ∪ preços da edição)
        sc.execute("""
            SELECT DISTINCT ci_ins_id FROM catalogo.composicoes_itens
             WHERE ci_cmp_id = ANY(%s) AND ci_ins_id IS NOT NULL
            UNION
            SELECT DISTINCT pri_ins_id FROM catalogo.insumos_preco WHERE pri_edi_id=%s
        """, (prod_cmp_ids, prod_edi))
        need_ins = [r[0] for r in sc.fetchall()]
        ins_map = {}
        if need_ins:
            sc.execute("SELECT * FROM catalogo.insumos WHERE ins_id = ANY(%s)", (need_ins,))
            pins = dicts(sc)
            dc.execute("SELECT ins_codigo, ins_id FROM catalogo.insumos WHERE ins_fte_id=%s", (dev_fte,))
            dev_ins = {a: b for a, b in dc.fetchall()}
            for pi in pins:
                if pi["ins_codigo"] in dev_ins:
                    ins_map[pi["ins_id"]] = dev_ins[pi["ins_codigo"]]
                else:
                    fk = {"ins_fte_id": {pf["fte_id"]: dev_fte}}
                    if pi.get("ins_ti_id") is not None:
                        fk["ins_ti_id"] = ti_map
                    ins_map[pi["ins_id"]] = insert(
                        dc, "catalogo.insumos", remap(pi, "ins_id", fk), "ins_id")
        print(f"insumos: {len(ins_map)}")

        # 6) COMPOSIÇÕES (parents; itens depois, pois sub-comp referencia composição)
        dc.execute("SELECT cmp_codigo, cmp_id FROM catalogo.composicoes "
                   "WHERE cmp_fte_id=%s AND cmp_edi_id=%s", (dev_fte, dev_edi))
        dev_cmp = {a: b for a, b in dc.fetchall()}
        cmp_map = {}
        for pc in pcomps:
            if pc["cmp_codigo"] in dev_cmp:
                cmp_map[pc["cmp_id"]] = dev_cmp[pc["cmp_codigo"]]
            else:
                fk = {"cmp_fte_id": {pf["fte_id"]: dev_fte}, "cmp_edi_id": {prod_edi: dev_edi}}
                if pc.get("cmp_sub_id") is not None:
                    fk["cmp_sub_id"] = sub_map
                cmp_map[pc["cmp_id"]] = insert(
                    dc, "catalogo.composicoes",
                    remap(pc, "cmp_id", fk, null_cols=("cmp_grupo_id",)), "cmp_id")
        dev_cmp_ids = list(cmp_map.values())
        print(f"composições mapeadas: {len(cmp_map)}")

        # 7) ITENS  (delete escopo + insert remapeado — AQUI vem o órfão)
        dc.execute("DELETE FROM catalogo.composicoes_itens WHERE ci_cmp_id = ANY(%s)", (dev_cmp_ids,))
        sc.execute("SELECT * FROM catalogo.composicoes_itens WHERE ci_cmp_id = ANY(%s)", (prod_cmp_ids,))
        n = pulados = 0
        for it in dicts(sc):
            fk = {"ci_cmp_id": cmp_map}
            if it.get("ci_ins_id") is not None:
                fk["ci_ins_id"] = ins_map
            if it.get("ci_cmp_filho_id") is not None:
                fk["ci_cmp_filho_id"] = cmp_map
            try:
                insert(dc, "catalogo.composicoes_itens", remap(it, "ci_id", fk)); n += 1
            except KeyError:
                pulados += 1  # sub-comp/insumo fora do escopo
        print(f"itens copiados: {n}" + (f" ({pulados} pulados — ref fora do escopo)" if pulados else ""))

        # 8) CUSTO
        dc.execute("DELETE FROM catalogo.composicoes_custo WHERE cc_cmp_id = ANY(%s)", (dev_cmp_ids,))
        sc.execute("SELECT * FROM catalogo.composicoes_custo WHERE cc_cmp_id = ANY(%s)", (prod_cmp_ids,))
        n = 0
        for cc in dicts(sc):
            insert(dc, "catalogo.composicoes_custo", remap(cc, "cc_id", {"cc_cmp_id": cmp_map})); n += 1
        print(f"custos copiados: {n}")

        # 9) PREÇOS da edição
        dc.execute("DELETE FROM catalogo.insumos_preco WHERE pri_edi_id=%s", (dev_edi,))
        sc.execute("SELECT * FROM catalogo.insumos_preco WHERE pri_edi_id=%s", (prod_edi,))
        n = 0
        for pr in dicts(sc):
            try:
                insert(dc, "catalogo.insumos_preco",
                       remap(pr, "pri_id", {"pri_ins_id": ins_map, "pri_edi_id": {prod_edi: dev_edi}})); n += 1
            except KeyError:
                pass
        print(f"preços copiados: {n}")

        # 10) LEIS SOCIAIS (header + itens)
        dc.execute("DELETE FROM catalogo.edicoes_leis_sociais WHERE els_edi_id=%s", (dev_edi,))
        sc.execute("SELECT * FROM catalogo.edicoes_leis_sociais WHERE els_edi_id=%s", (prod_edi,))
        els_map = {}
        for els in dicts(sc):
            els_map[els["els_id"]] = insert(
                dc, "catalogo.edicoes_leis_sociais",
                remap(els, "els_id", {"els_edi_id": {prod_edi: dev_edi}}), "els_id")
        if els_map:
            sc.execute("SELECT * FROM catalogo.edicoes_leis_sociais_itens WHERE elsi_els_id = ANY(%s)",
                       (list(els_map),))
            for elsi in dicts(sc):
                insert(dc, "catalogo.edicoes_leis_sociais_itens",
                       remap(elsi, "elsi_id", {"elsi_els_id": els_map}))
        print(f"LS: {len(els_map)} header(s)")

        dst.commit()
        print(f"\n✅ Edição {args.fonte} {args.mes} copiada PROD → DEV (dev_edi_id={dev_edi}).")
        print("   Próximo: reimporte essa edição em dev com o parser da branch")
        print("   fix/import-itens-idempotencia e confira o item órfão sumir (diff → 0).")


if __name__ == "__main__":
    main()
