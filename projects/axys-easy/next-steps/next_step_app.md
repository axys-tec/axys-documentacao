# AxysEasy — Próximo Passo: Import de Catálogos de Preços

> Gerado em: 31/05/2026
> Contexto: decisões de arquitetura tomadas antes da implementação dos parsers e telas de import.

---

## 1. Contexto e decisões

### O que é o módulo de import

O import é o mecanismo pelo qual as fontes de referência de preços (SINAPI, CDHU e outras) têm seus dados carregados no banco. Sem import, as tabelas `catalogo.*` ficam vazias e nenhum orçamento pode ser montado.

### Fontes suportadas — três modos de entrada

| Modo | Fonte | Parser | Arquivo(s) |
|---|---|---|---|
| **SINAPI** | Caixa Econômica Federal | Nativo | `SINAPI_Referência_YYYY_MM.xlsx` + `SINAPI_Manutenções_YYYY_MM.xlsx` |
| **CDHU** | Companhia de Desenvolvimento Habitacional e Urbano (SP) | Nativo | `insumos.VVV.xlsx` · `composicao.VVV.xlsx` · `servicos.VVV-sd.xlsx` |
| **OUTRA** | Qualquer fonte regional, estadual ou própria | Template CSV/Excel | Template baixado da app, preenchido e subido |

**Racional do híbrido:** SINAPI e CDHU são obrigatórias por lei em obras públicas e mantêm estrutura estável. Parsers nativos eliminam a camada de conversão manual. O template é a porta de entrada para fontes desconhecidas — e é, internamente, o mesmo formato normalizado que os parsers produzem.

---

## 2. Seções de import e dependências

O import é dividido em seções independentes, executáveis separadamente, com dependências de dados que o serviço valida antes de executar cada passo.

```
Layer 0  ─  Edição           pré-requisito: fte_id deve existir em `catalogo.fontes`
            (criada ou selecionada antes de qualquer import)

Layer 1  ─  Insumos          popula `catalogo.insumos` + `catalogo.precos_insumo`
            depende de: edição

Layer 2  ─  Composições+Grupos popula `catalogo.grupos` + `catalogo.subgrupos` +
                                      `catalogo.composicoes` + `catalogo.composicao_itens`
            depende de: insumos (itens referenciam `ins_id`)

Layer 3  ─  Preços de Composição popula `catalogo.custos_composicao`
            depende de: composições

Layer 4  ─  Manutenções      popula `catalogo.sinapi_manutencoes`
            SINAPI only — operação de patch mensal, não de import inicial
            depende de: edição anterior no banco

Layer 5  ─  Cadernos         popula `catalogo.cadernos`
            pipeline separado (PDFs), não bloqueia os demais layers
```

**Regra:** o serviço de import de cada layer verifica se o layer anterior tem dados para a edição/fonte em questão. Se não tiver, recusa com mensagem clara.

---

## 3. Estratégia de parser

### CDHU — parser stateful (rastreia posição)

A estrutura hierárquica está embutida em um único arquivo (`composicao.VVV.xlsx`). Não há coluna de grupo/subgrupo — o nível é determinado pelo formato do código:

```
Para cada linha do arquivo composicao.VVV.xlsx:

  código matches /^\d{2}$/            → Grupo
    → salvar grupo corrente

  código matches /^\d{2}\.\d{2}$/     → Subgrupo
    → salvar subgrupo corrente (vinculado ao grupo corrente)

  código matches /^\d{2}\.\d{2}\.\d{3}$/   → Composição (CPU)
    → criar entrada em catalogo.composicoes (vinculada ao subgrupo corrente)
    → zerar lista de itens e contador de ordem

  código matches /^[A-Z]\.\d{2}\.\d{3}\.\d{6}$/ → Item da composição
    → criar entrada em catalogo.composicao_itens (vinculada à composição corrente)
    → incrementar contador de ordem
```

### SINAPI — parser de contexto repetido

No `Analítico`, grupo e código de composição se repetem em cada linha. A discriminação é pela coluna `Tipo Item`:

```
Para cada linha da aba Analítico:

  Tipo Item == None (ou vazio)   → header de composição
    → criar/atualizar catalogo.composicoes
    → verificar/criar subgrupo pelo texto do Grupo

  Tipo Item == 'INSUMO'          → item tipo insumo
    → criar catalogo.composicao_itens com ci_tipo_filho='INSUMO'
    → ci_ins_id = lookup por ins_codigo na edição corrente

  Tipo Item == 'COMPOSICAO'      → item tipo sub-composição
    → criar catalogo.composicao_itens com ci_tipo_filho='COMPOSICAO'
    → ci_cmp_filho_id = lookup por cmp_codigo (pode ser NULL no Passo 1)
```

### Resolução de sub-composições recursivas (SINAPI — dois passos)

Composições SINAPI podem referenciar outras composições como itens (ex: `SERVENTE COM ENCARGOS COMPLEMENTARES` é uma composição usada dentro de outra composição).

```
Passo 1 — Import estrutural:
  Importar todos os cabeçalhos de composição (catalogo.composicoes)
  Importar todos os itens:
    - INSUMO → ci_ins_id resolvido imediatamente
    - COMPOSICAO → ci_cmp_filho_id = NULL (composição filha pode ainda não existir)

Passo 2 — Resolução de referências:
  Para cada catalogo.composicao_itens onde ci_tipo_filho='COMPOSICAO' e ci_cmp_filho_id IS NULL:
    ci_cmp_filho_id = lookup por código na aba Analítico
    UPDATE catalogo.composicao_itens SET ci_cmp_filho_id = ...
```

---

## 4. Localização dos parsers no projeto

```
backend/core/import_cpu/
  __init__.py
  base.py              ← interface comum: ImportResult, ImportConfig
  parser_cdhu.py       ← parsers CDHU (insumos, composicoes, servicos)
  parser_sinapi.py     ← parsers SINAPI (insumos, analitico, csd_ccd, manutencoes)
  parser_template.py   ← parser do template CSV/Excel genérico
  service_import.py    ← orquestra layers, valida dependências, chama parsers
```

---

## 5. Próximo passo de implementação

**O que fazer primeiro:**

1. Implementar `ImportResult` e `ImportConfig` em `base.py` (interface comum)
2. Implementar `parser_cdhu.py` — começando por `parse_insumos()` (arquivo mais simples e flat)
3. Testar `parse_insumos()` contra `z_search_repos/fontes-base/cdhu/insumos.201.xlsx`
4. Implementar `parse_composicoes()` CDHU (parser stateful)
5. Implementar `parser_sinapi.py` começando por `parse_analitico()` (fonte canônica de composições)
6. Implementar `parse_insumos_sinapi()` (ISD + ICD)
7. Implementar `parse_custos_sinapi()` (CSD + CCD) com extração de código da fórmula HYPERLINK
8. Montar `service_import.py` orquestrando os layers com validação de dependências
9. Tela de import (ver `PROMPT_NOVA_TELA.md` para padrão canônico)

**Arquivo de referência dos dados de teste:**
```
z_search_repos/fontes-base/cdhu/   ← arquivos CDHU versão 201
z_search_repos/fontes-base/sinapi/ ← arquivos SINAPI ABR/2026
```

**Documentação de mapeamento detalhado:** [next_step_map.md](next_step_map.md) — tabelas, campos, transformações, parsers

---

## 6. Como Informar "Next Step" no Novo Chat

Ao abrir um chat para continuar este trabalho, **inclua no início da mensagem:**

```
next_step: 
  - status: [em_andamento|pendente|completo]
  - fase: [Layer 0 Edição | Layer 1 Insumos | Layer 2 Composições | Layer 3 Custos | Layer 4 Manutenções | Layer 5 Cadernos]
  - ultimo_arquivo: [arquivo que estava trabalhando]
  - contexto: [linha 1-2 do que faltava fazer]
```

**Exemplo:**
```
next_step:
  - status: em_andamento
  - fase: Layer 2 Composições
  - ultimo_arquivo: parser_cdhu.py
  - contexto: Implementar parse_composicoes() stateful para CDHU — detectar níveis por regex de código
```

Isso permite que Claude remonte o contexto automaticamente sem precisar ler toda conversa anterior.
