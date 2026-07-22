# AXYS — Marketing Analytics

> Status: Contrato Canônico (V1A)
> Escopo: Site público `www.axys-tec.com.br`
> Base consolidada em: 18/07/2026
> Fonte de motivação: conversa completa + consolidação contratual local

---

# Objetivo deste documento

Este documento existe para responder quatro perguntas:

1. A proposta atual é madura o suficiente para nascer bem?
2. Ela é profunda o suficiente para uma empresa com potencial de escala?
3. Ela conversa corretamente com a app, com o schema atual e com o propósito do Hub?
4. Se formos seguir, qual deve ser o schema inicial canônico?

---

# Leitura da motivação real

A conversa completa mostra que a ideia não nasceu de uma preocupação genérica com analytics.

Ela nasceu de uma necessidade muito mais valiosa:

- entender quais temas despertam desejo no mercado;
- medir intenção, não só audiência;
- transformar navegação pública em inteligência comercial;
- aprender com comportamento antes mesmo de existir login;
- separar claramente marketing externo, inteligência do visitante e telemetria futura da app.

Essa motivação é correta e estratégica.

O ponto central é este:

> a AXYS não quer apenas saber quantas pessoas chegaram;
> a AXYS quer descobrir o que o mercado está tentando resolver.

Isso é coerente com a proposta do ecossistema e com o posicionamento de produto técnico.

---

# Veredito executivo

## Conclusão curta

A proposta está madura como visão de negócio e como decisão conceitual.

Depois das rodadas de refinamento, ela amadureceu o suficiente para avançar ao contrato técnico.

Com as decisões finais já consolidadas neste documento, o núcleo V1A está maduro para virar DDL.

## Decisão recomendada

Seguir com a proposta, mas não copiar a modelagem simplificada do documento original.

A recomendação é adotar uma V1A enxuta, com:

- identidade anônima do visitante;
- sessões;
- page views;
- catálogo versionado de eventos;
- eventos brutos com idempotência;
- enriquecimento e consolidação posterior via worker.

---

# O que a proposta acertou

## 1. Separação em três camadas

`Marketing Configuration`, `Visitor Intelligence` e `Product Telemetry` é uma divisão correta.

Ela evita misturar:

- integrações com terceiros;
- comportamento do site público;
- telemetria operacional da app.

## 2. Visitor anônimo em vez de identificação pessoal

Essa escolha é madura.

O objetivo da V1 não é CRM, nem fingerprinting agressivo.

O objetivo é continuidade comportamental mínima.

## 3. Foco em intenção

A maior força da proposta está em não limitar o modelo a pageviews.

Eventos como:

- `product_open`
- `pricing_open`
- `faq_expand`
- `cta_click`
- `create_account`

são mais valiosos do que “visitou a página X”.

## 4. Vínculo futuro com identidade real

O encadeamento:

`visitor -> lead -> user -> tenant`

é conceitualmente muito forte e conversa com a evolução natural do Hub.

---

# O que ainda está fraco

## 1. A modelagem está simplificada demais

No texto original, `mkt_visitor`, `mkt_session` e `mkt_event` carregam responsabilidades demais.

Isso gera risco de:

- baixa rastreabilidade;
- pouca flexibilidade analítica;
- retrabalho quando a plataforma crescer.

## 2. Sessão com contadores agregados é pouco auditável

Guardar `pages` e `events` direto em `mkt_session` é útil como derivado, mas fraco como base canônica.

O correto é tratar:

- `session` como contexto;
- `page_view` como fato;
- `event` como fato.

## 3. Falta governança de atribuição

O documento cita referrer, UTM e origem, mas ainda não separa:

- first touch;
- current touch;
- last touch relevante;
- touch de conversão.

Sem isso, a leitura comercial tende a ficar ambígua.

## 4. Lead score precisa ser governado

Guardar score implícito por evento sem uma tabela de regra versionada é perigoso.

Se os pesos mudarem, o histórico fica conceitualmente inconsistente.

## 5. Falta política explícita de retenção e privacidade

O documento está bem-intencionado ao dizer para não guardar IP bruto permanentemente.

Mas falta definir:

- retenção curta para IP temporário;
- granularidade permitida de geolocalização;
- quando um visitor pode ser vinculado a lead;
- quando o consentimento é necessário por categoria.

---

# Validação contra a app atual

## Leitura funcional da app pública

A landing pública atual do Hub já oferece uma superfície clara para analytics:

- hero principal;
- CTA “Conhecer soluções”;
- CTA “Explorar AxysEasy”;
- cards e modais de microapps;
- ida para `/combo`;
- formulário de contato;
- links externos para WhatsApp e Instagram.

Isso significa que já existe material suficiente para uma V1 útil.

## Oportunidades reais de eventos

A app atual permite medir com valor:

- `homepage_open`
- `hero_solutions_click`
- `hero_easy_click`
- `section_view`
- `product_modal_open`
- `product_plans_open`
- `product_cta_click`
- `combo_open`
- `contact_form_open`
- `contact_form_submit`
- `whatsapp_click`
- `instagram_click`
- `signup_open`
- `signup_submit_start`

