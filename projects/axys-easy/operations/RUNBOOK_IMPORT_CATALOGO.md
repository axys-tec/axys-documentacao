# Runbook — Importar uma edição do catálogo (SINAPI · CDHU · FDE)

**Status:** Vivo · **Atualizado:** 2026-09-14
**Escopo:** como importar uma edição NOVA de cada fonte-base, do zero ao custo publicado.
**Público:** operador do catálogo. Onde há `python …` é comando literal; onde é "pela app" é a tela `/import`.

> **Doutrina do custo (motor único, desde 2026-09-14):** o custo já sai CERTO no próprio import.
> `cc_custo_calculado` = **TRUNC/TRUNC** (o número da app) e `cc_status_conferencia` pelo **oráculo**
> (classificador composto) são gravados pelo parser, que delega a
> `backend/modules/catalogo/recompute_custo.recompute_edicao`. **Não** precisa rodar recompute manual
> depois de um import novo. O `migracao/recompute_cc_calculado.py` é SÓ para **retroação em massa**
> (recompor todas as edições como eram à época) — ver §5.

---

## 0. Pré-requisitos

- **Ambiente:** dev usa `.env.local`; prod usa o env do Render. NUNCA editar `.env.local` de outra sessão.
- **App no ar (dev):** para importar pela tela, subir a app + worker: `bash run_dev.sh` (web :8788,
  mobile :8790, worker Celery). O import roda no **worker**.
- **IA do descritivo:** o import "formar item" (insumos/composições/custos) **não chama IA**. O estágio
  de descritivo é separado; em dev deixe `AXYS_CPU_DESC_MODO=IA_local` (só monta o request `.md`). Em
  prod é `IA_auto`.
- **Edição semeada:** a edição-alvo (fonte + versão) precisa existir no banco antes do import
  (`catalogo.edicoes`). Se não existir, criar pela tela de Edições / rebuild.
- **Credenciais FDE:** `FDE_USER` / `FDE_PASSWORD` na `.env.local` (o portal da FDE; ver §3).

---

## 1. SINAPI (pela app)

Material bruto: `SINAPI_Referência_AAAA_MM.xlsx` + `_Manutenções` + `_familias_e_coeficientes` +
`_mao_de_obra` + `links.txt` (cadernos). Ex.: `z_search_repos/SINAPI-2026-08/`.

1. Semear a edição SINAPI da versão (ex.: `08-26`, mês-ref 2026-08-01).
2. Pela tela `/import` (SINAPI): subir o `SINAPI_Referência` + auxiliares e rodar os estágios
   **preparar → preços → dados**. O estágio Dados roda `parse_custos` + `calcular_custos_sinapi`
   (já TRUNC + oráculo).
3. Validar (§6). SINAPI reproduz a fonte ao centavo (oráculo==trunc).

## 2. CDHU (pela app)

Material bruto (tudo local): `insumos.NNN.xlsx`, `composicao-NNN.xlsx`, `servicos.NNN-sd.xlsx`,
`servicos.NNN-cd.xlsx` (CDHU publica SD **e** CD), `criterio.NNN.pdf`, encargos/metodologia PDFs.
Ex.: `z_search_repos/cdhu 203/`.

1. Semear a edição CDHU da versão (ex.: `203`).
2. Pela tela `/import` (CDHU): subir insumos → composições → serviços (SD e CD) e rodar até a
   **conferência**. O `parser_cdhu.calcular_custos` delega ao motor único (TRUNC + oráculo).
3. Validar (§6). Âncora: CDHU `01.02.081` (edi vigente) = **10.074,26** / `DIVERGENTE_ARREDONDAMENTO`.

---

## 3. FDE — montar o dist LOCAL, depois importar o dist

**Por que é diferente:** o preço de insumo da FDE vem de um **curl UM-A-UM** no portal
`produtostecnicos.fde.sp.gov.br` (busca logada, um insumo por vez). Isso **funciona local** (IP BR
alcança o portal) mas **quebra em prod/Ohio**. Por isso: **monta-se o `dist.zip` LOCAL** e importa-se
o dist em prod (portal-free).

