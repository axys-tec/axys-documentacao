# Prompt para Próximo Chat — Implementar Layer 1 (Insumos)

## Contexto de Mudanças

**Coluna removida do schema:** `catalogo.insumos.ins_tipo_sinapi`

### Por que?

Os 7 tipos de insumo em SINAPI ("MATERIAL", "MAO DE OBRA", etc.) são exatamente os mesmos em nossa tabela `catalogo.insumos_tipo`. Se SINAPI adicionar novos tipos, apenas adicionaremos à nossa tabela — nunca vão remover/alterar os existentes.

Portanto, `ins_tipo_sinapi` era redundante. **Solução:** mapear direto para `ins_ti_id` no momento do import.

### Mudanças Aplicadas

✅ **easy_schema.sql:**
- Removido: coluna `ins_tipo_sinapi TEXT`
- Removido: constraint CHECK validando valores
- Removido: índice `ix_insumos_tipo_sinapi`

✅ **next_step_map.md:**
- Atualizado: SINAPI mapping direto para `ins_ti_id` (não guarda texto)
- Atualizado: CDHU mapping por prefixo (já era assim)
- Simplificado: Lookup de insumos_tipo

---

## Próximo Passo de Implementação

**Arquivo:** `backend/core/import_cpu/parser_cdhu.py`  
**Função:** `parse_insumos(arquivo_path, edi_id, fte_id_cdhu)`

### Mudança no Mapeamento CDHU

**Antes:**
```python
ins_tipo_sinapi = None  # CDHU não tem classificação
ins_ti_id = infer_from_prefixo(codigo)  # Inferir
```

**Agora (igual):**
```python
# Não há mudança — CDHU continua usando prefixo para ins_ti_id
ins_ti_id = infer_from_prefixo(codigo)  # Inferir M0/MAT/EQUIP_AQ/SERV
```

**Para SINAPI:**
```python
# Antes:
ins_tipo_sinapi = row["Classificação"]  # "MATERIAL", "MAO DE OBRA", etc.
ins_ti_id = lookup_tipo(ins_tipo_sinapi)  # Mapear para MAT, MO, etc.

# Agora (mudança):
ins_tipo_sinapi = None  # ← REMOVIDO
ins_ti_id = lookup_tipo(row["Classificação"])  # Mapear direto
```

---

## Checklist para o Parser

- [ ] Carregar `insumos_tipo` em memória no início (lookup dict `ti_codigo → ti_id`)
- [ ] CDHU: `ins_ti_id` via prefixo (sem mudança)
- [ ] SINAPI: `ins_ti_id` via lookup de "Classificação" (remover `ins_tipo_sinapi`)
- [ ] SQL INSERT: não tentar inserir coluna `ins_tipo_sinapi` (ela não existe mais)
- [ ] Testes: validar que CDHU e SINAPI populam `ins_ti_id` corretamente

---

## Usar este prompt assim:

```
next_step:
  - status: pendente
  - fase: Layer 1 Insumos (CDHU + SINAPI)
  - arquivo: backend/core/import_cpu/parser_cdhu.py
  - contexto: Implementar parse_insumos() removendo ins_tipo_sinapi, mapeando direto para ins_ti_id

[COPIE O CONTEÚDO DESTE ARQUIVO ACIMA]
```

---

**Data das mudanças:** 31/05/2026  
**Refs:** easy_schema.sql · next_step_map.md · next_step_app.md