## Limitação atual da app

Hoje a principal limitação já não é mais a captura básica, e sim a governança
do catálogo de eventos, o consentimento e o vínculo progressivo entre
`visitor` e `commercial.lead`.

A base atual já permite:

- registrar navegação anônima por visitor e sessão;
- medir interesse por produto e CTA;
- criar ou reaproveitar lead nos fluxos públicos identificados;
- associar a conversão identificada ao contexto analítico anterior.

Os próximos cuidados passam a ser:

- manter o catálogo de eventos enxuto e semânticamente claro;
- respeitar consentimento na superfície pública;
- evoluir o vínculo entre comportamento anônimo e lead identificado sem agressividade comercial.

---

# Validação contra o schema atual

## O que já existe e ajuda

O schema atual já tem blocos comerciais úteis:

- `commercial.lead`
- `commercial.referral_visit`
- `commercial.tenant_attribution`

Também já existem identidades e estruturas de vínculo:

- `identity.hub_user`
- `identity.hub_tenant`
- `product.product`
- `audit.audit_log`

## O que não existe ainda

Não existe hoje um domínio canônico específico para analytics do site público.

Ou seja:

- o problema existe;
- o schema ainda não tem uma “casa” adequada para isso.

## Leitura arquitetural recomendada

A recomendação consolidada deste documento é:

- um único schema `analytics` na V1;
- com separação interna entre contexto, fatos e configuração;
- sem espalhar o domínio cedo demais em múltiplos schemas.

---

# Validação contra o propósito do Hub

## Aderência estratégica

Essa proposta conversa muito bem com o propósito do Hub porque o Hub já é o eixo institucional e comercial do ecossistema.

O Hub não serve apenas para login.

Ele também é:

- porta de entrada;
- catálogo;
- interface comercial;
- ponte entre descoberta e produto.

## Risco de desalinhamento

O risco seria transformar essa frente em um “mini Google Analytics”.

Isso seria pequeno demais para a AXYS e ao mesmo tempo complexo demais para manter.

A direção correta é:

- menos dashboard genérico;
- mais leitura de intenção técnica e comercial.

---

# Proposta de modelagem canônica

## Diretrizes gerais

- `visitor_id` é o identificador principal do visitante anônimo.
- IP bruto não é identificador canônico.
- Geolocalização deve ser derivada e armazenada já reduzida.
- `page_view` e `event` são fatos brutos.
- score é derivado por regra.
- vínculo com lead/user/tenant é explícito, não implícito.

---

# Ajustes de arquitetura após refinamento crítico

## O que muda em relação à primeira versão da proposta

Após uma segunda leitura crítica, alguns ajustes ficam mais maduros para a V1:

- reduzir o número de tabelas interpretativas já no nascimento;
- explicitar melhor a diferença entre fato, derivado e interpretação;
- introduzir um catálogo de tipos de evento;
- documentar o papel do worker analítico;
- tratar a estrutura de aquisição com mais cautela para não supermodelar cedo demais.

## Regra de ouro para esta V1

Se uma informação puder ser:

- rederivada com segurança;
- recalculada por job;
- ou interpretada de formas diferentes no futuro;

ela não deve nascer como fato canônico sem necessidade real.

---

# Natureza dos blocos

## Entidades de contexto

- `visitor`
- `session`

Essas tabelas representam continuidade e contexto operacional da navegação.

## Fatos

- `page_view`
- `event`

Esses são os fatos brutos mínimos da captura.

## Configuração e dimensão semântica

- `provider_config`
- `event_type`
- `score_rule`

Essas tabelas definem semântica, governança e integração.

## Derivados

Podem nascer depois, por worker, materialized view ou tabela auxiliar:

- duração final consolidada da sessão;
- bounce consolidado;
- score total;
- ranking de interesse;
- dashboards por produto/origem/região.

## Interpretações

Devem nascer por último e com mais cuidado:

- `lead_signal`
- bandas de temperatura comercial;
- classificação de desejo do mercado;
- alertas de “visitor quente”.

Isso porque interpretação muda com frequência.

---

# Fases de implantação

## V1A — captura confiável

O núcleo mínimo recomendado para a primeira implantação é:

- `analytics.visitor`
- `analytics.session`
- `analytics.page_view`
- `analytics.event_type`
- `analytics.event`

Objetivo:

- capturar com confiabilidade;
- manter rastreabilidade;
- evitar interpretação precoce.

## V1B — interpretação governada

Entram logo depois, sem bloquear a implantação inicial:

- `analytics.score_rule`
- `analytics.identity_link`
- derivados materializados por worker

Objetivo:

- introduzir leitura comercial e score com governança;
- sem contaminar o núcleo de captura.

---

# Bounded context

## Nome do schema

A primeira versão da proposta separou `marketing` e `visitor`.

Essa separação continua semanticamente boa, mas para a V1 existe um argumento forte para simplificar o bounded context em um único schema.

Nome recomendado para discussão:

- `analytics`

Nome alternativo curto:

- `mkt`

## Decisão recomendada

Para a V1, eu tenderia a um único schema:

- `analytics`

Racional:

- reduz dispersão inicial;
- mantém o contexto unido;
- facilita leitura do domínio enquanto ele ainda está nascendo;
- permite subáreas internas sem forçar duas fronteiras cedo demais.

Se no futuro houver crescimento relevante, ainda será simples separar logicamente:

- configuração de providers;
- comportamento do visitante;
- interpretação comercial.

---

# Schema `analytics`

## Tabela `analytics.provider_config`

**motivo:**
Centralizar a configuração de integrações externas de marketing e observabilidade de audiência.

**nivel de controle:**
Alto. A AXYS liga, desliga e versiona o que é enviado para terceiros.

**como funciona:**
Cada provider externo fica cadastrado com seu tipo, status, credenciais e configuração JSON.
Essa tabela não mede comportamento interno; ela apenas controla conectores externos.

**como ler/usar:**
Consultar para saber quais integrações estão habilitadas em cada ambiente e quais parâmetros devem ser carregados no frontend ou backend.

**campos propostos:**

- `provider_config_id`
- `provider_code`
- `provider_name`
- `provider_type`
- `status`
- `measurement_id`
- `secret_ref`
- `config_json`
- `created_at`
- `updated_at`

---

## Tabela `analytics.visitor`

**motivo:**
Representar o navegador anônimo como unidade persistente mínima de comportamento.

**nivel de controle:**
Altíssimo. É a entidade raiz da inteligência de navegação.

**como funciona:**
Na primeira visita, o frontend cria ou recebe um `visitor_id` estável.
Esse registro não representa pessoa física; representa continuidade de navegação.

**como ler/usar:**
Usar para responder:

- quantos visitantes únicos reais existem;
- como o mesmo visitor retorna ao longo do tempo;
- quando um visitor depois virou lead ou usuário.

**campos propostos:**

- `visitor_id`
- `site_code`
- `first_seen_at`
- `last_seen_at`
- `first_referrer_url`
- `first_landing_path`
- `first_country_code`
- `first_region_code`
- `first_city`
- `preferred_language`
- `created_at`
- `updated_at`

**decisão final consolidada:**

- `visitor_id UUID PRIMARY KEY`
- `site_code TEXT NOT NULL`
- não criar `visitor_uuid` redundante

O visitor é escopado por propriedade digital.

Exemplo inicial:

- `AXYS_PUBLIC`

---

## Tabela `analytics.session`

**motivo:**
Representar cada visita ativa com começo, fim e contexto técnico de navegação.

**nivel de controle:**
Alto. É o contêiner da jornada de uma visita.

**como funciona:**
Cada visitor pode abrir várias sessões ao longo do tempo.
A sessão concentra contexto de device, ambiente e aquisição imediata, mas não substitui os fatos detalhados.

**como ler/usar:**
Usar para medir:

- retorno;
- duração;
- profundidade;
- contexto do acesso.

**campos propostos:**

- `session_id`
- `visitor_id`
- `started_at`
- `last_activity_at`
- `ended_at`
- `duration_ms`
- `exit_path`
- `device_type`
- `browser_family`
- `os_family`
- `screen_width`
- `screen_height`
- `timezone`
- `country_code`
- `region_code`
- `city`
- `referrer_url`
- `utm_source`
- `utm_medium`
- `utm_campaign`
- `utm_term`
- `utm_content`
- `landing_path`
- `created_at`

**nota contratual importante:**

Os campos abaixo não nascem obrigatoriamente no `INSERT` inicial:

- `ended_at`
- `duration_ms`
- `exit_path`

Eles devem:

- nascer `NULL` quando aplicável;
- ser preenchidos ou consolidados pelo `Analytics Worker`;
- ser tratados como derivados recalculáveis;
- nunca substituir os fatos de `page_view` e `event`.

**nota sobre engajamento e bounce:**

Para a V1, é mais maduro preferir derivados objetivos como:

- `page_view_count`
- `event_count`
- `engaged_at`

e deixar `bounce` como view, dashboard ou regra derivada.
Isso evita cristalizar cedo uma definição semântica frágil.

**decisões finais consolidadas:**

- remover `entry_path`
- manter apenas `landing_path`
- fechar sessão por `last_activity_at + 30 minutos`
- consolidar `ended_at = last_activity_at`

---

## Tabela `analytics.page_view`

**motivo:**
Guardar a visualização de páginas como fato canônico e auditável.

**nivel de controle:**
Altíssimo. É base de funil e jornada.

**como funciona:**
Cada página aberta gera um registro com path, título lógico, ordem na sessão e permanência estimada.

**como ler/usar:**
Usar para:

- funis de navegação;
- páginas mais visitadas;
- tempo por página;
- entrada e saída reais.

**decisão contratual recomendada:**

Na V1, não repetir `visitor_id` em `page_view`.

Racional:

- `session_id` já determina o visitor;
- reduz risco de inconsistência;
- simplifica o núcleo inicial.

Se a denormalização for necessária no futuro por volume ou benchmark, ela deve ser introduzida como decisão explícita de performance.

**campos propostos:**

- `page_view_id`
- `session_id`
- `ingestion_key`
- `sequence_no`
- `page_path`
- `page_title`
- `page_type`
- `product_id`
- `dwell_ms`
- `referrer_path`
- `viewed_at`

