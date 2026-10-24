# Estratégia de SEO e aquisição orgânica da Axys

## Estado do plano

Documento originalmente elaborado a partir do primeiro pacote do Google Search Console,
compartilhado em **13/10/2026**, e atualizado em **24/10/2026** com a telemetria própria de
produção e o novo export do Search Console. Embora o novo conjunto tenha sido descrito como “de 14
até ontem”, o filtro do próprio arquivo informa **14/08/2026 a 23/10/2026**. Para medir o momento
recente, o gráfico também foi recortado de **14/10 a 23/10**.

Esta versão substitui a lógica de “publicar muitas páginas” por uma sequência orientada por
evidência:

1. capturar uma intenção comercial principal que hoje não encontra a Axys;
2. aproveitar a autoridade que o Google já reconhece em acórdãos e materiais técnicos;
3. ligar conteúdo técnico, página de solução e produto em uma jornada mensurável;
4. expandir somente depois que a primeira arquitetura provar indexação, tráfego e avanço comercial.

### Achados que alteram a prioridade

- A busca manual por **“sistema para orçamento de obras”**, realizada em 24/10/2026, não
  apresentou a Axys nos resultados percorridos. A posição exata não deve ser tratada como fixa,
  pois a SERP varia por localização, dispositivo e personalização.
- No novo export acumulado, Easy Orça continua com somente uma impressão e nenhuma URL de
  `/solucoes/` aparece. O Knowledge soma 1.846 impressões na dimensão de páginas.
- Entre 14 e 23/10, houve 770 impressões e cinco cliques, contra 171 impressões e dois cliques nos
  sete dias do pacote anterior. A visibilidade diária cresceu, mas o CTR recente ficou em 0,65%.
- Acórdãos respondem por 754 impressões e 14 cliques. Porém, casos, artigos, dúvidas, downloads e
  demais conteúdos técnicos somam 1.092 impressões: a estratégia deve conectar todo o Knowledge,
  não apenas decisões do TCU.
- Nos últimos 30 dias da telemetria própria, cinco sessões chegaram pelo Google: três por
  acórdãos, uma por um download técnico e uma pela home.
- A sessão orgânica mais qualificada entrou pelo material do IBRAOP sobre sobrepreço e
  superfaturamento e avançou até Easy Orça e Easy Price.
- Isso confirma que o Knowledge já funciona como porta de entrada, mas ainda precisa transferir
  autoridade e visitantes para páginas comerciais.

### Hipótese central

O caminho mais curto para começar a ranquear comercialmente não é abandonar os conteúdos que já
funcionam. É construir a ligação explícita:

```text
Pesquisa técnica no Google
        ↓
Acórdão, download, artigo ou dúvida
        ↓
Hub temático ou página de solução
        ↓
Landing do produto
        ↓
Demonstração, contato, cadastro ou instalação
```

---

## Métricas e SEO no Google


### Leitura do primeiro pacote
O export cobre apenas os últimos 7 dias. Nesse período tivemos:
* 171 impressões;
* 2 cliques;
* CTR aproximada de 1,17%;
* somente cinco consultas visíveis no export, devido ao baixo volume e aos filtros de privacidade do Search Console.
O tráfego está quase todo concentrado na base de conhecimento:
* Acórdãos: 72 impressões.
* Casos práticos: 24.
* Artigos: 18.
* Home: 36.
* Easy Orça: somente 1 impressão.
* Easy Docs: 1.
* Easy FinControl: 1.
Ou seja: o Google já reconhece alguma autoridade técnica, especialmente nos conteúdos jurídicos e de engenharia, mas ainda praticamente não associa a Axys às buscas comerciais pelos sistemas.
As melhores oportunidades já visíveis são:
* comparacao-orcamento-onerado-desonerado: 17 impressões, posição 9,06 e nenhum clique;
* tcu-2622-2013: 11 impressões, posição 6,09 e nenhum clique;
* encargos-sociais-horista-mensalista: 6 impressões, posição 6,83 e nenhum clique;
* a própria home aparece em posição média 4,06, mas com CTR de apenas 2,78%.
São páginas já na primeira página ou perto dela. Melhorar título, descrição, introdução, links internos e intenção atendida nelas tende a produzir resultado antes de páginas totalmente novas.
O arquivo de links externos mostra somente um domínio/página recente apontando para a Axys. É uma evidência de autoridade externa ainda muito limitada, embora esse relatório isolado não seja suficiente para inventariar todos os backlinks.

### Leitura do export de 24/10/2026

O acumulado de 14/08 a 23/10 registrou 38 cliques, 2.334 impressões, CTR de 1,63% e posição
aproximada de 9,16. No corte recente de 14 a 23/10, foram cinco cliques, 770 impressões, CTR de
0,65% e posição aproximada de 9,21.

Os destinos com maior oportunidade imediata são:

- comparação entre orçamento onerado e desonerado: 247 impressões, um clique, posição 9,62;
- artigo sobre truncar ou arredondar: 135 impressões, nenhum clique, posição 7,39;
- orientações para planilhas orçamentárias: 94 impressões, nenhum clique, posição 8,70;
- Acórdão TCU 2622/2013: 77 impressões, nenhum clique, posição 9,13;
- administração local: 40 impressões, nenhum clique, posição 4,80;
- mobilização e desmobilização: 30 impressões, nenhum clique, posição 5,37;
- material IBRAOP OT-005: 25 impressões, nenhum clique, posição 5,00.

O relatório de consultas mostra procura por orientações de planilhas orçamentárias, onerado e
desonerado, mobilização, orçamento analítico, orçamento sintético e controle físico-financeiro. Não
há consulta visível para “sistema para orçamento de obras” nem variante comercial equivalente. O
arquivo de consultas expõe apenas uma fração dos dados por privacidade — 356 das 2.334 impressões e
um dos 38 cliques —, mas é suficiente para confirmar a diferença entre autoridade técnica e demanda
comercial.

Nenhuma URL sob `/solucoes/` aparece no relatório de páginas. A primeira ação não é criar mais
páginas, mas confirmar a indexação das páginas já publicadas, revisar seus links internos e dar tempo
para que acumulem sinais. A análise completa está em `analysis/2026_10_24.md`.
### O problema das páginas não indexadas
Em 8 de outubro, o relatório tinha:
* 275 páginas indexadas;
* 153 não indexadas.
A divisão das 153 é:
Motivo	URLs
Detectada, mas não indexada	132
Rastreada, mas não indexada	10
Página com redirecionamento	4
Alternativa com canonical adequada	3
Soft 404	2
404 real	2
Não parece haver um bloqueio técnico geral:
* robots.txt libera o conteúdo público;
* o sitemap está acessível;
* as 399 URLs atualmente presentes no sitemap responderam HTTP 200 no meu rastreamento;
* as páginas principais têm canonical próprio;
* HTTPS está válido;
* não há erro nos dados estruturados exportados.
O Google deixa claro que sitemap e HTTP 200 tornam uma URL elegível, mas não garantem indexação. Páginas com pouco valor percebido, baixa demanda e poucos links podem não ser priorizadas. Google Search Central
Há, porém, problemas concretos no site atual:
1. Grande quantidade de páginas órfãs ou quase órfãs No rastreamento da arquitetura interna:
    * 166 dos 188 acórdãos não receberam nenhum link interno de outra URL do sitemap;
    * 28 das 31 páginas de dúvidas estavam sem link interno detectável;
    * 34 das 35 newsletters estavam sem link interno detectável;
    * várias páginas de artigos e downloads também estavam órfãs.
2. Estar no sitemap não substitui uma arquitetura navegável. O Google recomenda links <a> rastreáveis e uma hierarquia clara.
3. Newsletters extremamente pobres em HTML Das 35 páginas individuais de newsletter:
    * 34 não possuem <h1>;
    * o conteúdo HTML visível gira em torno de apenas 25 palavras;
    * o material principal parece ficar fora da página HTML, provavelmente no PDF.
4. Essas páginas são candidatas fortes a “soft 404” ou “rastreada, mas não indexada”. Temos duas opções corretas:
    * transformar cada página em uma publicação HTML útil, com resumo, destaques, tabelas, metodologia e links para o PDF;
    * ou aplicar noindex e removê-las do sitemap, deixando o PDF/documento como recurso principal.
5. Terminologia muito curta As 90 páginas de terminologia têm mediana próxima de 97 palavras. Algumas podem ser úteis, mas várias provavelmente são curtas demais e semanticamente sobrepostas. Precisamos enriquecer as importantes e consolidar sinônimos/variações.
6. Acórdãos sem agrupamento temático Existem 188 páginas, mas a maioria não está ligada a hubs como:
    * BDI;
    * sobrepreço e superfaturamento;
    * aditivos;
    * medição;
    * reajuste e reequilíbrio;
    * orçamento de referência;
    * SINAPI;
    * administração local.
