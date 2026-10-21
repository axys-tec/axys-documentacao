# Herança de Fontes/BDI/LS por empreendimento — contrato (A APROVAR)

> **STATUS: PROPOSTA — aguardando aprovação do Renan.** Nenhum schema/código escrito ainda.
> Objetivo: matar o retrabalho de configurar N orçamentos IGUAIS num empreendimento, SEM o risco que
> assustou (nada automático, nada destrutivo, nasce tudo desligado).

## 1. As 3 flags (no empreendimento)
Na tab do empreendimento (`/empreendimentos/{id}`), **depois de Responsável Técnico**, três flags —
uma por pauta, independentes:
- `Fontes/Edição única por empreendimento`
- `BDI único por empreendimento`
- `LS/Regime único por empreendimento`

**Nascem FALSE** (migration). Os ativos de hoje já estão preenchidos e variados → ligar por default
quebraria. Depois, uma varredura (§6) liga onde os ativos de fato repetem.

> Reconcilia o precedente de 05/10 ("fonte no empreendimento é errada por natureza"): aqui é **opt-in
> por pauta e por empreendimento**, e só liga onde a realidade já é idêntica. Empreendimento
> heterogêneo fica FALSE (continua certo); homogêneo vira único (mata o retrabalho).

## 2. UI
- Cada flag é uma **seção expansível** no mesmo padrão visual de "Ativos vinculados"/"Responsáveis
  técnicos".
- Ligar a flag **expande** o form **idêntico ao do ativo** `/ativos/{id}/orca/R00/fontes` — só que
  editando a config DO EMPREENDIMENTO. Aparece só a pauta flagada.
- No ATIVO, a pauta flagada fica **read-only**, exibindo o que vem do empreendimento (com um aviso
  "definido no empreendimento"). As demais pautas (não flagadas) seguem editáveis no ativo, como hoje.

## 3. Comportamento (não-destrutivo)
- Flag ON → o ativo **lê** a config da pauta do empreendimento; a config própria do ativo **fica
  intacta, só não é lida** enquanto ligada. Desligar → o ativo volta a ler a sua (nada se perdeu).
- Preço por-linha (BDI/LS gravados na linha do orçamento): sob herança, **repetem** os do
  empreendimento; sem herança, cada ativo aplica o seu. Todo recálculo passa pelo gatilho único já
  existente (`converter_precos`), que reprecifica a bancada (rotação de regime inclusa).

## 4. Como (proposta de implementação — a validar)
Reusar TUDO (forms, serviços, resolvedores) via uma **"revisão de configuração do empreendimento"**:
um portador de config (fontes/BDI/LS) pendurado no empreendimento, gravado pelos MESMOS
`salvar_fonte_ativo`/`salvar_bdi`/`salvar_ls` (por isso o form é idêntico, de graça).
- **Resolução:** quando a flag da pauta está ligada, o resolvedor do ativo lê a config do
  empreendimento em vez da própria (`listar_fonte_ativo`/`listar_bdis`/`get_ls` e os helpers de LS/
  regime passam a aceitar a origem empreendimento). **Nenhuma cópia, nenhum overwrite.**
- **BDI por-linha funciona:** `ati_bdi_id` referencia `ativo_orcamento_bdi(abd_id)` e `abd_id` é global
  → a linha pode apontar um BDI do empreendimento sem quebrar a FK. A escolha por-linha (Normal ×
  Reduzido) continua, apontando para o conjunto do empreendimento.

## 5. Schema (mínimo, a aprovar)
- 3 flags no empreendimento (ex.: `empreendimento.*_unico` BOOLEAN DEFAULT FALSE, ou JSONB 1×1).
- Um portador de config do empreendimento (revisão de config) — ou tabelas-espelho emp-level.
  (Decido o formato exato na aprovação; o critério é **reaproveitar os serviços do ativo sem fork**.)
- Default FALSE em tudo → **migration não muda nada no ar**.

## 6. Varredura (depois, fora desta entrega)
Script que percorre cada empreendimento e, por pauta, compara a config dos ativos: **idêntica em
todos → liga a flag** (semeando a config do empreendimento a partir dos ativos) ; **divergente →
deixa FALSE**. Nunca automático sem o diagnóstico de igualdade.

## 7. Invariantes
- Nasce tudo FALSE; nada muda no ar.
- Nada é apagado nem sobrescrito: ligar = "ler de cima"; desligar = "ler o seu" (preservado).
- Não há reset de BDI por-linha: a linha aponta pro BDI do empreendimento (FK permite).
- Fontes só fica única por escolha explícita + confirmação de igualdade (§6), nunca por natureza.
