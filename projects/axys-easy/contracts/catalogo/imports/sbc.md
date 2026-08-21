# Contrato de importação — SBC

## 1. Princípio

O schema `catalogo` emula o cálculo da fonte-base. Singularidades de
arredondamento pertencem ao adaptador da fonte e não alteram o critério
transversal usado pelo orçamento quando há transformação.

- catálogo e bancada sem transformação: custo calculado pelo método SBC;
- bancada com rotação de LS, MDO, insumos ou regime: `TRUNC/TRUNC/TRUNC`, regra
  uniforme do orçamento;
- custo divulgado permanece preservado como dado da fonte e é conferido contra
  o custo emulado.

## 2. Incidência de leis sociais

Tipo do insumo e incidência de LS são dimensões distintas. A importação deve
preservar o tipo cadastral e possuir decisão auditável de incidência para a
memória SBC. Exemplos comprovados em 08/2026:

- adicional de insalubridade: `ENC_COMP`, mas integra a base de LS;
- `91117 ISOLADOR`: função humana, mas a linha publicada não integra a base de
  LS nas CPUs verificadas.

## 3. Método SBC observado na publicação

```text
linha_pelada = ROUND(preço_pelado × coeficiente, 2)
base_mo      = Σ linha_pelada dos itens com incidência
encargos     = ROUND(base_mo × LS%, 2)
total_mo     = base_mo + encargos
total_cpu    = Σ linhas sem incidência + total_mo
```

## 4. Modelo D — convergência por centavos

O modelo D oferece memória carregada por linha sem perder o total nativo:

```text
unitário_easy = preço_pelado × (1 + LS%)            # precisão completa
linha_easy    = ROUND(unitário_easy × coeficiente, 2)
diferença     = total_mo_sbc - Σ linhas_easy_mo
```

O unitário carregado pode ser exibido com duas casas no front, mas o valor
formatado não retorna ao cálculo. A persistência/cálculo conserva todas as
casas disponíveis; existe um único arredondamento monetário, no total da linha.

A diferença contra o total divulgado é convertida para centavos inteiros e
distribuída por todas as linhas de valor positivo da composição. Linhas não-MO
partem do total de linha publicado, pois o SBC pode exibir unitário `0,00` e
linha `0,01` (precisão interna não exposta):

1. `q = trunc(|centavos| / quantidade_de_linhas_positivas)`;
2. todas as linhas recebem `sinal × q` centavos;
3. o resto recebe `sinal × R$ 0,01`, da maior linha para a menor;
4. a soma ajustada deve ser exatamente o total divulgado da CPU;
5. cada ajuste fica registrado por item para auditoria;
6. preço, coeficiente e total original da linha não são sobrescritos.

Uma diferença de apenas um centavo necessariamente afeta uma única linha se as
linhas forem mantidas em duas casas decimais. Fora dessa impossibilidade
aritmética, o ajuste não deve ser concentrado em um único item.

O modelo D é emulação da fonte no catálogo. Ele não substitui o perfil
`TRUNC/TRUNC/TRUNC` da bancada quando ocorre transformação.

O executor pré-importação `z_scripts_apoio/sbc/modelo_d_regional.py` lê a
partição autossuficiente da UF e grava memória separada em
`modelo_d_ufs/<UF>`. É proibido aplicar receita, coeficiente ou LS de SPO sobre
preços de outra praça. A regressão SPO/`2026_07` converge 12.443/12.443 CPUs,
sem incompletas e com ajuste máximo de 2 centavos por linha.

## 5. Edição e data-base

A edição comercial SBC é o mês imediatamente anterior à data-base mostrada nos
formulários de preços e composições:

```text
edição 2025_01 → DTBASE 20250201
edição 2026_07 → DTBASE 20260801
```

O import deve persistir as duas informações e nunca inferir que `01/08` é edição
de agosto. O CUB é consultado pelo próprio mês-base da edição.

## 6. Pacote pré-importação

O coletor oficial é `z_scripts_apoio/sbc/coletar_edicoes.py`. Cada diretório
`edicoes/AAAA_MM` contém:

- `insumos.csv`, com uma praça por UF e exatamente 27 preços;
- `composicoes_referencia_spo.csv` e `composicoes_itens_referencia_spo.csv`,
  usados somente como índices comparativos de São Paulo;
- `composicoes_ufs/<UF>/composicoes.csv`, com identidade, unidade, total e LS
  divulgados na praça;
- `composicoes_ufs/<UF>/itens.csv.gz`, com tipo, identidade, unidade,
  coeficiente, preço unitário e total de linha divulgados na praça;
- `documentos/cub.csv` e o PDF público de critérios;
- `manifest.json`, com escopo, contagens e SHA-256.

Há exatamente uma praça por UF, sem Ribeirão Preto, e cada partição regional é
autossuficiente. Na edição vigente, a comparação integral entre `SPO`, `RJO`,
`BHE`, `MNS` e `PAE` encontrou identidade/ordem iguais, mas milhares de
coeficientes e praticamente todos os custos variaram. Essa igualdade estrutural
não é presumida para outras edições. Por isso nenhum campo da receita é herdado
da referência SPO. Ausência na matriz de
insumos não apaga o preço/total publicado no detalhe da composição; ambos são
evidências distintas. Credenciais e GUIDs não podem integrar o pacote.

A recaptura serial de `2025_01` confirmou a necessidade: `AC/RBO` possui 12.434
CPUs/83.373 linhas contra 12.433/83.372 em SPO, com uma identidade de CPU
divergente quando comparada por código.
No fechamento serial das 27 praças, 24 UFs continham a CPU regional adicional
`16580`; apenas ES, RJ e SP coincidiam estruturalmente com a referência.

A captura de insumos e composições é obrigatoriamente serial e protegida pelo
mesmo lock entre processos. O WebLink mistura `LOC/DTBASE` entre sessões concorrentes da mesma
credencial; a CPU `53085` demonstrou conteúdo de `AC/RBO` sendo devolvido em um
checkpoint rotulado `AL/MCO`. Arquivo produzido sob concorrência é inválido,
mesmo quando sua contagem fecha, e não pode entrar no import.
Isso também invalida matrizes de insumo produzidas em paralelo até sua
substituição por recaptura serial confirmada página a página.

A validação estrutural inicial de `2025_01..2026_07`, executada em 19/08/2026,
foi supersedida em 20/08/2026 após a prova de contaminação entre sessões. Seus
arquivos paralelos não são publicáveis. O lote só volta ao estado validado após
recaptura serial integral e aprovação de
`z_scripts_apoio/sbc/validar_edicoes.py`.

## 7. Analíticos CUB

Os três PDFs analíticos ligados pela tela CUB são empacotados somente na edição
vigente da captura, pois usam URLs estáticas e não declaram competência interna.
O parser `cub_analiticos.py` gera projetos, CPUs e itens rastreáveis por
documento/página, preservando quantidades, índices e preços literais.

A comparação de área entre tela e PDF é obrigatória e não corrige a fonte. Na
captura de 19/08/2026, o multifamiliar divergiu em `5,00 m²` (tela `5.983,73`,
PDF `5.988,73`) e a tela não informou a área do galpão (`1.000,00 m²` no PDF).
Esses estados são dados de auditoria para publicação futura, não erros a serem
silenciosamente normalizados.
