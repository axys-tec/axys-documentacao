# AxysPro

**Status:** 🟡 Planejado  
**Versão:** —  
**Repositório:** axys-pro (futuro)  

---

## O que é?

AxysPro é o **sistema ERP completo para projetos e obras**.

**Escopo (planejado):**
- Gestão de projetos (obra, fases, atividades)
- Custo e orçamento (integrado com AxysEasy)
- Contratos e documentação legal
- Controle executivo e indicadores
- Integração com sistemas externos (ERPs, fiscais)

**Status:** Documentação de design em [../../z_trash/old_docs_repo/AxysPro/](../../z_trash/old_docs_repo/AxysPro/)

---

## 📋 Estrutura Planejada

```
projects/axys-pro/
├── README.md           # este arquivo
├── ARCHITECTURE.md     # (por criar)
├── schemas/
│   ├── schema.sql      # (por criar)
│   └── migrations/
├── adrs/               # decisões específicas
├── contracts/
├── modules/            # (por definir)
└── ...
```

---

## 🚀 Como Iniciar

Quando AxysPro for iniciado:
1. Crie [ARCHITECTURE.md](ARCHITECTURE.md) com visão geral
2. Defina módulos principais em [modules/](modules/)
3. Documente banco de dados em [schemas/](schemas/)
4. Registre decisões em [adrs/](adrs/)

Siga o padrão de AxysEasy como referência.

---

## 📞 Referências

- @see [AxysEasy — Referência](../axys-easy/ARCHITECTURE.md)
- @see [Foundation — Decisões Globais](../../foundation/)