**decisões finais consolidadas:**

- `ingestion_key UUID NOT NULL`
- `UNIQUE (ingestion_key)`
- `UNIQUE (session_id, sequence_no)`

Modal não é `page_view`.

---

## Tabela `analytics.event_type`

**motivo:**
Catalogar tipos de evento para evitar typo, centralizar significado e permitir governança do que é rastreado.

**nivel de controle:**
Altíssimo. É o dicionário semântico dos eventos.

**como funciona:**
A cada evento rastreável corresponde um código canônico, uma categoria e sinalizadores de uso.
A tabela `event` aponta para esse catálogo em vez de depender apenas de texto livre.

**como ler/usar:**
Usar para:

- documentar eventos ativos;
- desligar ou descontinuar eventos;
- classificar eventos por grupo;
- controlar o que entra em score e dashboards.

**campos propostos:**

- `event_type_id`
- `event_code`
- `event_version`
- `event_name`
- `category`
- `scope`
- `description`
- `is_public`
- `is_enabled`
- `is_scoreable`
- `payload_schema_json`
- `valid_from`
- `valid_until`
- `created_at`
- `updated_at`

**nota contratual importante:**

`event_type` precisa suportar evolução semântica sem reescrever a história.

Recomendação:

- `event_code = pricing_open`
- `event_version = 1`

com unicidade em:

- `(event_code, event_version)`

Assim o código lógico continua legível, mas o significado histórico permanece auditável.

**decisões finais consolidadas:**

- `event_type_id BIGINT`
- `UNIQUE (event_code, event_version)`
- `payload_schema_json` como contrato leve inspirado em JSON Schema

---

## Tabela `analytics.event`

**motivo:**
Registrar eventos de intenção e interação fina do visitante.

**nivel de controle:**
Altíssimo. É o núcleo do modelo de inteligência.

**como funciona:**
Cada ação relevante gera um evento com tipo, contexto e metadados.
Exemplo: abrir modal de produto, clicar CTA, abrir pricing, iniciar cadastro.

**como ler/usar:**
Usar para:

- descobrir intenção por produto;
- comparar desejo por funcionalidade;
- compor score;
- medir conversão entre etapas.

**decisão contratual recomendada:**

Na V1, não repetir `visitor_id` em `event`.

O visitor deve ser recuperado via `session`.
Se no futuro a denormalização passar a valer a pena, ela deve entrar como otimização consciente.

**campos propostos:**

- `event_id`
- `session_id`
- `page_view_id`
- `ingestion_key`
- `event_type_id`
- `component`
- `product_id`
- `feature_code`
- `value_numeric`
- `metadata_json`
- `occurred_at`

**decisões finais consolidadas:**

- `ingestion_key UUID NOT NULL`
- `UNIQUE (ingestion_key)`
- garantir integridade entre `page_view_id` e `session_id` no banco

---

## Tabela `analytics.identity_link`

**motivo:**
Vincular o histórico anônimo a uma identidade conhecida quando houver conversão.

**nivel de controle:**
Altíssimo. É a ponte entre marketing e operação.

**como funciona:**
Quando o visitor se torna lead, user ou tenant, o sistema registra explicitamente o vínculo e o motivo da associação.

**como ler/usar:**
Usar para responder:

- qual comportamento antecedeu uma criação de conta;
- quais jornadas geram clientes;
- quais fontes trazem tenants melhores.

**campos propostos:**

- `identity_link_id`
- `visitor_id`
- `lead_id`
- `user_id`
- `tenant_id`
- `link_type`
- `link_source`
- `linked_at`

---

**nota de maturidade:**
Esta tabela é útil, mas pode nascer em uma segunda etapa se a V1 ainda não internalizar conversão suficiente para justificar o vínculo persistido.

---

## Tabela `analytics.score_rule`

**motivo:**
Versionar a lógica de pontuação para não contaminar o histórico quando a régua mudar.

**nivel de controle:**
Alto. A regra precisa ser explícita e auditável.

**como funciona:**
Cada regra define quantos pontos um evento ou condição acrescenta a determinado objetivo.

**como ler/usar:**
Usar para recalcular score, revisar hipótese comercial e comparar modelos de leitura de intenção.

**campos propostos:**

- `score_rule_id`
- `rule_code`
- `rule_name`
- `event_name`
- `product_code`
- `feature_code`
- `points`
- `status`
- `valid_from`
- `valid_until`
- `config_json`

**posição recomendada:**

`score_rule` pertence à V1B.

Ela pode constar no contrato-alvo do módulo desde já, mas não deve bloquear a primeira implantação de captura.

---

# Contrato técnico da V1A

Esta seção fecha o contrato técnico das cinco tabelas centrais de captura.

Escopo:

- sem SQL;
- sem implementação;
- sem tabelas derivadas;
- apenas decisões estruturais que custam caro para mudar depois.

---

## `analytics.visitor`

### Natureza

Entidade de contexto.

### Responsabilidade exclusiva

Representar a continuidade anônima de um navegador ou agente visitante ao longo do tempo.

