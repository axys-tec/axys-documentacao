# AxysCAD — Contrato e Especificação do Plugin de Captura de Quantitativos

**Versão:** 1.1 (documento único — contrato normativo + especificação operacional)
**Data:** 2026-06-13
**Schema do payload:** `axys-cad-v1`
**Status:** Canônico para implementação do plugin e da ingestão no Easy.

> **Como ler:** §1–§9 são a parte **normativa** (cláusulas imutáveis, JSON canônico, regras de campo, fluxos, integração) — mudá-las é mudar o contrato. §2.2 (stack), §10 (camadas do plugin) e §11 (status no desenho) são **especificação operacional** — detalhe de implementação que pode evoluir sem tocar o contrato.

> **AxysCAD não é orçamentista. AxysCAD é capturador BIM-like de quantitativos.**
> Plugin da família Axys, plugável a AutoCAD, GstarCAD, ZWCAD, BricsCAD e afins.

---

## 1. Identidade e Princípio Reitor

O AxysCAD **captura e marca** quantitativos em ambiente CAD, aplicando rastreabilidade BIM-like sobre o desenho 2D que o engenheiro já produz — sem obrigar migração para modelagem 3D. Ele lê entidades, marca no desenho, normaliza em JSON e envia para o Easy. **Não decide orçamento, não valida verdade técnica, não dedup.**

**Objetivo geral:** realizar levantamentos quantitativos em ambiente CAD aplicando conceitos BIM (rastreabilidade).

**Objetivos específicos:** conectar-se via API ao ecossistema Axys; levantar unidades, comprimentos, áreas, volumes ou valores em texto a partir de elementos do desenho; quantificar os levantamentos; associar quantitativos a itens orçamentários (vinculados a um ativo/empreendimento) — sempre como ato do orçamentista, nunca decisão da máquina.

**Nomenclatura.** Os comandos no CAD são curtos (`AXUNIT`, `AXCOMP`, `AXAREA`, `AXVOL`, `AXTEXT`); o valor canônico no JSON usa o mesmo token em `collector` e o `quantity_type` correspondente (ver §3). Onde a documentação de produto falar em "AXYS_UNIT/AXYS_LENGTH/…", trata-se de rótulo de exibição — o contrato é o nome canônico.

### 1.1 Cláusula de Fidelidade-não-Correção (relevante para minuta jurídica)

> **A aplicação garante FIDELIDADE ao que foi lido** — a entidade, a quantidade aferida, o rastro visual e a procedência. **Não garante, e não promete, CORREÇÃO do que foi lido.** Entrada válida é responsabilidade do profissional habilitado (o orçamentista). A ferramenta torna o erro **visível e barato de achar** — não impossível.

Justificativa técnica desta cláusula, que deve ser preservada na minuta:

- Entidade bem-formada, handle único e JSON que valida no schema **não** garantem dado verdadeiro. Escala errada do DWG, elementos sobrepostos, seleção de peça indevida ou leitura em dobro produzem dados igualmente "válidos".
- A informação que separa **válido** de **verdadeiro** não está no dado — está no mundo que o dado representa. Só a perícia humana sabe que um rodapé de sala não tem 4 km.
- Por isso o sistema **não impõe** constraints de unicidade que a realidade do levantamento não respeita. Fingir que um constraint impede erro de campo é mentira de schema.
- O papel da ferramenta é **acelerar a leitura e expor o rastro** (marcação no desenho + quantitativo + evidência por entidade), para que a perícia aconteça com o trabalho pesado já feito. A responsabilidade técnica permanece, por lei e por bom senso, com o profissional habilitado — como em todo software de engenharia.

### 1.2 Cláusula de Agnosticismo de Plataforma (invariante de não-refatoração)

> **O contrato `axys-cad-v1` é único e imutável entre todas as origens de coleta — AutoCAD, GstarCAD, ZWCAD, BricsCAD, Revit (RVT), IFC e qualquer ferramenta ou modelo de coleta futuro. A API NUNCA ramifica seu comportamento por `source.platform`.**

