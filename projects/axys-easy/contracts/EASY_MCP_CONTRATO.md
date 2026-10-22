# Easy MCP — contrato

**Versão:** V1 (2026-10-20) · **Status:** implementado e validado em DEV (ChatGPT pelo túnel);
produção pendente (§12). O contrato governa; o código implementa e referencia este arquivo no topo.
**Origem:** proposta `axys_easy_mcp_proposta_inicial.md` (Renan, 2026-10-20), conferida contra o
repositório.

**Companheiros:**
- [`EASY_MCP_FERRAMENTAS.md`](EASY_MCP_FERRAMENTAS.md): apêndice com **todas as ferramentas**
  (o que fazem, parâmetros, campos). É GERADO; não se edita à mão (§4.1).
- [`backend/api/mcp/conteudo/instrucoes_ia.md`](../../../../backend/api/mcp/conteudo/instrucoes_ia.md): **fonte única de tudo o que a
  IA lê** (instruções, guia, títulos, descrições, campos, avisos). É ali que se cura o texto.
- [`EASY_HUB_MCP.md`](EASY_HUB_MCP.md): o que o Hub entrega (P1–P4).
- [`HERANCA_ORCAMENTO_EMPREENDIMENTO.md`](HERANCA_ORCAMENTO_EMPREENDIMENTO.md): pauta única
  (fontes/BDI/L.S.) no empreendimento.
- [`EASY_PERFIS_PERMISSOES.md`](EASY_PERFIS_PERMISSOES.md) (claims) ·
  [`ativo/bancada_orcamento_contrato.md`](ativo/bancada_orcamento_contrato.md) (regras da árvore).

---

## 1. O que é, e o que não é

O MCP do Easy é **mais uma interface** para os serviços que a app web já usa. A IA do usuário
(ChatGPT, Claude, outro cliente MCP) interpreta o pedido e escolhe as ferramentas; o Easy executa
operações validadas, com a mesma identidade, o mesmo tenant, a mesma licença e as mesmas regras
da tela.

**Por que existe.** Toda operação repetitiva da bancada pedia uma tela nova, e cada tela nova é
mais suporte. O caso que abriu a frente: no ativo 34 (PIZZA HUT, R00), 110 grupos de nível 3 das
disciplinas 2.2–2.7 precisavam do mesmo serviço que os grupos de 2.1 já tinham. Na tela, isso é um
copiar/colar por grupo; no MCP, é um pedido. **Doutrina (Renan):** as ferramentas nascem **sob
demanda**, como deveriam ter nascido as telas.

**Não é:** um agente de IA nosso (não hospedamos nem cobramos inferência), um acesso ao banco, um
SQL livre, um proxy HTTP genérico, nem uma segunda plataforma de identidade.

**Princípio:** um usuário, um tenant autorizado, uma regra de negócio, várias interfaces.

**Princípio de produto (Renan): o MCP é ferramenta de PRODUTIVIDADE, não de substituição.** Ele
executa o que o usuário decidiu, mais rápido. Não substitui o usuário, a curadoria manual nem a
análise. Na prática:
- toda escolha técnica é do usuário: composição, análogo, fonte, preço, cura de conciliação;
- a IA propõe candidatos e mostra evidências;
- nada muda sem prévia e confirmação;
- o que é curadoria ou ato formal na tela não entra no MCP.

**Escopo fechado (Renan, 2026-10-20).**

| Entra (preenchimento) | Fica só na tela |
|---|---|
| bancada: itens, estrutura (EAP), composição, cotação, recálculo | gerar entregáveis (PDF/Excel): pelo MCP, só consultar pendências |
| memória de cálculo (o grid da tela) | anexos (memória, propostas de cotação) |
| descritivo da composição no orçamento | excluir ativo (senha + cascata) |
| cronograma (nível + %) | equivalência entre fontes, concluir revisão, medições |
| BDI, L.S., fontes-base, pauta única do empreendimento | pré-planejamento: **suspenso** (Renan, 2026-10-20) |
| empreendimento e ativo (cadastro) | |
| dados próprios: cadastro, descritivo, preços | |

## 2. Topologia

```text
ChatGPT / Claude / cliente MCP          navegador do usuário
        │ (servidor da OpenAI etc.)            │
        │ HTTPS + Bearer                       │ login
        ▼                                      ▼
  ┌──────────────── Easy Web (FastAPI, mesmo processo, mesmo Render) ───────────────┐
  │  /.well-known/oauth-protected-resource/mcp  /.well-known/oauth-authorization-server │
  │  /register  /authorize  /token  /revoke  (raiz do host: o SDK fixa esses caminhos)│
  │  /mcp/oauth/hub-callback  (nosso: volta do login no Hub)                         │
  │  /mcp  ← Streamable HTTP (SDK `mcp` 2.3.0, MCPServer)                            │
  │        └─ AuthContext (JWT do Hub, aud=easy-mcp) → ferramentas → serviços Python │
  └──────────────────────────────────────────────────────────────────────────────────┘
        │ exchange do code (server→server)          │
        ▼                                           ▼
     Axys Hub (identidade, licença, sessão)    PostgreSQL / OpenSearch / R2 / Redis
```

- **Um único servidor MCP para o Easy**, montado na app FastAPI principal. Sem serviço Render novo.
  SDK oficial `mcp==2.3.0` (`mcp.server.mcpserver.MCPServer`, `stateless_http=True`).
- A app web **não depende** do MCP: falha no `/mcp` não derruba rota REST nem tela.
- Código separado em `backend/api/mcp/` (espelha `backend/api/mobile/`), para poder virar serviço
  próprio no futuro sem reescrever regra de negócio.

```text
backend/api/mcp/
  server.py        EasyMCPServer (tools/list por usuário), montagem, despachante ASGI
  oauth.py         provider OAuth: DCR autocontido, authorize→Hub, hub-callback, code, refresh
  auth.py          TokenVerifier (aud easy-mcp) → AuthContext
  contexto.py      AuthContext, módulos MCP, exige_escrita
  estado.py        Redis fail-closed (pedido, code, plano, transcrição)
  planos.py        plano: criar, carregar, travar, concluir (idempotente), auditar
  refs.py          referências opacas (§5.7)
  limites.py       cotas (reusa o limitador do mobile)
  erros.py         {erro, mensagem}: tradução única de exceção → erro previsível
  instrucoes.py    leitor das instruções para a IA + gerador do apêndice
  conteudo/
    instrucoes_ia.md   TODO o texto que a IA lê (fonte única, curada à mão)
    produtos_site.md   o que o site diz de cada produto (referência do conhecimento do ecossistema)
  tools/           uma por domínio: guia, acesso, ativos, cadastro, orcamento, transcricao,
                   composicao, config_orcamento, catalogo, proprios, proprios_cadastro,
                   memoria, descritivo
```

