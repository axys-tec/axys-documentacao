# Easy MCP — contrato

**Versão:** V0 (prévia, 2026-10-20) · **Status:** contrato governa; código a implementar conforme
[`plano_mcp.md`](../../../../plano_mcp.md) · **Origem:** proposta inicial
`axys_easy_mcp_proposta_inicial.md` (Renan, 2026-10-20), conferida contra o repositório.
**Companheiros:** [`EASY_HUB_MCP.md`](EASY_HUB_MCP.md) (o que o Hub entrega),
[`EASY_PERFIS_PERMISSOES.md`](EASY_PERFIS_PERMISSOES.md) (claims),
[`ativo/bancada_orcamento_contrato.md`](ativo/bancada_orcamento_contrato.md) (regras da árvore).

> Código e SQL que implementam este contrato referenciam este arquivo no topo.

---

## 1. O que é, e o que não é

O MCP do Easy é **mais uma interface** para os serviços que a app web já usa. A IA do usuário
(ChatGPT, Claude, outro cliente MCP) interpreta o pedido e escolhe as ferramentas; o Easy executa
operações validadas, com a mesma identidade, o mesmo tenant, a mesma licença e as mesmas regras
da tela.

**Por que existe.** Toda operação repetitiva da bancada pedia uma tela nova — e cada tela nova é
mais suporte. Exemplo que abriu a frente: no ativo 34 (R00), dezenas de grupos de nível 3 das
disciplinas 2.2–2.7 precisam do mesmo serviço que os grupos de 2.1 já têm. Na tela é um
copiar/colar por grupo; no MCP é um pedido.

**Não é:** um agente de IA nosso (não hospedamos nem cobramos inferência), um acesso ao banco, um
SQL livre, um proxy HTTP genérico, nem uma segunda plataforma de identidade.

**Princípio:** um usuário, um tenant autorizado, uma regra de negócio, várias interfaces.

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
  │  /mcp  ← Streamable HTTP (SDK `mcp` 2.x, MCPServer)                              │
  │        └─ AuthContext (JWT do Hub, aud=easy-mcp) → ferramentas → serviços Python │
  └──────────────────────────────────────────────────────────────────────────────────┘
        │ exchange do code (server→server)          │
        ▼                                           ▼
     Axys Hub (identidade, licença, sessão)    PostgreSQL / OpenSearch / R2 / Redis
```

- **Um único servidor MCP para o Easy**, montado na app FastAPI principal. Sem serviço Render novo.
- A app web **não depende** do MCP: falha no `/mcp` não derruba rota REST nem tela.
- Código separado em `backend/api/mcp/` (espelha `backend/api/mobile/`), para poder virar serviço
  próprio no futuro sem reescrever regra de negócio.

## 3. Identidade e autenticação

### 3.1 Quem é a autoridade

**O Hub.** O Easy não cria usuário, não cria role, não guarda senha e não emite identidade
própria para o MCP. O Easy apenas **coordena** o OAuth que os clientes MCP exigem e repassa a
eles o JWT que o Hub assinou.

O Hub registra um **app de SSO novo, `easy-mcp`** (ao lado de `easy`, `easy-mobile`, `gestor`),
com client próprio, `aud=easy-mcp` e as mesmas claims do `easy` — ver
[`EASY_HUB_MCP.md`](EASY_HUB_MCP.md) §P1. "Um MCP por produto" = um app de SSO por produto.

### 3.2 Fluxo de conexão (OAuth 2.1 + PKCE, com o Hub como provedor de identidade)

1. Usuário cadastra a URL `https://<host>/mcp` no cliente MCP.
2. Cliente chama `/mcp` sem token → `401` + `WWW-Authenticate` apontando o
   `/.well-known/oauth-protected-resource/mcp` (RFC 9728).
3. Cliente lê os metadados do servidor de autorização (RFC 8414, `/.well-known/oauth-authorization-server`)
   e se registra em `/register` (Dynamic Client Registration, RFC 7591).