Esta é a cláusula que sustenta a promessa de **nunca refatorar a API** ao adicionar uma nova origem. Ela se apoia na separação entre duas camadas do payload:

- **Envelope (agnóstico, imutável):** `schema_version`, `source`, `context` e os campos canônicos de cada captura (`collector`, `quantity_type`, `unit`, `quantity`, `method`, `coefficient`, `association`, `sync`). A semântica do quantitativo é a mesma independentemente da origem — uma área é uma área, venha de uma hachura no CAD, de uma face no Revit ou de um `IfcSlab`. **A API lê e quantifica exclusivamente esta camada.**
- **Entidades (específicas da origem, mas de forma fixa):** a *forma* do campo de entidade não muda (`handle`, `type`, `layer`, `coordinates`, `raw_text`, `parsed`); muda apenas o *conteúdo*. No CAD, `handle` é o handle do DWG e `type` é `INSERT/LWPOLYLINE`; no IFC, o mesmo `handle` carrega o `GlobalId` e `type` vira `IfcWall/IfcSlab`. A ingestão trata `entities` como **payload opaco** (evidência), persistido em `mci_entidades_consideradas` + `mc_json_cru`. A diferença de origem nunca sobe para a lógica de negócio.

**Regra dura, de primeira classe:** é **proibido** à API condicionar processamento por plataforma (`if platform == 'AutoCAD' … else if 'IFC' …`). Qualquer ramificação por origem é, por definição, uma violação deste contrato e o único caminho para forçar refatoração. Adicionar RVT, IFC ou outra ferramenta deve ser **zero mudança** na API — apenas uma nova origem emitindo o mesmo envelope.

---

## 2. Arquitetura de Fluxo

### 2.1 Premissas de operação (fluxo end-to-end)

```
Plugin [comando AXYS no CAD]
   ↓ Login OAuth/JWT (via AxysHub → validação de licença)
   ↓ Seleção de entidades no desenho
   ↓ Extração de geometria / camadas / blocos / textos
   ↓ Marcação visual no desenho (layer AXYS_CAD_*)
   ↓ JSON normalizado (axys-cad-v1)
   ↓ Envio à API Easy (UPSERT idempotente por arquivo)
   ↓ Recebe confirmação / memória
   ↓ Conciliação no Easy (perícia humana → associação → persistência)
```

### 2.2 Stack

C# .NET Framework · WinForms ou WPF · AutoCAD .NET API · GstarCAD .NET API · HTTP Client · JWT.

> A stack é **detalhe de implementação**, não cláusula. Trocar WPF↔WinForms, adicionar a API .NET de outra plataforma CAD ou mudar o cliente HTTP **não toca o contrato** (envelope `axys-cad-v1` permanece — ver §1.2).

### 2.3 Autenticação e licença

```
Plugin CAD
   ↓ Login OAuth/JWT
   ↓ API Axys [via AxysHub]
   ↓ Validação de licença
```

Login OAuth/JWT contra a API Axys via AxysHub, com validação de licença. Token mantido em estado local do plugin (`LocalState.token`). As credenciais de contexto (`tenant_id`, `user_id`, `user_name`) descem da API após o login e populam o cabeçalho do JSON.

### 2.4 Comandos

**Comandos CAD nativos** (o user usa normalmente para desenhar o que será medido): line, polyline, rectangle, circle, hatch, text, block/insert etc.

**Comandos Axys de captura:** `AXUNIT` (qualquer entidade unitária — bloco, texto, linha; tem de ser unidade), `AXCOMP` (lines/polylines), `AXAREA` (elementos com área — rectangle, circle, hatch), `AXVOL` (área de AXAREA × coeficiente-espessura), `AXTEXT` (valor numérico registrado em texto, a qualquer unidade). Detalhe em §3.