7. Hoje o Google recebe uma lista extensa de URLs, mas poucos sinais sobre quais decisões são importantes e como elas se relacionam.
8. Diferença entre URLs conhecidas e sitemap atual O Search Console conhecia 428 URLs; o sitemap atual possui 399. Isso sugere aproximadamente 29 URLs antigas, removidas ou alternativas ainda conhecidas pelo Google. É bastante compatível com os redirecionamentos, canonicals e 404s do relatório.
Para descobrir exatamente quais são as duas 404, duas soft 404 e as dez rastreadas mas não indexadas, ainda precisamos exportar a lista de URLs de dentro de cada motivo no Search Console. O material enviado traz a contagem, mas não os exemplos.
### Estratégia original para o Easy Orça
A landing atual é boa institucionalmente, mas o posicionamento principal é “bancada profissional de orçamento de engenharia”. Essa expressão não corresponde à forma mais provável de busca.
Eu reposicionaria a página principal para algo próximo de:
* Title: Sistema de orçamento de obras | Easy Orça
* H1: Sistema para elaboração e revisão de orçamentos de obras
* Descrição: destacar orçamento analítico, composições, SINAPI/SICRO, BDI, encargos, curva ABC, cronograma e memória de cálculo.
A landing precisa responder, em HTML, perguntas comerciais e operacionais:
* O que é um sistema de orçamento de obras?
* Para quais empresas e profissionais ele serve?
* Faz orçamento público e privado?
* Trabalha com SINAPI, SICRO, CDHU e bases próprias?
* Importa Excel?
* Permite orçamento sintético e analítico?
* Calcula BDI e encargos sociais?
* Possui curva ABC?
* Gera cronograma físico-financeiro?
* Como controla revisões?
* Quais relatórios e exportações oferece?
* É online?
* Atende todo o Brasil?
* Como funciona a demonstração ou contratação?
Também faltam evidências concretas: imagens reais, exemplos de relatórios, vídeo curto, fluxos de uso e diferenciais verificáveis.
### Arquitetura comercial proposta
Em vez de tentar colocar tudo dentro da landing do produto, criaria uma camada /solucoes/, já prevista no backlog do projeto:
* /solucoes/sistema-de-orcamento-de-obras
* /solucoes/orcamento-de-obras-publicas
* /solucoes/orcamento-sinapi
* /solucoes/composicao-de-custos
* /solucoes/orcamento-analitico
* /solucoes/calculo-de-bdi-e-encargos
* /solucoes/curva-abc-de-obras
* /solucoes/cronograma-fisico-financeiro
* /solucoes/revisao-de-orcamento-de-obras
Cada página deve atender uma intenção diferente, trazer conteúdo realmente próprio e conduzir ao Easy Orça. Não deve apenas repetir a mesma landing trocando palavras.
Fluxo ideal:
Conteúdo educativo
        ↓
Página de solução/intenção
        ↓
Landing do Easy Orça
        ↓
Demonstração, contato ou cadastro
### Localização
A ideia de alcançar “sistema de orçamento de obras Brasil” e “São Paulo” faz sentido. Criar automaticamente uma página para cada município, não.
O Google classifica páginas municipais quase idênticas que levam ao mesmo destino como abuso de páginas de entrada. Política oficial sobre doorway abuse
A estratégia segura seria:
* Uma página nacional forte: /solucoes/sistema-de-orcamento-de-obras.
* Informar claramente “atendimento em todo o Brasil”.
* Criar páginas estaduais apenas quando houver conteúdo regional próprio.
* Priorizar inicialmente estados/bases com valor técnico real.
Exemplos defensáveis:
* /solucoes/orcamento-de-obras-sao-paulo
    * SINAPI-SP;
    * CDHU;
    * FDE;
    * particularidades das bases estaduais;
    * estudos ou casos reais do estado.
* /solucoes/orcamento-de-obras-minas-gerais
    * SINAPI-MG;
    * SETOP/DER-MG, quando aplicável;
    * conteúdo e casos locais reais.
“Pirapora do Norte” só justificaria página própria se existissem dados, clientes, referências, base de custos ou conteúdo realmente específico daquela localidade. Para cobrir a cauda longa geográfica, é melhor criar uma página nacional tecnicamente completa e uma seção explicando regionalização de preços e bases por UF.
## Plano de execução atualizado

### Prioridade 0 — linha de base e rotina de análise

O pacote anterior do Search Console foi compartilhado em 13/10/2026. O export de 24/10 trouxe o
acumulado desde 14/08 e permitiu extrair internamente o corte de 14 a 23/10. Nos próximos ciclos,
manter um período acumulado e outro sem sobreposição com a análise anterior.

Exportar:

- consultas;
- páginas;
- países e dispositivos;
- aparência na pesquisa, quando houver dados;
- dimensão consulta × página;
- URLs de cada motivo de não indexação;
- links externos e páginas mais vinculadas.

Guardar cada leitura em `seo_analytics/analysis/AAAA_MM_DD.md`, contendo:

- período e fontes consultadas;
- fotografia das métricas;
- páginas e consultas ganhadoras ou perdedoras;
- jornadas observadas na telemetria própria;
- hipóteses, decisões e ações;
- comparação com a análise anterior.

### Prioridade 1 — capturar “sistema para orçamento de obras”

Esta é a primeira lacuna comercial a atacar. O objetivo não é apenas inserir a expressão na landing,
mas criar o melhor destino possível para quem procura escolher ou entender um sistema desse tipo.

**Concluído e aprovado em 24/10/2026:** criada a landing
`/solucoes/sistema-de-orcamento-de-obras`, com intenção comercial própria, cobertura nacional,
FAQ, dados estruturados, entrada no sitemap e ligação recíproca com Easy Orça. A comunicação das
bases distingue o que está disponível hoje — SINAPI, CDHU, FDE e bases próprias — de outras fontes
ainda em processo de homologação. O layout e o conteúdo foram aprovados e publicados. A inspeção no
Search Console foi concluída em 24/10/2026: a URL publicada estava tecnicamente elegível, ainda era
desconhecida pelo Google e entrou na fila prioritária de rastreamento. Permanecem pendentes os links
vindos do primeiro lote do Knowledge e o acompanhamento de impressões, posição e CTR.

O padrão visual desta página fica definido como **padrão canônico das novas landings da Axys**.
Vídeos demonstrativos poderão ser incorporados posteriormente como evidência de uso, preservando a
estrutura editorial e a intenção de busca de cada página.