## 3. Identidade e autenticação

### 3.1 Quem é a autoridade

**O Hub.** O Easy não cria usuário, não cria role, não guarda senha e não emite identidade
própria para o MCP. O Easy apenas **coordena** o OAuth que os clientes MCP exigem e repassa a
eles o JWT que o Hub assinou.

O Hub registra um **app de SSO, `easy-mcp`** (ao lado de `easy`, `easy-mobile`, `gestor`), com
client próprio, `aud=easy-mcp` e as mesmas claims do `easy` (ver
[`EASY_HUB_MCP.md`](EASY_HUB_MCP.md) §P1). "Um MCP por produto" = um app de SSO por produto.

### 3.2 Fluxo de conexão (OAuth 2.1 + PKCE, com o Hub como provedor de identidade)

1. O usuário cadastra a URL `https://<host>/mcp` no cliente MCP.
2. O cliente chama `/mcp` sem token e recebe `401` + `WWW-Authenticate` apontando o
   `/.well-known/oauth-protected-resource/mcp` (RFC 9728).
3. O cliente lê os metadados do servidor de autorização (RFC 8414,
   `/.well-known/oauth-authorization-server`) e se registra em `/register` (Dynamic Client
   Registration, RFC 7591).
4. O cliente abre no navegador `/authorize` (com `code_challenge` S256 e `state`).
5. O Easy guarda o pedido no Redis (TTL 5 min) e redireciona o navegador para
   `HUB/login?app=easy-mcp&redirect_uri=<host>/mcp/oauth/hub-callback&state=<state Easy>`.
6. O usuário faz login **no Hub** (ou passa direto, se já tem sessão no Hub). O cliente MCP nunca
   vê a senha.
7. O Hub devolve um `code`. O Easy o troca em `HUB/auth/exchange` (Basic com as credenciais
   `easy-mcp`, enviando o `redirect_uri`) e recebe o JWT `aud=easy-mcp` (+ refresh, §3.6).
8. O Easy gera um **code próprio** e redireciona o navegador ao cliente. O code é aleatório, de uso
   único, fica no Redis com TTL 5 min e é amarrado a `client_id` + `redirect_uri` +
   `code_challenge` + JWT.
9. O cliente troca o code em `/token` (PKCE verificado pelo SDK) e recebe
   `access_token` = **o JWT do Hub**, com `expires_in` = o `exp` dele.
10. Cada chamada a `/mcp` traz `Authorization: Bearer <JWT>`; o Easy a valida contra o JWKS do Hub.

Erros do Hub (usuário sem licença, inativo) viram uma página de erro simples, sem jargão.

### 3.3 Validação do token (toda chamada)

| Checagem | Regra |
|---|---|
| Assinatura | RS256 contra o JWKS do Hub (o mesmo cache de 1 h do `decode_token`) |
| `aud` | **exatamente** `easy-mcp`. Token `easy` (cookie da web) é recusado no MCP; token `easy-mcp` é recusado na web |
| `iss` | `EASY_JWT_ISSUER` (o mesmo emissor da web) |
| `exp` | vencido → `401`, e o cliente renova (§3.6) ou refaz o OAuth |
| Licença | modo derivado de `licencas` + override do Hub no Redis, pela **mesma função** do `require_auth` (`modo_acesso`). `BLOCKED`/`ARCHIVED` → nenhuma ferramenta; `VIEW_ONLY` → só leitura (`somente_leitura`) |
| Add-on MCP por módulo (Hub §P4) | autoriza SÓ `mcp_licencas` com status `ACTIVE` (`contexto.modulos_mcp`); `licencas`/`apps_licenciadas` não servem de fallback. Token sem nenhum add-on ativo (ou sem a claim) → **HTTP 403** `insufficient_scope` no `/mcp`. Ferramenta de módulo sem add-on → `licenca_insuficiente` |
| Sessão (Hub §P2) | `sid` do JWT consultado no Hub (`GET /auth/sessoes/{sid}/status`, Basic do app) por `backend/core/sessao_hub.py`, a MESMA função da web. Revogada ou inexistente → `401`. Status fresco por 60 s (cache do processo). Hub fora → tolera 5 min com o último "ativa", depois recusa. Token sem `sid` (anterior ao P2) passa. Kill switch: `EASY_SESSAO_UNICA=false` |

### 3.4 AuthContext

Toda ferramenta recebe internamente
`AuthContext(user_sub, email, nome, tenant_uuid, tenant_nome, tenant_codigo, apps, modulos_mcp, modo_licenca, client_id, sid)`
(`pode_escrever` deriva do modo de licença).
**Nenhum argumento da IA vira identidade.** Não existe parâmetro `tenant_uuid` nem `user_id` em
ferramenta alguma. Usuário com mais de um tenant escolhe o tenant **no login do Hub**; trocar de
tenant = reconectar.

### 3.5 Estado guardado pelo Easy (zero tabela nova)

| Coisa | Onde | Por quê |
|---|---|---|
| Cliente registrado (DCR) | **nenhum lugar**: o `client_id` é o próprio metadado do cliente, compactado e cifrado (Fernet, chave `EASY_MCP_CLIENT_SECRET`, prefixo `emc1.`). O SDK sorteia um uuid4 e passa a `register_client` o mesmo objeto que devolve ao cliente; é ali que o id é trocado (SDK travado em 2.3.0, coberto por `test_oauth.py`). Trocar a chave = os clientes reconectam | nada a perder num flush do Redis, nada a migrar |
| Pedido de autorização pendente | Redis, TTL 5 min | vida curta |
| Code do Easy → cliente | Redis, TTL 5 min, uso único (GETDEL) | vida curta |
| Plano de escrita (§6) | Redis, TTL 15 min | vida curta |
| Transcrição (lotes ligados, §4.3) | Redis, TTL 24 h | liga os lotes de uma planilha |
| Contadores de cota (§7) | Redis | o mesmo padrão do mobile |

Sem Redis, o OAuth e as escritas **recusam** (fail-closed). As cotas de leitura, como no mobile,
são fail-open.

### 3.6 Revogação, validade e refresh

- **Revogação (Hub §P2):** desconectar o MCP = o Hub revoga o `sid` daquele usuário × `easy-mcp`,
  sem tocar na sessão web. Sessão única por usuário × app.
- **Refresh (Hub §P3):** o exchange do Hub devolve um refresh rotativo amarrado ao `sid`. O Easy o
  entrega ao cliente **embrulhado** (Fernet com o `client_id` dentro, prefixo `emr1.`) e, no
  `grant_type=refresh_token`, repassa ao `HUB/auth/refresh`. O Hub reavalia usuário, tenant e
  add-ons: módulo removido some do JWT renovado; se todos forem removidos, o refresh é recusado e o
  cliente reconecta. O Easy não guarda refresh nenhum.

