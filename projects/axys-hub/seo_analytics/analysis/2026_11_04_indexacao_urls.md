# Auditoria de URLs e indexação — 04/11/2026

## Escopo e fontes

- propriedade informada: `axys-tec.com.br`;
- relatório do Google Search Console consultado em 04/11/2026, atualizado em 22/10/2026;
- fotografia histórica informada: 5 soft 404, 4 URLs 404, 4 duplicadas sem canonical selecionada, 4 redirecionamentos, 3 alternativas com canonical adequada, 7 rastreadas não indexadas e 33 descobertas não indexadas;
- sitemap e páginas de produção rastreados diretamente em 04/11/2026;
- código e testes do Axys Hub inspecionados localmente.

A exportação das URLs de cada motivo do Search Console não está disponível no repositório e o navegador autenticado não ficou acessível nesta execução. Portanto, as contagens históricas não foram convertidas artificialmente em URLs. A revalidação de cada item histórico depende da exportação das listas do GSC.

## Resultado do rastreamento atual

- 451 URLs no sitemap publicado;
- 450 responderam `200`;
- uma respondeu `308` e não deveria estar no sitemap;
- todas as 450 respostas HTML `200` apresentaram canonical própria e coerente;
- nenhuma duplicata exata ou duplicata apenas por barra final foi encontrada no sitemap;
- o crawl dos links internos encontrou dois links para produtos inexistentes, um conjunto de links para a URL movida e links de login pelo host não preferido;
- cinco páginas completas de downloads estavam no sitemap, mas não recebiam link HTML rastreável da central, pois a lista era montada apenas por JavaScript.

## URLs com causa local confirmada

| URL | Estado em produção antes da correção | Sitemap | Links internos | Causa | Correção local | Evidência esperada após publicação |
|---|---|---:|---:|---|---|---|
| `https://www.axys-tec.com.br/knowledge/artigos/onerado-ou-desonerado-a-conta-ano-a-ano` | `308` para `/knowledge/casos/comparacao-orcamento-onerado-desonerado`, sem corpo ou canonical | sim | 6 | URL movida ainda era emitida pelo sitemap e pela recomendação editorial | centralizado o caminho preferido; sitemap deduplica e publica somente o destino; listagens, temas e relacionados passam a usar o destino | origem continua com um único `308`; não aparece no sitemap nem em links internos; destino responde `200` com canonical própria |
| `https://www.axys-tec.com.br/knowledge/casos/comparacao-orcamento-onerado-desonerado` | `200`, 59.124 bytes, H1 e 4.820 palavras, canonical própria | sim | destino da URL antiga | destino correto e completo | preservado como URL pública estável | uma ocorrência no sitemap e links internos apontando diretamente para ela |
| `https://www.axys-tec.com.br/easy-projectmanager` | `404`, JSON `Produto não encontrado.`, sem canonical | não | 1 | slug incorreto no hub temático | link corrigido para `/easy-proj-manager` | URL incorreta deixa de receber links; destino responde `200` com canonical própria |
| `https://www.axys-tec.com.br/easy-builddiary` | `404`, JSON `Produto não encontrado.`, sem canonical | não | 1 | slug incorreto no hub temático | link corrigido para `/easy-build-diary` | URL incorreta deixa de receber links; destino responde `200` com canonical própria |
| `https://axys-tec.com.br/login` | `301` para `https://www.axys-tec.com.br/login` | não | presente no header de 450 páginas | navegação interna usava host não preferido | header público passa a ligar diretamente ao host `www` | nenhum link interno para o host alternativo; redirecionamento de borda permanece correto para acessos externos |

## Páginas completas que estavam sem descoberta HTML

Todas já respondiam `200`, tinham H1, conteúdo substancial e canonical própria. A correção não altera os manifests nem os materiais do bucket: a central do Hub agora renderiza no servidor os links que antes só apareciam após JavaScript.

| URL | Conteúdo retornado | Sitemap | Links HTML antes | Correção local |
|---|---|---:|---:|---|
| `/knowledge/downloads/tcu-engenharia-custos-perguntas-respostas` | 1.499 palavras | sim | 0 | link server-side na Central de Downloads |
| `/knowledge/downloads/ibraop-ot-009-reequilibrio` | 953 palavras | sim | 0 | link server-side na Central de Downloads |
| `/knowledge/downloads/ibraop-irb-008-alteracoes-contratuais` | 971 palavras | sim | 0 | link server-side na Central de Downloads |
| `/knowledge/downloads/tcu-orientacoes-planilhas-orcamentarias` | 1.361 palavras | sim | 0 | link server-side na Central de Downloads |
| `/knowledge/downloads/ibraop-ot-005-sobrepreco-superfaturamento` | 978 palavras | sim | 0 | link server-side na Central de Downloads |

## Itens que não foram tratados como erro

- redirecionamentos de HTTP para HTTPS e do domínio sem `www` para `www` são permanentes, diretos e adequados;
- `/knowledge` redireciona para `/knowledge/`, que é a URL canônica publicada;
- as três páginas alternativas com canonical adequada não devem ser alteradas apenas por aparecerem nessa categoria;
- descoberta ou rastreamento sem indexação não implica falha técnica. O rastreamento atual confirma disponibilidade e canonical, mas não garante seleção pelo Google;
- `/easy-orca/inscricao` não foi alterada: é uma página de campanha e o pedido desta auditoria proíbe mudanças em campanha, Pixel ou formulário.

## Validação local

- testes de regressão verificam os slugs de produtos, host preferido do login, URL preferida do conteúdo movido, deduplicação do sitemap e links HTML dos downloads;
- `scripts.tests.test_public_seo` e `scripts.tests.test_product_landings`: 21 testes aprovados;
- compilação dos módulos Python alterados concluída sem erro.

## Estado e próximos passos

1. **Correção local:** concluída no worktree; ainda não publicada por esta execução.
2. **Produção:** após deploy, repetir o crawl integral e confirmar que o sitemap contém somente respostas `200`, que não existem links internos `404/3xx` evitáveis e que os downloads recebem links HTML.
3. **Google:** exportar do Search Console as URLs exatas de cada um dos sete motivos históricos, confrontá-las com esta auditoria e solicitar validação apenas para os grupos efetivamente corrigidos. A atualização do relatório depende de novo rastreamento do Google.
4. **Pendência externa:** se uma URL problemática pertencer a conteúdo ausente ou inconsistente no projeto produtor, registrar o ajuste no produtor; o Hub permanece somente leitura e nenhum manifest ou material do bucket foi alterado aqui.