Material bruto (portal salvo + PDFs), ex. `z_search_repos/fde - jul 26/`:
`Tabela ... Sintetica ....pdf`, `Tabela ... Analitica ....pdf`, `bdi.aspx`, `leis sociais.aspx`
(os `.aspx` são PDF), `pag_catalogo_servicos.html`, `pag_catalogo_componentes.html`
(+ `pag_listagem_insumos.html`, que NÃO é usado — não tem preço).

### 3.1 Montar o dist (LOCAL, ~8 min)

Ferramenta: **`z_scripts_apoio/manutencao/fde_dist_local.py`** (roda `fde_mod_novo.montar_csvs`
= parseia PDFs + **scrapa os preços** do portal, + `fde_transform.transformar` = fichas dos 2 HTMLs,
+ empacota `csv/` + `originais/` + `fichas/` + `manifest.json` → `AAAA_MM.zip`). Lê `FDE_USER`/`FDE_PASSWORD`.

```bash
S="z_search_repos/fde - jul 26"
python z_scripts_apoio/manutencao/fde_dist_local.py \
  --edicao 2026_07 --dir "$S" \
  --sintetica "$S/Tabela de Preços  Sintetica  julho 26 .pdf" \
  --analitica "$S/Tabela  Preços Analitica  julho 26 .pdf" \
  --bdi "$S/bdi.aspx" --ls "$S/leis sociais.aspx" \
  --catalogos "$S/pag_catalogo_servicos.html" \
  --componentes "$S/pag_catalogo_componentes.html"
# saída: z_search_repos/find_fde/boletins/dist/2026_07.zip
```

- Os `--<tipo>` explícitos são necessários quando os nomes/extensões fogem do padrão (nomes com espaço,
  `.aspx` no lugar de `.pdf`). Se a pasta tiver os 6-8 arquivos com nomes canônicos, basta `--dir`.
- Fim esperado: `preços 2408/2408 · 0 pendentes` · `fichas: N PDFs · M vínculos · 0 órfãs` · `✓ …2026_07.zip`.

### 3.2 Conferir o dist (estrutural)

```bash
python - <<'PY'
import zipfile,csv,io,json
z=zipfile.ZipFile("z_search_repos/find_fde/boletins/dist/2026_07.zip")
man=next(n for n in z.namelist() if n.endswith("manifest.json")); print(json.loads(z.read(man)))
ins=z.read(next(n for n in z.namelist() if n.endswith("tabela_insumos.csv"))).decode()
rows=list(csv.DictReader(io.StringIO(ins)))
comp=sum(1 for r in rows if (r.get("valor_unit") or "").strip() not in ("","0","0,00"))
print(f"{len(rows)} insumos · {comp} com preço ({100*comp//len(rows)}%)")  # esperado 100%
PY
```

### 3.3 Importar o dist

- Semear a edição FDE da versão (ex.: `07-26`, mês-ref 2026-07-01) → em RASCUNHO.
- Pela **tela padrão** `/edicoes/importar` (portal-free): escolher fonte **FDE**, a edição, e no radio
  **`dist`** (em vez de `convencional`) subir o `2026_07.zip`. Segue os **estágios convencionais** do painel:
  Preparar → Preços → Dados → Documentos (clicando cada chip). No estágio Dados aparece `fichas: N nova(s)`
  e a curadoria de vinculação (`pendente_user`). O `parser_fde.calcular_custos` delega ao motor único
  (TRUNC + oráculo des-BDI). (A antiga página dedicada `/import/fde-dist` foi aposentada; a rota POST
  `/api/import/fde-dist` continua, agora acionada por essa tela.)
- Validar (§6). FDE publica **COM BDI** → a conferência des-BDIniza (`fonte ÷ (1+BDI%)`); o `calc` é limpo.

---

## 4. Deploy do código (quando os parsers/motor mudarem)

O import roda no **worker**. Se mudou parser/motor: `git push` → Blueprint redeploya web+worker+mobile.
O custo TRUNC + oráculo passa a valer para imports NOVOS automaticamente. NÃO precisa recompute manual
para uma edição recém-importada.

---