### O que não pertence à tabela

- sessão;
- page views;
- eventos;
- score;
- interpretação comercial;
- origem de campanha por múltiplos toques;
- identidade real de lead/user/tenant.

### PK e estratégia de geração

- `visitor_id UUID PRIMARY KEY`

Decisão recomendada:

- uma única PK UUID;
- sem `BIGINT` interno adicional na V1;
- sem `visitor_uuid` redundante.

Geração:

- preferencialmente aceita do frontend quando válida;
- criada pelo backend quando ausente ou inválida;
- persistida de forma idempotente.

### Campos obrigatórios no INSERT

- `visitor_id`
- `site_code`
- `first_seen_at`
- `last_seen_at`
- `created_at`

### Campos opcionais

- `first_referrer_url`
- `first_landing_path`
- `first_country_code`
- `first_region_code`
- `first_city`
- `preferred_language`
- `updated_at`

### Campos consolidados pelo worker

Nenhum é estritamente dependente do worker.

O worker pode enriquecer:

- geolocalização reduzida;
- linguagem preferencial consolidada;
- normalizações complementares.

### Mutabilidade permitida

- `last_seen_at` pode avançar;
- atributos enriquecidos podem ser preenchidos posteriormente;
- `first_*` não devem ser reescritos depois de definidos, salvo correção operacional controlada.

### Regra de idempotência

Se o mesmo `visitor_id` chegar novamente:

- não criar novo visitor;
- apenas atualizar `last_seen_at` e preencher campos faltantes quando permitido.

### Integridade e cardinalidade

- `visitor 1 -> N session`
- visitor existe antes ou no momento da primeira sessão.

### Retenção

Retenção longa, pois é a raiz da continuidade histórica.

Sugestão de política:

- manter enquanto o módulo existir, salvo política posterior de expurgo anonimizado.

### Volume esperado

Baixo a médio no início.

Tende a crescer linearmente com visitantes únicos e bem menos que `event`.

### Índices mínimos

- PK em `visitor_id`
- índice por `last_seen_at`

### Constraints mínimas

- `visitor_id` deve ser UUID válido
- `last_seen_at >= first_seen_at`

### Fluxo de escrita

1. frontend envia ou recupera identificador anônimo;
2. backend valida;
3. cria ou reaproveita o visitor;
4. atualiza `last_seen_at`.

### Fluxo de leitura

Leitura por:

- `visitor_id`
- coortes temporais
- continuidade de navegação

### Riscos e decisões pendentes

- visitor fica explicitamente escopado por propriedade digital via `site_code`;
- valor inicial recomendado: `AXYS_PUBLIC`;
- tabela própria de sites pode nascer depois, se o ecossistema público se multiplicar.

---

## `analytics.session`

### Natureza

Entidade de contexto.

### Responsabilidade exclusiva

Representar uma visita ativa ou consolidada com contexto técnico de entrada, device e aquisição imediata.

### O que não pertence à tabela

- page views como fatos individuais;
- eventos como fatos individuais;
- score;
- classificação comercial;
- múltiplos touches complexos de atribuição.

### PK e estratégia de geração

- `session_id UUID PRIMARY KEY`

Geração:

- criada pelo backend no início da sessão;
- frontend reaproveita enquanto a sessão estiver ativa.

### Campos obrigatórios no INSERT

- `session_id`
- `visitor_id`
- `started_at`
- `last_activity_at`
- `created_at`

### Campos opcionais

- `device_type`
- `browser_family`
- `os_family`
- `screen_width`
- `screen_height`
- `timezone`
- `country_code`
- `region_code`
- `city`
- `referrer_url`
- `utm_source`
- `utm_medium`
- `utm_campaign`
- `utm_term`
- `utm_content`
- `landing_path`

### Campos consolidados pelo worker

- `ended_at`
- `duration_ms`
- `exit_path`
- derivados objetivos futuros como `page_view_count`, `event_count`, `engaged_at`

### Mutabilidade permitida

- contexto inicial pode ser enriquecido cedo;
- campos de consolidação podem ser atualizados pelo worker;
- `started_at` e `visitor_id` não devem mudar;
- `landing_path` não deve ser reescrito silenciosamente.

### Regra de idempotência

Reenvios do mesmo heartbeat ou lote não devem criar nova sessão.

A sessão permanece a mesma até a regra canônica de encerramento ser atingida.

### Integridade e cardinalidade

- `session N -> 1 visitor`
- `session 1 -> N page_view`
- `session 1 -> N event`

### Retenção

Retenção longa ou média-longa.

É contexto suficiente para reconstituir jornada e deve sobreviver ao menos enquanto existirem fatos vinculados.

### Volume esperado

Muito menor que `event`, maior que `visitor`.

### Índices mínimos

- PK em `session_id`
- índice por `visitor_id, started_at`
- índice por `started_at`

### Constraints mínimas

- FK para `visitor(visitor_id)`
- `ended_at IS NULL OR ended_at >= started_at`
- limites básicos positivos para duração e dimensões de tela quando preenchidos

### Fluxo de escrita