**Comandos Axys de plugin:** conectar à API; trazer dados de empreendimento/ativo/orçamento; associar JSON de levantamento a itens; enviar JSON para a API.

### 2.5 O que entra e o que sai

- **O user seleciona:** as entidades do desenho conforme o coletor acionado (§3).
- **O plugin extrai:** geometria, camadas, blocos e textos das entidades selecionadas, normalizando em capturas (§5).
- **Vai para a API Easy:** o JSON `axys-cad-v1` (§5).
- **Volta da API:** confirmação de sync / `remote_id` e, conforme o fluxo, dados de memória para conciliação.
- **O plugin escreve no CAD:** os marcadores na layer própria (§4).

---

## 3. Coletores

Cinco coletores canônicos. **Comando curto** no CAD; **`collector`/`quantity_type`** canônicos no JSON.

| Comando CAD | `collector` | `quantity_type` | Unidade típica | Lê | Marca |
|---|---|---|---|---|---|
| `AXUNIT` | `AXUNIT` | `UNIT` | UN | qualquer entidade unitária (bloco, texto, linha) | círculo r=0.5 |
| `AXCOMP` | `AXCOMP` | `LENGTH` | M | lines / polylines | linha auxiliar esp. 0.05 |
| `AXAREA` | `AXAREA` | `AREA` | M2 | elementos com área (rectangle, circle, hatch) | hachura |
| `AXVOL` | `AXVOL` | `VOLUME` | M3 | área (AXAREA) × coeficiente (espessura) | hachura |
| `AXTEXT` | `AXTEXT` | `TEXT_VALUE` | qualquer | valor numérico registrado em texto | tachado (strikethrough) |

---

## 4. Marcação no Desenho

Toda captura é marcada numa **layer própria**:

```
AXYS_CAD_{LOCATION_OR_FLOOR}_{FRIENDLY_NAME}_{CAPTURE_ID}
```

O `CAPTURE_ID` na layer **é intencional**: preserva a trilha de *passadas*. Se a coleta de um mesmo levantamento aconteceu em mais de uma leitura, cada passada vira uma layer rastreável — dado pericial de primeira ordem (permite enxergar, p.ex., sobreposição entre duas leituras sobre a mesma região). O agrupamento visual "por tipo" é resolvido na conciliação/no Easy, não na layer.

Marcas por tipo: `CIRCLE` (unit, círculo de raio 0.5), `LINE` (length, linha auxiliar esp. 0.05), `HATCH` (area/volume, hachura sobre os elementos), `STRIKETHROUGH` (text, linha riscando o texto). Todos os marcadores são registrados na layer própria da captura.

---

## 5. Modelo JSON Canônico (`axys-cad-v1`)

**Um JSON por arquivo DWG**, contendo N capturas. Envio idempotente por **UPSERT** (se o user recria o arquivo local, o reenvio sobrescreve). Não há unicidade imposta — duplicata é tratada na conciliação como **aviso**, nunca bloqueio.