4. Cliente abre no navegador `/authorize` (com `code_challenge` S256 e `state`).
5. Easy guarda o pedido no Redis (TTL 5 min) e redireciona o navegador para
   `HUB/login?app=easy-mcp&redirect_uri=<host>/mcp/oauth/hub-callback&state=<state Easy>`.
6. Usuário faz login **no Hub** (ou passa direto, se já tem sessão no Hub). O cliente MCP nunca vê
   a senha.
7. Hub devolve `code` → Easy troca em `HUB/auth/exchange` (Basic com as credenciais `easy-mcp`) →
   recebe o JWT `aud=easy-mcp`.
8. Easy gera um **code próprio** (aleatório, uso único, Redis TTL 5 min, amarrado a
   `client_id` + `redirect_uri` + `code_challenge` + JWT) e redireciona o navegador ao cliente.
9. Cliente troca o code em `/token` (PKCE verificado pelo SDK) e recebe
   `access_token` = **o JWT do Hub**, `expires_in` = o `exp` dele.
10. Cada chamada a `/mcp` traz `Authorization: Bearer <JWT>`; o Easy valida contra o JWKS do Hub.

### 3.3 Validação do token (toda chamada)

| Checagem | Regra |
|---|---|
| Assinatura | RS256 contra o JWKS do Hub (mesmo cache de 1 h do `decode_token`) |
| `aud` | **exatamente** `easy-mcp`. Token `easy` (cookie da web) é recusado no MCP, e token `easy-mcp` é recusado na web |
| `iss` | `EASY_JWT_ISSUER` (mesmo emissor da web) |
| `exp` | vencido → `401`, o cliente refaz o OAuth |
| Licença | modo derivado de `licencas` + override do Hub no Redis — **a mesma função** do `require_auth`. `BLOCKED`/`ARCHIVED` → nenhuma ferramenta; `VIEW_ONLY` → só leitura |
| Sessão | `sid` do JWT consultado no Hub (`GET /auth/sessoes/{sid}/status`, Basic do app) por `backend/core/sessao_hub.py`, a MESMA função da web: revogada ou inexistente → `401`; status fresco por 60 s (cache do processo); Hub fora → tolera 5 min com o último "ativa", depois recusa; token sem `sid` (anterior ao P2) passa. Kill switch `EASY_SESSAO_UNICA=false` |

### 3.4 AuthContext

Toda ferramenta recebe internamente
`AuthContext(user_sub, email, nome, tenant_uuid, tenant_nome, apps, modo_licenca, pode_escrever, sid, client_id)`.
**Nenhum argumento da IA vira identidade.** Não existe parâmetro `tenant_uuid` nem `user_id` em
ferramenta alguma. Usuário com mais de um tenant escolhe o tenant **no login do Hub**. Trocar de
tenant = reconectar.

### 3.5 Estado guardado pelo Easy (zero tabela nova)

| Coisa | Onde | Por quê |
|---|---|---|
| Cliente registrado (DCR) | **nenhum lugar**: o `client_id` é o próprio metadado do cliente, compactado e cifrado (Fernet, chave `EASY_MCP_CLIENT_SECRET`, prefixo `emc1.`). O SDK sorteia um uuid4 e passa a `register_client` o mesmo objeto que devolve ao cliente; é ali que o id é trocado (SDK travado em 2.3.0, coberto por `test_oauth.py`). Trocar a chave = clientes reconectam | nada a perder num flush do Redis, nada a migrar |
| Pedido de autorização pendente | Redis, TTL 5 min | vida curta |
| Code do Easy → cliente | Redis, TTL 5 min, uso único | vida curta |
| Plano de escrita (§6) | Redis, TTL 15 min | vida curta |
| Contadores de cota (§7) | Redis | mesmo padrão do mobile |

Sem Redis, o OAuth e as escritas **recusam** (fail-closed). As cotas de leitura, como no mobile,
são fail-open.

### 3.6 Revogação e validade

- Hoje (antes do §P2 do Hub): o token vale até o `exp` (TTL do app `easy-mcp`, definido no Hub).
- Com o §P2: desconectar o MCP = o Hub revoga o `sid` daquele usuário×`easy-mcp`, sem tocar na
  sessão web.
