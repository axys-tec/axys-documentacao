# Contrato — Preenchimento do descritivo do CTC (IA)

Governa a geração das seções **1) Forma de medição** e **2) Descritivo do que remunera** do CTC (AxysDoc)
pela IA. Motor único: `backend/core/import_cpu/ctc_fill_core.gerar_descritivo`, chamado pelo estágio Documentos do
import (`import_service._preencher_descritivos`) e pelo refino em massa (`z_scripts_apoio/ctc/ctc_refina.py`).
Doutrina de estilo + dataset: `fine_tuning_cpus/descritivo/`.

## Princípios
1. **No import, sempre (29/10/2026):** o estágio Documentos preenche as versões `em_revisao` da fonte
   (delta:hash). A IA devolve texto; quem grava é o import (`gravar_descritivo`, `origem = IA_auto`).
   Não preencheu → o estágio vai a `erro` com a causa e a retentativa pega só o que falta. O ciclo
   manual `ctc_pull`→`put_md` (modo `IA_local`) foi extinto — plano `next-steps/final_associacoes.md` §3.
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

### Ferramental
O ferramental local do ciclo manual (`_ctc_paths`, `ctc_pull`, `ctc_push`, `ctc_verifica`, `ctc_reconcilia`,
`put_md`, `get_md`) saiu com o `IA_local` em 29/10/2026. Fica `ctc_refina.py` (refino em massa pelo motor
único) — ver `z_scripts_apoio/ctc/instrucao_ctc.md`.
