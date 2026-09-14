# Easy Mobile — publicação pública e App Store

**Estado em 13/09/2026:** implementação concluída no código; publicação em
produção depende do deploy do Hub e da aplicação prévia da migration 009.

## Entregas públicas

| Rota | Finalidade | Sitemap |
|---|---|---:|
| `/easy-mobile` | Landing e apresentação das funcionalidades | sim |
| `/easy-mobile/privacidade` | Política de privacidade do aplicativo | sim |
| `/easy-mobile/termos` | Termos aceitos no cadastro | sim |
| `/easy-mobile/suporte` | Support URL da App Store | sim |
| `/politicas/privacidade` | Política institucional | sim |
| `/politicas/confidencialidade` | Confidencialidade institucional | sim |
| `/politicas/compliance` | Compliance institucional | sim |
| `/termos-de-uso` | Termos gerais do ecossistema | sim |
| `/suporte` | Suporte institucional usado no rodapé | sim |

`/privacidade-e-cookies` redireciona permanentemente para
`/politicas/privacidade`. O endpoint POST `/contato` não deve ser usado como
Support URL, pois não é uma página navegável.

## Decisões de interface

- Documentos institucionais e específicos usam layout editorial simples, sem o
  hero promocional da home.
- A landing `/easy-mobile` possui estilos isolados para evitar herdar tamanhos,
  cores e comportamento temático inadequados da home.
- As telas da Central de Custos e os relatórios técnicos são exibidos sem
  distorção; `caderno-tecnico.jpeg` e `analise-tecnica.jpeg` aparecem lado a
  lado na seção correspondente.
- A grade de vídeos existente é a demonstração oficial da landing; não existe
  reserva para um vídeo futuro de apresentação.
- O rodapé usa `/suporte` como suporte geral. A landing oferece links próprios
  para privacidade, termos e suporte do Easy Mobile.
- Easy Mobile ocupa a primeira posição no carrossel AxysEasy. `Conheça mais`
  abre um resumo do app e oferece somente `Ver Funcionalidades` →
  `/easy-mobile`.

## Mídias no bucket público

Bucket: `axys-public`  
Base pública: `https://public.axys-tec.com.br`  
Prefixo: `easy-mobile/media/`

```text
easy-mobile/media/
├── site/
├── app-store/
│   ├── screenshots/
│   └── previews/
└── archive/
    ├── original-screenshots/
    └── original-videos/
```

Os objetos públicos usam cache longo (`public, max-age=31536000, immutable`).
Caso um ativo publicado seja substituído mantendo a mesma chave, considerar a
invalidação do cache ou preferir uma chave versionada.

## Pacote de envio à Apple

O pacote de trabalho local fica em:

```text
Axys/EasyMobile/AppStore/
├── 01-originais/
├── 02-screenshots-1284x2778/
├── 03-videos-originais/
└── 04-previews-886x1920/
    └── rejeitados-frame-rate-alto/
```

### Screenshots

- formato final: PNG;
- dimensão: 1284 × 2778 px;
- interface ampliada proporcionalmente;
- sem corte ou deformação;
- sobra lateral preenchida com o fundo escuro do aplicativo;
- originais preservados separadamente.

### App previews

- dimensão: 886 × 1920 px;
- codec: H.264, High Profile Level 4.0;
- pixel format: `yuv420p`;
- frame rate: 30 fps constante;
- áudio: AAC estéreo, 44,1 kHz;
- duração permitida: de 15 a 30 segundos;
- vídeos atuais: aproximadamente 22,73 s, 20,03 s e 29,90 s.

Os primeiros previews preparados estavam a aproximadamente 60 fps — um deles
declarava base de 120 fps — e foram rejeitados pelo App Store Connect. Essas
cópias permanecem apenas para histórico na subpasta
`rejeitados-frame-rate-alto`; para envio, usar os três arquivos diretamente na
raiz de `04-previews-886x1920`.

## Exclusão de conta

Rotas equivalentes:

- `POST /api/easy-mobile/me/excluir`;
- `POST /auth/excluir` (alias de compatibilidade).

Payload:

```json
{
  "senha": "...",
  "motivo": "Não uso com frequência",
  "motivo_detalhe": "texto livre, até 280 caracteres",
  "aceita_contato": false
}
```

O endpoint verifica token e senha, realiza exclusão lógica, preserva
`client_uuid`, `deleted_at` e `status=deleted`, e anula os dados pessoais,
credenciais, verificações e preferências. O feedback fica em tabela anônima,
sem FK para a identidade. Nome e telefone só podem permanecer com opt-in
explícito, por prazo máximo configurável de 30 dias, seguido de expurgo.

O alerta Z-API ao número configurado nunca contém PII sem opt-in. Falha no
alerta é registrada, mas não desfaz a exclusão concluída.

## Ordem obrigatória para produção

1. Fazer backup do banco de produção.
2. Aplicar `schemas/migrations/009-easy-mobile-account-deletion.sql`.
3. Configurar `EASY_MOBILE_DELETION_ALERT_PHONE` e, se necessário,
   `EASY_MOBILE_DELETION_CONTACT_RETENTION_DAYS`.
4. Publicar o commit do Hub no Render.
5. Testar as quatro rotas públicas com HTTP 200.
6. Testar exclusão com `aceita_contato=false` e confirmar anonimização.
7. Testar exclusão com `aceita_contato=true` e confirmar retenção limitada.
8. Confirmar `/sitemap.xml`, o aquecimento noturno e o expurgo idempotente.
9. Reenviar à Apple os previews a 30 fps da pasta final.

Não publicar o código da exclusão antes da migration 009: sem as novas colunas
e a tabela de feedback, o endpoint falha em produção.

## Verificações já concluídas

- arquivo de verificação do Google, `robots.txt` e `sitemap.xml` responderam
  HTTP 200;
- propriedade de domínio validada no Google Search Console por DNS;
- sitemap processado pelo Search Console, com 180 páginas encontradas na
  conferência realizada;
- home, terminologia BDI e dúvida sobre cálculo do preço de venda com BDI foram
  submetidas à inspeção de URL;
- testes focados das páginas públicas e do carrossel passaram localmente.

## Pendências separadas desta entrega

Cauda longa comercial, contrato editorial SEO dos manifests, árvore
`/solucoes`, linkagem contextual ampliada e relatórios de aquisição/conversão
continuam no backlog `seo_publico_backlog.md`. A produção dos manifests e dos
materiais pertence ao projeto publicador, não ao Hub.
