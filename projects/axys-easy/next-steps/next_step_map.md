# AxysEasy — Mapeamento de Import: CDHU e SINAPI → Banco de Dados

> Gerado em: 31/05/2026
> Referência de arquivos: `z_search_repos/fontes-base/`
> Referência de schema: `docs/db/easy/easy_schema.sql`
>
> **Convenção de texto:** todos os campos de texto inseridos no banco devem ser
> normalizados para CAIXA ALTA (`.upper()` ou `str.strip().upper()`) salvo
> exceções explicitamente anotadas.

---

## Índice

- [Pré-requisito: catalogo.edicoes](#pré-requisito-catalogoedicoes)
- [CDHU — Mapeamento por tabela](#cdhu--mapeamento-por-tabela)
  - [catalogo.insumos — CDHU](#catalogoinsumos--cdhu)
  - [catalogo.precos_insumo — CDHU](#catalogoprecos_insumo--cdhu)
  - [catalogo.grupos — CDHU](#catalogogrupos--cdhu)
  - [catalogo.subgrupos — CDHU](#catalogosubgrupos--cdhu)
  - [catalogo.composicoes — CDHU](#catalogocomposicoes--cdhu)
  - [catalogo.composicao_itens — CDHU](#catalogocomposicao_itens--cdhu)
  - [catalogo.custos_composicao — CDHU](#catalogocustos_composicao--cdhu)
- [SINAPI — Mapeamento por tabela](#sinapi--mapeamento-por-tabela)
  - [catalogo.insumos — SINAPI](#catalogoinsumos--sinapi)
  - [catalogo.precos_insumo — SINAPI](#catalogoprecos_insumo--sinapi)
  - [catalogo.subgrupos — SINAPI](#catalogosubgrupos--sinapi)
  - [catalogo.composicoes — SINAPI](#catalogocomposicoes--sinapi)
  - [catalogo.composicao_itens — SINAPI](#catalogocomposicao_itens--sinapi)
  - [catalogo.custos_composicao — SINAPI](#catalogocustos_composicao--sinapi)
  - [catalogo.sinapi_manutencoes](#catalogosinapi_manutencoes)
- [Tabelas não populadas por import](#tabelas-não-populadas-por-import)
- [Lookup: tipos_insumo](#lookup-catalogotipos_insumo)

---

## Pré-requisito: catalogo.edicoes

Antes de qualquer import, a edição deve existir ou ser criada. Nenhum parser cria a edição — ela é selecionada ou criada via tela/serviço antes do import.

| Fonte | edi_mes_ref | edi_codigo_versao | edi_uf_padrao | Observação |
|---|---|---|---|---|
| CDHU 201 | `2026-02-01` | `'201'` | `'SP'` | Data base FEV/2026; versão = número do boletim |
| SINAPI ABR/2026 | `2026-04-01` | NULL | `'SP'` | Data base 1º dia do mês de referência |

`edi_fte_id` é o `fte_id` da fonte em `catalogo.fontes` (CDHU ou SINAPI já no seed).

---

## CDHU — Mapeamento por tabela

### catalogo.insumos — CDHU

**Arquivo:** `insumos.VVV.xlsx`
**Aba:** `Insumos`
**Início dos dados:** linha 9 (pular 8 linhas: 7 de metadado + 1 de cabeçalho)
**Linhas de dados:** ~3.227

| Coluna do Excel | Posição | Campo DB | Transformação |
|---|---|---|---|
| `Referência` | col 1 | `ins_codigo` | `.strip().upper()` — ex: `'A.02.000.070107'` |
| `Descrição do Insumo` | col 2 | `ins_descricao` | `.strip().upper()` — atenção: header tem espaço leading |
| `Unidade` | col 3 | `ins_unidade` | `.strip().upper()` — ex: `'H'`, `'M3'`, `'UN'` |
| _(prefixo do código)_ | col 1 (derivado) | `ins_ti_id` | Inferir pelo prefixo da letra (ver tabela de mapeamento abaixo) |
| — | — | `ins_fte_id` | `fte_id` de CDHU em `catalogo.fontes` |
| — | — | `ins_ativo` | `True` (default) |

**Mapeamento de `ins_ti_id` pelo prefixo do código CDHU:**

| Prefixo CDHU | Significado | `tipos_insumo.ti_codigo` |
|---|---|---|
| `B` | Mão de obra | `MO` |
| `Q` | Equipamentos — aquisição | `EQUIP_AQ` |
| `A` | Locações / serviços especiais | `SERV` |
| `S` | Serviços / locações | `SERV` |
| `C` a `P` (exceto Q) | Materiais / artefatos | `MAT` |

> **Nota:** mapeamento aproximado (CDHU não publica tabela oficial). Usar `ins_ti_id` para histogramas e agrupamentos.

**Upsert:** `ON CONFLICT (ins_fte_id, ins_codigo) DO UPDATE` — reimport da mesma
edição é idempotente; atualiza descrição e unidade se mudaram.

---

### catalogo.precos_insumo — CDHU

**Arquivo:** `insumos.VVV.xlsx` — mesma leitura de `catalogo.insumos`
**Origem:** coluna 4 do mesmo arquivo

| Coluna do Excel | Posição | Campo DB | Transformação |
|---|---|---|---|
| `Custo (R$)` | col 4 | `pri_valor` | `float` — pode ser `None` (pular linha) |
| — | — | `pri_ins_id` | FK para `catalogo.insumos` pelo `ins_codigo` recém-inserido |
| — | — | `pri_edi_id` | FK para a edição corrente |
| — | — | `pri_uf` | `'SP'` fixo — CDHU é fonte estadual SP |
| — | — | `pri_modalidade` | `'SD'` fixo — CDHU publica valores sem desoneração |
| — | — | `pri_origem` | `NULL` — não informado pela CDHU |

**Regra:** se `Custo (R$)` for `None` ou zero, não inserir linha de preço.

**Upsert:** `ON CONFLICT (pri_ins_id, pri_edi_id, pri_uf, pri_modalidade) DO UPDATE SET pri_valor = EXCLUDED.pri_valor`

---

### catalogo.grupos — CDHU

**Arquivo:** `composicao.VVV.xlsx`
**Aba:** `Composição`
**Início dos dados:** linha 9
**Detecção:** código da coluna 1 matches regex `^\d{2}$`

| Dado da linha | Campo DB | Transformação |
|---|---|---|
| col 1 — código `'01'` | `grp_codigo` | `.strip()` — manter zeros à esquerda |
| col 2 — descrição | `grp_descricao` | `.strip().upper()` |
| — | `grp_fte_id` | `fte_id` de CDHU |

**Upsert:** `ON CONFLICT (grp_fte_id, grp_codigo) DO UPDATE SET grp_descricao = EXCLUDED.grp_descricao`

---

### catalogo.subgrupos — CDHU

**Arquivo:** `composicao.VVV.xlsx`
**Aba:** `Composição`
**Detecção:** código matches regex `^\d{2}\.\d{2}$`

| Dado da linha | Campo DB | Transformação |
|---|---|---|
| col 1 — código `'01.02'` | `sub_codigo` | `.strip()` |
| col 2 — descrição | `sub_descricao` | `.strip().upper()` |
| grupo corrente (estado do parser) | `sub_grp_id` | FK para `catalogo.grupos` pelo código dos dois primeiros dígitos |
| — | `sub_fte_id` | `fte_id` de CDHU |

**Upsert:** `ON CONFLICT (sub_fte_id, sub_codigo) DO UPDATE SET sub_descricao = EXCLUDED.sub_descricao`

---

### catalogo.composicoes — CDHU

**Arquivo:** `composicao.VVV.xlsx`
**Aba:** `Composição`
**Detecção:** código matches regex `^\d{2}\.\d{2}\.\d{3}$`

| Dado da linha | Campo DB | Transformação |
|---|---|---|
| col 1 — código `'01.02.071'` | `cmp_codigo` | `.strip()` |
| col 2 — descrição | `cmp_descricao` | `.strip().upper()` |
| col 3 — unidade | `cmp_unidade` | `.strip().upper()` — ex: `'M2'`, `'UN'` |
| subgrupo corrente (estado do parser) | `cmp_sub_id` | FK para `catalogo.subgrupos` |
| — | `cmp_fte_id` | `fte_id` de CDHU |
| — | `cmp_edi_id` | FK para a edição corrente |
| — | `cmp_situacao` | `NULL` — CDHU não publica situação |
| — | `cmp_ativa` | `True` |

**Upsert:** `ON CONFLICT (cmp_fte_id, cmp_codigo, cmp_edi_id) DO UPDATE SET cmp_descricao = EXCLUDED.cmp_descricao, cmp_unidade = EXCLUDED.cmp_unidade`

---

### catalogo.composicao_itens — CDHU

**Arquivo:** `composicao.VVV.xlsx`
**Aba:** `Composição`
**Detecção:** código matches regex `^[A-Z]\.\d{2}\.\d{3}\.\d{6}$`

| Dado da linha | Campo DB | Transformação |
|---|---|---|
| col 4 — coeficiente | `ci_coef` | `float` — ex: `5.67` |
| composição corrente (estado do parser) | `ci_cmp_id` | FK para `catalogo.composicoes` |
| col 1 — código do insumo | `ci_ins_id` | FK para `catalogo.insumos` pelo `ins_codigo` e `ins_fte_id=CDHU` |
| — | `ci_tipo_filho` | `'INSUMO'` fixo — CDHU não tem sub-composições |
| — | `ci_cmp_filho_id` | `NULL` fixo |
| contador incremental | `ci_ordem` | Reinicia a cada nova composição |
| — | `ci_situacao` | `NULL` — não informado pela CDHU |

> **Coluna 5 (`15`):** presente em todos os itens. Provavelmente código de grupo
> de encargos sociais. Não importar para o banco por ora — registrar como aviso
> no `ImportResult` para análise futura.

**Upsert:** `ON CONFLICT (ci_cmp_id, ci_ins_id) DO NOTHING` (idempotente por composição + insumo)

---

### catalogo.custos_composicao — CDHU

**Arquivo:** `servicos.VVV-sd.xlsx`
**Aba:** `Serviços`
**Início dos dados:** linha 9 (pular 8 linhas; linha 7 contém metadado BDI/LS — ignorar)
**Detecção de linha de serviço:** código matches regex `^\d{2}\.\d{2}\.\d{3}$`

| Coluna do Excel | Posição | Campo DB | Transformação |
|---|---|---|---|
| `Referência` | col 1 | lookup `cmp_codigo` | `.strip()` → buscar `cmp_id` em `catalogo.composicoes` |
| `Custo Total` | col 6 | `cc_custo` | `float` — pode ser `None` (pular) |
| — | — | `cc_edi_id` | FK para a edição corrente |
| — | — | `cc_uf` | `'SP'` fixo |
| — | — | `cc_modalidade` | `'SD'` fixo (arquivo `-sd.xlsx` = sem desoneração) |
| — | — | `cc_pct_sp` | `NULL` — não aplicável (CDHU é fonte SP) |

> **Linhas de grupo/subgrupo** (código `^\d{2}$` ou `^\d{2}\.\d{2}$`):
> ignorar — não têm custo.

**Upsert:** `ON CONFLICT (cc_cmp_id, cc_edi_id, cc_uf, cc_modalidade) DO UPDATE SET cc_custo = EXCLUDED.cc_custo`

---

## SINAPI — Mapeamento por tabela

---

### catalogo.insumos — SINAPI

**Arquivo:** `SINAPI_Referência_YYYY_MM.xlsx`
**Aba primária:** `ISD` (Sem Desoneração)
**Início dos dados:** linha 11 (pular 10 linhas de metadado + cabeçalho)
**Linhas de dados:** ~4.854

| Coluna do Excel | Posição | Campo DB | Transformação |
|---|---|---|---|
| `Classificação` | col 1 | `ins_ti_id` | Lookup em `tipos_insumo` (MATERIAL→MAT, MAO DE OBRA→MO, etc.) |
| `Código do Insumo` | col 2 | `ins_codigo` | `str(int(valor))` — converter inteiro para string |
| `Descrição do Insumo` | col 3 | `ins_descricao` | `.strip().upper()` |
| `Unidade` | col 4 | `ins_unidade` | `.strip().upper()` |
| `Classificação` (derivado) | col 1 | `ins_ti_id` | Lookup via tabela (ver seção Lookup abaixo) |
| — | — | `ins_fte_id` | `fte_id` de SINAPI em `catalogo.fontes` |
| — | — | `ins_ativo` | `True` (default) |

> **Fonte:** usar apenas aba `ISD` para insumos (evitar duplicatas entre ISD/ICD/ISE).
> ICD e ISE têm os mesmos insumos, apenas com preços diferentes por modalidade.
> O insumo em si (identidade) é o mesmo.

**Upsert:** `ON CONFLICT (ins_fte_id, ins_codigo) DO UPDATE SET ins_descricao = EXCLUDED.ins_descricao, ins_unidade = EXCLUDED.ins_unidade, ins_tipo_sinapi = EXCLUDED.ins_tipo_sinapi, ins_ti_id = EXCLUDED.ins_ti_id`

---

### catalogo.precos_insumo — SINAPI

**Arquivo:** `SINAPI_Referência_YYYY_MM.xlsx`
**Abas:** `ISD` (modalidade `'SD'`) + `ICD` (modalidade `'CD'`)
**Início dos dados:** linha 11

**Colunas de UF (27 colunas, posições 6 a 32):**
```
col  6 → AC  |  col 7 → AL  |  col  8 → AM  |  col  9 → AP  |  col 10 → BA
col 11 → CE  |  col 12 → DF |  col 13 → ES  |  col 14 → GO  |  col 15 → MA
col 16 → MG  |  col 17 → MS |  col 18 → MT  |  col 19 → PA  |  col 20 → PB
col 21 → PE  |  col 22 → PI |  col 23 → PR  |  col 24 → RJ  |  col 25 → RN
col 26 → RO  |  col 27 → RR |  col 28 → RS  |  col 29 → SC  |  col 30 → SE
col 31 → SP  |  col 32 → TO
```

**Para cada linha de insumo, para cada coluna de UF:**

| Dado | Campo DB | Transformação |
|---|---|---|
| código (col 2) | `pri_ins_id` | lookup `ins_id` por `ins_codigo` e `ins_fte_id=SINAPI` |
| valor da célula UF | `pri_valor` | `float` — se `None`, pular (não inserir linha) |
| nome da coluna UF | `pri_uf` | `str` — ex: `'SP'`, `'RJ'` |
| aba `ISD` ou `ICD` | `pri_modalidade` | `'SD'` ou `'CD'` |
| col 5 — `Origem de Preço` | `pri_origem` | `.strip().upper()` — `'C'` ou `'CR'` |
| — | `pri_edi_id` | FK para a edição corrente |

**Resultado:** até 27 linhas por insumo por aba × 2 abas = até 54 linhas por insumo por edição.

**Upsert:** `ON CONFLICT (pri_ins_id, pri_edi_id, pri_uf, pri_modalidade) DO UPDATE SET pri_valor = EXCLUDED.pri_valor, pri_origem = EXCLUDED.pri_origem`

---

### catalogo.subgrupos — SINAPI

**Arquivo:** `SINAPI_Referência_YYYY_MM.xlsx`
**Aba:** `Analítico`
**Início dos dados:** linha 11

SINAPI não tem grupos (nível 1) — apenas subgrupos (nível 2) com `sub_grp_id = NULL`.
O nome do subgrupo vem da coluna `Grupo` (col 1), que se repete em cada linha.

**Parser:** coletar todos os valores únicos da coluna `Grupo` durante a leitura do `Analítico`.

| Dado | Campo DB | Transformação |
|---|---|---|
| col 1 — `Grupo` (valor único) | `sub_descricao` | `.strip().upper()` |
| col 1 — `Grupo` (normalizado) | `sub_codigo` | `.strip().upper()` — SINAPI usa o texto como código |
| — | `sub_grp_id` | `NULL` — SINAPI não tem nível de grupo |
| — | `sub_fte_id` | `fte_id` de SINAPI |

**Upsert:** `ON CONFLICT (sub_fte_id, sub_codigo) DO NOTHING`

---

### catalogo.composicoes — SINAPI

**Arquivo:** `SINAPI_Referência_YYYY_MM.xlsx`
**Aba:** `Analítico`
**Início dos dados:** linha 11
**Detecção de header de composição:** linha onde `Tipo Item` (col 3) está vazio/None

| Coluna do Excel | Posição | Campo DB | Transformação |
|---|---|---|---|
| `Código da Composição` | col 2 | `cmp_codigo` | `str(int(valor))` |
| `Descrição` | col 5 | `cmp_descricao` | `.strip().upper()` |
| `Unidade` | col 6 | `cmp_unidade` | `.strip().upper()` |
| `Situação` | col 8 | `cmp_situacao` | `.strip().upper()` — ex: `'COM CUSTO'`, `'SUSPENSO'` |
| `Grupo` (col 1) | col 1 | `cmp_sub_id` | FK para `catalogo.subgrupos` pelo código/texto do grupo |
| — | — | `cmp_fte_id` | `fte_id` de SINAPI |
| — | — | `cmp_edi_id` | FK para a edição corrente |
| — | — | `cmp_ativa` | `True` se `cmp_situacao != 'SUSPENSO'`, senão `False` |

**Upsert:** `ON CONFLICT (cmp_fte_id, cmp_codigo, cmp_edi_id) DO UPDATE SET cmp_descricao = EXCLUDED.cmp_descricao, cmp_situacao = EXCLUDED.cmp_situacao, cmp_ativa = EXCLUDED.cmp_ativa`

---

### catalogo.composicao_itens — SINAPI

**Arquivo:** `SINAPI_Referência_YYYY_MM.xlsx`
**Aba:** `Analítico`
**Detecção:** linhas onde `Tipo Item` (col 3) == `'INSUMO'` ou `'COMPOSICAO'`

| Coluna do Excel | Posição | Campo DB | Transformação |
|---|---|---|---|
| `Tipo Item` | col 3 | `ci_tipo_filho` | `.strip().upper()` — `'INSUMO'` ou `'COMPOSICAO'` |
| `Código do Item` | col 4 | lookup `ci_ins_id` ou `ci_cmp_filho_id` | `str(int(valor))` |
| `Coeficiente` | col 7 | `ci_coef` | `float` — ex: `1.2790000` |
| `Situação` | col 8 | `ci_situacao` | `.strip().upper()` |
| composição corrente (col 2) | — | `ci_cmp_id` | FK para `catalogo.composicoes` pela composição da linha corrente |
| contador incremental | — | `ci_ordem` | Reinicia a cada nova composição |

**Resolução de referências (dois passos — ver `next_step_app.md`):**

- **Passo 1 (Tipo Item = INSUMO):**
  `ci_ins_id` = lookup `ins_id` por `ins_codigo = str(Código do Item)` e `ins_fte_id = SINAPI`
  `ci_cmp_filho_id` = `NULL`

- **Passo 1 (Tipo Item = COMPOSICAO):**
  `ci_cmp_filho_id` = lookup `cmp_id` por `cmp_codigo = str(Código do Item)` — pode ser `NULL` se a composição filha ainda não foi importada
  `ci_ins_id` = `NULL`

- **Passo 2 (resolução de NULL):**
  ```sql
  UPDATE catalogo.composicao_itens
  SET ci_cmp_filho_id = (
      SELECT cmp_id FROM catalogo.composicoes
      WHERE cmp_fte_id = {sinapi_fte_id}
        AND cmp_edi_id = {edi_id}
        AND cmp_codigo = ci_codigo_pendente   -- campo temporário do Passo 1
  )
  WHERE ci_tipo_filho = 'COMPOSICAO'
    AND ci_cmp_filho_id IS NULL
  ```
  > Campo temporário `ci_codigo_pendente` é descartado após o Passo 2.
  > Alternativa sem campo extra: guardar `(ci_id, codigo_filha)` em memória durante o Passo 1.

**Upsert:** `ON CONFLICT (ci_cmp_id, ci_ins_id) DO NOTHING` para INSUMO;
`ON CONFLICT (ci_cmp_id, ci_cmp_filho_id) DO NOTHING` para COMPOSICAO

---

### catalogo.custos_composicao — SINAPI

**Arquivo:** `SINAPI_Referência_YYYY_MM.xlsx`
**Abas:** `CSD` (modalidade `'SD'`) + `CCD` (modalidade `'CD'`)
**Início dos dados:** linha 11

**Problema: código da composição está em fórmula HYPERLINK**

A coluna 2 (`Código da Composição`) contém uma fórmula Excel:
```
=HYPERLINK("#Analítico!B"&MATCH(104658,Analítico!$B:$B,0),TEXT(104658,"0"))
```

**Estratégia:** abrir o arquivo com `data_only=False` (openpyxl lê fórmulas).
Extrair o código com regex: `r'MATCH\((\d+)'` aplicado ao valor da célula.

Se a extração falhar (fórmula em formato diferente): fallback por posição de linha
(Analítico e CSD/CCD têm a mesma ordem de composições — match por índice).

**Colunas de custo por UF (54 colunas, posições 5 a 58):**
```
Cada UF tem um par de colunas:
  col ímpar → Custo (R$)   para aquela UF
  col par   → %AS          (porcentagem atribuída a SP)

Ordem das UFs: AC, AL, AM, AP, BA, CE, DF, ES, GO, MA, MG, MS, MT,
               PA, PB, PE, PI, PR, RJ, RN, RO, RR, RS, SC, SE, SP, TO
```

| Dado | Campo DB | Transformação |
|---|---|---|
| código extraído da fórmula (col 2) | `cc_cmp_id` | lookup `cmp_id` por `cmp_codigo` e `cmp_fte_id=SINAPI` |
| custo da coluna de UF | `cc_custo` | `float` — se `None` ou `0` com `%AS=None`, pular |
| `%AS` da coluna par | `cc_pct_sp` | `float` — pode ser `None` |
| nome da UF | `cc_uf` | `str` — ex: `'SP'`, `'MG'` |
| aba `CSD` ou `CCD` | `cc_modalidade` | `'SD'` ou `'CD'` |
| — | `cc_edi_id` | FK para a edição corrente |

**Upsert:** `ON CONFLICT (cc_cmp_id, cc_edi_id, cc_uf, cc_modalidade) DO UPDATE SET cc_custo = EXCLUDED.cc_custo, cc_pct_sp = EXCLUDED.cc_pct_sp`

---

### catalogo.sinapi_manutencoes

**Arquivo:** `SINAPI_Manutenções_YYYY_MM.xlsx`
**Aba:** `Manutenções`
**Início dos dados:** linha 7 (pular 4 metadados + 1 vazia + 1 cabeçalho)
**Linhas de dados:** ~30.562

| Coluna do Excel | Posição | Campo DB | Transformação |
|---|---|---|---|
| `Referência` | col 1 | _(derivado)_ `sm_edi_id` | `datetime.date` → lookup edição por `edi_mes_ref = data` |
| `Tipo` | col 2 | `sm_tipo` | `.strip().upper()` — `'INSUMO'` ou `'COMPOSICAO'` |
| `Código` | col 3 | `sm_codigo` | `str(int(valor))` |
| `Descrição` | col 4 | `sm_descricao` | `.strip().upper()` — pode ser `None` |
| `Manutenção` | col 5 | `sm_manutencao` | `.strip().upper()` — ex: `'ALTERAÇÃO DE DESCRIÇÃO'` |

**Operação:** INSERT apenas — `catalogo.sinapi_manutencoes` é append-only.
`ON CONFLICT DO NOTHING` (idempotente por edição + tipo + código).

> **Nota:** este arquivo é o mecanismo de atualização incremental do SINAPI.
> Import de manutenções pressupõe que a edição correspondente (`sm_edi_id`) já existe
> no banco, criada por um import de referência anterior ou manualmente.

---

## Tabelas não populadas por import

| Tabela | Motivo |
|---|---|
| `catalogo.cadernos` | Pipeline separado (PDFs); não faz parte do import de Excel |
| `catalogo.tipos_insumo` | Seed fixo em `easy_seed.sql`; não muda por import |
| `catalogo.fontes` | Seed fixo; SINAPI, CDHU etc. já estão no banco |
| `catalogo.edicoes` | Criada via tela/serviço antes do import (pré-requisito) |

---

## Lookup: catalogo.tipos_insumo

Mapeamento **SINAPI** → `tipos_insumo`:

| Texto em SINAPI | `ti_codigo` |
|---|---|
| `MATERIAL` | `MAT` |
| `MAO DE OBRA` | `MO` |
| `ENCARGOS COMPLEMENTARES` | `MO` |
| `EQUIPAMENTO (AQUISIÇÃO)` | `EQUIP_AQ` |
| `EQUIPAMENTO (LOCAÇÃO)` | `EQUIP_LOC` |
| `SERVIÇOS` | `SERV` |
| `ESPECIAIS` | `ESP` |

**Mapeamento CDHU** (por prefixo do código): vide tabela na seção `catalogo.insumos — CDHU`.

O lookup deve ser carregado em memória no início do parser:
```python
# Ambos os parsers usam esta mesma tabela
tipos = {row["ti_codigo"]: row["ti_id"] for row in SELECT ti_codigo, ti_id FROM catalogo.tipos_insumo}
```
