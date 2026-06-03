# AxySync — Engine de Contabilidade

**Status:** 🟢 Produção  
**Tipo:** Serviço de Contabilidade  
**Repositório:** [axys-sync](https://github.com/axys-tec/axys-sync)

---

## O que é?

AxySync é o **engine de contabilidade do ecossistema Axys**, responsável por:

- 📊 Gestão de plano de contas
- 💳 Contas a pagar e receber
- 📈 Análise contábil e de custos
- 🔗 Integração com ERP Axys (Pro)
- 🏢 Suporte a múltiplas empresas (multi-tenant)
- 🎯 Validações de regras contábeis

**Diferentemente de Pro** (ERP generalista), Sync é **especializado em contabilidade**, operando como serviço independente que:
- Pode executar localmente
- Integra com Pro quando ativo
- Valida dados contábeis por regras de negócio
- Mantém conformidade fiscal

---

## 📁 Documentação

### Local (Este Repositório)
- **Integrations** — Como Sync se conecta ao ecossistema

### Remota (Repositório Independente)
Documentação original mantida em: **[axys-sync/docs/](https://github.com/axys-tec/axys-sync/tree/main/docs)**

```
axys-sync/docs/
├── axys_sync_ascont_regras_vendas.md          # Regras de vendas
├── axys_sync_baseline_operacional.md          # Setup inicial
├── axys_sync_business_matrix.md               # Matriz de negócio
├── axys_sync_business_rules.md                # Regras operacionais
├── axys_sync_continuous_redesign.md           # Evolução contínua
├── axys_sync_documentacao.md                  # Índice
├── axys_sync_runtime_environment.md           # Ambiente runtime
└── axys_sync_smoke_test_checklist.md          # Testes
```

**Consulte o repositório principal para:**
- Regras de contabilidade específicas
- Configuração de ambiente
- Procedimentos operacionais
- Testes de fumaça (smoke tests)

---

## 🔗 Integração com Ecossistema Axys

```
AxySync (Engine de Contabilidade)
   ├─ AxysHub (Control Plane)
   │  └─ autenticação & tenants
   │
   ├─ AxysEasy (MicroApp)
   │  └─ consome dados contábeis
   │
   └─ AxysPro (ERP) — Futuro
      └─ módulo financeiro
```

---

## 📋 Estrutura Aqui

```
docs/projects/axys-sync/
├── README.md              # este arquivo
├── integrations/
│   ├── with-hub.md        # Autenticação & tenants
│   ├── with-easy.md       # Como Easy consome Sync
│   └── data-flows.md      # Fluxos contábeis
└── docs-reference.md      # Índice de docs remotas
```

---

## 🚀 Como Começar

1. **Leia a documentação remota:**  
   [axys-sync/docs/](https://github.com/axys-tec/axys-sync/tree/main/docs)

2. **Entenda as regras contábeis:**  
   [axys_sync_business_rules.md](https://github.com/axys-tec/axys-sync/blob/main/docs/axys_sync_business_rules.md)

3. **Configure o ambiente:**  
   [axys_sync_baseline_operacional.md](https://github.com/axys-tec/axys-sync/blob/main/docs/axys_sync_baseline_operacional.md)

4. **Entenda a integração com Axys:**  
   Veja [integrations/with-hub.md](integrations/with-hub.md)

---

## 📚 Referências

- **Hub** — [AxysHub](../axys-hub/README.md)
- **Easy** — [AxysEasy](../axys-easy/README.md)
- **Pro** — [AxysPro](../axys-pro/README.md)
- **Sync-Loccitane** — [AxySync Especializado](../axys-sync-loccitane/README.md)
- **Foundation** — [Decisões Globais](../../foundation/)

---

## ⚠️ Nota Importante

AxySync é mantido como **repositório independente** com sua própria documentação de domínio.

Este diretório ([axys-easy/docs/projects/axys-sync/](./)) serve como **bridge de integração** no ecossistema, não como cópia.

Para mudanças na documentação remota, consulte: [axys-sync](https://github.com/axys-tec/axys-sync)