1. backend identifica visitor;
2. avalia se existe sessão ativa;
3. cria nova sessão quando necessário;
4. worker consolida encerramento posterior.

### Fluxo de leitura

Leitura por:

- jornada de um visitor;
- sessões por origem/campanha;
- contexto de navegação.

### Riscos e decisões pendentes

- sessão fecha canonicamente por `last_activity_at + 30 minutos de inatividade`;
- `landing_path` é a primeira rota rastreável normalizada da sessão;
- `ended_at = last_activity_at` quando a sessão for consolidada;
- tempo ativamente engajado continua sendo derivado futuro, separado de `duration_ms`.

---

## `analytics.page_view`

### Natureza

Fato.

### Responsabilidade exclusiva

Registrar a visualização de uma página rastreável dentro de uma sessão.

### O que não pertence à tabela

- modais;
- cliques;
- ações de formulário;
- score;
- contexto comercial interpretado.

### PK e estratégia de geração

- `page_view_id UUID PRIMARY KEY`

Recomendação adicional:

- incluir `ingestion_key` como chave semântica de idempotência, separada da PK.

### Campos obrigatórios no INSERT

- `page_view_id`
- `session_id`
- `ingestion_key`
- `sequence_no`
- `page_path`
- `viewed_at`

### Campos opcionais

- `page_title`
- `page_type`
- `product_code`
- `dwell_ms`
- `referrer_path`

### Campos consolidados pelo worker

- `dwell_ms`, quando ele depender de fechamento posterior ou cálculo de permanência

### Mutabilidade permitida

- `dwell_ms` pode ser preenchido ou ajustado depois;
- demais campos do fato não devem ser reescritos silenciosamente.

### Regra de idempotência

Reenvio do mesmo evento de visualização não pode duplicar métrica.

A recomendação é `ingestion_key UUID` por ocorrência recebida.

### Integridade e cardinalidade

- `page_view N -> 1 session`
- modal não é `page_view`
- navegação SPA pode gerar `page_view` se houver mudança real de rota lógica

### Retenção

Retenção longa.

É fato analítico primário.

### Volume esperado

Alto, porém ainda bem menor que `event` em muitos cenários.

### Índices mínimos

- PK em `page_view_id`
- índice por `session_id, sequence_no`
- índice por `viewed_at`
- índice por `page_path`

### Constraints mínimas

- FK para `session(session_id)`
- UNIQUE em `ingestion_key`
- UNIQUE em `(session_id, sequence_no)`
- `sequence_no >= 1`
- `dwell_ms IS NULL OR dwell_ms >= 0`

### Fluxo de escrita

1. frontend detecta mudança de página lógica;
2. envia evento de page view com ordem e contexto;
3. backend grava o fato;
4. worker ou fechamento posterior consolida permanência, se necessário.

### Fluxo de leitura

Leitura por:

- funil;
- páginas mais vistas;
- sequência de jornada por sessão;
- tempo por página.

### Riscos e decisões pendentes

- definir formalmente o que conta como nova visualização:
  - carregamento completo;
  - navegação SPA com mudança de rota;
  - hash puro, apenas se houver significado de tela;
  - retorno de aba, em regra não;
  - modal, em regra não.

---

## `analytics.event_type`

### Natureza

Configuração e dimensão semântica.

### Responsabilidade exclusiva

Definir o significado canônico de cada tipo de evento rastreável.

### O que não pertence à tabela

- ocorrências do evento;
- métricas agregadas;
- jornada do usuário;
- score calculado.

### PK e estratégia de geração

- `event_type_id BIGINT PRIMARY KEY`

Decisão recomendada:

- `BIGINT` é suficiente e preferível para uma dimensão técnica pequena;
- o ponto central continua sendo a unicidade semântica de `event_code + event_version`.
- o banco deve gerar a PK via `GENERATED ALWAYS AS IDENTITY`.

### Campos obrigatórios no INSERT

- `event_code`
- `event_version`
- `category`
- `description`
- `is_enabled`
- `valid_from`

### Campos opcionais

- `event_type_id`
- `event_name`
- `scope`
- `payload_schema_json`
- `is_scoreable`
- `valid_until`

### Campos consolidados pelo worker

Nenhum.

### Mutabilidade permitida

- descrição pode evoluir com cuidado;
- `valid_until` pode ser fechado;
- `is_enabled` pode mudar;
- significado de uma versão histórica não deve ser reescrito silenciosamente.

### Regra de idempotência

Cadastro idempotente por unicidade de:

- `(event_code, event_version)`

### Integridade e cardinalidade

- `event_type 1 -> N event`

### Retenção

Retenção permanente ou muito longa.

É catálogo histórico do domínio.

### Volume esperado

Baixíssimo.

### Índices mínimos

- PK em `event_type_id`
- unique em `(event_code, event_version)`
- índice por `category, is_enabled`

### Constraints mínimas

- `event_version >= 1`
- `valid_until IS NULL OR valid_until >= valid_from`
- `event_code` não vazio e com padrão controlado

### Fluxo de escrita

1. time define evento;
2. registra a versão semântica;
3. backend/frontend passam a emitir ocorrências referenciando esse tipo.

