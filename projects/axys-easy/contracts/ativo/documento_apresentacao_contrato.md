# Apresentação do documento — contrato

**Status:** Vigente
**Data:** 2026-10-10 (nasceu do refino final da bancada, itens 12-13)
**Escopo:** como o orçamento se apresenta quando sai da app — em PDF e em Excel.
**Implementa:** `ativo.empreendimento_parametros`, `backend/modules/ativo/documento_config_service.py`,
`motor_pdf.py`, `motor_xlsx.py`.

> Este contrato governa a APRESENTAÇÃO. O que o orçamento *é* está em
> [`bancada_orcamento_contrato.md`](bancada_orcamento_contrato.md); o que ele guarda ao ser
> concluído, em [`bancada_orcamento_persistencia_contrato.md`](bancada_orcamento_persistencia_contrato.md).

---

## 1. Onde a configuração mora

Uma linha por empreendimento em `ativo.empreendimento_parametros` — casa única de tudo que decide
a forma do documento: estilo do timbrado, o que se oculta, a quem se dirige, local e data,
orientação de cada peça, gráficos, agrupamento e entrega.

O que é **por obra** (quais seções entram) mora em `ativo.ativos.atv_secoes`; o que é **do
documento** (capa, ofício, composições), em `epa_secoes`. O id do ativo nunca entra no JSON — ele
É a linha —, e apagar a obra leva as escolhas dela junto, sem cascata para escrever.

## 2. Os três parâmetros de arranjo, e como se cruzam

| parâmetro | valores | decide |
|---|---|---|
| **Agrupamento** | `ISOLADO` · `AGRUPADO` | a FORMA do consolidado |
| **Entrega** | `UNICO` · `ISOLADO` | um arquivo ou um zip numerado |
| **Execução** | `CONCOMITANTE` · `ISOLADA` | como os cronogramas de várias obras se somam |

O cruzamento dos dois primeiros define o documento:

| Agrupamento | Entrega | sai assim |
|---|---|---|
| ISOLADO | ISOLADO | um arquivo por obra — capa, sumário e peças de cada uma |
| ISOLADO | ÚNICO | **N orçamentos num envelope**: capa, ofício e quadro resumo do empreendimento por cima, e cada obra num BLOCO FECHADO aberto por contra-capa. **Sem repath** |
| AGRUPADO | — | **UM orçamento**: planilhas unificadas, capa e sumário únicos. **Com repath** |

**A regra que sustenta as duas situações:** no ISOLADO o resultado tem de ser o mesmo que gerar o
PDF de cada obra e grampear. Usar a regra de slot do unificado fazia o documento sair
INTERCALADO — Sintético(A), Sintético(B), Analítico(A)… —, que é a leitura de um orçamento único
sobre obras que não foram unificadas.

### 2.1 O escopo da OBRA

A tela oferece Gerar PDF / Exportar Excel por obra. Ali o ARRANJO deixa de existir — agrupamento,
tipo e execução não têm o que combinar — e sobra a APRESENTAÇÃO, que vale inteira. A **Entrega
desce um nível junto com o escopo**: no empreendimento `ISOLADO` separa por obra; na obra, separa
por documento.

## 3. O repath

No AGRUPADO a obra desce um nível: ela passa a ser `1.`, `2.`… e os itens dela descem junto — o
que era `1.1` na obra vira `1.1.1` no consolidado.

O repath **não é escolha**. Quem cita um item — a Memória de Cálculo, a "Aplicação no orçamento"
das Composições Próprias — cita o número que a planilha DESTE documento mostra. Citar outro seria
mandar o leitor procurar o que não está lá, e errado não se oferece como opção.

No arranjo `SEQUENCIAL` o nível 1 do repath É a obra, e o Quadro Resumo abre o bloco com ela (em
negrito, com o subtotal) antes dos níveis 2. No `POR_ETAPAS` o nível 1 é a ETAPA, que já reúne as
obras — ali não há obra a anunciar.

**Sem agrupar não há repath, e o quadro não pode fingir que há:** no ISOLADO a obra entra como
cabeçalho SEM número, e os níveis abaixo mantêm a numeração real do orçamento dela (os dois
começam no `1.0` deles).

## 4. A ordem canônica

```
capa → ofício de Apresentação → sumário →
resumo · ls · bdi · sintetico · analitico · proprias ·
cronograma · curvas · histogramas · memorias · caderno
```

