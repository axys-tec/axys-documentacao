# Unicidade de Fontes/BDI/LS por empreendimento — contrato (modelo 2)

> **STATUS: IMPLEMENTADO em dev (2026-10-21).** Modelo 2 ("propaga + trava"), aprovado pelo Renan.
> Objetivo: matar o retrabalho de configurar N orçamentos IGUAIS num empreendimento, **sem nenhum
> preço mudando em silêncio**. A unicidade deixou de ser "de onde se LÊ" e virou "quem pode EDITAR".

## 1. As 3 flags (no empreendimento)
`empreendimentos.emp_fontes_unica / emp_bdi_unico / emp_ls_unico` (BOOLEAN DEFAULT FALSE no schema).
Uma por pauta, independentes. São **decisão de largada no cadastro** do empreendimento e **nascem
MARCADAS** (`criar_empreendimento(..., fontes_unica=True, bdi_unico=True, ls_unico=True)`), porque o
comum é único. O DEFAULT do schema continua FALSE → **empreendimentos antigos ficam como estão**
(migration é no-op).

## 2. Princípio (modelo 2)
- A **bancada SEMPRE lê do ativo** — um caminho único de leitura (`aor_de`, sem resolvedor condicional).
- **Flag ON** = a pauta é definida na **config-MESTRE** do empreendimento; cada ativo recebe uma
  **cópia** gravada nele; a edição da pauta **no ativo fica travada**; editar a mestre **propaga p/
  todos os ativos + reprecifica**.
- **Ativo novo nasce DERIVADO** (cópia da mestre) e já travado nas pautas únicas.
- **Desligar** = só **destrava** o ativo; valores e preços atuais **permanecem** (nada muda sozinho).
- **Religar** = só se os ativos forem **idênticos na pauta (percentual E composição)**; senão recusa,
  com "ver divergências" (expande o que difere por ativo). **Não há "descartar dados".**

## 3. Armazenamento (XOR, sem schema novo)
`ativo_orcamento` é `ao_atv_id` **XOR** `ao_emp_id` (CHECK `ck_ao_escopo`). A MESTRE do empreendimento
é o orçamento `ao_emp_id` (revisão resolvida por `revisao_vigente_emp`/`aor_de_emp`), com as mesmas
tabelas-filhas (`ativo_orcamento_parametros/bdi/ls`). O ativo guarda a **cópia** nas suas próprias
tabelas-filhas. Nenhuma coluna nova; nenhuma migration.

## 4. Onde mora cada coisa (código)
- **Leitura:** sempre `aor_de(cur, atv_id)` (revertido o antigo `aor_cfg`). `orcamento_fonte.py`.
- **Propagação + reprice:** `orcamento_heranca.propagar_pauta` (mestre→cada ativo, via `_seed`) e
  `reprecificar_do_emp` (todos os ativos; guardas de `_capturar_custo_unit` valem — preço fixado e
  composição descontinuada com preço gravado **não** são apagados).
- **Escrita da mestre:** `salvar_fonte_emp` / `salvar_bdi_emp` / `deletar_bdi_emp` / `salvar_ls_emp` /
  `semear_ls_emp` — gravam na mestre (`aor_de_emp`) → `propagar_pauta` → `reprecificar_do_emp`. Núcleos
  keyed-por-aor compartilhados com o ativo (`_gravar_params`/`_gravar_bdi`/`_gravar_ls`/`_semear_ls`).
- **Trava do ativo:** `salvar_fonte_ativo`/`salvar_bdi`/`salvar_ls`/`semear_ls` e `deletar_bdi`
  recusam com `{success:False, locked:True}` quando `pauta_herdada`. A UI também bloqueia (ver §5).
- **Nascer derivado:** `orcamento_heranca.derivar_ativo` dentro de `criar_ativo` (mesma transação).
- **Ligar/desligar:** `set_heranca` (ligar exige `not _divergente`; semeia a mestre do ativo[0] se
  vazia + propaga; **não** reprecifica, pois idêntico. desligar só seta a flag). `divergencias(...)`
  dá o detalhe por ativo p/ o modal.

## 5. UI
- **Cadastro** (`/empreendimentos`, modal "Novo empreendimento"): 3 checkboxes "Configuração única",
  marcados por padrão → enviados no POST.
- **Tab do empreendimento** (`/empreendimentos/{id}`): seção "Premissas do empreendimento" com as 3
  flags + botão Editar → `/empreendimentos/{id}/premissas`. Ligar/desligar: `easy_emp_heranca.js`
  (desligar avisa que destrava sem mudar valor; ligar divergente abre modal com "ver divergências").
- **Editor da mestre:** `/empreendimentos/{id}/premissas` (Fontes-Base), `/empreendimentos/{id}/bdi`,
  `/empreendimentos/{id}/ls` — rendem os MESMOS templates do ativo em `emp_mode` (sidebar
  `sidebar_premissas_emp.html`). O front compartilhado (`easy_workspace.js` fbl, `easy_bdi_editor.js`,
  `easy_ls_editor.js`) lê a base de API de `data-fbl-api`/`data-api-base` com **fallback
  `/api/ativos/{id}`** — sem o atributo, comportamento idêntico ao de hoje. Funciona com ZERO ativos.
- **No ativo** (`/empreendimentos/{emp}/ativos/{atv}/orca/R00/fontes`): a pauta única vira read-only
  com "Editar no empreendimento". A GET de `/api/ativos/{id}/fonte|bdi|ls` devolve `locked`.

## 6. Invariantes
- Um caminho único de leitura (bancada = ativo). A flag decide EDIÇÃO, não leitura.
- Nada muda em silêncio: desligar não reprecifica; editar a mestre reprecifica conscientemente
  (impacto por total + guardas de fixado/descontinuado).
- Religar exige igualdade real (percentual + composição). Sem descartar dados.