## 4. Ferramentas

### 4.1 Registro, categorias, módulos e textos

Cada ferramenta é registrada por `tools.publicar(server, fn, categoria=, modulo=)`. Esse registro
(`REGISTRO`) é a fonte única de três coisas: a checagem do módulo na execução, o filtro do
`tools/list` por usuário e a lista de ferramentas do `easy_guia`.

| Categoria | O que é | Efeito |
|---|---|---|
| `consulta` | catálogo PÚBLICO (SINAPI, CDHU, FDE…) | nenhum; cota anti-raspagem |
| `leitura` | dados DA EMPRESA (orçamentos, composição no orçamento, dados próprios) | nenhum |
| `previa` | simula uma alteração e devolve um plano | nenhum |
| `efetivacao` | `easy_aplicar_plano`: aplica um plano confirmado pelo usuário | o ÚNICO que grava |

A categoria aparece no título ("Prévia · Editar composição") e nas `ToolAnnotations`
(`readOnlyHint` = tudo menos efetivação; `idempotentHint` = todas). Os módulos são os slugs
canônicos do Hub: `easy-orca` (orçamento, cadastros, configuração, memória, descritivo) e
`easy-cpu` (catálogo e dados próprios). `easy_guia` e `easy_meu_acesso` são da plataforma
(qualquer add-on). O `tools/list` só anuncia os módulos com add-on MCP ativo, mas anunciar não é
autorizar: a execução confere de novo.

**Textos para a IA: um arquivo só.** Tudo o que a IA lê mora em `backend/api/mcp/conteudo/instrucoes_ia.md`:
- as `instructions` do servidor;
- o guia (papel, princípios, conceitos, protocolo, fluxos, erros, o que não fazer, gramática da
  memória);
- o título e a descrição de cada ferramenta e a explicação de cada campo;
- o conhecimento sobre a app e o ecossistema (`easy_sobre`);
- os avisos fixos das prévias (`proximo_passo`, `depois_de_aplicar`).

O código só pede por chave (`instrucoes.texto/lista/mapa/titulo`) e não guarda texto para a IA, nem
docstring de ferramenta, nem `Field(description=)`. As mensagens de RECUSA não estão no arquivo:
são o motivo da app, montado na hora (§5.5). A linguagem é de máquina: curta, imperativa e sem nada
interno (§5.7).

`test_instrucoes.py` garante:
- toda ferramenta tem título e texto, e nenhum bloco sobra;
- todo campo descrito existe no modelo;
- todo aviso usado existe, e nenhum sobra;
- nenhum padrão interno (`xxx_id`, `schema.tabela`, `/api/`, SQL) aparece nos textos;
- o apêndice está em dia.

**Apêndice gerado.** [`EASY_MCP_FERRAMENTAS.md`](EASY_MCP_FERRAMENTAS.md) sai do `instrucoes_ia.md` mais o
esquema real de cada ferramenta (parâmetros, tipos, obrigatoriedade, campos dos objetos). Para
regenerar: `.venv/bin/python -m backend.api.mcp.instrucoes --apendice`. Curou o texto, regenere. O teste
acusa apêndice velho.

Nomes em português, com prefixo `easy_` (o cliente pode ter vários servidores MCP; o prefixo evita
colisão). Todas as ferramentas têm `inputSchema` explícito e saída estruturada.

O que cada ferramenta faz está no apêndice. Abaixo ficam as **regras de cada domínio**, ou seja, o
que o apêndice não diz.

### 4.2 Acesso e navegação

- `easy_guia` é o protocolo estruturado mais as ferramentas DESTE usuário (geradas do registro).
- `easy_sobre` é o **conhecimento sob demanda**, para a IA responder "o que é / como funciona" sem
  gastar contexto:
  - sem tópico, devolve o SUMÁRIO (~1,5 mil tokens): grupo "Produtos do ecossistema" (visão geral, os
    9 produtos e o Easy Mobile) e grupo "Como a app funciona" (empreendimento e ativo, bancada,
    fontes-base, composições, BDI, L.S., recálculo, pauta única, memória, cronograma, descritivo,
    dados próprios, entregáveis, o próprio assistente);
  - com tópico, devolve só aquela explicação (~150–250 tokens);
  - o texto mora no `instrucoes_ia.md` (blocos `sobre.*`; a 1ª frase de cada um é o resumo do sumário);
  - os produtos vêm do que está no site (`conteudo/produtos_site.md`, consolidado da fonte canônica do Hub):
    o que é, objetivo, público e ligação no ecossistema, SEM lista de funções, cada um com a página
    pública (`/easy-orca` etc. em `https://www.axys-tec.com.br`); mudou o site, atualize aqui;
  - **regra:** a IA não afirma disponibilidade, prazo ou preço de produto; encaminha ao site.
- `easy_meu_acesso` devolve tenant, apps, modo de licença, se pode escrever e os limites.
- `easy_listar_empreendimentos` devolve os empreendimentos com os ativos aninhados, sem URL da tela
  (que carrega ids, §5.7).
- `easy_orcamento_arvore` é a mesma árvore da tela (`get_bancada`, revisão vigente):
  - o caminho sai no formato da tela (`2.1.3`);
  - recorte por prefixo e profundidade, com página de 500 linhas;
  - `tem_filhos=false` = grupo vazio; `sem_composicao` = serviço a conciliar;
  - ativo sem orçamento nasce com a R00 ao ser lido (o mesmo que abrir a aba).

### 4.3 Orçamento (bancada)

- **Buscar serviço** (`easy_orcamento_buscar_servico`) é o picker da bancada como serviço
  (`orcamento_busca.buscar_composicoes_ativo`):
  - só as fontes do ativo, com as próprias primeiro e a favorita no topo;
  - custo na edição/UF/modalidade do ativo;
  - confere a posse do ativo.
- **Replicar** (`replicar_itens`, sobre `_copiar_bloco`, o laço do `colar_itens`):
  - copia origens (serviço ou grupo com o conteúdo) para dentro de cada grupo destino, no fim;
  - a quantidade padrão é a da ORIGEM (o duplicar da tela zera de propósito, e continua zerando);
  - guardas da tela: `NIVEL_MAX`, lei da posição, anti-ciclo, destino tem de ser grupo e fora da
    origem; teto de 500 itens.
