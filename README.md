# AxysHub - Documentacao

## O que e o AxysHub
O AxysHub e a plataforma central (hosted) do ecossistema Axys para licenciamento, catalogo comercial e autosservico. Ele e a fonte da verdade para tenants, usuarios, assinaturas e acesso a microapps.

## Escopo e limites
- Licenciamento, catalogo e autosservico do cliente
- Tenancy e controle de acesso
- Integracoes por API e webhooks
- Nao executa operacao do cliente (nao e ERP)
- Nao substitui sistemas internos da Axys

## Docs principais
- docs/api_flow_axysdash.md
- docs/axysdash_api_bridge.md
- docs/media_products.md
- docs/hub_console.md

## Estrutura de diretorios (raiz do repo)
- backend/hub: site publico do Hub (templates e static)
- backend/api: API (AxysDash e servicos de apoio)
- backend/core: fundacao e contratos comuns
- backend/modules: dominio do Hub
- docs: documentacao oficial
- instance: runtime local (nao versionado)

## Como rodar local
1) Configure `.env` ou `.env.local` com banco local
2) Suba o Hub (porta 8000):
   - `uvicorn backend.app:app --reload --port 8000`
3) Suba o Dash (porta 8001):
   - `uvicorn backend.app_dash:app --reload --port 8001`
4) Acesse:
   - Hub: `http://127.0.0.1:8000`
   - Dash: `http://127.0.0.1:8001/dash`

## Deploy (visao geral)
- Subir o backend (FastAPI) em ambiente cloud
- Apontar variaveis de ambiente para banco gerenciado
- Servir `backend/hub/static` como assets do site publico
