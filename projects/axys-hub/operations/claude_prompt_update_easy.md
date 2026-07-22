# Prompt para Claude — atualizar axys-easy a partir do estado atual do AxysHub

Leia cautelosamente, nesta ordem:

1. `docs/projects/axys-hub/contract/axys_mkt_analytics.md`
2. `docs/projects/axys-hub/schemas/schema.sql`
3. `docs/projects/axys-hub/integrations/with-easy.md`
4. `docs/projects/axys-hub/integrations/sso-login-easy.md`
5. o código atual do `axys-hub` que implementa:
   - analytics público em modo `full` e `restricted`;
   - captura de interesse com modal contextual;
   - criação/reuso de `commercial.lead`;
   - vínculo canônico `analytics.visitor_identity_link`;
   - CTA/comercial de `AxysEasy` como porta principal de entrada pública.

Objetivo:

Atualizar o repositório `axys-easy` para que ele fique coerente com o estado atual do Hub, sem depender de premissas antigas.

Diretrizes:

1. Não tocar em nada de `Gestor`. Gestor está fora deste projeto e fora deste repositório.
2. Preservar o modelo JWT/SSO já vigente entre Hub e Easy.
3. Tratar o Hub público como origem de jornada, lead e identificação progressiva.
4. Considerar que o visitante pode chegar ao Easy já vindo de contexto comercial do Hub.
5. Não inventar analytics paralelo desconectado do contrato atual do Hub.

O que validar no `axys-easy`:

1. Pontos de integração com Hub:
   - redirects de login;
   - `redirect_uri`;
   - retorno ao Hub quando aplicável;
   - suposições antigas de origem de usuário.

2. Contratos e documentação:
   - referências ao Hub em README, integrações e onboarding;
   - linguagem sobre porta de entrada comercial do produto;
   - qualquer documentação que tenha ficado defasada após a priorização pública do `AxysEasy`.

3. Fluxo comercial:
   - se existem páginas, CTAs, onboarding ou mensagens no Easy que assumem aquisição isolada;
   - se há pontos que deveriam reconhecer origem `Hub` / `site público`.

4. Segurança e sessão:
   - manter coerência com o SSO atual;
   - não criar atalhos que contornem o fluxo JWT existente;
   - não misturar Easy com Gestor.

Entrega esperada:

1. Liste primeiro todas as inconsistências encontradas entre `axys-easy` e o estado atual do `axys-hub`.
2. Depois proponha as correções.
3. Em seguida, aplique as mudanças necessárias no repositório `axys-easy`.
4. Ao final, informe:
   - o que foi ajustado;
   - o que permaneceu igual por decisão correta;
   - o que ainda depende de decisão humana.

Restrições:

1. Não reescrever a arquitetura do Easy sem necessidade.
2. Não criar novos fluxos comerciais especulativos.
3. Não remover compatibilidade com o SSO atual.
4. Se houver ambiguidade, priorizar o contrato canônico do Hub e apontar explicitamente a dúvida residual.