```json
{
  "schema_version": "axys-cad-v1",
  "source": {
    "app": "AxysCADPlugin",
    "platform": "AutoCAD",
    "file_name": "projeto.dwg"
  },
  "context": {
    "tenant_id": "TENANT_UUID",
    "user_id": "USER_UUID",
    "user_name": "Renan Dias",
    "asset_id": null,
    "budget_id": null
  },
  "captures": [
    {
      "capture_id": "uuid-unit-001",
      "location_or_floor": "TERREO",
      "friendly_name": "BACIAS",
      "name": "Bacias do térreo",
      "description": "Contagem unitária de bacias sanitárias",
      "association": { "budget_item_id": null, "composition_code": null, "input_code": null },
      "collector": "AXUNIT",
      "quantity_type": "UNIT",
      "unit": "UN",
      "quantity": 4,
      "method": "selection_count",
      "coefficient": null,
      "trace": {
        "marker_layer": "AXYS_CAD_TERREO_BACIAS_uuid-unit-001",
        "mark_type": "CIRCLE",
        "status": "CAPTURED"
      },
      "entities": [
        {
          "handle": "4757A0", "type": "INSERT", "layer": "MOBILIÁRIO - louças",
          "name": "LOUÇA - bacia deca unic planta", "layout": "Model",
          "quantity": null, "unit": "UN", "raw_text": null, "parsed": null,
          "coordinates": { "x": 1221.020684, "y": -1734.428383, "z": 0.0 }
        },
        {
          "handle": "475FA4", "type": "INSERT", "layer": "MOBILIÁRIO - louças",
          "name": "LOUÇA - bacia deca unic planta", "layout": "Model",
          "quantity": null, "unit": "UN", "raw_text": null, "parsed": null,
          "coordinates": { "x": 1224.670684, "y": -1735.728383, "z": 0.0 }
        }
      ],
      "sync": { "status": "PENDING", "remote_id": null, "last_synced_at": null, "error_message": null }
    },
    {
      "capture_id": "uuid-length-001",
      "location_or_floor": "TERREO",
      "friendly_name": "RODAPE_SALA",
      "name": "Rodapé da sala",
      "description": "Comprimento total de rodapé",
      "association": { "budget_item_id": null, "composition_code": null, "input_code": null },
      "collector": "AXCOMP",
      "quantity_type": "LENGTH",
      "unit": "M",
      "quantity": 42.75,
      "method": "entity_length_sum",
      "coefficient": null,
      "trace": {
        "marker_layer": "AXYS_CAD_TERREO_RODAPE_SALA_uuid-length-001",
        "mark_type": "LINE",
        "status": "CAPTURED"
      },
      "entities": [
        {
          "handle": "5A20C1", "type": "LWPOLYLINE", "layer": "ARQ - paredes",
          "name": null, "layout": "Model",
          "quantity": 25.5, "unit": "M", "raw_text": null, "parsed": null,
          "coordinates": { "x": 1190.10, "y": -1700.42, "z": 0.0 }
        },
        {
          "handle": "5A20C8", "type": "LWPOLYLINE", "layer": "ARQ - paredes",
          "name": null, "layout": "Model",
          "quantity": 17.25, "unit": "M", "raw_text": null, "parsed": null,
          "coordinates": { "x": 1205.33, "y": -1712.88, "z": 0.0 }
        }
      ],
      "sync": { "status": "PENDING", "remote_id": null, "last_synced_at": null, "error_message": null }
    },
    {
      "capture_id": "uuid-area-001",
      "location_or_floor": "TERREO",
      "friendly_name": "PISO",
      "name": "Piso do térreo",
      "description": "Área de piso do térreo",
      "association": { "budget_item_id": null, "composition_code": null, "input_code": null },
      "collector": "AXAREA",
      "quantity_type": "AREA",
      "unit": "M2",
      "quantity": 85.32,
      "method": "entity_area_sum",
      "coefficient": null,
      "trace": {
        "marker_layer": "AXYS_CAD_TERREO_PISO_uuid-area-001",
        "mark_type": "HATCH",
        "status": "CAPTURED"
      },
      "entities": [
        {
          "handle": "6B11F0", "type": "HATCH", "layer": "ARQ - pisos",
          "name": null, "layout": "Model",
          "quantity": 50.12, "unit": "M2", "raw_text": null, "parsed": null,
          "coordinates": { "x": 1210.40, "y": -1720.10, "z": 0.0 }
        },
        {
          "handle": "6B11F7", "type": "HATCH", "layer": "ARQ - pisos",
          "name": null, "layout": "Model",
          "quantity": 35.20, "unit": "M2", "raw_text": null, "parsed": null,
          "coordinates": { "x": 1235.18, "y": -1728.55, "z": 0.0 }
        }
      ],
      "sync": { "status": "PENDING", "remote_id": null, "last_synced_at": null, "error_message": null }
    },
    {
      "capture_id": "uuid-volume-001",
      "location_or_floor": "TERREO",
      "friendly_name": "CONCRETO_LAJE",
      "name": "Concreto da laje do térreo",
      "description": "Volume de concreto calculado por área × espessura",
      "association": { "budget_item_id": null, "composition_code": null, "input_code": null },
      "collector": "AXVOL",
      "quantity_type": "VOLUME",
      "unit": "M3",
      "quantity": 10.24,
      "method": "area_times_coefficient",
      "coefficient": { "type": "THICKNESS", "value": 0.12, "unit": "M" },
      "trace": {
        "marker_layer": "AXYS_CAD_TERREO_CONCRETO_LAJE_uuid-volume-001",
        "mark_type": "HATCH",
        "status": "CAPTURED"
      },
      "entities": [
        {
          "handle": "7C3300", "type": "HATCH", "layer": "EST - lajes",
          "name": null, "layout": "Model",
          "quantity": 85.33, "unit": "M2", "raw_text": null, "parsed": null,
          "coordinates": { "x": 1218.70, "y": -1740.22, "z": 0.0 }
        }
      ],
      "sync": { "status": "PENDING", "remote_id": null, "last_synced_at": null, "error_message": null }
    },
    {
      "capture_id": "uuid-text-001",
      "location_or_floor": "FUNDACAO",
      "friendly_name": "ACO",
      "name": "Aço da fundação",
      "description": "Peso de aço capturado a partir de textos do desenho",
      "association": { "budget_item_id": null, "composition_code": null, "input_code": null },
      "collector": "AXTEXT",
      "quantity_type": "TEXT_VALUE",
      "unit": "KG",
      "quantity": 3009.0,
      "method": "text_value_sum",
      "coefficient": null,
      "trace": {
        "marker_layer": "AXYS_CAD_FUNDACAO_ACO_uuid-text-001",
        "mark_type": "STRIKETHROUGH",
        "status": "CAPTURED"
      },
      "entities": [
        {
          "handle": "5C1496", "type": "TEXT", "layer": "EST - ferragem",
          "name": null, "layout": "Model",
          "quantity": 1504.5, "unit": "KG", "raw_text": "1504,50",
          "parsed": { "number": 1504.5, "unit": "KG", "confidence": "HIGH", "parser": "decimal_comma" },
          "coordinates": { "x": 1382.294291, "y": -1719.45482, "z": 0.0 }
        },
        {
          "handle": "5C1502", "type": "TEXT", "layer": "EST - ferragem",
          "name": null, "layout": "Model",
          "quantity": 1504.5, "unit": "KG", "raw_text": "TOTAL CA-50: 1504,50 kg",
          "parsed": { "number": 1504.5, "unit": "KG", "confidence": "MEDIUM", "parser": "decimal_comma_with_label" },
          "coordinates": { "x": 1395.10, "y": -1722.80, "z": 0.0 }
        }
      ],
      "sync": { "status": "PENDING", "remote_id": null, "last_synced_at": null, "error_message": null }
    }
  ]
}
```