## 5. Retroação em massa (SÓ quando precisa recompor o HISTÓRICO)

Use quando quiser recompor `cc_custo_calculado`/status de **edições já existentes** (todas, como eram
à época — receita reconstruída de `composicoes_historico`). NÃO é parte de um import novo.

```bash
python migracao/recompute_cc_calculado.py            # DRY: distribuição + amostras, nada gravado
python migracao/recompute_cc_calculado.py --edicao N # DRY de uma edição
python migracao/recompute_cc_calculado.py --go       # GRAVA (CDHU/FDE, todas edições; SINAPI fora, já é trunc)
python migracao/purge_warm_cache.py                  # DEPOIS do --go: purga Redis + reaquece vigentes
```

- Em prod: rodar no **shell do Render** (env já no ambiente). O `--go` manda heartbeat ZAPI (início/20min/fim).
- Ordem em prod: (1) deploy do código; (2) `recompute_cc_calculado.py --go`; (3) `purge_warm_cache.py`.
- Rede de segurança: o `recompute_edicao` do import e o `recompute_cc_calculado.py` compartilham o mesmo
  `_classificar` → resultado idêntico ao centavo (validado 0-diff).

---

## 6. Validação (após qualquer import)

```bash
DBURL=$(grep '^EASY_DB_URL=' .env.local | cut -d= -f2-)
# distribuição de status da edição (RELEVANTE deve ser baixo; DERIVADO=SE; ARREDONDAMENTO=maioria)
psql "$DBURL" -tAc "SELECT cc_status_conferencia, count(*) FROM catalogo.composicoes_custo cc
  JOIN catalogo.composicoes c ON c.cmp_id=cc.cc_cmp_id JOIN catalogo.fontes f ON f.fte_id=c.cmp_fte_id
  WHERE f.fte_codigo='CDHU' AND cc.cc_edi_id=<EDI> GROUP BY 1 ORDER BY 2 DESC"
```

- **Âncora CDHU:** `01.02.081` vigente = `cc_custo_calculado` **10.074,26** · fonte 10.074,35 ·
  `DIVERGENTE_ARREDONDAMENTO`.
- **Lista = detalhe = bancada:** a consulta mostra os 2 valores (Custo AXYS + Fonte).
- **Tela `diff-fonte-app`:** CDHU/FDE em ARREDONDAMENTO; SINAPI intocado.
- **`DIVERGENTE_RELEVANTE`:** deve ser MUITO baixo (casos reais de bug de dado); revisar na tela diff.

---

## 7. Troubleshooting

- **FDE "curl não funciona":** é esperado EM PROD (Ohio). Sempre montar o dist LOCAL (§3.1) e importar o
  dist. Nunca tentar o portal direto em prod.
- **FDE fichas: crash em código-lixo:** era o bug da regex de etapa-sem-PDF (`fde_transform._ROW`),
  corrigido em `bd29332` (2026-09-14). Se reaparecer, conferir `_ROW` (não pode cruzar campo `&#39;`).
- **`FDE_USER/FDE_PASSWORD não setados`:** as creds estão na `.env.local` — o script lê ESSES nomes
  (há também LOGIN_FDE/SENHA_FDE, que o script NÃO usa).
- **Import não recalcula em prod:** deploy não recalcula o gravado. Import NOVO já sai trunc; para
  edição ANTIGA usar a retroação (§5).
- **`composicoes_custo_alerta`:** RESOLVIDO (2026-09) — a tabela foi **dropada** do schema (a app nunca
  a leu e o motor único não gera alerta). Os parsers não referenciam mais. Se algum dia fizer falta, é um
  `create table` novo.

---

## Referências

- Motor único / doutrina trunc: `REFACTOR_MOTOR_UNICO_PLANO.md`, `contracts/catalogo/BUSINESS_RULES.md §4`.
- Contratos de import: `contracts/catalogo/imports/{sinapi,cdhu,fde}.md`.
- Código: `backend/modules/catalogo/recompute_custo.py` (motor + classificador), parsers em
  `backend/core/import_cpu/`, dist FDE em `z_scripts_apoio/manutencao/fde_dist_local.py`.
