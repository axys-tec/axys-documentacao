# Campanhas Instagram — marco de comparação

## Easy Orça

Fotografia informada em **03/11/2026, às 03:17 (America/Sao_Paulo)**, a partir dos insights do Instagram/Meta:

- destino público: `https://www.axys-tec.com.br/easy-orca/inscricao`;
- `website visits`: **147**;
- `link clicks`: **170**;
- diferença entre cliques e visitas declaradas: **23**;
- relação declarada `website visits / link clicks`: **86,47%**.

Este marco serve para comparação posterior com `analytics.public_endpoint_hit`, inscrições persistidas e eventos comportamentais consentidos. Os números do Meta são métricas da própria plataforma e não devem ser tratados como equivalentes automáticos a requisições humanas recebidas pelo Hub.

### Contexto técnico do marco

O contador server-side independente de consentimento foi criado na migration `022-public-endpoint-hit.sql`. Esta fotografia foi registrada antes da confirmação do deploy do código correspondente no serviço público. Portanto, os acessos anteriores não são retroativamente recuperáveis na nova tabela e devem permanecer como baseline externo informado pelo Meta.

### Encerramento da campanha otimizada para cliques

Fotografia informada em **03/11/2026, às 21:24 (America/Sao_Paulo)**, após a interrupção do anúncio configurado para cliques:

- `website visits` acumuladas no Meta: **471**;
- `link clicks` acumulados no Meta: **518**;
- diferença acumulada entre cliques e visitas declaradas: **47**;
- relação acumulada `website visits / link clicks`: **90,93%**;
- variação desde a fotografia das 03:17: **+324 website visits** e **+348 link clicks**.

No intervalo mensurável pelo Hub, de **03:17:32 a 21:24:59**, `analytics.public_endpoint_hit` registrou:

- **409** requisições brutas para `/easy-orca/inscricao`;
- **383** acessos válidos após excluir bots e previews;
- **26** requisições classificadas como bot ou preview;
- último acesso registrado às **19:32:35**;
- **0** inscrições em `commercial.campaign_registration`;
- conversão observada de acesso válido em inscrição: **0%**.

Distribuição dos **383 acessos válidos**:

- `m.facebook.com` / Android: **199**;
- `instagram.com` / iOS: **138**;
- `instagram.com` / Android: **35**;
- acessos diretos sem origem identificada: **9**;
- `eventsmanager.facebook.com` / desktop: **1**;
- `l.facebook.com` / Android: **1**.

O anúncio otimizado para cliques foi interrompido. Em seguida, foi configurada no repositório/Meta uma nova campanha orientada a **lead/conversão**, com a conversão também medida pela Meta. Este registro não presume que a nova campanha já tenha iniciado a veiculação; o começo efetivo deverá receber um novo marco com horário e contadores zerados ou fotografados naquele momento.

## Easy Mobile

Às **03:17 de 03/11/2026**, o anúncio patrocinado do Easy Mobile **ainda não havia iniciado/entrado em veiculação**. A baseline inicial da campanha é, portanto, anterior à entrega do anúncio; registrar nova fotografia quando a plataforma indicar o começo da veiculação.