1. Auditar a landing do Easy Orça publicada:
   - title, H1, description e canonical;
   - presença natural da intenção principal e de sinônimos;
   - conteúdo HTML indexável;
   - dados estruturados e perguntas frequentes;
   - imagens reais, relatórios e evidências verificáveis.
2. Consolidar a página nacional `/solucoes/sistema-de-orcamento-de-obras`:
   - explicar critérios para escolher o sistema;
   - cobrir orçamento analítico e sintético, SINAPI/SICRO/CDHU, BDI, encargos, curva ABC,
     cronograma, memória de cálculo, revisão e exportação;
   - declarar atendimento em todo o Brasil sem criar páginas municipais artificiais;
   - comparar planilha isolada, ferramenta paramétrica, CPU e sistema completo;
   - conduzir ao Easy Orça sem duplicar sua landing.
3. Criar links internos para essa solução a partir dos conteúdos tecnicamente relacionados.
4. Criar links de retorno da landing para guias, acórdãos, casos e materiais que comprovem
   autoridade no assunto.
5. Solicitar indexação após publicação e acompanhar consulta, impressões, posição e CTR por semana.

Antes de ampliar a família de soluções, inspecionar no Search Console a URL nacional e as páginas
já publicadas. A ausência completa de `/solucoes/` no relatório precisa ser classificada como:

- ainda não indexada;
- indexada, mas sem impressões;
- canonical ou redirecionamento incorreto;
- descoberta recente aguardando novo rastreamento.

Critério inicial de sucesso:

- URL indexada;
- primeiras impressões para a consulta principal e variantes;
- evolução de posição em ciclos de 28 dias;
- sessões orgânicas avançando da solução para Easy Orça;
- contato ou CTA comercial identificado na mesma jornada.

### Prioridade 2 — transformar o Knowledge em canal de aquisição

Os primeiros acessos orgânicos validaram acórdãos e downloads como portas de entrada. Devemos
começar pelas páginas que já receberam visita real ou já possuíam posição entre 4 e 10.

**Aplicado em 24/10/2026 — padrão visual das páginas individuais:** artigos, casos práticos,
downloads, acórdãos, terminologia e dúvidas passaram a usar o mesmo sistema visual das landings de
produto: hero em duas colunas, seções amplas alternadas, blocos de aplicação prática e área de
descoberta. O breadcrumb foi reforçado como navegação clicável. Essa entrega resolve apresentação e
legibilidade; a expansão editorial e os links comerciais do primeiro lote continuam pendentes.

**Concluído e aprovado em 24/10/2026 — onerado × desonerado:** a primeira página do lote foi
reescrita como artigo técnico completo e passou a relacionar BDI e Leis Sociais durante a transição
de 2024 a 2028. A entrega inclui tabela comparativa, simulador público em abas para BDI e Leis
Sociais, regimes horista e mensalista, bloqueio das parcelas sem incidência no mensalista, exportação
dos valores efetivamente simulados para XLSX e eventos próprios de analytics. A implementação desta
página está encerrada; publicação, indexação e leitura de desempenho pertencem ao ciclo operacional
seguinte.

**Concluído em 24/10/2026 — Central de Downloads:** os cinco materiais publicados passaram a ter
página editorial integral em Markdown produzida pelo Easy e servida pelo R2. O Hub valida o campo
opcional `conteudo`, converte o Markdown em HTML indexável, preserva tabelas, mantém o PDF no card
principal e oferece links rastreáveis da central para cada página individual. Os cinco Markdown e
os cinco PDFs foram verificados com HTTP 200. A cartilha TCU de 2014 identifica de forma explícita
seu caráter histórico e a substituição pela edição de 2026. Permanecem para a etapa de arquitetura
interna os links contextuais efetivos entre os materiais e a classificação por assuntos no
manifesto; as referências hoje publicadas no texto não usam links Markdown.

**Concluído em 24/10/2026 — newsletters em HTML:** as 34 edições passaram a publicar conteúdo
integral em Markdown no R2. O Hub renderiza esse conteúdo como corpo indexável, mantém PDF e páginas
diagramadas como complementos e concentra o download no card principal da página canônica.

**Concluído em 24/10/2026 — arquitetura visual e navegação do Knowledge:** as páginas individuais
passaram a usar o padrão canônico aprovado, com conteúdo longo em uma coluna, largura adequada,
download no card principal e breadcrumb completo. Artigos, casos, dúvidas, acórdãos, terminologia,
downloads, newsletters, temas e ferramentas agora seguem `Axys › Axys Knowledge › central`, sempre
com destino rastreável. A página principal também passou a expor os destinos de Temas e Ferramentas.

**Concluído em 24/10/2026 — simulador público BDI/LS:** a ferramenta possui abas separadas, cálculo
em tempo real, tratamento de horista e mensalista, bloqueio das parcelas sem incidência, download da
simulação efetivamente preenchida e eventos próprios de analytics. A pauta de implementação está
encerrada; os próximos passos são publicação, indexação e leitura de uso.

