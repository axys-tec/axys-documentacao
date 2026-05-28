# ADR-030 — Arquitetura de Ferramentas: Excel, AutoLISP e API

**Status:** Aceito  
**Data:** 2026-05-25  
**Relacionado a:** easy_orca, easy_price, easy_cpu

---

## Contexto

O Axys Easy precisa integrar três ambientes de trabalho distintos do usuário de engenharia civil: o **navegador web** (onde vive a aplicação), o **Excel** (onde o usuário opera orçamentos e exporta documentos) e o **AutoCAD** (onde o usuário faz levantamentos de quantitativos a partir de desenhos técnicos).

A questão arquitetural central é: **onde fica a inteligência do sistema?**

Opções consideradas:
- Lógica distribuída entre Excel/VBA + LISP + API
- Lógica no cliente (Excel ou LISP) com API como repositório
- **API como núcleo exclusivo de regras de negócio** ← escolhida

---

## Decisões

### 1. Regra de negócio blindada na API

Nenhuma lógica crítica residirá em Excel, VBA ou AutoLISP. O backend Axys Easy é o único responsável por:

- associação com CPUs;
- motor paramétrico;
- cálculos de valor e coeficientes;
- validações críticas;
- precificação e composições;
- auditoria e histórico.

**Motivo:** evitar engenharia reversa do Excel, impedir cópia da lógica e centralizar manutenção.

### 2. Excel como interface operacional

O Excel é **comunicador, visualizador e editor controlado** — não o cérebro do sistema.

Responsabilidades do Excel/VBA:
- autenticar via API;
- baixar templates e sincronizar dados;
- montar abas a partir de CSV/JSON retornado pela API;
- permitir edição operacional controlada;
- exportar relatórios e propostas;
- operar parcialmente offline.

**Formato primário de troca:** CSV separado por vírgula (leve, simples, fácil de depurar no VBA e no backend). JSON apenas quando necessário.

### 3. AutoLISP como coletor CAD

O AutoLISP é **coletor de informações de desenho** — não sistema de orçamento.

Responsabilidades do AutoLISP:
- selecionar objetos, ler layers, blocos e atributos;
- calcular áreas, perímetros e quantidades;
- gerar arquivo TXT normalizado para upload.

### 4. Arquivo TXT normalizado como intercâmbio CAD → Web

Formato oficial de saída do AutoLISP:

```
AXYS_EASY_LEVANTAMENTO_V1
PROJETO=Nome do Projeto
ARQUIVO=planta_01.dwg
DATA=2026-05-25

[TRECHOS]
TIPO;IDENTIFICADOR;LAYER;DESCRICAO;UNIDADE;QUANTIDADE
AREA;SALA_01;ARQ_AMBIENTES;Sala de espera;m2;18.52
PERIMETRO;SALA_01;ARQ_AMBIENTES;Sala de espera;m;17.30
BLOCO;PORTA_80;ESQ_PORTAS;Porta 80cm;un;4
```

Vantagens: universal, portátil, fácil gerar no LISP, fácil parsear no backend, fácil versionar.

### 5. Web como centro de processamento

Upload e processamento ocorrem na interface web:

```
AutoLISP → TXT → upload web → API processa → obra atualizada → Excel sincroniza
```

A web é responsável por: upload, parsing, validação, associação com CPUs, auditoria, versionamento e confirmação do usuário.

### 6. Sem executável local no MVP

Descartado: instalador local, agent local, executável pesado.

**Filosofia:** no-installation. Motivos: suporte, antivírus, assinatura digital, atualizações, dependência de SO.

### 7. AutoLISP universal — sem plugin compilado no MVP

AutoLISP puro roda em AutoCAD, BricsCAD, ZWCAD, GstarCAD e compatíveis IntelliCAD. Plugin nativo restringe CADs, multiplica versões e aumenta suporte.

Nome conceitual do produto: **Conector CAD Universal do Axys Easy** (não plugin, não add-in).

### 8. Fluxo macro consolidado

```
CAD mede → TXT transporta → Web processa → API pensa → Excel opera
```

---

## Consequências

**Positivas:**
- lógica de negócio não exposta ao cliente;
- suporte simplificado (sem instalador);
- compatibilidade ampla de CADs;
- manutenção centralizada no backend;
- base para ecossistema com dependência positiva no Axys.

**Negativas / Compensações:**
- Excel e AutoLISP dependem de conectividade para sincronizar dados críticos;
- UX mais fragmentada no MVP (upload manual de TXT);
- evolução do LISP limitada sem plugin nativo.

---

## Evolução prevista

Ver [`../../../roadmap/easy_tools_roadmap.md`](../../../roadmap/easy_tools_roadmap.md).
