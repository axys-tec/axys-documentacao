# ImportarXML Arquivado no Hub

Em 22 de julho de 2026, a funcionalidade `importarxml` foi removida do AxysHub e retirada do escopo deste projeto.

## Decisao

- O Hub nao evolui mais a captura, processamento ou exportacao de XML.
- Qualquer continuidade funcional desse fluxo deve ocorrer fora deste repositorio.
- O destino previsto e um legado controlado no Gestor antigo (`axysdash`), tratado como contexto separado.

## O que saiu do Hub

- Rota publica `/importarxml`
- Upload e exportacao associados ao fluxo
- Polling visual no cabecalho privado relacionado a processamento de importacao
- Artefatos de template, CSS e parser local ligados a essa funcionalidade

## Regra daqui para frente

- Nao reintroduzir `importarxml` no Hub.
- Nao acoplar novas regras de XML ao backend ou ao frontend deste projeto.
- Se houver necessidade operacional futura, abrir implementacao propria no projeto do Gestor.

## Observacao

Este arquivamento nao altera o restante da superficie publica do site nem o dominio de analytics; apenas remove do Hub uma funcionalidade que deixou de pertencer a este produto.