Primeiro lote, agora ordenado por oportunidade observada no Search Console e por jornada real:

- ~~comparação entre orçamento onerado e desonerado~~ — concluída em 24/10/2026;
- truncar ou arredondar — implementação inicial concluída em 24/10/2026, aguardando revisão visual;
- ~~orientações para elaboração de planilhas orçamentárias~~ — página editorial do download concluída em 24/10/2026;
- Acórdão TCU 2622/2013;
- administração local;
- mobilização e desmobilização;
- ~~material IBRAOP OT-005 sobre sobrepreço e superfaturamento~~ — página editorial do download concluída em 24/10/2026;
- Acórdão TCU 1466/2013;
- Acórdão TCU 508/2018;
- encargos sociais horista e mensalista;
- BDI sem atalhos;
- conteúdos sobre aditivos e reequilíbrio.

Cada página deverá receber, conforme fizer sentido:

- resumo executivo original;
- problema analisado;
- entendimento técnico ou jurídico;
- impacto prático para orçamento, contratação, fiscalização ou medição;
- erros a evitar;
- perguntas frequentes;
- links para terminologia, artigos, casos e materiais relacionados;
- ponte editorial para a página de solução;
- CTA contextual para Easy Orça, Easy CPU, Easy Price, Easy LicitPlan ou EasyMobile.

O CTA não deve interromper a leitura nem transformar o conteúdo em propaganda. Ele deve responder ao
problema tratado na própria página.

### Prioridade 3 — hubs temáticos e arquitetura interna

Criar primeiro os hubs que conectam demanda técnica já observada com produtos:

- sobrepreço e superfaturamento;
- orçamento de referência;
- composição de custos unitários;
- SINAPI e bases referenciais;
- BDI e encargos sociais;
- jogo de planilha e curva ABC;
- fiscalização e medição;
- reajuste e reequilíbrio econômico-financeiro.

Cada hub deve reunir acórdãos, artigos, dúvidas, termos, casos, downloads e soluções. As centrais e
os conteúdos individuais devem apontar para os hubs, e os hubs devem devolver links para conteúdos
e produtos.

### Prioridade 4 — corrigir indexação e qualidade estrutural

- Remover do sitemap URLs redirecionadas, 404 e páginas que não devem ser indexadas.
- Corrigir as duas soft 404 identificadas no relatório anterior.
- Exportar as URLs concretas de cada motivo no novo pacote do Search Console.
- Transformar newsletters indexáveis em páginas HTML completas, com H1, resumo, destaques,
  metodologia, links e acesso ao PDF; aplicar `noindex` às que não receberem essa camada.
- Criar paginação e links HTML rastreáveis nas centrais.
- Reduzir páginas órfãs com relações editoriais reais.
- Enriquecer terminologias prioritárias e consolidar variações semanticamente duplicadas.
- Manter sitemap, canonical, status HTTP e links internos coerentes.

### Prioridade 5 — fechar lacunas de mensuração

- Corrigir `dwell_ms`, hoje nulo nas visualizações recentes.
- Adicionar UTMs próprios aos links distribuídos por WhatsApp, Instagram, e-mail e campanhas.
- Separar `site`, `instagram`, `whatsapp` e demais campanhas nos links das lojas.
- Investigar atribuição de instalação/primeiro uso permitida por App Store e Google Play.
- Revisar possível duplicidade de eventos ao alternar modalidades de uma composição no EasyMobile.
- Medir os funis:
  - conteúdo orgânico → solução → produto → contato;
  - landing EasyMobile → loja → cadastro → primeira busca → primeira composição → retorno em 7 dias.

Geolocalização analítica é desejável, mas secundária e deve respeitar consentimento, necessidade e
minimização de dados.

### Prioridade 6 — expansão editorial por produto

O catálogo da seção seguinte permanece como mapa de oportunidades, não como fila automática de
publicação. Uma nova URL só deve ser criada quando possuir intenção própria, conteúdo substancial,
links internos e destino comercial claro.


#### Marco concluído — landings comerciais
* Reposicionar title, H1 e descrição do Easy Orça.
* Expandir a landing com FAQ, recursos, público, bases de custos, fluxo e evidências.
* Criar a primeira página: sistema de orçamento de obras.
* Criar depois orçamento de obras públicas, orçamento SINAPI e composição de custos.
* Ligar conteúdos técnicos existentes a essas páginas e ao produto.

## Catálogo editorial de expansão por produto
Com as landings principais reposicionadas, a próxima etapa consiste em ampliar a cobertura orgânica de cada produto por meio de conteúdos associados a problemas, tarefas e dúvidas reais dos usuários.
As novas páginas não devem repetir a apresentação comercial das landings. Cada publicação precisa responder a uma intenção específica de pesquisa, oferecer conteúdo útil por si mesma e conduzir naturalmente o visitante ao produto relacionado.
A expansão pode combinar quatro formatos:
* Páginas de solução: apresentam uma necessidade concreta e como ela pode ser resolvida.
* Matérias e guias: aprofundam dúvidas técnicas, comparações, métodos e boas práticas.
* Estudos de caso: demonstram situações práticas, decisões tomadas e resultados alcançados.
* Tags e hubs temáticos: organizam conteúdos relacionados e distribuem links internos entre Knowledge, soluções e produtos.
Estrutura de relacionamento
Matéria, dúvida ou estudo de caso
                ↓
       Página de solução
                ↓
       Landing do produto
                ↓
   Demonstração, contato ou download