### Fluxo de leitura

Leitura por:

- documentação do catálogo;
- governança de eventos ativos;
- interpretação do histórico.

### Riscos e decisões pendentes

- `scope` entra já na V1;
- `payload_schema_json` entra já na V1;
- não é necessária uma engine completa de JSON Schema agora, mas o campo já nasce como contrato leve e documentação formal.

---

## `analytics.event`

### Natureza

Fato.

### Responsabilidade exclusiva

Registrar uma ocorrência concreta de comportamento ou interação dentro da sessão.

### O que não pertence à tabela

- semântica do evento;
- score consolidado;
- classificação comercial;
- métricas agregadas de sessão.

### PK e estratégia de geração

- `event_id UUID PRIMARY KEY`

Recomendação adicional:

- incluir `ingestion_key` como chave semântica de idempotência.

### Campos obrigatórios no INSERT

- `event_id`
- `session_id`
- `ingestion_key`
- `event_type_id`
- `occurred_at`

### Campos opcionais

- `page_view_id`
- `component`
- `product_id`
- `feature_code`
- `value_numeric`
- `metadata_json`

### Campos consolidados pelo worker

Nenhum no fato bruto.

Interpretações e score devem acontecer fora daqui.

### Mutabilidade permitida

Fato praticamente imutável.

Após gravado:

- não deve ter reescrita sem motivo operacional grave;
- no máximo, correção excepcional e auditada.

### Regra de idempotência

Reenvio do mesmo evento não pode duplicar ocorrência.

A recomendação é `ingestion_key UUID` por ocorrência recebida.

### Integridade e cardinalidade

- `event N -> 1 session`
- `event N -> 0..1 page_view`
- `event N -> 1 event_type`

Se `page_view_id` existir:

- ele deve pertencer à mesma `session_id` do evento.

Essa regra deve existir no banco via FK composta, não apenas na aplicação.

### Retenção

Retenção longa.

É o fato mais detalhado do domínio.

### Volume esperado

Mais alto de todo o núcleo.

### Índices mínimos

- PK em `event_id`
- índice por `session_id, occurred_at`
- índice por `event_type_id, occurred_at`
- índice por `page_view_id`
- índices auxiliares futuros em `product_id` e `feature_code` se o uso confirmar necessidade

### Constraints mínimas

- FK para `session(session_id)`
- FK para `event_type(event_type_id)`
- UNIQUE em `ingestion_key`
- `value_numeric` livre, mas validada conforme uso futuro
- `occurred_at` obrigatório

### Fluxo de escrita

1. frontend ou backend detecta interação;
2. emite evento com tipo já conhecido;
3. backend grava o fato;
4. worker ou camadas derivadas interpretam depois.

### Fluxo de leitura

Leitura por:

- intenção por produto;
- etapas de conversão;
- jornada intra-sessão;
- sinais para score e observatório de mercado.

### Riscos e decisões pendentes

- definir política objetiva para o que vai em campo estruturado e o que vai em `metadata_json`.

Regra recomendada:

> dado usado com frequência em filtro, agrupamento, ordenação ou join não deve ficar enterrado no JSON.

Também precisa fechar:
- quais eventos exigem `page_view_id`;
- quais podem ser apenas de sessão;
- e o formato operacional da ingestão em lote.

---

# Rodada 2 — checklist contratual antes do DDL

Antes do DDL, cada tabela do núcleo de captura deve ser fechada pelos mesmos critérios.

## Para `analytics.visitor`

- natureza: entidade de contexto;
- tipo da PK;
- regra de geração do identificador;
- campos obrigatórios no primeiro insert;
- mutabilidade;
- retenção;
- cardinalidade com sessão;
- idempotência de criação.

## Para `analytics.session`

- natureza: entidade de contexto;
- campos obrigatórios no insert inicial;
- campos consolidados pelo worker;
- política de fechamento;
- estratégia de engajamento;
- retenção;
- índices mínimos.

## Para `analytics.page_view`

- natureza: fato;
- PK;
- ordenação por sessão;
- idempotência;
- política de `dwell_ms`;
- cardinalidade com sessão;
- volume esperado;
- índices mínimos.

## Para `analytics.event_type`

- natureza: configuração/dimensão;
- versionamento semântico;
- unicidade de código e versão;
- categorias mínimas;
- mutabilidade permitida;
- política de descontinuação.

## Para `analytics.event`

- natureza: fato;
- vínculo obrigatório com sessão;
- opcionalidade de vínculo com página;
- idempotência;
- fronteira entre campos estruturados e `metadata_json`;
- volume esperado;
- índices mínimos.

## Para `analytics.score_rule`

- natureza: configuração;
- entrada na V1B;
- versionamento;
- relação com `event_type`;
- validade temporal;
- política de recálculo.

---

# Eventos mínimos recomendados para a V1

## Eventos de navegação

- `homepage_open`
- `section_view`

## Eventos de descoberta de produto

- `hero_solutions_click`
- `hero_easy_click`
- `product_modal_open`
- `product_plans_open`
- `product_cta_click`
- `combo_open`

## Eventos de conversão pública

