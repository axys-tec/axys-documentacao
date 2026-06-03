# ADR-010 — Licenciamento por Lease Token e Validação Periódica

**Status:** Aceito  
**Data:** 2026-02-02  

## Contexto
O AxysPro pode operar localmente ou hospedado pelo cliente.  
Como o código local é copiável por definição, a proteção do produto deve ser **econômica e operacional**, não baseada em sigilo de código.

É necessário:
- permitir operação offline controlada;
- evitar chamadas constantes ao Hub;
- impedir uso prolongado sem licença válida.

---

## Decisão
Adotar **licenciamento por Lease Token**, emitido e assinado pelo AxysHub, com validade temporária.

O ERP:
- valida o token localmente;
- opera normalmente dentro do prazo;
- degrada funcionalidades após expiração.

---

## Conceitos-chave

### Lease Token
Token temporário que concede direito de uso por período limitado.

Características:
- assinado pelo Hub;
- contém escopo da licença;
- expira automaticamente;
- validável offline.

### Grace Period
Janela após expiração em que:
- dados permanecem acessíveis;
- operações críticas são bloqueadas;
- usuário é orientado a reconectar.

---

## Fluxo de Licenciamento

1. Usuário autentica no Hub
2. Hub emite Lease Token
3. ERP valida e armazena token
4. ERP opera offline até expiração
5. ERP tenta renovar em background
6. Sem renovação → modo degradado

---

## Modo Degradado

Funcionalidades permitidas:
- leitura de dados
- histórico
- relatórios rascunho

Funcionalidades bloqueadas:
- export oficial
- integrações externas
- novos projetos (opcional)
- recursos premium

---

## Segurança
- Token sempre assinado
- Fingerprint flexível por instalação
- Auditoria mínima no Hub

---

## Consequências
- Proteção contra cópia não autorizada
- UX rápida
- Hub escalável
- Operação previsível