Cada página deverá possuir:
* uma intenção de busca principal;
* título e H1 próprios;
* conteúdo substancial e não repetitivo;
* exemplos e aplicação prática;
* links para conteúdos técnicos relacionados;
* link para a landing do produto;
* CTA coerente com o estágio do visitante;
* links de retorno a partir da landing e dos conteúdos associados.

Easy Price — estimativa preliminar e orçamento paramétrico
Páginas de solução
* Software de orçamento paramétrico
* Estimativa de custos de obras
* Orçamento preliminar de construção
* Custo estimado por metro quadrado
* Estimativa de custos para estudo de viabilidade
* Orçamento estimativo para ETP e anteprojeto
* Comparação de cenários de custos de empreendimentos
Matérias e guias
* O que é orçamento paramétrico e quando utilizar
* Diferença entre orçamento paramétrico, estimativo e analítico
* Como estimar o custo de uma obra com poucas informações
* Como a localização interfere no custo de construção
* Custo por metro quadrado: limites e forma correta de utilização
* Qual nível de precisão esperar em cada fase do projeto
* Como apresentar uma estimativa preliminar para tomada de decisão
Estudos de caso
* Estimativa inicial de uma escola antes do projeto executivo
* Comparação de padrões construtivos para um mesmo empreendimento
* Avaliação de viabilidade entre duas localizações
* Atualização de uma estimativa após evolução do projeto
* Estimativa de custos para subsidiar um ETP
Tags
orçamento paramétrico, estimativa de custos, custo por metro quadrado, estudo de viabilidade, anteprojeto, orçamento preliminar, tipologia construtiva.

Easy CPU — composição de custos e aproveitamento de planilhas
Páginas de solução
* Sistema de composição de custos
* Composição de preços unitários
* Orçamento analítico a partir do Excel
* Importação de planilha orçamentária
* Composições SINAPI e SICRO
* Atualização de orçamento por bases referenciais
* Associação de serviços a composições de custos
Matérias e guias
* O que é uma composição de custo unitário
* Como transformar uma planilha sintética em orçamento analítico
* Como relacionar serviços de uma planilha ao SINAPI
* Diferença entre composição própria e composição referencial
* Como tratar serviços sem correspondência nas bases oficiais
* Como atualizar preços mantendo os quantitativos existentes
* Cuidados ao importar uma planilha de orçamento
* Como interpretar coeficientes, insumos e produtividades
Estudos de caso
* Planilha recebida sem composições analíticas
* SINAPI e SICRO utilizados no mesmo orçamento
* Tratamento de descrições diferentes para serviços equivalentes
* Atualização de uma planilha antiga para nova data-base
* Identificação de itens sem referência de custos
Tags
composição de custos, CPU, preço unitário, orçamento analítico, SINAPI, SICRO, insumos, coeficientes, planilha orçamentária.

Easy Orça — elaboração completa do orçamento
Páginas de solução
* Sistema de orçamento de obras
* Software para orçamento de construção civil
* Orçamento de obras públicas
* Orçamento SINAPI
* Orçamento analítico e sintético
* Curva ABC de obras
* Cálculo de BDI e encargos sociais
* Cronograma físico-financeiro do orçamento
* Memória de cálculo de orçamento
* Revisão e controle de versões do orçamento
Matérias e guias
* Como elaborar um orçamento de obras
* Etapas de um orçamento completo de engenharia
* Diferença entre orçamento sintético e analítico
* Como escolher a data-base do orçamento
* Como trabalhar com múltiplos BDIs
* Como elaborar a curva ABC de serviços e insumos
* Como documentar a memória de cálculo
* Como revisar um orçamento sem perder o histórico
* Principais erros em planilhas orçamentárias
* Como preparar um orçamento para licitação
Estudos de caso
* Comparação entre orçamento onerado e desonerado
* Serviço inexistente no SINAPI e criação de composição própria
* Revisão do orçamento após alteração de quantitativos
* Uso de bases de diferentes estados em um mesmo projeto
* Controle das alterações entre orçamento inicial e versão final
* Aplicação de BDI diferenciado em itens específicos
Tags
orçamento de obras, orçamento público, SINAPI, BDI, encargos sociais, curva ABC, cronograma físico-financeiro, memória de cálculo, planilha orçamentária.