> **Encoding:** o payload é **UTF-8**. Mojibake (`MOBILI�RIO`) é bug de codificação do plugin a corrigir na origem — não faz parte do contrato.

---

## 6. Regras de Campo

**Cabeçalho (`source` + `context`)** — um por arquivo. `tenant_id`, `user_id`, `user_name` **não-nulos**; `asset_id`, `budget_id` **nulláveis**.

**`location_or_floor`** — **obrigatório** (null → não sobe). Âncora de localização da memória de cálculo; aceita andar **ou** lugar: `TERREO`, `SUBSOLO`, `1PAV`, `AREA_EXTERNA`, `PRACA`, `CANTEIRO`, `FOSSO_LUZ`. Para levantamento sem pavimento, usar token de localização adequado (ex.: `AREA_EXTERNA`, `GERAL`). É campo de auditoria, não de unicidade.

**`friendly_name`** — slug normalizado pelo plugin, ≤ 20 caracteres, apenas `[A-Z0-9_-]`, sem espaço/acento. Compõe a layer. Sem unicidade.

**`name`** — texto livre do user (rótulo legível). O user nomeia como quiser; a disciplina é mérito dele, a perícia é dele.

**`description`** — texto livre, opcional. Só para o user. **Nunca** toca máquina (fora de layer, fora de chave, fora de derivação).