- **Transcrever planilha** (`orcamento_transcricao.transcrever_lote`, sobre `_criar_item` e
  `_resolver_codigo`): lote de até 100 linhas, sem worker.
  - A hierarquia vem da numeração (`2.2.1` → pai `2.2`, procurado no lote e nos lotes já
    aplicados). Item sem pai entra sob o destino escolhido pelo usuário.
  - Código não resolvido, ou de fonte fora do ativo, vira **linha de CONCILIAÇÃO** (texto em CAIXA
    ALTA, sem composição). Fica em erro na bancada até o usuário curar.
  - **O preço da planilha nunca vira preço:** só marca `preco_diverge` e `unidade_diverge`.
  - A transcrição (Redis, 24 h) liga os lotes. O lote seguinte só vem depois de o anterior ser
    aplicado. Medido: 100 linhas em 2,6 s.
- **Editar estrutura** (`orcamento_estrutura.editar_estrutura`, sobre `_editar_item`, `_set_codigo`,
  `_mover`, `_deletar`): até 200 operações numa transação. Operações:
  - `quantidade`;
  - `descricao` (CAIXA ALTA);
  - `composicao` (é assim que se cura a conciliação);
  - `mover`;
  - `remover` (os filhos sobem);
  - `inserir` (grupo, ou serviço por fonte+código);
  - `duplicar` (sem quantidade, como a tela).

  As guardas são MAIS estritas que as da tela: composição não encontrada ou de fonte fora do ativo
  é recusada; remover item com memória é recusado; mudar a quantidade de um serviço que vem da
  memória (ƒ) é recusado.
- **Composição no orçamento** (`orcamento_composicao_previa.editar_composicao`, sobre
  `_gravar_receita`, o miolo de `salvar_itens`). É **como o preço muda pelo MCP: pela composição,
  nunca por preço fixado.**
  - Mudanças: `coeficiente | incluir | remover | substituir` (por análogo confirmado).
  - Alcances, os do modal: `ORCAMENTO` (padrão), `CRIAR_PROPRIA`, `ATUALIZAR_CATALOGO`.
  - A composição é UMA por orçamento: editá-la muda todos os serviços que a usam (a prévia conta
    quantos são).
  - A parte do catálogo próprio roda depois, em conexões próprias, como na tela.
- **Cotação de insumo** (`orcamento_cotacao.cotar_insumo`, sobre `_gravar_cotacao`):
  - até 5 propostas como evidência;
  - método MENOR/MEDIA/MEDIANA/MIN_MED_MEDIANA ou preço informado;
  - para MO, grava o preço e as composições mantêm a L.S. (regra da tela).
- **Recalcular preços** (`orcamento_recalculo.recalcular_precos`, sobre `_converter_precos`, o
  "Converter preços" da tela).
  - Re-resolve a base de cada item pelas fontes/edições/L.S./regime/BDI vigentes e regrava o custo.
  - Preço fixado não se mexe; receita editada no orçamento mantém o seu custo.
  - A prévia devolve o Δ do total e as 15 maiores variações.
  - **REGRA (Renan): é OBRIGATÓRIO logo depois de mudar BDI ou L.S.** Sem ele, a bancada fica com
    os preços da configuração anterior. As prévias e os resultados de BDI/L.S. dizem isso à IA
    (`depois_de_aplicar` / `proximo_passo`), e o guia e as `instructions` também. Fontes-base e
    pauta única já recalculam dentro da função da tela.
- **Pendências** (`easy_orcamento_pendencias`): reúne as pendências da exportação da app, os itens a
  conciliar e os itens sem quantidade. Os entregáveis se geram SÓ na app.

**"O que já está na bancada se repete, sempre" (Renan).** A composição e o insumo são únicos no
orçamento. Nos 4 pontos de ENTRADA (`_criar_item`, colar, `_set_codigo`, troca de composição no
`editar_item`), `_base_na_entrada` faz o item novo cuja composição outro item já usa herdar do
irmão o custo, o regime/L.S. e as marcas de conversão. Só composição nova vai à fonte. A conversão
de preços, a rotação de regime e o desafixar seguem recalculando pela fonte (é a intenção deles).
Isso corrigiu um defeito pré-existente da TELA, achado pelo MCP: inserir serviço com receita editada
gravava custo 0,00 e zerava a composição para todos.

### 4.4 Memória de cálculo: o grid da TELA, nenhum formato próprio