- Refresh token: o Hub não tem. Enquanto não tiver (§P3, opcional), o cliente refaz o OAuth ao
  vencer, em silêncio se a sessão do Hub no navegador estiver viva.

## 4. Ferramentas da V0

Nomes em português, prefixo `easy_` (o cliente pode ter vários servidores MCP; o prefixo evita
colisão). Todas com `inputSchema` explícito, saída estruturada e `ToolAnnotations`
(`readOnlyHint`, `destructiveHint`, `idempotentHint`).

### 4.1 Acesso

**`easy_meu_acesso()`** — leitura.
Devolve `{usuario:{nome,email}, tenant:{nome,codigo}, apps:[...], modo_licenca, pode_escrever, limites:{...}}`.
É o que a IA consulta para saber o que pode fazer. Sem identidade sensível além do que o próprio
usuário já vê na tela.

### 4.2 Navegação

**`easy_listar_empreendimentos(busca?)`** — leitura. Serviço: `ativo.service.listar_empreendimentos`.

**`easy_listar_ativos(emp_id)`** — leitura. Serviço: `ativo.service.listar_ativos_detalhe`.
Cada ativo vem com `atv_id`, nome, revisão vigente (ex.: `R00`) e a URL da tela.

### 4.3 Orçamento (bancada)

**`easy_orcamento_arvore(atv_id, prefixo?, profundidade?, pagina?)`** — leitura.
Serviço: `orcamento_service.get_bancada` (a mesma árvore da tela). Linhas compactas:
`{id, path, nivel, tipo, codigo, fonte, descricao, unidade, quantidade, filhos}`. O `path` sai no
formato da tela (`2.1.3`), não no formato interno (`002000.001000.003000`). `prefixo` recorta uma
subárvore (`2.2`), e `profundidade` corta níveis. Teto de 500 linhas por página.

**`easy_orcamento_replicar(atv_id, origem_ids, destino_ids, quantidade?)`** — escrita, **gera plano**.
Copia os itens de `origem_ids` (serviços e/ou grupos com tudo que têm dentro) para dentro de cada
grupo de `destino_ids`, no fim dos filhos, e opcionalmente ajusta a quantidade das cópias. A prévia
lista, por destino, o que vai nascer e o que vai ser recusado (destino não é grupo, estoura
`NIVEL_MAX`, fonte não utilizável no ativo). Serviço novo `orcamento_service.replicar_itens`,
montado nos miolos `_duplicar`/`_mover`, num cursor e num commit (o mesmo desenho do
`colar_itens`). A tela pode usar depois.

**`easy_orcamento_adicionar_servico(atv_id, parent_id, codigo, fonte?, quantidade?, after_id?)`** — escrita, **gera plano**.
Serviço: `orcamento_service.criar_item` + `_resolver_codigo` (mesma porta da digitação de código
na bancada, inclusive código PRÓPRIO).

**`easy_orcamento_editar_quantidade(atv_id, itens:[{id, quantidade}])`** — escrita, **gera plano**.
Serviço: `orcamento_service.editar_item`. Dispara o `recompute_vinculos_de_fonte` como na tela.

**`easy_aplicar_plano(plano_id)`** — escrita. Executa um plano gerado por qualquer ferramenta acima
(§6).

### 4.4 Catálogo

**`easy_buscar_composicoes(termo, fonte?, edicao?, uf?, modalidade?, pagina?)`** — leitura.
Mesmo `SearchService.search_catalog` da busca da app (`entity_type=CPU`), mesmos candidatos e na
mesma ordem, sob filtros equivalentes. Resposta: `{codigo, fonte, edicao, descricao, unidade, custo, match}`.
**O primeiro resultado não é declarado tecnicamente correto**: quem decide é o operador.

**`easy_buscar_insumos(...)`** — idem, `entity_type=INS`.

### 4.5 Fora da V0 (fila, não promessa)

`easy_get_ecosystem` / `easy_get_product_details` (catálogo institucional: depende de uma fonte
oficial versionada que ainda não existe), detalhe de composição (insumos e coeficientes), mover,
apagar, memória de cálculo, cronograma, Price, CPU própria. Entram quando houver demanda real e
serviço maduro por trás.

