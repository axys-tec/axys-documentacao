# Matchers de vinculação aposentados (2026-07-22)

Removidos de `backend/modules/catalogo/equivalencias_service.py` (existem no commit **24dbd97** e anteriores).

| Função | O que fazia | Por que saiu |
|---|---|---|
| `propor_cpu_1x1` | 2º matcher CPU: 1×1 duro no SINAPI **inteiro** (over≥0,90, unidade igual) | universo-todo → 100% cross no resíduo; competência da IA |
| `propor_ins_sanitizado` (+ `_ordered_toks`) | INS relaxado floor 0,40 + sanitizador guloso | passe relaxado gera lixo que a IA teria de desfazer |
| `propor_atributo` (+ `_attr_prep`, `_attr_head`, `_tubo_fam`, `_tubo_dn`, `_eh_conexao`, `_eh_tubo`, `_ATTR_STOP`) | matcher por ATRIBUTO (tubulação DN, formas, concreto — fine-tuning) | **fine-tuning é competência da IA** (sobre os deltas), não do script; a 0,50 universo-todo preemptava o `propor_cpu` |

**Doutrina vigente:** cadeia = `revalidar_hashes` (PASS 1) + `propor_mo` + `propor_ins` (S2) + `propor_cpu` (subgrupo 0,55/3). Ver `vinculacoes.md §3.4.1`. Se a lógica de atributo (tubulação) voltar a ser útil, será **na fase da IA**, recuperável do commit acima.
