# Contratos — Catálogo (schema `catalogo`)

**Princípio de governança:** Contrato governa · Schema suporta · Código implementa · Tela opera.
Cada arquivo aqui é um **contrato de capability** (responsabilidade única, na linguagem do domínio) — a regra de negócio daquela capacidade mora **nele**, não num monólito. *(O antigo `CATALOGO_BUSINESS_RULES.md` foi dissolvido nas capabilities em 2026-07-14; a regra transversal genuína é **schema** — CHECK/vocabulário — não contrato.)*

## Capabilities

| Capability | Governa | Contrato |
|---|---|---|
| **Fontes** | Cadastro de fonte-base + flags (gate de manipulação, catálogos contínuos) | [fontes.md](fontes.md) |
| **Edições** | Cadastro + **ciclo de vida** da edição (rascunho→publicada→revisão/arquivada, lock, gates) | [edicoes.md](edicoes.md) |
| **Listagem** | Consulta de insumos/CPUs + **busca** + o **modelo-núcleo** (preço SE-only, custo, época/retroação) | [listagem.md](listagem.md) |
| **Imports** | Como cada fonte importa: máquina de estados (estágios) + regras (classificação, derivação, conferência, situação, diff) | [imports/estagios.md](imports/estagios.md) · [imports/sinapi.md](imports/sinapi.md) · [imports/cdhu.md](imports/cdhu.md) · [imports/fde.md](imports/fde.md) |
| **Vinculações** | Conciliação de códigos (H↔MÊS, MDO→SINAPI, substituições) | [vinculacoes.md](vinculacoes.md) |
| **Publicação** | Artefatos no R2 + registro (`documentos`/`external_path`) + gate de publicar | [publicacao.md](publicacao.md) |

> Descendo as responsabilidades: as de cima são **mandatórias/gerais**, as de baixo **específicas**. Regra transversal de dado (situação = `CHECK`; unidade = vocabulário) vive no **schema**, com o comportamento (ex.: "0 nunca é SEM PREÇO", "unidade verbatim") na capability que a decide (quase sempre **imports**).

---

## Roadmap / próximos passos

### Repositório de arquivos do catálogo (tela estilo Finder) — a construir
- **Posição do caderno:** o **caderno** (e os demais artefatos) vive em `catalogo.documentos` — o **banco persiste o path**, o **storage guarda o arquivo**. (Regra em [publicacao.md](publicacao.md).)
- **O que o usuário vê hoje:** a **CTC AXYS** (que lista/linka a CTC SINAPI + as fichas de insumo) e o **caderno da edição** (livros, notas, leis sociais, BDI quando aplicável, CTC). Logo, os **cadernos-fonte / arquivos brutos do storage NÃO ficam legíveis** ao usuário por essas telas.
- **FUTURO:** criar no catálogo uma **tela de repositório** que **lista e monta**, no estilo **Windows Explorer / Finder**, os arquivos do storage (a partir de `documentos` + paths). É aí que os cadernos-fonte e demais arquivos passam a aparecer/navegar.

### Work-pages (contratos de tela) — pendência
- Os contratos de **comportamento/UX das telas** hoje vivem em `backend/frontend/templates/catalogo/catalogo_work_pages.md` (fora de `contracts/`). Revisar e trazer para uma capability `work-pages/` **depois de fechar import/fontes**.

### Deferidos (registrados)
- **fichas_fde N:N** — a ficha FDE de componente serve N CPUs; o repense doc/path (§11.9) reserva o `composicao_documento` p/ esse "cross-ref real". Decisão de modelagem adiada. Ver [imports/estagios.md](imports/estagios.md) (DADOS) e a memória do projeto.
- **ativo/routes.py** ficha/caderno → `external_path` — 1º item ao abrir o módulo Ativos.
- **2 cadernos de EQUIPAMENTO** (apresentação sem composição) — listar como referência ou modelar o custo horário. Decisão nichada pendente.
- **Polimento de staleness residual** — as citações inline "ver também" nos contratos de fonte foram roteadas direcionalmente para as capabilities na dissolução; revisar caso a caso quando tocar cada fonte.