## 5. Regras que valem para toda ferramenta

1. **Só serviço de domínio.** A ferramenta não abre cursor nem monta SQL. Se falta serviço, o
   serviço nasce no módulo dele (ex.: `replicar_itens` em `orcamento_service`), nunca dentro de
   `backend/api/mcp/`.
2. **Posse do recurso no serviço.** `_own(cur, tenant_uuid, atv_id)` e equivalentes. ID de outro
   tenant devolve **o mesmo** "não encontrado" de ID inexistente (sem enumeração).
3. **Escrita só na revisão vigente** (`aor_de`), como na tela.
4. **Mesmas guardas da tela:** `NIVEL_MAX`, lei da posição (serviço segue o grupo acima), fonte
   utilizável com data-base, TRUNC(2). O MCP não ganha atalho que a tela não tem.
5. **Erros previsíveis**, em `{erro: <codigo>, mensagem}`: `nao_autorizado`, `licenca_insuficiente`,
   `somente_leitura`, `nao_encontrado`, `entrada_invalida`, `conflito` (plano velho), `limite`.
   Nunca stack trace, SQL, caminho de arquivo nem segredo.
6. **Saída enxuta.** Pagina tudo que pode crescer. Valores monetários em número com 2 casas (TRUNC),
   sempre acompanhados de fonte, edição, UF e modalidade.

## 6. Escrita em duas fases: prévia → aplicar

A proteção existe **contra a IA do usuário**, que pode errar feio no negócio. Por isso vale em dev
e em prod, e não depende de o cliente pedir confirmação.

1. A ferramenta de escrita **não escreve**. Ela valida tudo, calcula o que vai acontecer e grava no
   Redis um **plano**: `{plano_id, ferramenta, atv_id, aor_id, operacoes, digital, criado_por, expira_em}`.
   Devolve à IA a prévia legível (contagens, exemplos, recusas) e o `plano_id`.
2. A IA mostra a prévia ao usuário. O usuário confirma.
3. `easy_aplicar_plano(plano_id)`:
   - plano de outro usuário/tenant → `nao_encontrado`;
   - plano vencido (15 min) → `conflito` (gera de novo);
   - **digital** = hash do trecho da árvore que o plano toca (ids, pais, ordens, aoc e quantidades
     dos destinos). Se mudou desde a prévia (alguém editou na tela) → `conflito`, nada é escrito;
   - executa as operações **numa transação só**: ou entra tudo, ou nada;
   - consome o plano. Aplicar de novo devolve **o mesmo resultado**, sem escrever outra vez
     (idempotência).
4. Teto por plano: `EASY_MCP_MAX_OPS` (default 500 itens criados/alterados).

## 7. Anti-raspagem do catálogo

O risco: um concorrente usando o MCP para baixar o banco de insumos/composições pedindo "isto,
aquilo, aquilo outro". Mesma doutrina do Easy Mobile (`backend/api/mobile/limites.py` e
`rate_limit.py`), reusada e não copiada:

| Guarda | Valor default | Env |
|---|---|---|
| Termo mínimo | 3 caracteres | (constante do mobile) |
| Itens por página | 20 | `EASY_MCP_POR_PAGINA` |
| Páginas por termo | 10 | (constante do mobile) |
| Buscas por minuto, por usuário | 30 | `EASY_MCP_BUSCA_MIN` |
| Buscas por dia, por usuário | 400 | `EASY_MCP_BUSCA_DIA` |
| Chamadas por minuto, por usuário (todas as ferramentas) | 120 | `EASY_MCP_RATE_MIN` |

O termo mínimo sozinho não basta (o raspador varre `aaa`, `aab`, …). Quem trava a varredura é a
**cota diária por usuário**, que um humano orçando não alcança. Como é um contador no Redis por
chamada, não custa desempenho nem qualidade de busca. Estourou → `limite` com `retry_after`.

Leitura do **próprio** orçamento (árvore) não tem cota de busca, só a geral: é dado do tenant.

## 8. Auditoria