**`association`** — **por captura** (não por entidade), os três campos nulláveis. Só ganha valor no **fluxo direcionado**. `budget_item_id` é a associação semente; `composition_code`/`input_code` são **hint de conciliação** no fluxo aberto — nunca vínculo autoritativo. A verdade do vínculo mora no Easy (`memo_item_link`), mutável.

**`coefficient`** — `null` ou `{ type, value, unit }`. Hoje só o AXVOL usa (`THICKNESS`); a forma comporta outros (altura, peso específico) sem refatorar. A tela orienta o user no preenchimento.

**Entidade** — toda entidade tem a **mesma forma** (`raw_text` e `parsed` sempre presentes, nulos fora do AXTEXT). Regra de `quantity` por entidade:
- **`null` para UNIT** — 1 entidade = 1 unidade; o número vive no cabeçalho da captura.
- **numérica `round(2)` + unidade para grandeza** (LENGTH/AREA/VOLUME/TEXT_VALUE) — a parcela por entidade é o que permite a perícia.
- No **AXVOL**, a entidade carrega a **área** (M2) e o cabeçalho o **volume** resultante (M3): área × coeficiente auditável de ponta a ponta.

**`parsed` (AXTEXT)** — `{ number, unit, confidence, parser }`. `confidence` MEDIUM/LOW entra **sinalizado** na conciliação (avisa, não bloqueia). Número tirado de texto não alimenta orçamento no escuro.

**`sync`** — por captura: `status`, `remote_id`, `last_synced_at`, `error_message`. Permite sincronizar parte e deixar parte pendente. Estados: `CAPTURED` · `PENDING` · `SYNCED` · `ERROR` · `SUPERSEDED` (re-levantamento marca a leitura anterior como substituída sem apagar histórico).

---

## 7. Os Dois Fluxos de Associação

Ambos escrevem no **mesmo schema**; muda só o `mil_tipo` e como o front monta o vínculo.

**Fluxo Direcionado (`DIRECIONADO`)** — o orçamentista define o item no plugin antes de coletar. A captura sobe com `association.budget_item_id` preenchido; a API associa e quantifica. Menor margem de erro, escalável.

**Fluxo Aberto (`GLOBAL`)** — o user levanta livremente; o JSON acumula **por arquivo** com várias capturas e possivelmente vários itens-alvo. A associação acontece depois, numa **tela de conciliação** (modelo "extrato de cartão"): o Easy mostra o que cada captura vai mexer, sinaliza duplicatas e colisões como **aviso**, e o orçamentista decide. Mais flexível ao quantificar; a conciliação é onde a perícia trabalha. Para ancorar sem ficar totalmente solto, o user pode usar `composition_code` como hint (a API oferece a busca).

> Transferir memória de um item para outro é operação **do orçamento, no Easy** — o plugin apenas tolera a mudança. O `budget_item_id` do JSON é semente; a verdade mutável mora no `memo_item_link`.

---

## 8. Integração com o Módulo Ativo

| JSON AxysCAD | Schema `ativo` (módulo Ativo) |
|---|---|
| `source` + `context` | `memo_calc` (1 por arquivo/import; `mc_json_cru` guarda o payload bruto = verdade da auditoria) |
| cada `captures[]` | `memo_calc_item` (`code`/`name`/`collector`/`quantity_type`/`unit`/`quantity`/`method`/`coefficient` → colunas; `location_or_floor` como âncora) |
| `entities[]` (+ `parsed`) | `mci_entidades_consideradas` (evidência) + bruto em `mc_json_cru` |
| `association.budget_item_id` | `memo_item_link` (N:N), `mil_tipo = DIRECIONADO\|GLOBAL` — **semente**, Easy é a verdade |
| `sync{}` | estado local do plugin; `remote_id` ↔ id de `memo_calc(_item)` |