Easy Docs — memoriais e especificações técnicas
Páginas de solução
* Software para memorial descritivo
* Sistema para especificações técnicas
* Memorial descritivo de obra
* Caderno de especificações técnicas
* Memorial descritivo com BIM
* Documentação técnica a partir de modelo IFC
* Padronização de documentos de engenharia
Matérias e guias
* O que deve constar em um memorial descritivo
* Diferença entre memorial descritivo e especificação técnica
* Como organizar um caderno de especificações
* Principais omissões em documentos técnicos de obras
* Como relacionar orçamento e especificação técnica
* Como utilizar informações do IFC na documentação
* Como revisar memoriais entre disciplinas
* Padronização documental em empresas e órgãos públicos
Estudos de caso
* Memorial produzido sem modelo BIM
* Geração documental a partir de arquivo IFC
* Divergência entre especificação e planilha orçamentária
* Padronização de memoriais de uma carteira de projetos
* Revisão de requisitos antes da licitação
Tags
memorial descritivo, especificação técnica, caderno de especificações, documentação de engenharia, BIM, IFC, requisitos técnicos.

Easy ProjectManager — gestão de projetos de engenharia
Páginas de solução
* Sistema de gestão de projetos de engenharia
* Gestão documental de projetos
* Coordenação de projetos multidisciplinares
* Controle de entregáveis de engenharia
* Estrutura de pastas ASBEA
* Controle de revisões de projetos
* Padronização de nomenclaturas de arquivos
Matérias e guias
* Como organizar um projeto de engenharia
* Como estruturar pastas e documentos técnicos
* Como aplicar uma estrutura baseada no padrão ASBEA
* Como controlar revisões e versões de projetos
* Como organizar entregáveis por disciplina
* Checklist para recebimento de projetos
* Como reduzir perda de contexto entre projetistas
* Diferença entre armazenamento de arquivos e gestão documental
Estudos de caso
* Organização de um projeto multidisciplinar
* Reestruturação de uma pasta técnica desorganizada
* Controle de revisões entre arquitetura e projetos complementares
* Validação de entregáveis antes da medição
* Padronização de nomenclaturas em uma organização
Tags
gestão de projetos, coordenação de projetos, gestão documental, ASBEA, controle de revisões, entregáveis, projetos multidisciplinares.

Easy BuildDiary — diário de obras digital
Páginas de solução
* Aplicativo de diário de obras
* Diário de obras digital
* Relatório diário de obra
* Diário de obra com fotos
* Registro de ocorrências de obra
* Controle de mão de obra e equipamentos em campo
* Evidências para fiscalização e medição
Matérias e guias
* O que deve constar em um diário de obras
* Como preencher corretamente o diário de obra
* Quem deve assinar e validar o diário de obra
* Como registrar paralisações e ocorrências
* Como organizar fotografias da execução
* Diário de obras como evidência contratual
* Relação entre diário, fiscalização e medição
* Erros comuns em relatórios diários de obra
Estudos de caso
* Registro de paralisação por condição climática
* Divergência entre contratada e fiscalização
* Evidências fotográficas para medição de serviço
* Ocorrência de campo com impacto no cronograma
* Reconstrução do histórico de execução de uma etapa
Tags
diário de obras, relatório diário, fiscalização, registro fotográfico, ocorrências, evidências de campo, mão de obra, equipamentos.

Easy FinControl — medições e controle físico-financeiro
Páginas de solução
* Sistema de medição de obras
* Controle físico-financeiro de obras
* Acompanhamento de avanço físico
* Controle de saldo contratual
* Comparação entre previsto e realizado
* Histórico de medições de serviços
* Gestão financeira de contratos de obras
Matérias e guias
* Como fazer medição de obras
* O que é controle físico-financeiro
* Como comparar avanço previsto e realizado
* Como controlar o saldo de um contrato
* Como organizar o histórico de medições
* Medição por etapas e eventos
* Como tratar reajustes e alterações contratuais
* Diferença entre avanço físico e avanço financeiro
* Principais erros em boletins de medição
Estudos de caso
* Serviço executado acima da quantidade contratada
* Retenção aplicada na última medição
* Divergência entre avanço físico e financeiro
* Aditivo com impacto no saldo contratual
* Reprogramação do cronograma após atraso
* Controle de medições de múltiplos contratos
Tags
medição de obras, controle físico-financeiro, avanço físico, saldo contratual, boletim de medição, previsto e realizado, reajuste, aditivo.

Easy LicitPlan — planejamento das contratações públicas
Páginas de solução
* Software para elaborar ETP
* Sistema para Termo de Referência
* Planejamento de contratações públicas
* Matriz de riscos para licitações
* Elaboração de requisitos técnicos
* Critérios de medição em contratos públicos
* Fase preparatória da Lei 14.133
Matérias e guias
* Como elaborar um Estudo Técnico Preliminar
* O que deve constar no Termo de Referência
* Diferença entre ETP e Termo de Referência
* Como definir requisitos sem restringir a competição
* Como construir uma matriz de riscos
* Como definir critérios de medição
* Principais documentos da fase preparatória
* Como manter coerência entre necessidade, solução e contratação
* Erros comuns no planejamento de licitações
Estudos de caso
* Requisito técnico incompatível com o objeto
* Divergência entre ETP e Termo de Referência
* Critério de medição insuficiente
* Risco sem responsável ou resposta definida
* Alteração da solução durante a fase preparatória
* Contratação de serviço de engenharia pela Lei 14.133
Tags
ETP, Termo de Referência, Lei 14.133, matriz de riscos, contratação pública, fase preparatória, critérios de medição, requisitos técnicos.