A doutrina da bancada (não auditar por operação) continua valendo **para a tela**. No MCP, cada
`easy_aplicar_plano` bem-sucedido grava **uma** linha em `audit.logs`, via
`audit_service.registrar`, sem coluna nova:

| Coluna | Valor |
|---|---|
| `log_schema` / `log_tabela` | `ativo` / `ativo_orcamento_itens` |
| `log_registro_id` | `atv_id` |
| `log_acao` | `INSERT` (replicar/adicionar) ou `UPDATE` (quantidade) |
| `log_usuario` | e-mail do AuthContext |
| `log_dados_depois` | `{canal:"mcp", ferramenta, plano_id, client_id, aor_id, n_itens, ids_criados/alterados, request_id}` |

Login via MCP já cai no `audit.login_log` do Hub (origem `easy-mcp`).

## 9. Transporte e segurança HTTP

- Streamable HTTP, `stateless_http=True` (nada de sessão em memória; qualquer worker atende).
- `TransportSecuritySettings` do SDK com allowlist de Host/Origin (`EASY_MCP_ALLOWED_HOSTS`).
- Limites de payload e de tempo por chamada (`EASY_MCP_TIMEOUT_S`, default 30 s). Nada de escrita
  longa síncrona: se uma ferramenta futura precisar, ela vira job (ADR-006).
- O SDK fixa o OAuth e os metadados na **raiz** do host (`/authorize`, `/token`, `/register`,
  `/revoke`, `/.well-known/oauth-*`). Um despachante ASGI na frente da app desvia para o MCP só
  esses caminhos + `/mcp` + `/mcp/oauth/hub-callback`; o resto (inclusive o 404 da web) segue
  intocado. Nenhuma rota do Easy pode nascer nesses caminhos.
- Nada disso aparece no OpenAPI/docs da app.

## 10. Ambientes

| | Dev | Prod |
|---|---|---|
| URL MCP | `https://mcp-dev.axys-tec.com.br/mcp` (cloudflared → `localhost:8788`) | `https://<host do Easy>/mcp` |
| Hub | local `127.0.0.1:8000` (o navegador alcança direto) | `axys-tec.com.br` |
| Exposição | túnel com **ingress filtrado**: só `/mcp*`, `/authorize`, `/token`, `/register`, `/revoke` e `/.well-known/oauth-*`; o resto → 404 | o próprio Easy |
| Login | fluxo real do Hub, sem bypass (`EASY_AUTH_BYPASS=false`) | idem |

Só o Easy precisa ser alcançável pelo servidor da OpenAI. A ida ao Hub acontece no navegador do
usuário (login) e de servidor a servidor a partir do Easy (exchange), então o Hub de dev continua
local.

## 11. Critérios de aceite da V0

1. ChatGPT conecta pela URL, autentica pelo Hub e nunca recebe senha.
2. `easy_meu_acesso` mostra tenant, apps e modo de licença corretos.
3. Usuário do tenant A não lê nem escreve no ativo do tenant B, nem com ID conhecido (mesma
   resposta de ID inexistente).
4. Token `easy` (da web) é recusado no `/mcp`, e token `easy-mcp` é recusado na web.
5. Token vencido, assinado por outra chave, de outra audiência ou malformado → `401`.
6. `VIEW_ONLY` → as ferramentas de escrita devolvem `somente_leitura`.
7. `easy_buscar_composicoes` devolve os mesmos candidatos, na mesma ordem, que a busca da app com
   filtros equivalentes.
8. Escrita sem `easy_aplicar_plano` não altera nada. Plano velho (árvore mudou) → `conflito`.
   Aplicar duas vezes → uma escrita.
9. `easy_aplicar_plano` grava uma linha em `audit.logs` com `canal:"mcp"`.
10. Cota de busca estourada → `limite`, e a app web segue normal.
11. Erros nunca expõem SQL, stack trace ou segredo.
12. **Caso real:** no ativo 34 (R00), a IA replica o serviço dos grupos de 2.1 nos grupos de nível 3
    vazios de 2.2–2.7, com prévia e aplicação, e a tela mostra o resultado idêntico ao que um
    copiar/colar manual daria.