O MCP escreve o que a tela grava: `corpo.celulas` por posição A–K, `corpo.ids` com id estável,
`prox_id` e `corpo.vinculos`. Calcula pelo motor da tela, espelhado em `ativo/memoria_motor.py`
(tradução linha a linha do `easy_memoria.js`, inclusive o `String(n)` do JS e o `1e-7` que vira
#ERRO). As ações seguem a sequência do front pelas funções de `memoria_service`:
- `salvar_memoria`;
- `associar_item` / `desassociar_item`;
- `vincular_item` / `remover_vinculo`.

Os limites são 500 células por escrita e o grid existente. Fica de fora: inserir linha deslocando
fórmulas, e os anexos.

**Versão:** o salvar da memória (da tela e do MCP) manda a versão carregada, e o servidor só grava
se ela ainda é a vigente (`UPDATE … WHERE mc_versao = versao`). Uma tela aberta antes de o MCP
escrever não apaga mais o que ele gravou: ela recusa e pede para recarregar.

### 4.5 Descritivo da composição NO ORÇAMENTO (funcionalidade nova)

- **Onde fica:** colunas `aoc_descritivo` (mesma forma de `cmp_descritivo`) e `aoc_justificativa`
  (só para composição própria). Migration `2026-10-20_aoc_descritivo.sql`, aditiva.
- **REGRA:** vale SEMPRE o do orçamento; NULL = herda do catálogo (CTC) ou da própria. A edição
  afeta só este orçamento (todos os serviços que usam a composição). O catálogo próprio se muda na
  tela dele.
- **Serviço** (`ativo/orcamento_descritivo.py`):
  - a 1ª edição parte do texto herdado;
  - texto vazio apaga; `restaurar` volta a herdar;
  - `descritivo_efetivo` é o leitor dos entregáveis;
  - audita sempre, e só grava em RASCUNHO.
- **Caderno de Encargos:** imprime o do orçamento quando ele existe. Provado: sem edição, saída
  idêntica em 3 orçamentos; com edição, sai a medição editada e a remuneração herdada.
- **Tela:** botão direito no serviço → "Ver descritivo" (espelho de "Ver composição"), com edição
  por seção e "Restaurar herdado".
- **Importar de outro orçamento:** copia o descritivo e SUBSTITUI o do destino ("copiou é porque
  quer o outro").

### 4.6 Cadastros e configuração do orçamento

Padrão §6.1 (antes → depois, aplicação pela função DA TELA).
- **Cadastros:** empreendimento criar/editar/arquivar (excluir não existe na app) e ativo
  criar/editar. O criar ativo usa a capacidade da licença, como na rota. Excluir ativo só na tela.
- **BDI:** o percentual sai da FÓRMULA da app, e a prévia mostra onde cada parcela cai na faixa do
  TCU (os valores são do usuário).
- **L.S.:** `semear` (reset a partir da fonte, substitui inteira) ou `editar` (itens e totais).
- **Fontes-base:**
  - `easy_fontes_salvar` recebe a lista COMPLETA, que substitui a atual, como na tela;
  - a edição vai pelo rótulo (o id fica por dentro);
  - toda fonte precisa de edição;
  - fonte com serviço na bancada não sai (a recusa diz quais itens);
  - a função da tela recalcula ao salvar, e o resultado traz o Δ do total.
- **Cronograma:**
  - `configurar` = prazo (múltiplo de 30) + NÍVEL de corte (só os que fecham o total; a prévia diz
    quais e por quê);
  - `preencher` = `salvar_percent` célula a célula, tudo validado na prévia (ALO, prazo, 0–100,
    soma por linha);
  - `substituir` = `aplicar_percents` (nenhuma linha fica com valor sem distribuição).
- **Pauta única do empreendimento** (contrato
  [`HERANCA_ORCAMENTO_EMPREENDIMENTO.md`](HERANCA_ORCAMENTO_EMPREENDIMENTO.md)). São 3 flags no
  empreendimento: Fontes/Edição, BDI e L.S./Regime. Empreendimento novo nasce com as três ligadas.
  - **Ligada:** o registro fica no empreendimento e os ativos herdam. O ativo NÃO recebe registro daquela
    pauta: as funções da tela recusam (`pauta_herdada`), e as ferramentas do ativo recusam já na prévia,
    com a referência do empreendimento a usar.
  - **Configurar no empreendimento:** as ferramentas de fontes, BDI e L.S. aceitam `ativo` OU
    `empreendimento`. No empreendimento, só com a pauta ligada, e o aplicar usa as funções da tela
    (`salvar_fonte_emp`, `salvar_bdi_emp`, `semear_ls_emp`, `salvar_ls_emp`), que gravam na mestre,
    propagam a todos os ativos e recalculam cada um. Por isso não se pede recálculo depois.
  - **Onde vale:** as leituras dizem em `definido_em` (`ativo` | `empreendimento`).
  - **Ligar e desligar:** `acao: ligar | desligar`, verbo explícito. Ligar exige os ativos iguais e copia
    a configuração; desligar só destrava (cada ativo mantém os valores atuais). Nenhum dos dois muda preço.
  - **O nível é decisão do usuário**, tomada ao aplicar os dados; o guia manda a IA perguntar.
  - **Incidente que motivou o verbo explícito (22/10/2026):** com um booleano `unica`, a IA desligou as três
    pautas de um empreendimento novo (que nasceu com elas ligadas) enquanto dizia ao usuário que estavam
    ativadas. A auditoria mostrou os três planos.

### 4.7 Dados Próprios (Easy CPU)

- **Ferramentas:** listar, ver, cadastrar, editar e preços. Editar cobre a identidade e o descritivo
  (medição, remuneração, justificativa); texto vazio apaga, campo ausente fica. Preços são o valor
  informado ou até 5 propostas + método.
- **Como:** só CHAMA as funções da tela de `dados_proprios_service`, que auditam. Os itens vão por
  fonte + código (+ UF), e a edição pelo mês da data-base (AAAA-MM).
- **Lote:** até 100, gravado item a item como na tela. Para no primeiro erro, com o motivo e o que
  já foi gravado.
- **Receita da composição própria:** pela bancada (`easy_composicao_editar`, alcance
  `ATUALIZAR_CATALOGO`).
- `easy_proprios_precos_insumos` (sob demanda): insumos ativos com preço de data-base anterior a um
  mês, e os sem preço. A régua é a data-base, não o rótulo da edição (texto livre); a divergência
  vem sinalizada.

### 4.8 Catálogo público (Easy CPU)

- `easy_buscar_composicoes` / `easy_buscar_insumos` usam o mesmo `SearchService.search_catalog` da
  app, reidratado no Postgres e paginado, com o item identificado por **fonte + código**.
- **O primeiro resultado não é declarado tecnicamente correto:** quem decide é o operador.
- **Lacuna conhecida:** busca livre na biblioteca PRÓPRIA. Hoje ela é feita por
  `easy_orcamento_buscar_servico` (no contexto de um ativo) e pelas ferramentas de dados próprios.

### 4.9 Fila (sob demanda, não promessa)

| Candidata | Categoria | Serviço que já existe |
|---|---|---|
| curva ABC de serviços e insumos | leitura | `get_curva_abc` / `get_curva_abc_insumos` |
| insumos e composições do orçamento | leitura | `orcamento_listas.insumos_do_orcamento` / `composicoes_do_orcamento` |
| histograma, versões do orçamento | leitura | `get_histograma`, `versoes_do_orcamento` |
| pré-planejamento | — | suspenso (Renan, 2026-10-20) |

## 5. Regras que valem para toda ferramenta

1. **Só serviço de domínio.** A ferramenta não abre cursor nem monta SQL de negócio. Se falta
   serviço, o serviço nasce no módulo dele (`backend/modules/ativo/…`), nunca dentro de
   `backend/api/mcp/`.
2. **Posse do recurso no serviço** (`_own` e equivalentes). ID de outro tenant devolve **o mesmo**
   "não encontrado" de ID inexistente (sem enumeração).
3. **Escrita só na revisão vigente** (`aor_de`) e só em RASCUNHO, como na tela.
4. **Mesmas guardas da tela:** `NIVEL_MAX`, lei da posição, fonte utilizável com data-base,
   TRUNC(2). O MCP não ganha atalho que a tela não tem; onde diverge, é mais estrito (§4.3).
5. **Toda recusa traz o MOTIVO** (Renan): a mensagem da app vai inteira para a IA, para ela relatar
   ao usuário o porquê e o que fazer, nunca um "não deu certo" genérico.
   - Formato: `{erro: <codigo>, mensagem}`.
   - Códigos: `nao_autorizado`, `licenca_insuficiente`, `somente_leitura`, `nao_encontrado`,
     `entrada_invalida`, `conflito`, `limite` (com `retry_after_s`), `interno`.
   - Nunca sai stack trace, SQL, caminho de arquivo nem segredo.
6. **Saída enxuta.** Pagina tudo que pode crescer. Valores monetários em número com 2 casas,
   acompanhados de fonte, edição, UF e modalidade.
7. **Nada interno sai pelo MCP** (Renan). O que o MCP mostra dá a ordem de grandeza do MCP, nada
   interno da app:
   - nenhum nome de coluna, endpoint ou URL interna; os campos vêm em vocabulário de domínio (`ref`,
     `caminho`, `quantidade`, `fonte`, `codigo`);
   - nenhum id sequencial: o identificador é uma **referência opaca** (`emp_…`, `ativo_…`, `item_…`,
     `mem_…`; `refs.py`):
     - AES de um bloco com o tipo embutido;
     - determinística, reversível sem tabela e inadivinhável;
     - a ref de item não abre ativo, e uma ref adulterada dá `nao_encontrado`;
     - a ref não autoriza nada: a posse segue conferida no serviço;
   - composição e insumo de catálogo vão pelo identificador **público**: fonte + código; edição,
     pelo rótulo;
   - nada que revele como o sistema foi construído.

   `test_leitura.py` varre a saída das ferramentas atrás de nome de coluna e de id interno, e
   `test_instrucoes.py` varre os textos.
8. **O MCP não muda o comportamento da bancada** (Renan). Ele só chama o que a tela chama. Quando
   precisa de transação única para prévia/aplicação, o serviço da tela vira CASCA de um miolo
   extraído sem mudança de lógica. Os miolos de hoje:
   - `_copiar_bloco` (colar_itens);
   - `_criar_item` (criar_item);
   - `_gravar_receita` (salvar_itens);
   - `_gravar_cotacao` (salvar_cotacao);
   - `_editar_item` / `_montar_edicao` (editar_item);
   - `_set_codigo` (set_codigo_item);
   - `_deletar` (deletar_item);
   - `_converter_precos` (converter_precos).

   Nenhuma coluna, flag ou estado novo para o MCP; nada de preço fixado. **Prova:** a versão antiga
   e a nova de cada uma, rodadas sobre dados reais em conexão sem commit, deixam estado e retorno
   IDÊNTICOS (§13). Toda extração nova repete essa prova. Mudança de comportamento só com decisão
   explícita do Renan, registrada aqui: `_base_na_entrada` (§4.3) e a versão da memória (§4.4).
9. **Tudo que mexe em dado fica registrado** (§8).

## 6. Escrita em duas fases: prévia → aplicar

A proteção existe **contra a IA do usuário**, que pode errar feio no negócio. Por isso vale em dev
e em prod, e não depende de o cliente pedir confirmação.

1. A ferramenta de prévia **não escreve**. Ela valida tudo, calcula o que vai acontecer e grava no
   Redis um **plano** com `{ferramenta, atv_id, params, digital, criado_por, expira_em}`. Devolve à
   IA a prévia legível (contagens, exemplos, impacto, recusas) e a ref do plano.
2. A IA mostra a prévia ao usuário. O usuário confirma.
3. `easy_aplicar_plano(plano)`:
   - plano de outro usuário/tenant → `nao_encontrado`; plano vencido (15 min) → `conflito`;
   - confere a **digital**: mudou desde a prévia (alguém editou na tela) → `conflito`, e nada é
     escrito;
   - executa **numa transação só** quando a operação é de bancada (ou entra tudo, ou nada);
   - consome o plano: aplicar de novo devolve **o mesmo resultado**, sem escrever outra vez
     (idempotência; uma trava impede aplicação dupla concorrente).

**Dois estilos de prévia:**
- **Execução desfeita (bancada):** replicar, transcrever, estrutura, composição, cotação e
  recálculo.
  - O serviço executa a operação inteira e faz rollback (`simular=True`): a prévia não é uma conta
    paralela que poderia divergir do que se aplica.
  - A digital é o hash da revisão inteira (`digital_orcamento`), conferida com a revisão travada
    (`FOR UPDATE`).
  - Efeito colateral aceito: cada prévia consome números da sequência de itens. Por isso os itens
    novos saem na prévia **sem ref**; a ref nasce no aplicar.
- **Antes → depois (§6.1: cadastros, configuração, dados próprios, memória, descritivo):**
  - a prévia valida e mostra o estado atual e o proposto, lidos pelas funções da tela;
  - a digital é a desse estado;
  - o aplicar relê, confere e chama a função DA TELA, com a validação e as guardas de licença dela.

**Tetos por operação:**

| Operação | Teto |
|---|---|
| replicar | 500 itens |
| transcrever | lote de 100 linhas |
| editar estrutura | 200 operações |
| memória | 500 células |
| dados próprios | lote de 100 |

### 6.2 Confirmação proporcional ao risco (Renan, 22/10/2026)

A prévia é sempre obrigatória: é ela que pega o conflito com a tela e dá o plano idempotente. O que varia
é QUANDO a IA precisa parar e perguntar ao usuário. Exigir confirmação a cada plano queimava tokens e
paciência (criar um empreendimento e um ativo vazio custava duas idas e voltas). Cada prévia declara um
nível, numa tabela única (`tools.RISCO`), e o envelope do `publicar` carimba `confirmacao` e o
`proximo_passo` correspondente em toda prévia:

| Nível | A IA faz | Ferramentas |
|---|---|---|
| `livre` | aplica direto e informa | criar/editar empreendimento e ativo, criar memória, descritivo |
| `tarefa` | uma autorização do usuário vale para a tarefa inteira | transcrever, estrutura, replicar, memória (escrever/ligar), cronograma, composição no orçamento, cotação, recálculo, dados próprios |
| `sempre` | confirmação explícita a cada plano | arquivar, excluir memória, BDI, L.S., fontes-base, pauta única |

A ferramenta pode SUBIR o nível pelo conteúdo, nunca descer: estrutura com `remover` e composição com
alcance fora do orçamento viram `sempre`. Na primeira ação `tarefa` ou `sempre` da conversa, a IA explica
o protocolo em uma linha e oferece a autorização em bloco. O apêndice mostra o nível de cada ferramenta.

## 7. Anti-raspagem do catálogo

O risco: um concorrente usar o MCP para baixar o banco de insumos/composições ("isto, aquilo,
aquilo outro"). Vale a mesma doutrina do Easy Mobile (`backend/api/mobile/limites.py` e
`rate_limit.py`), reusada e não copiada (escopos `mcp` e `mcp_busca`):

| Guarda | Default | Env |
|---|---|---|
| Termo mínimo | 3 caracteres | (constante do mobile) |
| Itens por página | 20 (máx. 50) | `EASY_MCP_POR_PAGINA` |
| Páginas por termo | 10 | (constante do mobile) |
| Buscas por minuto / por dia, por usuário | 30 / 400 | `EASY_MCP_BUSCA_MIN` / `_DIA` |
| Chamadas por minuto / por dia, por usuário (todas) | 120 / 5000 | `EASY_MCP_RATE_MIN` / `_DIA` |

O termo mínimo sozinho não basta (o raspador varre `aaa`, `aab`, …). Quem trava a varredura é a
**cota diária por usuário**, que um humano orçando não alcança. Estourou → `limite` com
`retry_after_s`. Leitura do **próprio** orçamento não tem cota de busca, só a geral.

## 8. Auditoria

Tudo o que o MCP grava fica em `audit.logs`, com o e-mail do usuário. **A tela não muda:** a
doutrina da bancada (não auditar por operação) continua valendo para ela.

| Caminho | Quem audita | Como |
|---|---|---|
| Bancada: replicar, transcrever, estrutura, composição, cotação, recálculo | o serviço, na MESMA transação, pela `trilha` | 1 linha por aplicação: `{canal:"mcp", ferramenta, plano, …impacto/ids}` |
| Cadastros (empreendimento, ativo) | a função da tela (`ativo/service.py`) | o que a tela já grava |
| Dados próprios | a função da tela (`dados_proprios_service`, schema lógico `tenant_catalogo`) | o que a tela já grava |
| Descritivo no orçamento | `orcamento_descritivo.salvar_descritivo` | antes/depois do texto |
| Memória: criar, excluir, associar, vincular | a função da tela (`memoria_service._audit`) | o que a tela já grava |
| Memória: escrever no grid | **o MCP** (`planos.auditar`); a tela não audita o salvar do grid (ruído) | células alteradas antes/depois + versão |
| BDI, L.S., fontes-base, cronograma | **o MCP** (`planos.auditar`); essas funções da tela não auditam | estado antes/depois |
| Pauta única do empreendimento | **o MCP** (`planos.auditar`) | pauta antes/depois + ativos recalculados |

Toda linha do MCP leva `canal:"mcp"`, a ferramenta e o plano. O login via MCP cai no
`audit.login_log` do Hub (origem `easy-mcp`).

> **Lacuna da TELA (fora do escopo do MCP):** BDI, L.S., fontes-base, cronograma e herança não
> auditam quando feitos pela tela. Pela doutrina ("CRUD/estado audita sempre"), deveriam. Fica
> para decisão do Renan.

## 9. Transporte e segurança HTTP

- Streamable HTTP, `stateless_http=True` (sem sessão em memória; qualquer worker atende).
- `TransportSecuritySettings` do SDK com allowlist de Host/Origin (`EASY_MCP_ALLOWED_HOSTS`).
- Ferramentas são `def` síncronas, como as rotas: valem os mesmos limites do pool
  (`EASY_DB_POOL_SIZE`). Nada de escrita longa síncrona: os tetos (§6) mantêm cada chamada em
  segundos. Se uma ferramenta futura precisar de mais, ela vira job (ADR-006).
- O SDK fixa o OAuth e os metadados na **raiz** do host (`/authorize`, `/token`, `/register`,
  `/revoke`, `/.well-known/oauth-*`). Um despachante ASGI (`_DespachaMCP`) na frente da app desvia
  para o MCP só esses caminhos, mais `/mcp` e `/mcp/oauth/hub-callback`. O resto (inclusive o 404
  da web) segue intocado. **Nenhuma rota do Easy pode nascer nesses caminhos.**
- Nada disso aparece no OpenAPI/docs da app.

## 10. Ambientes e configuração

| | Dev | Prod |
|---|---|---|
| URL MCP | `https://mcp-dev.axys-tec.com.br/mcp` (cloudflared → `localhost:8788`) | `https://<host do Easy>/mcp` |
| Hub | local `127.0.0.1:8000` (o navegador alcança direto) | `axys-tec.com.br` |
| Exposição | túnel com **ingress filtrado** (`infra/cloudflared/mcp-dev.yml`): só `/mcp*`, `/authorize`, `/token`, `/register`, `/revoke` e `/.well-known/oauth-*`; o resto → 404 | o próprio Easy |
| Subir | `EASY_MCP_TUNNEL=1 ./run_dev.sh` | deploy normal |
| Login | fluxo real do Hub, sem bypass (`EASY_AUTH_BYPASS=false`) | idem |

Só o Easy precisa ser alcançável pelo servidor da OpenAI. A ida ao Hub acontece no navegador do
usuário (login) e de servidor a servidor a partir do Easy (exchange), então o Hub de dev continua
local.

| Env | Para quê |
|---|---|
| `EASY_MCP_ENABLED` | liga a montagem do `/mcp` |
| `EASY_MCP_PUBLIC_URL` | issuer do OAuth e URL do recurso |
| `EASY_MCP_ALLOWED_HOSTS` | Host/Origin do transporte |
| `EASY_MCP_CLIENT_SECRET` | chave Fernet do `client_id` autocontido e do refresh embrulhado |
| `EASY_MCP_SSO_CLIENT_ID` / `_SECRET` | exchange e status de sessão no Hub (app `easy-mcp`) |
| `EASY_MCP_SSO_AUDIENCE` | aud exigida (default `easy-mcp`) |
| `EASY_MCP_POR_PAGINA`, `EASY_MCP_BUSCA_MIN/_DIA`, `EASY_MCP_RATE_MIN/_DIA` | cotas (§7) |
| `EASY_SESSAO_UNICA` | kill switch da checagem de sessão (§3.3) |
| `EASY_MCP_TUNNEL` | só dev: `run_dev.sh` sobe o túnel junto |

## 11. Testes (`backend/tests/mcp/`)

| Teste | Garante |
|---|---|
| `test_token.py` | aud errada, vencido, outra chave, malformado → 401; token `easy` recusado no MCP e `easy-mcp` na web; VIEW_ONLY, BLOCKED; 404 da web intacto |
| `test_oauth.py` | DCR autocontido; PKCE; code de uso único; callback sem pedido recusado; refresh embrulhado |
| `test_sessao.py` | `sid` revogado/inexistente → 401; cache; tolerância com o Hub fora; kill switch |
| `test_modulos.py` | add-on por módulo (um teste por item da lista do Hub §P4); `tools/list` por usuário; 403 sem add-on |
| `test_leitura.py` | refs (ida e volta, tipo trocado, adulterada); ativo alheio = não encontrado; árvore; busca; cota; nada interno na saída |
| `test_escrita.py` | prévia não escreve; conflito; aplicar duas vezes = uma escrita; plano de outro usuário |
| `test_transcricao.py`, `test_estrutura.py`, `test_composicao.py` | tradução das operações, plano, recusas com motivo |
| `test_cadastro_config.py` | cadastros, BDI, L.S., fontes-base, pauta única, cronograma, recálculo explícito, auditoria |
| `test_proprios.py`, `test_descritivo.py`, `test_memoria.py` | idem nos respectivos domínios |
| `test_memoria_motor.py` | motor Python = `easy_memoria.js` no node (326 planilhas) |
| `test_instrucoes.py` | cobertura do `instrucoes_ia.md` nos dois sentidos, nada interno, apêndice em dia |

```bash
.venv/bin/python -m unittest discover -s backend/tests/mcp -t .
```

As provas de equivalência contra dados reais (§13) não são testes de CI: rodam em conexão sem
commit no dev, a cada extração nova. A validação de cada fase foi feita no **fluxo real em
localhost** (os 3 serviços no ar, login real pelo Hub local, sem bypass) e no ChatGPT pelo túnel.

## 12. Produção (pendente; push/deploy só com OK explícito do Renan)

1. Hub prod: P1–P4 e as migrations 013–016 do Hub (app `easy-mcp`, callback/allowlist com o host
   do Easy, sessão, refresh, `mcp_licencas`).
2. Easy prod: migration `2026-10-20_aoc_descritivo.sql`.
3. Envs no Render (§10) com segredos NOVOS (`EASY_MCP_CLIENT_SECRET`, credenciais `easy-mcp` do Hub
   prod), e `EASY_MCP_ENABLED=true`.
4. Commit sem misturar trabalho em andamento de outras frentes (stage só dos hunks do MCP).
5. Smoke em prod com o usuário do Renan: conectar, ler, uma escrita num ativo de teste.
6. Atualizar `pendencias.md` e as memórias.

O deploy do Render reinicia o container e mata job em execução: combine a janela.

## 13. Histórico e provas (2026-10-20)

| Marco | O quê |
|---|---|
| Fase 0 — fundação | `mcp==2.3.0`; `modo_acesso()` extraído do `require_auth` (web sem mudança); despachante ASGI; túnel com ingress filtrado. Checkpoint pelo túnel: 401 com metadados em https; `/main` e `/login` → 404 |
| Fase 1 — OAuth | provider com DCR autocontido, authorize→Hub, hub-callback com exchange, code próprio; Redis fail-closed. Hub P2 → checagem de `sid` (web e MCP, a mesma função) |
| Hub P3/P4 | refresh embrulhado; `mcp_licencas` por módulo, `tools/list` por usuário, 403 sem add-on. **Regra: nada interno sai** → refs opacas |
| Fase 2 — leitura | checkpoint no ChatGPT: 110 de 134 grupos N3 vazios no PIZZA HUT, batendo com o banco. 10/10 num roteiro de testes no ChatGPT |
| Replicar | `_copiar_bloco` extraído; ativo 34 em simulação: 110 destinos em 0,86 s, orçamento intacto |
| Transcrever | `_criar_item` extraído; 100 linhas em 2,6 s (ativo 22, simulação) |
| Composição e cotação | `_gravar_receita`, `_gravar_cotacao` extraídos. Dev em simulação: C-000092 11,94→12,14, 22 serviços, Δ +88,00 (+0,66%) |
| **Equivalência da bancada** | versão antiga × nova de `colar_itens`, `criar_item` (grupo e serviço), `salvar_itens`, `salvar_cotacao`, `editar_item`, `set_codigo_item`, `deletar_item` no PIZZA HUT, em conexão sem commit: **13 casos em 8 funções, estado e retorno IDÊNTICOS**, 0 persistido. `_converter_precos`: idêntico nos ativos 22/26/34; receitas editadas intactas (30/32/34) |
| Defeito da tela corrigido | inserir serviço com receita editada gravava 0,00 e zerava a composição → `_base_na_entrada` (OK do Renan). Equivalência: 12 idênticos + 1 diferença intencional |
| Memória | motor espelhado; **326 planilhas = JS no node; 177 memórias / 4.868 células reais = 0 divergência**; ida e volta pela tela no dev. Versão no salvar (OK do Renan): certa grava, velha recusa |
| Descritivo no orçamento | colunas + migration; Caderno de Encargos idêntico sem edição em 3 orçamentos; tela "Ver descritivo"; importar substitui |
| Recalcular | ativo 22: 3 itens, −71,85; ativo 26: 33 itens, +3.844,35 (+0,71%); ativo 34: 0 — em simulação, tudo intacto |
| Fontes-base e pauta única | ferramentas novas; recusa por herança na prévia; `definido_em` nas leituras |
| Conhecimento | `easy_sobre` (sumário → tópico): ecossistema a partir da fonte editorial do Hub; app a partir do implementado (fórmula do BDI e regra da Administração Local conferidas no código) |
| Confirmação e empreendimento | níveis livre/tarefa/sempre (§6.2); fontes, BDI e L.S. configuráveis no empreendimento com a pauta única; herança com `acao` ligar/desligar depois do incidente em que a IA desligou as três pautas |
| Textos | `instrucoes_ia.md` como fonte única + apêndice gerado; os 48 textos e todas as explicações de campo conferidos iguais aos de antes da mudança |

Achados à parte, não do MCP:
- `test_licensing_capacity.test_usage_audit_is_idempotent_and_local` já falhava antes (procura
  `ON CONFLICT` com nomes de coluna antigos).
- No dev, a edição PRÓPRIA tem data-base 2026-08-01 com rótulo "09-26".
- PENDÊNCIA: a rota `bancada_buscar_api` passar a chamar `buscar_composicoes_ativo` (e sair o
  `_cfg_fonte_do_ativo` duplicado de `routes.py`).

## 14. Critérios de aceite

1. O ChatGPT conecta pela URL, autentica pelo Hub e nunca recebe senha. ✅ dev
2. `easy_meu_acesso` mostra tenant, apps e modo de licença corretos. ✅ dev
3. O usuário do tenant A não lê nem escreve no ativo do tenant B, nem com ID conhecido (mesma
   resposta de ID inexistente). ✅ testes
4. O token `easy` (da web) é recusado no `/mcp`, e o token `easy-mcp` é recusado na web. ✅ testes
5. Token vencido, assinado por outra chave, de outra audiência ou malformado → `401`. ✅ testes
6. `VIEW_ONLY` → as ferramentas de escrita devolvem `somente_leitura`. ✅ testes
7. `easy_buscar_composicoes` devolve os mesmos candidatos, na mesma ordem, que a busca da app com
   filtros equivalentes. ✅ por construção (a ferramenta chama o mesmo `search_catalog`, com os
   mesmos filtros); sem teste dedicado
8. Prévia não altera nada. Plano velho → `conflito`. Aplicar duas vezes → uma escrita. ✅ testes
9. Toda aplicação fica em `audit.logs` (§8). ✅ testes
10. Cota de busca estourada → `limite`, e a app web segue normal. ✅ testes
11. Erros nunca expõem SQL, stack trace ou segredo. ✅ testes
12. **Caso real:** no ativo 34 (R00), a IA replica o serviço dos grupos de 2.1 nos grupos de nível
    3 vazios de 2.2–2.7, com prévia e aplicação, e a tela mostra o mesmo resultado que um
    copiar/colar manual daria. ✅ simulação; ⏳ aplicação pelo ChatGPT
13. A bancada se comporta igual com e sem o MCP (§5.8). ✅ provas de equivalência
