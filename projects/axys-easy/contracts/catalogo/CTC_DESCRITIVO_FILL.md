# Contrato — Preenchimento do descritivo do CTC (IA)

Governa a geração das seções **1) Forma de medição** e **2) Descritivo do que remunera** do CTC (AxysDoc)
pela IA. Ferramenta: `z_scripts_apoio/ctc_fill.py`. Doutrina de estilo + dataset: `fine_tuning_cpus/descritivo/`.

## Princípios
1. **Pipeline decoupla IA↔banco:** `ctc_pull` (DB/R2→`.md`) → `ctc_fill` (edita `.md`) → `put_md` (`.md`→
   `cmp_descritivo`). Idempotente (só «Em revisão»); `--force` recalibra. A IA **não escreve no banco**.
2. **Determinismo estrutural:** o CÓDIGO monta a estrutura do §2 (frame por classe MAT/MO/EQP, mão de obra,
   contrações). O modelo só preenche o que faz bem. Nada de "esperar o modelo obedecer" a estrutura.
3. **Fiel à composição, sem invenção:** nada de norma (NBR/ABNT), exclusão ("não remunera"), nem item fora
   do [c]. Sujeito **"A composição remunera"** (nunca "O preço"/"O serviço remunera").
4. **Provider:** OpenAI `gpt-4o-mini` (não-raciocínio), `temperature=0` + `seed` (o mais idempotente que a
   API dá). Fallback multi-IA é trivial (mesma interface) — só NÃO fine-tunar (trava no fornecedor).
5. **Validadores determinísticos** (rejeita → fica «Em revisão»): `;`, norma, exclusão, CAIXA ALTA,
   comparação **sem acento** (fonte SINAPI é sem acento/maiúscula; a IA acentua/minusculiza).

## Duas versões do §2
- **v0 ENUMERADO (CONGELADO):** §2 nomeia TODOS os itens. Bom quando o descritivo viaja SOZINHO. Congelado
  porque, no orçamento, a **composição (§3) acompanha** → enumerar SKU repete a §3 e perde objetividade em
  CPU grande. Preservado em `fine_tuning_cpus/descritivo/ctc_fill_v0_enumerado.py` (+ `CONGELAMENTO_v0.md`).
- **v1 ENXUTO (VIGENTE):** §2 objetivo — "A composição remunera o fornecimento de material, mão de obra e
  encargos complementares para a execução {do serviço}, {enriquecimento inerente, do caderno, sem inventar}".
  O **detalhe SKU-a-SKU está na composição (§3)**, que é a fonte auditável (item×coef×preço).

## §1 (invariante nas duas)
"Será medido por {unidade POR EXTENSO com sigla, ex. metro quadrado (M2)}, {critério da seção 5 do [b]}."
Termina em ponto. Nunca só a sigla ("M2, METRO QUADRADO") nem só a unidade.

## Coluna **Grupo** — classe CANÔNICA por item (Fase 2, "fine-tuning dentro da CPU")
A tabela `[c]`/§3 ganha a coluna **Grupo** com a classificação canônica do banco (não a heurística por
nome, que errava **6,4%** — MO/ENC_COMP viravam MAT):
- **INSUMO** → `insumos.ins_ti_id` → `insumos_tipo.ti_nome` (Material · Mão de Obra · Encargos
  Complementares · Equipamento — Aquisição/Locação · Serviço · Especiais · Não Classificado).
- **COMPOSICAO** → `composicoes.cmp_sub_id` → `composicoes_subgrupos.sub_descricao` (VERBATIM). Semântica:
  `LIVRO SINAPI: CÁLCULOS E PARÂMETROS` = **MDO ou indiretos de MDO** (encargos, EPI, DSR, capacitação);
  `CUSTOS HORÁRIOS…` / `DEPRECIAÇÃO, JUROS…` = **equipamento**; demais (ARGAMASSAS, CONCRETO…) = sub-serviço.
- Formato: `| Tipo | Código | Descrição | Grupo | Unid. | Coef. |`. Injeta em prompt `[c]` E doc §3 (publicado).
- **`_montar_remunera` lê o Grupo** (`_classe_do_grupo`) em vez de adivinhar; sem Grupo → fallback heurístico.
- **req_hash NÃO muda**: o hash (`_conteudo_req`) usa a tabela SEM Grupo — Grupo é metadado derivado, não
  identidade. Ao mexer na app, materializar §3/[c] com `_tabela_grupo` e manter `_tabela` (5 col) p/ o hash.

### Ferramental (fonte única de layout: `_ctc_paths.py` — repo local ESPELHA o R2 `ctc/{doc,prompt,_old}`)
- `ctc_pull.py [fonte] [--force]` — universo = todas CPUs com CTC (vigente + `_old` versionados por
  `req_hash[:12]`). Sem `--force` = só o que falta local (preserva reparos). CTC_DIR por fonte.
- `ctc_enriquece.py <fonte> [--apply]` — injeta a coluna Grupo (one-off local). Idempotente.
- `ctc_repara.py [--apply] [--em-revisao] [--familia]` — conserta §1/§2 (custo-horário determinístico +
  vazamento `[b]` + pole). `--em-revisao` = só não-preenchidos (p/ `_old`).
- `put_md.py <fonte>` — FONTE-LEVEL: grava na versão certa de `cmp_descritivo` por `req_hash`
  (`{cod}.md`→atual, `{cod}_{ref}.md`→`_old`) e sobe pro path-espelho.

### Diferido (~próximo import): app `montar_prompt`/doc materializa com Grupo (`_tabela_grupo`) + tela de
curadoria + IA_auto. Até lá, o enriquecimento é one-off local (`ctc_enriquece`).
