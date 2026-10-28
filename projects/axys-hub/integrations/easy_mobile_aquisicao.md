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

Robôs, pré-visualizações e visitantes repetidos ficam separados. A estimativa de únicos usa um identificador aleatório first-party; não usa IP, características do aparelho nem fingerprinting. O funcionamento respeita o modo integral/restrito do consentimento público existente.

O painel interno fica em `/app/acquisition/easy-mobile`. O escopo do Hub termina na saída para a loja: ele não mede instalação, primeira abertura ou ação dentro do aplicativo. Esses resultados só podem ser consultados nos relatórios nativos do Google Ads, Google Play e App Store, quando já estiverem disponíveis, sem exigir alteração do EasyMobile.

## Google Ads

- Campanhas web (Pesquisa, Display, Demand Gen e anúncios que aceitam URL final) podem usar `/go/<codigo>` quando a política do formato permitir URL web.
- Campanhas nativas de aplicativo devem ser configuradas separadamente por plataforma com o app oficial cadastrado na loja e a atribuição nativa do Google/Apple. Não se deve forçar a passagem pelo Hub nem usar redirect para contornar o formato.
- UTMs e click IDs são preservados no Hub, mas só parâmetros oficialmente suportados são encaminhados à loja. Na Play Store o token segue no `referrer`; na App Store o Hub não promete associação individual.

## Operação

Aplicar `schemas/migrations/019-easy-mobile-acquisition.sql` antes de ativar links. A migration apenas cria tabelas e índices; não publica campanha, não compra mídia e não gera gasto.