Sem unicidade de banco. Dedup (mesma entidade em dois itens, levantamento repetido) é **ergonomia de conciliação** — sinal ao user, nunca constraint. A quantidade é **asseverada pelo coletor**; divergência com a contagem de entidades é **alerta**, não recálculo.

---

## 9. Idempotência e Re-levantamento

- **UPSERT por arquivo.** Reenviar sobrescreve; recriar o JSON local e reenviar é seguro.
- **Sync granular.** Levantei bacias + lavatórios, enviei, lavatório estava errado → reabro só o lavatório → plugin marca `PENDING` → re-levanto → reenvio → `SYNCED`. O resto permanece intocado.
- **`SUPERSEDED`.** Re-levantamento de um mesmo levantamento não apaga o anterior; marca como substituído (histórico preservado).
- **Idempotência CAD/RVT/IFC.** O contrato `axys-cad-v1` é o mesmo entre plataformas. RVT/IFC futuros entram sem tocar o schema, pois a ingestão só lê campos estáveis; o específico de plataforma vive no JSON bruto.

---

## 10. Arquitetura do Plugin (camadas)

```
AxysCADPlugin
├── Commands        (AXYS · AXUNIT · AXCOMP · AXAREA · AXVOL · AXTEXT)
├── CaptureEngine   (Unit · Length · Area · Volume · Text)
├── MarkingEngine   (CircleMarker · LineMarker · HatchMarker · StrikeTextMarker)
├── ApiClient       (Auth · Projects · Budgets · Captures)
├── UI              (Palette simples)
└── LocalState      (token · selected_project · pending_captures)
```

- **Commands** — registra os comandos no CAD; `AXYS` abre/gerencia a sessão, os demais disparam os coletores.
- **CaptureEngine** — um capturador por tipo; lê a seleção e produz a captura normalizada (quantidade + entidades).
- **MarkingEngine** — desenha o marcador correspondente na layer da captura (§4).
- **ApiClient** — Auth (login/licença), Projects (ativos/empreendimentos), Budgets (orçamento/itens), Captures (envio/sync).
- **UI** — palette simples para acionar comandos, ver pendências e disparar envio.
- **LocalState** — token de sessão, projeto/ativo selecionado e fila de capturas pendentes; base do envio idempotente e do sync granular.

### 10.1 Estrutura de Diretórios (solution .NET)

Organização **core agnóstico + adaptadores por plataforma** — a materialização, no disco, do invariante da §1.2: o Core não conhece nenhuma API de CAD; cada plataforma entra como projeto adaptador na borda.

```
AxysCAD/                          (solution)
├── AxysCAD.Core/                 (agnóstico — ZERO dependência de DLL de CAD)
│   ├── Capture/                  (CaptureEngine: Unit · Length · Area · Volume · Text)
│   ├── Marking/                  (contratos de marcação — formas, não API CAD)
│   ├── Model/                    (Capture · Entity · Coefficient · Sync — o axys-cad-v1)
│   ├── Serialization/            (monta e valida o JSON canônico)
│   └── Api/                      (ApiClient: Auth · Projects · Budgets · Captures)
│
├── AxysCAD.Cad.Abstractions/     (interfaces da borda: ISelection · IEntityReader · IMarker)
│
├── AxysCAD.AutoCAD/              (adaptador — AutoCAD .NET API)
├── AxysCAD.GstarCAD/             (adaptador — GstarCAD .NET API)
│   (ZWCAD · BricsCAD entram como NOVOS projetos adaptadores, sem tocar o Core)
│
├── AxysCAD.UI/                   (palette WinForms — compartilhada)
│
└── AxysCAD.LocalState/           (token · selected_project · pending_captures)
```