- `contact_form_open`
- `contact_form_submit`
- `whatsapp_click`
- `instagram_click`
- `signup_open`
- `signup_submit_start`

## Regra contratual de lead na superfície pública

Todo ponto público que sair de navegação anônima e entrar em identificação
utilizável para continuidade comercial deve criar ou reaproveitar um
`commercial.lead`, quando aplicável.

Isso vale para a regra de negócio do Hub, não apenas para analytics.

A camada analítica:

- registra o evento bruto;
- preserva o contexto do `visitor`;
- ajuda a explicar a origem e a intenção da conversão.

Mas o nascimento formal do interesse comercial continua acontecendo em
`commercial.lead`.

Regra prática consolidada:

- navegação pública sem identificação fica apenas em `analytics`;
- identificação pública com valor comercial deve materializar lead;
- se o próprio fluxo já nasce como lead, não criar uma segunda abstração paralela.

Exemplo canônico:

- `contact_form_submit` com email informado já é criação formal de lead;
- o evento continua sendo gravado em `analytics.event`;
- porém o registro comercial não deve ficar pendente para uma etapa futura.

O mesmo princípio deve orientar futuras superfícies públicas identificáveis:

- pedido de demo;
- início de signup com dados de contato;
- captura assistida em WhatsApp quando houver estrutura canônica;
- qualquer outro fluxo público que gere contato acionável.

## Eventos de intenção analítica

- `pricing_open`
- `faq_expand`
- `feature_interest`
- `documentation_open`

---

# Worker analítico

## Papel do worker

Existe um componente importante que não deve ficar implícito:

- `Analytics Worker`

Ele é o responsável natural por tirar peso da API síncrona e consolidar tarefas que não precisam acontecer em tempo real.

## Responsabilidades recomendadas

- resolver geolocalização a partir do IP temporário;
- normalizar `user_agent` em device/browser/os;
- consolidar fim de sessão;
- calcular score por regra vigente;
- gerar snapshots e agregados;
- montar datasets para dashboard;
- apagar IP bruto após retenção curta;
- emitir alertas internos quando necessário.

## O que não deve ficar no worker

Os fatos brutos principais devem nascer antes:

- visitor;
- session;
- page_view;
- event.

O worker complementa, consolida e interpreta.
Ele não deve substituir a captura canônica.

---

# Regras de privacidade recomendadas

## O que guardar

- `visitor_id`
- país, estado/região, cidade quando fizer sentido
- timezone
- device/browser/os
- referrer e UTM
- eventos do site

## O que evitar como base canônica

- IP bruto permanente
- fingerprint detalhado
- qualquer tentativa de “descobrir a pessoa” antes da conversão

## O que pode existir temporariamente

- IP bruto em retenção curta apenas para geolocalização e proteção operacional

---

# Integração com o domínio comercial

## Relação com `commercial.lead`

`commercial.lead` continua sendo o lead formal.

O novo domínio proposto não substitui esse registro.

Ele prepara o terreno para:

- enriquecer o lead quando ele nascer;
- explicar sua origem;
- explicar quais desejos antecederam a conversão.

Decisão adicional consolidada:

- quando a superfície pública gerar identificação aplicável, o fluxo deve criar
  ou reaproveitar `commercial.lead`;
- envio de contato com email já conta como nascimento do lead;
- analytics não substitui esse passo, apenas o contextualiza.

## Relação com `commercial.referral_visit`

Essa tabela atual pode continuar existindo como bloco específico de referral/partner.

Na V1, a recomendação é não criar ainda uma tabela autônoma de `acquisition_touch`.

O mais enxuto é começar com aquisição dentro de `session`:

- referrer;
- utm;
- landing;
- source imediata.

Se depois surgir necessidade de múltiplos touches por visitor, multi-touch attribution ou reconciliação comercial mais sofisticada, aí sim uma tabela própria passa a fazer sentido.

---

# Proposta de escopo V1 realista

## Entrar agora

- `analytics.provider_config`
- `analytics.visitor`
- `analytics.session`
- `analytics.page_view`
- `analytics.event_type`
- `analytics.event`

## Pode esperar um segundo passo

- `analytics.score_rule`
- `analytics.identity_link`
- `lead_signal` como view, worker ou tabela futura
- `score_snapshot` como view materializada ou tabela futura
- dashboards analíticos completos

## Fica explicitamente para o futuro

- product telemetry operacional dentro das apps
- leitura profunda de jornada autenticada
- scoring mais sofisticado com modelos adaptativos

---

# Conclusão final

O documento original está certo no que importa:

- visão;
- direção;
- separação de camadas;
- filosofia de dados.

O que faltava era maturidade estrutural.

Para a AXYS começar bem, a melhor decisão não é simplificar demais nem tentar construir uma plataforma gigante.

A melhor decisão é nascer com:

- fatos brutos claros;
- vínculos claros;
- semântica de domínio clara;
- capacidade de crescer sem retrabalho conceitual.

Em resumo:

> a proposta é boa o suficiente para seguir;
> a modelagem original não é boa o suficiente para virar contrato final sem este refino;
> e a V1 fica melhor quando nasce com menos interpretação e mais fatos brutos.
