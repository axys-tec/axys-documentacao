# AxysLisp

**Status:** 🟡 Planejado  
**Versão:** —  
**Repositório:** axys-lisp (futuro)  

---

## O que é?

AxysLisp é a **integração CAD/BIM** que converte levantamentos de CAD em estruturas de orçamento.

**Função:** Automatizar a extração de dados de projetos CAD (Revit, AutoCAD, etc) para alimentar AxysEasy.

**Saídas:**
- JSON estruturado de levantamentos (items, quantities, hierarchies)
- Mapeamento automático de componentes para composições
- Suporte a diferentes fontes (AutoLISP, Revit API, IFC)

---

## 📋 Contratos

- **JSON Levantamento** — Formato padrão (schema, exemplos)
- **Mapeamento CAD → Insumos** — Como converter componentes CAD

Veja [contracts/](contracts/) quando iniciado.

---

## 🚀 Como Iniciar

1. Defina [contracts/json-schema.md](contracts/)
2. Documente integração CAD em [CAD-BIM-integration.md](CAD-BIM-integration.md)
3. Crie exemplos em [examples/](examples/)

---

## 📞 Referências

- @see [AXYS-ADR-020 — Ferramentas Excel, AutoLISP, API](../../foundation/adrs/AXYS-ADR-020-ferramentas-excel-autolisp-api.md)
- @see [AxysEasy — Integração](../axys-easy/integrations/with-lisp.md)
