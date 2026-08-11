# Contrato — `catalogo.parametros_normativos`

**Papel.** Fonte única de **constante legal/política com vigência as-of** — valor que muda
**por normativa** (lei/decreto), não por edição nem por fonte. Hoje: `CPRB`, `JORNADA_H_MES`.

Não é um "metadata" genérico: entra aqui **só** parâmetro normativo versionado no tempo, com o
**registro do porquê** (`pn_motivo` = normativa; `pn_anotacoes` = histórico narrativo).

## Estrutura
- `pn_codigo` — identidade textual estável (`CPRB`, `JORNADA_H_MES`). UNIQUE.
- `pn_vigencias` — JSONB `[{"inicio":"AAAA-MM-DD","valor":N}, …]`. Agregado pequeno, sempre
  lido junto, raramente escrito → JSONB (sem tabela-filha).
- Auditoria em `pn_criado/atualizado_em/por`.

## Resolução as-of
`valor_asof(codigo, data_ref)` = a vigência com o **maior `inicio` ≤ `data_ref`** → `valor`.
Sem overlap, sem borda dupla. `None` se o código não existe ou nada aplica.
Implementação: `backend/modules/catalogo/parametros_service.py`.

## Parâmetros vigentes
### `CPRB` — Contribuição Previdenciária s/ Receita Bruta (construção, DESONERADO)
- Aplicada **só no regime DESONERADO** (o `bdi_service.cprb_default` resolve por `date(ano,1,1)`).
- Vigências: 2024=4,5 · 2025=3,6 · 2026=2,7 · 2027=1,8 · 2028=0 (Lei 14.973/2024, reoneração gradual).
- **Substitui** o hardcode `CPRB_DESONERADO_POR_ANO` do `bdi_service`.

### `JORNADA_H_MES` — jornada mensal padrão (h/mês)
- Fator de conversão MDO **H→MÊS = 1/valor**. Hoje **220** (CLT art. 58).
- Reforma trabalhista: quando virar lei, **acrescentar 1 vigência** `{inicio, 200}` — boletim
  antigo pega o fator da época pela **data da edição** (`edi_mes_ref`). Retroatividade automática.
- **Substitui** a coluna `cmm_qtd_h_mes` de `composicoes_mapeamento_mdo` (que ficou fonte-level, só o par).

## Consumidores
- `bdi_service.cprb_default` → `CPRB`.
- `conversao_mdo` / bancada (rotação MDO h→mês) → `JORNADA_H_MES`.

## Prod
Migração registrada em `z_scripts_apoio/migrations/2026-08-11_parametros_normativos_mdo.sql`
(cria a tabela + seed + enxuga `composicoes_mapeamento_mdo`). Não toca em ativo/orçamento.
