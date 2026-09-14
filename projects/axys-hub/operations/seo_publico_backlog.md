# SEO público — estado atual, fronteiras e pendências

## Estado implementado no Axys Hub

O Hub consome os manifests e materiais públicos do bucket e oferece:

- rotas individuais dinâmicas para artigos, dúvidas, casos, terminologia e downloads;
- HTML renderizado no servidor;
- `sitemap.xml` derivado do conteúdo publicado;
- `robots.txt`, canonical, metadados e dados estruturados;
- analytics de abertura de conteúdo e download de materiais.

As rotas são genéricas (`/knowledge/{tipo}/{id}`). Não são criados arquivos HTML nem
rotas Python novas para cada publicação.

## Comportamento real do cache

O cache atual é sob demanda, com validade de cinco minutos. Não existe worker,
agendador ou varredura periódica atualizando o site inteiro.

1. Uma requisição carrega o conteúdo e inicia a validade do cache.
2. Durante cinco minutos, outras requisições reutilizam essa cópia.
3. Depois desse prazo, a cópia **não é apagada**: ela apenas fica marcada como antiga.
4. A primeira nova requisição tenta buscar o conteúdo atualizado.
5. Se a origem estiver indisponível, o Hub preserva a última cópia válida em memória.

A expiração do cache não remove a rota e não faz uma página publicada deixar de existir.
A rota genérica continua registrada no FastAPI e o material continua no bucket. Se o
processo reiniciar, o cache em memória começa vazio e a primeira requisição reconstrói a
página consultando a origem. O risco real ocorre somente se o processo reiniciar e o
bucket estiver indisponível nesse primeiro acesso; nesse cenário a página responde 503
temporariamente.

Se ninguém acessar a central, a página individual ou o sitemap, nenhuma consulta nova é
executada e uma publicação recém-adicionada ainda não é incorporada à cópia em memória.
Uma visita do Google ao sitemap também é uma requisição e pode provocar a atualização.

Para não depender de visita humana, o worker noturno do projeto Easy faz uma requisição
ao `/sitemap.xml` do Hub depois de concluir a atualização dos índices inflacionários. Essa
requisição revalida os manifests, atualiza a relação de URLs publicada ao Google e também
aciona o expurgo idempotente dos contatos temporariamente retidos após exclusão de conta.
Não foi criada API, webhook nem fila específica no Hub.

O aquecimento diário reduz o atraso de descoberta, mas não transforma o Hub em gerador
estático: as páginas individuais continuam sendo montadas quando solicitadas. Uma URL não
deixa de existir quando o cache expira; a rota genérica e o material no bucket permanecem
disponíveis.

## Fronteira de responsabilidade

Este projeto, `axys-hub`, é consumidor somente-leitura do conteúdo público. Outro
projeto é responsável por:

- produzir e revisar os materiais;
- escrever os JSONs, Markdown e PDFs;
- atualizar e publicar os manifests no bucket;
- garantir IDs/URLs estáveis e integridade das referências.

O Hub não deve escrever no bucket nem alterar manifests. Mudanças de contrato entre os
projetos devem ser versionadas e manter compatibilidade com os campos atuais.

## Pendências deliberadamente adiadas

Estas frentes estão registradas, mas não devem ser publicadas como oferta comercial
antes de existir solução pronta para venda e posicionamento aprovado:

1. Definir, no projeto produtor, um contrato editorial SEO opcional para os manifests:
   `title`, `description`, assunto principal, termos relacionados, data de atualização,
   autor/revisor, política `index/noindex` e relações internas.
2. Fazer o Hub consumir esses campos opcionais com fallback para os dados atuais.
3. Planejar a árvore comercial `/solucoes`, agrupando variações por intenção real de
   busca, sem criar uma página artificial para cada palavra-chave.
4. Publicar páginas comerciais somente quando produto, proposta de valor, demonstração,
   atendimento e conversão estiverem prontos.
5. Expandir a linkagem contextual entre Knowledge, futuras Soluções e produtos Easy.
6. Criar relatórios de aquisição orgânica: origem/UTM, landing page, conteúdo visitado,
   download, lead, cadastro, teste e conversão.
7. Monitorar o aquecimento noturno já implantado e decidir futuramente se publicações
   urgentes justificam invalidação explícita. Por ora, não criar webhook ou API adicional.

### Árvore comercial candidata — não publicada

- `/solucoes/orcamento-de-obras`
- `/solucoes/orcamento-de-obras-publicas`
- `/solucoes/orcamento-sinapi`
- `/solucoes/composicao-de-custos`
- `/solucoes/engenharia-de-custos`
- `/solucoes/diario-de-obras`
- `/solucoes/gestao-de-obras`
- `/solucoes/planejamento-de-obras`
- `/solucoes/fiscalizacao-de-obras`
- `/solucoes/elaboracao-de-etp-e-termo-de-referencia`

Antes de implementar essa árvore, validar para cada página: solução existente, público,
intenção de busca, diferenciais comprováveis, produto de destino, CTA e evento de
conversão.