**Regra de ouro da estrutura:** `AxysCAD.Core` **não referencia nenhuma DLL de CAD**. Toda chamada à API do AutoCAD/GstarCAD/etc. mora no respectivo projeto adaptador, atrás das interfaces de `AxysCAD.Cad.Abstractions`. Adicionar uma nova plataforma = **novo projeto adaptador, zero mudança no Core**. É o agnosticismo de plataforma (§1.2) refletido na organização do código.

**Direção da dependência (o Core não referenciar CAD não quebra o plugin).** O plugin **é o adaptador + o Core juntos**, nunca o Core sozinho. Quem o CAD carrega é o **adaptador**, e é ele que referencia as DLLs do CAD (`acdbmgd`, `accoremgd`, etc.), tem os `[CommandMethod]` e fala com a API nativa. O adaptador **referencia o Core**; o Core nunca referencia o adaptador.

```
AutoCAD  →  carrega  →  AxysCAD.AutoCAD (adaptador, referencia DLLs do CAD)
                              ↓ referencia
                          AxysCAD.Core (lógica pura, agnóstica)
                              ↓ referencia
                          AxysCAD.Cad.Abstractions (interfaces: IEntityReader · IMarker · ISelection)
```

O Core depende só das **interfaces**; quem as **implementa** com a API real do CAD é o adaptador. Fluxo em runtime (ex.: `AXAREA`):

1. User digita `AXAREA` — o comando vive no **adaptador**.
2. O adaptador usa a API do CAD para pegar a seleção e ler as hachuras.
3. Entrega ao **Core** como dados simples (entidades, áreas) — o Core não sabe de qual CAD veio.
4. O Core monta a captura, calcula e normaliza o JSON `axys-cad-v1`.
5. O Core pede "marca isto" via `IMarker`; o **adaptador** desenha com a API do CAD.
6. O Core envia o JSON pela API.

O CAD nunca toca o Core diretamente, e o Core nunca toca o CAD — e o plugin funciona inteiro. A tradução "tipo de entidade do CAD → `Entity` do Core" (ex.: `INSERT`/`LWPOLYLINE` → modelo genérico) mora **no adaptador**, que é a borda; é exatamente onde deve estar.

Mapa camada lógica → projeto: Commands/CaptureEngine/MarkingEngine(contratos)/ApiClient/Model → `Core`; bordas concretas de marcação e leitura → adaptadores; UI → `UI` (WinForms); LocalState → `LocalState`.

---

## 11. Validações de Status (no desenho)

`AXYS_QTO_STATUS` Capturado/Pendente · `AXYS_QTO_ERROR` erro de sync · `AXYS_QTO_SYNCED` sincronizado. Espelham o `sync.status` da captura.

---

## 12. Decisões Travadas (resumo)

1. Plugin **captura e marca**; não decide orçamento, não valida verdade, não dedup.
2. **Fidelidade-não-correção** — cláusula §1.1, base do disclaimer jurídico.
2.1. **Agnosticismo de plataforma** — cláusula §1.2: contrato único e imutável entre CAD/RVT/IFC e qualquer coleta futura; a API nunca ramifica por `source.platform`. É o invariante de não-refatoração.
3. **Sem unicidade imposta** — duplicata é aviso na conciliação.
4. `location_or_floor` **obrigatório**; `friendly_name` slug ≤20; `name`/`description` livres.
5. `association` por captura, nullable; `composition_code` é hint, não vínculo.
6. `coefficient` tipado; `parsed` nullable em toda entidade (populado no AXTEXT, com gate de confiança).
7. `quantity` por entidade: null para UNIT, numérica para grandeza.
8. Layer com `capture_id` preserva trilha de passada.
9. UPSERT por arquivo; sync granular; `SUPERSEDED` no re-levantamento.
10. Integra ao Ativo via `memo_calc` / `memo_calc_item` / `memo_item_link`; JSON bruto é a verdade da auditoria.