Cada posição é um slot. No unificado o slot traz a versão unificada; no isolado, todas as obras.
O que **unifica** (a bancada agrupada responde pelo empreendimento): sintético, analítico,
próprias, cronograma, curvas, histogramas, caderno. O que **não unifica** (é por obra, e sai em
sequência dentro do slot): LS, BDI, memória — duas LS diferentes não viram uma.

O Excel segue a mesma sequência: CAPA, RESUMO, LS, BDI, Sintético, Insumos, Analítico, Curvas,
Cronograma, Histograma, Memórias.

## 5. Identificação e timbrado

Três estilos: **1** comercial compacto (só o timbrado), **2** comercial detalhado (Contratante ·
Objeto · Endereço), **3** institucional (o do 2 mais encargos/BDI e fontes-base com edição e
vigência). A faixa vem de `cabecalho_do_documento`, que é a MESMA fonte do PDF e do Excel —
documento não se apresenta de um jeito impresso e de outro na planilha.

Regras que a faixa fixa:

- **Objeto** com 2+ obras vira `{empreendimento} — {obra}`; descrição igual ao nome não se
  concatena (sai como eco "X — X").
- A coluna do valor se mede pelo rótulo mais largo presente, com piso de 19 mm.
- Estilo fixo (sem faixa): capa, contra-capa, ofício, sumário, Quadro Resumo, LS e BDI.

**Largura:** toda tabela de documento acompanha a régua do timbrado, de margem a margem. As
margens do `SimpleDocTemplate` descontam o padding do frame (6 pt), senão o corpo nasce 2,1 mm
para dentro e as tabelas estouram do outro lado.

## 6. Data de emissão

A data de emissão é a que o documento **declara** em Local e Data. Sem ela declarada, a linha não
sai. Nunca a data de hoje: carimbar o dia da geração faz o mesmo orçamento mudar de data a cada
clique, e documento que se re-data não serve para nada que se arquive.

Se a data declarada for anterior à vigência de alguma fonte-base, a tela avisa e deixa seguir —
retroagir um documento é prática corrente, então é conferência, não trava.

**Código interno** da obra sai qualificado pelo do empreendimento: `251.49-001`. Sem código
próprio, a obra é a primeira (`{empreendimento}-001`). A comparação ignora separadores.

## 7. Assinatura

Todo documento é assinado, **uma vez, no pé da última folha** — nunca por página. Local e data
acima, tudo alinhado à direita. O bloco é indivisível: vai inteiro, ou inteiro para a página
seguinte.

Não assinam: capa, contra-capa e sumário. O ofício traz a sua no corpo. As memórias de uma obra
são um bloco — só a última assina.

## 8. Gráficos

A Curva S, as barras do histograma e o Pareto da ABC são ILUSTRAÇÃO, não a peça: quem analisa um
orçamento lê a tabela. Entram a pedido (um parâmetro por documento), e por isso nascem `FALSE`.

## 9. O que o Excel acrescenta ao contrato

A planilha é amarrada por FÓRMULAS — ela recalcula. Então ela tem de chegar no mesmo número que o
PDF entregue junto, e duas regras garantem isso:

- **`TRUNC` sobre produto arredonda o ruído antes:** `TRUNC(ROUND(x; 6); 2)`. O Excel multiplica em
  IEEE 754, e `441,88 × 12` dá `5302,5599999999995` — truncado, 5302,55 contra os 5302,56 que o
  app soma em Decimal. Um centavo por linha.
- **A Curva ABC de Insumos NÃO se amarra à aba Insumos.** Ela agrega: o mesmo insumo aparece em
  várias composições com preço efetivo diferente em cada uma (conversão de LS, %AS, rotação de
  regime), e o unitário da linha é o PONDERADO do conjunto. Um `VLOOKUP` traria um preço só, que
  não representa o conjunto — e a curva deixaria de somar o que o orçamento soma. A Curva de
  Serviços continua amarrada ao Analítico, onde a linha é um serviço e a referência é fiel.

Ao renomear as abas no fim da montagem, as referências dos **gráficos** são reescritas junto com
as das células — senão cada série aponta para uma aba que já não existe e o Excel abre acusando
links quebrados.

## 10. Sanidade

`z_scripts_apoio/sanidade/documento_pdf.py` mede as regras acima **no PDF gerado** (51 checks), e
`excel_valores.py` confronta o que o Excel calcularia com o que o app calcula (o openpyxl guarda a
fórmula, não o resultado). Regra que este contrato fixa e que não tem check é regra que volta a
quebrar.