Easy One — gestão integrada para órgãos públicos
Páginas de solução
* Sistema de gestão de obras públicas
* Plataforma para engenharia pública
* Gestão integrada de contratos e obras
* Governança de contratações públicas
* Controle de usuários internos e externos
* Integração entre planejamento, orçamento e execução
* Gestão de carteira de obras públicas
Matérias e guias
* Como integrar o ciclo de uma obra pública
* Da necessidade à medição: etapas da contratação
* Como evitar perda de informação entre departamentos
* Governança de usuários internos e externos
* Rastreabilidade de decisões em contratos públicos
* Como integrar orçamento, projeto e fiscalização
* Indicadores para uma carteira de obras públicas
* Estrutura de governança para engenharia municipal
Estudos de caso
* Integração entre setor demandante e equipe de engenharia
* Transferência do orçamento para acompanhamento da execução
* Gestão simultânea de vários contratos e obras
* Controle de acesso de projetistas, fiscais e contratadas
* Auditoria do histórico de uma contratação
* Padronização de processos entre secretarias ou unidades
Tags
obras públicas, engenharia pública, governança, gestão de contratos, fiscalização, contratações públicas, carteira de obras, auditoria.

EasyMobile — guia de bolso da engenharia de custos
Páginas de solução
* Aplicativo de engenharia de custos
* Consulta de custos de obras pelo celular
* Aplicativo para consultar SINAPI
* Consulta de composições e insumos
* Série histórica de preços da construção
* Simulador de BDI e encargos sociais
* Guia de bolso para orçamento de obras
Matérias e guias
* Como consultar custos de obras pelo celular
* Como pesquisar composições e insumos
* Como interpretar uma composição de custos
* Como acompanhar a série histórica de preços
* Como consultar diferentes edições do SINAPI
* Como simular BDI e encargos sociais
* Ferramentas úteis para orçamentistas em campo
* Fontes de preços da construção disponíveis no Brasil
Estudos de caso
* Consulta rápida de um insumo durante visita à obra
* Comparação do preço de uma composição entre períodos
* Verificação de referência antes de uma reunião
* Simulação de BDI diretamente pelo celular
* Pesquisa de jurisprudência durante análise técnica
Tags
aplicativo de engenharia, engenharia de custos, SINAPI, consulta de preços, composição de custos, série histórica, BDI, orçamento de obras, guia de bolso.

Expansão geográfica
A cobertura regional deverá ocorrer apenas quando houver conteúdo técnico próprio. Não serão criadas páginas municipais apenas com troca do nome da cidade.
Páginas estaduais podem ser justificadas quando reunirem:
* bases referenciais específicas;
* peculiaridades regionais;
* fontes estaduais;
* estudos de caso locais;
* séries históricas;
* conteúdo produzido para aquela região.
Exemplos:
* Orçamento de obras em São Paulo: SINAPI-SP, CDHU e FDE.
* Orçamento de obras em Minas Gerais: SINAPI-MG e referências estaduais aplicáveis.
* Orçamento de obras no Paraná: SINAPI-PR e bases regionais disponíveis.
A página nacional de cada solução continuará sendo o destino principal para pesquisas genéricas e localidades sem conteúdo próprio.
Critério de priorização
A publicação deve seguir esta ordem:
1. intenções diretamente ligadas à compra ou adoção do produto;
2. pesquisas técnicas já identificadas no Search Console;
3. problemas frequentes observados em atendimento e demonstrações;
4. conteúdos para os quais a Axys possui conhecimento ou dados próprios;
5. estudos de caso que comprovem aplicação prática;
6. variações regionais com diferenciação técnica legítima.
O objetivo não é aumentar indiscriminadamente o número de URLs. A meta é construir uma rede de conteúdos úteis que amplie a entrada orgânica, demonstre autoridade técnica e leve o visitante até a solução adequada sem repetição ou canibalização.

---

### Prioridade 7 — autoridade externa legítima

O site precisa conquistar links editoriais vindos de:

- conselhos e associações;
- portais de engenharia;
- universidades e cursos;
- parceiros e clientes;
- artigos técnicos assinados;
- materiais originais citáveis, como calculadoras, guias e levantamentos.

Não comprar pacotes de links nem fazer trocas em massa. A melhor oportunidade é produzir ativos que
mereçam citação: estudos sobre variação de custos, comparativos de bases, calculadoras, modelos,
guias técnicos e análises de decisões relevantes.

## Próxima sequência operacional

1. Baixar o novo pacote do Search Console.
2. Publicar ou revisar a página nacional “sistema para orçamento de obras”.
3. Enriquecer o primeiro lote de acórdãos e o material IBRAOP.
4. Implementar links entre conteúdo, hub, solução e produto.
5. Corrigir `dwell_ms` e parametrizar as campanhas.
6. Medir por 28 dias antes de escalar o catálogo editorial.

A recomendação vigente é começar pela lacuna comercial de “sistema para orçamento de obras” e,
simultaneamente, usar as páginas técnicas que já recebem Google para transferir autoridade e usuários
ao Easy Orça. Páginas estaduais entram somente depois de a estrutura nacional demonstrar resultado.

