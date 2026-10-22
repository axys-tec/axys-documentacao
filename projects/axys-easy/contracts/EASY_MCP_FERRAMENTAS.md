# Easy MCP — apêndice: as ferramentas

> GERADO de `backend/api/mcp/conteudo/instrucoes_ia.md` + o registro das ferramentas, por
> `.venv/bin/python -m backend.api.mcp.instrucoes --apendice`. Não edite à mão: cure o texto em
> `instrucoes_ia.md` e regenere (o teste `test_instrucoes` acusa apêndice desatualizado).

Contrato: [EASY_MCP_CONTRATO.md](EASY_MCP_CONTRATO.md) §4 (categorias, módulos, protocolo).

Confirmação (só prévias): **livre** = a IA aplica e informa · **tarefa** = uma autorização do usuário
vale para a tarefa inteira · **sempre** = confirmação a cada plano. A ferramenta pode subir o nível
pelo conteúdo (estrutura com remover; composição fora do orçamento).

| Ferramenta | Categoria | Confirmação | Módulo | O que é |
|---|---|---|---|---|
| [`easy_guia`](#easy_guia) | Leitura |  | plataforma | Guia de operação |
| [`easy_sobre`](#easy_sobre) | Leitura |  | plataforma | Sobre o Easy e o ecossistema |
| [`easy_meu_acesso`](#easy_meu_acesso) | Leitura |  | plataforma | Meu acesso ao Easy |
| [`easy_listar_empreendimentos`](#easy_listar_empreendimentos) | Leitura |  | Easy Orça | Empreendimentos e ativos |
| [`easy_ativo_dados`](#easy_ativo_dados) | Leitura |  | Easy Orça | Dados do ativo |
| [`easy_empreendimento_criar`](#easy_empreendimento_criar) | Prévia | livre | Easy Orça | Cadastrar empreendimento |
| [`easy_empreendimento_editar`](#easy_empreendimento_editar) | Prévia | livre | Easy Orça | Editar empreendimento |
| [`easy_empreendimento_arquivar`](#easy_empreendimento_arquivar) | Prévia | sempre | Easy Orça | Arquivar empreendimento |
| [`easy_ativo_criar`](#easy_ativo_criar) | Prévia | livre | Easy Orça | Cadastrar ativo |
| [`easy_ativo_editar`](#easy_ativo_editar) | Prévia | livre | Easy Orça | Editar ativo |
| [`easy_orcamento_arvore`](#easy_orcamento_arvore) | Leitura |  | Easy Orça | Árvore do orçamento |
| [`easy_orcamento_buscar_servico`](#easy_orcamento_buscar_servico) | Leitura |  | Easy Orça | Buscar serviço para o orçamento |
| [`easy_orcamento_replicar`](#easy_orcamento_replicar) | Prévia | tarefa | Easy Orça | Replicar itens |
| [`easy_orcamento_pendencias`](#easy_orcamento_pendencias) | Leitura |  | Easy Orça | Pendências para emitir |
| [`easy_orcamento_editar`](#easy_orcamento_editar) | Prévia | tarefa | Easy Orça | Editar estrutura |
| [`easy_orcamento_recalcular_precos`](#easy_orcamento_recalcular_precos) | Prévia | tarefa | Easy Orça | Recalcular preços da bancada |
| [`easy_aplicar_plano`](#easy_aplicar_plano) | Aplicar |  | Easy Orça | Aplicar plano |
| [`easy_orcamento_transcrever`](#easy_orcamento_transcrever) | Prévia | tarefa | Easy Orça | Transcrever planilha |
| [`easy_composicao_ver`](#easy_composicao_ver) | Leitura |  | Easy Orça | Ver composição no orçamento |
| [`easy_composicao_editar`](#easy_composicao_editar) | Prévia | tarefa | Easy Orça | Editar composição |
| [`easy_insumo_cotar`](#easy_insumo_cotar) | Prévia | tarefa | Easy Orça | Cotar insumo no orçamento |
| [`easy_bdi_ver`](#easy_bdi_ver) | Leitura |  | Easy Orça | BDI do orçamento |
| [`easy_bdi_salvar`](#easy_bdi_salvar) | Prévia | sempre | Easy Orça | Salvar BDI |
| [`easy_ls_ver`](#easy_ls_ver) | Leitura |  | Easy Orça | Leis Sociais da obra |
| [`easy_ls_semear`](#easy_ls_semear) | Prévia | sempre | Easy Orça | Semear Leis Sociais |
| [`easy_ls_editar`](#easy_ls_editar) | Prévia | sempre | Easy Orça | Ajustar Leis Sociais |
| [`easy_fontes_ver`](#easy_fontes_ver) | Leitura |  | Easy Orça | Fontes-base do orçamento |
| [`easy_fontes_salvar`](#easy_fontes_salvar) | Prévia | sempre | Easy Orça | Definir fontes-base |
| [`easy_empreendimento_heranca_ver`](#easy_empreendimento_heranca_ver) | Leitura |  | Easy Orça | Pautas únicas do empreendimento |
| [`easy_empreendimento_heranca_definir`](#easy_empreendimento_heranca_definir) | Prévia | sempre | Easy Orça | Definir pauta única do empreendimento |
| [`easy_cronograma_ver`](#easy_cronograma_ver) | Leitura |  | Easy Orça | Cronograma |
| [`easy_cronograma_configurar`](#easy_cronograma_configurar) | Prévia | tarefa | Easy Orça | Configurar cronograma |
| [`easy_cronograma_preencher`](#easy_cronograma_preencher) | Prévia | tarefa | Easy Orça | Preencher cronograma |
| [`easy_buscar_composicoes`](#easy_buscar_composicoes) | Consulta |  | Easy CPU | Buscar composições |
| [`easy_buscar_insumos`](#easy_buscar_insumos) | Consulta |  | Easy CPU | Buscar insumos |
| [`easy_proprios_precos_insumos`](#easy_proprios_precos_insumos) | Leitura |  | Easy CPU | Preços dos insumos próprios |
| [`easy_proprios_listar`](#easy_proprios_listar) | Leitura |  | Easy CPU | Listar dados próprios |
| [`easy_proprio_ver`](#easy_proprio_ver) | Leitura |  | Easy CPU | Ver insumo/composição própria |
| [`easy_proprios_cadastrar`](#easy_proprios_cadastrar) | Prévia | tarefa | Easy CPU | Cadastrar dados próprios |
| [`easy_proprios_editar`](#easy_proprios_editar) | Prévia | tarefa | Easy CPU | Editar dados próprios |
| [`easy_proprios_precos`](#easy_proprios_precos) | Prévia | tarefa | Easy CPU | Lançar preços próprios |
| [`easy_memorias_listar`](#easy_memorias_listar) | Leitura |  | Easy Orça | Memórias de cálculo |
| [`easy_memoria_ver`](#easy_memoria_ver) | Leitura |  | Easy Orça | Ver memória de cálculo |
| [`easy_memoria_criar`](#easy_memoria_criar) | Prévia | livre | Easy Orça | Criar memória de cálculo |
| [`easy_memoria_excluir`](#easy_memoria_excluir) | Prévia | sempre | Easy Orça | Excluir memória de cálculo |
| [`easy_memoria_escrever`](#easy_memoria_escrever) | Prévia | tarefa | Easy Orça | Escrever na memória |
| [`easy_memoria_ligar`](#easy_memoria_ligar) | Prévia | tarefa | Easy Orça | Associar/vincular células |
| [`easy_descritivo_ver`](#easy_descritivo_ver) | Leitura |  | Easy Orça | Ver descritivo no orçamento |
| [`easy_descritivo_editar`](#easy_descritivo_editar) | Prévia | livre | Easy Orça | Editar descritivo no orçamento |

## easy_guia

**Guia de operação** · Leitura · plataforma

Guia de operação do AxysEasy para a IA: papel, princípios, conceitos, o protocolo de escrita (prévia → confirmação → aplicar), fluxos (transcrever planilha, curar conciliações, ajustar preço, replicar, BDI/L.S. + recálculo, fontes-base, pauta única do empreendimento, consultar catálogo), o que fazer com cada erro e as ferramentas disponíveis para ESTE usuário, por categoria. Leia antes de operar.

## easy_sobre

**Sobre o Easy e o ecossistema** · Leitura · plataforma

Explicações sobre o ecossistema AxysEasy (produtos) e sobre como a app funciona (conceitos e regras). Sem `topico`: devolve o SUMÁRIO (tópico + resumo de uma linha) — barato; leia-o primeiro. Com `topico`: devolve a explicação só daquele tópico. Use para responder dúvida do usuário e para entender um conceito antes de operar; responda a partir do texto devolvido, sem inventar funcionalidade, prazo ou preço.

| Parâmetro | Tipo | Obrigatório |
|---|---|---|
| `topico` | texto? |  |

## easy_meu_acesso

**Meu acesso ao Easy** · Leitura · plataforma

Quem está conectado ao AxysEasy, em qual empresa, quais módulos estão habilitados neste assistente (modulos_mcp) e se é possível alterar dados (pode_escrever). Módulos da empresa sem o add-on de assistente aparecem em modulos_sem_assistente. Consulte antes de propor qualquer alteração.

## easy_listar_empreendimentos

**Empreendimentos e ativos** · Leitura · Easy Orça

Empreendimentos da empresa, cada um com os seus ativos (obras/edificações orçadas). `busca` filtra pelo nome do empreendimento ou do ativo (sem acento, parcial). Use a `ref` do ativo nas demais ferramentas.

| Parâmetro | Tipo | Obrigatório |
|---|---|---|
| `busca` | texto? |  |

## easy_ativo_dados

**Dados do ativo** · Leitura · Easy Orça

Dados cadastrais do ativo (nome, código interno, tipo, UF, endereço, situação) e os tipos disponíveis.

| Parâmetro | Tipo | Obrigatório |
|---|---|---|
| `ativo` | texto | sim |

## easy_empreendimento_criar

**Cadastrar empreendimento** · Prévia · Easy Orça · confirmação: livre

PRÉVIA de cadastrar um empreendimento (só o nome; o resto se edita depois).

| Parâmetro | Tipo | Obrigatório |
|---|---|---|
| `nome` | texto | sim |

## easy_empreendimento_editar

**Editar empreendimento** · Prévia · Easy Orça · confirmação: livre

PRÉVIA de editar o empreendimento: só os campos informados mudam; o resto fica como está.

| Parâmetro | Tipo | Obrigatório |
|---|---|---|
| `empreendimento` | texto | sim |
| `nome` | texto? |  |
| `codigo_interno` | texto? |  |
| `descricao` | texto? |  |
| `endereco` | Endereco? |  |

## easy_empreendimento_arquivar

**Arquivar empreendimento** · Prévia · Easy Orça · confirmação: sempre

PRÉVIA de arquivar (ou desarquivar, com arquivar=false) o empreendimento. Excluir empreendimento não existe no Easy; arquivar o tira da lista sem apagar nada.

| Parâmetro | Tipo | Obrigatório |
|---|---|---|
| `empreendimento` | texto | sim |
| `arquivar` | sim/não |  |

## easy_ativo_criar

**Cadastrar ativo** · Prévia · Easy Orça · confirmação: livre

PRÉVIA de cadastrar um ativo (obra/edificação) no empreendimento — só a descrição; o resto se edita depois. A licença pode limitar quantos ativos a empresa tem (a recusa diz o motivo).

| Parâmetro | Tipo | Obrigatório |
|---|---|---|
| `empreendimento` | texto | sim |
| `nome` | texto | sim |

## easy_ativo_editar

**Editar ativo** · Prévia · Easy Orça · confirmação: livre

PRÉVIA de editar os dados cadastrais do ativo: só os campos informados mudam. `tipo` = um dos tipos de easy_ativo_dados.

| Parâmetro | Tipo | Obrigatório |
|---|---|---|
| `ativo` | texto | sim |
| `nome` | texto? |  |
| `codigo_interno` | texto? |  |
| `tipo` | texto? |  |
| `uf` | texto? |  |
| `endereco` | Endereco? |  |

## easy_orcamento_arvore

**Árvore do orçamento** · Leitura · Easy Orça

Árvore do orçamento (revisão vigente) de um ativo, igual à bancada do Easy: grupos (níveis) e serviços, com caminho (ex.: 2.1.3), código e fonte da composição, quantidade e valores com BDI. `prefixo` recorta uma subárvore (ex.: "2.2"); `profundidade` corta em um nível absoluto (ex.: 3 = até o nível 3). Grupo com `tem_filhos=false` é um grupo vazio. Até 500 linhas por página.

| Parâmetro | Tipo | Obrigatório |
|---|---|---|
| `ativo` | texto | sim |
| `prefixo` | texto? |  |
| `profundidade` | inteiro? |  |
| `pagina` | inteiro |  |

## easy_orcamento_buscar_servico

**Buscar serviço para o orçamento** · Leitura · Easy Orça

Busca composições para um SERVIÇO deste orçamento, como o seletor da bancada do Easy: só as fontes configuradas no ativo, composições próprias da empresa primeiro e custo na edição/ UF/modalidade do ativo (até 25). `fonte` restringe a uma fonte (ex.: SINAPI ou PRÓPRIA). Termo com 3+ caracteres. Os resultados são candidatos: confirme com o usuário qual serve.

| Parâmetro | Tipo | Obrigatório |
|---|---|---|
| `ativo` | texto | sim |
| `termo` | texto | sim |
| `fonte` | texto? |  |

## easy_orcamento_replicar

**Replicar itens** · Prévia · Easy Orça · confirmação: tarefa

PRÉVIA de copiar os itens `origens` (refs de serviços e/ou grupos — grupo vai com tudo o que tem dentro) para dentro de CADA grupo de `destinos` (refs), no fim dos filhos. As cópias de serviço saem com `quantidade` ou, sem ela, com a quantidade da origem. NÃO altera nada: devolve a prévia e um `plano`. Mostre a prévia ao usuário e, com a confirmação dele, chame easy_aplicar_plano com esse plano (vale 15 minutos).

| Parâmetro | Tipo | Obrigatório |
|---|---|---|
| `ativo` | texto | sim |
| `origens` | lista de texto | sim |
| `destinos` | lista de texto | sim |
| `quantidade` | número? |  |

## easy_orcamento_pendencias

**Pendências para emitir** · Leitura · Easy Orça

O que falta para o orçamento sair completo nos documentos da app (a geração é sempre pela app, não pelo assistente): as pendências que a própria app aponta na exportação (serviços sem custo, ERR de conversão de regime, cronograma não configurado ou incompleto, L.S. ou BDI ausentes) + serviços a CONCILIAR (sem composição) e serviços sem quantidade.

| Parâmetro | Tipo | Obrigatório |
|---|---|---|
| `ativo` | texto | sim |

## easy_orcamento_editar

**Editar estrutura** · Prévia · Easy Orça · confirmação: tarefa

PRÉVIA de editar a estrutura do orçamento em lote (até 200 operações, aplicadas juntas): inserir (GRUPO com descrição, ou SERVIÇO por fonte+código, num grupo/após um item), duplicar (ao lado do original, sem quantidade — regra da tela), quantidade (serviço), descricao (grupo ou serviço sem composição), composicao (define/troca a composição de um serviço por fonte+código — é como se cura uma linha a CONCILIAR), mover (para dentro de um grupo, opcionalmente após um item) e remover (só o item; os filhos sobem um nível). Remover item com memória de cálculo é recusado (desassocie na tela). NÃO altera nada: devolve antes/depois de cada operação, o Δ do total e um plano para easy_aplicar_plano.

| Parâmetro | Tipo | Obrigatório |
|---|---|---|
| `ativo` | texto | sim |
| `operacoes` | lista de Operacao | sim |

## easy_orcamento_recalcular_precos

**Recalcular preços da bancada** · Prévia · Easy Orça · confirmação: tarefa

PRÉVIA de RECALCULAR os preços da bancada INTEIRA pelas fontes, edições, L.S./regime e BDI vigentes do ativo (o "Converter preços" da tela). DISPARE LOGO APÓS qualquer mudança de fontes, edições, L.S./regime ou BDI (no ativo ou na herança do empreendimento) — sem ele a bancada segue com os preços da configuração anterior. Preço fixado não muda; receita editada no orçamento fica com o seu custo. Mostra quantos itens mudam, o Δ do total e as maiores variações; aplicar com easy_aplicar_plano.

| Parâmetro | Tipo | Obrigatório |
|---|---|---|
| `ativo` | texto | sim |

## easy_aplicar_plano

**Aplicar plano** · Aplicar · Easy Orça

APLICA um plano gerado por uma ferramenta de prévia (ex.: easy_orcamento_replicar) — só depois de o usuário confirmar a prévia. Grava tudo numa operação só (ou nada). Recusa se o orçamento mudou desde a prévia (gere a prévia de novo). Aplicar o mesmo plano de novo não duplica: devolve o resultado da primeira vez.

| Parâmetro | Tipo | Obrigatório |
|---|---|---|
| `plano` | texto | sim |

## easy_orcamento_transcrever

**Transcrever planilha** · Prévia · Easy Orça · confirmação: tarefa

PRÉVIA de transcrever um LOTE (até 100 linhas) de uma planilha de orçamento para a bancada. A hierarquia sai do `item` (o pai de 2.2.1 é 2.2). Serviço com fonte+código encontrado entra com a composição e o preço do Easy; código não encontrado entra como linha a CONCILIAR (com os dados da planilha, sem composição — o usuário cura na bancada). O preço da planilha NÃO vira preço: só aparece como divergência. Primeiro lote: sem `transcricao`; `destino` = ref de um grupo onde tudo entra (sem destino = raiz do orçamento). Lotes seguintes: passe a `transcricao` devolvida e só as linhas novas, em ordem. NÃO altera nada: mostre a prévia ao usuário e aplique com easy_aplicar_plano (um lote por vez, aplicado antes de prever o próximo).

| Parâmetro | Tipo | Obrigatório |
|---|---|---|
| `ativo` | texto | sim |
| `linhas` | lista de LinhaPlanilha | sim |
| `transcricao` | texto? |  |
| `destino` | texto? |  |

## easy_composicao_ver

**Ver composição no orçamento** · Leitura · Easy Orça

A composição (receita) do serviço `item` COMO ESTÁ NESTE ORÇAMENTO: insumos e subcomposições com coeficiente, preço unitário e total, custo da composição e quantos serviços do orçamento a usam (a composição é uma só por orçamento: editá-la muda todos esses serviços).

| Parâmetro | Tipo | Obrigatório |
|---|---|---|
| `ativo` | texto | sim |
| `item` | texto | sim |

## easy_composicao_editar

**Editar composição** · Prévia · Easy Orça · confirmação: tarefa

PRÉVIA de editar a composição do serviço `item` neste orçamento — é assim que se muda preço (nunca fixando). Mudanças: coeficiente (de uma linha), incluir (insumo/composição por fonte+ código, com coeficiente), remover, substituir (por análogo confirmado). `alcance`: ORCAMENTO (só aqui, padrão); CRIAR_PROPRIA (composição de catálogo vira própria da empresa com esta receita, e o orçamento passa a usá-la); ATUALIZAR_CATALOGO (a composição própria passa a ter esta receita nos Dados Próprios; outros orçamentos não mudam). NÃO altera nada: devolve o IMPACTO (custo antes/depois, serviços afetados, Δ do total) e um plano para easy_aplicar_plano.

| Parâmetro | Tipo | Obrigatório |
|---|---|---|
| `ativo` | texto | sim |
| `item` | texto | sim |
| `mudancas` | lista de Mudanca | sim |
| `alcance` | ORCAMENTO | CRIAR_PROPRIA | ATUALIZAR_CATALOGO |  |

## easy_insumo_cotar

**Cotar insumo no orçamento** · Prévia · Easy Orça · confirmação: tarefa

PRÉVIA de cotar um INSUMO deste orçamento (o preço vale só aqui; as propostas são a evidência — art. 23 da Lei 14.133/2021). Até 5 propostas. O preço é o `metodo` sobre as propostas aplicadas, ou `preco_informado` (aí as propostas ficam como justificativa). Mostra a estatística (CV, observação), preço antes/depois e o Δ do total. Insumo de mão de obra: o preço é gravado, mas as composições mantêm a L.S. aplicada (aviso). Anexos de proposta só pela tela. NÃO altera nada: devolve um plano para easy_aplicar_plano.

| Parâmetro | Tipo | Obrigatório |
|---|---|---|
| `ativo` | texto | sim |
| `fonte` | texto | sim |
| `codigo` | texto | sim |
| `propostas` | lista de Proposta | sim |
| `metodo` | MENOR | MEDIA | MEDIANA | MIN_MED_MEDIANA |  |
| `preco_informado` | número? |  |

## easy_bdi_ver

**BDI do orçamento** · Leitura · Easy Orça

Os BDIs (nome, classe NORMAL/REDUZIDO, regime, tipo de obra, ISS, parcelas, percentual) do ativo ou do empreendimento, e a tabela de referência do TCU (Acórdão 2622/2013: 1º quartil, médio, 3º quartil por tipo de obra) — referência para o usuário decidir, não valor a impor. Informe `ativo` OU `empreendimento`; `definido_em` diz onde a pauta vale.

| Parâmetro | Tipo | Obrigatório |
|---|---|---|
| `ativo` | texto? |  |
| `empreendimento` | texto? |  |

## easy_bdi_salvar

**Salvar BDI** · Prévia · Easy Orça · confirmação: sempre

PRÉVIA de criar ou alterar um BDI (identificado pelo `nome`: existe → altera; não existe → cria). O percentual sai da FÓRMULA da app (não se informa). A prévia mostra o percentual, os alertas da fórmula e, por parcela, onde o valor cai na faixa do TCU para o tipo de obra. `padrao=true` torna este o BDI padrão dos serviços. Alvo: `ativo` OU `empreendimento` (um dos dois). No empreendimento, só com a pauta única ligada; o ativo com a pauta herdada é recusado, e a recusa traz a referência do empreendimento a usar. No empreendimento, a app propaga a todos os ativos e recalcula os preços deles.

| Parâmetro | Tipo | Obrigatório |
|---|---|---|
| `nome` | texto | sim |
| `parcelas` | ParcelasBDI | sim |
| `ativo` | texto? |  |
| `empreendimento` | texto? |  |
| `classe` | NORMAL | REDUZIDO |  |
| `regime` | ONERADO | DESONERADO |  |
| `tipo_obra` | texto? |  |
| `iss_base` | número? |  |
| `iss_aliquota` | número? |  |
| `padrao` | sim/não? |  |

## easy_ls_ver

**Leis Sociais da obra** · Leitura · Easy Orça

Leis Sociais (encargos) do ativo ou do empreendimento: tipo (ONERADA/DESONERADA), regime de mão de obra (HORISTA/MENSALISTA), totais horista/mensalista e os itens por grupo (A, B, C, D…), com os avisos da app (divergência com as fontes-base, conversão de preços). Informe `ativo` OU `empreendimento`; `definido_em` diz onde a pauta vale.

| Parâmetro | Tipo | Obrigatório |
|---|---|---|
| `ativo` | texto? |  |
| `empreendimento` | texto? |  |

## easy_ls_semear

**Semear Leis Sociais** · Prévia · Easy Orça · confirmação: sempre

PRÉVIA de (re)semear a L.S. a partir do catálogo, pela edição e UF que a `fonte` tem configuradas (no ativo ou no empreendimento). É um RESET: a L.S. editada atual é substituída (o regime de mão de obra é preservado). Alvo: `ativo` OU `empreendimento` (um dos dois). No empreendimento, só com a pauta única ligada; o ativo com a pauta herdada é recusado, e a recusa traz a referência do empreendimento a usar. No empreendimento, a app propaga a todos os ativos e recalcula os preços deles.

| Parâmetro | Tipo | Obrigatório |
|---|---|---|
| `regime` | ONERADO | DESONERADO | sim |
| `ativo` | texto? |  |
| `empreendimento` | texto? |  |
| `fonte` | texto |  |

## easy_ls_editar

**Ajustar Leis Sociais** · Prévia · Easy Orça · confirmação: sempre

PRÉVIA de ajustar a L.S.: % de itens (por código), totais, tipo e regime de mão de obra. Só o informado muda. Como na app, o TOTAL do cabeçalho é o que vale (não é recalculado dos itens); a prévia mostra a soma dos itens para conferência. MENSALISTA aciona a rotação de regime da bancada (regra da app). Alvo: `ativo` OU `empreendimento` (um dos dois). No empreendimento, só com a pauta única ligada; o ativo com a pauta herdada é recusado, e a recusa traz a referência do empreendimento a usar. No empreendimento, a app propaga a todos os ativos e recalcula os preços deles.

| Parâmetro | Tipo | Obrigatório |
|---|---|---|
| `ativo` | texto? |  |
| `empreendimento` | texto? |  |
| `itens` | lista de ItemLS? |  |
| `total_horista` | número? |  |
| `total_mensalista` | número? |  |
| `tipo` | ONERADA | DESONERADA? |  |
| `mdo` | HORISTA | MENSALISTA? |  |

## easy_fontes_ver

**Fontes-base do orçamento** · Leitura · Easy Orça

Fontes-base (as únicas que o orçamento pode usar) do ativo ou do empreendimento: fonte, edição (data-base), UF, modalidade (SD/CD/SE), favorita e as conversões ligadas; e o catálogo de fontes e edições disponíveis para escolher. Informe `ativo` OU `empreendimento`; `definido_em` diz onde a pauta vale.

| Parâmetro | Tipo | Obrigatório |
|---|---|---|
| `ativo` | texto? |  |
| `empreendimento` | texto? |  |

## easy_fontes_salvar

**Definir fontes-base** · Prévia · Easy Orça · confirmação: sempre

PRÉVIA de definir as fontes-base — a lista informada SUBSTITUI a atual (como na tela). Toda fonte precisa de edição. No ativo, fonte com serviço na bancada não pode sair (a app recusa e diz quais itens), e ao aplicar a app recalcula os preços da bancada (o resultado traz o Δ do total). Alvo: `ativo` OU `empreendimento` (um dos dois). No empreendimento, só com a pauta única ligada; o ativo com a pauta herdada é recusado, e a recusa traz a referência do empreendimento a usar. No empreendimento, a app propaga a todos os ativos e recalcula os preços deles.

| Parâmetro | Tipo | Obrigatório |
|---|---|---|
| `fontes` | lista de FonteBase | sim |
| `ativo` | texto? |  |
| `empreendimento` | texto? |  |

## easy_empreendimento_heranca_ver

**Pautas únicas do empreendimento** · Leitura · Easy Orça

As 3 pautas que podem ser ÚNICAS no empreendimento (Fontes/Edição, BDI, L.S./Regime): se está ligada (então os ativos herdam e NÃO recebem registro próprio dela) e se PODE ligar (só se os ativos já tiverem a pauta igual).

| Parâmetro | Tipo | Obrigatório |
|---|---|---|
| `empreendimento` | texto | sim |

## easy_empreendimento_heranca_definir

**Definir pauta única do empreendimento** · Prévia · Easy Orça · confirmação: sempre

PRÉVIA de ligar ou desligar a pauta única (Fontes/Edição, BDI ou L.S./Regime) no empreendimento: `acao` = "ligar" ou "desligar". Ligada, o registro fica no empreendimento e todos os ativos herdam (as ferramentas do ativo recusam editá-la; configure com `empreendimento`). Só liga se os ativos já tiverem a pauta igual. Nem ligar nem desligar muda preço. Empreendimento novo já nasce com as três ligadas: antes de desligar, confirme que é isso que o usuário quer.

| Parâmetro | Tipo | Obrigatório |
|---|---|---|
| `empreendimento` | texto | sim |
| `pauta` | fontes | bdi | ls | sim |
| `acao` | ligar | desligar | sim |

## easy_cronograma_ver

**Cronograma** · Leitura · Easy Orça

Cronograma físico-financeiro: configuração (prazo em dias, nº de períodos de 30 dias, NÍVEL de corte), quais níveis podem ser escolhidos (e por quê não), e as linhas com caminho, valor, se é linha editável (folha fora da Administração Local) e o % por período.

| Parâmetro | Tipo | Obrigatório |
|---|---|---|
| `ativo` | texto | sim |

## easy_cronograma_configurar

**Configurar cronograma** · Prévia · Easy Orça · confirmação: tarefa

PRÉVIA de configurar o cronograma: prazo (múltiplo de 30 dias; vira períodos de 30) e o NÍVEL de corte da EAP (as linhas do cronograma são os itens desse nível). Só níveis que 'fecham' o total podem ser escolhidos — a prévia diz quais e por quê. Reduzir o prazo apaga os % dos períodos que somem.

| Parâmetro | Tipo | Obrigatório |
|---|---|---|
| `ativo` | texto | sim |
| `prazo_dias` | inteiro | sim |
| `nivel` | inteiro | sim |

## easy_cronograma_preencher

**Preencher cronograma** · Prévia · Easy Orça · confirmação: tarefa

PRÉVIA de preencher % do cronograma. Padrão: altera só as células informadas (como digitar na tela). `substituir=true`: o cronograma inteiro vira só o informado — e então TODA linha editável com valor precisa de distribuição (regra da app). Só linhas editáveis (folhas fora da Administração Local, que segue o seu % derivado). A prévia mostra a soma de cada linha.

| Parâmetro | Tipo | Obrigatório |
|---|---|---|
| `ativo` | texto | sim |
| `percentuais` | lista de Percentual | sim |
| `substituir` | sim/não |  |

## easy_buscar_composicoes

**Buscar composições** · Consulta · Easy CPU

Busca composições (serviços) no catálogo geral — SINAPI, CDHU, FDE… — por descrição ou código, com custo na `uf` e `modalidade` pedidas (SD = sem desoneração, CD = com). `fonte` restringe a uma fonte (ex.: SINAPI). Termo com 3+ caracteres, paginado. Para escolher um serviço DENTRO de um orçamento, use easy_orcamento_buscar_servico. Os resultados são candidatos ranqueados: confirme com o usuário qual serve.

| Parâmetro | Tipo | Obrigatório |
|---|---|---|
| `termo` | texto | sim |
| `fonte` | texto? |  |
| `uf` | texto? |  |
| `modalidade` | texto? |  |
| `pagina` | inteiro |  |

## easy_buscar_insumos

**Buscar insumos** · Consulta · Easy CPU

Busca insumos (materiais, mão de obra, equipamentos) no catálogo por descrição ou código. O preço é o publicado pela fonte, sem encargos (os encargos são da composição). Termo com 3+ caracteres, paginado.

| Parâmetro | Tipo | Obrigatório |
|---|---|---|
| `termo` | texto | sim |
| `fonte` | texto? |  |
| `uf` | texto? |  |
| `pagina` | inteiro |  |

## easy_proprios_precos_insumos

**Preços dos insumos próprios** · Leitura · Easy CPU

Situação dos preços dos INSUMOS PRÓPRIOS da empresa (Dados Próprios): lista os que têm o preço mais recente com data-base ANTERIOR ao mês `anterior_a` (formato AAAA-MM, ex.: 2026-09) e, à parte, os que não têm preço nenhum. Cada item traz preço, data-base e o rótulo da edição; `rotulo_diverge_da_data_base=true` avisa quando o rótulo (texto livre) indica outro mês que a data-base. `fonte` restringe a uma fonte própria (ex.: PRÓPRIA, SBC).

| Parâmetro | Tipo | Obrigatório |
|---|---|---|
| `anterior_a` | texto | sim |
| `fonte` | texto? |  |

## easy_proprios_listar

**Listar dados próprios** · Leitura · Easy CPU

Lista os insumos e/ou composições PRÓPRIOS da empresa (Dados Próprios), com busca por termo (descrição/código) e filtro por fonte própria. Paginado.

| Parâmetro | Tipo | Obrigatório |
|---|---|---|
| `tipo` | insumo | composicao | todos |  |
| `termo` | texto? |  |
| `fonte` | texto? |  |
| `pagina` | inteiro |  |

## easy_proprio_ver

**Ver insumo/composição própria** · Leitura · Easy CPU

Um insumo próprio (identidade + preço por edição) ou uma composição própria (identidade + descritivo: medição, remuneração e justificativa).

| Parâmetro | Tipo | Obrigatório |
|---|---|---|
| `tipo` | insumo | composicao | sim |
| `fonte` | texto | sim |
| `codigo` | texto | sim |
| `uf` | texto? |  |

## easy_proprios_cadastrar

**Cadastrar dados próprios** · Prévia · Easy CPU · confirmação: tarefa

PRÉVIA de cadastrar insumos e/ou composições PRÓPRIOS em lote (até 100 no total): fonte própria, descrição (CAIXA ALTA), unidade, classe (insumo), UF (insumo), código (vazio = automático) e, na composição, medição/remuneração. Preço do insumo: easy_proprios_precos; receita da composição: pela bancada (editar composição com alcance ATUALIZAR_CATALOGO).

| Parâmetro | Tipo | Obrigatório |
|---|---|---|
| `insumos` | lista de InsumoNovo? |  |
| `composicoes` | lista de ComposicaoNova? |  |

## easy_proprios_editar

**Editar dados próprios** · Prévia · Easy CPU · confirmação: tarefa

PRÉVIA de editar insumos/composições PRÓPRIOS em lote: identidade (descrição, unidade, classe, código) e, na composição, o DESCRITIVO (medição, remuneração, justificativa). Só o informado muda; texto vazio apaga. A fonte de um item não muda (regra da app).

| Parâmetro | Tipo | Obrigatório |
|---|---|---|
| `insumos` | lista de InsumoEdicao? |  |
| `composicoes` | lista de ComposicaoEdicao? |  |

## easy_proprios_precos

**Lançar preços próprios** · Prévia · Easy CPU · confirmação: tarefa

PRÉVIA de lançar preços de insumos PRÓPRIOS por edição (mês AAAA-MM da fonte): `valor` informado, ou `propostas` (até 5) + `metodo` (as propostas viram a evidência, como na tela). Até 100 por lote.

| Parâmetro | Tipo | Obrigatório |
|---|---|---|
| `precos` | lista de Preco | sim |

## easy_memorias_listar

**Memórias de cálculo** · Leitura · Easy Orça

Memórias de cálculo do ativo (título, quantos serviços cada uma alimenta, se tem conteúdo).

| Parâmetro | Tipo | Obrigatório |
|---|---|---|
| `ativo` | texto | sim |

## easy_memoria_ver

**Ver memória de cálculo** · Leitura · Easy Orça

A memória como o grid da tela: cada célula (posição, tipo, conteúdo bruto, valor calculado), os serviços associados (e de que célula vem a quantidade) e as células vinculadas. Traz a gramática de preenchimento em `como_preencher`.

| Parâmetro | Tipo | Obrigatório |
|---|---|---|
| `ativo` | texto | sim |
| `memoria` | texto | sim |

## easy_memoria_criar

**Criar memória de cálculo** · Prévia · Easy Orça · confirmação: livre

PRÉVIA de criar uma memória de cálculo vazia no ativo.

| Parâmetro | Tipo | Obrigatório |
|---|---|---|
| `ativo` | texto | sim |
| `titulo` | texto | sim |

## easy_memoria_excluir

**Excluir memória de cálculo** · Prévia · Easy Orça · confirmação: sempre

PRÉVIA de excluir a memória inteira. Os serviços associados a ela perdem a quantidade calculada (voltam a zero e destravam na bancada) — a prévia lista quais. Anexos são apagados.

| Parâmetro | Tipo | Obrigatório |
|---|---|---|
| `ativo` | texto | sim |
| `memoria` | texto | sim |

## easy_memoria_escrever

**Escrever na memória** · Prévia · Easy Orça · confirmação: tarefa

PRÉVIA de escrever células da memória (até 500 por vez): número, texto ou fórmula (gramática em `como_preencher` de easy_memoria_ver). O grid inteiro é recalculado como na tela; a prévia mostra o valor de cada célula alterada e a NOVA quantidade dos serviços associados (= soma das células associadas). Célula vinculada é só-leitura. Fórmula com #ERRO/#CICLO em célula associada zera a quantidade do serviço — a prévia avisa.

| Parâmetro | Tipo | Obrigatório |
|---|---|---|
| `ativo` | texto | sim |
| `memoria` | texto | sim |
| `celulas` | lista de Celula | sim |
| `titulo` | texto? |  |

## easy_memoria_ligar

**Associar/vincular células** · Prévia · Easy Orça · confirmação: tarefa

PRÉVIA de ligar células a serviços: associar (célula numérica → quantidade do serviço = soma das células associadas, travada ƒ na bancada), desassociar, vincular (a célula mostra a quantidade de outro serviço × fator, só-leitura, usável nas fórmulas) e desvincular. Regras da app: um serviço só em UMA memória; um serviço não é entrada e saída da mesma memória.

| Parâmetro | Tipo | Obrigatório |
|---|---|---|
| `ativo` | texto | sim |
| `memoria` | texto | sim |
| `operacoes` | lista de Ligacao | sim |

## easy_descritivo_ver

**Ver descritivo no orçamento** · Leitura · Easy Orça

O descritivo da composição do serviço `item` NESTE orçamento: forma de medição, remuneração e (composição própria) justificativa; de onde vem o texto que vale (ORCAMENTO, CATALOGO ou PROPRIA), o texto herdado e quantos serviços usam a composição.

| Parâmetro | Tipo | Obrigatório |
|---|---|---|
| `ativo` | texto | sim |
| `item` | texto | sim |

## easy_descritivo_editar

**Editar descritivo no orçamento** · Prévia · Easy Orça · confirmação: livre

PRÉVIA de editar o descritivo NO ORÇAMENTO: só os campos informados mudam (texto vazio apaga; ausente fica). `restaurar=true` volta a herdar do catálogo/da própria. Vale para todos os serviços deste orçamento que usam a composição, e é o que o Caderno de Encargos imprime. Justificativa só em composição própria.

| Parâmetro | Tipo | Obrigatório |
|---|---|---|
| `ativo` | texto | sim |
| `item` | texto | sim |
| `medicao` | texto? |  |
| `remuneracao` | texto? |  |
| `justificativa` | texto? |  |
| `restaurar` | sim/não |  |

## Campos dos objetos de entrada

### Celula

| Campo | Tipo | Obrigatório | Explicação |
|---|---|---|---|
| `celula` | texto | sim | Posição, ex.: B3 (colunas A a K) |
| `valor` | número | texto? |  | número, texto, ou fórmula começando com '='; vazio apaga |
| `negrito` | sim/não? |  |  |

### ComposicaoEdicao

| Campo | Tipo | Obrigatório | Explicação |
|---|---|---|---|
| `fonte` | texto | sim |  |
| `codigo` | texto | sim |  |
| `descricao` | texto? |  |  |
| `unidade` | texto? |  |  |
| `novo_codigo` | texto? |  |  |
| `medicao` | texto? |  | Forma de medição (texto vazio apaga) |
| `remuneracao` | texto? |  | O que a composição remunera (texto vazio apaga) |
| `justificativa` | texto? |  | Memorial da montagem (texto vazio apaga) |

### ComposicaoNova

| Campo | Tipo | Obrigatório | Explicação |
|---|---|---|---|
| `fonte` | texto | sim |  |
| `descricao` | texto | sim |  |
| `unidade` | texto | sim |  |
| `codigo` | texto? |  | Vazio = código automático |
| `medicao` | texto? |  |  |
| `remuneracao` | texto? |  |  |

### Endereco

| Campo | Tipo | Obrigatório | Explicação |
|---|---|---|---|
| `cep` | texto? |  |  |
| `logradouro` | texto? |  |  |
| `numero` | texto? |  |  |
| `complemento` | texto? |  |  |
| `bairro` | texto? |  |  |
| `municipio` | texto? |  |  |
| `uf` | texto? |  |  |

### FonteBase

| Campo | Tipo | Obrigatório | Explicação |
|---|---|---|---|
| `fonte` | texto | sim | Código da fonte (SINAPI, CDHU, FDE, ou uma fonte própria) |
| `edicao` | texto | sim | Edição (rótulo de easy_fontes_ver → disponiveis.edicoes) |
| `uf` | texto |  |  |
| `modalidade` | SD | CD | SE |  |  |
| `favorita` | sim/não |  |  |
| `converter_ls` | sim/não |  |  |
| `converter_mdo` | sim/não |  |  |
| `converter_ins` | sim/não |  |  |

### InsumoEdicao

| Campo | Tipo | Obrigatório | Explicação |
|---|---|---|---|
| `fonte` | texto | sim |  |
| `codigo` | texto | sim |  |
| `uf` | texto? |  |  |
| `descricao` | texto? |  |  |
| `unidade` | texto? |  |  |
| `tipo` | texto? |  |  |
| `novo_codigo` | texto? |  |  |

### InsumoNovo

| Campo | Tipo | Obrigatório | Explicação |
|---|---|---|---|
| `fonte` | texto | sim | Fonte própria (código, ex.: PRÓPRIA) |
| `descricao` | texto | sim |  |
| `unidade` | texto | sim |  |
| `tipo` | texto | sim | Classe do insumo: MO, MAT, EQUIP_AQ, EQUIP_LOC, SERV, ESP, ENC_COMP… |
| `uf` | texto |  |  |
| `codigo` | texto? |  | Vazio = código automático |

### ItemLS

| Campo | Tipo | Obrigatório | Explicação |
|---|---|---|---|
| `codigo` | texto | sim | Código do item da L.S. (ex.: A1, B3) |
| `horista` | número? |  | % horista |
| `mensalista` | número? |  | % mensalista |

### Ligacao

| Campo | Tipo | Obrigatório | Explicação |
|---|---|---|---|
| `op` | associar | desassociar | vincular | desvincular | sim |  |
| `celula` | texto | sim | Posição da célula (ex.: B3) |
| `servico` | texto? |  | associar/vincular: ref do serviço |
| `fator` | número? |  | vincular: multiplicador (padrão 1) |
| `fator_nome` | texto? |  | vincular: nome do fator (ex.: 'perda 5%') |

### LinhaPlanilha

| Campo | Tipo | Obrigatório | Explicação |
|---|---|---|---|
| `item` | texto | sim | Numeração da planilha: 1, 1.2, 1.2.3… — define a hierarquia |
| `tipo` | texto | sim | GRUPO (nível/título) ou SERVIÇO |
| `descricao` | texto? |  | Descrição como está na planilha |
| `fonte` | texto? |  | Fonte do serviço: SINAPI, CDHU, FDE, PRÓPRIA… |
| `codigo` | texto? |  | Código do serviço na fonte |
| `unidade` | texto? |  |  |
| `quantidade` | número? |  |  |
| `preco` | número? |  | Preço unitário da planilha (só para comparar; não vira preço) |

### Mudanca

| Campo | Tipo | Obrigatório | Explicação |
|---|---|---|---|
| `acao` | coeficiente | incluir | remover | substituir | sim |  |
| `tipo` | INSUMO | COMPOSICAO |  |  |
| `fonte` | texto? |  | Fonte da linha (ex.: SINAPI, CDHU, PRÓPRIA) |
| `codigo` | texto | sim | Código do insumo/composição da linha |
| `coeficiente` | número? |  | Novo coeficiente (coeficiente/incluir; opcional em substituir) |
| `por` | Substituto? |  | substituir: o análogo CONFIRMADO que entra no lugar |

### Operacao

| Campo | Tipo | Obrigatório | Explicação |
|---|---|---|---|
| `op` | quantidade | descricao | composicao | mover | remover | inserir | duplicar | sim |  |
| `item` | texto? |  | ref do item (todas, menos inserir) |
| `tipo` | GRUPO | SERVIÇO? |  | inserir: GRUPO ou SERVIÇO |
| `valor` | número | texto? |  | quantidade (número; também a do serviço inserido) ou descricao (texto) |
| `descricao` | texto? |  | inserir GRUPO: a descrição |
| `fonte` | texto? |  | composicao/inserir SERVIÇO: fonte (SINAPI, CDHU, FDE, PRÓPRIA…) |
| `codigo` | texto? |  | composicao/inserir SERVIÇO: código da composição |
| `destino` | texto? |  | mover/inserir: ref do grupo de destino (vazio = raiz) |
| `apos` | texto? |  | mover/inserir: ref do item após o qual entra (vazio = no fim) |

### ParcelasBDI

| Campo | Tipo | Obrigatório | Explicação |
|---|---|---|---|
| `AC` | número? |  | Administração central (%) |
| `SG` | número? |  | Seguro e garantia (%) |
| `R` | número? |  | Risco (%) |
| `DF` | número? |  | Despesas financeiras (%) |
| `L` | número? |  | Lucro (%) |
| `CP` | número? |  | PIS+COFINS (%) |
| `ISS` | número? |  | ISS efetivo (%); se vazio, sai de iss_base × iss_aliquota |
| `CPRB` | número? |  | CPRB (%), só no regime DESONERADO |

### Percentual

| Campo | Tipo | Obrigatório | Explicação |
|---|---|---|---|
| `item` | texto | sim | ref da linha do cronograma (de easy_cronograma_ver) |
| `periodo` | inteiro | sim | período (1 = primeiros 30 dias) |
| `percent` | número | sim | % do valor da linha naquele período (0 apaga) |

### Preco

| Campo | Tipo | Obrigatório | Explicação |
|---|---|---|---|
| `fonte` | texto | sim |  |
| `codigo` | texto | sim |  |
| `uf` | texto? |  |  |
| `edicao` | texto | sim | Mês da edição da fonte (AAAA-MM) |
| `valor` | número? |  | Preço informado (ou use propostas + metodo) |
| `propostas` | lista de Proposta? |  |  |
| `metodo` | MENOR | MEDIA | MEDIANA | MIN_MED_MEDIANA |  |  |

### Proposta

| Campo | Tipo | Obrigatório | Explicação |
|---|---|---|---|
| `empresa` | texto | sim | Fornecedor/empresa da proposta |
| `valor` | número | sim | Preço unitário proposto, na unidade do insumo |
| `data` | texto? |  | Data da proposta (AAAA-MM-DD) |
| `aplicada` | sim/não |  | Entra no cálculo (false = só registro/justificativa) |

### Substituto

| Campo | Tipo | Obrigatório | Explicação |
|---|---|---|---|
| `fonte` | texto | sim |  |
| `codigo` | texto | sim |  |
