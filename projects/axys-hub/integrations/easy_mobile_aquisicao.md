# Aquisição e mensuração do EasyMobile

O Hub fornece links configuráveis `https://www.axys-tec.com.br/go/<codigo>` e mede um funil sem chamar clique de instalação.

## Cadastro de links

O cadastro é feito por um administrador interno em `POST /app/acquisition/easy-mobile/links`:

```json
{
  "code": "ig-outubro-video-a",
  "sourcePlatform": "instagram",
  "campaignCode": "easy-mobile-outubro",
  "creativeCode": "video-a",
  "objective": "awareness",
  "destination": "landing",
  "isActive": true
}
```

Objetivos e destinos válidos:

- `awareness` exige `landing` e direciona para `/easy-mobile`;
- `direct_acquisition` com `auto_store` direciona Android à Google Play, iPhone/iPad à App Store e desktop/ambíguo à landing;
- `google_play` e `app_store` forçam uma loja oficial quando a campanha realmente exigir isso.

Não existe parâmetro de URL capaz de transformar o endpoint em open redirect. Os destinos oficiais ficam centralizados em `backend/modules/easy_mobile_acquisition/constants.py`.

Exemplos:

```text
Google Ads (campanha web): /go/google-search-bdi?utm_source=google&utm_medium=cpc&utm_campaign=bdi&gclid={gclid}
Instagram: /go/ig-outubro-video-a?utm_source=instagram&utm_medium=paid_social&utm_campaign=easy-mobile-outubro&utm_content=video-a
LinkedIn: /go/li-engenharia-publica?utm_source=linkedin&utm_medium=paid_social&utm_campaign=engenharia-publica
```

## Eventos

| Evento | Emissor | O que significa |
|---|---|---|
| `campaign_passage` | Hub | requisição ao link `/go/<codigo>` |
| `landing_view` | navegador após o bootstrap | visualização efetiva da landing |
| `store_click` | navegador | escolha explícita de uma loja |
| `store_redirect` | Hub | redirect temporário para a loja |
| `first_app_open` | aplicativo | primeira abertura informada pelo app |
| `first_relevant_action` | aplicativo | primeira ação útil informada pelo app |

Robôs, pré-visualizações e visitantes repetidos ficam separados. A estimativa de únicos usa um identificador aleatório first-party; não usa IP, características do aparelho nem fingerprinting. O funcionamento respeita o modo integral/restrito do consentimento público existente.

O painel interno fica em `/app/acquisition/easy-mobile`. Não mostra custo quando não há investimento real importado e não calcula conversão de etapas que não tenham dados comparáveis.

## Contrato pendente no aplicativo

Esta entrega não altera o repositório do EasyMobile. Para concluir atribuição de uso, o aplicativo deve enviar eventos idempotentes a:

```http
POST /api/easy-mobile/acquisition/event
X-Easy-Mobile-Client-Id: <cliente SSO easy-mobile>
X-Easy-Mobile-Client-Secret: <segredo>
Content-Type: application/json
```

```json
{
  "ingestionKey": "uuid-estavel-gerado-pelo-app",
  "eventType": "first_app_open",
  "clientUuid": "uuid-do-cliente-quando-identificado",
  "platform": "android",
  "code": "ig-outubro-video-a",
  "touchId": "uuid-recebido-no-referrer",
  "attributionStatus": "confirmed",
  "attribution": {"utm_source": "instagram"},
  "metadata": {"install_referrer_version": 1}
}
```

Regras externas:

1. Android deve ler `acq` e `acq_code` pelo **Google Play Install Referrer** e somente então declarar atribuição individual `confirmed`.
2. iOS não deve inventar vínculo individual. Dados SKAdNetwork/AdServices ou da plataforma devem ser enviados como `aggregated` ou `modelled`; ausência de evidência é `unknown`.
3. `ingestionKey` precisa permanecer igual em retries. A chave única do banco torna a ingestão idempotente.
4. `first_relevant_action` deve ser emitido uma única vez por cliente/instalação após a primeira ação acordada pelo produto.

## Google Ads

- Campanhas web (Pesquisa, Display, Demand Gen e anúncios que aceitam URL final) podem usar `/go/<codigo>` quando a política do formato permitir URL web.
- Campanhas nativas de aplicativo devem ser configuradas separadamente por plataforma com o app oficial cadastrado na loja e a atribuição nativa do Google/Apple. Não se deve forçar a passagem pelo Hub nem usar redirect para contornar o formato.
- UTMs e click IDs são preservados no Hub, mas só parâmetros oficialmente suportados são encaminhados à loja. Na Play Store o token segue no `referrer`; na App Store o Hub não promete associação individual.

## Operação

Aplicar `schemas/migrations/019-easy-mobile-acquisition.sql` antes de ativar links. A migration apenas cria tabelas e índices; não publica campanha, não compra mídia e não gera gasto.

