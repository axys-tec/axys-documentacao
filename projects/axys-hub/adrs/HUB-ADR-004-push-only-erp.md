# ADR-027 — Arquitetura Push-Only (ERP → AxysHub → AxysDashDB)
**Status:** Proposto (para aceite)  
**Data:** 2026-02-06  
**Área:** AxysHub / AxysDash / Microapps ERP

---

## 1) Contexto
O AxysDash é um dashboard de bolso. Muitos ERPs serão **locais** (ex.: LunalôSys), sem endpoint público e sem disponibilidade garantida para *pull* do Hub.

Em escala (1000+ empresas), qualquer arquitetura “Hub puxando do ERP”:
- aumenta superfície de ataque,
- cria dependência de disponibilidade do ERP,
- explode custo/complexidade de jobs,
- quebra fácil quando o ERP é local.

---

## 2) Decisão
A arquitetura oficial do AxysDash é **Push-Only**:

ERP/microapp do cliente → envia snapshots/updates → AxysHub  
AxysHub valida e persiste em AxysDashDB (cache) → iOS lê

O AxysHub **não** realiza *pull* padrão do ERP.

---

## 3) Detalhe operacional (por feature)
Cada funcionalidade do app (ex.: vendas, financeiro) possui dois tipos de ingest:

1) **month_snapshot** (geralmente dia 1)
- Pode ocorrer fora do dia 1 para clientes que entram no meio do mês.
- A API limita (quota), ex.: **máx. 3 vezes por mês** por store+feature.

2) **day_update** (intraday)
- Atualização recorrente (ex.: a cada 5 min).
- A API aplica trava mínima: **não aceitar** requests com intervalo < 5 min por store+feature.

A escolha do ritmo (5 min, 10 min, etc.) é do ERP, mas a API sempre impõe um **mínimo**.

---

## 4) Jobs: o que existe e o que não existe
### Existe
- Jobs internos do AxysHub para **manutenção do cache**:
  - limpeza mensal (dia 1),
  - limpeza de mídias do mês anterior,
  - compactação/housekeeping.

### Não existe (como padrão)
- Job do AxysHub “consultando/raspando” o ERP do cliente.

---

## 5) Consequências
### Benefícios
- Compatível com ERPs locais.
- Segurança melhor (menos integrações inbound).
- Escala previsível (push controlado + rate limit).
- AxysDashDB pode ser descartado sem impacto em CORE.

### Custos/limitações
- Sem histórico garantido (por definição do produto).
- Reprocessamentos mensais dependem do ERP enviar `month_snapshot`.

---

## 6) Impacto em contratos e ADRs existentes
- O contrato do Dash deve explicitar que o iOS é **read-only** e que o ingest é **separado**.
- A ADR-026 (Client Credentials) permanece válida e **não conflita** com Push-Only.
  - Um **único API client** pode ser usado para ingest + leitura (automação).
  - Separar em dois clients é **opcional**, não obrigatório.

---

## 7) Registro
Esta ADR define o padrão de integração para o AxysDash.
Qualquer exceção (*pull* de ERP) exige ADR específica por caso.
