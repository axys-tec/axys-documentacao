# Easy Connects™ — Ecossistema de Integração

## Conceito

Os Connects são canais operacionais de utilização dos produtos Easy.

Não são produtos independentes.

São extensões que permitem operar os produtos Easy fora da interface web.

---

## Excel Connect™ — MVP Inicial

### Objetivo

Permitir que o usuário trabalhe integralmente em ambiente Excel mantendo sincronização com o ecossistema Easy.

---

### Fluxo

Usuário acessa o ativo.

Sistema disponibiliza:

* modelo vazio;
* modelo já configurado para o ativo.

---

### Aba Easy-Conector

Responsável por:

* autenticação;
* sincronização;
* seleção de empreendimento;
* seleção de ativo;
* envio;
* obtenção de dados.

---

### Abas

#### Easy-Conector

Conexão com a plataforma.

#### Emp-Ativo

Dados do empreendimento e ativo.

#### CPUs

Lista das composições utilizadas.

Campos:

* fonte;
* edição;
* UF;
* código;
* descrição;
* unidade;
* valor unitário.

#### LS

Leis sociais.

#### BDI

BDI.

#### Planilha

Bancada principal.

#### Cronograma

Planejamento.

#### Memo-Calc

Memorial de cálculo personalizado.

#### Finalização

Finalização e exportação.

---

### Sincronização

Operações:

* Obter;
* Enviar.

Toda sincronização ocorre através da API do ecossistema Easy.

---

## CAD Connect™ — MVP Inicial

### Objetivo

Permitir levantamentos quantitativos diretamente em ambiente CAD.

---

### Plataformas

* AutoCAD;
* GstarCAD;
* ZWCAD;
* BricsCAD.

---

### Funcionalidades

* levantamento de unidades;
* levantamento de comprimentos;
* levantamento de áreas;
* levantamento de volumes.

---

### Integração

O levantamento pode:

* ser associado diretamente a itens do orçamento;
* permanecer desacoplado para associação futura.

---

### Fluxo

CAD

↓

Levantamento

↓

JSON Normalizado

↓

API Easy

↓

Orçamento

---

## RVT Connect™ — Expansão

Plugin para ambiente Revit.

Mantém a mesma filosofia do CAD Connect.

Diferença:

* aproveitamento de informações BIM nativas;
* associação automática mais rica.

---

## IFC Connect™ — Expansão

Ferramenta web para leitura de arquivos IFC.

Objetivo:

* extração de quantitativos;
* associação orçamentária;
* rastreabilidade visual.

Mantém a mesma filosofia operacional dos conectores CAD e RVT.

---

## Observação

Os Connects não substituem os produtos Easy.

Eles apenas oferecem formas alternativas de operação utilizando a mesma infraestrutura central da plataforma.
